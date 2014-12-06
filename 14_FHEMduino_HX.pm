##############################################
# $Id: 14_FHEMduino_HX.pm 3818 2014-06-24 $
package main;

use strict;
use warnings;

  # 10011 => 1. 2xDing-Dong
  # 10101 => 2. Telefonklingeln
  # 11001 => 3. Zirkusmusik
  # 11101 => 4. Banjo on my knee
  # 11110 => 5. Morgen kommt der Weihnachtsmann
  # 10110 => 6. It’s a small world
  # 10010 => 7. Hundebellen
  # 10001 => 8. Westminster

my %codes = (
  "XMIToff" 		=> "off",
  "XMITon" 		=> "on",
  "XMIThx1" 		=> "hx1",
  "XMIThx2" 		=> "hx2",
  "XMIThx3" 		=> "hx3",
  "XMIThx4" 		=> "hx4",
  "XMIThx5" 		=> "hx5",
  "XMIThx6" 		=> "hx6",
  "XMIThx7" 		=> "hx7",
  "XMIThx8" 		=> "hx8",
  );

my %elro_c2b;

my $hx_defrepetition = 14;   ## Default number of HX Repetitions

my $fa20rf_simple ="off on";
my %models = (
  Heidemann   => 'HX Series',
  );

#####################################
sub
FHEMduino_HX_Initialize($)
{
  my ($hash) = @_;
 
  foreach my $k (keys %codes) {
    $elro_c2b{$codes{$k}} = $k;
  }
  
  $hash->{Match}     = "H...\$";
  $hash->{SetFn}     = "FHEMduino_HX_Set";
  $hash->{StateFn}   = "FHEMduino_HX_SetState";
  $hash->{DefFn}     = "FHEMduino_HX_Define";
  $hash->{UndefFn}   = "FHEMduino_HX_Undef";
  $hash->{AttrFn}    = "FHEMduino_HX_Attr";
  $hash->{ParseFn}   = "FHEMduino_HX_Parse";
  $hash->{AttrList}  = "IODev HXrepetition do_not_notify:0,1 showtime:0,1 ignore:0,1 model:HX,RM150RF,KD101".
  $readingFnAttributes;
}

sub FHEMduino_HX_SetState($$$$){ ###################################################
  my ($hash, $tim, $vt, $val) = @_;
  $val = $1 if($val =~ m/^(.*) \d+$/);
  return "Undefined value $val" if(!defined($elro_c2b{$val}));
  return undef;
}

sub
FHEMduino_HX_Do_On_Till($@)
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
  FHEMduino_HX_Set($hash, @b);
  my $tname = $hash->{NAME} . "_till";
  CommandDelete(undef, $tname) if($defs{$tname});
  CommandDefine(undef, "$tname at $hms_till set $a[0] off");

}

sub
FHEMduino_HX_On_For_Timer($@)
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
  FHEMduino_HX_Set($hash, @b);
  my $tname = $hash->{NAME} . "_till";
  CommandDelete(undef, $tname) if($defs{$tname});
  CommandDefine(undef, "$tname at $hms_till set $a[0] off");

}

