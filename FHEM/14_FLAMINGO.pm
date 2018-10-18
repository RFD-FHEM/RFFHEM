#################################################################
# $Id: 14_FLAMINGO.pm 3818 2016-08-15 $
#################################################################
# The module was taken over by an unknown maintainer
#################################################################
# note / ToDo´s / Bugs:
# - 
# - 
#################################################################

package main;

use strict;
use warnings;


my %FLAMINGO_c2b;
my %sets = (
	"Testalarm:noArg" => "noArg",
	"Counterreset:noArg" => "noArg",
	#"on-for-timer" => "textField",
);


#####################################
sub
FLAMINGO_Initialize($)
{
  my ($hash) = @_;
  
  $hash->{Match}     = "^P13\.?1?#[A-Fa-f0-9]+";
  $hash->{SetFn}     = "FLAMINGO_Set";
#  $hash->{StateFn}   = "FLAMINGO_SetState";
  $hash->{DefFn}     = "FLAMINGO_Define";
  $hash->{UndefFn}   = "FLAMINGO_Undef";
  $hash->{ParseFn}   = "FLAMINGO_Parse";
  $hash->{AttrList}  = "IODev do_not_notify:0,1 showtime:0,1 ignore:0,1 ".
											 "model:model:FA20RF,FA21RF,FA22RF,LM-101LD,unknown ".
											 "room:FLAMINGO ".
											 $readingFnAttributes;
   $hash->{AutoCreate}=
    { 
				"FLAMINGO.*" => { ATTR => "event-on-change-reading:.* event-min-interval:.*:300 room:FLAMINGO", FILTER => "%NAME", GPLOT => ""},
    };
}

#####################################
sub FLAMINGO_SetState($$$$) {
  my ($hash, $tim, $vt, $val) = @_;
  $val = $1 if($val =~ m/^(.*) \d+$/);
  return "Undefined value $val" if(!defined($FLAMINGO_c2b{$val}));
  return undef;
}

#####################################
sub FLAMINGO_Define($$) {
	my ($hash, $def) = @_;
	my @a = split("[ \t][ \t]*", $def);

	return "wrong syntax: define <name> FLAMINGO <code> <optional IODev>" if(int(@a) < 3 || int(@a) > 4);
	return "wrong hex value: ".$a[2] if not ($a[2] =~ /^[0-9a-fA-F]{6}$/m);
	#return "wrong syntax: define <name> FLAMINGO <code> <optional IODev>".int(@a) if(int(@a) < 3 || int(@a) > 4);

	$hash->{CODE} = $a[2];
	$hash->{lastMSG} =  "";
	$hash->{bitMSG} =  "";

	$modules{FLAMINGO}{defptr}{$a[2]} = $hash;
	$hash->{STATE} = "Defined";

	my $name= $hash->{NAME};
	my $iodev = $a[3] if($a[3]);
	$iodev = $modules{FLAMINGO}{defptr}{ioname} if (exists $modules{FLAMINGO}{defptr}{ioname} && not $iodev);

	### Attributes ###
	if ( $init_done == 1 ) {
		#$attr{$name}{model}	= "unknown"	if( not defined( $attr{$name}{model} ) );
		$attr{$name}{room}	= "FLAMINGO";
		#$attr{$name}{stateFormat} = "{ReadingsVal($name, "state", "")." | ".ReadingsTimestamp($name, "state", "")}";
	}
	
	AssignIoPort($hash,$iodev);		## sucht nach einem passenden IO-Gerät (physikalische Definition)

	return undef;
}

#####################################
sub FLAMINGO_Undef($$) {
  my ($hash, $name) = @_;

  RemoveInternalTimer($hash, "FLAMINGO_UpdateState");
  delete($modules{FLAMINGO}{defptr}{$hash->{CODE}}) if($hash && $hash->{CODE});
  return undef;
}

