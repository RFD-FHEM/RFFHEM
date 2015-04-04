##############################################
# $Id: 00_SIGNALduino.pm 
# The file is taken from the FHEMduino project
# see http://www.fhemwiki.de/wiki/FHEMduino
# and was modified
# to provide support for raw message handling
# The purpos is to use it as addition to the SIGNALduino
# modules in combination with RFDuino
# N. Butzek, S. Butzek, 2014-2015 
#

package main;

use strict;
use warnings;
use Time::HiRes qw(gettimeofday);
use Data::Dumper qw(Dumper);
use POSIX qw( floor);

sub SIGNALduino_Attr(@);
sub SIGNALduino_Clear($);
#sub SIGNALduino_HandleCurRequest($$);
#sub SIGNALduino_HandleWriteQueue($);
sub SIGNALduino_Parse($$$$@);
sub SIGNALduino_Read($);
sub SIGNALduino_ReadAnswer($$$$);
sub SIGNALduino_Ready($);
sub SIGNALduino_Write($$$);

sub SIGNALduino_SimpleWrite(@);

my %gets = (    # Name, Data to send to the SIGNALduino, Regexp for the answer
  "version"  => ["V", '^V .*'],
  "raw"      => ["", '.*'],
  "uptime"   => ["t", '^[0-9A-F]{8}[\r\n]*$' ],
  "cmds"     => ["?", '.*Use one of[ 0-9A-Za-z]+[\r\n]*$' ],
  "ITParms"  => ["ip",'.*' ],
  "FAParms"  => ["fp", '.*' ],
  "TCParms"  => ["dp", '.*' ],
  "HXParms"  => ["hp", '.*' ]
);


my %sets = (
  "raw"       => "",
  "flash"     => "",
  "reset"     => ""
);

my $clientsSIGNALduino = "";

my %matchListSIGNALduino = (
#    "1:CUL_TX"             => "^TX..........",        # Need TX to avoid FHTTK
#    "2:SIGNALduino_Env"      => "W.*\$",
#    "3:SIGNALduino_PT2262"   => "IR.*\$",
#    "4:SIGNALduino_HX"       => "H...\$",
#    "5:OREGON"            => "^(3[8-9A-F]|[4-6][0-9A-F]|7[0-8]).*",
#    "6:SIGNALduino_AS"      => "AS.*\$", #Arduino based Sensors
#    "7:SIGNALduino_ARC"     => "AR.*\$", #ARC protocol switches like IT selflearn
);

		#protoID[0]=(s_sigid){-4,-8,-18,500,0,twostate}; // Logi
		#protoID[1]=(s_sigid){-4,-8,-18,500,0,twostate}; // TCM 97001
		#protoID[2]=(s_sigid){-1,-2,-18,500,0,twostate}; // AS
		#protoID[3]=(s_sigid){-1,3,-30,pattern[clock][0],0,tristate}; // IT old


my %ProtocolListSIGNALduino  = (
    "1"    => 
        {
            name			=> 'EV1527type',
			id          	=> '1',
			one				=> [1,-8],
			zero			=> [1,-4],
			sync			=> [1,-18],		
			clockabs   		=> '500',		# not used now
			format     		=> 'twostate',  # not used now
			
        },
    
    "2"    => 
        {
            name			=> 'pt2262',
			id          	=> '3',
			one				=> [1,-1],
			zero			=> [1,-3],
			float			=> [-1,3],
			sync			=> [1,-30],
			clockabs     	=> 'auto',		# not used now
			format 			=> 'tristate',	# not used now
        },
    
);




##Sven: Vorschlag sollten wir hier nicht mal das Protokoll, also das Nachrichtenformat etwas abändern. Bem OSV2 z.B. fand ich ganz gut, dass die ersten beiden Werte die Länge der Nachricht wiederspiegeln (HEX)
##      Darauf kann man ja ganz gut eine Regex bauen um das Protokoll zu ermitteln. Dass wir hier machchmal einen Buchstaben, manchmal zwei und hin und wieder auch eine konkrete Länge haben macht es etwas unübersichlicht.

