###########################################
# FHEMduino PT2262 Modul (Remote/Switch)
# $Id: 14_FHEMduino_PT2262.pm 0002 2014-05-28 snoop & mdorenka $
# 2014-06-15: SetExtension und on-till und on-for-timer implementiert
# The file is taken from the fhemduino project
# see http://www.fhemwiki.de/wiki/FHEMduino
# and was modified by a few additions
# to provide support for self build sensors.
# The purpos is to use it as addition to the fhemduino
# modules in combination with RFDuino
# N. Butzek, S. Butzek, 2014 
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
# - PT2262
# - DÜWI  
#####################################
sub FHEMduino_PT2262_Initialize($){ ####################################################
  my ($hash) = @_;

  foreach my $k (keys %codes) {
    $elro_c2b{$codes{$k}} = $k;
  }
  
  $hash->{Match}     = "^IR.?\$";
  $hash->{SetFn}     = "FHEMduino_PT2262_Set";
  $hash->{StateFn}   = "FHEMduino_PT2262_SetState";
  $hash->{DefFn}     = "FHEMduino_PT2262_Define";
  $hash->{UndefFn}   = "FHEMduino_PT2262_Undef";
  $hash->{AttrFn}    = "FHEMduino_PT2262_Attr";
  $hash->{ParseFn}   = "FHEMduino_PT2262_Parse";
  $hash->{AttrList}  = "IODev ITrepetition do_not_notify:0,1 showtime:0,1 ignore:0,1 model:itremote,itswitch,itdimmer".
  $readingFnAttributes;
}

sub FHEMduino_PT2262_SetState($$$$){ ###################################################
  my ($hash, $tim, $vt, $val) = @_;
  $val = $1 if($val =~ m/^(.*) \d+$/);
  return "Undefined value $val" if(!defined($elro_c2b{$val}));
  return undef;
}

sub
FHEMduino_PT2262_Do_On_Till($@)
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
  FHEMduino_PT2262_Set($hash, @b);
  my $tname = $hash->{NAME} . "_till";
  CommandDelete(undef, $tname) if($defs{$tname});
  CommandDefine(undef, "$tname at $hms_till set $a[0] off");

}

sub
FHEMduino_PT2262_On_For_Timer($@)
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
  FHEMduino_PT2262_Set($hash, @b);
  my $tname = $hash->{NAME} . "_till";
  CommandDelete(undef, $tname) if($defs{$tname});
  CommandDefine(undef, "$tname at $hms_till set $a[0] off");

}

sub FHEMduino_PT2262_Define($$){ #######################################################

  my ($hash, $def) = @_;

  Log3 $hash, 3, "Define: $def";

  my @a = split("[ \t][ \t]*", $def);

  my $name = $a[0];

  my $tristatecode = $a[2];
  my $basedur = "";

  if (index($a[2], "_") != -1) {
    ($tristatecode, $basedur) = split m/_/, $a[2], 2;
  } else {
    $tristatecode = $a[2];
  }

  my $code = lc($tristatecode); 

  my $ontristate = "FF";
  my $offtristate = "F0";

  if(int(@a) == 3) {
  }
  elsif(int(@a) == 5) {
    $ontristate = $a[3];
    $offtristate = $a[4];
  }
  elsif(int(@a) == 6) {
    $basedur = $a[3];
    $ontristate = $a[4];
    $offtristate = $a[5];
  }
  else {
    return "wrong syntax: define <name> FHEMduino_PT2262 <code>";
  }

  Log3 undef, 5, "Arraylenght:  int(@a)";

  $hash->{CODE} = $tristatecode;
  if ($basedur ne "") {
    $hash->{DEF} = $tristatecode. " " . $basedur . " " . $ontristate . " " . $offtristate;
    $hash->{BDUR} = $basedur;
  } else {
    $hash->{DEF} = $tristatecode. " " . $ontristate . " " . $offtristate;
  }

  $hash->{XMIT} = lc($tristatecode);
  
  Log3 $hash, 5, "Define hascode: {$tristatecode}{$name}";

  $modules{FHEMduino_PT2262}{defptr}{$tristatecode} = $hash;
  $hash->{$elro_c2b{"on"}}  = lc($ontristate);
  $hash->{$elro_c2b{"off"}} = lc($offtristate);
  $modules{FHEMduino_PT2262}{defptr}{$code}{$name} = $hash;

  if(!defined $hash->{IODev} ||!defined $hash->{IODev}{NAME}){
   AssignIoPort($hash);
 };
 return undef;
}

