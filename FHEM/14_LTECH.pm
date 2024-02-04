# $Id: 14_LTECH.pm 1.0 2022-04-24 16:52:51Z Byte09 $
#
# LTECH LED ControllerModule for FHEM
# History:
# 24.04.22 Version 1.0 innitial comit
################################################################################################################
# Todo's:
# -
# -
###############################################################################################################

package main;

use strict;
use warnings;
my $version = "1.0";


sub LTECH_Initialize {
    my ($hash) = @_;
    $hash->{SetFn}    = \&FHEM::LTECH::Set;
    $hash->{DefFn}    = \&FHEM::LTECH::Define;
    $hash->{UndefFn}  = \&FHEM::LTECH::Undef;
    $hash->{DeleteFn} = \&FHEM::LTECH::Delete;
    $hash->{ParseFn}  = \&FHEM::LTECH::Parse;
    $hash->{Match}    = qr/^P31#[A-Fa-f0-9]{26}/;
    $hash->{AttrList} =
        " IODev"
      . " disable:0,1"
      . " LTECH_signalRepeats:1,2,3,4,5,6,7,8,9"
	  . " $readingFnAttributes"
	  ;

	  
    $hash->{AutoCreate} = {
        "LTECH.*" => {
            ATTR   => "event-min-interval:.*:300 event-on-change-reading:.*",
            FILTER => "%NAME",
            autocreateThreshold => "2:180"
        }
    };
}


#############################


#### arbeiten mit packages
package FHEM::LTECH;

use strict;
use warnings;
use Color;
use Digest::CRC;
use Scalar::Util qw(looks_like_number);

use GPUtils qw(GP_Import)
  ;    # wird fuer den Import der FHEM Funktionen aus der fhem.pl ben?tigt


## Import der FHEM Funktionen
BEGIN {
    GP_Import(
        qw(readingsSingleUpdate
		  readingsBeginUpdate
		  readingsEndUpdate
		  readingsBulkUpdate
          defs
          modules
          Log3
          AttrVal
          ReadingsVal
          IsDisabled
          gettimeofday
          InternalTimer
          RemoveInternalTimer
          AssignIoPort
          IOWrite
          ReadingsNum
          CommandAttr
		  attr
		  fhem
		  init_done
		  setDevAttrList
		  readingFnAttributes
		  devspec2array 
		  )

    );
}

my %sets = (
  "on"  => "noArg",
  "off" => "noArg",
  "white" => "slider,0,1,255",
  "rgbcolor" => "colorpicker,HSV",
  "h" => "colorpicker,HUE,0,1,359",
  "saturation" => "colorpicker,BRI,0,1,100",
  "brightness" => "colorpicker,BRI,0,1,100"
);

my $ctx = Digest::CRC->new(width=>16, init=>0x0000, xorout=>0x0000, refout=>0, poly=>0x1021, refin=>0, cont=>1);

#############################
sub Define {
    my ( $hash, $def ) = @_;
    my @a = split( "[ \t][ \t]*", $def );

    my $u = "Wrong syntax: define <name> LTECH code ";
 
    # Fail early and display syntax help
    if ( int(@a) < 3 ) {
        return $u;
    }

    my $name = $a[0];
    my $code  = uc( $a[2] );

    $hash->{CODE} = $code;
	my $devpointer = $hash->{CODE};
    $hash->{MODEL} = "M4-A5";
    $modules{LTECH}{defptr}{$devpointer} = $hash;
	AssignIoPort($hash);

    # attributliste anlegen 
	setDevAttrList($name, $hash->{AttrList});
 
	my $webcmd = "webCmd rgbcolor:white:on:off";
    CommandAttr( undef,$name . ' devStateIcon {Color_devStateIcon(ReadingsVal($name,"rgbcolor","000000"))}' )
        if ( AttrVal($name,'devStateIcon','none') eq 'none' );

    CommandAttr(undef,$name . ' '.$webcmd)
        if ( AttrVal($name,'webCmd','none') eq 'none' );

    Log3( $name, 4, "LTECH_define: angelegtes Device - code -> $code name -> $name hash -> $hash ");
}

#############################
sub Attr {
	my ( $cmd, $name, $aName, $aVal ) = @_;
    my $hash = $defs{$name};
    return "\"LTECH Attr: \" $name does not exist" if ( !defined($hash) );

	if ( $cmd eq "set" and $init_done == 1) 
	{
	
	
	
	Log3( $name,5 , "LTECH_attr: $cmd, $name, $aName, $aVal ");
	
	}
	
	Log3( $name,5 , "LTECH_attr init done : $init_done");
return;
}

