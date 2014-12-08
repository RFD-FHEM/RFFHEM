###########################################
# FHEMduino ARC Modul (Remote/Switch)
# $Id: 14_FHEMduino_ARC.pm 0002 2014-12-03 NButzek
# The file is taken from the fhemduino project
# see http://www.fhemwiki.de/wiki/FHEMduino
# and was modified by a few additions
# to provide support for self build sensors.
# The purpos is to use it as addition to the fhemduino
# modules in combination with RFDuino
# N. Butzek, S. Butzek, 2014 
#
#

package main;

use strict;
use warnings;

use SetExtensions;

my %codes = (
  "XMIToff" 		=> "off",
  "XMITon" 			=> "on",
  );

my %elro_c2b;

my $it_def_repetition = 10;   ## Default number of InterTechno Repetitions

my $it_simple ="off on";
my %models = (
  itremote    => 'sender',
  itswitch    => 'simple',
  itdimmer    => 'dimmer',
  );

# Supports following devices:
# - IT selflearning
#####################################
sub FHEMduino_ARC_Initialize($){ ####################################################
  my ($hash) = @_;

  foreach my $k (keys %codes) {
    $elro_c2b{$codes{$k}} = $k;
  }
  
  $hash->{Match}     = "^AR.?\$";
  $hash->{SetFn}     = "FHEMduino_ARC_Set";
  $hash->{StateFn}   = "FHEMduino_ARC_SetState";
  $hash->{DefFn}     = "FHEMduino_ARC_Define";
  $hash->{UndefFn}   = "FHEMduino_ARC_Undef";
  $hash->{AttrFn}    = "FHEMduino_ARC_Attr";
  $hash->{ParseFn}   = "FHEMduino_ARC_Parse";
  $hash->{AttrList}  = "IODev ITrepetition do_not_notify:0,1 showtime:0,1 ignore:0,1 model:itremote,itswitch,itdimmer".
  $readingFnAttributes;
}

sub FHEMduino_ARC_SetState($$$$){ ###################################################
  my ($hash, $tim, $vt, $val) = @_;
  $val = $1 if($val =~ m/^(.*) \d+$/);
  return "Undefined value $val" if(!defined($elro_c2b{$val}));
  return undef;
}

sub
FHEMduino_ARC_Do_On_Till($@)
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
  FHEMduino_ARC_Set($hash, @b);
  my $tname = $hash->{NAME} . "_till";
  CommandDelete(undef, $tname) if($defs{$tname});
  CommandDefine(undef, "$tname at $hms_till set $a[0] off");

}

sub
FHEMduino_ARC_On_For_Timer($@)
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
  FHEMduino_ARC_Set($hash, @b);
  my $tname = $hash->{NAME} . "_till";
  CommandDelete(undef, $tname) if($defs{$tname});
  CommandDefine(undef, "$tname at $hms_till set $a[0] off");

}

sub FHEMduino_ARC_Define($$){ #######################################################

  my ($hash, $def) = @_; #an die Funktion übergebene Parameter

  Log3 $hash, 3, "Define: $def";

  my @a = split("[ \t][ \t]*", $def); #@a - array

  return "wrong syntax: define <name> FHEMduino_ARC <code>".int(@a)
		if(int(@a) < 3 || int(@a) > 8);
  my $name = $a[0];
  my $code = $a[2];
  #my $basedur = "";

  Log3 undef, 5, "Arraylenght:  int(@a)";

  $hash->{CODE} = $code;
  $hash->{DEF} = $code;
  $hash->{XMIT} = $code;
  
  Log3 $hash, 5, "Define hascode: {$code}{$name}";

  $modules{FHEMduino_ARC}{defptr}{$code} = $hash;
  $hash->{$elro_c2b{"on"}}  = "FF";
  $hash->{$elro_c2b{"off"}} = "0F";
  $modules{FHEMduino_ARC}{defptr}{$code}{$name} = $hash;

  if(!defined $hash->{IODev} ||!defined $hash->{IODev}{NAME}){
   AssignIoPort($hash);
 };
 return undef;
}

