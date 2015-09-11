##############################################
# $Id: 14_Cresta.pm  2015-08-30 $
# The file is taken from the SIGNALduino project
# see http://www.fhemwiki.de/wiki/SIGNALduino
# and was modified by a few additions
# to support Cresta Sensors
# S. Butzek, 2015
#

package main;

use strict;
use warnings;
use POSIX;
 
#use Data::Dumper;
 
#####################################
sub
Cresta_Initialize($)
{
  my ($hash) = @_;


  $hash->{Match}     = "^[5][0|8]75[A-F0-9]+";   # GGF. noch weiter anpassen
  $hash->{DefFn}     = "Cresta_Define";
  $hash->{UndefFn}   = "Cresta_Undef";
  $hash->{AttrFn}    = "Cresta_Attr";
  $hash->{ParseFn}   = "Cresta_Parse";
  $hash->{AttrList}  = "IODev do_not_notify:0,1 showtime:0,1 ".
                       "ignore:0,1 ".
                       $readingFnAttributes;
}


#####################################
sub
Cresta_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);

  return "wrong syntax: define <name> Cresta <code> <minsecs> <equalmsg>".int(@a)
		if(int(@a) < 3 || int(@a) > 5);

  $hash->{CODE}    = $a[2];
  $hash->{minsecs} = ((int(@a) > 3) ? $a[3] : 30);
  $hash->{equalMSG} = ((int(@a) > 4) ? $a[4] : 0);
  $hash->{lastMSG} =  "";
  $hash->{bitMSG} =  "";

  $modules{Cresta}{defptr}{$a[2]} = $hash;
  $hash->{STATE} = "Defined";

  AssignIoPort($hash);
  return undef;
}

#####################################
sub
Cresta_Undef($$)
{
  my ($hash, $name) = @_;
  delete($modules{Cresta}{defptr}{$hash->{CODE}}) if($hash && $hash->{CODE});
  return undef;
}

sub Cresta_hex2bin {
        my $h = shift;
        my $hlen = length($h);
        my $blen = $hlen * 4;
        return unpack("B$blen", pack("H$hlen", $h));
}

