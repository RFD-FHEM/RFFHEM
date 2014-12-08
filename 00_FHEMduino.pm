##############################################
# $Id: 00_FHEMduino.pm 
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
use Time::HiRes qw(gettimeofday);

sub FHEMduino_Attr(@);
sub FHEMduino_Clear($);
sub FHEMduino_HandleCurRequest($$);
sub FHEMduino_HandleWriteQueue($);
sub FHEMduino_Parse($$$$);
sub FHEMduino_Read($);
sub FHEMduino_ReadAnswer($$$$);
sub FHEMduino_Ready($);
sub FHEMduino_Write($$$);

sub FHEMduino_SimpleWrite(@);

my %gets = (    # Name, Data to send to the FHEMduino, Regexp for the answer
  "version"  => ["V", '^V .*'],
  "raw"      => ["", '.*'],
  "uptime"   => ["t", '^[0-9A-F]{8}[\r\n]*$' ],
  "cmds"     => ["?", '.*Use one of[ 0-9A-Za-z]+[\r\n]*$' ],
  "ITParms"  => ["ip",'.*' ],
  "FAParms"  => ["fp", '.*' ],
  "TCParms"  => ["dp", '.*' ],
  "HXParms"  => ["hp", '.*' ]
);

#my %sets = (
#  "raw"       => "",
#  "led"       => "",
#  "patable"   => "",
#  "time"      => "",
#  "flash"     => ""
#);

my %sets = (
  "raw"       => "",
  "flash"     => "",
  "reset"     => ""
);

my $clientsFHEMduino = ":IT:CUL_TX:OREGON:FHEMduino_Env:FHEMduino_EZ6:FHEMduino_Oregon:FHEMduino_PT2262:FHEMduino_FA20RF:FHEMduino_TCM:FHEMduino_HX:FHEMduino_DCF77:FHEMduino_Gas:FHEMduino_AS:FHEMduino_ARC";

my %matchListFHEMduino = (
    "1:IT"                 => "^i......\$",
    "2:CUL_TX"             => "^TX..........",        # Need TX to avoid FHTTK
    "3:FHEMduino_Env"      => "W.*\$",
    "4:FHEMduino_EZ6"      => "E...........\$",       # Special Sketch needed. See FHEMWIKI
    "5:FHEMduino_Oregon"   => "OSV2:.*\$",
    "6:FHEMduino_PT2262"   => "IR.*\$",
    "7:FHEMduino_FA20RF"   => "F............\$",
    "8:FHEMduino_TCM"      => "M.....\$",
    "9:FHEMduino_HX"       => "H...\$",
    "10:FHEMduino_DCF77"   => "D...............\$",
    "11:OREGON"            => "^(3[8-9A-F]|[4-6][0-9A-F]|7[0-8]).*",
    "12:FHEMduino_Gas"     => "G...........\$",      # Special Sketch needed. See GitHub GAS_I2C or FHEMWIKI
    "13:FHEMduino_AS"      => "AS.*\$", #Arduino based Sensors
    "14:FHEMduino_ARC"     => "AR.*\$", #ARC protocol switches like IT selflearn
);
##Sven: Vorschlag sollten wir hier nicht mal das Protokoll, also das Nachrichtenformat etwas abändern. Bem OSV2 z.B. fand ich ganz gut, dass die ersten beiden Werte die Länge der Nachricht wiederspiegeln (HEX)
##      Darauf kann man ja ganz gut eine Regex bauen um das Protokoll zu ermitteln. Dass wir hier machchmal einen Buchstaben, manchmal zwei und hin und wieder auch eine konkrete Länge haben macht es etwas unübersichlicht.

