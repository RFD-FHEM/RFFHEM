# $Id: 98_Siro.pm 20772 2019-12-17 16:52:51Z Byte09 $
#
# Siro module for FHEM
# Thanks for templates/coding from SIGNALduino team and Jarnsen_darkmission_ralf9
# Thanks to Dr. Smag for decoding the protocol, which made this module possible
# Needs SIGNALduino.
# Published under GNU GPL License, v2
# History:
# 30.05.19 Version 1.0 innitial comit
################################################################################################################
# Todo's:
# -
# -
###############################################################################################################

package main;

use strict;
use warnings;
my $version = "1.0";


sub LTECH_Initialize($) {
    my ($hash) = @_;
    $hash->{SetFn}      = "FHEM::LTECH::Set";
    #$hash->{NotifyFn}   = "FHEM::LTECH::Notify";
    #$hash->{ShutdownFn} = "FHEM::LTECH::Shutdown";
	$hash->{FW_deviceOverview} = 1;
	#$hash->{FW_detailFn} = "FHEM::Siro::fhemwebFn";
    $hash->{DefFn}    = "FHEM::LTECH::Define";
    $hash->{UndefFn}  = "FHEM::LTECH::Undef";
    $hash->{DeleteFn} = "FHEM::LTECH::Delete";
    $hash->{ParseFn}  = "FHEM::LTECH::Parse";
    #$hash->{AttrFn}   = "FHEM::LTECH::Attr";
    $hash->{Match}    = "^P31#[A-Fa-f0-9]+";
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
            autocreateThreshold => "1:10"
        }
    };
}


#############################


#### arbeiten mit packages
package FHEM::LTECH;

use strict;
use warnings;
use Switch;
use Color;

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
  "white" => "uzsuToggle,on,off",
  "brightness" => "slider,0,1,255",
  "color" => "colorpicker,HSV",
  "test" => "textFieldNL"
);

#############################
sub Define($$) {
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
    Log3( $name, 4, "LTECH_define: trying");
	my $devpointer = $hash->{CODE};
    $hash->{MODEL} = "M4-A5";
    $modules{LTECH}{defptr}{$devpointer} = $hash;
	AssignIoPort($hash);

    # attributliste anlegen 
	setDevAttrList($name, $hash->{AttrList});
 
	my $webcmd = "webCmd white:color:brightness:on:off:test";
    CommandAttr( undef,$name . ' devStateIcon {return FHEM::LTECH::Icon($name)}' )
        if ( AttrVal($name,'devStateIcon','none') eq 'none' );

    CommandAttr(undef,$name . ' '.$webcmd)
        if ( AttrVal($name,'webCmd','none') eq 'none' );

    readingsSingleUpdate($hash, 'white', "off", 0);
    Log3( $name, 4, "LTECH_define: angelegtes Device - code -> $code name -> $name hash -> $hash ");
}

#############################
sub Attr(@) {
	my ( $cmd, $name, $aName, $aVal ) = @_;
    my $hash = $defs{$name};
    return "\"LTECH Attr: \" $name does not exist" if ( !defined($hash) );

	if ( $cmd eq "set" and $init_done == 1) 
	{
	
	
	
	Log3( $name,5 , "Siro_attr: $cmd, $name, $aName, $aVal ");
	
	}
	
	Log3( $name,5 , "Siro_attr init done : $init_done");
return;
}

#############################
sub Undef($$) {
    my ( $hash, $name ) = @_;
    delete( $modules{LTECH}{defptr}{$hash->{CODE}} );
    return undef;
}

#############################
sub Shutdown($) {
    my ($hash) = @_;
    my $name = $hash->{NAME};
    return;
}

#############################
sub LoadHelper($) {
    my ($hash) = @_;
    my $name = $hash->{NAME};
    return;
}

#############################

sub Notify($$) {

    return;
}
#############################

sub Delete($$) {
    my ( $hash, $name ) = @_;
    return undef;
}