sub FHEMduino_ARC_Set($@){ ##########################################################
  my ($hash, @a) = @_;
  my $ret = undef;
  my $na = int(@a);
  my $message;
  my $msg;
  my $hname = $hash->{NAME};
  my $name = $a[1];
  my ($repChanged, $recChanged, $durChanged) = 0;

  return "no set value specified" if($na < 2 || $na > 3);
  
  my $list = "";
  $list .= "off:noArg on:noArg on-till on-for-timer"; # if( AttrVal($hname, "model", "") ne "itremote" );
  $list .= "dimUp:noArg dimDown:noArg on-till" if( AttrVal($hname, "model", "") eq "itdimmer" );

  return SetExtensions($hash, $list, $hname, @a) if( $a[1] eq "?" );
  return SetExtensions($hash, $list, $hname, @a) if( !grep( $_ =~ /^$a[1]($|:)/, split( ' ', $list ) ) );

  my $c = $elro_c2b{$a[1]};

  return FHEMduino_ARC_Do_On_Till($hash, @a) if($a[1] eq "on-till");
  return "Bad time spec" if($na == 3 && $a[2] !~ m/^\d*\.?\d+$/);

  return FHEMduino_ARC_On_For_Timer($hash, @a) if($a[1] eq "on-for-timer");
  # return "Bad time spec" if($na == 1 && $a[2] !~ m/^\d*\.?\d+$/);

  if(!defined($c)) {

    # Model specific set arguments
    if(defined($attr{$a[0]}) && defined($attr{$a[0]}{"model"})) {
      my $mt = $models{$attr{$a[0]}{"model"}};
      return "Unknown argument $a[1], choose one of "
      if($mt && $mt eq "sender");
      return "Unknown argument $a[1], choose one of $it_simple"
      if($mt && $mt eq "simple");
    }
    return "Unknown argument $a[1], choose one of " . join(" ", sort keys %elro_c2b);
  }
  my $io = $hash->{IODev};

  ## Do we need to change ITrepetition ??	
  if(defined($attr{$a[0]}) && defined($attr{$a[0]}{"ITrepetition"})) {
    $message = "ir".$attr{$a[0]}{"ITrepetition"};
    $msg = CallFn($io->{NAME}, "GetFn", $io, (" ", "raw", $message));
    if ($msg =~ m/raw => $message/) {
 	  Log GetLogLevel($a[0],4), "FHEMduino_ARC: Set ITrepetition: $message for $io->{NAME}";
    } else {
 	  Log GetLogLevel($a[0],4), "FHEMduino_ARC: Error set ITrepetition: $message for $io->{NAME}";
    }
  }

  my $v = join(" ", @a);
  $message = "is".uc($hash->{XMIT}.$hash->{$c}.$hash->{BDUR});

  ## Log that we are going to switch InterTechno
  Log GetLogLevel($a[0],2), "FHEMduino_ARC set $v IO_name:$io->{NAME}";
  (undef, $v) = split(" ", $v, 2);	# Not interested in the name...

  ## Send Message to IODev and wait for correct answer
  Log3 $hash, 5, "Messsage an IO senden Message raw: $message";
  $msg = CallFn($io->{NAME}, "GetFn", $io, (" ", "raw", $message));
  if ($msg =~ m/raw => $message/) {
    Log3 $hash, 5, "Answer from $io->{NAME}: $msg";
  } else {
    Log3 $hash, 5, "FHEMduino_ARC IODev device didn't answer is command correctly: $msg";
  }

  ## Do we need to change ITrepetition back??	
  if(defined($attr{$a[0]}) && defined($attr{$a[0]}{"ITrepetition"})) {
    $message = "ir".$it_def_repetition;
    $msg = CallFn($io->{NAME}, "GetFn", $io, (" ", "raw", $message));
    if ($msg =~ m/raw => $message/) {
 	  Log GetLogLevel($a[0],4), "FHEMduino_ARC: Set ITrepetition back: $message for $io->{NAME}";
    } else {
 	  Log GetLogLevel($a[0],4), "FHEMduino_ARC: Error ITrepetition back: $message for $io->{NAME}";
    }
  }

  # Look for all devices with the same code, and set state, timestamp
  my $code = "$hash->{XMIT}";
  my $tn = TimeNow();

  $name = "$hash->{NAME}";

  foreach my $n (keys %{ $modules{FHEMduino_ARC}{defptr}{$code} }) {
    my $lh = $modules{FHEMduino_ARC}{defptr}{$code}{$n};
    $lh->{CHANGED}[0] = $v;
    $lh->{STATE} = $v;
    $lh->{READINGS}{state}{TIME} = $tn;
    $lh->{READINGS}{state}{VAL} = $v;
    $modules{FHEMduino_ARC}{defptr}{$code}{$name}  = $hash;
  }
  return $ret;
}

