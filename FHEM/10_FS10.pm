##############################################
# FS10 basierend auf dem FS20 Modul (FHEM 5.3), elektron-bbs
package main;

use strict;
use warnings;

my %codes = (
  "0" => "off",
  "2" => "off",
  "1" => "on",
  "3" => "on",
  "4" => "dimdown",
  "5" => "dimup",
);
# my %codes = (
  # "2" => "off",
  # "8" => "off",
  # "1" => "on",
  # "b" => "on",
  # "d" => "dimup",
  # "4" => "dimdown",
# );

my %readonly = (
  "thermo-on" => 1,
  "thermo-off" => 1,
);

use vars qw(%fs10_c2b);		# Peter would like to access it from outside

my $fs10_simple ="off on";
my %models = (
    fs10s4      => 'sender',
    fs10s8      => 'sender',
    dummySender => 'sender',

    fs10di      => 'dimmer',
    dummyDimmer => 'dimmer',

    fs10st      => 'simple',
    dummySimple => 'simple',
);

sub
FS10_Initialize($)
{
  my ($hash) = @_;

  foreach my $k (keys %codes) {
    $fs10_c2b{$codes{$k}} = $k;
  }

  $hash->{Match}     = "^FS10[a-fA-F0-9]{8}";
  $hash->{SetFn}     = "FS10_Set";
  $hash->{DefFn}     = "FS10_Define";
  $hash->{UndefFn}   = "FS10_Undef";
  $hash->{ParseFn}   = "FS10_Parse";
  $hash->{AttrList}  = "IODev follow-on-for-timer:1,0 follow-on-timer ".
                       "do_not_notify:1,0 ".
                       "ignore:1,0 dummy:1,0 showtime:1,0 ".
                       "loglevel:0,1,2,3,4,5,6 " .
                       "model:".join(",", sort keys %models);
}

