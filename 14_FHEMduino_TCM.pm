##############################################
# $Id: 14_FHEMduino_TCM.pm 3818 2014-06-24 $
package main;

use strict;
use warnings;

my %codes = (
  "XMIToff" 		=> "off",
  "XMITon" 		=> "on",
  );

my %elro_c2b;

my $TCM_defrepetition = 14;   ## Default number of TCM Repetitions

my $fa20rf_simple ="off on";
my %models = (
  tchibo    => 'TCM',
  );

#####################################
sub
FHEMduino_TCM_Initialize($)
{
  my ($hash) = @_;
  
  foreach my $k (keys %codes) {
    $elro_c2b{$codes{$k}} = $k;
  }
  
  $hash->{Match}     = "M.....\$";
  $hash->{SetFn}     = "FHEMduino_TCM_Set";
  $hash->{StateFn}   = "FHEMduino_TCM_SetState";
  $hash->{DefFn}     = "FHEMduino_TCM_Define";
  $hash->{UndefFn}   = "FHEMduino_TCM_Undef";
  $hash->{AttrFn}    = "FHEMduino_TCM_Attr";
  $hash->{ParseFn}   = "FHEMduino_TCM_Parse";
  $hash->{AttrList}  = "IODev TCMrepetition do_not_notify:0,1 showtime:0,1 ignore:0,1 model:TCM,RM150RF,KD101".
  $readingFnAttributes;
}

sub FHEMduino_TCM_SetState($$$$){ ###################################################
  my ($hash, $tim, $vt, $val) = @_;
  $val = $1 if($val =~ m/^(.*) \d+$/);
  return "Undefined value $val" if(!defined($elro_c2b{$val}));
  return undef;
}

sub
FHEMduino_TCM_Do_On_Till($@)
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
  FHEMduino_TCM_Set($hash, @b);
  my $tname = $hash->{NAME} . "_till";
  CommandDelete(undef, $tname) if($defs{$tname});
  CommandDefine(undef, "$tname at $hms_till set $a[0] off");

}

sub
FHEMduino_TCM_On_For_Timer($@)
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
  FHEMduino_TCM_Set($hash, @b);
  my $tname = $hash->{NAME} . "_till";
  CommandDelete(undef, $tname) if($defs{$tname});
  CommandDefine(undef, "$tname at $hms_till set $a[0] off");

}

#####################################
sub
FHEMduino_TCM_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);

  return "wrong syntax: define <name> FHEMduino_TCM TCM".int(@a)
		if(int(@a) < 2 || int(@a) > 5);

  my $name = $a[0];
  my $TCMcode = $a[2];
  my $code = lc($TCMcode); 
  my $onTCM = "";

  if(int(@a) == 3) {
  }
  elsif(int(@a) == 5) {
    $onTCM = $a[3];
  }
  else {
    return "wrong syntax: define <name> FHEMduino_TCM <code>";
  }

  Log3 undef, 5, "Arraylenght:  int(@a)";

  $hash->{CODE} = $TCMcode;
  $hash->{DEF} = $TCMcode . " " . $onTCM;
  $hash->{XMIT} = hex2bin($code);
  $hash->{BTN}  = hex2bin($code);
  
  Log3 $hash, 5, "Define hascode: {$code} {$name}";
  $modules{FHEMduino_TCM}{defptr}{$TCMcode} = $hash;
  $hash->{$elro_c2b{"on"}}  = hex2bin($code);
  $hash->{$elro_c2b{"off"}}  = hex2bin($code);
  $modules{FHEMduino_TCM}{defptr}{$code}{$name} = $hash;

  if(!defined $hash->{IODev} ||!defined $hash->{IODev}{NAME}){
   AssignIoPort($hash);
  };  
  return undef;
}

#####################################
sub
FHEMduino_TCM_Undef($$)
{
  my ($hash, $name) = @_;
  delete($modules{FHEMduino_TCM}{defptr}{$hash->{CODE}}) if($hash && $hash->{CODE});
  return undef;
}