#####################################
sub
Cresta_Parse($$)
{
	my ($hash,$msg) = @_;
	my $name = $hash->{NAME};
	#my $name="CRESTA";
	my @a = split("", $msg);
	#my $name = $hash->{NAME};
	Log3 $hash, 4, "Cresta_Parse $name incomming $msg";
	my $rawData=substr($msg,2); ## Copy all expect of the message length header
	
	#Convert hex to bit, may not needed
	my $hlen = length($rawData);
	my $blen = $hlen * 4;
	my $bitData= unpack("B$blen", pack("H$hlen", $rawData)); 
	Log3 $hash, 4, "$name converted to bits: $bitData";

	# decrypt bytes
	my @decodedBytes = (); # holds the decrpyted data as array
	my $decodedString =(); # holds the decryped hex string
	$decodedString = decryptBytes($rawData); # decrpyt hex string to hex string
	#convert back to array of bytes:
	for (my $i=0; $i<(length($decodedString))/2; $i++){
		my $hex=hex(substr($decodedString, $i*2, 2));
		push (@decodedBytes, $hex);
	}
	#for debug only
	my $test="";
	
	for(my $i=0; $i<scalar @decodedBytes; $i++){
		$test.=sprintf("%02x", $decodedBytes[$i]);
	}
	Log3 $name,4, "bytes arr->".$test;
	Log3 $name,4, "bytes hex->$decodedString";
	#end for debug only
	
	if (!@decodedBytes)
	{
		Log3 $hash, 4, "$name decrypt failed";
		return "$name decrypt failed";
	}
	if (!Cresta_crc($rawData))
	{
		Log3 $hash, 4, "$name crc failed";
		return "$name crc failed";
	}
	my $sensorTyp=getSensorType($decodedBytes[3]);
	Log3 $hash, 4, "SensorTyp=$sensorTyp, ".$decodedBytes[3];
	my $id=1;
	my $channel=0;
	my $temp=0;
	my $hum=0;
	my $rc;
	my $model;
	my $val;
	## 1. Detect what type of sensor we have, then calll specific function to decode
	if ($sensorTyp==0x1E){
		($rc,$channel, $temp, $hum) = decodeThermoHygro($decodedString);
		$model="th";  
		$val = "T: $temp H: $hum";
	}else{
		Log3 $hash, 4, "$name Sensor Typ $sensorTyp not supported";
		return "$name Sensor Typ $sensorTyp not supported";
	}

	if ($rc != 1)
	{
		Log3 $hash, 4, "$name error, decoding Cresta protocol" ;
		return "UNDEFINED $sensorTyp error, decoding Cresta protocol";
	}
    my $deviceCode=$model."_".$sensorTyp."_".$channel;
	Log3 $hash, 4, "$name decoded Cresta protocol Typ=$sensorTyp, sensor id=$id, channel=$channel, temp=$temp, humidity=$hum\n" ;
    Log3 $hash, 5, "deviceCode= $deviceCode";	

	my $def = $modules{Cresta}{defptr}{$hash->{NAME} . "." . $deviceCode};
	$def = $modules{Cresta}{defptr}{$deviceCode} if(!$def);

	if(!$def) {
		Log3 $hash, 1, "Cresta: UNDEFINED sensor $sensorTyp detected, code $deviceCode";
		return "UNDEFINED $deviceCode Cresta $deviceCode";
	}
	#Log3 $hash, 5, "def= ". Dumper($def);
	
	$hash = $def;
	$name = $hash->{NAME};
	return "" if(IsIgnored($name));

	Log3 $name, 4, "Cresta: $name ($msg)";  

	if($hash->{lastReceive} && (time() - $hash->{lastReceive} < $def->{minsecs} )) {
	if (($def->{lastMSG} ne $msg) && ($def->{equalMSG} > 0)) {
	  Log3 $name, 4, "Cresta: $name: $deviceCode no skipping due unequal message even if to short timedifference";
	} else {
	  Log3 $name, 4, "Cresta: $name: $deviceCode Skipping due to short timedifference";
	  return "";
	}
	}
	$hash->{lastReceive} = time();

	#if(!$val) {
	#Log3 $name, 1, "Cresta: $name: $deviceCode Cannot decode $msg";
	#return "";
	#}

	$def->{lastMSG} = $msg;

	Log3 $name, 4, "Cresta update $name:". $name;

	readingsBeginUpdate($hash);
	readingsBulkUpdate($hash, "state", $val);
	#readingsBulkUpdate($hash, "battery", $bat)   if ($bat ne "");
	#readingsBulkUpdate($hash, "trigger", $trigger) if ($trigger ne "");
	# use short term reading names T and H
#	readingsBulkUpdate($hash, "H", $hum) if ($hum ne "");
#	readingsBulkUpdate($hash, "T", $temp) if ($temp ne "");
        # or use long term reading names temperature and humidity
	readingsBulkUpdate($hash, "humidity", $hum) if ($hum ne "");
	readingsBulkUpdate($hash, "temperature", $temp) if ($temp ne "");

	readingsEndUpdate($hash, 1); # Notify is done by Dispatch

#	Log3 $name, 5, "Cresta test DoTrigger";
#	DoTrigger($name, "T: ".$temp." H: ".$hum);
	
	return $name;
}

# check crc for incoming message
# in: hex string with encrypted, raw data, starting with 75
# out: 1 for OK, 0 for failed
# sample "75BDBA4AC2BEC855AC0A00"
sub Cresta_crc{
	my $crestahex=shift;
	my @crestabytes=();
	push @crestabytes,0x75; #first byte always 75 and will not be included in decrypt/encrypt!
	#convert to array except for first hex
	for (my $i=1; $i<(length($crestahex))/2; $i++){
		my $hex=Cresta_decryptByte(hex(substr($crestahex, $i*2, 2)));
		push (@crestabytes, $hex);
	}
	my $cs1=0; #will be zero for xor over all (bytes>>1)&0x1F except first byte (always 0x75)
	#my $rawData=shift;
	#todo add the crc check here
	my $count=0;
	$count=($crestabytes[2]>>1) & 0x1f;
	#iterate over data only, first byte is 0x75 always
	for (my $i=1; $i<$count+2; $i++) {
		my $b =  $crestabytes[$i];
		$cs1 = $cs1 ^ $b; # calc first chksum 
	} 
	if($cs1==0){
		return 1;
	}
	else{
		return 0;
	}
}