#####################################
sub
FHEMduino_HX_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);

  return "wrong syntax: define <name> FHEMduino_HX HX".int(@a)
		if(int(@a) < 2 || int(@a) > 5);

  my $name = $a[0];
  my $code = $a[2];
  my $bitcode = substr(unpack("B32", pack("N", $code)),-4);
  my $onHX = "";
  my $offHX = "";

  Log3 $hash, 4, "FHEMduino_HX_DEF: $name $code";

  if(int(@a) == 3) {
  }
  elsif(int(@a) == 5) {
    $onHX = $a[3];
    $offHX = $a[4];
  }
  else {
    return "wrong syntax: define <name> FHEMduino_HX <code>";
  }

  Log3 undef, 5, "Arraylenght:  int(@a)";

  $hash->{CODE} = $code;
  $hash->{DEF} = $code . " " . $onHX . " " . $offHX;
  $hash->{XMIT} = $bitcode;
  $hash->{BTN}  = $onHX;
  
  Log3 $hash, 4, "Define hascode: {$code} {$name}";
  $modules{FHEMduino_HX}{defptr}{$code} = $hash;
  $hash->{$elro_c2b{"on"}}  = $onHX;    # => 8. Westminster
  $hash->{$elro_c2b{"off"}} = $offHX;   # => 1. 2xDing-Dong
  $hash->{$elro_c2b{"hx1"}} = "10011";  # => 1. 2xDing-Dong
  $hash->{$elro_c2b{"hx2"}} = "10101";  # => 2. Telefonklingeln
  $hash->{$elro_c2b{"hx3"}} = "11001";  # => 3. Zirkusmusik
  $hash->{$elro_c2b{"hx4"}} = "11101";  # => 4. Banjo on my knee
  $hash->{$elro_c2b{"hx5"}} = "11110";  # => 5. Morgen kommt der Weihnachtsmann
  $hash->{$elro_c2b{"hx6"}} = "10110";  # => 6. It’s a small world
  $hash->{$elro_c2b{"hx7"}} = "10010";  # => 7. Hundebellen
  $hash->{$elro_c2b{"hx8"}} = "10001";  # => 8. Westminster
  $modules{FHEMduino_HX}{defptr}{$code}{$name} = $hash;

  if(!defined $hash->{IODev} ||!defined $hash->{IODev}{NAME}){
   AssignIoPort($hash);
  };  
  return undef;
}

#####################################
sub
FHEMduino_HX_Undef($$)
{
  my ($hash, $name) = @_;
  delete($modules{FHEMduino_HX}{defptr}{$hash->{CODE}}) if($hash && $hash->{CODE});
  return undef;
}

sub FHEMduino_HX_Set($@){ ##########################################################
  my ($hash, @a) = @_;
  my $ret = undef;
  my $na = int(@a);
  my $message;
  my $msg;
  my $hname = $hash->{NAME};
  my $name = $a[1];

  return "no set value specified" if($na < 2 || $na > 3);
  
  my $list = "";
  $list .= "on:noArg off:noArg on-till on-for-timer hx1:noArg hx2:noArg hx3:noArg hx4:noArg hx5:noArg hx6:noArg hx7:noArg hx8:noArg";

  return SetExtensions($hash, $list, $hname, @a) if( $a[1] eq "?" );
  return SetExtensions($hash, $list, $hname, @a) if( !grep( $_ =~ /^$a[1]($|:)/, split( ' ', $list ) ) );

  my $c = $elro_c2b{$a[1]};

  return FHEMduino_HX_Do_On_Till($hash, @a) if($a[1] eq "on-till");
  return "Bad time spec" if($na == 3 && $a[2] !~ m/^\d*\.?\d+$/);

  return FHEMduino_HX_On_For_Timer($hash, @a) if($a[1] eq "on-for-timer");
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

  ## Do we need to change HXrepetition ??	
  if(defined($attr{$a[0]}) && defined($attr{$a[0]}{"HXrepetition"})) {
  	$message = "hr".$attr{$a[0]}{"HXrepetition"};
    $msg = CallFn($io->{NAME}, "GetFn", $io, (" ", "raw", $message));
    if ($msg =~ m/raw => $message/) {
 	  Log GetLogLevel($a[0],4), "FHEMduino_HX: Set HXrepetition: $message for $io->{NAME}";
    } else {
 	  Log GetLogLevel($a[0],4), "FHEMduino_HX: Error set HXrepetition: $message for $io->{NAME}";
    }
  }

  my $v = join(" ", @a);
  $message = "hs".$hash->{XMIT}."111".$hash->{$c};

  ## Log that we are going to switch InterTechno
  Log GetLogLevel($a[0],2), "FHEMduino_HX set $v IO_Name:$io->{NAME} CMD:$a[1] CODE:$c";
  (undef, $v) = split(" ", $v, 2);	# Not interested in the name...

  ## Send Message to IODev and wait for correct answer
  Log3 $hash, 4, "Messsage an IO senden Message raw: $message";
  $msg = CallFn($io->{NAME}, "GetFn", $io, (" ", "raw", $message));
  if ($msg =~ m/raw => $message/) {
    Log3 $hash, 5, "FHEMduino_HX: Answer from $io->{NAME}: $msg";
  } else {
    Log3 $hash, 5, "FHEMduino_HX: IODev device didn't answer is command correctly: $msg";
  }

  ## Do we need to change HXrepetition back??	
  if(defined($attr{$a[0]}) && defined($attr{$a[0]}{"HXrepetition"})) {
  	$message = "hr".$hx_defrepetition;
    $msg = CallFn($io->{NAME}, "GetFn", $io, (" ", "raw", $message));
    if ($msg =~ m/raw => $message/) {
 	  Log GetLogLevel($a[0],4), "FHEMduino_HX: Set HXrepetition back: $message for $io->{NAME}";
    } else {
 	  Log GetLogLevel($a[0],4), "FHEMduino_HX: Error HXrepetition back: $message for $io->{NAME}";
    }
  }

  # Look for all devices with the same code, and set state, timestamp
  $name = "$hash->{NAME}";
  my $code = "$hash->{XMIT}";
  my $tn = TimeNow();

  foreach my $n (keys %{ $modules{FHEMduino_HX}{defptr}{$code} }) {
    my $lh = $modules{FHEMduino_HX}{defptr}{$code}{$n};
    $lh->{CHANGED}[0] = $v;
    $lh->{STATE} = $v;
    $lh->{READINGS}{state}{TIME} = $tn;
    $lh->{READINGS}{state}{VAL} = $v;
    $modules{FHEMduino_HX}{defptr}{$code}{$name}  = $hash;
  }
  return $ret;
}

