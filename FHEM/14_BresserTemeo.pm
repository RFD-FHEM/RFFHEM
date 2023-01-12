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


  $hash->{Match}     = "^P44x{0,1}#[A-F0-9]{18}";   # Laenge (Anzahl nibbles nach 0x75 )noch genauer spezifizieren
  $hash->{DefFn}     = \&BresserTemeo_Define;
  $hash->{UndefFn}   = \&BresserTemeo_Undef;
  $hash->{AttrFn}    = \&BresserTemeo_Attr;
  $hash->{ParseFn}   = \&BresserTemeo_Parse;
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
  return ;
}

#####################################
sub
BresserTemeo_Undef($$)
{
  my ($hash, $name) = @_;
  delete($modules{BresserTemeo}{defptr}{$hash->{CODE}}) if($hash && $hash->{CODE});
  return ;
}


#####################################
sub
BresserTemeo_Parse($$)
{
	my ($iohash,$msg) = @_;
	my ($protoid ,$rawData) = split("#",$msg);
	$protoid=~ s/^P(\d+)/$1/; # extract protocol

 	my $binvalue = unpack("B*" ,pack("H*", $rawData));
 
	if (length($binvalue) != 72) {
		Log3 $iohash, 4, "BresserTemeo_Parse length error (72 bits expected)!!!";
		return "";
	}

    # Check what Humidity Prefix (*sigh* Bresser!!!) 
    if ($protoid eq "44")
    {
      $binvalue = "0".$binvalue;
      Log3 $iohash, 4, "BresserTemeo_Parse Humidity <= 79  Flag";
    }
    else
    {
      $binvalue = "1".$binvalue;
      Log3 $iohash, 4, "BresserTemeo_Parse Humidity > 79  Flag";
    }

	Log3 $iohash, 4, "BresserTemeo_Parse new bin $binvalue";
	
	my $checksumOkay = 1;
	
	my $hum;
	my $hum1Dec = SD_WS_binaryToNumber($binvalue, 0, 3);
	my $hum2Dec = SD_WS_binaryToNumber($binvalue, 4, 7);
	my $checkHum1 = SD_WS_binaryToNumber($binvalue, 32, 35) ^ 0b1111;
	my $checkHum2 = SD_WS_binaryToNumber($binvalue, 36, 39) ^ 0b1111;

	if ($checkHum1 != $hum1Dec || $checkHum2 != $hum2Dec)
	{
		Log3 $iohash, 4, "BresserTemeo_Parse checksum error in Humidity";
	}
	else
	{
		$hum = $hum1Dec.$hum2Dec;
		if ($hum < 1 || $hum > 100)
		{
			Log3 $iohash, 4, "BresserTemeo_Parse Humidity Error. Humidity=$hum";
			return "";
		}
	}

	my $temp1Dec = SD_WS_binaryToNumber($binvalue, 21, 23);
	my $temp2Dec = SD_WS_binaryToNumber($binvalue, 24, 27);
	my $temp3Dec = SD_WS_binaryToNumber($binvalue, 28, 31);
	my $checkTemp1 = SD_WS_binaryToNumber($binvalue, 53, 55) ^ 0b111;
	my $checkTemp2 = SD_WS_binaryToNumber($binvalue, 56, 59) ^ 0b1111;
	my $checkTemp3 = SD_WS_binaryToNumber($binvalue, 60, 63) ^ 0b1111;
	my $temp = $temp1Dec.$temp2Dec.".".$temp3Dec;
	
	if ($checkTemp1 != $temp1Dec || $checkTemp2 != $temp2Dec || $checkTemp3 != $temp3Dec)
	{
		Log3 $iohash, 4, "BresserTemeo_Parse checksum error in Temperature";
		$checksumOkay = 0;
	}

	if ($temp > 60)
	{
		Log3 $iohash, 4, "BresserTemeo_Parse Temperature Error. temp=$temp";
		return "";
	}
	
	my $bat = substr($binvalue,9,1);
	my $checkBat = substr($binvalue,41,1) ^ 0b1;
	
	if ($bat != $checkBat)
	{
		Log3 $iohash, 4, "BresserTemeo_Parse checksum error in Bat";
		$bat = undef;
	}
	else
	{
		$bat = ($bat == 0) ? "ok" : "low";
	}
	
	my $channel = SD_WS_binaryToNumber($binvalue, 10, 11);
	my $checkChannel = SD_WS_binaryToNumber($binvalue, 42, 43) ^ 0b11;
	my $id = SD_WS_binaryToNumber($binvalue, 12, 19);
	my $checkId = SD_WS_binaryToNumber($binvalue, 44, 51) ^ 0b11111111;
	
	if ($channel != $checkChannel || $id != $checkId)
	{
		Log3 $iohash, 4, "BresserTemeo_Parse checksum error in Channel or Id";
		$checksumOkay = 0;
	}
	
	if ($checksumOkay == 0)
	{
		Log3 $iohash, 4, "BresserTemeo_Parse checksum error!!! These Values seem incorrect: temp=$temp, channel=$channel, id=$id";
		return "";
	}
	
	my $name = $iohash->{NAME};
	my $deviceCode;
	my $model= "BresserTemeo";

	my $val = "T: $temp H: $hum";
	
	$deviceCode = $model . "_" . $channel;
	
	Log3 $iohash, 4, "$name decoded BresserTemeo protocol model=$model, temp=$temp, hum=$hum, channel=$channel, id=$id, bat=$bat";
	Log3 $iohash, 5, "deviceCode: $deviceCode";
    
	my $def = $modules{BresserTemeo}{defptr}{$iohash->{NAME} . "." . $deviceCode};
	$def = $modules{BresserTemeo}{defptr}{$deviceCode} if(!$def);
    
	if(!$def) {
		Log3 $iohash, 1, 'BresserTemeo: UNDEFINED sensor ' . $model . ' detected, code ' . $deviceCode;
		return "UNDEFINED $deviceCode BresserTemeo $deviceCode";
	}

	my $hash = $def;
	$name = $hash->{NAME};
	return "" if(IsIgnored($name));

	if (!defined(AttrVal($hash->{NAME},"event-min-interval",undef)))
	{
		my $minsecs = AttrVal($iohash->{NAME},'minsecs',0);
		if($hash->{lastReceive} && (time() - $hash->{lastReceive} < $minsecs)) {
			Log3 $iohash, 4, "$deviceCode Dropped due to short time. minsecs=$minsecs";
		  	return "";
		}
	}
	$hash->{lastReceive} = time();

	$def->{lastMSG} = $rawData;

	readingsBeginUpdate($hash);
	readingsBulkUpdate($hash, "state", $val);
	readingsBulkUpdate($hash, "battery", $bat) if (defined($bat));
	readingsBulkUpdate($hash, "channel", $channel) if (defined($channel));
	readingsBulkUpdate($hash, "humidity", $hum) if (defined($hum));
	readingsBulkUpdate($hash, "temperature", $temp) if (defined($temp));
	readingsEndUpdate($hash, 1); # Notify is done by Dispatch

	return $name;
}


sub SD_WS_binaryToNumber
{
	my $binstr=shift;
	my $fbit=shift;
	my $lbit=$fbit;
	$lbit=shift if @_;
	
	return oct("0b".substr($binstr,$fbit,($lbit-$fbit)+1));
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
  return ;
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