# return decoded sensor type
# in: one byte
# out: one byte
# Der Typ eines Sensors steckt in Byte 3:
# Byte3 & 0x1F  Device
# 0x0C	      Anemometer
# 0x0D	      UV sensor
# 0x0E	      Rain level meter
# 0x1E	      Thermo/hygro-sensor
sub getSensorType{
	return $_[0] & 0x1F;
}

# decrypt bytes of hex string
# in: hex string
# out: decrypted hex string
sub decryptBytes{
	my $crestahex=shift;
	#create array of hex string
	my @crestabytes=();
	push @crestabytes, 0x75; #first byte is not encrypted and always 0x75
	for (my $i=1; $i<(length($crestahex))/2; $i++){
		my $hex=Cresta_decryptByte(hex(substr($crestahex, $i*2, 2)));
		push (@crestabytes, $hex);
	}
	my $result="";
	for (my $i=0; $i<scalar (@crestabytes); $i++){
		$result.=sprintf("%02x",$crestabytes[$i]);
	}
	return $result;
}

sub Cresta_decryptByte{
	my $byte = shift;
	#printf("\ndecryptByte 0x%02x >>",$byte);
	my $ret2 = ($byte ^ ($byte << 1) & 0xFF); #gives possible overflow to left so c3->145 instead of 45
	#printf(" %02x\n",$ret2);
	return $ret2; 
}

# decode byte array and return channel, temperature and hunidity
# input: decrypted byte array starting with 0x75, passed by reference as in mysub(\@array);
# output <return code>, <channel>, <temperature>, <humidity>
# was unable to get this working with an array ref as input, so switched to hex string input
sub decodeThermoHygro {
	my $crestahex = shift;
	my @crestabytes=();
	for (my $i=0; $i<(length($crestahex))/2; $i++){
		my $hex=hex(substr($crestahex, $i*2, 2)); ## Mit split und map geht es auch ... $str =~ /(..?)/g;
		push (@crestabytes, $hex);
	}
	my $channel=0;
	my $temp=0;
	my $humi=0;

	$channel = $crestabytes[1] >> 5;
	# //Internally channel 4 is used for the other sensor types (rain, uv, anemo).
	# //Therefore, if channel is decoded 5 or 6, the real value set on the device itself is 4 resp 5.
	if ($channel >= 5) {
		$channel--;
	}
	#my $devicetype = $crestabytes[3]&0x1f;
	$temp = 100 * ($crestabytes[5] & 0x0f) + 10 * ($crestabytes[4] >> 4) + ($crestabytes[4] & 0x0f);
	## // temp is negative?
	if (!($crestabytes[5] & 0x80)) {
		$temp = -$temp;
	}

	$humi = 10 * ($crestabytes[6] >> 4) + ($crestabytes[6] & 0x0f);	 

	$temp = $temp / 10;
	return (1, $channel, $temp, $humi);
}

sub
Cresta_Attr(@)
{
  my @a = @_;

  # Make possible to use the same code for different logical devices when they
  # are received through different physical devices.
  return if($a[0] ne "set" || $a[2] ne "IODev");
  my $hash = $defs{$a[1]};
  my $iohash = $defs{$a[3]};
  my $cde = $hash->{CODE};
  delete($modules{Cresta}{defptr}{$cde});
  $modules{Cresta}{defptr}{$iohash->{NAME} . "." . $cde} = $hash;
  return undef;
}

sub
hex2bin($)
{
  my $h = shift;
  my $hlen = length($h);
  my $blen = $hlen * 4;
  return unpack("B$blen", pack("H$hlen", $h));
}

