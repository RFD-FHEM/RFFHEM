##############################################
# $Id: 14_SD_AS.pm 350 2023-01-09 19:54:08Z sidey79 $
# The file is part of the SIGNALduino project
# see http://www.fhemwiki.de/wiki/SIGNALduino
# and was created to provide support for self build sensors.
# The purpos is to use it as addition to the SIGNALduino
# modules in combination with RFDuino
# N. Butzek, S. Butzek, 2014 
# elektron-bbs, 2020

package main;
#use version 0.77; our $VERSION = version->declare('v3.4.3');

use strict;
use warnings;
use POSIX;
use FHEM::Meta;

#####################################
sub
SD_AS_Initialize
{
  my ($hash) = @_;

  #FHEM Schnittstelle:
  #    ASTTIIDDDDCC
  # AS  - Arduino Sensor
  # TT  - Bit 0..6 type - Bit 7 trigger (0 auto, 1 manual)
  # II  - Bit 0..5 id   - Bit 6,7 battery status (00 - bad, 01 - change, 10 - ok, 11 - optimal)
  # DD1 - LowByte
  # DD2 - HighByte
  # CC  -  Dallas (now Maxim) iButton 8-bit CRC calculation
  #-----------------------------
  #  T Type:
  #  0
  #  1 moisture
  #  2 door
  #  3 light hirange (outdoor)
  #  4 light hires (indoor)
  #  5 water
  #  6 temperature
  #  7 reed gas
  #  8 voltage
  #  9 humidity
  # 10 raw
  # ..31 

  $hash->{Match}     = "^P2#[A-Fa-f0-9]{7,8}";
  $hash->{DefFn}     = \&SD_AS_Define;
  $hash->{UndefFn}   = \&SD_AS_Undef;
  $hash->{ParseFn}   = \&SD_AS_Parse;
  $hash->{AttrList}  = "do_not_notify:0,1 showtime:0,1 ignore:0,1 ".$readingFnAttributes;
  $hash->{AutoCreate}=
        { 
          "ArduinoSensor_temp.*" => { ATTR => "event-min-interval:.*:300 event-on-change-reading:.*", FILTER => "%NAME", GPLOT => "temp4:Temp,", autocreateThreshold => "3:600"},
          "ArduinoSensor_humidity.*" => { ATTR => "event-min-interval:.*:300 event-on-change-reading:.*", FILTER => "%NAME", GPLOT => "temp4hum4:Temp/Hum,", autocreateThreshold => "3:600"},
          "ArduinoSensor_reedGas.*" => { ATTR => "event-min-interval:.*:300 event-on-change-reading:.*", FILTER => "%NAME", autocreateThreshold => "3:600"},
          "ArduinoSensor_moisture.*" => { ATTR => "event-min-interval:.*:300 event-on-change-reading:.*", FILTER => "%NAME", autocreateThreshold => "3:600"},
          "ArduinoSensor_voltage.*" => { ATTR => "event-min-interval:.*:300 event-on-change-reading:.*", FILTER => "%NAME", autocreateThreshold => "3:600"},
          "ArduinoSensor_raw.*" => { ATTR => "event-min-interval:.*:300 event-on-change-reading:.*", FILTER => "%NAME", autocreateThreshold => "3:600"},
        };

	return FHEM::Meta::InitMod( __FILE__, $hash );
}

#####################################
sub
SD_AS_Define
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
SD_AS_Undef
{
  my ($hash, $name) = @_;
  delete($modules{AS}{defptr}{$hash->{CODE}}) if($hash && $hash->{CODE});
  return undef;
}