sub FHEMduino_PT2262_Set($@){ ##########################################################
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

  return FHEMduino_PT2262_Do_On_Till($hash, @a) if($a[1] eq "on-till");
  return "Bad time spec" if($na == 3 && $a[2] !~ m/^\d*\.?\d+$/);

  return FHEMduino_PT2262_On_For_Timer($hash, @a) if($a[1] eq "on-for-timer");
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
 	  Log GetLogLevel($a[0],4), "FHEMduino_PT2262: Set ITrepetition: $message for $io->{NAME}";
    } else {
 	  Log GetLogLevel($a[0],4), "FHEMduino_PT2262: Error set ITrepetition: $message for $io->{NAME}";
    }
  }

  my $v = join(" ", @a);
  $message = "is".uc($hash->{XMIT}.$hash->{$c}.$hash->{BDUR});

  ## Log that we are going to switch InterTechno
  Log GetLogLevel($a[0],2), "FHEMduino_PT2262 set $v IO_name:$io->{NAME}";
  (undef, $v) = split(" ", $v, 2);	# Not interested in the name...

  ## Send Message to IODev and wait for correct answer
  Log3 $hash, 5, "Messsage an IO senden Message raw: $message";
  $msg = CallFn($io->{NAME}, "GetFn", $io, (" ", "raw", $message));
  if ($msg =~ m/raw => $message/) {
    Log3 $hash, 5, "Answer from $io->{NAME}: $msg";
  } else {
    Log3 $hash, 5, "FHEMduino_PT2262 IODev device didn't answer is command correctly: $msg";
  }

  ## Do we need to change ITrepetition back??	
  if(defined($attr{$a[0]}) && defined($attr{$a[0]}{"ITrepetition"})) {
    $message = "ir".$it_def_repetition;
    $msg = CallFn($io->{NAME}, "GetFn", $io, (" ", "raw", $message));
    if ($msg =~ m/raw => $message/) {
 	  Log GetLogLevel($a[0],4), "FHEMduino_PT2262: Set ITrepetition back: $message for $io->{NAME}";
    } else {
 	  Log GetLogLevel($a[0],4), "FHEMduino_PT2262: Error ITrepetition back: $message for $io->{NAME}";
    }
  }

  # Look for all devices with the same code, and set state, timestamp
  my $code = "$hash->{XMIT}";
  my $tn = TimeNow();

  $name = "$hash->{NAME}";

  foreach my $n (keys %{ $modules{FHEMduino_PT2262}{defptr}{$code} }) {
    my $lh = $modules{FHEMduino_PT2262}{defptr}{$code}{$n};
    $lh->{CHANGED}[0] = $v;
    $lh->{STATE} = $v;
    $lh->{READINGS}{state}{TIME} = $tn;
    $lh->{READINGS}{state}{VAL} = $v;
    $modules{FHEMduino_PT2262}{defptr}{$code}{$name}  = $hash;
  }
  return $ret;
}

sub getButton($$){ ###################################################################

  my ($hash,$msg) = @_;
  my $receivedHouseCode = "undef";
  my $receivedButtonCode = "undef";
  my $receivedActionCode ="undef";
  my $parsedHouseCode = "undef";
  my $parsedButtonCode = "undef";
  my $parsedAction = "undef";
  my $ontristate = $hash->{$elro_c2b{"on"}};
  my $offtristate = $hash->{$elro_c2b{"off"}};

  #my $bin = dec2bin($msg);
  #my $msgmod = bin2tristate($bin);
  my $msgmod = substr($msg,2);
  #Log3 $hash, 5, "FHEMduino_PT2262 Message received: $msg BIN $bin TRISTATE $msgmod";
  Log3 $hash, 5, "FHEMduino_PT2262 Message received: TRISTATE $msgmod";

  ## Groupcode
  $receivedHouseCode = substr($msgmod,0,5);
  $receivedButtonCode = substr($msgmod,5,5);
  $receivedActionCode = substr($msgmod,10,2);
  Log3 $hash, 5, "FHEMduino_PT2262 Message Housecode: $receivedHouseCode Buttoncode: $receivedButtonCode actioncode $receivedActionCode";

  my %housecode = ("00000" => "0",
    "0000F" => "1",
    "000F0" => "2",
    "000FF" => "3",
    "00F00" => "4",
    "00F0F" => "5",
    "00FF0" => "6",
    "00FFF" => "7",
    "0F000" => "8",
    "0F00F" => "9",
    "0F0F0" => "10",
    "0F0FF" => "11",
    "0FF00" => "12",
    "0FF0F" => "13",
    "0FFF0" => "14",
    "0FFFF" => "15",
    "F0000" => "16",
    "F000F" => "17",
    "F00F0" => "18",
    "F00FF" => "19",
    "F0F00" => "20",
    "F0F0F" => "21",
    "F0FF0" => "22",
    "F0FFF" => "23",
    "FF000" => "24",
    "FF00F" => "25",
    "FF0F0" => "26",
    "FF0FF" => "27",
    "FFF00" => "28",
    "FFF0F" => "29",
    "FFFF0" => "30",
    "FFFFF" => "31"
    );

  my %button = (
    "00000" => "0",
    "0000F" => "E",
    "000F0" => "D",
    "000FF" => "3",
    "00F00" => "C",
    "00F0F" => "5",
    "00FF0" => "6",
    "00FFF" => "7",
    "0F000" => "B",
    "0F00F" => "9",
    "0F0F0" => "10",
    "0F0FF" => "11",
    "0FF00" => "12",
    "0FF0F" => "13",
    "0FFF0" => "14",
    "0FFFF" => "15",
    "F0000" => "A",
    "F000F" => "17",
    "F00F0" => "18",
    "F00FF" => "19",
    "F0F00" => "20",
    "F0F0F" => "21",
    "F0FF0" => "22",
    "F0FFF" => "23",
    "FF000" => "24",
    "FF00F" => "25",
    "FF0F0" => "26",
    "FF0FF" => "27",
    "FFF00" => "28",
    "FFF0F" => "29",
    "FFFF0" => "30",
    "FFFFF" => "31"
    );

  my %action = (
    "FF" => "on",
    "0F"	=> "on",
    "F0"	=> "off"
    );

  if (exists $housecode{$receivedHouseCode}) {
    $parsedHouseCode = $housecode{$receivedHouseCode};
  }

  if (exists $button{$receivedButtonCode}) {
    $parsedButtonCode = $button{$receivedButtonCode};
  }

  if (exists $action{$receivedActionCode}) {
    $parsedAction = $action{$receivedActionCode};
  }
  
  if ($parsedHouseCode ne "undef") {
    if ($parsedButtonCode ne "undef") {
      if ($parsedAction ne "undef") {
        Log3 $hash, 5, "Get button return/result: ID: " . $receivedHouseCode . $receivedButtonCode . "DEVICE: " . $parsedHouseCode . "_" . $parsedButtonCode . " ACTION: " . $parsedAction;
        return $parsedHouseCode . "_" . $parsedButtonCode . " " . $receivedHouseCode . $receivedButtonCode . " " . $parsedAction;
      }
    }
  }
  return "";
}