sub FHEMduino_TCM_Set($@){ ##########################################################
  my ($hash, @a) = @_;
  my $ret = undef;
  my $na = int(@a);
  my $message;
  my $msg;
  my $hname = $hash->{NAME};
  my $name = $a[1];

  return "no set value specified" if($na < 2 || $na > 3);
  
  my $list = "";
  $list .= "on:noArg off:noArg on-till on-for-timer"; # if( AttrVal($hname, "model", "") ne "itremote" );

  return SetExtensions($hash, $list, $hname, @a) if( $a[1] eq "?" );
  return SetExtensions($hash, $list, $hname, @a) if( !grep( $_ =~ /^$a[1]($|:)/, split( ' ', $list ) ) );

  my $c = $elro_c2b{$a[1]};

  return FHEMduino_TCM_Do_On_Till($hash, @a) if($a[1] eq "on-till");
  return "Bad time spec" if($na == 3 && $a[2] !~ m/^\d*\.?\d+$/);

  return FHEMduino_TCM_On_For_Timer($hash, @a) if($a[1] eq "on-for-timer");
  # return "Bad time spec" if($na == 1 && $a[2] !~ m/^\d*\.?\d+$/);

  if(!defined($c)) {

   # Model specific set arguments
   if(defined($attr{$a[0]}) && defined($attr{$a[0]}{"model"})) {
     my $mt = $models{$attr{$a[0]}{"model"}};
     return "Unknown argument $a[1], choose one of "
     if($mt && $mt eq "sender");
     return "Unknown argument $a[1], choose one of $fa20rf_simple"
     if($mt && $mt eq "simple");
   }
   return "Unknown argument $a[1], choose one of " . join(" ", sort keys %elro_c2b);
 }
 my $io = $hash->{IODev};

 ## Do we need to change RFMode to SlowRF?? // Not implemented in fhemduino -> see fhemduino.pm
  if(defined($attr{$a[0]}) && defined($attr{$a[0]}{"switch_rfmode"})) {
  	if ($attr{$a[0]}{"switch_rfmode"} eq "1") {			# do we need to change RFMode of IODev
      my $ret = CallFn($io->{NAME}, "AttrFn", "set", ($io->{NAME}, "rfmode", "SlowRF"));
    }	
  }

  ## Do we need to change TCMrepetition ??	
  if(defined($attr{$a[0]}) && defined($attr{$a[0]}{"TCMrepetition"})) {
  	$message = "dr".$attr{$a[0]}{"TCMrepetition"};
    $msg = CallFn($io->{NAME}, "GetFn", $io, (" ", "raw", $message));
    if ($msg =~ m/raw => $message/) {
 	  Log GetLogLevel($a[0],4), "FHEMduino_TCM: Set TCMrepetition: $message for $io->{NAME}";
    } else {
 	  Log GetLogLevel($a[0],4), "FHEMduino_TCM: Error set TCMrepetition: $message for $io->{NAME}";
    }
  }

  my $v = join(" ", @a);
  $message = "ds".$hash->{XMIT};

  ## Log that we are going to switch InterTechno
  Log GetLogLevel($a[0],2), "FHEMduino_TCM set $v";
  (undef, $v) = split(" ", $v, 2);	# Not interested in the name...

  ## Send Message to IODev and wait for correct answer
  Log3 $hash, 5, "Messsage an IO senden Message raw: $message";
  $msg = CallFn($io->{NAME}, "GetFn", $io, (" ", "raw", $message));
  if ($msg =~ m/raw => $message/) {
    Log3 $hash, 5, "FHEMduino_TCM: Answer from $io->{NAME}: $msg";
  } else {
    Log3 $hash, 5, "FHEMduino_TCM: IODev device didn't answer is command correctly: $msg";
  }

  ## Do we need to change FArepetition back??	
  if(defined($attr{$a[0]}) && defined($attr{$a[0]}{"TCMrepetition"})) {
  	$message = "dr".$TCM_defrepetition;
    $msg = CallFn($io->{NAME}, "GetFn", $io, (" ", "raw", $message));
    if ($msg =~ m/raw => $message/) {
 	  Log GetLogLevel($a[0],4), "FHEMduino_TCM: Set TCMrepetition back: $message for $io->{NAME}";
    } else {
 	  Log GetLogLevel($a[0],4), "FHEMduino_TCM: Error TCMrepetition back: $message for $io->{NAME}";
    }
  }

  # Look for all devices with the same code, and set state, timestamp
  $name = "$hash->{NAME}";
  my $code = "$hash->{XMIT}";
  my $tn = TimeNow();

  foreach my $n (keys %{ $modules{FHEMduino_TCM}{defptr}{$code} }) {
    my $lh = $modules{FHEMduino_TCM}{defptr}{$code}{$n};
    $lh->{CHANGED}[0] = $v;
    $lh->{STATE} = $v;
    $lh->{READINGS}{state}{TIME} = $tn;
    $lh->{READINGS}{state}{VAL} = $v;
    $modules{FHEMduino_TCM}{defptr}{$code}{$name}  = $hash;
  }
  return $ret;
}