sub
SIGNALduino_Initialize($)
{
  my ($hash) = @_;

  require "$attr{global}{modpath}/FHEM/DevIo.pm";

# Provider
  $hash->{ReadFn}  = "SIGNALduino_Read";
  $hash->{WriteFn} = "SIGNALduino_Write";
  $hash->{ReadyFn} = "SIGNALduino_Ready";

# Normal devices
  $hash->{DefFn}  		 	= "SIGNALduino_Define";
  $hash->{FingerprintFn} 	= "SIGNALduino_FingerprintFn";
  $hash->{UndefFn} 		 	= "SIGNALduino_Undef";
  $hash->{GetFn}   			= "SIGNALduino_Get";
  $hash->{SetFn}   			= "SIGNALduino_Set";
  $hash->{AttrFn}  			= "SIGNALduino_Attr";
  $hash->{AttrList}			= #"Clients MatchList "
					  "do_not_notify:1,0 dummy:1,0 "
					  ." hexFile"
                      ." initCommands"
                      ." flashCommand"
                      .$readingFnAttributes;

  $hash->{ShutdownFn} = "SIGNALduino_Shutdown";

}

sub
SIGNALduino_FingerprintFn($$)
{
  my ($name, $msg) = @_;

  # Store only the "relevant" part, as the Signalduino won't compute the checksum
  $msg = substr($msg, 8) if($msg =~ m/^81/ && length($msg) > 8);

  return ($name, $msg);
}

#####################################
sub
SIGNALduino_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);

  if(@a != 3) {
    my $msg = "wrong syntax: define <name> SIGNALduino {none | devicename[\@baudrate] | devicename\@directio | hostname:port}";
    Log3 undef, 2, $msg;
    return $msg;
  }

  DevIo_CloseDev($hash);

  my $name = $a[0];

  my $dev = $a[2];
  $dev .= "\@9600" if( $dev !~ m/\@/ );
  
  $hash->{CMDS} = "";
  $hash->{Clients} = $clientsSIGNALduino;
  $hash->{MatchList} = \%matchListSIGNALduino;

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
  my $ret = DevIo_OpenDev($hash, 0, "SIGNALduino_DoInit");
  return $ret;
}

#####################################
sub
SIGNALduino_Undef($$)
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

  SIGNALduino_Shutdown($hash);
  DevIo_CloseDev($hash); 
  return undef;
}

#####################################
sub
SIGNALduino_Shutdown($)
{
  my ($hash) = @_;
  SIGNALduino_SimpleWrite($hash, "X00");  # Switch reception off, it may hang up the SIGNALduino
  return undef;
}

#####################################
sub
SIGNALduino_Set($@)
{
  my ($hash, @a) = @_;

  return "\"set SIGNALduino\" needs at least one parameter" if(@a < 2);
  return "Unknown argument $a[1], choose one of " . join(" ", sort keys %sets)
  	if(!defined($sets{$a[1]}));

  my $name = shift @a;
  my $cmd = shift @a;
  my $arg = join(" ", @a);
  
  #my $list = "raw led:on,off led-on-for-timer reset flash";
  #return $list if( $cmd eq '?' || $cmd eq '');

  if($cmd eq "raw") {
    Log3 $name, 4, "set $name $cmd $arg";
    SIGNALduino_SimpleWrite($hash, $arg);
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

    DevIo_OpenDev($hash, 0, "SIGNALduino_DoInit");
    $log .= "$name opened\n";

    return $log;

  } elsif ($cmd =~ m/reset/i) {
    return SIGNALduino_ResetDevice($hash);
  } else {
    return "Unknown argument $cmd, choose one of ".$hash->{CMDS};
  }

  return undef;
}

#####################################
sub
SIGNALduino_Get($@)
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
  
  SIGNALduino_SimpleWrite($hash, $gets{$a[1]}[0] . $arg);

  ($err, $msg) = SIGNALduino_ReadAnswer($hash, $a[1], 0, $gets{$a[1]}[1]);
  Log3 $name, 5, "$name: received message for gets: " . $msg if ($msg);

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
SIGNALduino_Clear($)
{
  my $hash = shift;

  # Clear the pipe
  $hash->{RA_Timeout} = 0.1;
  for(;;) {
    my ($err, undef) = SIGNALduino_ReadAnswer($hash, "Clear", 0, undef);
    last if($err && $err =~ m/^Timeout/);
  }
  delete($hash->{RA_Timeout});
}

