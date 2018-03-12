##############################################
# $Id: 14_SD_WS_Maverick.pm 9346 2018-03-06 19:00:00Z v3.3-dev $
# 
# The purpose of this module is to support Maverick sensors
# Sidey79 & Cruizer 2016
# Ralf9 2018

package main;


use strict;
use warnings;

#use Data::Dumper;
sub SD_WS_Maverick_Initialize($);
sub SD_WS_Maverick_Define($$);
sub SD_WS_Maverick_Undef($$);
sub SD_WS_Maverick_Parse($$);
sub SD_WS_Maverick_Attr(@);
sub SD_WS_Maverick_ClearTempBBQ($);
sub SD_WS_Maverick_ClearTempFood($);
sub SD_WS_Maverick_updateReadings($$$$);

sub
SD_WS_Maverick_Initialize($)
{
  my ($hash) = @_;

  $hash->{Match}     = "^P47#[A-Fa-f0-9]+";
  $hash->{DefFn}     = "SD_WS_Maverick_Define";
  $hash->{UndefFn}   = "SD_WS_Maverick_Undef";
  $hash->{ParseFn}   = "SD_WS_Maverick_Parse";
  $hash->{AttrFn}	 = "SD_WS_Maverick_Attr";
  $hash->{AttrList}  = "IODev do_not_notify:1,0 ignore:0,1 showtime:1,0 inaktivityInterval " .
                        "$readingFnAttributes ";
  $hash->{AutoCreate} =
        { "SD_WS_Maverick.*" => { ATTR => "event-min-interval:.*:300 event-on-change-reading:.*", FILTER => "%NAME",  autocreateThreshold => "2:180"} };
## Todo: Pruefen der Autocreate Einstellungen

}

#############################
sub
SD_WS_Maverick_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);

  return "wrong syntax: define <name> SD_WS_Maverick <model>  ".int(@a)
        if(int(@a) < 3 );

  $hash->{CODE} = $a[2];
  $hash->{lastMSG} =  "";
 # $hash->{bitMSG} =  "";

  $modules{SD_WS_Maverick}{defptr}{$a[2]} = $hash;
  $hash->{STATE} = "Defined";
  
  my $name= $hash->{NAME};
  return undef;
}

#####################################
sub
SD_WS_Maverick_Undef($$)
{
  my ($hash, $name) = @_;
  delete($modules{SD_WS_Maverick}{defptr}{$hash->{CODE}})
     if(defined($hash->{CODE}) &&
        defined($modules{SD_WS_Maverick}{defptr}{$hash->{CODE}}));
  return undef;
}