#############################
sub Undef {
    my ( $hash, $name ) = @_;
    delete( $modules{LTECH}{defptr}{$hash->{CODE}} );
    return;
}

#############################
sub Shutdown {
    my ($hash) = @_;
    my $name = $hash->{NAME};
    return;
}

#############################

sub Notify {

    return;
}
#############################

sub Delete {
    my ( $hash, $name ) = @_;
    return;
}

#############################
sub Parse {
    my @args;
    my ( $hash, $msg ) = @_;
	my $name = $hash->{NAME};
	my ( undef, $rawData ) = split( "#", $msg );
    $rawData = uc unpack 'H*',pack 'B*', unpack 'b*', pack 'H*' , $rawData; 
    Log3 $hash, 2, "LTECH: $rawData";
	my $crc = substr($rawData,22,4);
	my $checkCrc = CRC16(substr($rawData,0,-4));
	if( $crc ne $checkCrc){
		Log3 $hash, 2, "LTECH: CRC Error -> $crc is not like calculated $checkCrc";
        return;
	}
	
	my $hlen    = length($rawData);
	my $blen    = $hlen * 4;
	my $bitData = unpack( "B$blen", pack( "H$hlen", $rawData ) );
	Log3( $name, 3, "LTECH_Parse: parsing" );
	Log3( $name, 3, "LTECH_Parse: msg = $msg length: ". length($msg));
	Log3( $name, 3, "LTECH_Parse: rawData = $rawData length: $hlen" );
	Log3( $name, 3, "LTECH_Parse: converted to bits: $bitData" );

	my $deviceCode=substr($rawData,0,8);
	my $mode=substr($rawData,8,2);
	my $rgbcolor= substr($rawData,10,6);
	my $function=substr($rawData,16,2); #80 on ; 82 dim; 83 dim rgbcolor; 00 off
	my $dim=substr($rawData,18,2);
	my $speed=substr($rawData,20,2);	
    
	my $def = $modules{LTECH}{defptr}{$deviceCode};
	$hash = $def;
    $name = $hash->{NAME};	
	if (!defined($def)){
		Log3 $hash, 2, "LTECH: unknown device $deviceCode, please define it";
        return "UNDEFINED LTECH_$deviceCode LTECH $deviceCode";
	}
	$def->{bitMSG} =  $bitData;
  	$def->{lastMSG} = substr($rawData,8,18); 
    
    Log3 $hash, 4, "$name LTECH_Parse: msg = $rawData length: $msg";
    Log3 $hash, 4, "$name LTECH_Parse: ID $deviceCode";
	Log3 $hash, 4, "$name LTECH_Parse: Mode $mode";
	Log3 $hash, 4, "$name LTECH_Parse: Color $rgbcolor";
	Log3 $hash, 4, "$name LTECH_Parse: Function $function";
	Log3 $hash, 4, "$name LTECH_Parse: Dimming $dim";
	Log3 $hash, 4, "$name LTECH_Parse: Speed $speed";
    
    readingsBeginUpdate($hash);
    if($function eq "00") {
            $rgbcolor = "000000";
            readingsBulkUpdate($hash, "rgbcolor", $rgbcolor );
    }else{
        if($mode eq "FE"){
             if($dim ne "FF"){
                my @rgb = Color::hex2rgb($rgbcolor);
                my ($h ,$s ,$v ) = Color::rgb2hsv( $rgb[0] / 255, $rgb[1] / 255, $rgb[2] / 255 );
                $v = hex($dim) / 255;
                $rgbcolor = Color::hsv2hex($h,$s,$v);
                }
                readingsBulkUpdate($hash, "rgbcolor", $rgbcolor );
                readingsBulkUpdate($hash, "rgbcolor_sel", $rgbcolor);
        }elsif($mode eq "80"){
            if($function == "18"){
                $dim = "00";
            }
            readingsBulkUpdate($hash, "white", Hex2dec($dim));
            readingsBulkUpdate($hash, "white_sel", Hex2dec($dim));
        }
    }
	readingsBulkUpdate($hash, "function", $function);  
	readingsBulkUpdate($hash, "mode", $mode);
	readingsBulkUpdate($hash, "crc", $crc) ;
    readingsBulkUpdate($hash, "speed", $speed) ;
	readingsEndUpdate($hash, 1);
	return $name;
}

#############################