sub
FHEMduino_Initialize($)
{
  my ($hash) = @_;

  require "$attr{global}{modpath}/FHEM/DevIo.pm";

# Provider
  $hash->{ReadFn}  = "FHEMduino_Read";
  $hash->{WriteFn} = "FHEMduino_Write";
  $hash->{ReadyFn} = "FHEMduino_Ready";

# Normal devices
  $hash->{DefFn}   = "FHEMduino_Define";
  $hash->{FingerprintFn} = "FHEMduino_FingerprintFn";
  $hash->{UndefFn} = "FHEMduino_Undef";
  $hash->{GetFn}   = "FHEMduino_Get";
  $hash->{SetFn}   = "FHEMduino_Set";
  $hash->{AttrFn}  = "FHEMduino_Attr";
  $hash->{AttrList}= "Clients MatchList "
                      ." hexFile"
                      ." initCommands"
                      ." flashCommand"
                      ." $readingFnAttributes";

  $hash->{ShutdownFn} = "FHEMduino_Shutdown";

}

sub
FHEMduino_FingerprintFn($$)
{
  my ($name, $msg) = @_;
  Log3 $name,5, "FingerprintFn Message: Name: $name  und Message: $msg";
  # Store only the "relevant" part, as the FHEMduino won't compute the checksum
  $msg = substr($msg, 8) if($msg =~ m/^81/ && length($msg) > 9);
 
  return ($name, $msg);
}

#####################################
sub
FHEMduino_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);

  if(@a != 3) {
    my $msg = "wrong syntax: define <name> FHEMduino {none | devicename[\@baudrate] | devicename\@directio | hostname:port}";
    Log3 undef, 2, $msg;
    return $msg;
  }

  DevIo_CloseDev($hash);

  my $name = $a[0];

  my $dev = $a[2];
  $dev .= "\@9600" if( $dev !~ m/\@/ );
  
#  $hash->{CMDS} = "";
  $hash->{Clients} = $clientsFHEMduino;
  $hash->{MatchList} = \%matchListFHEMduino;

  if( !defined( $attr{$name}{flashCommand} ) ) {
#    $attr{$name}{flashCommand} = "avrdude -p atmega328P -c arduino -P [PORT] -D -U flash:w:[HEXFILE] 2>[LOGFILE]"
    $attr{$name}{flashCommand} = "avrdude -c arduino -b 57600 -P [PORT] -p atmega328p -vv -U flash:w:[HEXFILE] 2>[LOGFILE]"
  }

  if($dev eq "none") {
    Log3 $name, 1, "$name device is none, commands will be echoed only";
    $attr{$name}{dummy} = 1;
    return undef;
  }
  
  $hash->{DeviceName} = $dev;
  my $ret = DevIo_OpenDev($hash, 0, "FHEMduino_DoInit");
  return $ret;
}

#####################################
sub
FHEMduino_Undef($$)
{
  my ($hash, $arg) = @_;
  my $name = $hash->{NAME};

  foreach my $d (sort keys %defs) {
    if(defined($defs{$d}) &&
       defined($defs{$d}{IODev}) &&
       $defs{$d}{IODev} == $hash)
      {
        my $lev = ($reread_active ? 4 : 2);
        Log3 $name, $lev, "deleting port for $d";
        delete $defs{$d}{IODev};
      }
  }

  FHEMduino_Shutdown($hash);
  DevIo_CloseDev($hash); 
  return undef;
}

#####################################
sub
FHEMduino_Shutdown($)
{
  my ($hash) = @_;
  FHEMduino_SimpleWrite($hash, "X00");  # Switch reception off, it may hang up the FHEMduino
  return undef;
}

