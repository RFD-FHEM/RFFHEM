##############################################
# $Id: 14_Hideki.pm 1003 2015-10-03 $
# The file is taken from the SIGNALduino project
# see http://www.fhemwiki.de/wiki/SIGNALduino
# and was modified by a few additions
# to support Hideki Sensors
# S. Butzek & HJGode  2015
#

package main;

use strict;
use warnings;
use POSIX;

#use Data::Dumper;

#####################################
sub
Hideki_Initialize($)
{
  my ($hash) = @_;


  $hash->{Match}     = "^[5][0|8]75[A-F0-9]+";   # GGF. noch weiter anpassen
  $hash->{DefFn}     = "Hideki_Define";
  $hash->{UndefFn}   = "Hideki_Undef";
  $hash->{AttrFn}    = "Hideki_Attr";
  $hash->{ParseFn}   = "Hideki_Parse";
  $hash->{AttrList}  = "IODev do_not_notify:0,1 showtime:0,1 "
                       ."ignore:0,1 "
                       ."$readingFnAttributes";
}


#####################################
sub
Hideki_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);

  return "wrong syntax: define <name> Hideki <code>".int(@a)
		if(int(@a) < 3 || int(@a) > 5);

  $hash->{CODE}    = $a[2];
  $hash->{lastMSG} =  "";

  my $name= $hash->{NAME};

  $modules{Hideki}{defptr}{$a[2]} = $hash;
  $hash->{STATE} = "Defined";

  AssignIoPort($hash);

  my $iohash = $hash->{IODev};
  if (!defined($attr{$iohash->{NAME}}{minsecs}))    # if sduino minsecs not defined
  {
    $attr{$name}{"event-min-interval"} = ".*:300";
    $attr{$name}{"event-on-change-reading"} = ".*";
  }
  return undef;
}

#####################################
sub
Hideki_Undef($$)
{
  my ($hash, $name) = @_;
  delete($modules{Hideki}{defptr}{$hash->{CODE}}) if($hash && $hash->{CODE});
  return undef;
}


#####################################
sub
Hideki_Parse($$)
{
	my ($iohash,$msg) = @_;

	my $name = $iohash->{NAME};
	my @a = split("", $msg);
	Log3 $iohash, 4, "Hideki_Parse $name incomming $msg";
	my $rawData=substr($msg,2); ## Copy all expect of the message length header

	# decrypt bytes
	my $decodedString = decryptBytes($rawData); # decrpyt hex string to hex string

	#convert dectypted hex str back to array of bytes:
	my @decodedBytes  = map { hex($_) } ($decodedString =~ /(..)/g);

	if (!@decodedBytes)
	{
		Log3 $iohash, 4, "$name decrypt failed";
		return "$name decrypt failed";
	}
	if (!Hideki_crc(\@decodedBytes))
	{
		Log3 $iohash, 4, "$name crc failed";
		return "$name crc failed";
	}
	my $sensorTyp=getSensorType($decodedBytes[3]);
	Log3 $iohash, 4, "Hideki_Parse SensorTyp = $sensorTyp decodedString = $decodedString";
	my $id=substr($decodedString,2,2);      # get the random id from the data
	my $channel=0;
	my $temp=0;
	my $hum=0;
	my $rc;
	my $val;
	my $bat;
	my $deviceCode;
	my $model= "Hideki_$sensorTyp";

	## 1. Detect what type of sensor we have, then calll specific function to decode
	if ($sensorTyp==0x1E){
		($channel, $temp, $hum) = decodeThermoHygro(\@decodedBytes); # decodeThermoHygro($decodedString);
		$bat = ($decodedBytes[2] >> 6 == 3) ? 'ok' : 'low';			 # decode battery
		$val = "T: $temp H: $hum Bat: $bat";
	}else{
		Log3 $iohash, 4, "$name Sensor Typ $sensorTyp not supported, please report sensor information!";
		return "$name Sensor Typ $sensorTyp not supported, please report sensor information!";
	}

	my $longids = $attr{$iohash->{NAME}}{longids};
	if (defined($longids) && ($longids eq "1" || $longids eq "ALL" || (",$longids," =~ m/,$model,/)))
	{
		$deviceCode = $model . "_" . $id;
		Log3 $iohash,4, "$name using longid: $longids model: $model";
	} else {
		$deviceCode = $model . "_" . $channel;
	}

	Log3 $iohash, 4, "$name decoded Hideki protocol model=$model, sensor id=$id, channel=$channel, temp=$temp, humidity=$hum, bat=$bat";
	Log3 $iohash, 5, "deviceCode: $deviceCode";

	my $def = $modules{Hideki}{defptr}{$iohash->{NAME} . "." . $deviceCode};
	$def = $modules{Hideki}{defptr}{$deviceCode} if(!$def);

	if(!$def) {
		Log3 $iohash, 1, "Hideki: UNDEFINED sensor $sensorTyp detected, code $deviceCode";
		return "UNDEFINED $deviceCode Hideki $deviceCode";
	}

	my $hash = $def;
	$name = $hash->{NAME};
	return "" if(IsIgnored($name));

	#Log3 $name, 4, "Hideki: $name ($msg)";

	my $minsecs = $attr{$iohash->{NAME}}{minsecs};
	if (defined($minsecs) && $minsecs > 0) {
		if($hash->{lastReceive} && (time() - $hash->{lastReceive} < $minsecs)) {
			Log3 $iohash, 4, "$deviceCode Dropped ($decodedString) due to short time. minsecs=$minsecs";
	  		return "";
		}
	}
	$hash->{lastReceive} = time();

	$def->{lastMSG} = $decodedString;

	#Log3 $name, 4, "Hideki update $name:". $name;

	readingsBeginUpdate($hash);
	readingsBulkUpdate($hash, "state", $val);
	readingsBulkUpdate($hash, "battery", $bat)   if ($bat ne "");
	readingsBulkUpdate($hash, "humidity", $hum) if ($hum ne "");
	readingsBulkUpdate($hash, "temperature", $temp) if ($temp ne "");
	readingsEndUpdate($hash, 1); # Notify is done by Dispatch

	return $name;
}