###################################
sub
SD_WS_Maverick_Parse($$)
{
  my ($iohash, $msg) = @_;
  #my $rawData = substr($msg, 2);
  my $name = $iohash->{NAME};
  my (undef ,$rawData) = split("#",$msg);
  #$protocol=~ s/^P(\d+)/$1/; # extract protocol

  my $model = "SD_WS_Maverick";
  my $hlen = length($rawData);
  #my $blen = $hlen * 4;
  #my $bitData = unpack("B$blen", pack("H$hlen", $rawData)); 

  Log3 $name, 4, "$name SD_WS_Maverick_Parse  $model ($msg) length: $hlen";
  
  # https://hackaday.io/project/4690-reverse-engineering-the-maverick-et-732/
  # https://forums.adafruit.com/viewtopic.php?f=8&t=25414&sid=e1775df908194d56692c6ad9650fdfb2&start=15#p322178
  #
  #1      8     13    18       26 
  #AA999559 55555 95999 A9A9A669  Sensor 1 =21 2Grad
  #AA999559 95996 55555 95A65565  Sensor 2 =22 2Grad
  #  
  ## Todo: Change decoding per model into a foreach  
  #foreach $key (keys %models) {
  #   ....
  #}
  
  # ohne header:
  # MC;LL=-507;LH=490;SL=-258;SH=239;D=AA9995599599A959996699A969;C=248;L=104;
  # P47#599599A959996699A969
  #
  # 0  2   6 7     12
  # ss 11111 22222 uuuuuuuu
  # 59 9599A 95999 6699A969
  # 

	my $startup = substr($rawData,0,2);   # 0x6A upon startup, 0x59 otherwise
	my $temp_str1 = substr($rawData,2,5);
	my $temp_str2 = substr($rawData,7,5);
	my $checksum_str = substr($rawData,12);
  
  Log3 $iohash, 4, "$name $model decoded protocolid: 47 sensor startup=$startup, temp-f=$temp_str1, temp-b=$temp_str2, checksum-s=$checksum_str";
  
  if ($startup ne '59' && $startup ne '6A') {
      Log3 $iohash, 4, "$name $model ERROR: wrong startup=$startup (must be 59 or 6A)";
      return '';
  }
  
  # Calculate temp from data
  my $c;
  my $temp_food=-532;
  my $temp_bbq=-532;
  
  if ($temp_str1 ne '55555') { # wenn 55555 könnte man auch disconnected setzen
    $temp_str1 =~ tr/569A/0123/;
    for ( my $i = 0; $i < length($temp_str1); $i++ ) { 
        $c = substr( $temp_str1, $i, 1);
        $temp_food += $c*4**(4-$i);
    }
    if ($temp_food <= 0 || $temp_food > 300) {
        Log3 $iohash, 4, "$name $model ERROR: wrong temp-food=$temp_food";
        $temp_food = "";
    }
  } else {
      $temp_food = "";
  }
    
  if ($temp_str2 ne '55555') { # wenn 55555 könnte man auch disconnected setzen
    $temp_str2 =~ tr/569A/0123/;
    for ( my $i = 0; $i < length($temp_str2); $i++ ) { 
        $c = substr( $temp_str2, $i, 1);
        $temp_bbq += $c*4**(4-$i);
    }
    if ($temp_bbq <= 0 || $temp_bbq > 300) {
        Log3 $iohash, 4, "$name $model ERROR: wrong temp-bbq=$temp_bbq";
        $temp_bbq = "";
    }
  } else {
      $temp_bbq = "";
  }
  
  if ($temp_bbq eq "" && $temp_food eq "") {
       return '';
  }
  
  Log3 $iohash, 4, "$name $model decoded protocolid: temp-food=$temp_food, temp-bbq=$temp_bbq;";
  
  #print Dumper($modules{SD_WS_Maverick}{defptr});
    
  my $def = $modules{SD_WS_Maverick}{defptr}{$iohash->{NAME} };
  $def = $modules{SD_WS_Maverick}{defptr}{$model} if(!$def);

  if(!$def) {
      Log3 $iohash, 1, "$name SD_WS_Maverick: UNDEFINED sensor $model";
      return "UNDEFINED $model SD_WS_Maverick $model";
  }
      #Log3 $iohash, 3, 'SD_WS_Maverick: ' . $def->{NAME} . ' ' . $id;

    my $hash = $def;
    $name = $hash->{NAME};
    Log3 $name, 4, "SD_WS_Maverick: $name ($rawData)";  

    if (!defined(AttrVal($hash->{NAME},"event-min-interval",undef)))
    {
        my $minsecs = AttrVal($iohash->{NAME},'minsecs',0);
        if($hash->{lastReceive} && (time() - $hash->{lastReceive} < $minsecs)) {
            Log3 $hash, 4, "$model Dropped due to short time. minsecs=$minsecs";
            return "";
        }
    }

    $hash->{lastReceive} = time();
    $hash->{lastMSG} = $rawData;
    #$hash->{bitMSG} = $bitData2; 
    my $inaktivityInterval=int(AttrVal($name,"inaktivityInterval",5));
    if ($temp_bbq ne "") {
        RemoveInternalTimer($hash, 'SD_WS_Maverick_ClearTempBBQ');
        InternalTimer(time()+($inaktivityInterval*60), 'SD_WS_Maverick_ClearTempBBQ', $hash, 0);
    }
    if ($temp_food ne "") {
        RemoveInternalTimer($hash, 'SD_WS_Maverick_ClearTempFood');
        InternalTimer(time()+($inaktivityInterval*60), 'SD_WS_Maverick_ClearTempFood', $hash, 0);
    }
    $checksum_str =~ tr/569A/0123/;
    my $checksum="";
    #for ( my $i = 0; $i < length($checksum_str); $i++ ) { 
    #    $c = substr( $checksum_str, $i, 1);
    #    $checksum += $c*4**(4-$i);
    #}
    $checksum=$checksum_str;
    $hash->{checksum}=$checksum;
    
  
    Log3 $iohash, 5, "$name $model statistic: checksum=$checksum, t1=$temp_str1, temp-food=$temp_food, t2_$temp_str2, temp-bbq=$temp_bbq;";
    SD_WS_Maverick_updateReadings($hash, $temp_food, $temp_bbq, $startup);

    return $name;

}

