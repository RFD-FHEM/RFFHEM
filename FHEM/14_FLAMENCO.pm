##############################################
# $Id: 14_FLAMENCO.pm 3818 2016-08-15 $
package main;

use strict;
use warnings;


my %flamenco_c2b;


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
FLAMENCO_Initialize($)
{
  my ($hash) = @_;
  
    
  
  $hash->{Match}     = "P13#[A-Fa-f0-9]+";
  $hash->{SetFn}     = "FLAMENCO_Set";
#  $hash->{StateFn}   = "FLAMENCO_SetState";
  $hash->{DefFn}     = "FLAMENCO_Define";
  $hash->{UndefFn}   = "FLAMENCO_Undef";
  $hash->{AttrFn}    = "FLAMENCO_Attr";
  $hash->{ParseFn}   = "FLAMENCO_Parse";
  $hash->{AttrList}  = "IODev FA20RFrepetition do_not_notify:0,1 showtime:0,1 ignore:0,1 model:FA20RF,FA21RF ".
  $readingFnAttributes;
}

sub FLAMENCO_SetState($$$$){ ###################################################
  my ($hash, $tim, $vt, $val) = @_;
  $val = $1 if($val =~ m/^(.*) \d+$/);
  return "Undefined value $val" if(!defined($flamenco_c2b{$val}));
  return undef;
}

sub
FLAMENCO_Do_On_Till($@)
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
  FLAMENCO_Set($hash, @b);
  my $tname = $hash->{NAME} . "_till";
  CommandDelete(undef, $tname) if($defs{$tname});
  CommandDefine(undef, "$tname at $hms_till set $a[0] off");

}

sub
FLAMENCO_On_For_Timer($@)
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
  FLAMENCO_Set($hash, @b);
  my $tname = $hash->{NAME} . "_till";
  CommandDelete(undef, $tname) if($defs{$tname});
  CommandDefine(undef, "$tname at $hms_till set $a[0] off");

}

#####################################
sub
FLAMENCO_Define($$)
{
	my ($hash, $def) = @_;
	my @a = split("[ \t][ \t]*", $def);

	return "wrong syntax: define <name> FLAMENCO <code> ".int(@a) if(int(@a) < 3 );

	$hash->{CODE} = $a[2];
	$hash->{lastMSG} =  "";
	$hash->{bitMSG} =  "";

	$modules{FLAMENCO}{defptr}{$a[2]} = $hash;
	$hash->{STATE} = "Defined";

	my $name= $hash->{NAME};


	if(!defined $hash->{IODev} ||!defined $hash->{IODev}{NAME}){	
		AssignIoPort($hash);
  	};  
	
	return undef; 
 
}

#####################################
sub
FLAMENCO_Undef($$)
{
  my ($hash, $name) = @_;
  delete($modules{FLAMENCO}{defptr}{$hash->{CODE}}) if($hash && $hash->{CODE});
  return undef;
}

sub FLAMENCO_Set($@){ ##########################################################
  
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
	
	
	return FLAMENCO_Do_On_Till($hash, @args) if($args[1] eq "on-till");
	return "Bad time spec" if($na == 3 && $args[2] !~ m/^\d*\.?\d+$/);
	
	return FLAMENCO_On_For_Timer($hash, @args) if($args[1] eq "on-for-timer");
	# return "Bad time spec" if($na == 1 && $args[2] !~ m/^\d*\.?\d+$/);

	my $io = $hash->{IODev};

	my $v = join(" ", @args);
	$message = "P13#".$hash->{CODE}."#R7";
  
	Log GetLogLevel($args[0],2), "FLAMENCO set $v";
	(undef, $v) = split(" ", $v, 2);	# Not interested in the name...

	## Send Message to IODev and wait for correct answer
	Log3 $hash, 5, "Messsage an IO senden Message raw: $message";
  
	IOWrite($io,'sendMsg',$message);
  
	return $ret;
}

#####################################
sub
FLAMENCO_Parse($$)
{
 	my ($iohash, $msg) = @_;
	#my $rawData = substr($msg, 2);
	my $name = $iohash->{NAME};
	my ($protocol,$rawData) = split("#",$msg);
	$protocol=~ s/^[P](\d+)/$1/; # extract protocol
	


	my $deviceCode = $rawData;  	# Message is in hex "4d4efd"
	


  
	my $def = $modules{FLAMENCO}{defptr}{$iohash->{NAME} . "." . $deviceCode};
	$def = $modules{FLAMENCO}{defptr}{$deviceCode} if(!$def);
	if(!$def) {
    	Log3 $iohash, 1, "FLAMENCO UNDEFINED sensor FLAMENCO detected, code $deviceCode";
		return "UNDEFINED FLAMENCO_$deviceCode FLAMENCO $deviceCode";
	}
  
	my $hash = $def;
	my $name = $hash->{NAME};
	return "" if(IsIgnored($name));
  
	Log3 $name, 5, "FLAMENCO: actioncode: $deviceCode";  
	$hash->{lastReceive} = time();
	  
	Log3 $name, 4, "FLAMENCO: $name: is sending Alarm";

 	readingsBeginUpdate($hash);
 	readingsBulkUpdate($hash, "state", "Alarm");
	readingsEndUpdate($hash, 1); # Notify is done by Dispatch
	InternalTimer(gettimeofday()+$hash->{Interval}, "FLAMENCO_UpdateState", $hash, 0);	
  	return $name;
}

sub 
FLAMENCO_UpdateState($)
{
	my ($hash) = @_;
	my $name = $hash->{NAME};
	
	readingsBeginUpdate($hash);
 	readingsBulkUpdate($hash, "state", "no alarm");
	readingsEndUpdate($hash, 1); # Notify is done by Dispatch
	
	Log3 $name, 4, "FLAMENCO: $name: Alarm stopped";
}

sub
FLAMENCO_Attr(@)
{
  
  my @a = @_;

  # Make possible to use the same code for different logical devices when they
  # are received through different physical devices.
  return if($a[0] ne "set" || $a[2] ne "IODev");
  my $hash = $defs{$a[1]};
  my $iohash = $defs{$a[3]};
  my $cde = $hash->{CODE};
  delete($modules{FLAMENCO}{defptr}{$cde});
  $modules{FLAMENCO}{defptr}{$iohash->{NAME} . "." . $cde} = $hash;
  return undef;
}


1;

=pod
=begin html

<a name="FLAMENCO"></a>
<h3>FLAMENCO</h3>
<ul>
  The FLAMENCO module interprets Flamenco FA20RF/FA21 type of messages received by the SIGNALduino.
  <br><br>

  <a name="FLAMENCOdefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; FLAMENCO &lt;code&gt;</code> <br>

    <br>
    &lt;code&gt; is the unic code of the autogenerated address of the Flamenco device. This changes, after pairing to the master<br>
  </ul>
  <br>

  <a name="FLAMENCOset"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="FLAMENCOget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="FLAMENCOattr"></a>
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

<a name="FLAMENCO"></a>
<h3>FLAMENCO</h3>
<ul>
  Das FLAMENCO module dekodiert vom SIGNALduino empfangene Nachrichten des Flamenco FA20RF / FA21RF Rauchmelders.
  <br><br>

  <a name="FLAMENCOdefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; FLAMENCO &lt;code&gt; </code> <br>

    <br>
    &lt;code&gt; ist der automatisch angelegte eindeutige code  des Flamenco Rauchmelders. Dieser ändern sich nach
	dem Pairing mit einem Master.<br>
  </ul>
  <br>

  <a name="FLAMENCOset"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="FLAMENCOget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="FLAMENCOattr"></a>
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