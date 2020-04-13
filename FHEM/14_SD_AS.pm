##############################################
# $Id: 14_SD_AS.pm 3.4.3 2016-24-01 00:16:11
# The file is part of the SIGNALduino project
# see http://www.fhemwiki.de/wiki/SIGNALduino
# and was created to provide support for self build sensors.
# The purpos is to use it as addition to the SIGNALduino
# modules in combination with RFDuino
# N. Butzek, S. Butzek, 2014 
#

package main;
#use version 0.77; our $VERSION = version->declare('v3.4.3');

use strict;
use warnings;
use POSIX;

#####################################
sub
SD_AS_Initialize($)
{
  my ($hash) = @_;

  #FHEM Schnittstelle:
  #    ASTTIIDDDDCC
  # AS  - Arduino Sensor
  # TT  - Bit 0..6 type
  #	- Bit 7 trigger (0 auto, 1 manual)
  # II  - Bit 0..5 id
  #	- Bit 6,7 battery status (00 - bad, 01 - change, 10 - ok, 11 - optimal)
  # DD1 - LowByte
  # DD2 - HighByte
  # CC  -  Dallas (now Maxim) iButton 8-bit CRC calculation
  #-----------------------------
  # T	Type:
  # 0
  # 1
  # 2
  # 3   light hirange (outdoor)
  # 4	light hires (indoor)
  # 5	water
  # 6	temp
  # 7	reed gas
  # 8    voltage
  # 9   Humidity
  # ..31 
  $hash->{Match}     = "^P2#[A-Fa-f0-9]{7,8}";
  $hash->{DefFn}     = "SD_AS_Define";
  $hash->{UndefFn}   = "SD_AS_Undef";
  $hash->{ParseFn}   = "SD_AS_Parse";
  $hash->{AttrList}  = "do_not_notify:0,1 showtime:0,1 ignore:0,1 ".$readingFnAttributes;
  $hash->{AutoCreate}=
        { 
          "ArduinoSensor_temp.*" => { ATTR => "event-min-interval:.*:300 event-on-change-reading:.*", FILTER => "%NAME", GPLOT => "temp4:Temp,", autocreateThreshold => "2:600"},
          "ArduinoSensor_humidity.*" => { ATTR => "event-min-interval:.*:300 event-on-change-reading:.*", FILTER => "%NAME", GPLOT => "temp4hum4:Temp/Hum,", autocreateThreshold => "2:600"},
          "ArduinoSensor_reedGas.*" => { ATTR => "event-min-interval:.*:1 event-on-change-reading:.*", FILTER => "%NAME", autocreateThreshold => "2:600"},
          "ArduinoSensor_voltage.*" => { ATTR => "event-min-interval:.*:300 event-on-change-reading:.*", FILTER => "%NAME", autocreateThreshold => "2:600"},
        };
}


#####################################
sub
SD_AS_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);

  return "wrong syntax: define <name> SD_AS <code>".int(@a)
		if(int(@a) != 3);

  $hash->{CODE}    = $a[2];
  $hash->{lastMSG} =  "";
  $hash->{bitMSG} =  "";

  $modules{AS}{defptr}{$a[2]} = $hash;
  $hash->{STATE} = "Defined";

  return undef;
}

#####################################
sub
SD_AS_Undef($$)
{
  my ($hash, $name) = @_;
  delete($modules{AS}{defptr}{$hash->{CODE}}) if($hash && $hash->{CODE});
  return undef;
}