###################################
sub
FS10_Set($@)
{
  my ($hash, @a) = @_;
  my $name = $a[0];											# z.B. FS10_0111
  # Log GetLogLevel($name,2), "FS10_Set: name $name";		# FS10_0111
  # Log GetLogLevel($name,2), "FS10: hash $hash";		# HASH(0xab56a2c)
  # Log GetLogLevel($name,2), "FS10: a    @a";			# FS10_0111 dimdown 10
  my $ret = undef;
  my $na = int(@a);											# Anzahl in Array 
  # Log GetLogLevel($name,2), "FS10: na   $na";		# 2 oder 3

  return "no set value specified" if($na < 2 || $na > 3);
  return "Readonly value $a[1]" if(defined($readonly{$a[1]}));

  if($na > 2 && $a[1] eq "dim") {
	my $dimvalue = $a[2];
	Log GetLogLevel($name,2), "FS10: dimvalue    $dimvalue";
    $a[1] = ($a[2] eq "0" ? "off" : sprintf("dim%02d%%",$a[2]) );
    splice @a, 2, 1;
    $na = int(@a);
  }

  my $c = $fs10_c2b{$a[1]};
  # Log GetLogLevel($name,2), "FS10: c    $c";
  my $setstate = $a[1];
  # Log GetLogLevel($name,2), "FS10: setstate    $setstate";		# on/off/dim/dimup/dimdown oder ?
  
  if(!defined($c)) {
    # Model specific set arguments
    if(defined($attr{$name}) && defined($attr{$name}{"model"})) {
      my $mt = $models{$attr{$name}{"model"}};
      return "Unknown argument $a[1], choose one of " if($mt && $mt eq "sender");
      return "Unknown argument $a[1], choose one of $fs10_simple" if($mt && $mt eq "simple");
    }
    return "Unknown argument $a[1], choose one of " . join(" ", sort keys %fs10_c2b) . " dim:slider,0,6.25,100";
  }
	return Do_On_Till($hash, @a) if($a[1] eq "on-till");
  return "Bad time spec" if($na == 3 && $a[2] !~ m/^\d*\.?\d+$/);

  my $v = join(" ", @a);	# FS10_0111 off
	Log3 $name, 3, "$name: set $v";

  #Log GetLogLevel($name,2), "FS10_Set: set $v";
  (undef, $v) = split(" ", $v, 2);	# Not interested in the name...

  my $val;

  if($na == 3) {                                # Timed command.
    $c = sprintf("%02X", (hex($c) | 0x20)); # Set the extension bit

    ########################
    # Calculating the time.
    LOOP: for(my $i = 0; $i <= 12; $i++) {
      for(my $j = 0; $j <= 15; $j++) {
        $val = (2**$i)*$j*0.25;
        if($val >= $a[2]) {
          if($val != $a[2]) {
            Log GetLogLevel($name,2), "$name: changing timeout to $val from $a[2]";
          }
          $c .= sprintf("%x%x", $i, $j);
          last LOOP;
        }
      }
    }
    return "Specified timeout too large, max is 15360" if(length($c) == 2);
  }
  

my $sum = 0;
my $temp = "";

# Nachricht 1, Taste druecken
my $newmsg = "P61#0000000000001";		# 12 Bit Praeambel, 1 Pruefbit
if ($setstate eq "on") {
	$newmsg .= "00011";						# 1. Kommando on, Wiederholbit 1 nicht gesetzt
	$sum = 1;
} else {
	$newmsg .= "10001";						# 1. Kommando off, Wiederholbit 1 nicht gesetzt
}

$temp = substr($name, 8, 1);				# 2. Ebene low
$newmsg .= dec2nibble($temp);		
$sum += $temp;

$temp = substr($name, 7, 1);				# 3. Ebene high
$newmsg .= dec2nibble($temp);		
$sum += $temp;

$newmsg .= "10001";							# 4. unused

$temp = substr($name, 6, 1);				# 5. Hauscode
$newmsg .= dec2nibble($temp);		
$sum += $temp;

if ($sum >= 11) {								# 6. Summe
	$temp = 18 - $sum;
} else {
	$temp = 10 - $sum;
}
$newmsg .= dec2nibble($temp);		

$newmsg .= "#R1";

 	IOWrite($hash, 'sendMsg', $newmsg);
 
	Log3 $name, 3, "$name: Send message #1 $newmsg";
	Log3 $name, 3, "$name: wait 200 mS";
	select(undef, undef, undef, 0.2);	# 200 mSek warten
  
# Nachricht 2, Taste loslassen
$sum = 0;
$newmsg = "P61#0000000000001";		# 12 Bit Praeambel, 1 Pruefbit
if ($setstate eq "on") {
	$newmsg .= "10111";						# 1. Kommando on, Wiederholbit 1 gesetzt
	$sum = 3;
} else {
	$newmsg .= "00101";						# 1. Kommando off, Wiederholbit 1 gesetzt
	$sum = 2;
}

$temp = substr($name, 8, 1);				# 2. Ebene low
$newmsg .= dec2nibble($temp);
$sum += $temp;

$temp = substr($name, 7, 1);				# 3. Ebene high
$newmsg .= dec2nibble($temp);		
$sum += $temp;

$newmsg .= "10001";							# 4. unused

$temp = substr($name, 6, 1);				# 5. Hauscode
$newmsg .= dec2nibble($temp);		
$sum += $temp;

if ($sum >= 11) {								# 6. Summe
	$temp = 18 - $sum;
} else {
	$temp = 10 - $sum;
}
$newmsg .= dec2nibble($temp);		

$newmsg .= "#R1";
	Log3 $name, 3, "$name: Send message #2 $newmsg";
 	IOWrite($hash, 'sendMsg', $newmsg);
  
  ###########################################
  # Set the state of a device to off if on-for-timer is called
  if($modules{FS10}{ldata}{$name}) {
    CommandDelete(undef, $name . "_timer");
    delete $modules{FS10}{ldata}{$name};
  }

  my $newState="";
  my $onTime = AttrVal($name, "follow-on-timer", undef);

  ####################################
  # following timers
  if($a[1] eq "on" && $na == 2 && $onTime) {
    $newState = "off";
    $val = $onTime;
  } elsif($a[1] =~ m/(on|off).*-for-timer/ && $na == 3 && AttrVal($name, "follow-on-for-timer", undef)) {
    $newState = ($1 eq "on" ? "off" : "on");
  }

  if($newState) {
    my $to = sprintf("%02d:%02d:%02d", $val/3600, ($val%3600)/60, $val%60);
    $modules{FS10}{ldata}{$name} = $to;
    Log 4, "Follow: +$to setstate $name $newState";
    CommandDefine(undef, $name."_timer at +$to ".
        "setstate $name $newState; trigger $name $newState");
  }

  ##########################
  # Look for all devices with the same code, and set state, timestamp
  my $code = "$hash->{XMIT} $hash->{BTN}";
  my $tn = TimeNow();
  my $defptr = $modules{FS10}{defptr};
  foreach my $n (keys %{ $defptr->{$code} }) {
    my $lh = $defptr->{$code}{$n};
    $lh->{CHANGED}[0] = $v;
    $lh->{STATE} = $v;
    $lh->{READINGS}{state}{TIME} = $tn;
    $lh->{READINGS}{state}{VAL} = $v;
    my $lhname = $lh->{NAME};
    if($name ne $lhname) {
      DoTrigger($lhname, undef)
    }
  }
  return $ret;
}