sub FHEMduino_PT2262_Parse($$){ ########################################################

  my ($hash,$msg) = @_;

  my $deviceCode = "";
  my $displayName = "";
  my $action = "";
  my $result = "";
  my $basedur = "";
  
  ($msg, $basedur) = split m/_/, $msg, 2;

  Log3 $hash, 4, "Message: $msg Basedur: $basedur";
  $result = getButton($hash,$msg);

  if ($result ne "") {
    ($displayName,$deviceCode,$action) = split m/ /, $result, 3;

    Log3 $hash, 4, "Parse: Device: $displayName Code: $deviceCode Basedur: $basedur Action: $action";

    my $def = $modules{FHEMduino_PT2262}{defptr}{$hash->{NAME} . "." . $deviceCode};
    $def = $modules{FHEMduino_PT2262}{defptr}{$deviceCode} if(!$def);

    if(!$def) {
      Log3 $hash, 5, "UNDEFINED Remotebutton send to define: $displayName";
      return "UNDEFINED FHEMduino_PT2262_$displayName FHEMduino_PT2262 $deviceCode"."_".$basedur;
    }

    $hash = $def;

    my $name = $hash->{NAME};
    return "" if(IsIgnored($name));

    if(!$action) {
      Log3 $name, 5, "FHEMduino_PT2262 can't decode $msg";
      return "";
    }
    Log3 $name, 5, "FHEMduino_PT2262 actioncode: $action";

    readingsBeginUpdate($hash);
    readingsBulkUpdate($hash, "state", $action);
    readingsBulkUpdate($hash, "basedur", $basedur);
    readingsEndUpdate($hash, 1);
    return $name;
  }
  return "";
}

sub FHEMduino_PT2262_Attr(@){ ##########################################################
  my @a = @_;

  # Make possible to use the same code for different logical devices when they
  # are received through different physical devices.
  return if($a[0] ne "set" || $a[2] ne "IODev");
  my $hash = $defs{$a[1]};
  my $iohash = $defs{$a[3]};
  my $cde = $hash->{CODE};
  delete($modules{FHEMduino_PT2262}{defptr}{$cde});
  $modules{FHEMduino_PT2262}{defptr}{$iohash->{NAME} . "." . $cde} = $hash;
  
  return undef;
}

sub FHEMduino_PT2262_Undef($$){ ########################################################
  my ($hash, $name) = @_;
  delete($modules{FHEMduino_PT2262}{defptr}{$hash->{CODE}}) if($hash && $hash->{CODE});
  return undef;
}

sub dec2bin($){ ######################################################################
	my ($strraw) = @_;
	my $str = unpack("B*", pack("N", substr($strraw,2,length($strraw)-2)));
    $str =~ s/^0{8}(?=\d)//;   # cut first 8 zeros
    return $str;
  }

sub bin2tristate{ ####################################################################
	my $bindata = shift;
	my $returnValue = "";
	my $pos = 0;
	my $i = 0;

	while($i < length($bindata)/2){

		if (substr($bindata,$pos,1)=='0' && substr($bindata,$pos+1,1)=='0') {
			$returnValue .= '0';
			#print "value $returnValue.\n";
      } elsif (substr($bindata,$pos,1)=='1' && substr($bindata,$pos+1,1)=='1') {
       $returnValue .= '1';
			#print "value $returnValue.\n";
      } elsif (substr($bindata,$pos,1)=='0' && substr($bindata,$pos+1,1)=='1') {
       $returnValue .= 'F';
			#print "value $returnValue.\n";
      } else {
			#return "not applicable";
		}
		$pos = $pos+2;
		$i++;
	}
  return $returnValue;
}

1;