#####################################
sub
FHEMduino_Set($@)
{
  my ($hash, @a) = @_;

  return "\"set FHEMduino\" needs at least one parameter" if(@a < 2);
  return "Unknown argument $a[1], choose one of " . join(" ", sort keys %sets)
  	if(!defined($sets{$a[1]}));

  my $name = shift @a;
  my $cmd = shift @a;
  my $arg = join(" ", @a);

  my $list = "raw led:on,off led-on-for-timer reset flash";
  return $list if( $cmd eq '?' || $cmd eq '');

  if($cmd eq "raw") {
    Log3 $name, 4, "set $name $cmd $arg";
    FHEMduino_SimpleWrite($hash, $arg);
  } elsif( $cmd eq "flash" ) {
    my @args = split(' ', $arg);
    my $log = "";
    my $hexFile = "";
    my @deviceName = split('@', $hash->{DeviceName});
    my $port = $deviceName[0];
    my $defaultHexFile = "./hexfiles/$hash->{TYPE}.hex";
    my $logFile = AttrVal("global", "logdir", "./log/") . "$hash->{TYPE}-Flash.log";

    if(!$arg || $args[0] !~ m/^(\w|\/|.)+$/) {
      $hexFile = AttrVal($name, "hexFile", "");
      if ($hexFile eq "") {
        $hexFile = $defaultHexFile;
      }
    }
    else {
      $hexFile = $args[0];
    }

    return "Usage: set $name flash [filename]\n\nor use the hexFile attribute" if($hexFile !~ m/^(\w|\/|.)+$/);

    $log .= "flashing Arduino $name\n";
    $log .= "hex file: $hexFile\n";
    $log .= "port: $port\n";
    $log .= "log file: $logFile\n";

    my $flashCommand = AttrVal($name, "flashCommand", "");

    if($flashCommand ne "") {
      if (-e $logFile) {
        unlink $logFile;
      }

      DevIo_CloseDev($hash);
      $hash->{STATE} = "disconnected";
      $log .= "$name closed\n";

      my $avrdude = $flashCommand;
      $avrdude =~ s/\Q[PORT]\E/$port/g;
      $avrdude =~ s/\Q[HEXFILE]\E/$hexFile/g;
      $avrdude =~ s/\Q[LOGFILE]\E/$logFile/g;

      $log .= "command: $avrdude\n\n";
      `$avrdude`;

      local $/=undef;
      if (-e $logFile) {
        open FILE, $logFile;
        my $logText = <FILE>;
        close FILE;
        $log .= "--- AVRDUDE ---------------------------------------------------------------------------------\n";
        $log .= $logText;
        $log .= "--- AVRDUDE ---------------------------------------------------------------------------------\n\n";
      }
      else {
        $log .= "WARNING: avrdude created no log file\n\n";
      }

    }
    else {
      $log .= "\n\nNo flashCommand found. Please define this attribute.\n\n";
    }

    DevIo_OpenDev($hash, 0, "FHEMduino_DoInit");
    $log .= "$name opened\n";

    return $log;

  } elsif ($cmd =~ m/reset/i) {
    return FHEMduino_ResetDevice($hash);
  } elsif( $cmd eq "led" ) {
    return "Expecting a 0-padded hex number" if((length($arg)&1) == 1);
    Log3 $name, 3, "set $name $cmd $arg";
    $arg = "l$arg";
    FHEMduino_SimpleWrite($hash, $arg);
  } elsif( $cmd eq "patable" ) {
    return "Expecting a 0-padded hex number" if((length($arg)&1) == 1);
    Log3 $name, 3, "set $name $cmd $arg";
    $arg = "x$arg";
    FHEMduino_SimpleWrite($hash, $arg);
  } else {
    return "Unknown argument $cmd, choose one of ".$list;
  }

  return undef;
}

#####################################
sub
FHEMduino_Get($@)
{
  my ($hash, @a) = @_;
  my $type = $hash->{TYPE};

  return "\"get $type\" needs at least one parameter" if(@a < 2);
  if(!defined($gets{$a[1]})) {
    my @cList = map { $_ =~ m/^(file|raw)$/ ? $_ : "$_:noArg" } sort keys %gets;
    return "Unknown argument $a[1], choose one of " . join(" ", @cList);
  }

  my $arg = ($a[2] ? $a[2] : "");
  my ($msg, $err);
  my $name = $a[0];

  return "No $a[1] for dummies" if(IsDummy($name));

  Log3 $name, 5, "$name: command for gets: " . $gets{$a[1]}[0] . " " . $arg;
  
  FHEMduino_SimpleWrite($hash, $gets{$a[1]}[0] . $arg);

  ($err, $msg) = FHEMduino_ReadAnswer($hash, $a[1], 0, $gets{$a[1]}[1]);
  Log3 $name, 5, "$name: received message for gets: " . $msg;

  if(!defined($msg)) {
    DevIo_Disconnected($hash);
    $msg = "No answer";

  } elsif($a[1] eq "cmds") {       # nice it up
    $msg =~ s/.*Use one of//g;

  } elsif($a[1] eq "uptime") {     # decode it
    $msg =~ s/[\r\n]//g;
    $msg = hex($msg);              # /125; only for col or coc
    $msg = sprintf("%d %02d:%02d:%02d", $msg/86400, ($msg%86400)/3600, ($msg%3600)/60, $msg%60);
  }

  $msg =~ s/[\r\n]//g;

  $hash->{READINGS}{$a[1]}{VAL} = $msg;
  $hash->{READINGS}{$a[1]}{TIME} = TimeNow();

  return "$a[0] $a[1] => $msg";
}

