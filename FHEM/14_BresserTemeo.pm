##############################################
# $Id$
# The file is taken from the SIGNALduino project
# see http://www.fhemwiki.de/wiki/SIGNALduino
# and was modified by a few additions
# to support BresserTemeo Sensors
# S. Butzek & HJGode & Ralf9 2015-2016
# B. Plutka 2016

package main;

use strict;
use warnings;
use POSIX;

#use Data::Dumper;

#####################################
sub
BresserTemeo_Initialize($)
{
  my ($hash) = @_;


  $hash->{Match}     = "^u(44|51)#[A-F0-9]{17,19}";   # Laenge (Anzahl nibbles nach 0x75 )noch genauer spezifizieren
  $hash->{DefFn}     = "BresserTemeo_Define";
  $hash->{UndefFn}   = "BresserTemeo_Undef";
  $hash->{AttrFn}    = "BresserTemeo_Attr";
  $hash->{ParseFn}   = "BresserTemeo_Parse";
  $hash->{AttrList}  = "IODev do_not_notify:0,1 showtime:0,1 "
                       ."ignore:0,1 "
                      ." $readingFnAttributes";
                      
  $hash->{AutoCreate}=
        { "BresserTemeo.*" => { ATTR => "event-min-interval:.*:300 event-on-change-reading:.*", FILTER => "%NAME", GPLOT => "temp4hum4:Temp/Hum,", autocreateThreshold => "2:180"} };

}


#####################################
sub
BresserTemeo_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);

  return "wrong syntax: define <name> BresserTemeo <code>".int(@a)
		if(int(@a) < 3);

  $hash->{CODE}    = $a[2];
  $hash->{lastMSG} =  "";

  my $name= $hash->{NAME};

  $modules{BresserTemeo}{defptr}{$a[2]} = $hash;
  $hash->{STATE} = "Defined";

  #AssignIoPort($hash);
  return undef;
}

#####################################
sub
BresserTemeo_Undef($$)
{
  my ($hash, $name) = @_;
  delete($modules{BresserTemeo}{defptr}{$hash->{CODE}}) if($hash && $hash->{CODE});
  return undef;
}