# check crc for incoming message
# in: hex string with encrypted, raw data, starting with 75
# out: 1 for OK, 0 for failed
# sample "75BDBA4AC2BEC855AC0A00"
sub Hideki_crc{
	#my $Hidekihex=shift;
	#my @Hidekibytes=shift;

	my @Hidekibytes = @{$_[0]};
	#push @Hidekibytes,0x75; #first byte always 75 and will not be included in decrypt/encrypt!
	#convert to array except for first hex
	#for (my $i=1; $i<(length($Hidekihex))/2; $i++){
    #	my $hex=Hideki_decryptByte(hex(substr($Hidekihex, $i*2, 2)));
	#	push (@Hidekibytes, $hex);
	#}

	my $cs1=0; #will be zero for xor over all (bytes>>1)&0x1F except first byte (always 0x75)
	#my $rawData=shift;
	#todo add the crc check here

	my $count=($Hidekibytes[2]>>1) & 0x1f;
	my $b;
	#iterate over data only, first byte is 0x75 always
	for (my $i=1; $i<$count+2; $i++) {
		$b =  $Hidekibytes[$i];
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
	my $Hidekihex=shift;
	#create array of hex string
	my @Hidekibytes  = map { Hideki_decryptByte(hex($_)) } ($Hidekihex =~ /(..)/g);

	my $result="75";  # Byte 0 is not encrypted
	for (my $i=1; $i<scalar (@Hidekibytes); $i++){
		$result.=sprintf("%02x",$Hidekibytes[$i]);
	}
	return $result;
}

sub Hideki_decryptByte{
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
	my @Hidekibytes = @{$_[0]};

	#my $Hidekihex = shift;
	#my @Hidekibytes=();
	#for (my $i=0; $i<(length($Hidekihex))/2; $i++){
	#	my $hex=hex(substr($Hidekihex, $i*2, 2)); ## Mit split und map geht es auch ... $str =~ /(..?)/g;
	#	push (@Hidekibytes, $hex);
	#}
	my $channel=0;
	my $temp=0;
	my $humi=0;

	$channel = $Hidekibytes[1] >> 5;
	# //Internally channel 4 is used for the other sensor types (rain, uv, anemo).
	# //Therefore, if channel is decoded 5 or 6, the real value set on the device itself is 4 resp 5.
	if ($channel >= 5) {
		$channel--;
	}
	my $sensorId = $Hidekibytes[1] & 0x1f;  		# Extract random id from sensor
	#my $devicetype = $Hidekibytes[3]&0x1f;
	$temp = 100 * ($Hidekibytes[5] & 0x0f) + 10 * ($Hidekibytes[4] >> 4) + ($Hidekibytes[4] & 0x0f);
	## // temp is negative?
	if (!($Hidekibytes[5] & 0x80)) {
		$temp = -$temp;
	}

	$humi = 10 * ($Hidekibytes[6] >> 4) + ($Hidekibytes[6] & 0x0f);

	$temp = $temp / 10;
	return ($channel, $temp, $humi);
}

sub
Hideki_Attr(@)
{
  my @a = @_;

  # Make possible to use the same code for different logical devices when they
  # are received through different physical devices.
  return if($a[0] ne "set" || $a[2] ne "IODev");
  my $hash = $defs{$a[1]};
  my $iohash = $defs{$a[3]};
  my $cde = $hash->{CODE};
  delete($modules{Hideki}{defptr}{$cde});
  $modules{Hideki}{defptr}{$iohash->{NAME} . "." . $cde} = $hash;
  return undef;
}


1;

=pod
=begin html

<a name="Hideki"></a>
<h3>Hideki</h3>
<ul>
  The Hideki module is a module for deconding weather sensors, which use the hideki protocol. Known brands are Bresser, Cresta and Hama.
  <br><br>

  <a name="Hideki_undefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; Hideki &lt;code&gt; </code> <br>

    <br>
    &lt;code&gt; is the housecode of the autogenerated address of the sensor device and
	is build by the channelnumber (1 to 5) or if the attribute longid is specfied an autogenerated address build when inserting
	the battery (this adress will change every time changing the battery).<br>

  </ul>
  <br>

  <a name="Hideki_unset"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="Hideki_unget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="Hideki_unattr"></a>
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

<a name="Hideki"></a>
<h3>Hideki</h3>
<ul>
  Das Hideki module dekodiert vom Hideki empfangene Nachrichten von Wettersensoren. Bekannte Hersteller sind Cresta, Hama und Bresser.
  <br><br>

  <a name="Hideki_undefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; Hideki &lt;code&gt; </code> <br>

    <br>
    &lt;code&gt; ist der automatisch angelegte Hauscode des Env und besteht aus einer
	Kanalnummer (1..5) oder wenn longid gesetzt ist aus einer Zufallsadresse, die durch das Geraet beim einlegen der
	Batterie generiert wird (Die Adresse aendert sich bei jedem Batteriewechsel).<br>
    minsecs definert die Sekunden die mindesten vergangen sein muessen bis ein neuer
	Logeintrag oder eine neue Nachricht generiert werden.
    <br>
  </ul>
  <br>

  <a name="Hideki_unset"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="Hideki_unget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="Hideki_unattr"></a>
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