sub
FHEMduino_Clear($)
{
  my $hash = shift;

  # Clear the pipe
  $hash->{RA_Timeout} = 0.1;
  for(;;) {
    my ($err, undef) = FHEMduino_ReadAnswer($hash, "Clear", 0, undef);
    last if($err && $err =~ m/^Timeout/);
  }
  delete($hash->{RA_Timeout});
}

#####################################
sub
FHEMduino_ResetDevice($)
{
  my ($hash) = @_;

  DevIo_CloseDev($hash);
  my $ret = DevIo_OpenDev($hash, 0, "FHEMduino_DoInit");

  return $ret;
}

#####################################
sub
FHEMduino_DoInit($)
{
  my $hash = shift;
  my $name = $hash->{NAME};
  my $err;
  my $msg = undef;

  FHEMduino_Clear($hash);
  my ($ver, $try) = ("", 0);
  while ($try++ < 3 && $ver !~ m/^V/) {
    FHEMduino_SimpleWrite($hash, "V");
    ($err, $ver) = FHEMduino_ReadAnswer($hash, "Version", 0, undef);
    return "$name: $err" if($err && ($err !~ m/Timeout/ || $try == 3));
    $ver = "" if(!$ver);
  }

  if($ver !~ m/^V/) {
    $attr{$name}{dummy} = 1;
    $msg = "Not an FHEMduino device, got for V:  $ver";
    Log3 $name, 1, $msg;
    return $msg;
  }
  $ver =~ s/[\r\n]//g;
  $hash->{VERSION} = $ver;

  # Cmd-String feststellen

  my $cmds = FHEMduino_Get($hash, $name, "cmds", 0);
  $cmds =~ s/$name cmds =>//g;
  $cmds =~ s/ //g;
  $hash->{CMDS} = $cmds;
  Log3 $name, 3, "$name: Possible commands: " . $hash->{CMDS};
#  if( my $initCommandsString = AttrVal($name, "initCommands", undef) ) {
#    my @initCommands = split(' ', $initCommandsString);
#    foreach my $command (@initCommands) {
#      FHEMduino_SimpleWrite($hash, $command);
#    }
#  }
  $hash->{STATE} = "Initialized";

  # Reset the counter
  delete($hash->{XMIT_TIME});
  delete($hash->{NR_CMD_LAST_H});
  return undef;
}

#####################################
# This is a direct read for commands like get
# Anydata is used by read file to get the filesize
sub
FHEMduino_ReadAnswer($$$$)
{
  my ($hash, $arg, $anydata, $regexp) = @_;
  my $type = $hash->{TYPE};

  while($hash->{TYPE} eq "FHEMduino_RFR") {   # Look for the first "real" FHEMduino
    $hash = $hash->{IODev};
  }

  return ("No FD", undef)
        if(!$hash || ($^O !~ /Win/ && !defined($hash->{FD})));

  my ($mFHEMduinodata, $rin) = ("", '');
  my $buf;
  my $to = 3;                                         # 3 seconds timeout
  $to = $hash->{RA_Timeout} if($hash->{RA_Timeout});  # ...or less
  for(;;) {

    if($^O =~ m/Win/ && $hash->{USBDev}) {
      $hash->{USBDev}->read_const_time($to*1000); # set timeout (ms)
      # Read anstatt input sonst funzt read_const_time nicht.
      $buf = $hash->{USBDev}->read(999);          
      return ("Timeout reading answer for get $arg", undef)
        if(length($buf) == 0);

    } else {
      return ("Device lost when reading answer for get $arg", undef)
        if(!$hash->{FD});

      vec($rin, $hash->{FD}, 1) = 1;
      my $nfound = select($rin, undef, undef, $to);
      if($nfound < 0) {
        next if ($! == EAGAIN() || $! == EINTR() || $! == 0);
        my $err = $!;
        DevIo_Disconnected($hash);
        return("FHEMduino_ReadAnswer $arg: $err", undef);
      }
      return ("Timeout reading answer for get $arg", undef)
        if($nfound == 0);
      $buf = DevIo_SimpleRead($hash);
      return ("No data", undef) if(!defined($buf));

    }

    if($buf) {
      Log3 $hash->{NAME}, 5, "FHEMduino/RAW (ReadAnswer): $buf";
      $mFHEMduinodata .= $buf;
    }
    $mFHEMduinodata = FHEMduino_RFR_DelPrefix($mFHEMduinodata) if($type eq "FHEMduino_RFR");

    # \n\n is socat special
    if($mFHEMduinodata =~ m/\r\n/ || $anydata || $mFHEMduinodata =~ m/\n\n/ ) {
      if($regexp && $mFHEMduinodata !~ m/$regexp/) {
        FHEMduino_Parse($hash, $hash, $hash->{NAME}, $mFHEMduinodata);
      } else {
        return (undef, $mFHEMduinodata)
      }
    }
  }

}