# Call with hash, name, virtual/send, set-args
sub Set {
	my ( $hash, $name, @args ) = @_;
	my $cmd    = $args[0]; 
	my $value  = $args[1];
	Log3( $name, 4, "LTECH_Set: eingehende Werte $cmd , $value");


	if($cmd eq "rgbcolor" ) { 
        if($value =~ m/^[[:xdigit:]]{6}$/){
            readingsSingleUpdate($hash, 'rgbcolor_sel', uc $value, 1);
            return
        }
        return "Please provide a valid RGB-HexColor"
    }
    elsif($cmd eq "white" ) { 
        if( looks_like_number($value) && 0 <= $value  && $value <= 255 ){
            readingsSingleUpdate($hash, 'white_sel', $value , 1); 
            return
        }
        return "Please provide valid number between 0 and 255"
    }
	elsif($cmd eq "on" ) {
        my $rgbcolor = ReadingsVal( $name, 'rgbcolor', 'FF3700' );
        my $rgbcolor_sel = ReadingsVal( $name, 'rgbcolor_sel', 'FF3700' );
        my $white = ReadingsVal( $name, 'white', '00' );
        my $white_sel = ReadingsVal( $name, 'white_sel', '00' );
        if( hex($rgbcolor) != hex($rgbcolor_sel) ){
            Send ($hash, $name, "FE" . $rgbcolor_sel . "01FF00" ); 
            readingsSingleUpdate($hash, 'rgbcolor', $rgbcolor_sel,1);
        }
        if( $white != 0 && $white_sel == 0 ){
            Log3 $hash, 4, "$name LTECH_Set: White off";
            Send ($hash, $name, "80" . $rgbcolor_sel . "18" . Dec2hex($white_sel) . "00" ); 
            readingsSingleUpdate($hash, 'white', $white_sel,1);
        }elsif( hex($white) != hex($white_sel) ){
            Log3 $hash, 4, "$name LTECH_Set: Change White";
            Send ($hash, $name, "80" . $rgbcolor_sel . "19" . Dec2hex($white_sel) . "00" ); 
            readingsSingleUpdate($hash, 'white', $white_sel,1);
        }
        return
	}
    elsif($cmd eq "off") {
			Send ($hash, $name, "FE00000000FF00" );
            readingsSingleUpdate($hash, 'rgbcolor', '000000', 1);
            return
	}
    elsif($cmd eq "h") {
        if( looks_like_number($value) && 0 <= $value  && $value <= 360 ){
            my $rgbcolor = ReadingsVal( $name, 'rgbcolor', 'FF3700' );
            my @rgb = Color::hex2rgb($rgbcolor);
            my ($h ,$s ,$v ) = Color::rgb2hsv( $rgb[0] / 255, $rgb[1] / 255, $rgb[2] / 255 );
            $h = $value / 360;
            my $rgbcolor_sel = Color::hsv2hex($h,$s,$v);
            readingsSingleUpdate($hash, 'rgbcolor_sel', $rgbcolor_sel, 1);
            $args[0] = "on"; 
            Set($hash, $name, @args);
            return
        }
        return "Please provide valid number between 0 and 360"  
	}
    elsif($cmd eq "brightness") {
        if( looks_like_number($value) && 0 <= $value  && $value <= 100 ){
            my $rgbcolor = ReadingsVal( $name, 'rgbcolor', 'FF3700' );
            my @rgb = Color::hex2rgb($rgbcolor);
            my ($h ,$s ,$v ) = Color::rgb2hsv( $rgb[0] / 255, $rgb[1] / 255, $rgb[2] / 255 );
            $v = $value / 100;
            my $rgbcolor_sel = Color::hsv2hex($h,$s,$v);
            readingsSingleUpdate($hash, 'rgbcolor_sel', $rgbcolor_sel, 1);
            $args[0] = "on"; 
            Set($hash, $name, @args);
            return
        }
        return "Please provide valid number between 0 and 100"
    }
    elsif($cmd eq "saturation") {
        if( looks_like_number($value) && 0 <= $value  && $value <= 100 ){
            my $rgbcolor = ReadingsVal( $name, 'rgbcolor', 'FF3700' );
            my @rgb = Color::hex2rgb($rgbcolor);
            my ($h ,$s ,$v ) = Color::rgb2hsv( $rgb[0] / 255, $rgb[1] / 255, $rgb[2] / 255 );
            $s = $value / 100;
            my $rgbcolor_sel = Color::hsv2hex($h,$s,$v);
            readingsSingleUpdate($hash, 'rgbcolor_sel', $rgbcolor_sel, 1);
            $args[0] = "on"; 
            Set($hash, $name, @args);
            return
        }
        return "Please provide valid number between 0 and 100"
    }


	my @cList;
	my $atts = AttrVal( $name, 'setList', "" );
	my %setlist = split( "[: ][ ]*", $atts );
	foreach my $k ( sort keys %sets ) {
		my $opts = undef;
		$opts = $sets{$k};
		$opts = $setlist{$k} if ( exists( $setlist{$k} ) );
		if ( defined($opts) ) {
			push( @cList, $k . ':' . $opts );
		}
		else {
			push( @cList, $k );
		}
	}    # end foreach
	return "Unknown argument $cmd, choose one of " . join( " ", @cList );
}
#############################
sub CRC16 {
   my ($string) = @_;
   $ctx->add( (pack 'H*' ,$string) );
   return uc $ctx->hexdigest;
}
#############################
sub Invert {
   my ($string) = @_;
   my $text = "";
   for my $i (0..length($string)-1){
    my $char = substr($string, $i, 1);
    my $hex = hex($char) ^ 0xF;
    $text .=  sprintf("%01X", $hex);   
   }
   return $text;
}
#############################
sub Dec2hex {
   my ($val) = @_;
   return   unpack 'H*' , pack 'C*' , $val;
}
#############################
sub Hex2dec {
   my ($val) = @_;
   return  unpack 'C*' , pack 'H*' , $val;
}
#####################################
sub Send {
   my ($hash, $name , $msg) = @_;
   $msg = ($hash->{CODE} . $msg);	
   my $message = uc (unpack 'H*',pack 'B*', unpack 'b*', pack 'H*', ( $msg . CRC16($msg) )); 
   my $sendstring = "P31#0x" . $message . "#R" . int(AttrVal($name, 'LTECH_signalRepeats', '5'));
   IOWrite( $hash, 'sendMsg', $sendstring );
   Log3( $name, 3, "LTECH Send: $sendstring");
}