#####################################
sub FLAMINGO_Set($$@) {
	my ( $hash, $name, @args ) = @_;

	my $ret = undef;
	my $message;
	my $list;
	my $model = $attr{$name}{model};
	my $iodev = $hash->{IODev}{NAME};
	
	$list = join (" ",keys %sets);
	return "ERROR: wrong command! (only $list)"  if ($args[0] ne "?" && $args[0] ne "Testalarm" && $args[0] ne "Counterreset");
	
	if ($args[0] eq "?") {
		$ret = $list;
	}
	
	my $hlen = length($hash->{CODE});
	my $blen = $hlen * 4;
	my $bitData= unpack("B$blen", pack("H$hlen", $hash->{CODE}));
	
	my $bitAdd = substr($bitData,23,1);					# for last bit, is needed to send
	$message = "P13.1#".$bitData.$bitAdd."P#R55";

	## Send Message to IODev and wait for correct answer	
	Log3 $hash, 3, "FLAMINGO set $name $args[0]" if ($args[0] ne "?");
	Log3 $hash, 4, "$iodev: FLAMINGO send raw Message: $message" if ($args[0] eq "Testalarm");

	## Counterreset ##
	if ($args[0] eq "Counterreset") {
		readingsSingleUpdate($hash, "alarmcounter", 0, 1);
	}

	## Testarlarm ##	
	if ($args[0] ne "?" and $args[0] ne "Counterreset") {
																			 
		# remove InternalTimer
		RemoveInternalTimer($hash, "FLAMINGO_UpdateState");
		
		readingsSingleUpdate($hash, "state", "Testalarm", 1);
		IOWrite($hash, 'sendMsg', $message);
		
		InternalTimer(gettimeofday()+5, "FLAMINGO_UpdateState", $hash, 0);		# set timer to Update status
	}
  
	return $ret;
}

#####################################
sub FLAMINGO_Parse($$) {
 	my ($iohash, $msg) = @_;
	#my $name = $iohash->{NAME};
	my ($protocol,$rawData) = split("#",$msg);
	$protocol=~ s/^[P](\d+)/$1/; # extract protocol

	my $iodev = $iohash->{NAME};
	$modules{FLAMINGO}{defptr}{ioname} = $iodev;	

	my $hlen = length($rawData);
	my $blen = $hlen * 4;
	my $bitData= unpack("B$blen", pack("H$hlen", $rawData));

	my $deviceCode = $rawData;  	# Message is in hex "4d4efd"
	
	my $def = $modules{FLAMINGO}{defptr}{$deviceCode};
	$def = $modules{FLAMINGO}{defptr}{$deviceCode} if(!$def);
	my $hash = $def;

	if(!$def) {
		Log3 $iohash, 1, "FLAMINGO UNDEFINED sensor detected, code $deviceCode";
		return "UNDEFINED FLAMINGO_$deviceCode FLAMINGO $deviceCode";
	}
  
	my $name = $hash->{NAME};
	my $model = $attr{$name}{model};
	return "" if(IsIgnored($name));
	
	$hash->{bitMSG} = $bitData;
	$hash->{lastMSG} = $rawData;
	$hash->{lastReceive} = time();
	
	# if ($model eq "unknown") {
		# Log3 $name, 3, "$iodev: FLAMINGO $name ---> Please define your model! <--- (attr $name model [your model])";
		# return $name;
	# }

	my $alarmcounter = ReadingsVal($name, "alarmcounter", 0);
	
	if (ReadingsVal($name, "state", "") ne "Alarm") {
		$alarmcounter = $alarmcounter+1;	
	}

	Log3 $name, 5, "$iodev: FLAMINGO actioncode: $deviceCode";
	Log3 $name, 4, "$iodev: FLAMINGO $name: is receiving Alarm (Counter $alarmcounter)";
	
	# remove InternalTimer
	RemoveInternalTimer($hash, "FLAMINGO_UpdateState");
	
 	readingsBeginUpdate($hash);
 	readingsBulkUpdate($hash, "state", "Alarm");
	readingsBulkUpdate($hash, "alarmcounter", $alarmcounter);
	readingsEndUpdate($hash, 1); # Notify is done by Dispatch

	InternalTimer(gettimeofday()+5, "FLAMINGO_UpdateState", $hash, 0);		# set timer to Update status
  return $name;
}

#####################################
sub FLAMINGO_UpdateState($) {
	my ($hash) = @_;
	my $name = $hash->{NAME};

	readingsBeginUpdate($hash);
 	readingsBulkUpdate($hash, "state", "no Alarm");
	readingsEndUpdate($hash, 1); # Notify is done by Dispatch
	
	Log3 $name, 4, "FLAMINGO: $name: Alarm stopped";
}


1;

=pod
=item summary    Supports flamingo fa20rf/fa21 smoke detectors
=item summary_DE Unterst&uumltzt Flamingo FA20RF/FA21/FA22RF/LM-101LD Rauchmelder
=begin html