#####################################
# Check if the 1% limit is reached and trigger notifies
sub
FHEMduino_XmitLimitCheck($$)
{
  my ($hash,$fn) = @_;
  my $now = time();

  if(!$hash->{XMIT_TIME}) {
    $hash->{XMIT_TIME}[0] = $now;
    $hash->{NR_CMD_LAST_H} = 1;
    return;
  }

  my $nowM1h = $now-3600;
  my @b = grep { $_ > $nowM1h } @{$hash->{XMIT_TIME}};

  if(@b > 163) {          # Maximum nr of transmissions per hour (unconfirmed).

    my $name = $hash->{NAME};
    Log3 $name, 2, "FHEMduino TRANSMIT LIMIT EXCEEDED";
    DoTrigger($name, "TRANSMIT LIMIT EXCEEDED");

  } else {

    push(@b, $now);

  }
  $hash->{XMIT_TIME} = \@b;
  $hash->{NR_CMD_LAST_H} = int(@b);
}


#####################################
sub
FHEMduino_Write($$$)
{
  my ($hash,$fn,$msg) = @_;

  my $name = $hash->{NAME};

  Log3 $name, 5, "$hash->{NAME} sending $fn$msg";
  my $bstring = "$fn$msg";

  FHEMduino_SimpleWrite($hash, $bstring);

}

sub
FHEMduino_SendFromQueue($$)
{
  my ($hash, $bstring) = @_;
  my $name = $hash->{NAME};

  if($bstring ne "") {
	FHEMduino_XmitLimitCheck($hash,$bstring);
    FHEMduino_SimpleWrite($hash, $bstring);
  }

  ##############
  # Write the next buffer not earlier than 0.23 seconds
  # = 3* (12*0.8+1.2+1.0*5*9+0.8+10) = 226.8ms
  # else it will be sent too early by the FHEMduino, resulting in a collision
  InternalTimer(gettimeofday()+0.3, "FHEMduino_HandleWriteQueue", $hash, 1);
}

#####################################
sub
FHEMduino_HandleWriteQueue($)
{
  my $hash = shift;
  my $arr = $hash->{QUEUE};
  if(defined($arr) && @{$arr} > 0) {
    shift(@{$arr});
    if(@{$arr} == 0) {
      delete($hash->{QUEUE});
      return;
    }
    my $bstring = $arr->[0];
    if($bstring eq "") {
      FHEMduino_HandleWriteQueue($hash);
    } else {
      FHEMduino_SendFromQueue($hash, $bstring);
    }
  }
}