#####################################
sub
SD_AS_Parse
{
	my ($iohash,$msg) = @_;
	my (undef ,$rawData) = split("#",$msg);
	my $name = $iohash->{NAME};

  if (length($rawData) < 8) {
    Log3 $iohash, 3, "$name: SD_AS ERROR - message $rawData too short";
    return q{};
  }
  ### CRC Check only if more than 8 characters for backward compatibility ###
  if (length($rawData) > 8) {
		my $rc = eval	{
			require Digest::CRC;
			Digest::CRC->import();
			1;
		};
		if ($rc) {
			my $ctx = Digest::CRC->new( width => 8, poly => 0x31 );
			my $calcCrc = $ctx->add( pack 'H*', substr( $rawData, 0, 8 ) )->digest;
			my $checksum = sprintf( "%d", hex( substr( $rawData, 8, 2 ) ) );
			if ($calcCrc != $checksum) {
				Log3 $iohash, 3, "$name: SD_AS ERROR - Calculated CRC ($calcCrc) not match received ($checksum) in msg $rawData";
				return q{};
			}
		} else {
			Log3 $name, 1, "$name: SD_AS ERROR - CRC not load, please install modul Digest::CRC";
			# return q{};
		}
	}

	if ((hex(substr($rawData,0,2)) & 0x7f) > 10) {
		Log3 $iohash, 3, "$name: SD_AS ERROR - ArduinoSensor unknown model " . (hex(substr($rawData,0,2)) & 0x7f);
		return q{};
	}

  Log3 $iohash, 4, "$name: SD_AS $rawData";

  my ($deviceCode, $SensorTyp, $model, $id, $valHigh, $valLow, $Sigval, $bat, $batteryVoltage, $batteryState, $batteryPercent, $trigger, $val, $sigType);
  #  T Type:
  #  0
  #  1	moisture
  #  2	door
  #  3 light hirange (outdoor)
  #  4	light hires (indoor)
  #  5	water
  #  6 temperature
  #  7	reed gas
  #  8 voltage
  #  9 humidity
  # 10 raw
  # ..31 
  my %typeStr = (0, "unknown", 1,"moisture", 2,"door", 3,"lightHiRange", 4,"lightHiRes", 5,"water", 6,"temp", 7,"reedGas", 8,"voltage",9,"humidity",10,"raw");
  my %sigStr = (0, "unknown", 1,"moisture", 2,"door", 3,"light", 4,"light", 5,"water", 6,"temperature", 7,"gas", 8,"voltage",9,"humidity",10,"raw");
  my %batStr = (0,"bad",1,"change",2,"ok",3,"optimal");
  my %trigStr = (0,"auto",1,"manual");

  #FHEM Schnittstelle:
  #    ASTTIIDDDDCC
  # AS  - Arduino Sensor
  # TT  - Bit 0..6 type - Bit 7 trigger (0 auto, 1 manual)
  # II  - Bit 0..5 id   - Bit 6,7 battery status (00 - bad, 01 - change, 10 - ok, 11 - optimal)
  # DD1 - LowByte
  # DD2 - HighByte
	# CC  - CRC8 (optional)

	$SensorTyp = "ArduinoSensor";
	$model = $typeStr{hex(substr($rawData,0,2)) &0x7f}; # Sensortype
	$sigType = $sigStr{hex(substr($rawData,0,2)) &0x7f}; # Signaltype
	$id = hex(substr($rawData,2,2)) &0x3f;
	$valLow = hex(substr($rawData,4,2));
	$valHigh = hex(substr($rawData,6,2));
	$Sigval = (($valHigh<<8) + $valLow);
	$bat = $batStr{(hex(substr($rawData,2,2))>>6) &3};
	$batteryState = ((hex(substr($rawData,2,2))>>6) &3) > 0 ? "ok" : "low";
	$trigger = $trigStr{(hex(substr($rawData,0,2))>>7) &1};
	Log3 $iohash, 4, "$name: SD_AS Sigval $Sigval";

	if ($model eq "lightHiRange") { # 3
	  $Sigval = sprintf( "%.1f", $Sigval /1.2); #TBD
	}
	elsif ($model eq "lightHiRes") { # 4
	  $Sigval = sprintf( "%.1f", $Sigval /1.2/2);
	}
	elsif ($model eq "temp") { # 6
	  $Sigval = ($Sigval-0x8000) /10;
	  Log3 $iohash, 3, "$name: SD_AS temp out of range - $Sigval" if ($Sigval > 100 || $Sigval < -60);
	  return "" if ($Sigval > 100 || $Sigval < -60);
	  $Sigval = sprintf( "%.1f", $Sigval); #temp is send 10*C
		$val = "T: $Sigval";
	}
	elsif ($model eq "door") { # 2
	  $Sigval = (($Sigval==255)? 1:0); 
	}
	elsif ($model eq "moisture") { # 1
	  $Sigval = sprintf( "%.1f%%", (1024-$Sigval)*100/1024);
	}
	elsif ($model eq "humidity") { # 9
	  $Sigval = ($Sigval-0x8000) /10;
	  Log3 $iohash, 3, "$name: SD_AS humidity out of range - $Sigval" if ($Sigval > 100 || $Sigval < 0);
	  return "" if ($Sigval > 100 || $Sigval < 0);
		$val = "H: $Sigval";
	}
	elsif ($model eq "reedGas") { # 7
	  $Sigval = sprintf( "%i m3", ($Sigval)); #simple counter, code has to be extended to support restart of the sensor etc.
	}
	# Bei Voltage Sensoren die Batterieinfo als Zahl ausgeben, damit man sie in einem Diagramm abbilden kann	
	elsif ($model eq "voltage") { # 8
		$batteryVoltage = $Sigval;
	  # $bat = (hex(substr($msg,7,2))>>1)&3; # ???
		$bat = hex(substr($rawData,2,2))>>6;
		$Sigval = round($Sigval / 1000, 2);	# Vcc is send in millivolts
		$val = "V: $Sigval";
	}
	elsif ($model eq "raw") { # 10
		$bat = hex(substr($rawData,2,2))>>6;
	  $Sigval = $valHigh * 256 + $valLow;
		$val = "S: $Sigval";
	}
	else { # 0
		Log3 $iohash, 4, "$name: SD_AS unknown model $model";
		return;
  }
  $val = "S: $Sigval B: $bat" if (!$val);

  if ($id ne "") {
    $deviceCode = $model."_".$id;
  }
  
  my $def = $modules{AS}{defptr}{$iohash->{NAME} . "." . $deviceCode};
  $def = $modules{AS}{defptr}{$deviceCode} if(!$def);
  
  if(!$def) {
    Log3 $iohash, 1, "$name: SD_AS UNDEFINED sensor $SensorTyp detected, code $deviceCode (".$SensorTyp."_".$deviceCode.")";
    return "UNDEFINED ".$SensorTyp."_".$deviceCode." SD_AS $deviceCode";
    #return "UNDEFINED $deviceCode SD_AS $deviceCode";
    
  }

  my $ioname = $name;
  my $hash = $def;
  $name = $hash->{NAME};
  return "" if(IsIgnored($name));
  
  Log3 $hash, 4, "$ioname: SD_AS $name rawmsg $msg";
  
  $hash->{lastReceive} = time();

  if(!$val) {
    Log3 $hash, 3, "$ioname: SD_AS $name $deviceCode Cannot decode $msg";
    return "";
  }
  
  $def->{lastMSG} = $msg;

  Log3 $hash, 4, "$ioname: SD_AS $name state $val";

	$hash->{timeReceiveDiffLast} = round(gettimeofday() - $hash->{timeReceive} , 1) if defined($hash->{timeReceive});
	$hash->{timeReceive} = gettimeofday();

  readingsBeginUpdate($hash);
  readingsBulkUpdate($hash, "state", $val);
	readingsBulkUpdate($hash, 'batteryState', $batteryState);
	readingsBulkUpdate($hash, 'batteryVoltage', $batteryVoltage) if defined $batteryVoltage;
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

sub SD_AS_crc
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
    <li><a href="#showtime">showtime</a></li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
  </ul>
  <br>
</ul>

=end html_DE
=for :application/json;q=META.json 14_SD_AS.pm
{
  "abstract": "Logical Module for arduino sensors with AS Protocol",
  "author": [
    "Sidey <>",
    "elektron-bbs <>"
  ],
  "x_fhem_maintainer": [
    "Sidey"
  ],
  "x_fhem_maintainer_github": [
    "Sidey79",
    "elektron-bbs",
	  "HomeAutoUser"
  ],
  "description": "This module interprets digitals signals send from an Arduinosensordevice provided from the signalduino hardware",
  "dynamic_config": 1,
  "keywords": [
    "fhem-sonstige-systeme",
    "fhem-hausautomations-systeme",
    "fhem-mod",
    "signalduino",
    "Arduino Sensor"
  ],
  "license": [
    "GPL_2"
  ],
  "meta-spec": {
    "url": "https://metacpan.org/pod/CPAN::Meta::Spec",
    "version": 2
  },
  "name": "FHEM::SD_AS",
  "prereqs": {
    "runtime": {
      "requires": {
        "Digest::CRC;": "0"
      }
    },
    "develop": {
      "requires": {
        "Digest::CRC;": "0"
      }
    }
  },
  "release_status": "stable",
  "resources": {
    "bugtracker": {
      "web": "https://github.com/RFD-FHEM/RFFHEM/issues/"
    },
    "x_testData": [
      {
        "url": "https://raw.githubusercontent.com/RFD-FHEM/RFFHEM/master/t/FHEM/14_SD_AS/testData.json",
        "testname": "Testdata with SD_AS sensors"
      }
    ],
    "repository": {
      "x_master": {
        "type": "git",
        "url": "https://github.com/RFD-FHEM/RFFHEM.git",
        "web": "https://github.com/RFD-FHEM/RFFHEM/tree/master"
      }
    },
    "x_support_community": {
      "board": "Sonstige Systeme",
      "boardId": "29",
      "cat": "FHEM - Hausautomations-Systeme",
      "description": "Sonstige Hausautomations-Systeme",
      "forum": "FHEM Forum",
      "rss": "https://forum.fhem.de/index.php?action=.xml;type=rss;board=29",
      "title": "FHEM Forum: Sonstige Systeme",
      "web": "https://forum.fhem.de/index.php/board,29.0.html"
    },
    "x_wiki": {
      "web": "https://wiki.fhem.de/wiki/SIGNALduino"
    }
  }
}
=end :application/json;q=META.json
=cut
