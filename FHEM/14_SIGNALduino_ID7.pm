##############################################
##############################################
# $Id: 14_SIGNALduino_ID7.pm  2015-09-16 $
# 
# The purpose of this module is to support serval 
# weather sensors like eas8007
# S. Butzek & Ralf9  2015  
#

package main;


use strict;
use warnings;

use SetExtensions;
use constant { TRUE => 1, FALSE => 0 };
use Data::Dumper;

#
# All suported models
#
my %models = (
    "EAS800z"     => 'EAS800z',
    "TX70DTH"     => 'TX70DTH',
);

sub
SIGNALduino_ID7_Initialize($)
{
  my ($hash) = @_;

  $hash->{Match}     = "^u7[a-F0-9]+";    ## Muss noch mal überarbeitet werden, wenn wir mehr über die Sensoren wissen
  $hash->{DefFn}     = "SIGNALduino_ID7_Define";
  $hash->{UndefFn}   = "SIGNALduino_ID7_Undef";
  $hash->{ParseFn}   = "SIGNALduino_ID7_Parse";
  $hash->{AttrList}  = "IODev do_not_notify:1,0 ignore:0,1 showtime:1,0 " .
                        "$readingFnAttributes " .
                        "model:".join(",", sort keys %models);

  #$hash->{AutoCreate}=
  #     { "SIGNALduino_ID7.*" => { GPLOT => "temp4hum4:Temp/Hum,", FILTER => "%NAME" } };
}

#############################
sub
SIGNALduino_ID7_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);
  
  Log3 "SIGNALduino", 3, "SIGNALduino_ID7_Define $def";

  return "wrong syntax: define <name> SIGNALduino_ID7 <code> <minsecs> <equalmsg>".int(@a)
        if(int(@a) < 3 || int(@a) > 5);

  $hash->{CODE} = $a[2];

  $hash->{minsecs} = ((int(@a) > 3) ? $a[3] : 30);
  $hash->{equalMSG} = ((int(@a) > 4) ? $a[4] : 0);
  $hash->{lastMSG} =  "";
  $hash->{bitMSG} =  "";

  $modules{SIGNALduino_ID7}{defptr}{$a[2]} = $hash;
  $hash->{STATE} = "Defined";

  AssignIoPort($hash);
  return undef;
}

#####################################
sub
SIGNALduino_ID7_Undef($$)
{
  my ($hash, $name) = @_;
  delete($modules{SIGNALduino_ID7}{defptr}{$hash->{CODE}})
     if(defined($hash->{CODE}) &&
        defined($modules{SIGNALduino_ID7}{defptr}{$hash->{CODE}}));
  return undef;
}


###################################
sub
SIGNALduino_ID7_Parse($$)
{
  my ($hash, $msg) = @_;
  my $rawData = substr($msg, 2);
  my $name = $hash->{NAME};

  my $model = "EAS800z";
  
  my $l = length($rawData);

  Log3 "SIGNALduino", 3, "SIGNALduino_ID7_Parse  $model ($msg) length: $l";
  
  #      4    8 9    12            24    28       36
  # 0011 0110 1 010  000100000010  1111  00111000 0000 
  #      ID  Bat CHN       TMP      ??   HUM
  
  #my $hashumidity = FALSE;
  
  if ($l == 10) {
    my $hlen = length($rawData);
    my $blen = $hlen * 4;
    my $bitData = unpack("B$blen", pack("H$hlen", $rawData)); 
    my $bitData2 = substr($bitData,0,4) . ' ' . substr($bitData,4,4) . ' ' . substr($bitData,8,1) . ' ' . substr($bitData,9,3);
       $bitData2 = $bitData2 . ' ' . substr($bitData,12,12) . ' ' . substr($bitData,24,4) . ' ' . substr($bitData,28,8) . ' ' . substr($bitData,36,4);
    Log3 $hash, 3, $model . ' converted to bits: ' . $bitData2;
    
    my $id = oct("0b".substr($bitData,4,4) . substr($bitData,9,3));
    my $channel = oct("0b" . substr($bitData,9,3)) + 1;
    my $temp = oct("0b" . substr($bitData,12,12)) / 10;
    my $bat = int(substr($bitData,8,1)) eq "1" ? "ok" : "critical";
    my $hum = oct("0b" . substr($bitData,28,8));
    Log3 $hash, 3, "$model decoded protocolid: 7 sensor id=$id, channel=$channel, temp=$temp, hum=$hum, bat=$bat" ;

    my $deviceCode = $model . '_' . $id;
    
    #print Dumper($modules{SIGNALduino_ID7}{defptr});
    
	my $def = $modules{SIGNALduino_ID7}{defptr}{$hash->{NAME} . "." . $deviceCode};
	$def = $modules{SIGNALduino_ID7}{defptr}{$deviceCode} if(!$def);

    Log3 $hash, 3, 'SIGNALduino_ID7: ' . $def->{NAME} . ' ' . $id;

    if(!$def) {
		Log3 $hash, 1, 'SIGNALduino_ID7: UNDEFINED sensor ' . $model . ' detected, code ' . $deviceCode . ' name ' . $hash->{NAME};
		return "UNDEFINED SIGNALduino_ID7 $deviceCode";
    }

	$hash = $def;
	$name = $hash->{NAME};
	Log3 $name, 4, "SIGNALduino_ID7: $name ($rawData)";  

   	if($hash->{lastReceive} && (time() - $hash->{lastReceive} < $def->{minsecs} )) {
		if (($def->{lastMSG} ne $rawData) && ($def->{equalMSG} > 0)) {
			Log3 $name, 4, "SIGNALduino_ID7: $name: $deviceCode no skipping due unequal message even if to short timedifference";
		} else {
			Log3 $name, 4, "SIGNALduino_ID7: $name: $deviceCode Skipping due to short timedifference";
			return "";
		}
	}
  	$hash->{lastReceive} = time();
	$def->{lastMSG} = $rawmsg;
	$def->{bitMSG} = $bitData; 

    my $state = "T: $temp H: $hum";
 
    readingsBeginUpdate($hash);
    readingsBulkUpdate($hash, "state", $state);
    readingsBulkUpdate($hash, "temperature", $temp)  if ($temp ne"");
    readingsBulkUpdate($hash, "humidity", $hum)  if ($hum ne "");
    readingsBulkUpdate($hash, "battery", $bat) if ($bat ne "");
    readingsBulkUpdate($hash, "channel", $channel) if ($channel ne "");

    readingsEndUpdate($hash, 1); # Notify is done by Dispatch

  }

  return undef;
}