#####################################
# called from the global loop, when the select for hash->{FD} reports data
sub
FHEMduino_Read($)
{
  my ($hash) = @_;

  my $buf = DevIo_SimpleRead($hash);
  return "" if(!defined($buf));
  my $name = $hash->{NAME};

  my $FHEMduinodata = $hash->{PARTIAL};
  Log3 $name, 5, "FHEMduino/RAW: $FHEMduinodata/$buf"; 
  $FHEMduinodata .= $buf;

  while($FHEMduinodata =~ m/\n/) {
    my $rmsg;
    ($rmsg,$FHEMduinodata) = split("\n", $FHEMduinodata, 2);
    $rmsg =~ s/\r//;
    FHEMduino_Parse($hash, $hash, $name, $rmsg) if($rmsg);
  }
  $hash->{PARTIAL} = $FHEMduinodata;
}

sub
FHEMduino_Parse($$$$)
{
  my ($hash, $iohash, $name, $rmsg) = @_;

  my $rssi;
##Sven: Auch hier würde sich eine Anpassung auf Basis der oben definierten Regex lohnen. Da wird ja doppelt gemoppelt noch mal ausgewertet zu welchem Protokoll jetzt eine Nachricht vorliegt.
## 
##
  my $dmsg = $rmsg;
  if($dmsg =~ m/^[AFTKEHRStZri]([A-F0-9][A-F0-9])+$/) { # RSSI
    my $l = length($dmsg);
    $rssi = hex(substr($dmsg, $l-2, 2));
    $dmsg = substr($dmsg, 0, $l-2);
    $rssi = ($rssi>=128 ? (($rssi-256)/2-74) : ($rssi/2-74));
    Log3 $name, 5, "$name: $dmsg $rssi";
  } else {
    Log3 $name, 5, "$name: $dmsg";
  }

  ###########################################
  #Translate Message from FHEMduino to FHZ
  next if(!$dmsg || length($dmsg) < 1);            # Bogus messages

  if($dmsg =~ m/^[0-9A-F]{4}U./) {                 # RF_ROUTER
    Dispatch($hash, $dmsg, undef);
    return;
  }

  if ($dmsg =~ m/^(3[8-9A-F]|[4-6][0-9A-F]|7[0-8]).*/) {
  ### implement error checking here!
    Log3 $name, 4, "Dispatching OREGON Protokoll. Received: $dmsg";
    Dispatch($hash, $dmsg, undef);
    return;		
  }

  my $fn = substr($dmsg,0,1);
  my $len = int(length($dmsg));

  if($fn eq "i" && $len >= 7) {           # IT
    $dmsg = lc($dmsg);
  } 
  elsif($fn eq "E" && $len >= 2) {        # EZ6 Meteo
  ### implement error checking here!
  ;
  }
  elsif($fn eq "W" && $len >= 12) {       # Weather sensors; allways filled up to 13 letters
    $dmsg = uc($dmsg);
  ### implement error checking here!
  ;
  }
  elsif($fn eq "T" && $len >= 2) {        # Technoline TX2/3/4
    Log3 $name, 4, "CUL_TX: $dmsg";
  ### implement error checking here!
  ;
  }
  elsif($fn eq "I" && $len >= 2) {		# PT2262
    Dispatch($hash, $dmsg, undef);
  ### implement error checking here!
  ;
  }
  elsif($fn eq "D" && $len >= 2) {		# DCF77
    Log3 $name, 4, "DCF77: $dmsg";
  ### implement error checking here!
  ;
  }
  elsif($fn eq "F" && $len >= 2) {		# FA20RF
    Log3 $name, 4, "FA20RF: $dmsg";
  ### implement error checking here!
  ;
  }
  elsif($fn eq "M" && $len >= 6) {        # Door bells TCM (Tchibo)
    Log3 $name, 4, "TCM: $dmsg";
  ### implement error checking here!
  ;
  }
  elsif($fn eq "H" && $len >= 4) {        # Door bells Heidemann HX
    Log3 $name, 4, "HX: $dmsg";
  ### implement error checking here!
  ;
  }
  elsif($fn eq "O" && $len >= 2) {        # Oregon
    Log3 $name, 4, "OSVduino: $dmsg";
  }
  elsif($fn eq "A" && $len >= 10 && $len <20 ) {        # ArduSens
    Log3 $name, 4, "AS: $dmsg";
  }
  elsif($fn eq "A" && $len >= 34) {        # ARC - ITselflearn
    Log3 $name, 4, "ARC: $dmsg";
  }  else {
    DoTrigger($name, "UNKNOWNCODE $dmsg message length ($len)");
    Log3 $name, 2, "$name: unknown message $dmsg message length ($len)";
    return;
  }

  $hash->{"${name}_MSGCNT"}++;
  $hash->{"${name}_TIME"} = TimeNow();
  $hash->{RAWMSG} = $rmsg;
  my %addvals = (RAWMSG => $rmsg);
  if(defined($rssi)) {
    $hash->{RSSI} = $rssi;
    $addvals{RSSI} = $rssi;
  }
  Dispatch($hash, $dmsg, \%addvals);
}