#############################
sub
FS10_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);

  my $u = "wrong syntax: define <name> FS10 housecode addr";

  return $u if(int(@a) < 4);
  return "Define $a[0]: wrong housecode format: specify a 2 digit hex value "
  		if( $a[2] !~ m/^[a-f0-9]{2}$/i ); # U, Hauscode
  		#if( $a[2] !~ m/^[a-f0-9]{3}$/i ); # 

  return "Define $a[0]: wrong btn format: specify a 2 digit hex value " .
         "or a 4 digit quad value"
  		if( $a[3] !~ m/^[a-f0-9]{2}$/i ); # Ebene Low, Ebene High

  my $housecode = $a[2];
  #$housecode = four2hex($housecode,4) if (length($housecode) == 8);

  my $btncode = $a[3];
  #$btncode = four2hex($btncode,2) if (length($btncode) == 4);

  $hash->{XMIT} = lc($housecode);
  $hash->{BTN}  = lc($btncode);

  my $code = lc("$housecode $btncode");
  my $ncode = 1;
  my $name = $a[0];
  $hash->{CODE}{$ncode++} = $code;
  $modules{FS10}{defptr}{$code}{$name}   = $hash;

  for(my $i = 4; $i < int(@a); $i += 2) {

    return "No address specified for $a[$i]" if($i == int(@a)-1);

    $a[$i] = lc($a[$i]);
    if($a[$i] eq "fg") {
      return "Bad fg address for $name, see the doc"
        if( ($a[$i+1] !~ m/^f[a-f0-9]$/) && ($a[$i+1] !~ m/^44[1-4][1-4]$/));
    } elsif($a[$i] eq "lm") {
      return "Bad lm address for $name, see the doc"
        if( ($a[$i+1] !~ m/^[a-f0-9]f$/) && ($a[$i+1] !~ m/^[1-4][1-4]44$/));
    } elsif($a[$i] eq "gm") {
      return "Bad gm address for $name, must be ff"
        if( ($a[$i+1] ne "ff") && ($a[$i+1] ne "4444"));
    } else {
      return $u;
    }

    my $grpcode = $a[$i+1];
    if (length($grpcode) == 4) {
       $grpcode = four2hex($grpcode,2);
    }

    $code = "$housecode $grpcode";
    $hash->{CODE}{$ncode++} = $code;
    $modules{FS10}{defptr}{$code}{$name}   = $hash;
  }
  AssignIoPort($hash);
}