#####################################
sub
SIGNALduino_ResetDevice($)
{
  my ($hash) = @_;

  DevIo_CloseDev($hash);
  my $ret = DevIo_OpenDev($hash, 0, "SIGNALduino_DoInit");

  return $ret;
}

#####################################
sub
SIGNALduino_DoInit($)
{
  my $hash = shift;
  my $name = $hash->{NAME};
  my $err;
  my $msg = undef;

  SIGNALduino_Clear($hash);
  my ($ver, $try) = ("", 0);
  
  # Try to get version from Arduino
  while ($try++ < 3 && $ver !~ m/^V/) {
    SIGNALduino_SimpleWrite($hash, "V");
    ($err, $ver) = SIGNALduino_ReadAnswer($hash, "Version", 0, undef);
    return "$name: $err" if($err && ($err !~ m/Timeout/ || $try == 3));
    $ver = "" if(!$ver);
  }

  # Check received string
  if($ver !~ m/^V/) {
    $attr{$name}{dummy} = 1;
    $msg = "Not an SIGNALduino device, got for V:  $ver";
    Log3 $name, 1, $msg;
    return $msg;
  }
  $ver =~ s/[\r\n]//g;
  $hash->{VERSION} = $ver;

  # Cmd-String feststellen

  my $cmds = SIGNALduino_Get($hash, $name, "cmds", 0);
  $cmds =~ s/$name cmds =>//g;
  $cmds =~ s/ //g;
  $hash->{CMDS} = $cmds;
  Log3 $name, 3, "$name: Possible commands: " . $hash->{CMDS};
#  if( my $initCommandsString = AttrVal($name, "initCommands", undef) ) {
#    my @initCommands = split(' ', $initCommandsString);
#    foreach my $command (@initCommands) {
#      SIGNALduino_SimpleWrite($hash, $command);
#    }
#  }
#  $hash->{STATE} = "Initialized";
  readingsSingleUpdate($hash, "state", "Initialized", 1);

  # Reset the counter
  delete($hash->{XMIT_TIME});
  delete($hash->{NR_CMD_LAST_H});
  return undef;
}

#####################################
# This is a direct read for commands like get
# Anydata is used by read file to get the filesize
sub
SIGNALduino_ReadAnswer($$$$)
{
  my ($hash, $arg, $anydata, $regexp) = @_;
  my $type = $hash->{TYPE};

  while($hash->{TYPE} eq "SIGNALduino_RFR") {   # Look for the first "real" SIGNALduino
    $hash = $hash->{IODev};
  }

  return ("No FD", undef)
        if(!$hash || ($^O !~ /Win/ && !defined($hash->{FD})));

  my ($mSIGNALduinodata, $rin) = ("", '');
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
        return("SIGNALduino_ReadAnswer $arg: $err", undef);
      }
      return ("Timeout reading answer for get $arg", undef)
        if($nfound == 0);
      $buf = DevIo_SimpleRead($hash);
      return ("No data", undef) if(!defined($buf));

    }

    if($buf) {
      Log3 $hash->{NAME}, 5, "SIGNALduino/RAW (ReadAnswer): $buf";
      $mSIGNALduinodata .= $buf;
    }
    $mSIGNALduinodata = SIGNALduino_RFR_DelPrefix($mSIGNALduinodata) if($type eq "SIGNALduino_RFR");

    # \n\n is socat special
    if($mSIGNALduinodata =~ m/\r\n/ || $anydata || $mSIGNALduinodata =~ m/\n\n/ ) {
      if($regexp && $mSIGNALduinodata !~ m/$regexp/) {
        SIGNALduino_Parse($hash, $hash, $hash->{NAME}, $mSIGNALduinodata);
      } else {
        return (undef, $mSIGNALduinodata)
      }
    }
  }

}

