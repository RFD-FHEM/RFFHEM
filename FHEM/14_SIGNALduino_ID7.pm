##############################################
##############################################
# $Id: 14_SIGNALduino_ID7.pm  2015-09-22 $
# 
# The purpose of this module is to support serval eurochron
# weather sensors like eas8007 which use the same protocol
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
    "TX70DTH"     => 'TX70DTH',  # Currently nothing tested
);

sub
SIGNALduino_ID7_Initialize($)
{
  my ($hash) = @_;

  $hash->{Match}     = "^u7[A-Fa-f0-9]{10}";    ## Muss noch mal Ã¼berarbeitet werden, wenn wir mehr Ã¼ber die Sensoren wissen
  $hash->{DefFn}     = "SIGNALduino_ID7_Define";
  $hash->{UndefFn}   = "SIGNALduino_ID7_Undef";
  $hash->{ParseFn}   = "SIGNALduino_ID7_Parse";
  $hash->{AttrFn}	 = "SIGNALduino_ID7_Attr";
  $hash->{AttrList}  = "IODev do_not_notify:1,0 ignore:0,1 showtime:1,0 " .
                        "$readingFnAttributes " .
                        "model:".join(",",keys %models);

  #$hash->{AutoCreate}=
  #     { "SIGNALduino_ID7.*" => { GPLOT => "temp4hum4:Temp/Hum,", FILTER => "%NAME" } };
}

#############################
sub
SIGNALduino_ID7_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);

  return "wrong syntax: define <name> SIGNALduino_ID7 <code> ".int(@a)
        if(int(@a) < 3 || int(@a) > 5);

  $hash->{CODE} = $a[2];
  $hash->{lastMSG} =  "";
  $hash->{bitMSG} =  "";

  $modules{SIGNALduino_ID7}{defptr}{$a[2]} = $hash;
  $hash->{STATE} = "Defined";
  
  my $name= $hash->{NAME};
  $attr{$name}{"event-min-interval"} = ".*:300";
  $attr{$name}{"event-on-change-reading"} = ".*";
 
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
  my ($iohash, $msg) = @_;
  my $rawData = substr($msg, 2);
  my $name = $iohash->{NAME};

  my $model = "EAS800z";
  my $hlen = length($rawData);
  my $blen = $hlen * 4;
  my $bitData = unpack("B$blen", pack("H$hlen", $rawData)); 
  

  Log3 "SIGNALduino", 4, "SIGNALduino_ID7_Parse  $model ($msg) length: $hlen";
  
  #      4    8  9    12            24    28     36
  # 0011 0110 1  010  000100000010  1111  00111000 0000  eas8007
  # 0111 0010 1  010  000010111100  1111  00000000 0000  other device from anfichtn
  #      ID  Bat CHN       TMP      ??   HUM
  
  #my $hashumidity = FALSE;
  
  ## Todo: Change decoding per model into a foreach  
   #foreach $key (keys %models) {
  #   ....
  #}
  Log3 "SIGNALduino",3, $blen."_".oct("0b".substr($bitData,36,4));
  
  if ($blen ==40 && oct("0b".substr($bitData,36,4)) == 0) # Eigentlich müsste es gewisse IDs geben
  {
    my $bitData2 = substr($bitData,0,8) . ' ' . substr($bitData,8,1) . ' ' . substr($bitData,9,3);
       $bitData2 = $bitData2 . ' ' . substr($bitData,12,12) . ' ' . substr($bitData,24,4) . ' ' . substr($bitData,28,8);
    Log3 $iohash, 3, $model . ' converted to bits: ' . $bitData2;
    
    my $id = substr($rawData,0,2);
    my $bat = int(substr($bitData,8,1)) eq "1" ? "ok" : "low";
    my $channel = oct("0b" . substr($bitData,9,3)) + 1;
    my $temp = oct("0b" . substr($bitData,12,12));
    my $bit24bis27 = oct("0b".substr($bitData,24,4));
    my $hum = oct("0b" . substr($bitData,28,8));
    
    if ($hum > 100 || $bit24bis27 != 0xF) {
      return undef;  # Eigentlich müsste sowas wie ein skip rein, damit ggf. später noch weitre Sensoren dekodiert werden können.
    }
    
    if ($temp > 700 && $temp < 3840) {
      return undef;
    } elsif ($temp >= 3840) {        # negative Temperaturen, muÃŸ noch ueberprueft und optimiert werden 
      $temp -= 4095;
    }  
    $temp /= 10;
    
    Log3 $iohash, 3, "$model decoded protocolid: 7 sensor id=$id, channel=$channel, temp=$temp, hum=$hum, bat=$bat" ;
    my $deviceCode;
    
    if (exists &SIGNALDuino_use_longid && SIGNALDuino_use_longid($iohash,"$model"))
	{
		$deviceCode=$model._$id.$channel;
	} else {
		$deviceCode=$model."_".$channel;
	}	
    
    
    #print Dumper($modules{SIGNALduino_ID7}{defptr});
    
    my $def = $modules{SIGNALduino_ID7}{defptr}{$iohash->{NAME} . "." . $deviceCode};
    $def = $modules{SIGNALduino_ID7}{defptr}{$deviceCode} if(!$def);

    if(!$def) {
		Log3 $iohash, 1, 'SIGNALduino_ID7: UNDEFINED sensor ' . $model . ' detected, code ' . $deviceCode;
		return "UNDEFINED $deviceCode SIGNALduino_ID7 $deviceCode";
    }
        #Log3 $iohash, 3, 'SIGNALduino_ID7: ' . $def->{NAME} . ' ' . $id;
	
	
	my $hash = $def;
	$name = $hash->{NAME};
	Log3 $name, 4, "SIGNALduino_ID7: $name ($rawData)";  

	$def->{lastMSG} = $rawData;
	$def->{bitMSG} = $bitData2; 

    my $state = "T: $temp H: $hum";
    
    readingsBeginUpdate($hash);
    readingsBulkUpdate($hash, "state", $state);
    readingsBulkUpdate($hash, "temperature", $temp)  if ($temp ne"");
    readingsBulkUpdate($hash, "humidity", $hum)  if ($hum ne "" && $hum != 0 );
    readingsBulkUpdate($hash, "battery", $bat) if ($bat ne "");
    readingsBulkUpdate($hash, "channel", $channel) if ($channel ne "");

    readingsEndUpdate($hash, 1); # Notify is done by Dispatch

	return $name;
  }

  return undef;
}

