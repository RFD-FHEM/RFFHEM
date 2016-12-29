##############################################
# $Id: 14_FLAMINGO.pm 3818 2016-08-15 $
package main;

use strict;
use warnings;


my %FLAMINGO_c2b;


my %models = (
  itremote    => 'FA20',
  itswitch    => 'FA21',
  itdimmer    => 'KD101',
  );

my %sets = (
	"off" => "noArg",
	"on" => "noArg",
	"on-for-timer" => "textField",
	"on-till" => "textField",
);


#####################################
sub
FLAMINGO_Initialize($)
{
  my ($hash) = @_;
  
    
  
  $hash->{Match}     = "P13#[A-Fa-f0-9]+";
  $hash->{SetFn}     = "FLAMINGO_Set";
#  $hash->{StateFn}   = "FLAMINGO_SetState";
  $hash->{DefFn}     = "FLAMINGO_Define";
  $hash->{UndefFn}   = "FLAMINGO_Undef";
  $hash->{AttrFn}    = "FLAMINGO_Attr";
  $hash->{ParseFn}   = "FLAMINGO_Parse";
  $hash->{AttrList}  = "IODev FA20RFrepetition do_not_notify:0,1 showtime:0,1 ignore:0,1 model:FA20RF,FA21RF ".
 						$readingFnAttributes;
   $hash->{AutoCreate}=
    { 
        "FLAMINGO.*" => {  FILTER => "%NAME", autocreateThreshold => "2:180"},
    };
 
}

sub FLAMINGO_SetState($$$$){ ###################################################
  my ($hash, $tim, $vt, $val) = @_;
  $val = $1 if($val =~ m/^(.*) \d+$/);
  return "Undefined value $val" if(!defined($FLAMINGO_c2b{$val}));
  return undef;
}

sub
FLAMINGO_Do_On_Till($@)
{
  my ($hash, @a) = @_;
  return "Timespec (HH:MM[:SS]) needed for the on-till command" if(@a != 3);

  my ($err, $hr, $min, $sec, $fn) = GetTimeSpec($a[2]);
  return $err if($err);

  my @lt = localtime;
  my $hms_till = sprintf("%02d:%02d:%02d", $hr, $min, $sec);
  my $hms_now = sprintf("%02d:%02d:%02d", $lt[2], $lt[1], $lt[0]);
  if($hms_now ge $hms_till) {
    Log 4, "on-till: won't switch as now ($hms_now) is later than $hms_till";
    return "";
  }

  my @b = ($a[0], "on");
  FLAMINGO_Set($hash, @b);
  my $tname = $hash->{NAME} . "_till";
  CommandDelete(undef, $tname) if($defs{$tname});
  CommandDefine(undef, "$tname at $hms_till set $a[0] off");

}

sub
FLAMINGO_On_For_Timer($@)
{
  my ($hash, @a) = @_;
  return "Seconds are needed for the on-for-timer command" if(@a != 3);

  # my ($err, $hr, $min, $sec, $fn) = GetTimeSpec($a[2]);
  # return $err if($err);
  
  my @lt = localtime;
  my @tt = localtime(time + $a[2]);
  my $hms_till = sprintf("%02d:%02d:%02d", $tt[2], $tt[1], $tt[0]);
  my $hms_now = sprintf("%02d:%02d:%02d", $lt[2], $lt[1], $lt[0]);
  
  if($hms_now ge $hms_till) {
    Log 4, "on-for-timer: won't switch as now ($hms_now) is later than $hms_till";
    return "";
  }

  my @b = ($a[0], "on");
  FLAMINGO_Set($hash, @b);
  my $tname = $hash->{NAME} . "_till";
  CommandDelete(undef, $tname) if($defs{$tname});
  CommandDefine(undef, "$tname at $hms_till set $a[0] off");

}

#####################################
sub
FLAMINGO_Define($$)
{
	my ($hash, $def) = @_;
	my @a = split("[ \t][ \t]*", $def);

	return "wrong syntax: define <name> FLAMINGO <code> ".int(@a) if(int(@a) < 3 );

	$hash->{CODE} = $a[2];
	$hash->{lastMSG} =  "";
	$hash->{bitMSG} =  "";

	$modules{FLAMINGO}{defptr}{$a[2]} = $hash;
	$hash->{STATE} = "Defined";

	my $name= $hash->{NAME};


	if(!defined $hash->{IODev} ||!defined $hash->{IODev}{NAME}){	
		AssignIoPort($hash);
  	};  
	
	return undef; 
 
}

#####################################
sub
FLAMINGO_Undef($$)
{
  my ($hash, $name) = @_;
  delete($modules{FLAMINGO}{defptr}{$hash->{CODE}}) if($hash && $hash->{CODE});
  return undef;
}