#####################################
sub
SD_AS_Parse($$)
{
  	my ($iohash,$msg) = @_;
 	my (undef ,$rawData) = split("#",$msg);
	my $name = $iohash->{NAME};

	
  if (length($rawData) < 8) {
    Log3 $iohash, 4, "SD_AS: wrong message -> $rawData";
    return "";
  }
  ### CRC Check only if more than 10 characters for backward compatibility ###
  if (length($rawData) > 8) {
	my $i;
	my $crc = 0x0;
	my $byte;
	
    for ($i = 2; $i <= 8; $i+=2) {
      #convert pairs of hex digits into number for Bytes 0-3 only!
      $byte = hex(substr $rawData, $i, 2);
      $crc=SD_AS_crc($crc,$byte);
	}
	my $crc8;
	$crc8 = substr($rawData,-2);  ## Get last two Ascii Chars for CRC Validation

	if ($crc != hex($crc8)) {
	  Log3 $iohash, 4, "AS: CRC ($crc) does not not match $rawData, should be CRC ($crc8)";

	  return undef;
	  
	}
  }


  Log3 $iohash, 4, "AS: $rawData";
  
  my ($deviceCode, $SensorTyp, $model, $id, $valHigh, $valLow, $Sigval, $bat, $trigger, $val, $sigType);
  # T	Type:
  # 0
  # 1	moisture
  # 2	door
  # 3   light hirange (outdoor)
  # 4	light hires (indoor)
  # 5	water
  # 6	temp
  # 7	reed gas
  # 8    voltage
  # 9   Humidity
  # ..31 
  my %typeStr = (0, "type0", 1,"moisture", 2,"door", 3,"lightHiRange", 4,"lightHiRes", 5,"water", 6,"temp", 7,"reedGas", 8,"voltage",9,"humidity");
  my %sigStr = (0, "type0", 1,"moisture", 2,"door", 3,"light", 4,"light", 5,"water", 6,"temp", 7,"gas", 8,"voltage",9,"humidity");
  my %batStr = (0,"bad",1,"change",2,"ok",3,"optimal");
  my %trigStr = (0,"auto",1,"manual");

  #FHEM Schnittstelle:
  #    ASTTIIDDDDDD
  # AS  - Arduino Sensor
  # TT  - Bit 0..6 type
  #	- Bit 7 trigger (0 auto, 1 manual)
  # II  - Bit 0..5 id
  #	- Bit 6,7 battery status (00 - bad, 01 - change, 10 - ok, 11 - optimal)
  # DD1 - LowByte
  # DD2 - HighByte
  
	$SensorTyp = "ArduinoSensor";
    $model = $typeStr{hex(substr($rawData,0,2)) &0x7f}; # Sensortype
	$sigType = $sigStr{hex(substr($rawData,0,2)) &0x7f}; # Signaltype
	$id = hex(substr($rawData,2,2)) &0x3f;
	$valLow = hex(substr($rawData,4,2));
	$valHigh = hex(substr($rawData,6,2));
	$Sigval = (($valHigh<<8) + $valLow);
	$bat = $batStr{(hex(substr($rawData,2,2))>>6) &3};
	$trigger = $trigStr{(hex(substr($rawData,0,2))>>7) &1};
	Log3 $iohash, 4, "SD_AS Sigval: $Sigval";#

	if ($model eq "lightHiRange") {
	  $Sigval = sprintf( "%.1f", $Sigval /1.2); #TBD
	}
	elsif ($model eq "lightHiRes") {
	  $Sigval = sprintf( "%.1f", $Sigval /1.2/2);
	}
	elsif ($model eq "temp") {
	  $Sigval = ($Sigval-0x8000) /10;
	  Log3 $iohash, 4, "SD_AS: temp out of range" if ($Sigval > 100 || $Sigval < -60);
	  return "" if ($Sigval > 100 || $Sigval < -60);
	  $Sigval = sprintf( "%.1f", $Sigval); #temp is send 10*C
	}
	elsif ($model eq "door") {
	  $Sigval = (($Sigval==255)? 1:0); 
	}
	elsif ($model eq "moisture") {
	  $Sigval = sprintf( "%.1f%%", (1024-$Sigval)*100/1024);
	}
	elsif ($model eq "humidity") {
	  $Sigval = ($Sigval-0x8000) /10;
	  Log3 $iohash, 4, "SD_AS: humidity out of range" if ($Sigval > 100 || $Sigval < 0);
	  return "" if ($Sigval > 100 || $Sigval < 0);
	  
	  $Sigval = sprintf( "%i %%", $Sigval); #hum is send 10*%
	  
	}
	elsif ($model eq "reedGas") {
	  $Sigval = sprintf( "%i m3", ($Sigval)); #simple counter, code has to be extended to support restart of the sensor etc.
	}

	# Bei Voltage Sensoren die Batterieinfo als Zahl ausgeben, damit man sie in einem Diagramm abbilden kann	
	elsif ($model eq "voltage") {
	  $bat = (hex(substr($msg,7,2))>>1)&3
	} else {
		Log3 $iohash, 4, "SD_AS unknown model: $model";#
		return undef;
    }
    $val = "S: $Sigval B: $bat";

  if ($id ne "") {
    $deviceCode = $model."_".$id;
  }
  
  my $def = $modules{AS}{defptr}{$iohash->{NAME} . "." . $deviceCode};
  $def = $modules{AS}{defptr}{$deviceCode} if(!$def);
  
  if(!$def) {
    Log3 $iohash, 1, "SD_AS: UNDEFINED sensor $SensorTyp detected, code $deviceCode (".$SensorTyp."_".$deviceCode.")";
    return "UNDEFINED ".$SensorTyp."_".$deviceCode." SD_AS $deviceCode";
    #return "UNDEFINED $deviceCode SD_AS $deviceCode";
    
  }

  my $hash = $def;
  $name = $hash->{NAME};
  return "" if(IsIgnored($name));
  
  Log3 $hash, 4, "SD_AS: $name ($msg)";  
  
  $hash->{lastReceive} = time();

  if(!$val) {
    Log3 $hash, 3, "SD_AS: $name: $deviceCode Cannot decode $msg";
    return "";
  }
  
  $def->{lastMSG} = $msg;

  Log3 $hash, 4, "SD_AS $name: $val";

  readingsBeginUpdate($hash);
  readingsBulkUpdate($hash, "state", $val);
  readingsBulkUpdate($hash, $sigType, $Sigval);
  if ($bat ne "") {
    readingsBulkUpdate($hash, "battery", $bat);
  }
  if ($trigger ne "") {
    readingsBulkUpdate($hash, "trigger", $trigger);
  }  
  readingsEndUpdate($hash, 1); # Notify is done by Dispatch

  return $name;
}