#############################
sub
FS10_Undef($$)
{
  my ($hash, $name) = @_;

  foreach my $c (keys %{ $hash->{CODE} } ) {
    $c = $hash->{CODE}{$c};

    # As after a rename the $name my be different from the $defptr{$c}{$n}
    # we look for the hash.
    foreach my $dname (keys %{ $modules{FS10}{defptr}{$c} }) {
      delete($modules{FS10}{defptr}{$c}{$dname})
        if($modules{FS10}{defptr}{$c}{$dname} == $hash);
    }
  }
  return undef;
}

sub
FS10_Parse($$)
{
  my ($hash, $msg) = @_;
	 Log 3, "FS10_Parse: Received message $msg";

  # Msg format: 
  # FS10CAAHHH??
  # raw format (preprocessed in CUL module):
  # p 3  400  320  400  720 12  3 5 xx CAAHHH??
  # xx = RSSI, C = command code, AA = address/button code, HHH = home/device code

   # Msg format sduino: 
	# FS10111016
	# ---|||||||_ Summe
	#    ||||||_ Hauscode
	#    |||||_ unused (0)
	#    ||||_ Ebene high
	#    |||_ Ebene low
	#    ||_ Kommand
	#    |_ Name
  
  my $dev = substr($msg, 7, 2);	# U, Hauscode
  my $btn = reverse(substr($msg, 5, 2));	# Ebene low, Ebene high
  my $cde = substr($msg, 4, 1);	# Command

  my $dur = 0;
  my $cx = hex($cde);

  my $v = $codes{$cde};
  $v = "unknown_$cde" if(!defined($v));
  $v .= " $dur" if($dur);

  my $def = $modules{FS10}{defptr}{"$dev $btn"};
  if($def) {
    my @list;
    foreach my $n (keys %{ $def }) {
      my $lh = $def->{$n};
      $n = $lh->{NAME};        # It may be renamed
      return "" if(IsIgnored($n));   # Little strange.
      $lh->{CHANGED}[0] = $v;
      $lh->{STATE} = $v;
      $lh->{READINGS}{state}{TIME} = TimeNow();
      $lh->{READINGS}{state}{VAL} = $v;
      Log GetLogLevel($n,2), "FS10_Parse: $n $v";		# FS10_0111 on
      if($modules{FS10}{ldata}{$n}) {
        CommandDelete(undef, $n . "_timer");
        delete $modules{FS10}{ldata}{$n};
      }

      my $newState = "";
      if($v =~ m/(on|off).*-for-timer/ && $dur && AttrVal($n, "follow-on-for-timer", undef)) {
        $newState = ($1 eq "on" ? "off" : "on");
      } elsif($v eq "on" && (my $d = AttrVal($n, "follow-on-timer", undef))) {
        $dur = $d;
        $newState = "off";
      }

      if($newState) {
        my $to = sprintf("%02d:%02d:%02d", $dur/3600, ($dur%3600)/60, $dur%60);
        Log 4, "Follow: +$to setstate $n $newState";
        CommandDefine(undef, $n."_timer at +$to "."setstate $n $newState; trigger $n $newState");
        $modules{FS10}{ldata}{$n} = $to;
      }
      push(@list, $n);
    }
    return @list;
  } else {
    # Special FHZ initialization parameter. In Multi-FHZ-Mode we receive
    # it by the second FHZ
    return "" if($dev eq "0001" && $btn eq "00" && $cde eq "00");

    Log 3, "FS10: Unknown device $dev, " . "Button $btn Code $cde ($v), please define it";
    return "UNDEFINED FS10_$dev$btn FS10 $dev $btn";
  }
}

sub dec2nibble {
	my $num = shift;
	my $parity = 1;								# Paritaet ungerade
	my $result = "";
	for(my $i = 0; $i < 3; $i++) {
		my $reminder = $num % 2;				# Modulo division to get reminder
		$result = $reminder . $result;		# Concatenation of two numbers
		$parity += $reminder;
		$num /= 2;									# New Value of decimal number to do next set of above operations
	}
	$result = ($parity % 2) . $result . "1";	# paritybit . bin( num) . checkbit
	return $result;
}

1;