#####################################
# Check if the 1% limit is reached and trigger notifies
sub
SIGNALduino_XmitLimitCheck($$)
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
    Log3 $name, 2, "SIGNALduino TRANSMIT LIMIT EXCEEDED";
    DoTrigger($name, "TRANSMIT LIMIT EXCEEDED");

  } else {

    push(@b, $now);

  }
  $hash->{XMIT_TIME} = \@b;
  $hash->{NR_CMD_LAST_H} = int(@b);
}


#####################################
sub
SIGNALduino_Write($$$)
{
  my ($hash,$fn,$msg) = @_;

  my $name = $hash->{NAME};

  Log3 $name, 5, "$hash->{NAME} sending $fn$msg";
  my $bstring = "$fn$msg";

  SIGNALduino_SimpleWrite($hash, $bstring);

}

#sub
#SIGNALduino_SendFromQueue($$)
#{
#  my ($hash, $bstring) = @_;
#  my $name = $hash->{NAME};
#
#  if($bstring ne "") {
#	SIGNALduino_XmitLimitCheck($hash,$bstring);
#    SIGNALduino_SimpleWrite($hash, $bstring);
#  }

  ##############
  # Write the next buffer not earlier than 0.23 seconds
  # = 3* (12*0.8+1.2+1.0*5*9+0.8+10) = 226.8ms
  # else it will be sent too early by the SIGNALduino, resulting in a collision
#  InternalTimer(gettimeofday()+0.3, "SIGNALduino_HandleWriteQueue", $hash, 1);
#}

#####################################
#sub
#SIGNALduino_HandleWriteQueue($)
#{
#  my $hash = shift;
#  my $arr = $hash->{QUEUE};
#  if(defined($arr) && @{$arr} > 0) {
#    shift(@{$arr});
#    if(@{$arr} == 0) {
#      delete($hash->{QUEUE});
#      return;
#    }
#    my $bstring = $arr->[0];
#    if($bstring eq "") {
#      SIGNALduino_HandleWriteQueue($hash);
#    } else {
#      SIGNALduino_SendFromQueue($hash, $bstring);
#    }
#  }
#}

#####################################
# called from the global loop, when the select for hash->{FD} reports data
sub
SIGNALduino_Read($)
{
  my ($hash) = @_;

  my $buf = DevIo_SimpleRead($hash);
  return "" if(!defined($buf));
  my $name = $hash->{NAME};

  my $SIGNALduinodata = $hash->{PARTIAL};
  Log3 $name, 5, "SIGNALduino/RAW: $SIGNALduinodata/$buf"; 
  $SIGNALduinodata .= $buf;

  while($SIGNALduinodata =~ m/\n/) {
    my $rmsg;
    ($rmsg,$SIGNALduinodata) = split("\n", $SIGNALduinodata, 2);
    $rmsg =~ s/\r//;
    SIGNALduino_Parse($hash, $hash, $name, $rmsg) if($rmsg);
  }
  $hash->{PARTIAL} = $SIGNALduinodata;
}




### Helper Subs >>>

sub
SIGNALduino_splitMsg
{
  my $txt = shift;
  my $delim = shift;
  my @msg_parts = split(/$delim/,$txt);
  
  return @msg_parts;
}



#SIGNALduino_MatchSignalPattern{@array, %hash, @array, $scalar};
sub SIGNALduino_MatchSignalPattern(\@\%\@$){

	my ($signalpattern,  $patternList,  $data_array, $idx) = @_;
	
	#print Dumper($patternList);		
	#print Dumper($idx);		
	#print Dumper($signalpattern);		
	my $found=0;
	foreach ( @{$signalpattern} )
	{
			#print " $idx check: ".$patternList->{$data_array->[$idx]}." == ".$_;		
			#print "\n";;
			if ($patternList->{$data_array->[$idx]} != $_ ) 
			{
				return -1;
			}
			$found=1;
			$idx++;
	}
	if ($found)
	{
		return $idx;
	}
	
}

### >>> Helper Subs 