#####################################
sub
FHEMduino_Ready($)
{
  my ($hash) = @_;

  return DevIo_OpenDev($hash, 1, "FHEMduino_DoInit")
                if($hash->{STATE} eq "disconnected");

  # This is relevant for windows/USB only
  my $po = $hash->{USBDev};
  my ($BlockingFlags, $InBytes, $OutBytes, $ErrorFlags);
  if($po) {
    ($BlockingFlags, $InBytes, $OutBytes, $ErrorFlags) = $po->status;
  }
  return ($InBytes && $InBytes>0);
}

########################
sub
FHEMduino_SimpleWrite(@)
{
  my ($hash, $msg, $nonl) = @_;
  return if(!$hash);
  if($hash->{TYPE} eq "FHEMduino_RFR") {
    # Prefix $msg with RRBBU and return the corresponding FHEMduino hash.
    ($hash, $msg) = FHEMduino_RFR_AddPrefix($hash, $msg); 
  }

  my $name = $hash->{NAME};
  Log3 $name, 5, "SW: $msg";

  $msg .= "\n" unless($nonl);

  $hash->{USBDev}->write($msg)    if($hash->{USBDev});
  syswrite($hash->{TCPDev}, $msg) if($hash->{TCPDev});
  syswrite($hash->{DIODev}, $msg) if($hash->{DIODev});

  # Some linux installations are broken with 0.001, T01 returns no answer
  select(undef, undef, undef, 0.01);
}

sub
FHEMduino_Attr(@)
{
  my @a = @_;

  return undef;
}

1;

=pod
=begin html

