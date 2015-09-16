##############################################
# From dancer0705
#
# Receive temperature sensor
# Supported models:
#
#
# Unsupported models are saved in a device named CUL_TCM97001_Unknown
#
# Copyright (C) 2015 Bjoern Hempel
#
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or (at your option) any later 
# version.
#
# This program is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for 
# more details.
#
# You should have received a copy of the GNU General Public License along with 
# this program; if not, write to the 
# Free Software Foundation, Inc., 
# 51 Franklin St, Fifth Floor, Boston, MA 02110, USA
#
##############################################

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

  $hash->{Match}     = "u.*"; 
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

  return "wrong syntax: define <name> SIGNALduino_ID7 <code>"
        if(int(@a) < 3 || int(@a) > 5);

  $hash->{CODE} = $a[2];

  $modules{SIGNALduino_ID7}{defptr}{$a[2]} = $hash;
  $hash->{STATE} = "Defined";

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
    
    my $def = $modules{SIGNALduino_ID7}{defptr}{$id};
    Log3 $hash, 3, 'SIGNALduino_ID7: ' . $def->{NAME} . ' ' . $id;
      
    if(!$def) {
      Log3 $hash, 1, 'SIGNALduino_ID7: UNDEFINED sensor ' . $model . ' detected, code ' . $deviceCode . ' name ' . $hash->{NAME};
    return "UNDEFINED SIGNALduino_ID7 $deviceCode";
    }

    my $state = "T: $temp H: $hum";
 
    readingsBeginUpdate($def);
    readingsBulkUpdate($def, "state", $state);
    readingsBulkUpdate($def, "temperature", $temp);
    readingsBulkUpdate($def, "humidity", $hum);
    readingsBulkUpdate($def, "battery", $bat);
    readingsEndUpdate($def, 1); # Notify is done by Dispatch

  }

  return undef;
}

1;


=pod
=begin html

<a name="CUL_TCM97001"></a>
<h3>CUL_TCM97001</h3>
<ul>
  The CUL_TCM97001 module interprets temperature sensor messages received by a Device like CUL, CUN, SIGNALduino etc.<br>
  <br>
  <b>Supported models:</b>
  <ul>
    <li>TCM97...</li>
    <li>ABS700</li>
    <li>TCM21....</li>
    <li>Prologue</li>
    <li>Rubicson</li>
    <li>NC_WS</li>
    <li>GT-WT-02</li>
    <li>AURIOL</li>
  </ul>
  <br>
  New received device packages are add in fhem category CUL_TCM97001 with autocreate.
  <br><br>

  <a name="CUL_TCM97001_Define"></a>
  <b>Define</b> 
  <ul>The received devices created automatically.<br>
  The ID of the defive are the first two Hex values of the package as dezimal.<br>
  </ul>
  <br>
  <a name="CUL_TCM97001 Events"></a>
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
    <li><a href="#model">model</a> (TCM97..., ABS700, TCM21...., Prologue, Rubicson, NC_WS, GT-WT-02, AURIOL, Unknown)</li>
    <li><a href="#showtime">showtime</a></li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
  </ul>

  <a name="CUL_TCM97001_Set"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="CUL_TCM97001_Parse"></a>
  <b>Set</b> <ul>N/A</ul><br>

</ul>

=end html

=begin html_DE

<a name="CUL_TCM97001"></a>
<h3>CUL_TCM97001</h3>
<ul>
  Das CUL_TCM97001 Module verarbeitet von einem IO Gerät (CUL, CUN, SIGNALDuino, etc.) empfangene Nachrichten von Temperatur-Sensoren.<br>
  <br>
  <b>Unterstütze Modelle:</b>
  <ul>
    <li>TCM97...</li>
    <li>ABS700</li>
    <li>TCM21....</li>
    <li>Prologue</li>
    <li>Rubicson</li>
    <li>NC_WS</li>
    <li>GT-WT-02</li>
    <li>AURIOL</li>
  </ul>
  <br>
  Neu empfangene Sensoren werden in der fhem Kategory CUL_TCM97001 per autocreate angelegt.
  <br><br>

  <a name="CUL_TCM97001_Define"></a>
  <b>Define</b> 
  <ul>Die empfangenen Sensoren werden automatisch angelegt.<br>
  Die ID der angelgten Sensoren sind die ersten zwei HEX Werte des empfangenen Paketes in dezimaler Schreibweise.<br>
  </ul>
  <br>
  <a name="CUL_TCM97001 Events"></a>
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
    <li><a href="#model">model</a> (TCM97..., ABS700, TCM21...., Prologue, Rubicson, NC_WS, GT-WT-02, AURIOL, Unknown)</li>
    <li><a href="#showtime">showtime</a></li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
  </ul>

  <a name="CUL_TCM97001_Set"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="CUL_TCM97001_Parse"></a>
  <b>Set</b> <ul>N/A</ul><br>

</ul>

=end html_DE
=cut
