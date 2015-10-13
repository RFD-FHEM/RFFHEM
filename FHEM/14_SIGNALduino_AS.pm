##############################################
# $Id: 14_AS.pm 3818 2015-08-30 $
# The file is part of the SIGNALduino project
# see http://www.fhemwiki.de/wiki/SIGNALduino
# and was created to provide support for self build sensors.
# The purpos is to use it as addition to the SIGNALduino
# modules in combination with RFDuino
# N. Butzek, S. Butzek, 2014 
#

package main;

use strict;
use warnings;
use POSIX;

#####################################
sub
AS_Initialize($)
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
  $hash->{DefFn}     = "AS_Define";
  $hash->{UndefFn}   = "AS_Undef";
  $hash->{AttrFn}    = "AS_Attr";
  $hash->{ParseFn}   = "AS_Parse";
  $hash->{AttrList}  = "IODev do_not_notify:0,1 showtime:0,1 ignore:0,1 ".$readingFnAttributes;
  $hash->{AutoCreate}=
        { "AS_temp.*" => { ATTR => "event-min-interval:.*:300 event-on-change-reading:.*", FILTER => "%NAME", GPLOT => "temp4:Temp,", autocreateThreshold => "2:600"},
          "AS_humidity.*" => { ATTR => "event-min-interval:.*:300 event-on-change-reading:.*", FILTER => "%NAME", GPLOT => "temp4hum4:Temp/Hum,", autocreateThreshold => "2:600"},
          "AS_reedGas.*" => { ATTR => "event-min-interval:.*:300 event-on-change-reading:.*", FILTER => "%NAME", autocreateThreshold => "2:600"},
          "AS_voltage.*" => { ATTR => "event-min-interval:.*:300 event-on-change-reading:.*", FILTER => "%NAME", autocreateThreshold => "2:600"},

        };
}


#####################################
sub
AS_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);

  return "wrong syntax: define <name> AS <code>".int(@a)
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
AS_Undef($$)
{
  my ($hash, $name) = @_;
  delete($modules{AS}{defptr}{$hash->{CODE}}) if($hash && $hash->{CODE});
  return undef;
}

#####################################
sub
AS_Parse($$)
{
  my ($hash,$msg) = @_;
  my @a = split("", $msg);

  if (length($msg) < 10) {
    Log3 "SIGNALduino", 4, "AS: wrong message -> $msg";
    return "";
  }
  ### CRC Check only if more than 10 characters for backward compatibility ###
  if (length($msg) > 10) {
	my $i;
	my $crc = 0x0;
	my $byte;
	
    for ($i = 2; $i <= 8; $i+=2) {
      #convert pairs of hex digits into number for Bytes 0-3 only!
      $byte = hex(substr $msg, $i, 2);
      $crc=AS_crc($crc,$byte);
	}
	my $crc8;
	$crc8 = substr($msg,-2);  ## Get last two Ascii Chars for CRC Validation

	if ($crc != hex($crc8)) {
	  Log3 $hash, 4, "AS: CRC ($crc) does not not match $msg, should be CRC ($crc8)";

	  return undef;
	  
	}
  }


  Log3 $hash, 3, "AS: $msg";
  
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
    $model = $typeStr{hex(substr($msg,2,2)) &0x7f}; # Sensortype
	$sigType = $sigStr{hex(substr($msg,2,2)) &0x7f}; # Signaltype
	$id = hex(substr($msg,4,2)) &0x3f;
	$valLow = hex(substr($msg,6,2));
	$valHigh = hex(substr($msg,8,2));
	$Sigval = (($valHigh<<8) + $valLow);
	$bat = $batStr{(hex(substr($msg,4,2))>>6) &3};
	$trigger = $trigStr{(hex(substr($msg,2,2))>>7) &1};
	Log3 $hash, 3, "AS Sigval: $Sigval";#

	if ($model eq "lightHiRange") {
	  $Sigval = sprintf( "%.1f", $Sigval /1.2); #TBD
	}
	elsif ($model eq "lightHiRes") {
	  $Sigval = sprintf( "%.1f", $Sigval /1.2/2);
	}
	elsif ($model eq "temp") {
	  $Sigval = sprintf( "%.1f", ($Sigval-0x8000) /10); #temp is send 10*°C
	}
	elsif ($model eq "door") {
	  $Sigval = (($Sigval==255)? 1:0); 
	}
	elsif ($model eq "moisture") {
	  $Sigval = sprintf( "%.1f%%", (1024-$Sigval)*100/1024);
	}
	elsif ($model eq "humidity") {
	  $Sigval = sprintf( "%i %", ($Sigval-0x8000) /10); #hum is send 10*%
	}
	elsif ($model eq "reedGas") {
	  $Sigval = sprintf( "%i m3", ($Sigval)); #simple counter, code has to be extended to support restart of the sensor etc.
	}

	# Bei Voltage Sensoren die Batterieinfo als Zahl ausgeben, damit man sie in einem Diagramm abbilden kann	
	elsif ($model eq "voltage") {
	  $bat = (hex(substr($msg,9,2))>>1)&3
	} else {
		Log3 $hash, 1, "AS unknown model: $model";#
		return undef;
    }
    $val = "S: $Sigval B: $bat";

  if ($id ne "") {
    $deviceCode = $model."_".$id;
  }
  
  my $def = $modules{AS}{defptr}{$hash->{NAME} . "." . $deviceCode};
  $def = $modules{AS}{defptr}{$deviceCode} if(!$def);
  
  if(!$def) {
    Log3 $hash, 1, "AS: UNDEFINED sensor $SensorTyp detected, code $deviceCode";
    return "UNDEFINED $SensorTyp"."_"."$deviceCode AS $deviceCode";
  }

  $hash = $def;
  my $name = $hash->{NAME};
  return "" if(IsIgnored($name));
  
  Log3 $name, 4, "AS: $name ($msg)";  
  
  $hash->{lastReceive} = time();

  if(!$val) {
    Log3 $name, 1, "AS: $name: $deviceCode Cannot decode $msg";
    return "";
  }
  
  $def->{lastMSG} = $msg;

  Log3 $name, 4, "AS $name: $val";

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

sub AS_crc($$)
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


sub
AS_Attr(@)
{
  my @a = @_;

  # Make possible to use the same code for different logical devices when they
  # are received through different physical devices.
  return if($a[0] ne "set" || $a[2] ne "IODev");
  my $hash = $defs{$a[1]};
  my $iohash = $defs{$a[3]};
  my $cde = $hash->{CODE};
  delete($modules{AS}{defptr}{$cde});
  $modules{AS}{defptr}{$iohash->{NAME} . "." . $cde} = $hash;
  return undef;
}

1;

=pod
=begin html

<a name="AS"></a>
<h3>AS</h3>
<ul>
  The AS module interprets Arduino based sensors received via SIGNALduino
  <br><br>

  <a name="ASdefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; AS &lt;code&gt;</code> <br>

    <br>
    &lt;code&gt; is the housecode of the address saved in the arduinosensor.
  </ul>
  <br>

  <a name="ASset"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="ASget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="ASattr"></a>
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

<a name="AS"></a>
<h3>AS</h3>
<ul>
  Das AS module dekodiert vom SIGNALduino empfangene Nachrichten von Arduino basierten Sensoren.
  <br><br>

  <a name="ASdefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; AS &lt;code&gt; </code> <br>

    <br>
    &lt;code&gt; ist der automatisch angelegte Code, welcher im Arduino gespeichert ist.
  </ul>
  <br>

  <a name="ASset"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="ASget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="ASattr"></a>
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
