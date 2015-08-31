##############################################
# $Id: 14_SIGNALduino_AS.pm 3818 2015-08-30 $
# The file is taken from the SIGNALduino project
# see http://www.fhemwiki.de/wiki/SIGNALduino
# and was modified by a few additions
# to provide support for self build sensors.
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
SIGNALduino_AS_Initialize($)
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
  $hash->{Match}     = "AS.*\$";
  $hash->{DefFn}     = "SIGNALduino_AS_Define";
  $hash->{UndefFn}   = "SIGNALduino_AS_Undef";
  $hash->{AttrFn}    = "SIGNALduino_AS_Attr";
  $hash->{ParseFn}   = "SIGNALduino_AS_Parse";
  $hash->{AttrList}  = "IODev do_not_notify:0,1 showtime:0,1 ignore:0,1 ".$readingFnAttributes;
  $hash->{AutoCreate}=
        { "SIGNALduino_Env.*" => { GPLOT => "light4:Brightness,", FILTER => "%NAME" } };
}


#####################################
sub
SIGNALduino_AS_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);

  return "wrong syntax: define <name> SIGNALduino_AS <code> <minsecs> <equalmsg>".int(@a)
		if(int(@a) < 3 || int(@a) > 5);

  $hash->{CODE}    = $a[2];
  $hash->{minsecs} = ((int(@a) > 3) ? $a[3] : 30);
  $hash->{equalMSG} = ((int(@a) > 4) ? $a[4] : 0);
  $hash->{lastMSG} =  "";
  $hash->{bitMSG} =  "";

  $modules{SIGNALduino_AS}{defptr}{$a[2]} = $hash;
  $hash->{STATE} = "Defined";

  AssignIoPort($hash);
  return undef;
}

#####################################
sub
SIGNALduino_AS_Undef($$)
{
  my ($hash, $name) = @_;
  delete($modules{SIGNALduino_AS}{defptr}{$hash->{CODE}}) if($hash && $hash->{CODE});
  return undef;
}

#####################################
sub
SIGNALduino_AS_Parse($$)
{
  my ($hash,$msg) = @_;
  my @a = split("", $msg);

  if (length($msg) < 10) {
    Log3 "SIGNALduino", 4, "SIGNALduino_AS: wrong message -> $msg";
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
      $crc=SIGNALduino_AS_crc($crc,$byte);
	}
	my $crc8;
	$crc8 = substr($msg,-2);  ## Get last two Ascii Chars for CRC Validation

	if ($crc != hex($crc8)) {
	  Log3 $hash, 4, "SIGNALduino_AS: CRC ($crc) does not not match $msg, should be CRC ($crc8)";
  	  Log3 "FHEMduino", 4, "SIGNALduino_AS: CRC ($crc) does not not match $msg, should be CRC ($crc8)";

	  return "SIGNALduino_AS: CRC ($crc) does not not match $msg, should be CRC ($crc8)";
	  
	}
  }


  Log3 $hash, 3, "SIGNALduino_AS: $msg";
  
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
	Log3 $hash, 3, "SIGNALduino_AS Sigval: $Sigval";#

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
		Log3 $hash, 1, "SIGNALduino_AS unknown model: $model";#
		return "";
    }
    $val = "S: $Sigval B: $bat";

  if ($id ne "") {
    $deviceCode = $model."_".$id;
  }
  
  my $def = $modules{SIGNALduino_AS}{defptr}{$hash->{NAME} . "." . $deviceCode};
  $def = $modules{SIGNALduino_AS}{defptr}{$deviceCode} if(!$def);
  
  if(!$def) {
    Log3 $hash, 1, "SIGNALduino_AS: UNDEFINED sensor $SensorTyp detected, code $deviceCode";
    return "UNDEFINED $SensorTyp"."_"."$deviceCode SIGNALduino_AS $deviceCode";
  }

  $hash = $def;
  my $name = $hash->{NAME};
  return "" if(IsIgnored($name));
  
  Log3 $name, 4, "SIGNALduino_AS: $name ($msg)";  
  
  if($hash->{lastReceive} && (time() - $hash->{lastReceive} < $def->{minsecs} )) {
    if (($def->{lastMSG} ne $msg) && ($def->{equalMSG} > 0)) {
      Log3 $name, 4, "SIGNALduino_AS: $name: $deviceCode no skipping due unequal message even if to short timedifference";
    } else {
      Log3 $name, 4, "SIGNALduino_AS: $name: $deviceCode Skipping due to short timedifference";
      return "";
    }
  }
  $hash->{lastReceive} = time();

  if(!$val) {
    Log3 $name, 1, "SIGNALduino_AS: $name: $deviceCode Cannot decode $msg";
    return "";
  }
  
  $def->{lastMSG} = $msg;

  Log3 $name, 4, "SIGNALduino_AS $name: $val";

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

sub SIGNALduino_AS_crc($$)
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
SIGNALduino_AS_Attr(@)
{
  my @a = @_;

  # Make possible to use the same code for different logical devices when they
  # are received through different physical devices.
  return if($a[0] ne "set" || $a[2] ne "IODev");
  my $hash = $defs{$a[1]};
  my $iohash = $defs{$a[3]};
  my $cde = $hash->{CODE};
  delete($modules{SIGNALduino_AS}{defptr}{$cde});
  $modules{SIGNALduino_AS}{defptr}{$iohash->{NAME} . "." . $cde} = $hash;
  return undef;
}

1;

=pod
=begin html

<a name="SIGNALduino_AS"></a>
<h3>SIGNALduino_AS</h3>
<ul>
  The SIGNALduino_AS module interprets Arduino based sensors received via SIGNALduino
  <br><br>

  <a name="SIGNALduino_ASdefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; SIGNALduino_AS &lt;code&gt; [minsecs] [equalmsg]</code> <br>

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

  <a name="SIGNALduino_ASset"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="SIGNALduino_ASget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="SIGNALduino_ASattr"></a>
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

<a name="SIGNALduino_AS"></a>
<h3>SIGNALduino_AS</h3>
<ul>
  Das SIGNALduino_AS module dekodiert vom SIGNALduino empfangene Nachrichten von Arduino basierten Sensoren.
  <br><br>

  <a name="SIGNALduino_ASdefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; SIGNALduino_AS &lt;code&gt; [minsecs] [equalmsg]</code> <br>

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

  <a name="SIGNALduino_ASset"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="SIGNALduino_ASget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="SIGNALduino_ASattr"></a>
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