#####################################
sub
BresserTemeo_Parse($$)
{
	my ($iohash,$msg) = @_;
	my (undef ,$rawData) = split("#",$msg);

	my $prefix = substr $msg, 0, 3;

  my $binvalue = "";
	my $hexvalue =  substr $msg, 4;
    #my $bin2 = sprintf( "%b", hex( $hexvalue ) );
  $binvalue = unpack("B*" ,pack("H*", $hexvalue));
	if (length($binvalue) != 72)
    {
        Log3 $iohash, 4, "BresserTemeo_Parse length error (72 bits expected)!!!";
        return "";
    }
    # Check what Humidity Prefix (*sigh* Bresser!!!) 
    if ($prefix eq "u44")
    {
      $binvalue = "0".$binvalue;
      Log3 $iohash, 4, "BresserTemeo_Parse Humidity <= 79  Flag";
    }
    else
    {
      $binvalue = "1".$binvalue;
      Log3 $iohash, 4, "BresserTemeo_Parse Humidity > 79  Flag";
    }

    my $checksumOkay = 1;
	
	my $hum1 = substr $binvalue, 0, 4;
	my $hum1Dec = oct( "0b$hum1" );
	my $hum2 = substr $binvalue, 4, 4;
	my $hum2Dec = oct( "0b$hum2" );
	my $hum = $hum1Dec.$hum2Dec;

    my $checksumHum1 = substr $binvalue, 32,4;
    my $chum1 =oct ("0b$checksumHum1");
    my $checkHum1 = oct ("0b$checksumHum1") ^ 0b1111;
    if ($checkHum1 != $hum1Dec)
    {
        Log3 $iohash, 4, "BresserTemeo_Parse checksum error in Hum 1";
        $checksumOkay = 0;
    }
    
    my $checksumHum2 = substr $binvalue, 36,4;
    my $checkHum2 = oct ("0b$checksumHum2") ^ 0b1111;
    if ($checkHum2 != $hum2Dec)
    {
        Log3 $iohash, 4, "BresserTemeo_Parse checksum error in Hum 2";
        $checksumOkay = 0;
    }
    
	Log3 $iohash, 4, "BresserTemeo_Parse new bin $binvalue";

	my $temp1 = substr $binvalue, 20,4;
	my $temp1Dec = oct( "0b$temp1" );
	my $temp2 = substr $binvalue, 24,4;
	my $temp2Dec = oct( "0b$temp2" );
	my $temp3 = substr $binvalue, 28,4;
	my $temp3Dec = oct( "0b$temp3" );
	my $temp = $temp1Dec.$temp2Dec.".".$temp3Dec;

	my $checksumTemp1 = substr $binvalue, 52,4;
    my $checkTemp1 = oct ("0b$checksumTemp1") ^ 0b1111;
    if ($checkTemp1 != $temp1Dec)
    {
        Log3 $iohash, 4, "BresserTemeo_Parse checksum error in Temp 1";
        $checksumOkay = 0;
    }

    my $checksumTemp2 = substr $binvalue, 56,4;
    my $checkTemp2 = oct ("0b$checksumTemp2") ^ 0b1111;
    if ($checkTemp2 != $temp2Dec)
    {
        Log3 $iohash, 4, "BresserTemeo_Parse checksum error in Temp 2";
        $checksumOkay = 0;
    }
    
    my $checksumTemp3 = substr $binvalue, 60,4;
    my $checkTemp3 = oct ("0b$checksumTemp3") ^ 0b1111;
    if ($checkTemp3 != $temp3Dec)
    {
        Log3 $iohash, 4, "BresserTemeo_Parse checksum error in Temp 3";
        $checksumOkay = 0;
    }

    if ($temp+0 > 60.)
    {
      Log3 $iohash, 4, "BresserTemeo_Parse Temperature Error";
      $checksumOkay = 0;
    }
    
    if ($hum+0 > 100.)
    {
      Log3 $iohash, 4, "BresserTemeo_Parse Humidity Error";
      $checksumOkay = 0;
    }

    if ($checksumOkay == 0)
    {
        Log3 $iohash, 4, "BresserTemeo_Parse checksum error!!! These Values seem incorrect: temp=$temp, humidity=$hum";
        return "";
        
    }
    
	my $name = $iohash->{NAME};
	my @a = split("", $msg);
	Log3 $iohash, 4, "BresserTemeo_Parse $name incoming $msg";

	# decrypt bytes
	my $decodedString = decryptBytes($rawData); # decrpyt hex string to hex string

	#convert dectypted hex str back to array of bytes:
	my @decodedBytes  = map { hex($_) } ($decodedString =~ /(..)/g);

	if (!@decodedBytes)
	{
		Log3 $iohash, 4, "$name decrypt failed";
		return undef;
	}
	
    my $sensorTyp=0x1E; # Fixed Value!
	Log3 $iohash, 4, "BresserTemeo_Parse SensorTyp = $sensorTyp decodedString = $decodedString";

	my $id=substr($decodedString,2,2);      # get the random id from the data
	my $channel=0;
	#my $temp=0;
	#my $hum=0;
	my $rain=0;
	my $rc = 0;
	my $val = 0;
	my $bat = 0;
	my $deviceCode = 0;
	my $model= "BresserTemeo_$sensorTyp";
	$val = "T: $temp H: $hum";
    Log3 $iohash, 4, "$name decoded BresserTemeo protocol model=$model, temp=$temp, humidity=$hum";
	Log3 $iohash, 5, "deviceCode: $deviceCode";

    $deviceCode = $model . "_" . $channel;
    
	my $def = $modules{BresserTemeo}{defptr}{$iohash->{NAME} . "." . $deviceCode};
	$def = $modules{BresserTemeo}{defptr}{$deviceCode} if(!$def);
    
	if(!$def) {
		Log3 $iohash, 1, "BresserTemeo: UNDEFINED sensor $sensorTyp detected, code $deviceCode";
		return "UNDEFINED $deviceCode BresserTemeo $deviceCode";
	}

	my $hash = $def;
	$name = $hash->{NAME};
	return "" if(IsIgnored($name));

	if (!defined(AttrVal($hash->{NAME},"event-min-interval",undef)))
	{
		my $minsecs = AttrVal($iohash->{NAME},'minsecs',0);
		if($hash->{lastReceive} && (time() - $hash->{lastReceive} < $minsecs)) {
			Log3 $iohash, 4, "$deviceCode Dropped ($decodedString) due to short time. minsecs=$minsecs";
		  	return "";
		}
	}
	$hash->{lastReceive} = time();

	$def->{lastMSG} = $decodedString;

	readingsBeginUpdate($hash);
	readingsBulkUpdate($hash, "state", $val);
	readingsBulkUpdate($hash, "message", $msg);
	readingsBulkUpdate($hash, "binvalue", $binvalue);
	readingsBulkUpdate($hash, "humidity", $hum) if ($hum ne "");
	readingsBulkUpdate($hash, "temperature", $temp) if ($temp ne "");
	readingsEndUpdate($hash, 1); # Notify is done by Dispatch

	return $name;
}

# decrypt bytes of hex string
# in: hex string
# out: decrypted hex string
sub decryptBytes{
	my $BresserTemeohex=shift;
	#create array of hex string
	my @BresserTemeobytes  = map { BresserTemeo_decryptByte(hex($_)) } ($BresserTemeohex =~ /(..)/g);

	my $result="44";  # Byte 0 is not encrypted
	for (my $i=1; $i<scalar (@BresserTemeobytes); $i++){
		$result.=sprintf("%02x",$BresserTemeobytes[$i]);
	}
	return $result;
}