#####################################
sub
FHEMduino_TCM_Parse($$)
{
  my ($hash,$msg) = @_;
  my @a = split("", $msg);

  my $deviceCode = $a[1].$a[2].$a[3].$a[4].$a[5];
  
  my $def = $modules{FHEMduino_TCM}{defptr}{$hash->{NAME} . "." . $deviceCode};
  $def = $modules{FHEMduino_TCM}{defptr}{$deviceCode} if(!$def);
  if(!$def) {
    Log3 $hash, 1, "FHEMduino_TCM UNDEFINED sensor TCM detected, code $deviceCode";
    return "UNDEFINED TCM_$deviceCode FHEMduino_TCM $deviceCode";
  }
  
  $hash = $def;
  my $name = $hash->{NAME};
  return "" if(IsIgnored($name));
  
  Log3 $name, 5, "FHEMduino_TCM: actioncode: $deviceCode";  
  
  $hash->{lastReceive} = time();
  $hash->{lastValues}{BITS} = $deviceCode;

  Log3 $name, 4, "FHEMduino_TCM: $name: $deviceCode:";

  readingsBeginUpdate($hash);
  readingsBulkUpdate($hash, "state", $deviceCode);
  readingsEndUpdate($hash, 1); # Notify is done by Dispatch

  return $name;
}

sub
FHEMduino_TCM_Attr(@)
{
  my @a = @_;

  # Make possible to use the same code for different logical devices when they
  # are received through different physical devices.
  return if($a[0] ne "set" || $a[2] ne "IODev");
  my $hash = $defs{$a[1]};
  my $iohash = $defs{$a[3]};
  my $cde = $hash->{CODE};
  delete($modules{FHEMduino_TCM}{defptr}{$cde});
  $modules{FHEMduino_TCM}{defptr}{$iohash->{NAME} . "." . $cde} = $hash;
  return undef;
}

sub
hex2bin($)
{
  my $h = shift;
  my $hlen = length($h);
  my $blen = $hlen * 4;
  return unpack("B$blen", pack("H$hlen", $h));
}

1;

=pod
=begin html

<a name="FHEMduino_TCM"></a>
<h3>FHEMduino_TCM</h3>
<ul>
  The FHEMduino_TCM module interprets LogiLink TCM type of messages received by the FHEMduino.
  <br><br>

  <a name="FHEMduino_TCMdefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; FHEMduino_TCM &lt;code&gt;</code> <br>

    <br>
    &lt;code&gt; is the housecode of the autogenerated address of the TCM device and 
	is build by the channelnumber (1 to 3) and an autogenerated address build when including
	the battery (adress will change every time changing the battery).<br>
  </ul>
  <br>

  <a name="FHEMduino_TCMset"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="FHEMduino_TCMget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="FHEMduino_TCMattr"></a>
  <b>Attributes</b>
  <ul>
    <li><a href="#IODev">IODev (!)</a></li>
    <li><a href="#do_not_notify">do_not_notify</a></li>
    <li><a href="#eventMap">eventMap</a></li>
    <li><a href="#ignore">ignore</a></li>
    <li><a href="#model">model</a> (LogiLink TCM)</li>
    <li><a href="#showtime">showtime</a></li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
  </ul>
  <br>
</ul>

=end html

=begin html_DE

<a name="FHEMduino_TCM"></a>
<h3>FHEMduino_TCM</h3>
<ul>
  Das FHEMduino_TCM module dekodiert vom FHEMduino empfangene Nachrichten des LogiLink TCM.
  <br><br>

  <a name="FHEMduino_TCMdefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; FHEMduino_TCM &lt;code&gt; </code> <br>

    <br>
    &lt;code&gt; ist der automatisch angelegte Hauscode des TCM. Dieser ändern sich nach
	dem Pairing mit einem Master.<br>
  </ul>
  <br>

  <a name="FHEMduino_TCMset"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="FHEMduino_TCMget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="FHEMduino_TCMattr"></a>
  <b>Attributes</b>
  <ul>
    <li><a href="#IODev">IODev (!)</a></li>
    <li><a href="#do_not_notify">do_not_notify</a></li>
    <li><a href="#eventMap">eventMap</a></li>
    <li><a href="#ignore">ignore</a></li>
    <li><a href="#model">model</a> (LogiLink TCM)</li>
    <li><a href="#showtime">showtime</a></li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
  </ul>
  <br>
</ul>

=end html_DE
=cut