#####################################
sub
FHEMduino_HX_Parse($$)
{
  my ($hash,$msg) = @_;
  my @a = split("", $msg);

  my $deviceCode = "";

  if (length($msg) < 4) {
    Log3 "FHEMduino", 4, "FHEMduino_Env: wrong message -> $msg";
    return "";
  }
  my $bitsequence = "";
  my $bin = "";
  my $sound = "";
  my $hextext = substr($msg,1);

  # Bit 8..12 => Sound of door bell
  # 10011 => 1. 2xDing-Dong
  # 10101 => 2. Telefonklingeln
  # 11001 => 3. Zirkusmusik
  # 11101 => 4. Banjo on my knee
  # 11110 => 5. Morgen kommt der Weihnachtsmann
  # 10110 => 6. It’s a small world
  # 10010 => 7. Hundebellen
  # 10001 => 8. Westminster
  # 1111 111 11111
  # 0    4   7
  $bitsequence = hex2bin($hextext); # getting message string and converting in bit sequence
  $bin = substr($bitsequence,0,4);
  $deviceCode = sprintf('%X', oct("0b$bin"));
  $sound = substr($bitsequence,7,5);

  Log3 $hash, 4, "FHEMduino_HX: $msg";
  Log3 $hash, 4, "FHEMduino_HX: $hextext";
  Log3 $hash, 4, "FHEMduino_HX: $bitsequence $deviceCode $sound";

  
  my $def = $modules{FHEMduino_HX}{defptr}{$hash->{NAME} . "." . $deviceCode};
  $def = $modules{FHEMduino_HX}{defptr}{$deviceCode} if(!$def);
  if(!$def) {
    Log3 $hash, 1, "FHEMduino_HX UNDEFINED sensor HX detected, code $deviceCode";
    return "UNDEFINED HX_$deviceCode FHEMduino_HX $deviceCode";
  }
  
  $hash = $def;
  my $name = $hash->{NAME};
  return "" if(IsIgnored($name));
  
  Log3 $name, 5, "FHEMduino_HX: actioncode: $deviceCode";  
  
  $hash->{lastReceive} = time();
  $hash->{lastValues}{FREQ} = $sound;

  Log3 $name, 4, "FHEMduino_HX: $name: $sound:";

  readingsBeginUpdate($hash);
  readingsBulkUpdate($hash, "state", $sound);
  readingsEndUpdate($hash, 1); # Notify is done by Dispatch

  return $name;
}