sub BresserTemeo_decryptByte{
	my $byte = shift;
	my $ret2 = ($byte ^ ($byte << 1) & 0xFF); #gives possible overflow to left so c3->145 instead of 45
	return $ret2;
}

sub
BresserTemeo_Attr(@)
{
  my @a = @_;

  # Make possible to use the same code for different logical devices when they
  # are received through different physical devices.
  return if($a[0] ne "set" || $a[2] ne "IODev");
  my $hash = $defs{$a[1]};
  my $iohash = $defs{$a[3]};
  my $cde = $hash->{CODE};
  delete($modules{BresserTemeo}{defptr}{$cde});
  $modules{BresserTemeo}{defptr}{$iohash->{NAME} . "." . $cde} = $hash;
  return undef;
}


1;

=pod
=begin html

<a name="BresserTemeo"></a>
<h3>BresserTemeo</h3>
<ul>
  The BresserTemeo module is a module for decoding weather sensors, which use the BresserTemeo protocol.
  <br><br>

  <a name="BresserTemeo_define"></a>
  <b>Supported Brands</b>
  <ul>
  	<li>BresserTemeo (7009995)</li>
  </ul>
  Please note, currently temp/hum devices are implemented. Please report data for other sensortypes.

  <a name="BresserTemeo_define"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; BresserTemeo &lt;code&gt; </code> <br>

    <br>
    &lt;code&gt; is the address of the sensor device and
	is build by the sensor type and the channelnumber (1 to 5) or if the attribute longid is specfied an autogenerated address build when inserting
	the battery (this adress will change every time changing the battery).<br>
	
	If autocreate is enabled, the device will be defined via autocreate. This is also the preferred mode of defining such a device.

  </ul>
  <a name="BresserTemeo_readings"></a>
  <b>Generated readings</b>
  <ul>
  	<li>state (T:x H:y)</li>
	<li>temperature (&deg;C)</li>
	<li>humidity (0-100)</li>
	<li>channel (The Channelnumber (number if)</li>
  </ul>
  
  
  <a name="BresserTemeo_unset"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="BresserTemeo_unget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="BresserTemeo_attr"></a>
  <b>Attributes</b>
  <ul>
    <li><a href="#do_not_notify">do_not_notify</a></li>
    <li><a href="#eventMap">eventMap</a></li>
    <li><a href="#ignore">ignore</a></li>
    <li><a href="#showtime">showtime</a></li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
  </ul>
  <br>
</ul>

=end html

=begin html_DE

<a name="BresserTemeo"></a>
<h3>BresserTemeo</h3>
<ul>
  Das BresserTemeo module dekodiert empfangene Nachrichten von Wettersensoren, welche das BresserTemeo Protokoll verwenden.
  <br><br>
  
  <a name="BresserTemeo_define"></a>
  <b>Unterstuetzte Hersteller</b>
  <ul>
    <li>BresserTemeo (7009995)</li>
  </ul>
  Hinweis, Aktuell sind nur temp/feuchte Sensoren implementiert. Bitte sendet uns Daten zu anderen Sensoren.
  
  <a name="BresserTemeo_define"></a>
  <b>Define</b>
  <ul>
  	<li><code>define &lt;name&gt; BresserTemeo &lt;code&gt; </code></li>
	<li>
    <br>
    &lt;code&gt; besteht aus dem Sensortyp und der Kanalnummer (1..5) oder wenn das Attribut longid im IO Device gesetzt ist aus einer Zufallsadresse, die durch den Sensor beim einlegen der
	Batterie generiert wird (Die Adresse aendert sich bei jedem Batteriewechsel).<br>
    </li>
    <li>Wenn autocreate aktiv ist, dann wird der Sensor automatisch in FHEM angelegt. Das ist der empfohlene Weg, neue Sensoren hinzuzufuegen.</li>
   
  </ul>
  <br>

  <a name="BresserTemeo_readings"></a>
  <b>Erzeugte Readings</b>
  <ul>
  	<li>state (T:x H:y)</li>
	<li>temperature (&deg;C)</li>
	<li>humidity (0-100)</li>
	<li>channel (Der Sensor Kanal)</li>
  </ul>
  <a name="BresserTemeo_unset"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="BresserTemeo_unget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="BresserTemeo_attr"></a>
  <b>Attribute</b>
  <ul>
    <li><a href="#do_not_notify">do_not_notify</a></li>
    <li><a href="#eventMap">eventMap</a></li>
    <li><a href="#ignore">ignore</a></li>
    <li><a href="#showtime">showtime</a></li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
  </ul>
  <br>
</ul>

=end html_DE
=cut