sub FLAMINGO_Set($@){ ##########################################################
  
	my ( $hash, $name, @args ) = @_;
	my $hname = $hash->{NAME};
	
	my $na = int(@args);
	return "no set value specified" if($na < 2 || $na > 3);
	
	my $ret = undef;
	my $message;
	my $msg;
	my $list = join (" ",keys %sets);
	
	
	return SetExtensions($hash, $list, $hname, @args) if( $args[1] eq "?" );
	return SetExtensions($hash, $list, $hname, @args) if( !grep( $_ =~ /^$args[1]($|:)/, split( ' ', $list ) ) );
	
	
	return FLAMINGO_Do_On_Till($hash, @args) if($args[1] eq "on-till");
	return "Bad time spec" if($na == 3 && $args[2] !~ m/^\d*\.?\d+$/);
	
	return FLAMINGO_On_For_Timer($hash, @args) if($args[1] eq "on-for-timer");
	# return "Bad time spec" if($na == 1 && $args[2] !~ m/^\d*\.?\d+$/);

	my $io = $hash->{IODev};

	my $v = join(" ", @args);
	$message = "P13#".$hash->{CODE}."#R7";
  
	Log GetLogLevel($args[0],2), "FLAMINGO set $v";
	(undef, $v) = split(" ", $v, 2);	# Not interested in the name...

	## Send Message to IODev and wait for correct answer
	Log3 $hash, 5, "Messsage an IO senden Message raw: $message";
  
	IOWrite($io,'sendMsg',$message);
  
	return $ret;
}

#####################################
sub
FLAMINGO_Parse($$)
{
 	my ($iohash, $msg) = @_;
	#my $rawData = substr($msg, 2);
	#my $name = $iohash->{NAME};
	my ($protocol,$rawData) = split("#",$msg);
	$protocol=~ s/^[P](\d+)/$1/; # extract protocol
	


	my $deviceCode = $rawData;  	# Message is in hex "4d4efd"
	


  
	my $def = $modules{FLAMINGO}{defptr}{$iohash->{NAME} . "." . $deviceCode};
	$def = $modules{FLAMINGO}{defptr}{$deviceCode} if(!$def);
	if(!$def) {
    	Log3 $iohash, 1, "FLAMINGO UNDEFINED sensor FLAMINGO detected, code $deviceCode";
		return "UNDEFINED FLAMINGO_$deviceCode FLAMINGO $deviceCode";
	}
  
	my $hash = $def;
	my $name = $hash->{NAME};
	return "" if(IsIgnored($name));
  
	Log3 $name, 5, "FLAMINGO: actioncode: $deviceCode";  
	$hash->{lastReceive} = time();
	  
	Log3 $name, 4, "FLAMINGO: $name: is sending Alarm";

 	readingsBeginUpdate($hash);
 	readingsBulkUpdate($hash, "state", "Alarm");
	readingsEndUpdate($hash, 1); # Notify is done by Dispatch
	InternalTimer(gettimeofday()+$hash->{Interval}, "FLAMINGO_UpdateState", $hash, 0);	
  	return $name;
}

sub 
FLAMINGO_UpdateState($)
{
	my ($hash) = @_;
	my $name = $hash->{NAME};
	
	readingsBeginUpdate($hash);
 	readingsBulkUpdate($hash, "state", "no alarm");
	readingsEndUpdate($hash, 1); # Notify is done by Dispatch
	
	Log3 $name, 4, "FLAMINGO: $name: Alarm stopped";
}

sub
FLAMINGO_Attr(@)
{
  
  my @a = @_;

  # Make possible to use the same code for different logical devices when they
  # are received through different physical devices.
  return if($a[0] ne "set" || $a[2] ne "IODev");
  my $hash = $defs{$a[1]};
  my $iohash = $defs{$a[3]};
  my $cde = $hash->{CODE};
  delete($modules{FLAMINGO}{defptr}{$cde});
  $modules{FLAMINGO}{defptr}{$iohash->{NAME} . "." . $cde} = $hash;
  return undef;
}


1;

=pod
=begin html

<a name="FLAMINGO"></a>
<h3>FLAMINGO</h3>
<ul>
  The FLAMINGO module interprets FLAMINGO FA20RF/FA21 type of messages received by the SIGNALduino.
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
  <b>Set</b> <ul>N/A</ul><br>

  <a name="FLAMINGOget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="FLAMINGOattr"></a>
  <b>Attributes</b>
  <ul>
    <li><a href="#IODev">IODev (!)</a></li>
    <li><a href="#do_not_notify">do_not_notify</a></li>
    <li><a href="#eventMap">eventMap</a></li>
    <li><a href="#ignore">ignore</a></li>
    <li><a href="#model">model</a> (LogiLink FA20RF)</li>
    <li><a href="#showtime">showtime</a></li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
  </ul>
  <br>
</ul>

=end html

=begin html_DE

<a name="FLAMINGO"></a>
<h3>FLAMINGO</h3>
<ul>
  Das FLAMINGO module dekodiert vom SIGNALduino empfangene Nachrichten des FLAMINGO FA20RF / FA21RF Rauchmelders.
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
  <b>Set</b> <ul>N/A</ul><br>

  <a name="FLAMINGOget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="FLAMINGOattr"></a>
  <b>Attributes</b>
  <ul>
    <li><a href="#IODev">IODev (!)</a></li>
    <li><a href="#do_not_notify">do_not_notify</a></li>
    <li><a href="#eventMap">eventMap</a></li>
    <li><a href="#ignore">ignore</a></li>
    <li><a href="#model">model</a> (FA20RF)</li>
    <li><a href="#showtime">showtime</a></li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
  </ul>
  <br>
</ul>

=end html_DE
=cut