#############################
sub Parse($$) {
   
    my @args;
    my ( $hash, $msg ) = @_;
	my $name = $hash->{NAME};
    return "" if ( IsDisabled($name) );	
	my ( undef, $rawData ) = split( "#", $msg );
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
	my $color= substr($rawData,10,6);
	my $function=substr($rawData,16,2); #80 on ; 82 dim; 83 dim color; 00 off
	my $dim=substr($rawData,18,2);
	my $speed=substr($rawData,20,2);	
    
	my $def = $modules{LTECH}{defptr}{$deviceCode};
	$hash = $def;
    $name = $hash->{NAME};	
	if (!defined($def)){
		Log3 $hash, 2, "LTECH: unknown device $deviceCode, please define it";
        return "UNDEFINED LTECH_$deviceCode LTECH $deviceCode";
	}
	$def->{STATE}= "Defined";
	$def->{bitMSG} =  $bitData;
  	$def->{lastMSG} = substr($rawData,8,18); 
    Log3 $hash, 4, "$name LTECH_Parse: msg = $rawData length: $msg";
    Log3 $hash, 4, "$name LTECH_Parse: ID $deviceCode";
	Log3 $hash, 4, "$name LTECH_Parse: Mode $mode";
	Log3 $hash, 4, "$name LTECH_Parse: Color $color";
	Log3 $hash, 4, "$name LTECH_Parse: Function $function";
	Log3 $hash, 4, "$name LTECH_Parse: Dimming $dim";
	Log3 $hash, 4, "$name LTECH_Parse: Speed $speed";


	my $white = ReadingsVal( $name, 'white', 'undef' );
	readingsBeginUpdate($hash);
	readingsBulkUpdate($hash, "function", $function);  
	readingsBulkUpdate($hash, "mode", $mode);
	readingsBulkUpdate($hash, "speed", $speed);
	readingsBulkUpdate($hash, "color", Color2hex($color) );
	readingsBulkUpdate($hash, "color_sel", undef);
	readingsBulkUpdate($hash, "brightness", Hex2dec($dim) );
	readingsBulkUpdate($hash, "brightness_sel", undef);
	readingsBulkUpdate($hash, "crc", $crc) ;
	readingsBulkUpdate($hash, "white", $white );
	readingsEndUpdate($hash, 1);
	return $name;
}

#############################