<a name="FHEMduino"></a>
<h3>FHEMduino</h3>
<ul>

  <table>
  <tr><td>
  The FHEMduino ia based on an idea from mdorenka published at <a
  href="http://forum.fhem.de/index.php/topic,17196.0.html">FHEM Forum</a>.

  With the opensource firmware (see this <a
  href="https://github.com/mdorenka">link</a>) they are capable
  to receive and send different 433MHz protocols.
  <br><br>
  
  The following protocols are available:
  <br><br>
  
  Date / Time protocol  <br>
  DCF-77 --> 14_FHEMduino_DCF77.pm <br>
  <br><br>
  
  Wireless switches  <br>
  PT2262 (IT / ELRO switches) --> 14_FHEMduino_PT2262.pm <br>
  <br><br>
  
  Smoke detector   <br>
  Flamingo FA20RF / ELRO RM150RF  --> 14_FHEMduino_FA20RF.pm<br>
  <br><br>
  
  Door bells   <br>
  Heidemann HX Series --> 14_FHEMduino_HX.pm<br>
  Tchibo TCM --> 14_FHEMduino_TCM.pm<br>
  <br><br>

  Temperatur / humidity sensors  <br>
  KW9010  --> 14_FHEMduino_Env.pm<br>
  PEARL NC7159, LogiLink WS0002  --> 14_FHEMduino_Env.pm<br>
  EUROCHRON / Tchibo  --> 14_FHEMduino_Env.pm<br>
  LIFETEC  --> 14_FHEMduino_Env.pm<br>
  TX70DTH  --> 14_FHEMduino_Env.pm<br>
  AURIOL   --> 14_FHEMduino_Env.pm<br>
  Intertechno TX2/3/4  --> CUL_TX.pm<br>
  <br><br>

  It is possible to attach more than one device in order to get better
  reception, fhem will filter out duplicate messages.<br><br>

  Note: this module may require the Device::SerialPort or Win32::SerialPort
  module if you attach the device via USB and the OS sets strange default
  parameters for serial devices.

  </td><td>
  <img src="ccc.jpg"/>
  </td></tr>
  </table>

  <a name="FHEMduinodefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; FHEMduino &lt;device&gt; &lt;FHTID&gt;</code> <br>
    <br>
    USB-connected devices (FHEMduino/CUR/CUN):<br><ul>
      &lt;device&gt; specifies the serial port to communicate with the FHEMduino.
	  The name of the serial-device depends on your distribution, under
      linux the cdc_acm kernel module is responsible, and usually a
      /dev/ttyACM0 device will be created. If your distribution does not have a
      cdc_acm module, you can force usbserial to handle the FHEMduino by the
      following command:<ul>modprobe usbserial vendor=0x03eb
      product=0x204b</ul>In this case the device is most probably
      /dev/ttyUSB0.<br><br>

      You can also specify a baudrate if the device name contains the @
      character, e.g.: /dev/ttyACM0@38400<br><br>

      If the baudrate is "directio" (e.g.: /dev/ttyACM0@directio), then the
      perl module Device::SerialPort is not needed, and fhem opens the device
      with simple file io. This might work if the operating system uses sane
      defaults for the serial parameters, e.g. some Linux distributions and
      OSX.  <br><br>

  </ul>
  <br>

  <a name="FHEMduinoset"></a>
  <b>Set </b>
  <ul>
    <li>raw<br>
        Issue a FHEMduino firmware command.  See the <a
        href="http://FHEMduinofw.de/commandref.html">this</a> document
        for details on FHEMduino commands.
    </li><br>

    <li>flash [hexFile]<br>
    The JeeLink needs the right firmware to be able to receive and deliver the sensor data to fhem. In addition to the way using the
    arduino IDE to flash the firmware into the JeeLink this provides a way to flash it directly from FHEM.

    There are some requirements:
    <ul>
      <li>avrdude must be installed on the host<br>
      On a Raspberry PI this can be done with: sudo apt-get install avrdude</li>
      <li>the flashCommand attribute must be set.<br>
        This attribute defines the command, that gets sent to avrdude to flash the JeeLink.<br>
        The default is: avrdude -p atmega328P -c arduino -P [PORT] -D -U flash:w:[HEXFILE] 2>[LOGFILE]<br>
        It contains some place-holders that automatically get filled with the according values:<br>
        <ul>
          <li>[PORT]<br>
            is the port the JeeLink is connectd to (e.g. /dev/ttyUSB0)</li>
          <li>[HEXFILE]<br>
            is the .hex file that shall get flashed. There are three options (applied in this order):<br>
            - passed in set flash<br>
            - taken from the hexFile attribute<br>
            - the default value defined in the module<br>
          </li>
          <li>[LOGFILE]<br>
            The logfile that collects information about the flash process. It gets displayed in FHEM after finishing the flash process</li>
        </ul>
      </li>
    </ul>
    </li><br>

    <li>led &lt;on|off&gt;<br>
    Is used to disable the blue activity LED
    </li><br>

  </ul>
  <a name="FHEMduinoget"></a>
  <b>Get</b>
  <ul>
    <li>version<br>
        return the FHEMduino firmware version
        </li><br>
    <li>raw<br>
        Issue a FHEMduino firmware command, and wait for one line of data returned by
        the FHEMduino. See the FHEMduino firmware README document for details on FHEMduino
        commands.
        </li><br>
    <li>cmds<br>
        Depending on the firmware installed, FHEMduinos have a different set of
        possible commands. Please refer to the README of the firmware of your
        FHEMduino to interpret the response of this command. See also the raw-
        command.
        </li><br>
  </ul>

  <a name="FHEMduinoattr"></a>
  <b>Attributes</b>
  <ul>
    <li><a href="#do_not_notify">do_not_notify</a></li>
    <li><a href="#attrdummy">dummy</a></li>
    <li><a href="#showtime">showtime</a></li>
    <li><a href="#model">model</a> (FHEMduino,CUN,CUR)</li>
  </ul>
  <br>
</ul>

=end html
=cut