sub getButtonARC($$){ ###################################################################

#  ID: 0 till 25(Convert the binary code to decimal to get the correct id)
#  All: 26
#  State: 27
#  Unit: 28 till 31

  my ($hash,$msg) = @_;
  my $parsedID = "undef";
  my $parsedALL = "undef";
  my $parsedSTATE = "undef";
  my $parsedUNIT = "undef";

  my $msgmod = substr($msg,2);
  Log3 $hash, 5, "FHEMduino_ARC Message received: $msgmod";

  $parsedID = oct("0b".substr($msgmod,0,26));
  $parsedALL = oct("0b".substr($msgmod,26,1));
  $parsedSTATE = ((oct("0b".substr($msgmod,27,1))==1) ? "on":"off");
  $parsedUNIT = oct("0b".substr($msgmod,28,4));
  Log3 $hash, 5, "FHEMduino_ARC Message ID: $parsedID ALL: $parsedALL STATE: $parsedSTATE UNIT $parsedUNIT";
 
  if (($parsedID eq "undef") | ($parsedUNIT eq "undef") | ($parsedALL eq "undef") | ($parsedSTATE eq "undef")) {
    #Log3 $hash, 5, "Get button return/result: ID: " . $receivedHouseCode . $receivedButtonCode . "DEVICE: " . $parsedHouseCode . "_" . $parsedButtonCode . " ACTION: " . $parsedAction;
    return "";
  }
  return $parsedID . "_" . $parsedUNIT . " " . $parsedALL . " " . $parsedSTATE ;
}

sub FHEMduino_ARC_Parse($$){ ########################################################

  my ($hash,$msg) = @_;

  my $deviceCode = "";
  my $deviceALL = "";
  my $displayName = "";
  my $action = "";
  my $result = "";
  #my $basedur = "";
  
  #($msg, $basedur) = split m/_/, $msg, 2;

  Log3 $hash, 4, "Message: $msg";
  $result = getButtonARC($hash,$msg);

  if ($result ne "") {
    ($displayName,$deviceALL,$action) = split m/ /, $result, 3;
	$deviceCode = $displayName;
    Log3 $hash, 4, "Parse: Device: $displayName Code: $deviceCode Action: $action";

    my $def = $modules{FHEMduino_ARC}{defptr}{$hash->{NAME} . "." . $deviceCode};
    $def = $modules{FHEMduino_ARC}{defptr}{$deviceCode} if(!$def);

    if(!$def) {
      Log3 $hash, 5, "UNDEFINED Remotebutton send to define: $displayName";
      return "UNDEFINED FHEMduino_ARC_$displayName FHEMduino_ARC $deviceCode";
    }

    $hash = $def;

    my $name = $hash->{NAME};
    return "" if(IsIgnored($name));

    if(!$action) {
      Log3 $name, 5, "FHEMduino_ARC can't decode $msg";
      return "";
    }
    Log3 $name, 5, "FHEMduino_ARC actioncode: $action";

    readingsBeginUpdate($hash);
    readingsBulkUpdate($hash, "state", $action);
    readingsEndUpdate($hash, 1);
    return $name;
  }
  return "";
}

sub FHEMduino_ARC_Attr(@){ ##########################################################
  my @a = @_;

  # Make possible to use the same code for different logical devices when they
  # are received through different physical devices.
  return if($a[0] ne "set" || $a[2] ne "IODev");
  my $hash = $defs{$a[1]};
  my $iohash = $defs{$a[3]};
  my $cde = $hash->{CODE};
  delete($modules{FHEMduino_ARC}{defptr}{$cde});
  $modules{FHEMduino_ARC}{defptr}{$iohash->{NAME} . "." . $cde} = $hash;
  
  return undef;
}

sub FHEMduino_ARC_Undef($$){ ########################################################
  my ($hash, $name) = @_;
  delete($modules{FHEMduino_ARC}{defptr}{$hash->{CODE}}) if($hash && $hash->{CODE});
  return undef;
}



1;