# Call with hash, name, virtual/send, set-args
sub Set($@) 
{
	my ( $hash, $name, @args ) = @_;
	my $cmd    = $args[0]; 
	my $value  = $args[1];
	Log3( $name, 4, "LTECH: eingehende Werte $cmd , $value");


	switch($cmd) {
		case "color" { readingsSingleUpdate($hash, 'color_sel', $value, 1); return};
		case "brightness" { readingsSingleUpdate($hash, 'brightness_sel', $value , 1); return};
		case "white" { readingsSingleUpdate($hash, 'white', $value , 1); return };
		case "on" {
			my $color_last = ReadingsVal( $name, 'color', 'undef' );
			my $color = ReadingsVal( $name, 'color_sel', $color_last );
			my $dim_last = ReadingsVal( $name, 'brightness', 'undef' );
			my $dim = ReadingsVal( $name, 'brightness_sel', $dim_last );
			my $white_last = ReadingsVal( $name, 'white', "off" );
			my $white = ReadingsVal( $name, 'white_sel', "off" );
			my $mode = "80";
			if($dim_last ne $dim) { $mode = "82"};
			my $msg = $hash->{CODE} . "7F". uc($color) . $mode . Dec2hex($dim) . "00"; 
			my $sendstring =  "u31#0x" . $msg . CRC16($msg) . "#R5" ;
=pod
			if($white ne "off"){
				Log3( $name, 4, "LTECH: whiteOn, $white");
				WhiteOn($hash);
			}else{
				Log3( $name, 4, "LTECH: whiteOff, $white");
				WhiteOff($hash);
			}
=cut
			Log3( $name, 4, ("LTECH: sending Message: " . $sendstring . " , " . $dim . " , " . $dim_last ));
			readingsBeginUpdate($hash);
			readingsBulkUpdate($hash, "color", $color);
			readingsBulkUpdate($hash, "brightness", $dim);
			readingsBulkUpdate($hash, "white", $white );
			readingsEndUpdate($hash, 1);
			IOWrite( $hash, 'sendMsg', $sendstring );
			return
		}
		case "off" {
			my $msg = $hash->{CODE} . "1F00000000FF00"; 
			my $sendstring =  "u31#0x" . $msg . CRC16($msg) . "#R5" ;
			IOWrite( $hash, 'sendMsg', $sendstring );
			return
		}
		case "test"{
			if(length($value) == 14){
				Send ($hash, $name, $value ); 
			}
			return
		}
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
sub Icon(@) {
   my ($name,$icon) = @_;
   my $hash = $defs{$name};
   my $state = ReadingsVal( $name, 'brightness', 'undef' );
   my $color = ReadingsVal( $name, 'color', 'undef' );
   $hash->{STATE} = int(hex($state)/2.55);
   my $sticon = ".*:light_light_dim_".int(hex($state)/25.5)."0\@".$color;
   return $sticon ;

}
#############################
sub CRC16 {
   my ($string) = @_;
   $string = pack( 'H*', $string);
   my $crc = 0;
   for my $c ( unpack 'C*', $string ) {
      $crc ^= $c;
      for ( 0 .. 7 ) {
         my $carry = $crc & 1;
         $crc >>= 1;
         $crc ^= 0x8408 if $carry;
      }
   }
   return  sprintf("%04X", unpack('n', pack('v', $crc)));
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
   return   unpack 'H*', pack 'b*', unpack 'B*' , pack 'C*' , $val;
}
#############################
sub Hex2dec {
   my ($val) = @_;
   return  unpack 'C*', pack 'B*', unpack 'b*' , pack 'H*' , $val;
}
#####################################
sub Hex2color {
   my ($val) = @_;
   return  unpack 'h*', pack 'B*', unpack 'b*' , pack 'h*', $val;
}
#####################################
sub Color2hex {
   my ($val) = @_;
   return  unpack 'h*', pack 'b*', unpack 'B*' , pack 'h*', $val;
}
#####################################
sub Send {
   my ($hash, $name , $msg) = @_;
   $msg = ($hash->{CODE} . $msg);	
   my $sendstring = "P31#0x" . $msg . CRC16($msg) . "#R5" ;
   IOWrite( $hash, 'sendMsg', $sendstring );
   Log3( $name, 3, "LTECH Send: $sendstring");
}
#####################################
sub WhiteOn {
  my ($hash) = @_;
  my $msg = ($hash->{CODE} . "0100000098FF00"); 
  my $sendstring =  "u31#0x" . $msg . CRC16($msg) . "#R5" ;
  IOWrite( $hash, 'sendMsg', $sendstring );
  return;
}
#####################################
sub WhiteOff {
  my ($hash)= @_; 
  my $msg = ($hash->{CODE} . "0100000018FF00"); 
  my $sendstring =  "u31#0x" . $msg . CRC16($msg) . "#R5" ;
  IOWrite( $hash, 'sendMsg', $sendstring );
  return;
}


=pod
#############################

sub fhemwebFn($$$$) {
my ( $FW_wname, $d, $room, $pageHash ) =@_;    # pageHash is set for summaryFn.
    my $hash     = $defs{$d};
    my $name     = $hash->{NAME};
    
	my $progmode =$hash->{helper}{progmode};
	Log3( $name, 5, "Siro-progmode: reached progmode $progmode");
	if (!defined $progmode){$progmode='off';}
	my $msg;

############################# 
# debugmode
	
	if (AttrVal( $name, 'SIRO_no_IO_msg',0 ) eq "1")
	{
		delete( $hash->{Signalduino_RAWMSG} );
		delete( $hash->{Signalduino_MSGCNT} );
		delete( $hash->{Signalduino_RSSI} );
		delete( $hash->{Signalduino_TIME} );
	}
	
	
	
	if (AttrVal( $name, 'SIRO_debug', "0" ) eq "1")
	{
	$msg.= "<table class='block wide' id='SiroWebTR'>
			<tr class='even'>
			<td><center>&nbsp;<br>Das Device ist im Debugmodus, es werden keine Befehle gesendet";
	$msg.= "<br>&nbsp;<br></td></tr></table>";
	
	}
############################# 
	
	if (AttrVal( $name, 'disable', "0" ) eq "1")
	
	{
	$msg= "<table class='block wide' id='SiroWebTR'>
			<tr class='even'>
			<td><center>&nbsp;<br>Das Device ist disabled";
	$msg.= "<br>&nbsp;<br></td></tr></table>";
	
	}
	



	if ( $progmode eq "on")
		{
		$msg= "<table class='block wide' id='SiroWebTR'>
			<tr class='even'>
			<td><center>&nbsp;<br>Programmiermodus aktiv, es werden nur folgende Befehle unterstuetzt:<br>&nbsp;<br>";
		$msg.= "Das Anlernen ene Rollos erfolgt unter der ID: ";
		
	my $sendid = AttrVal( $name, 'SIRO_send_id', 'undef' );
	if ( $sendid eq 'undef')
	{
		$msg.= $hash->{ID} ;
	}
	else
	{
		$msg.=  $sendid ;	
	}		
	$msg.= " und dem Kanal:  ";
	my $sendchan = AttrVal( $name, 'SIRO_send_channel', 'undef' );
	if ( $sendchan eq 'undef')
	{
		$msg.= $hash->{CHANNEL_RECEIVE} ;
	}
	else
	{
		$msg.=  $sendchan ;	
	}	
	
		$msg.= "<br>&nbsp;<br> ";	
		
		$msg.= "<input  style=\"height: 80px; width: 150px;\" type=\"button\" id=\"siro_prog_proc\" value=\"P2\" onClick=\"javascript:prog('prog');\">";
		$msg.= "&nbsp;";
			
		$msg.= "<input  style=\"height: 80px; width: 150px;\" type=\"button\" id=\"siro_prog_up\" value=\"UP\" onClick=\"javascript:prog('off');\">";
		$msg.= "&nbsp;";
			
		$msg.= "<input  style=\"height: 80px; width: 150px;\" type=\"button\" id=\"siro_prog_up\" value=\"DOWN\" onClick=\"javascript:prog('on');\">";
		$msg.= "&nbsp;";
			
		$msg.= "<input  style=\"height: 80px; width: 150px;\" type=\"button\" id=\"siro_prog_down\" value=\"STOP\" onClick=\"javascript:prog('stop');\">";
		$msg.= "&nbsp;";
			
		$msg.= "<input  style=\"height: 80px; width: 150px;\" type=\"button\" id=\"siro_prog_down\" value=\"LONGSTOP\" onClick=\"javascript:prog('longstop');\">";
		$msg.= "&nbsp;";
		
		$msg.= "&nbsp;";
		$msg.= "&nbsp;";
		$msg.= "&nbsp;";
		$msg.= "&nbsp;";
		$msg.= "&nbsp;";
		$msg.= "&nbsp;";
		$msg.= "&nbsp;";
		$msg.= "&nbsp;";
		$msg.= "&nbsp;";
		$msg.= "<input  style=\"height: 80px; width: 150px;\" type=\"button\" id=\"siro_prog_end\" value=\"END THIS MODE\" onClick=\"javascript:prog('prog_mode_off');\">";
		$msg.= "&nbsp;<br>&nbsp;";
			
		$msg.= "<br>- Motor anlernen: P2,P2,DOWN je nach Wicklung des Rollos";
		$msg.= "&nbsp;<input type=\"button\" id=\"siro_prog_stop\" value=\"execute\" onClick=\"javascript:prog('exec,prog,prog,on');\">";
			
		$msg.= "<br>- Motor anlernen: P2,P2,UP je nach Wicklung des Rollos";
		$msg.= "&nbsp;<input type=\"button\" id=\"siro_prog_stop\" value=\"execute\" onClick=\"javascript:prog('exec,prog,prog,off');\">";
			
		$msg.= "<br>- Einstellmodus aktivieren: P2, UP, P2";
		$msg.= "&nbsp;<input type=\"button\" id=\"siro_prog_stop\" value=\"execute\" onClick=\"javascript:prog('exec,prog,off,prog');\">";
			
		$msg.= "<br>- Endlagen loeschen: P2, DOWN, P2";
		$msg.= "&nbsp;<input type=\"button\" id=\"siro_prog_stop\" value=\"execute\" onClick=\"javascript:prog('exec,prog,on,prog');\">";
			
		$msg.= "<br>- Pairing loeschen: P2, STOP, P2";
		$msg.= "&nbsp;<input type=\"button\" id=\"siro_prog_stop\" value=\"execute\" onClick=\"javascript:prog('exec,prog,stop,prog');\">";
			
		$msg.= "<br>&nbsp;</td></tr></table>";
	}	
		
	$msg.= "<script type=\"text/javascript\">{";	
	$msg.= "function prog(msg){
		var  def = \"" . $name . "\"+\" \"+msg;
		if (msg == 'prog_mode_off')
		{
		location = location.pathname+\"?detail=" . $name . "&cmd=set \"+addcsrf(def);
		}
		else{
		var clickurl = location.pathname+\"?cmd=set \"+addcsrf(def);
		\$.post(clickurl, {});
		}
	}
	";
	
	$msg.= "}</script>";	
	return $msg;
}

#############################	
sub Siro_icon(@) 
	{
	my ($name,$icon) = @_;
	my $hash = $defs{$name};
	my $state = ReadingsVal( $name, 'state', 'undef' );
    my $move ="stop";
	$move = "open" if $state eq "100";
	$move = "close" if $state eq "0";
	
	if ($state =~ m/[a-z].*/){$state=0;}
	my $sticon = "fts_shutter_1w_";
	$sticon = $icon if defined $icon;
	
	
	my $invers = AttrVal( $name, 'SIRO_inversPosition',0 ); 
	my $ret ="programming:edit_settings notAvaible:hue_room_garage runningUp.*:fts_shutter_up:stop runningDown.*:fts_shutter_down:stop ".$state.":".$sticon.(int($state/10)*10).":".$move;
	$ret ="programming:edit_settings notAvaible:hue_room_garage runningUp.*:fts_shutter_up:stop runningDown.*:fts_shutter_down:stop ".$state.":".$sticon.(100 - (int($state/10)*10)).":".$move if $invers eq "1";
	$ret =".*:fts_shutter_all" if ($hash->{CHANNEL_RECEIVE} eq '0');
	$ret =".*:secur_locked\@red" if ReadingsVal( $name, 'lock_cmd', 'off' ) eq 'on';
	
	
	return $ret;
	}

#############################

sub Distributor($) {
    my ($input) = @_;
    my ( $name, $arg, $cmd ) = split( / /, $input );
    my $hash = $defs{$name};
    return "" if ( IsDisabled($name) );
	Log3( $name, 5, "Siro-Distributor : aufgerufen");
	Log3( $name, 5, "Siro-Distributor : Befehl - $arg");
	#suche devices
	my $devspec="TYPE=Siro:FILTER=ID=".$hash->{ID}.".*";
	my @devicelist = devspec2array($devspec);
	shift @devicelist;
	my $devicelist = join(" ",@devicelist);
	my $owndef = $hash->{ID};
	Log3( $name, 5, "Siro-Distributor : own DEF - ".$owndef);
	
	my @list =qw( 1 2 3 4 5 6 7 8 9 A B C D E F); 
	
	foreach my $key (@list) 
	{
		my $targdev = $owndef.$key;
			if (defined $modules{Siro}{defptr}{$targdev})
			{
			Log3( $name, 5, "Siro-Distributor : found defice kanal $key ID ".$modules{Siro}{defptr}{$targdev});
			my $devhash = $modules{Siro}{defptr}{$targdev};
			my $msg = "P72#".$targdev.$cmd;
			my $devname     = $devhash->{NAME};
			#$cmd = $codes{$cmd};
			Log3( $name, 5, "Siro-Distributor : transfer msg f�r $devname - $msg -$cmd"); 
			fhem( "set " . $devname . " " . $arg. " fakeremote" );
			}
	}
	
	readingsSingleUpdate( $hash, "LastAction", $arg, 1 );
	readingsSingleUpdate( $hash, "state", $arg, 1 );
	readingsSingleUpdate( $hash, "GroupDevices", $devicelist, 1 );

	delete( $hash->{Signalduino_RAWMSG} );
	delete( $hash->{Signalduino_MSGCNT} );
	delete( $hash->{Signalduino_RSSI} );
	delete( $hash->{Signalduino_TIME} );
	return;
}


1;
=cut


=pod

=item summary    Supports rf shutters from Siro
=item summary_DE Unterst&uumltzt Siro Rollo-Funkmotoren


=begin html

<a name="Siro"></a>
<h3>Siro protocol</h3>
<ul>
   
   <br> A <a href="#SIGNALduino">SIGNALduino</a> device (must be defined first).<br>
   
   <br>
        Since the protocols of Siro and Dooya are very similar, it is currently difficult to operate these systems simultaneously via one "IODev". Sending commands works without any problems, but distinguishing between the remote control signals is hardly possible in SIGNALduino. For the operation of the Siro-Module it is therefore recommended to exclude the Dooya protocol (16) in the SIGNALduino, via the whitelist. In order to detect the remote control signals correctly, it is also necessary to deactivate the "manchesterMC" protocol (disableMessagetype manchesterMC) in the SIGNALduino. If machester-coded commands are required, it is recommended to use a second SIGNALduino.<br>
 <br>
 <br>

   
  <a name="Sirodefine"></a>
   <br>
  <b>Define</b>
   <br>
  <ul>
    <code>define&lt; name&gt; Siro &lt;id&gt;&lt;channel&gt; </code>
  <br>
 <br>
   The ID is a 7-digit hex code, which is uniquely and firmly assigned to a Siro remote control. Channel is the single-digit channel assignment of the remote control and is also hexadecimal. This results in the possible channels 0 - 15 (hexadecimal 0-F). 
A unique ID must be specified, the channel (channel) must also be specified. 
An autocreate (if enabled) automatically creates the device with the ID of the remote control and the channel.

    <br><br>

    Examples:<br><br>
    <ul>
	<code>define Siro1 Siro AB00FC1</code><br>       Creates a Siro-device called Siro1 with the ID: AB00FC and Channel: 1<br>
    </ul>
  </ul>
  <br>

  <a name="Siroset"></a>
  <b>Set </b><br>
  <ul>
    <code>set &lt;name&gt; &lt;value&gt; [&lt;position&gt]</code>
    <br><br>
    where <code>value</code> is one of:<br>
    <pre>
    on
    off
    stop
    pos (0...100) 
    prog  
    fav
    </pre>
    
    Examples:<br><br>
    <ul>
      <code>set Siro1 on</code><br>
      <code>set Siro1 off</code><br>
      <code>set Siro1 position 50</code><br>
      <code>set Siro1 fav</code><br>
      <code>set Siro1 stop</code><br>
	    <code>set Siro1 set_favorite</code><br>
    </ul>
    <br>
     <ul>
set Siro1 on                           moves the roller blind up completely (0%)<br>
set Siro1 off                           moves the roller blind down completely (100%)<br>
set Siro1 stop                        stops the current movement of the roller blind<br>
set Siro1 pct 45              moves the roller blind to the specified position (45%)<br>
set Siro1 45                           moves the roller blind to the specified position (45%)<br>
set Siro1 fav                          moves the blind to the hardware-programmed favourite middle position<br>
set Siro1 set_favorite               programs the current roll position as hardware middle position. The attribute time_down_to_favorite is recalculated and set. <br>
set Siro1 progmode_on               enable the programming mode <br>


</ul>
    <br>
    Notes:<br><br>
    <ul>
      <li>If the module is in programming mode, the module detects successive stop commands because they are absolutely necessary for programming. In this mode, the readings and state are not updated. The mode is automatically terminated after 3 minutes. The remaining time in programming mode is displayed in the reading "pro_mode". The remaining time in programming mode is displayed in the reading "pro_mode". The programming of the roller blind must be completed during this time, otherwise the module will no longer accept successive stop commands. The display of the position, the state, is a calculated position only, since there is no return channel to status message. Due to a possible missing remote control command, timing problem etc. it may happen that this display shows wrong values sometimes. When moving into an end position without stopping the movement (set Siro1[on/off]), the status display and real position are synchronized each time the position is reached. This is due to the hardware and unfortunately not technically possible.
      </li>
     	</ul>
  </ul>
  <br>

  <b>Get</b> 
  <ul>N/A</ul><br>

  <a name="Siroattr"></a>
  <b>Attributes</b><br><br>
  <ul>
    <a name="IODev"></a>
    <li>IODev<br>
        The IODev must contain the physical device for sending and receiving the signals. Currently a SIGNALduino or SIGNALesp is supported.
        Without the specification of the "Transmit and receive module" "IODev", a function is not possible. 
    </li><br>

  <a name="SIRO_send_channel"></a>
    <li>channel (since V1.09 no longer available)<br>
        contains the channel used by the module for sending. 
        This is already set when the device is created.

    </li><br>
	
	 <a name="SIRO_send_ID"></a>
    <li>contains the ID used by the module for sending. 
        This is already set when the device is created.

    </li><br>
	

    <a name="SIRO_time_to_close"></a>
    <li>time_to_close<br>
        contains the movement time in seconds required by the blind from 0% position to 100% position. This time must be measured and entered manually. 
        Without this attribute, the module is not fully functional.</li><br>

       <a name="SIRO_time_to_open"></a>
    <li>time_to_open<br>
        contains the movement time in seconds required by the blind from 100% position to 0% position. This time must be measured and entered manually.
        Without this attribute, the module is not fully functional.</li><br>

		<a name="debug_mode [0:1]"></a>
    <li>debug_mode [0:1]<br>
        In mode 1 Commands are NOT physically sent.</li><br>
		
			<a name="Info"></a>
    <li>Info<br>
        The attributes webcmd and devStateIcon are set once when the device is created and are adapted to the respective mode of the device during operation. The adaptation of these contents only takes place until they have been changed by the user. After that, there is no longer any automatic adjustment.</li><br>

  </ul>
</ul>

=end html

=begin html_DE

<a name="Siro"></a>
<h3>Siro protocol</h3>
<ul>
   
   <br> Ein <a href="#SIGNALduino">SIGNALduino</a>-Geraet (dieses sollte als erstes angelegt sein).<br>
   
   <br>
        Da sich die Protokolle von Siro und Dooya sehr &auml;hneln, ist ein gleichzeitiger Betrieb dieser Systeme ueber ein "IODev" derzeit schwierig. Das Senden von Befehlen funktioniert ohne Probleme, aber das Unterscheiden der Fernbedienungssignale ist in Signalduino kaum m&ouml;glich. Zum Betrieb der Siromoduls wird daher empfohlen, das Dooyaprotokoll im SIGNALduino (16) &uuml;ber die Whitelist auszuschliessen. Zur fehlerfreien Erkennung der Fernbedienungssignale ist es weiterhin erforderlich im SIGMALduino das Protokoll "manchesterMC" zu deaktivieren (disableMessagetype manchesterMC). Wird der Empfang von machestercodierten Befehlen benoetigt, wird der Betrieb eines zweiten Signalduinos empfohlen.<br>
 <br>
 <br>

   
  <a name="Sirodefine"></a>
   <br>
  <b>Define</b>
   <br>
  <ul>
    <code>define &lt;name&gt; Siro &lt;id&gt; &lt;channel&gt;</code>
  <br>
 <br>
   Bei der <code>&lt;ID&gt;</code> handelt es sich um einen 7-stelligen Hexcode, der einer Siro Fernbedienung eindeutig und fest zugewiesen ist. <code>&lt;Channel&gt;</code> ist die einstellige Kanalzuweisung der Fernbedienung und ist ebenfalls hexadezimal. Somit ergeben sich die m&ouml;glichen Kan&auml;le 0 - 15 (hexadezimal 0-F).
Eine eindeutige ID muss angegeben werden, der Kanal (Channel) muss ebenfalls angegeben werden. <br>
Ein Autocreate (falls aktiviert), legt das Device mit der ID der Fernbedienung und dem Kanal automatisch an.

    <br><br>

    Beispiele:<br><br>
    <ul>
	<code>define Siro1 Siro AB00FC1</code><br>       erstellt ein Siro-Geraet Siro1 mit der ID: AB00FC und dem Kanal: 1<br>
    </ul>
  </ul>
  <br>

  <a name="Siroset"></a>
  <b>Set </b><br>
  <ul>
    <code>set &lt;name&gt; &lt;value&gt; [&lt;position&gt]</code>
    <br><br>
    where <code>value</code> is one of:<br>
    <pre>
    on
    off
    up
    down
    stop
    pct (0..100)
    prog_mode_on
    prog_mode_off
    fav
    set_favorite
    del_favorite
    </pre>
    
    Beispiele:<br><br>
    <ul>
      <code>set Siro1 on</code><br>
      <code>set Siro1 off</code><br>
      <code>set Siro1 pct 50</code><br>
      <code>set Siro1 fav</code><br>
      <code>set Siro1 stop</code><br>
      <code>set Siro1 set_favorite</code><br>
      <code>set Siro1 down_for_timer 5</code><br>
      <code>set Siro1 up_for_timer 5</code><br>
      <code>set Siro1 set_favorite</code><br>
    </ul>
    <br>
     <ul>
set Siro1 on                           f&auml;hrt das Rollo komplett hoch (0%)<br>
set Siro1 off                           f&auml;hrt das Rollo komplett herunter (100%)<br>
set Siro1 stop                        stoppt die aktuelle Fahrt des Rollos<br>
set Siro1 pct 45              f&auml;hrt das Rollo zur angegebenen Position (45%)<br>
set Siro1 45                           f&auml;hrt das Rollo zur angegebenen Position (45%)<br>
set Siro1 fav                          f&auml;hrt das Rollo in die hardwarem&auml;ssig programmierte Mittelposition<br>
set Siro1 down_for_timer 5                          f&auml;hrt das Rollo 5 Sekunden nach unten<br>
set Siro1 down_for_timer 5                         f&auml;hrt das Rollo 5 Sekunden nach oben<br>
set Siro1 progmode_on                       Das Modul wird in den Programmiermodus versetzt<br>
set Siro1 set_favorite               programmiert den aktuellen Rollostand als Hardwaremittelposition, das ATTR time_down_to_favorite wird neu berechnet und gesetzt. <br>
</ul>
    <br>
    Hinweise:<br><br>
    <ul>
      <li>Befindet sich das Modul im Programmiermodus, werden aufeinanderfolgende Stoppbefehle vom Modul erkannt, da diese zur Programmierung zwingend erforderlich sind. In diesem Modus werden die Readings und das State nicht aktualisiert. Der Modus wird nach 3 Minuten automatisch beendet. Die verbleibende Zeit im Programmiermodus wird im Reading "pro_mode" dargestellt. Die Programmierung des Rollos muss in dieser Zeit abgeschlossen sein, da das Modul andernfalls keine aufeinanderfolgenden Stoppbefehle mehr akzeptiert.
Die Anzeige der Position, des States, ist eine ausschliesslich rechnerisch ermittelte Position, da es keinen R&uumlckkanal zu Statusmeldung gibt. Aufgrund eines ggf. verpassten Fernbedienungsbefehls, Timingproblems etc. kann es vorkommen, dass diese Anzeige ggf. mal falsche Werte anzeigt. Bei einer Fahrt in eine Endposition, ohne die Fahrt zu stoppen (set Siro1 [on/off]), werden Statusanzeige und echte Position bei Erreichen der Position jedes Mal synchronisiert. Diese ist der Hardware geschuldet und technisch leider nicht anders l&ouml;sbar.
      </li>
     	</ul>
  </ul>
  <br>

  <b>Get</b> 
  <ul>N/A</ul><br>

  <a name="Siroattr"></a>
  <b>Attributes</b><br><br>
  <ul>
        <a name="IODev"></a>
    <li>IODev<br>
        Das IODev muss das physische Ger&auml;t zum Senden und Empfangen der Signale enthalten. Derzeit wird ein SIGNALduino bzw. SIGNALesp unterst?tzt.
        Ohne der Angabe des "Sende- und Empfangsmodul" "IODev" ist keine Funktion moeglich.</li><br>

    <a name="SIRO_time_to_close"></a>
    <li>time_to_close<br>
        beinhaltet die Fahrtzeit in Sekunden, die das Rollo von der 0% Position bis zur 100% Position ben&ouml;tigt. Diese Zeit muss manuell gemessen werden und eingetragen werden.
        Ohne dieses Attribut ist das Modul nur eingeschr&auml;nkt funktionsf&auml;hig.</li><br>

       <a name="time_to_open"></a>
    <li>SIRO_time_to_open<br>
        beinhaltet die Fahrtzeit in Sekunden, die das Rollo von der 100% Position bis zur 0% Position ben&ouml;tigt. Diese Zeit muss manuell gemessen werden und eingetragen werden.
        Ohne dieses Attribut ist das Modul nur eingeschr&auml;nkt funktionsf&auml;hig.</li><br>

    <a name="debug_mode [0:1]"></a>
    <li>debug_mode [0:1] <br>
         unterdrueckt das Weiterleiten von Befehlen an den Signalduino</li><br>
		 
	 <a name="SIRO_signalRepeats"></a>
    <li>SIRO_signalRepeats <br>
         Anzahl der Signalwiederholungen von gesendeten Befehlen </li><br>
		 
	 <a name="SIRO_signalLongstopRepeats"></a>
    <li>SIRO_signalLongstopRepeats <br>
         Anzahl der Signalwiederholungen des Favoritenbefehls </li><br>
		 
	<a name="SIRO_inversPosition"></a>
    <li>SIRO_signalLongstopRepeats <br>
         invertiert die Positionsangaben </li><br>	 
		 
	<a name="SIRO_inversPosition"></a>
    <li>SIRO_signalLongstopRepeats <br>
         invertiert die Positionsangaben </li><br>

	<a name="SIRO_sendChannel"></a>
    <li>SIRO_sendChannel <br>
         Kanal, der zum senden genutzt wird. Wird dieses Attribut gesetz, so empfaengt das Device nachwievor den urspruenglich gesetzten Kanal, sendet aber auf dem hier angegebenen Kanal </li><br>		 
	
	<a name="SIRO_sendID"></a>
    <li>SIRO_sendID <br>
         ID, die zum senden genutzt wird. Wird dieses Attribut gesetz, so empfaengt das Device nachwievor ie urspruenglich gesetzte ID, sendet aber auf der hier angegebenen ID </li><br>		 
		 	
	<a name="SIRO_battery_low"></a>
    <li>SIRO_battery_low <br>
         Motorlaufzeit in sekunden. Bei erreichen der Zeit wird das Reading Batterystate auf low gesetzt</li><br>		 
		 

    <a name="Info"></a>
    <li>Info<br>
        Die Attribute webcmd und devStateIcon werden beim Anlegen des Devices einmalig gesetzt und im auch im Betrieb an den jeweiligen Mode des Devices angepasst. Die Anpassung dieser Inhalte geschieht nur solange, bis diese durch den Nutzer ge&auml;ndert wurden. Danach erfolgt keine automatische Anpassung mehr.</li><br>

  </ul>
</ul>

=end html_DE



=cut