sub SD_WS_Maverick_Attr(@)
{
  my ($cmd,$name,$attr_name,$attr_value) = @_;
  my $hash = $defs{$name};
  if($cmd eq "set") {
    if($attr_name eq "IODev") {
      # Make possible to use the same code for different logical devices when they
      # are received through different physical devices.
      my $iohash = $defs{$attr_value};
      my $cde = $hash->{CODE};
      delete($modules{SD_WS_Maverick}{defptr}{$cde});
      $modules{SD_WS_Maverick}{defptr}{$iohash->{NAME} . "." . $cde} = $hash;
    }
    elsif($attr_name eq "inaktivityInterval") {
      if (!looks_like_number($attr_value) || int($attr_value) < 1 || int($attr_value) > 60) {
          return "$name: Value \"$attr_value\" is not allowed.\n"
                 ."inaktivityInterval must be a number between 1 and 60."
      }
    }
  }
  return undef;
}

sub SD_WS_Maverick_ClearTempBBQ($){
  my ($hash) = @_;
  my $name = $hash->{NAME};
  Log3 $hash, 4, "$name ClearTempBBQ";
  
  my $temp_bbq=-1;
  my $temp_food=ReadingsVal($name,"temp-food",-1);
  SD_WS_Maverick_updateReadings($hash, $temp_food, $temp_bbq,"ClearTempBBQ");
}

sub SD_WS_Maverick_ClearTempFood($){
  my ($hash) = @_;
  my $name = $hash->{NAME};
  Log3 $hash, 4, "$name ClearTempFood";

  my $temp_bbq=ReadingsVal($name,"temp-bbq",-1);  
  my $temp_food=-1;
  SD_WS_Maverick_updateReadings($hash, $temp_food, $temp_bbq,"ClearTempFood");
}

sub SD_WS_Maverick_updateReadings($$$$){
  my ($hash, $temp_food, $temp_bbq, $startup) = @_;
  my $state = "";
  if ($temp_food ne "") {
     $state = "Food: $temp_food ";
  }
  if ($temp_bbq ne "") {
     $state .= "BBQ: $temp_bbq ";
  }
  #$state .= "S: $startup";
  
  readingsBeginUpdate($hash);
  readingsBulkUpdate($hash, "state", $state);
  readingsBulkUpdate($hash, "messageType", $startup);
  readingsBulkUpdate($hash, "checksum", $hash->{checksum});
  
  readingsBulkUpdate($hash, "temp-food", $temp_food)  if ($temp_food ne"");
  readingsBulkUpdate($hash, "temp-bbq", $temp_bbq)  if ($temp_bbq ne"");

  readingsEndUpdate($hash, 1); # Notify is done by Dispatch
  return undef;
}

1;


=pod
=item summary    Supports maverick temperature sensors protocl 47 from SIGNALduino
=item summary_DE Unterst&uumltzt Maverick Temperatursensoren mit Protokol 47 vom SIGNALduino
=begin html