<a name="FLAMINGO"></a>
<h3>FLAMINGO</h3>
<ul>
  The FLAMINGO module interprets FLAMINGO FA20RF/FA21/FA22RF type of messages received by the SIGNALduino.<br>
  Of this smoke detector, there are identical types profitec KD101LA, POLLIN KD101LA or renkforce LM-101LD.
  <br><br>

  <a name="FLAMINGOdefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; FLAMINGO &lt;code&gt;</code> <br>

    <br>
    &lt;code&gt; is the unic code of the autogenerated address of the FLAMINGO device. This changes, after pairing to the master<br>
  </ul>
  <br>

  <a name="FLAMINGOset"></a>
  <b>Set</b>
  <ul>
  <li>Counterreset<br>
  - set alarmcounter to 0</li>
  <li>Testalarm<br>
  - trigger a test alarm</li>
  </ul><br>

  <a name="FLAMINGOget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="FLAMINGOattr"></a>
  <b>Attributes</b>
  <ul>
    <li><a href="#IODev">IODev (!)</a></li>
    <li><a href="#do_not_notify">do_not_notify</a></li>
    <li><a href="#eventMap">eventMap</a></li>
    <li><a href="#ignore">ignore</a></li>
	<a name="model"></a>
	<li>model<br>
	FA20RF, FA21RF, FA22RF, LM-101LD, unknown</li>
    <a name="showtime"></a>
	<li><a href="#showtime">showtime</a></li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
  </ul>
  <br><br>
  <b><u>Generated readings</u></b><br>
  - alarmcounter | counter started with 0<br>
  - state | (no Alarm, Alarm, Testalaram)<br>
  <br><br>
  <u><b>manual<br></b></u>
  <b>Pairing (Master-Slave)</b>  
  <ul>
    <li>Determine master<br>
  LEARN button push until the green LED lights on</li>
    <li>Determine slave<br>
  LEARN button push until the red LED lights on</li>
    <li>Master, hold down the TEST button until an alarm signal generated at all "Slaves"</li>
  </ul><br>
  <b>Standalone</b>
  <ul>
    <li>LEARN button push until the green LED lights on</li>
    <li>TEST button hold down until an alarm signal generated</li>
  </ul>
</ul>

=end html

=begin html_DE

<a name="FLAMINGO"></a>
<h3>FLAMINGO</h3>
<ul>
  Das FLAMINGO module dekodiert vom SIGNALduino empfangene Nachrichten des FLAMINGO FA20RF / FA21 / FA22RF Rauchmelders.<br>
  Von diesem Rauchmelder gibt es baugleiche Typen wie profitec KD101LA, POLLIN KD101LA oder renkforce LM-101LD.
  <br><br>

  <a name="FLAMINGOdefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; FLAMINGO &lt;code&gt; </code> <br>

    <br>
    &lt;code&gt; ist der automatisch angelegte eindeutige code  des FLAMINGO Rauchmelders. Dieser ändern sich nach
	dem Pairing mit einem Master.<br>
  </ul>
  <br>

  <a name="FLAMINGOset"></a>
  <b>Set</b>
  <ul>
  <li>Counterreset<br>
  - Alarmz&auml;hler auf 0 setzen</li>
  <li>Testalarm<br>
  - ausl&ouml;sen eines Testalarmes</li>
  </ul><br>

  <a name="FLAMINGOget"></a>
  <b>Get</b> <ul>N/A</ul><br><br>

  <a name="FLAMINGOattr"></a>
  <b>Attributes</b>
  <ul>
    <li><a href="#IODev">IODev (!)</a></li>
    <li><a href="#do_not_notify">do_not_notify</a></li>
    <li><a href="#eventMap">eventMap</a></li>
    <li><a href="#ignore">ignore</a></li>
	<a name="model"></a>
	<li>model<br>
	FA20RF, FA21RF, FA22RF, LM-101LD, unknown</li>
	<a name="showtime"></a>
    <li><a href="#showtime">showtime</a></li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
  </ul>
  <br><br>
  <b><u>Generierte Readings</u></b><br>
  - alarmcounter | Alarmz&auml;hler beginnend mit 0<br>
  - state | (no Alarm, Alarm, Testalaram)<br>
  <br><br>
  <u><b>Anleitung<br></b></u>
  <b>Melder paaren (Master-Slave Prinzip)</b>
  <ul>
  <li>Master bestimmen<br>
  LEARN-Taste bis gr&uuml;ne Anzeige LED leuchtet</li>
  <li>Slave bestimmen<br>
  LEARN-Taste bis rote Anzeige LED leuchtet</li>
  <li>Master, TEST-Taste gedr&uuml;ckt halten, bevor LEDś abschalten und alles "Slaves" ein Alarmsignal erzeugen</li>
  </ul><br>
  <b>Paarung aufheben / Standalone Betrieb</b>
  <ul>
  <li>LEARN-Taste bis gr&uuml;ne Anzeige LED leuchtet</li>
  <li>TEST-Taste gedr&uuml;ckt halten bis ein Alarmsignal erzeugt wird</li>
  </ul>
</ul>

=end html_DE
=cut