#Optimized Dallas (now Maxim) iButton 8-bit CRC calculation.
#Polynomial: x^8 + x^5 + x^4 + 1 (0x8C)
#Initial value: 0x0
#See http://www.maxim-ic.com/appnotes.cfm/appnote_number/27

sub SD_AS_crc($$)
{
  my ($lcrc,$ldata) = @_;
  my $i;
  $lcrc = $lcrc ^ $ldata;
  for ($i = 0; $i < 8; $i++)
  {
    if ($lcrc & 0x01)
    {
      $lcrc = ($lcrc >> 1) ^ 0x8C;
    } else {
      $lcrc >>= 1;
    }
  }
  return $lcrc;
}


1;

=pod
=item summary    Supports ArduinoSensor
=item summary_DE Unterst&uumltzt den ArduinoSensor
=begin html


<a name="SD_AS"></a>
<h3>AS</h3>
<ul>
  The ArduinoSensor module interprets Arduino based sensors received via SIGNALduino
  <br><br>

  <a name="SD_ASdefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; AS &lt;code&gt;</code> <br>

    <br>
    &lt;code&gt; is the housecode of the address saved in the arduinosensor.
  </ul>
  <br>

  <a name="SD_ASset"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="SD_ASget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="SD_ASattr"></a>
  <b>Attributes</b>
  <ul>
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

<a name="SD_AS"></a>
<h3>AS</h3>
<ul>
  Das AS module dekodiert vom SIGNALduino empfangene Nachrichten von Arduino basierten Sensoren.
  <br><br>

  <a name="SD_ASdefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; AS &lt;code&gt; </code> <br>

    <br>
    &lt;code&gt; ist der Sensor ID Code, welcher im Arduino definiert ist.
  </ul>
  <br>

  <a name="SD_ASset"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="SD_ASget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="SD_ASattr"></a>
  <b>Attributes</b>
  <ul>
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