<a name="SD_WS_Maverick"></a>
<h3>Wether Sensors protocol #7</h3>
<ul>
  The SD_WS_Maverick module interprets temperature sensor messages received by a Device like CUL, CUN, SIGNALduino etc.<br>
  <br>
  <b>Known models:</b>
  <ul>
    <li>Maverick 732/733</li>
  </ul>
  <br>
  New received device will be added in fhem with autocreate.
  <br><br>

  <a name="SD_WS_Maverick_Define"></a>
  <b>Define</b> 
  <ul>The received devices created automatically.<br>
  Maverick generates a new ID on each time turned on. So it is not possible to link the hardware with the fhem-device. 
  The consequence is, that only one Maverick could be defined in fhem.
  </ul>
  <br>
  <a name="SD_WS_Maverick Events"></a>
  <b>Generated readings:</b>
  <ul>
  	 <li>State (BBQ: Food: )</li>
     <li>temp-bbq (&deg;C)</li>
     <li>temp-food (&deg;C)</li>
     <li>messageType (6A at startup or rsync, otherwise 59)</li>
     <li>checksum (experimental)</li>
  </ul>
  <br>
  <b>Attributes</b>
  <ul>
    <li>inaktivityInterval <minutes (1-60)><br>
    The Interval to set temp-bbq and/or temp-food to -1 after defined minutes. Empty batteries or the malfunction of a tempertature-sensor could be recognized.<br> 
    <code>default: 5</code></li>
    <li><a href="#do_not_notify">do_not_notify</a></li>
    <li><a href="#ignore">ignore </a></li>
    <li><a href="#showtime">showtime (see FHEMWEB)</a></li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
  </ul>

  <a name="SD_WS_Maverick_Set"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="SD_WS_Maverick_Parse"></a>
  <b>Parse</b> <ul>N/A</ul><br>

</ul>

=end html

=begin html_DE

<a name="SD_WS_Maverick"></a>
<h3>SD_WS_Maverick</h3>
<ul>
  Das SD_WS_Maverick Module verarbeitet von einem IO Geraet (CUL, CUN, SIGNALDuino, etc.) empfangene Nachrichten von Temperatur-Sensoren.<br>
  <br>
  <b>Unterst&uumltzte Modelle:</b>
  <ul>
    <li>Maverick 732/733</li>
  </ul>
  <br>
  Neu empfangene Sensoren werden in FHEM per autocreate angelegt.
  <br><br>

  <a name="SD_WS_Maverick_Define"></a>
  <b>Define</b> 
  <ul>Die empfangenen Sensoren werden automatisch angelegt.<br>
  Da das Maverick bei jedem Start eine neue zufällige ID erzeugt kann das Gerät nicht mit dem fhem-device gekoppelt werden. 
  Das bedeutet, dass es nicht möglich ist in fhem zwei Mavericks parallel zu betreiben.
  </ul>
  <br>
  <a name="SD_WS_Maverick Events"></a>
  <b>Generierte Readings:</b>
  <ul>
  	 <li>State (BBQ: Food: )</li>
     <li>temp-bbq (&deg;C)</li>
     <li>temp-food (&deg;C)</li>
     <li>messageType (6A bei Start oder rsync, sonst 59)</li>
     <li>checksum (experimentell)</li>
  </ul>
  <br>
  <b>Attribute</b>
  <ul>
    <li>inaktivityInterval <minutes (1-60)><br>
    Das Interval nach dem temp-bbq und/oder temp-food auf -1 gesetzt werden, wenn keine Signale mehr empfangen werden.
    Hilfreich zum erkennen einer leeren Batterie oder eines defekten Termperaturfühlers.<br> 
    <code>default: 5</code></li>
    <li><a href="#do_not_notify">do_not_notify</a></li>
    <li><a href="#ignore">ignore</a></li>
    <li><a href="#showtime">showtime</a></li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
  </ul>

  <a name="SD_WS_Maverick1_Set"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="SD_WS_Maverick_Parse"></a>
  <b>Parse</b> <ul>N/A</ul><br>

</ul>

=end html_DE
=cut