sub
SIGNALduino_Parse($$$$@)
{
  my ($hash, $iohash, $name, $rmsg,$initstr) = @_;

	#print Dumper(\%ProtocolListSIGNALduino);

    #print "$protocol: ";
    #Log3 $name, 3, "id: $protocol=$ProtocolListSIGNALduino{$protocol}{id} ";
    
	#### TODO:  edit print statements to log statements
	
	#print "$name: search $search_string $rmsg\n";
	if ($rmsg=~ m/^M\d+/) ## Check if a Data Message arrived
	{
		my @msg_parts = SIGNALduino_splitMsg($rmsg,';');
		my $protocolid;
		
		my $syncidx;			# currently not used to decode message
		my $clockidx;			
		my $protocol;
		my $rawData;


		#print "Message splitted:";
		#print Dumper(\@msg_parts);

		
		my %patternList;
		foreach (@msg_parts){
 		   
		   if ($_ =~ m/^M/) 		#### Extract ID from data
		   {
			   $protocolid = $_ = s/\d+/r/;  
			   $protocol=$ProtocolListSIGNALduino{$protocolid}{name};	
			   print "$name: found $protocol with id: $protocolid Raw message: ($rmsg)\n";
		   }
		   elsif ($_ =~ m/^P/) 		#### Extract Pattern List from array
		   {
			   $_ =~ s/^P+//;  
			   my @pattern = split(/=/,$_);
			   $patternList{$pattern[0]} = $pattern[1];
		   }
		   elsif($_ =~ m/D=\d+/) 		#### Message from array
		   {
				$_ =~ s/D=//;  
				$rawData = $_ ;
		   }
		   elsif($_ =~ m/SP=\d+/) 		#### Sync Pulse Index
		   {
				(undef, $syncidx) = split(/=/,$_);
		   }
		   elsif($_ =~ m/CP=\d+/) 		#### Clock Pulse Index
		   {
				(undef, $clockidx) = split(/=/,$_);
				
		   }

 		   #print "$_\n";
		}
		
		## Make a lookup table for our pattern ids
		#print "List of pattern:";
		%patternList = map { $_ => floor($patternList{$_}/$patternList{$clockidx}) } keys %patternList; 
		#print Dumper(\%patternList);		
		
		#### Convert rawData in Message
		my @data_array = split( '', $rawData ); # string to array
		my @bit_msg;							# array to store decoded signal bits
		
		## Iterate over the data_array and find zero, one and sync bits with the signalpattern
	
		for ( my $i=0;$i<@data_array;$i++)  ## Does this work also for tristate?
		{
			my $tmp_idx=$i;
			if ( ($tmp_idx=SIGNALduino_MatchSignalPattern(@{$ProtocolListSIGNALduino{$protocolid}{zero}},%patternList,@data_array,$i)) != -1 ) {
				push(@bit_msg,0);
				$i=$tmp_idx-1;
			} elsif ( ($tmp_idx=SIGNALduino_MatchSignalPattern(@{$ProtocolListSIGNALduino{$protocolid}{one}},%patternList,@data_array,$i)) != -1 ) {
				push(@bit_msg,1);
				$i=$tmp_idx-1;
			} elsif ( ($tmp_idx=SIGNALduino_MatchSignalPattern(@{$ProtocolListSIGNALduino{$protocolid}{sync}},%patternList,@data_array,$i)) != -1 ) {
				push(@bit_msg,'S');
				$i=$tmp_idx-1;
			## aditional check for tristate protocols
			} elsif ( defined($ProtocolListSIGNALduino{$protocolid}{float}) && ($tmp_idx=SIGNALduino_MatchSignalPattern(@{$ProtocolListSIGNALduino{$protocolid}{float}},%patternList,@data_array,$i)) != -1 ) {
				push(@bit_msg,'F');
				$i=$tmp_idx-1;
			
			}
		}
		print "$name: decoded message raw (@bit_msg), ".@bit_msg." bits\n";
		### Next step: Send RAW Message to clients. May we need to adapt some of them or modify our format to fit
	}
  
  
	my $dmsg="";

	####
	#  $hash->{"${name}_MSGCNT"}++;
	#  $hash->{"${name}_TIME"} = TimeNow();
	#  readingsSingleUpdate($hash, "state", $hash->{READINGS}{state}{VAL}, 0);
	#  $hash->{RAWMSG} = $rmsg;
	#  my %addvals = (RAWMSG => $rmsg);
	#  Dispatch($hash, $dmsg, \%addvals);  ## Dispatch to other Modules 

}


