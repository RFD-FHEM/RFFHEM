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
	my @a = split("", $msg);
	my $name = $hash->{NAME};
	Log3 $hash, 4, "$name incomming $msg";
	my $rawData=substr($msg,2); ## Copy all expect of the message length header
	
	#Convert hex to bit, may not needed
	my $hlen = length($rawData);
	my $blen = $hlen * 4;
	my $bitData= unpack("B$blen", pack("H$hlen", $rawData)); 
	Log3 $hash, 4, "$name converted to bits: $bitData";

	
	if (!Cresta_crc($rawData))
	{
		Log3 $hash, 4, "$name crc failed";
		return "$name crc failed";
	}
	
	my $SensorTyp;
	my $id;
	my $channel;
	my $temp;
	my $hum;
	my $rc;
	my $model;
	## 1. Detect what type of sensor we have, then calll specific function to decode
	if ($msg =~ m/^50/) {
		($rc,$channel, $temp, $hum) = decodeThermoHygro($rawData);
		$model="th";  
	} elsif ($msg =~ m/^58/) {
		($rc,$channel, $temp, $hum) = decodeThermoHygro($rawData);
		$model="th";
	}
	#my @testdata1 = ("58753DBACAEEBEDD55953900", "58753DBA8AEEBEDD55D50300", "50753DBA8AEEBEDD55D503", "5875E2BA8A80BFD1AD915400", "58753DBA4AEEBEDD55151500", "5875E2BA4A80BFD1AD514200", "5875E2BACAD7BFD1AD861000", "287555500500", "58753DBA4AEFBEDD55146D00", "50753DBA8AEFBEDD55D400", "5075D3BA8ACDBEC851092F");
	#my @testdata2 = ("0075C3BACA7DBFCF51EF","0075C3BA8A7DBFCF51AF","0075C3BA4A7DBFCF516F");
	#my @testdata2decrpyted= ("7545CE5E87C151F3EF","7545CE9E87C151F3AF","7545CEDE87C151F36F");

	#my ($i, $data, @decoded);

	#print("Cresta ThermoHygro Test\n");

	#print("Testdata by RF_Receiver:\n");
	#for($i=0; $i < scalar(@testdata1); $i++){
	#	$data = @testdata1[$i]; 
	#	@decoded = &decodeThermoHygro($data,$c,$t,$h);
	#	printf ("data: data id: %i, channel: %i, temp: %.1f, humi: %i\n", $i, $decoded[1], ($decoded[2] / 10) + ($decoded[2] % 10), $decoded[3]);
	#}

	#print("===========================\nTestdata by RemoteSensor:\n");
	#for($i=0; $i < scalar(@testdata2); $i++){
	#	$data = @testdata2[$i]; 
	#	@decoded = &decodeThermoHygro($data,$c,$t,$h);
	#	printf ("data: data id: %i, channel: %i, temp: %.1f, humi: %i\n", $i, $decoded[1], (, $decoded[3]);
	#}


	if ($rc != 1)
	{
		Log3 $hash, 4, "$name error, decoding Cresta protocol" ;
		return "UNDEFINED $SensorTyp error, decoding Cresta protocol";
	}
        my $deviceCode="";
	Log3 $hash, 4, "$name decoded Cresta protocol   $SensorTyp, sensor id=$id, channel=$channel, temp=$temp\n" ;
	if ($id ne "") {
	$deviceCode = $model."_".$id;
	}

	my $def = $modules{Cresta}{defptr}{$hash->{NAME} . "." . $deviceCode};
	$def = $modules{Cresta}{defptr}{$deviceCode} if(!$def);

	if(!$def) {
	Log3 $hash, 1, "Cresta: UNDEFINED sensor $SensorTyp detected, code $deviceCode";
	return "UNDEFINED $SensorTyp"."_"."$deviceCode Cresta $deviceCode";
	}

	$hash = $def;
	#my $name = $hash->{NAME};
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

	Log3 $name, 4, "Cresta $name:". $name;

	readingsBeginUpdate($hash);
	#readingsBulkUpdate($hash, "state", $val);
	#readingsBulkUpdate($hash, "battery", $bat)   if ($bat ne "");
	#readingsBulkUpdate($hash, "trigger", $trigger) if ($trigger ne "");
	readingsBulkUpdate($hash, "hum", $hum) if ($hum ne "");
	readingsBulkUpdate($hash, "temp", $temp) if ($temp ne "");

	readingsEndUpdate($hash, 1); # Notify is done by Dispatch

	return $name;
}

sub Cresta_crc{
	my $rawData=shift;
	#todo add the crc check here
	
	return 1;
}

sub Cresta_decryptByte{
	my $byte = shift;
	#printf("\ndecryptByte 0x%02x >>",$byte);
	my $ret2 = ($byte ^ ($byte << 1) & 0xFF); #gives possible overflow to left so c3->145 instead of 45
	#printf(" %02x\n",$ret2);
	return $ret2; 
}

sub decodeThermoHygro {
	my $crestahex = shift; # function arg is hey string
	my $channel;
	my $temp;
	my $humi;
	my @crestabytes;#  = map { pack('C', hex($_)) } ($crestahex =~ /(..)/g);
	for (my $i=0; $i<(length($crestahex))/2; $i++){
		my $hex=hex(substr($crestahex, $i*2, 2));
		push (@crestabytes, $hex);
	}
	# (read and remove first element)
	my $len = shift @crestabytes; 

	#printf ("0x%02X ", $crestabytes[0]);
	if($crestabytes[0] == 0x75){  ##Das brauchen wir nicht mehr prüfen, das macht schon die regex im Modul match
		my @decrypted;
		my $idx=0;
		$decrypted[0]=$crestabytes[0];
		for($idx=1; $idx<7; ($idx)++) {
			$decrypted[$idx]=$crestabytes[$idx];
			$crestabytes[$idx]=&decryptByte($decrypted[$idx]);
		}
		
	}

	$channel = $crestabytes[1] >> 5;
	# //Internally channel 4 is used for the other sensor types (rain, uv, anemo).
	# //Therefore, if channel is decoded 5 or 6, the real value set on the device itself is 4 resp 5.
	if ($channel >= 5) {
		$channel--;
	}
	my $devicetype = $crestabytes[3]&0x1f;
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
	Kanalnummer (1..3) und einer Zufallsadresse, die durch das Gerät beim einlegen der
	Batterie generiert wird (Die Adresse ändert sich bei jedem Batteriewechsel).<br>
    minsecs definert die Sekunden die mindesten vergangen sein müssen bis ein neuer
	Logeintrag oder eine neue Nachricht generiert werden.
    <br>
	Z.B. wenn 300, werden Einträge nur alle 5 Minuten erzeugt, auch wenn das Device
    alle paar Sekunden eine Nachricht generiert. (Reduziert die Log-Dateigröße und die Zeit
	die zur Anzeige von Plots benötigt wird.)<br>
	equalmsg gesetzt auf 1 legt fest, dass Einträge auch dann erzeugt werden wenn die durch
	minsecs vorgegebene Zeit noch nicht verstrichen ist, sich aber der Nachrichteninhalt geändert
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