=item summary    Supports LTECH LED Controller
=item summary_DE Unterst&uumltzt LTECH LED Controller


=begin html

<a name="LTECH"></a>
<h3>LTECH</h3>
<ul>
  The Module interprets and sends FM Signals from and to LTECH LED Controllers via SIGNALduino
  <br><br>

  <a name="LTECHdefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; LTECH &lt;code&gt;</code> <br>

    <br>
    &lt;code&gt; is the unique identifier of a LTECH remote.

    <br><br>
      Example: <br>
    <code>define WohnzimmerLED LTECH 040EABFF</code>
      <br>
  </ul>
  <br>

  <a name="LTECHset"></a>
  <b>Set</b> <ul> Set brightness (pct),hue (h), rgbcolor, saturation, white by choosing the values whith sliders
  <br>rgbcolor and white will not be set directly. Instead "rgbcolor_sel" and "white_sel" readings are updated and applied whith antorher "on" command
  <br><br>
      Example: <br>
    <code>set WohnzimmerLED rgbcolor FF0000;set WohnzimmerLED on</code>
      <br>
  </ul>
   <ul> </ul><br>

  <a name="LTECHget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="LTECHattr"></a>
  <b>Attributes</b>
  <ul>
    <li><a href="LTECH_signalRepeats">Signal Repeats for LTECH Controller Commands</a></li>
  </ul>
  <br>
</ul>

=end html

=begin html_DE

<a name="LTECH"></a>
<h3>LTECH</h3>
<ul>
  Dieses Modul sendet und interpretiert Funktsignale zu und von LTECH LED Controlleren mit Hilfe von SIGNALduino
  <br><br>

  <a name="LTECHdefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; LTECH &lt;code&gt;</code> <br>

    <br>
    &lt;code&gt; ist die Adresse einer LTECH Fernbedienung.

    <br><br>
      Beispiel: <br>
    <code>define WohnzimmerLED LTECH 040EABFF</code>
      <br>
  </ul>
  <br>

  <a name="LTECHset"></a>
  <b>Set</b> <ul> Setzten der Helligkeit (brightness, pct), Farbton (h), RGBFarbe (rgbcolor), Sättigung (saturation), Weißlichtanteil (white) mit Hilfe der Schieberegler
  <br>rgbcolor und white werden nich direkt gesetzt. Es werden die Readings "rgbcolor_sel" und "white_sel" aktualisiert und mit einem weiteren "on" übernommen
  <br><br>
      Beispiel: <br>
    <code>set WohnzimmerLED rgbcolor FF0000;set WohnzimmerLED on</code>
      <br>
  </ul><br>

  <a name="LTECHget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="LTECHattr"></a>
  <b>Attributes</b>
  <ul>
    <li><a href="LTECH_signalRepeats">Signal Wiederholungen der Funkbefehle an den LTECH Controller </a></li>
  </ul>
  <br>
</ul>

=end html_DE



=cut