sub
FHEMduino_HX_Attr(@)
{
  my @a = @_;

  # Make possible to use the same code for different logical devices when they
  # are received through different physical devices.
  return if($a[0] ne "set" || $a[2] ne "IODev");
  my $hash = $defs{$a[1]};
  my $iohash = $defs{$a[3]};
  my $cde = $hash->{CODE};
  delete($modules{FHEMduino_HX}{defptr}{$cde});
  $modules{FHEMduino_HX}{defptr}{$iohash->{NAME} . "." . $cde} = $hash;
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

sub
bin2dec($)
{
  my $h = shift;
  my $int = unpack("N", pack("B32",substr("0" x 32 . $h, -32))); 
  return sprintf("%d", $int); 
}

1;

=pod
=begin html

<a name="FS20"></a>
<h3>FS20</h3>
<ul>
  The FS20 protocol is used by a wide range of devices, which are either of
  the sender/sensor category or the receiver/actuator category.  The radio
  (868.35 MHz) messages are either received through an <a href="#FHZ">FHZ</a>
  or an <a href="#CUL">CUL</a> device, so this must be defined first.

  <br><br>

  <a name="FS20define"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; FS20 &lt;housecode&gt; &lt;button&gt;
    [fg &lt;fgaddr&gt;] [lm &lt;lmaddr&gt;] [gm FF] </code>
    <br><br>

   The values of housecode, button, fg, lm, and gm can be either defined as
   hexadecimal value or as ELV-like "quad-decimal" value with digits 1-4. We
   will reference this ELV-like notation as ELV4 later in this document. You
   may even mix both hexadecimal and ELV4 notations, because FHEM can detect
   the used notation automatically by counting the digits.<br>

   <ul>
   <li><code>&lt;housecode&gt;</code> is a 4 digit hex or 8 digit ELV4 number,
     corresponding to the housecode address.</li>
   <li><code>&lt;button&gt;</code> is a 2 digit hex or 4 digit ELV4 number,
     corresponding to a button of the transmitter.</li>
   <li>The optional <code>&lt;fgaddr&gt;</code> specifies the function group.
     It is a 2 digit hex or 4 digit ELV address. The first digit of the hex
     address must be F or the first 2 digits of the ELV4 address must be
     44.</li>
   <li>The optional <code>&lt;lmaddr&gt;</code> specifies the local
     master. It is a 2 digit hex or 4 digit ELV address.  The last digit of the
     hex address must be F or the last 2 digits of the ELV4 address must be
     44.</li>
   <li>The optional gm specifies the global master, the address must be FF if
     defined as hex value or 4444 if defined as ELV4 value.</li>
   </ul>
   <br>

    Examples:
    <ul>
      <code>define lamp FS20 7777 00 fg F1 gm F</code><br>
      <code>define roll1 FS20 7777 01</code><br>
      <code>define otherlamp FS20 24242424 1111 fg 4412 gm 4444</code><br>
      <code>define otherroll1 FS20 24242424 1114</code>
    </ul>
  </ul>
  <br>

  <a name="FS20set"></a>
  <b>Set </b>
  <ul>
    <code>set &lt;name&gt; &lt;value&gt; [&lt;time&gt]</code>
    <br><br>
    where <code>value</code> is one of:<br>
    <ul><code>
      dim06% dim12% dim18% dim25% dim31% dim37% dim43% dim50%<br>
      dim56% dim62% dim68% dim75% dim81% dim87% dim93% dim100%<br>
      dimdown<br>
      dimup<br>
      dimupdown<br>
      off<br>
      off-for-timer<br>
      on                # dimmer: set to value before switching it off<br>
      on-for-timer      # see the note<br>
      on-old-for-timer  # set to previous (before switching it on)<br>
      ramp-on-time      # time to reach the desired dim value on dimmers<br>
      ramp-off-time     # time to reach the off state on dimmers<br>
      reset<br>
      sendstate<br>
      timer<br>
      toggle            # between off and previous dim val<br>
      on-till           # Special, see the note<br>
    </code></ul>
    The <a href="#setExtensions"> set extensions</a> are also supported.<br>
    <br>
    Examples:
    <ul>
      <code>set lamp on</code><br>
      <code>set lamp1,lamp2,lamp3 on</code><br>
      <code>set lamp1-lamp3 on</code><br>
      <code>set lamp on-for-timer 12</code><br>
    </ul>
    <br>

    Notes:
    <ul>
      <li>Use reset with care: the device forgets even the housecode.
      </li>
      <li>As the FS20 protocol needs about 0.22 seconds to transmit a
      sequence, a pause of 0.22 seconds is inserted after each command.
      </li>
      <li>The FS20ST switches on for dim*%, dimup. It does not respond to
          sendstate.</li>
      <li>If the timer is set (i.e. it is not 0) then on, dim*,
          and *-for-timer will take it into account (at least by the FS20ST).
      </li>
      <li>The <code>time</code> argument ranges from 0.25sec to 4 hours and 16
          minutes.  As the time is encoded in one byte there are only 112
          distinct values, the resolution gets coarse with larger values. The
          program will report the used timeout if the specified one cannot be
          set exactly.  The resolution is 0.25 sec from 0 to 4 sec, 0.5 sec
          from 4 to 8 sec, 1 sec from 8 to 16 sec and so on. If you need better
          precision for large values, use <a href="#at">at</a> which has a 1
          sec resolution.</li>
      <li>on-till requires an absolute time in the "at" format (HH:MM:SS, HH:MM
      or { &lt;perl code&gt; }, where the perl-code returns a time
          specification).
      If the current time is greater than the specified time, then the
      command is ignored, else an "on" command is generated, and for the
      given "till-time" an off command is scheduleld via the at command.
      </li>
    </ul>
  </ul>
  <br>

  <b>Get</b> <ul>N/A</ul><br>

  <a name="FS20attr"></a>
  <b>Attributes</b>
  <ul>
    <a name="IODev"></a>
    <li>IODev<br>
        Set the IO or physical device which should be used for sending signals
        for this "logical" device. An example for the physical device is an FHZ
        or a CUL. Note: Upon startup FHEM assigns each logical device
        (FS20/HMS/KS300/etc) the last physical device which can receive data
        for this type of device. The attribute IODev needs to be used only if
        you attached more than one physical device capable of receiving signals
        for this logical device.</li><br>

    <a name="eventMap"></a>
    <li>eventMap<br>
        Replace event names and set arguments. The value of this attribute
        consists of a list of space separated values, each value is a colon
        separated pair. The first part specifies the "old" value, the second
        the new/desired value. If the first character is slash(/) or komma(,)
        then split not by space but by this character, enabling to embed spaces.
        Examples:<ul><code>
        attr store eventMap on:open off:closed<br>
        attr store eventMap /on-for-timer 10:open/off:closed/<br>
        set store open
        </code></ul>
        </li><br>

    <a name="attrdummy"></a>
    <li>dummy<br>
    Set the device attribute dummy to define devices which should not
    output any radio signals. Associated notifys will be executed if
    the signal is received. Used e.g. to react to a code from a sender, but
    it will not emit radio signal if triggered in the web frontend.
    </li><br>

    <a name="follow-on-for-timer"></a>
    <li>follow-on-for-timer<br>
    schedule a "setstate off;trigger off" for the time specified as argument to
    the on-for-timer command. Or the same with on, if the command is
    off-for-timer.
    </li><br>

    <a name="follow-on-timer"></a>
    <li>follow-on-timer<br>
    Like with follow-on-for-timer schedule a "setstate off;trigger off", but
    this time for the time specified as argument in seconds to this attribute.
    This is used to follow the pre-programmed timer, which was set previously
    with the timer command or manually by pressing the button on the device,
    see your manual for details.
    </li><br>


    <a name="model"></a>
    <li>model<br>
        The model attribute denotes the model type of the device.
        The attributes will (currently) not be used by the fhem.pl directly.
        It can be used by e.g. external programs or web interfaces to
        distinguish classes of devices and send the appropriate commands
        (e.g. "on" or "off" to a fs20st, "dim..%" to fs20du etc.).
        The spelling of the model names are as quoted on the printed
        documentation which comes which each device. This name is used
        without blanks in all lower-case letters. Valid characters should be
        <code>a-z 0-9</code> and <code>-</code> (dash),
        other characters should be ommited. Here is a list of "official"
        devices:<br><br>
          <b>Sender/Sensor</b>: fs20fms fs20hgs fs20irl fs20kse fs20ls
          fs20pira fs20piri fs20piru fs20s16 fs20s20 fs20s4  fs20s4a fs20s4m
          fs20s4u fs20s4ub fs20s8 fs20s8m fs20sd  fs20sn  fs20sr fs20ss
          fs20str fs20tc1 fs20tc6 fs20tfk fs20tk  fs20uts fs20ze fs20bf fs20si3<br><br>

          <b>Dimmer</b>: fs20di  fs20di10 fs20du<br><br>

          <b>Receiver/Actor</b>: fs20as1 fs20as4 fs20ms2 fs20rgbsa fs20rst
          fs20rsu fs20sa fs20sig fs20sm4 fs20sm8 fs20st fs20su fs20sv fs20ue1
          fs20usr fs20ws1
    </li><br>


    <a name="ignore"></a>
    <li>ignore<br>
        Ignore this device, e.g. if it belongs to your neighbour. The device
        won't trigger any FileLogs/notifys, issued commands will silently
        ignored (no RF signal will be sent out, just like for the <a
        href="#attrdummy">dummy</a> attribute). The device won't appear in the
        list command (only if it is explicitely asked for it), nor will it
        appear in commands which use some wildcard/attribute as name specifiers
        (see <a href="#devspec">devspec</a>). You still get them with the
        "ignored=1" special devspec.
        </li><br>

    <li><a href="#do_not_notify">do_not_notify</a></li>
    <li><a href="#showtime">showtime</a></li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>

  </ul>
  <br>

  <a name="FS20events"></a>
  <b>Generated events:</b>
  <ul>
     From an FS20 device you can receive one of the following events.
     <li>on</li>
     <li>off</li>
     <li>toggle</li>
     <li>dimdown</li>
     <li>dimup</li>
     <li>dimupdown</li>
     <li>on-for-timer</li>
     Which event is sent is device dependent and can sometimes configured on
     the device.
  </ul>
</ul>

=end html

=begin html_DE

<a name="FHEMduino HX"></a>
<h3>FS20</h3>
<ul>
  Das FS20 Protokoll wird von einem gro&szlig;en Spektrum an Ger&auml;ten

  <br><br>

  <a name="FS20define"></a>
  <b>Define</b>
  <ul>

    // Bit 1..4 => Address of door bell<br>
    // DIP-Switch<br>
    // 4321 0=OFF / 1 = ON<br>
    // 0000 => 0000 = 0<br>
    // 1000 => 0001 = 1<br>
    // 0100 => 0010 = 2<br>
    // 1100 => 0011 = 3<br>
    // 0010 => 0100 = 4<br>
    // 1010 => 0101 = 5<br>
    // ...
    // 1111 => 1111 = 15<br>
    <code>define &lt;name&gt; FS20 &lt;housecode&gt; &lt;button&gt;
    [fg &lt;fgaddr&gt;] [lm &lt;lmaddr&gt;] [gm FF] </code>
    <br><br>

   Die Werte housecode, button, fg, lm, und gm k&ouml;nnen entweder hexadezimal
   oder in der ELV-typischen quatern&auml;ren Notation (Zahlen von 1-4)
   eingegeben werden.
   Hier und auch in sp&auml;teren Beispielen wird als Referenz die ELV4
   Notation verwendet. Die Notationen k&ouml;nnen auch gemischt werden da FHEM
   die verwendete Notation durch z&auml;hlen der Zeichen erkennt.<br>

   <ul>
   <li><code>&lt;housecode&gt;</code> ist eine 4 stellige Hex oder 8 stellige
     ELV4 Zahl, entsprechend der Hauscode Adresse.</li>

   <li><code>&lt;button&gt;</code> ist eine 2 stellige Hex oder 4 stellige ELV4
     Zahl, entsprechend dem Button des Transmitters.</li>

   <li>Optional definiert <code>&lt;fgaddr&gt;</code> die Funktionsgruppe mit
     einer 2 stelligen Hex oder 4 stelligen  ELV4 Adresse. Bei Hex muss die
     erste Stelle F, bei ELV4 die ersten zwei Stellen 44 sein.</li>

   <li>Optional definiert <code>&lt;lmaddr&gt;</code> definiert einen local
     master mit einer 2 stelligen Hex oder 4 stelligen  ELV4 Adresse. Bei Hex
     muss die letzte Stelle F, bei ELV4 die letzten zwei Stellen 44 sein.</li>

   <li>Optional definiert  gm den global master. Die Adresse muss FF bei HEX
     und 4444 bei ELV4 Notation sein.</li>

   </ul>
   <br>

    Beispiele:
    <ul>
      <code>define lamp FS20 7777 00 fg F1 gm F</code><br>
      <code>define roll1 FS20 7777 01</code><br>
      <code>define otherlamp FS20 24242424 1111 fg 4412 gm 4444</code><br>
      <code>define otherroll1 FS20 24242424 1114</code>
    </ul>
  </ul>
  <br>

  <a name="FS20set"></a>
  <b>Set </b>
  <ul>
    <code>set &lt;name&gt; &lt;value&gt; [&lt;time&gt]</code>
    <br><br>
    Wobei <code>value</code> einer der folgenden Werte sein kann:<br>
    <ul><code>
      on  => Westminster<br>
      off => 2xDing-Dong<br>
      hx1 => 1. 2xDing-Dong<br>
      hx2 => 2. Telefonklingeln<br>
      hx3 => 3. Zirkusmusik<br>
      hx4 => 4. Banjo on my knee<br>
      hx5 => 5. Morgen kommt der Weihnachtsmann<br>
      hx6 => 6. It’s a small world<br>
      hx7 => 7. Hundebellen<br>
      hx8 => 8. Westminster<br>

      off-for-timer<br>
      on-for-timer      # Siehe Hinweise<br>
      on-till           # Siehe Hinweise<br>

    </code></ul><br>
    Die<a href="#setExtensions"> set extensions</a> sind ebenfalls
    unterst&uuml;tzt.<br>
    <br>

    Hinweise:
    <ul>

      <li>on-till setzt eine absolute Zeit im "at" Format voraus (HH:MM:SS,
        HH:MM oder { &lt;perl code&gt; }, wobei der perl-code eine Zeit
        zur&uuml;ck geben muss).  Wenn die aktuelle Zeit gr&ouml;&szlig;er ist
        als die angegebene, dann wird der Befehl ignoriert und ein at-"on"
        Befehl erzeugt, sowie f&uuml;r die angegebe "till-time" ein at-"off"
        Befehl.
      </li>
    </ul>
  </ul>
  <br>

  <b>Get</b> <ul>N/A</ul><br>

  <a name="FS20attr"></a>
  <b>Attribute</b>
  <ul>
    <a name="IODev"></a>
    <li>IODev<br>
      Setzt das IO oder das physische Device welches zum Senden der Signale an
      dieses logische Device verwendet werden soll (Beispielsweise FHZ oder
      CUL).  Hinweis: Beim Start weist FHEM jedem logischen Device das letzte
      physische Device zu, das Daten von diesem Typ empfangen kann.  Das
      Attribut IODev muss nur gesetzt werden wenn mehr als ein physisches
      Device f&auml;hig ist Signale von diesem logischen Device zu empfangen.
      </li><br>

    <a name="eventMap"></a>
    <li>eventMap<br>
      Ersetze Event Namen und setze Argumente. Der Wert dieses Attributes
      besteht aus einer Liste von durch Leerzeichen getrennte Werten. Jeder
      Wert ist ein durch Doppelpunkt getrenntes Paar. Der erste Teil stellt den
      "alten" Wert, der zweite Teil den "neuen" Wert dar. Wenn der erste Wert
      ein Slash (/) oder ein Komma (,) ist, dann wird nicht durch Leerzeichen
      sondern durch das vorgestellte Zeichen getrennt.
      Beispiele:
      <ul><code>
        attr store eventMap on:open off:closed<br>
        attr store eventMap /on-for-timer 10:open/off:closed/<br>
        set store open
      </code></ul>
      </li><br>

    <a name="attrdummy"></a>
    <li>dummy<br>
      Setzt das Attribut dummy um Devices zu definieren, die keine Funksignale
      absetzen.  Zugeh&ouml;rige notifys werden ausgef&uuml;hrt wenn das Signal
      empfangen wird.  Wird beispielsweise genutzt um auf Code eines Sender zu
      reagieren, dennoch wird es auch dann kein Signal senden wenn es im Web
      Frontend getriggert wird.
      </li><br>

    <a name="follow-on-for-timer"></a>
    <li>follow-on-for-timer<br>
      Plant ein "setstate off;trigger off" f&uuml;r die angegebene Zeit als
      Argument zum on-for-timer Command. Oder das gleiche mit "on" wenn der
      Befehl "follow-off-for-timer" war.
      </li><br>

    <a name="follow-on-timer"></a>
    <li>follow-on-timer<br>
      Wie follow-on-for-timer plant es ein "setstate off;trigger off", aber
      diesmal als Argument in Sekunden zum Attribut.  Wird verwendet um dem
      vorprogrammierten Timer zu folgen welcher vorher durch den timer-Befehl,
      oder manuell durch Dr&uuml;cken des Buttons gesetzt wurde. Im Handbuch
      finden sich noch mehr Informationen.
      </li><br>


    <a name="model"></a>
    <li>model<br>
      Das "model" Attribut bezeichnet den Modelltyp des Ger&auml;tes.  Dieses
      Attribut wird (derzeit) nicht direkt durch fhem.pl genutzt.  Es kann
      beispielsweise von externen Programmen oder Webinterfaces genutzt werden
      um Ger&auml;teklassen zu unterscheiden und dazu passende Befehle zu senden
      (z.B. "on" oder "off" an ein fs20st, "dim..%" an ein fs20du etc.).  Die
      Schreibweise des Modellnamens ist wie die in Anf&uuml;hrungszeichen in
      der Anleitung gedruckte Bezeichnung die jedem Ger&auml;t beiliegt.
      Dieser Name wird ohne Leerzeichen ausschlie&szlig;lich in Kleinbuchstaben
      verwendet.  G&uuml;ltige Zeichen sind <code>a-z 0-9</code> und
      <code>-</code>, andere Zeichen sind zu vermeiden. Hier ist eine Liste der
      "offiziellen" Devices:<br><br>

      <b>Sender/Sensor</b>: fs20fms fs20hgs fs20irl fs20kse fs20ls
      fs20pira fs20piri fs20piru fs20s16 fs20s20 fs20s4  fs20s4a fs20s4m
      fs20s4u fs20s4ub fs20s8 fs20s8m fs20sd  fs20sn  fs20sr fs20ss
      fs20str fs20tc1 fs20tc6 fs20tfk fs20tk  fs20uts fs20ze fs20bf fs20si3<br><br>

      <b>Dimmer</b>: fs20di  fs20di10 fs20du<br><br>

      <b>Empf&auml;nger/Aktor</b>: fs20as1 fs20as4 fs20ms2 fs20rgbsa fs20rst
      fs20rsu fs20sa fs20sig fs20sm4 fs20sm8 fs20st fs20su fs20sv fs20ue1
      fs20usr fs20ws1
      </li><br>


    <a name="ignore"></a>
    <li>ignore<br>
      Ignoriere dieses Ger&auml;t, beispielsweise wenn es dem Nachbar
      geh&ouml;rt.  Das Ger&auml;t wird keine FileLogs/notifys triggern,
      empfangene Befehle werden stillschweigend ignoriert (es wird kein
      Funksignal gesendet, wie auch beim <a href="#attrdummy">dummy</a>
      Attribut). Das Ger&auml;t wird weder in der Device-List angezeigt (es sei
      denn, es wird explizit abgefragt), noch wird es in Befehlen mit
      "Wildcard"-Namenspezifikation (siehe <a href="#devspec">devspec</a>)
      erscheinen.  Es kann mit dem "ignored=1" devspec dennoch erreicht werden.
      </li><br>

    <li><a href="#do_not_notify">do_not_notify</a></li>
    <li><a href="#showtime">showtime</a></li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>

  </ul>
  <br>

  <a name="FS20events"></a>
  <b>Erzeugte Events:</b>
  <ul>
     Von einem FS20 Ger&auml;t k&ouml;nnen folgende Events empfangen werden:
     <li>on</li>
     <li>off</li>
     <li>toggle</li>
     <li>dimdown</li>
     <li>dimup</li>
     <li>dimupdown</li>
     <li>on-for-timer</li>
     Welches Event gesendet wird ist Ger&auml;teabh&auml;ngig und kann manchmal
     auf dem Device konfiguriert werden.
  </ul>
</ul>

=end html_DE

=cut