SIGNALduino_ID7_Attr(@)
{
  my @a = @_;

  # Make possible to use the same code for different logical devices when they
  # are received through different physical devices.
  return if($a[0] ne "set" || $a[2] ne "IODev");
  my $hash = $defs{$a[1]};
  my $iohash = $defs{$a[3]};
  my $cde = $hash->{CODE};
  delete($modules{SIGNALduino_ID7}{defptr}{$cde});
  $modules{SIGNALduino_ID7}{defptr}{$iohash->{NAME} . "." . $cde} = $hash;
  return undef;
}


1;


=pod
=begin html

<a name="Wether Sensors protocol #7"></a>
<h3>Wether Sensors protocol #7</h3>
<ul>
  The SIGNALduino_ID7 module interprets temperature sensor messages received by a Device like CUL, CUN, SIGNALduino etc.<br>
  <br>
  <b>Supported models:</b>
  <ul>
    <li>EAS800z</li>
  </ul>
  <br>
  New received device packages are add in fhem with autocreate.
  <br><br>

  <a name="SIGNALduino_ID7_Define"></a>
  <b>Define</b> 
  <ul>The received devices created automatically.<br>
  The ID of the defive are the first two Hex values of the package as dezimal.<br>
  </ul>
  <br>
  <a name="SIGNALduino_ID7 Events"></a>
  <b>Generated events:</b>
  <ul>
     <li>temperature: The temperature</li>
     <li>humidity: The humidity (if available)</li>
     <li>battery: The battery state: low or ok (if available)</li>
     <li>channel: The Channelnumber (if available)</li>
     <li>trend: The temperature trend (if available)</li>
  </ul>
  <br>
  <b>Attributes</b>
  <ul>
    <li><a href="#IODev">IODev</a>
      Note: by setting this attribute you can define different sets of 8
      devices in FHEM, each set belonging to a Device which is capable of receiving the signals. It is important, however,
      that a device is only received by the defined IO Device, e.g. by using
      different Frquencies (433MHz vs 868MHz)
      </li>
    <li><a href="#do_not_notify">do_not_notify</a></li>
    <li><a href="#ignore">ignore</a></li>
    <li><a href="#model">model</a> ()</li>
    <li><a href="#showtime">showtime</a></li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
  </ul>

  <a name="SIGNALduino_ID7_Set"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="SIGNALduino_ID7_Parse"></a>
  <b>Set</b> <ul>N/A</ul><br>

</ul>

=end html

=begin html_DE

<a name="SIGNALduino_ID7"></a>
<h3>SIGNALduino_ID7</h3>
<ul>
  Das SIGNALduino_ID7 Module verarbeitet von einem IO Gerät (CUL, CUN, SIGNALDuino, etc.) empfangene Nachrichten von Temperatur-Sensoren.<br>
  <br>
  <b>Unterstütze Modelle:</b>
  <ul>
    <li>EAS800z</li>
  </ul>
  <br>
  Neu empfangene Sensoren werden in der fhem per autocreate angelegt.
  <br><br>

  <a name="SIGNALduino_ID7_Define"></a>
  <b>Define</b> 
  <ul>Die empfangenen Sensoren werden automatisch angelegt.<br>
  Die ID der angelgten Sensoren sind die ersten zwei HEX Werte des empfangenen Paketes in dezimaler Schreibweise.<br>
  </ul>
  <br>
  <a name="SIGNALduino_ID7 Events"></a>
  <b>Generierte Events:</b>
  <ul>
     <li>temperature: Die aktuelle Temperatur</li>
     <li>humidity: Die aktuelle Luftfeutigkeit (falls verfügbar)</li>
     <li>battery: Der Batteriestatus: low oder ok (falls verfügbar)</li>
     <li>channel: Kanalnummer (falls verfügbar)</li>
     <li>trend: Der Temperaturtrend (falls verfügbar)</li>
  </ul>
  <br>
  <b>Attribute</b>
  <ul>
    <li><a href="#IODev">IODev</a>
      Spezifiziert das physische Ger&auml;t, das die Ausstrahlung der Befehle f&uuml;r das 
      "logische" Ger&auml;t ausf&uuml;hrt. Ein Beispiel f&uuml;r ein physisches Ger&auml;t ist ein CUL.<br>
      </li>
    <li><a href="#do_not_notify">do_not_notify</a></li>
    <li><a href="#ignore">ignore</a></li>
    <li><a href="#model">model</a> ()</li>
    <li><a href="#showtime">showtime</a></li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
  </ul>

  <a name="SIGNALduino_ID71_Set"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="SIGNALduino_ID7_Parse"></a>
  <b>Set</b> <ul>N/A</ul><br>

</ul>

=end html_DE
=cut