sub
bin2dec($)
{
  my $h = shift;
  my $int = unpack("N", pack("B32",substr("0" x 32 . $h, -32))); 
  return sprintf("%d", $int); 
}
sub
binflip($)
{
  my $h = shift;
  my $hlen = length($h);
  my $i = 0;
  my $flip = "";
  
  for ($i=$hlen-1; $i >= 0; $i--) {
    $flip = $flip.substr($h,$i,1);
  }

  return $flip;
}

1;

=pod
=begin html

<a name="Cresta"></a>
<h3>Cresta</h3>
<ul>
  The Cresta module is a testing and debugging module to decode some devices
  <br><br>

  <a name="Cresta_undefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; Cresta &lt;code&gt; [minsecs] [equalmsg]</code> <br>

    <br>
    &lt;code&gt; is the housecode of the autogenerated address of the Env device and 
	is build by the channelnumber (1 to 3) and an autogenerated address build when including
	the battery (adress will change every time changing the battery).<br>
    minsecs are the minimum seconds between two log entries or notifications
    from this device. <br>E.g. if set to 300, logs of the same type will occure
    with a minimum rate of one per 5 minutes even if the device sends a message
    every minute. (Reduces the log file size and reduces the time to display
    the plots)<br>
	equalmsg set to 1 generates, if even if minsecs is set, a log entrie or notification
	when the msg content has changed.
  </ul>
  <br>

  <a name="Cresta_unset"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="Cresta_unget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="Cresta_unattr"></a>
  <b>Attributes</b>
  <ul>
    <li><a href="#IODev">IODev (!)</a></li>
    <li><a href="#do_not_notify">do_not_notify</a></li>
    <li><a href="#eventMap">eventMap</a></li>
    <li><a href="#ignore">ignore</a></li>
    <li><a href="#model">model</a> (LogiLink Env)</li>
    <li><a href="#showtime">showtime</a></li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
  </ul>
  <br>
</ul>

=end html

=begin html_DE

<a name="Cresta"></a>
<h3>Cresta</h3>
<ul>
  Das Cresta module dekodiert vom Cresta empfangene Nachrichten von Arduino basierten Sensoren.
  <br><br>

  <a name="Cresta_undefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; Cresta &lt;code&gt; [minsecs] [equalmsg]</code> <br>

    <br>
    &lt;code&gt; ist der automatisch angelegte Hauscode des Env und besteht aus der
	Kanalnummer (1..3) und einer Zufallsadresse, die durch das Ger�t beim einlegen der
	Batterie generiert wird (Die Adresse �ndert sich bei jedem Batteriewechsel).<br>
    minsecs definert die Sekunden die mindesten vergangen sein m�ssen bis ein neuer
	Logeintrag oder eine neue Nachricht generiert werden.
    <br>
	Z.B. wenn 300, werden Eintr�ge nur alle 5 Minuten erzeugt, auch wenn das Device
    alle paar Sekunden eine Nachricht generiert. (Reduziert die Log-Dateigr��e und die Zeit
	die zur Anzeige von Plots ben�tigt wird.)<br>
	equalmsg gesetzt auf 1 legt fest, dass Eintr�ge auch dann erzeugt werden wenn die durch
	minsecs vorgegebene Zeit noch nicht verstrichen ist, sich aber der Nachrichteninhalt ge�ndert
	hat.
  </ul>
  <br>

  <a name="Cresta_unset"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="Cresta_unget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="Cresta_unattr"></a>
  <b>Attributes</b>
  <ul>
    <li><a href="#IODev">IODev (!)</a></li>
    <li><a href="#do_not_notify">do_not_notify</a></li>
    <li><a href="#eventMap">eventMap</a></li>
    <li><a href="#ignore">ignore</a></li>
    <li><a href="#model">model</a> (LogiLink Env)</li>
    <li><a href="#showtime">showtime</a></li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
  </ul>
  <br>
</ul>

=end html_DE
=cut