sub
SIGNALduino_ID7_Attr(@)
{
  my @a = @_;

  # Make possible to use the same code for different logical devices when they
  # are received through different physical devices.
  return  if($a[0] ne "set" || $a[2] ne "IODev");
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
  New received device are add in fhem with autocreate.
  <br><br>

  <a name="SIGNALduino_ID7_Define"></a>
  <b>Define</b> 
  <ul>The received devices created automatically.<br>
  The ID of the defice is the cannel or, if the longid attribute is specified, it is a combination of channel and some random generated bits at powering the sensor and the channel.<br>
  If you want to use more sensors, than channels available, you can use the longid option to differentiate them.
  </ul>
  <br>
  <a name="SIGNALduino_ID7 Events"></a>
  <b>Generated events:</b>
  <ul>
     <li>temperature: The temperature</li>
     <li>humidity: The humidity (if available)</li>
     <li>battery: The battery state: low or ok (if available)</li>
     <li>channel: The Channelnumber (if available)</li>
  </ul>
  <br>
  <b>Attributes</b>
  <ul>
    <li><a href="#IODev">IODev</a>
      Note: by setting this attribute you can define different sets of 
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
  Neu empfangene Sensoren werden in FHEM per autocreate angelegt.
  <br><br>

  <a name="SIGNALduino_ID7_Define"></a>
  <b>Define</b> 
  <ul>Die empfangenen Sensoren werden automatisch angelegt.<br>
  Die ID der angelgten Sensoren ist entweder der Kanal des Sensors, oder wenn das Attribut longid gesetzt ist, dann wird die ID aus dem Kanal und einer Reihe von Bits erzeugt, welche der Sensor beim Einschalten zufällig vergibt.<br>
  </ul>
  <br>
  <a name="SIGNALduino_ID7 Events"></a>
  <b>Generierte Events:</b>
  <ul>
     <li>temperature: Die aktuelle Temperatur</li>
     <li>humidity: Die aktuelle Luftfeutigkeit (falls verf&uuml;gbar)</li>
     <li>battery: Der Batteriestatus: low oder ok (falls verf&uuml;gbar)</li>
     <li>channel: Kanalnummer (falls verfügbar)</li>
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