#####################################
sub
SIGNALduino_Ready($)
{
  my ($hash) = @_;

  return DevIo_OpenDev($hash, 1, "SIGNALduino_DoInit")
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
SIGNALduino_SimpleWrite(@)
{
  my ($hash, $msg, $nonl) = @_;
  return if(!$hash);
  if($hash->{TYPE} eq "SIGNALduino_RFR") {
    # Prefix $msg with RRBBU and return the corresponding SIGNALduino hash.
    ($hash, $msg) = SIGNALduino_RFR_AddPrefix($hash, $msg); 
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
SIGNALduino_Attr(@)
{
  my @a = @_;

  return undef;
}

1;

=pod
=begin html

<a name="SIGNALduino"></a>
<h3>SIGNALduino</h3>
<ul>

  <table>
  <tr><td>
  The SIGNALduino ia based on an idea from mdorenka published at <a
  href="http://forum.fhem.de/index.php/topic,17196.0.html">FHEM Forum</a>.

  With the opensource firmware (see this <a
  href="https://github.com/RFD-FHEM/RFDuino">link</a>) they are capable
  to receive and send different wireless protocols.
  <br><br>
  
  The following protocols are available:
  <br><br>
  
  
  Wireless switches  <br>
  PT2262 (IT / ELRO switches) --> 14_SIGNALduino_PT2262.pm <br>
  <br><br>
  
  Smoke detector   <br>
  Flamingo FA20RF / ELRO RM150RF  --> 14_SIGNALduino_FA20RF.pm<br>
  <br><br>
  
  Door bells   <br>
  Heidemann HX Series --> 14_SIGNALduino_HX.pm<br>
  Tchibo TCM --> 14_SIGNALduino_TCM.pm<br>
  <br><br>

  Temperatur / humidity sensors  <br>
  KW9010  --> 14_SIGNALduino_Env.pm<br>
  PEARL NC7159, LogiLink WS0002  --> 14_SIGNALduino_Env.pm<br>
  EUROCHRON / Tchibo  --> 14_SIGNALduino_Env.pm<br>
  LIFETEC  --> 14_SIGNALduino_Env.pm<br>
  TX70DTH  --> 14_SIGNALduino_Env.pm<br>
  AURIOL   --> 14_SIGNALduino_Env.pm<br>
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

  <a name="SIGNALduinodefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; SIGNALduino &lt;device&gt; &lt;FHTID&gt;</code> <br>
    <br>
    USB-connected devices (SIGNALduino):<br><ul>
      &lt;device&gt; specifies the serial port to communicate with the SIGNALduino.
	  The name of the serial-device depends on your distribution, under
      linux the cdc_acm kernel module is responsible, and usually a
      /dev/ttyACM0 device will be created. If your distribution does not have a
      cdc_acm module, you can force usbserial to handle the SIGNALduino by the
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

  <a name="SIGNALduinoset"></a>
  <b>Set </b>
  <ul>
    <li>raw<br>
        Issue a SIGNALduino firmware command.  See the <a
        href="http://SIGNALduinofw.de/commandref.html">this</a> document
        for details on SIGNALduino commands.
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
  <a name="SIGNALduinoget"></a>
  <b>Get</b>
  <ul>
    <li>version<br>
        return the SIGNALduino firmware version
        </li><br>
    <li>raw<br>
        Issue a SIGNALduino firmware command, and wait for one line of data returned by
        the SIGNALduino. See the SIGNALduino firmware README document for details on SIGNALduino
        commands.
        </li><br>
    <li>cmds<br>
        Depending on the firmware installed, SIGNALduinos have a different set of
        possible commands. Please refer to the README of the firmware of your
        SIGNALduino to interpret the response of this command. See also the raw-
        command.
        </li><br>
  </ul>

  <a name="SIGNALduinoattr"></a>
  <b>Attributes</b>
  <ul>
    <li><a href="#do_not_notify">do_not_notify</a></li>
    <li><a href="#attrdummy">dummy</a></li>
    <li><a href="#showtime">showtime</a></li>
    <li><a href="#model">model</a> (SIGNALduino,CUN,CUR)</li>
  </ul>
  <br>
</ul>

=end html
=cut
