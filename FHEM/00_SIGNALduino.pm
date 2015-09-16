##############################################
# $Id: 00_SIGNALduino.pm  72402 2015-09-15
# The file is taken from the FHEMduino project and modified in serval the processing of incomming messages
# see http://www.fhemwiki.de/wiki/<tbd>
# It was modified also to provide support for raw message handling which it's send from the SIGNALduino
# The purpos is to use it as addition to the SIGNALduino which runs on an arduno nano or arduino uno.
# It routes Messages serval Modules which are already integrated in FHEM. But there are also modules which comes with it.
# N. Butzek, S. Butzek, 2014-2015 
# 



package main;

use strict;
use warnings;
use Time::HiRes qw(gettimeofday);
use Data::Dumper qw(Dumper);

use POSIX qw( floor);
#use Math::Round qw();

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

my $debug=0;

my %gets = (    # Name, Data to send to the SIGNALduino, Regexp for the answer
  "version"  => ["V", '^V\s.*'],
  "freeram"  => ["R", '^[0-9]+'],
  "raw"      => ["", '.*'],
#  "uptime"   => ["t", '^[0-9A-F]{8}[\r\n]*$' ],
  "cmds"     => ["?", '.*Use one of[ 0-9A-Za-z]+[\r\n]*$' ],

#  "ITParms"  => ["ip",'.*' ],
#  "FAParms"  => ["fp", '.*' ],
#  "TCParms"  => ["dp", '.*' ],
#  "HXParms"  => ["hp", '.*' ]
);


my %sets = (
  "raw"       => "",
  "flash"     => "",
  "reset"     => "",
  #"disablereceiver"     => "",
);

## Supported Clients per default
my $clientsSIGNALduino = ":IT:"
						."CUL_TCM97001:"
						."SIGNALduino_RSL:"
						."OREGON:"
						."CUL_TX:"
						."SIGNALduino_AS:"
						."SIGNALduino_un:"
						."Cresta:"
						."SIGNALduino_ID7:"
						; 

## default regex match List for dispatching message to logical modules, can be updated during runtime because it is referenced
my %matchListSIGNALduino = (
     "1:IT"            			=> "^i......",	  			  # Intertechno Format
     "2:CUL_TCM97001"      		=> "^s[A-Fa-f0-9]+",			  # Any hex string		beginning with s
	 "3:SIGNALduino_RSL"		=> "^rA-Fa-f0-9]+",				  # Any hex string		beginning with r
     "5:CUL_TX"               	=> "^TX..........",         	  # Need TX to avoid FHTTK
	 "6:SIGNALduino_AS"       	=> "AS[A-Fa-f0-9]{7,8}", 		  # Arduino based Sensors, should not be default
#    "2:SIGNALduino_Env"      	=> "W[0-9]+[a-f0-9]+\$",	# WNNHHHHHHH N=Number H=Hex
#    "3:SIGNALduino_PT2262"   	=> "IR.*\$",
#    "4:SIGNALduino_HX"       	=> "H...\$",
     "4:OREGON"            		=> "^(3[8-9A-F]|[4-6][0-9A-F]|7[0-8]).*",		
#    "7:SIGNALduino_ARC"     	=> "AR.*\$", #ARC protocol switches like IT selflearn
	 "8:SIGNALduino_un"			=> "u.*",
	 "9:Cresta"					=> "^[5][0|8]75[A-F0-9]+",
	 "10:SIGNALduino_ID7"		=> "^u7[A-F0-9]+",                       
);

		#protoID[0]=(s_sigid){-4,-8,-18,500,0,twostate}; // Logi
		#protoID[1]=(s_sigid){-4,-8,-18,500,0,twostate}; // TCM 97001
		#protoID[2]=(s_sigid){-1,-2,-18,500,0,twostate}; // AS
		#protoID[3]=(s_sigid){-1,3,-30,pattern[clock][0],0,tristate}; // IT old

my %ProtocolListSIGNALduino  = (
    "0"    => 
        {
            name			=> 'pulsepausetype1',		# Logilink, NC, WS, TCM97001 etc.
			id          	=> '0',
			one				=> [1,-8],
			zero			=> [1,-4],
			sync			=> [1,-18],		
			clockabs   		=> '500',		# not used now
			format     		=> 'twostate',  # not used now
			preamble		=> 's',			# prepend to converted message	 	
			postamble		=> '00',		# Append to converted message	 	
			clientmodule    => 'CUL_TCM97001',   # not used now
			modulematch     => '^s[A-Fa-f0-9]+', # not used now
			length_min      => '24',
			length_max      => '40',
        },
    "1"    => 
        {
            name			=> 'ConradRSL',			# 
			id          	=> '1',
			one				=> [2,-1],
			zero			=> [1,-2],
			sync			=> [1,-11],		
			clockabs   		=> '560',				# not used now
			format     		=> 'twostate',  		# not used now
			preamble		=> 'r',					# prepend to converted message	 	
			postamble		=> '',					# Append to converted message	 	
			clientmodule    => 'SIGNALduino_RSL',   # not used now
			modulematch     => '^r[A-Fa-f0-9]+', 	# not used now
        },

    "2"    => 
        {
            name			=> 'AS',		# Self build arduino sensor
			id          	=> '2',
			one				=> [1,-4],
			zero			=> [1,-2],
			#float			=> [-1,3],		# not full supported now later use
			sync			=> [1,-20],
			clockabs     	=> '405',		# not used now
			format 			=> 'twostate',	
			preamble		=> 'AS',		# prepend to converted message		
			clientmodule    => 'SIGNALduino_AS',   # not used now
			modulematch     => '^AS.*\$', # not used now
			length_min      => '32',
			length_max      => '34',		# Don't know maximal lenth of a valid message
	
        },
    "3"    => 
        {
            name			=> 'itv1',	
			id          	=> '3',
			one				=> [3,-1],
			zero			=> [1,-3],
			#float			=> [-1,3],		# not full supported now later use
			sync			=> [1,-31],
			clockabs     	=> -1,	# -1=auto	
			format 			=> 'twostate',	# not used now
			preamble		=> 'i',			
			clientmodule    => 'IT',   # not used now
			modulematch     => '^i......', # not used now
			length_min      => '24',
			#length_max      => '800',		# Don't know maximal lenth of a valid message

			},
    "4"    => 
        {
            name			=> 'itv3',	
			id          	=> '4',
			one				=> [3,-1],
			zero			=> [1,-3],
			#float			=> [-1,3],		# not full supported now, for later use
			sync			=> [1,-30],
			clockabs     	=> -1,			# -1 = auto
			format 			=> 'tristate',	# tristate can't be migrated from bin into hex!
			preamble		=> 'i',			# Append to converted message	
			clientmodule    => 'IT',   		# not used now
			modulematch     => '^i......',  # not used now
			length_min      => '68',
			#length_max      => '76',		# Don't know maximal lenth of a valid message


		},
    "5"    => 			## Similar protocol as intertechno, but without sync
        {
            name			=> 'unitec',	
			id          	=> '5',
			one				=> [3,-1],
			zero			=> [1,-3],
			#float			=> [-1,3],		# not full supported now, for later use
			#sync			=> [0,0],		# This special device has no sync
			clockabs     	=> -1,			# -1 = auto
			format 			=> 'twostate',	# tristate can't be migrated from bin into hex!
			preamble		=> 'i',			# Append to converted message	
			clientmodule    => 'IT',   		# not used now
			modulematch     => '^i......',  # not used now
			length_min      => '24',

		},    
	
	"6"    => 			## Eurochron Protocol
        {
            name			=> 'eurochron',	
			id          	=> '6',
			one				=> [1,-9],
			zero			=> [1,-4],
			#float			=> [-1,3],		# not full supported now, for later use
			sync			=> [1,-36],		# This special device has no sync
			clockabs     	=> 212,			# -1 = auto
			format 			=> 'twostate',	# tristate can't be migrated from bin into hex!
			preamble		=> 'u',			# Append to converted message	
			clientmodule    => 'undef',   	# not used now
			modulematch     => '^u......',  # not used now
			length_min      => '24',

		},
	"7"    => 			## unkown Protocol
        {
            name			=> 'unknown1 may TX70DHT',	
			id          	=> '7',
			one				=> [1,-4],
			zero			=> [1,-2],
			#float			=> [-1,3],		# not full supported now, for later use
			sync			=> [1,-8],		# 
			clockabs     	=> 484,			# -1 = auto
			format 			=> 'twostate',	# tristate can't be migrated from bin into hex!
			preamble		=> 'u7',		# prepend to converted message	
			clientmodule    => 'undef',   	# not used now
			modulematch     => '^u7......', # not used now
			length_min      => '30',
			length_max      => '40',

		}, 
	"8"    => 			## TX3 (ITTX) Protocol
        {
            name			=> 'TX3 Protocol',	
			id          	=> '8',
			one				=> [1,-2],
			zero			=> [2,-2],
			#float			=> [-1,3],		# not full supported now, for later use
			#sync			=> [1,-8],		# 
			clockabs     	=> 470,			# -1 = auto undef=noclock
			format 			=> 'pwm',	    # tristate can't be migrated from bin into hex!
			preamble		=> 'TX',		# prepend to converted message	
			clientmodule    => 'ittx',   	# not used now
			modulematch     => '^TX......', # not used now
			length_min      => '44',
			length_max      => '45',
			remove_zero     => 1,           # Removes leading zeros from output

		}, 	
	"9"    => 			## Funk Wetterstation CTW600
			{
            name			=> 'CTW 600',	
			id          	=> '9',
			one				=> [3,-2],
			zero			=> [1,-2],
			#float			=> [-1,3],		# not full supported now, for later use
			#sync			=> [1,-8],		# 
			clockabs     	=> 480,			# -1 = auto undef=noclock
			format 			=> 'pwm',	    # tristate can't be migrated from bin into hex!
			preamble		=> 'u9',		# prepend to converted message	
			clientmodule    => 'undef',   	# not used now
			modulematch     => '^u9......',  # not used now
			length_min      => '70',
			length_max      => '120',

		}, 	
	"10"    => 			## Oregon Scientific 2
			{
            name			=> 'OSV2',	
			id          	=> '10',
			#one				=> [3,-2],
			#zero			=> [1,-2],
			#float			=> [-1,3],		# not full supported now, for later use
			#sync			=> [1,-8],		# 
			#clockabs     	=> 480,			# -1 = auto undef=noclock
			clockrange     	=> [390,520],			# min , max
			format 			=> 'manchester',	    # tristate can't be migrated from bin into hex!
			#preamble		=> '',		# prepend to converted message	
			#clientmodule    => '41_OREGON',   	# not used now
			#modulematch     => '',  # not used now
			length_min      => '37',
			length_max      => '55',
			method          => \&SIGNALduino_OSV2 # Call to process this message


		}, 	
	"11"    => 			## Arduino Sensor
			{
            name			=> 'AS',	
			id          	=> '11',
			#one				=> [3,-2],
			#zero			=> [1,-2],
			#float			=> [-1,3],		# not full supported now, for later use
			#sync			=> [1,-8],		# 
			#clockabs     	=> 500,			# -1 = auto undef=noclock
			clockrange     	=> [380,425],			# min , max
			format 			=> 'manchester',	    # tristate can't be migrated from bin into hex!
			#preamble		=> '',		# prepend to converted message	
			#clientmodule    => '14_SIGNALduino_AS',   	# not used now
			#modulematch     => '',  # not used now
			length_min      => '13',
			length_max      => '14',
			method          => \&SIGNALduino_AS # Call to process this message

		}, 
	"12"    => 			## Cresta
			{
            name			=> 'Cresta TX',	
			id          	=> '12',
			#one			=> [3,-2],
			#zero			=> [1,-2],
			#float			=> [-1,3],				# not full supported now, for later use
			#sync			=> [1,-8],				# 
			clockrange     	=> [420,450],			# min , max
			format 			=> 'manchester',	    # tristate can't be migrated from bin into hex!
			#preamble		=> '',					# prepend to converted message	
			#clientmodule    => '14_SIGNALduino_AS',   	# not used now
			#modulematch     => '',  # not used now
			length_min      => '20',
			length_max      => '50',
			method          => \&SIGNALduino_Cresta	# Call to process this message
		}, 			
	"13"    => 			## RF20
			{
            name			=> 'RF20',	
			id          	=> '13',
			one				=> [1,-2],
			zero			=> [1,-4],
			#float			=> [-1,3],				# not full supported now, for later use
			#sync			=> [11,-1],				# currently we have no support for sync check for MU messages
			clockabs		=> 740,
			format 			=> 'twostate',	  		
			preamble		=> 'u13',				# prepend to converted message	
			#clientmodule    => '',   				# not used now
			#modulematch     => '',  				# not used now
			length_min      => '20',
			length_max      => '40',
			#method          => \&SIGNALduino_Cresta	# Call to process this message
		}, 		
	"14"    => 			## Heidemann HX
			{
            name			=> 'Heidemann HX',	
			id          	=> '14',
			one				=> [1,-2],
			zero			=> [1,-1],
			#float			=> [-1,3],				# not full supported now, for later use
			sync			=> [1,-14],				# 
			clockabs		=> 350,
			format 			=> 'twostate',	  		
			preamble		=> 'u14',				# prepend to converted message	
			#clientmodule    => '',   				# not used now
			#modulematch     => '',  				# not used now
			length_min      => '10',
			length_max      => '20',
			#method          => \&SIGNALduino_Cresta	# Call to process this message
		}, 			
	"15"    => 			## TCM234759
			{
            name			=> 'TCM Bell',	
			id          	=> '15',
			one				=> [1,-1],
			zero			=> [1,-2],
			#float			=> [-1,3],				# not full supported now, for later use
			sync			=> [1,-45],				# 
			clockabs		=> 700,
			format 			=> 'twostate',	  		
			preamble		=> 'u14',				# prepend to converted message	
			#clientmodule    => '',   				# not used now
			#modulematch     => '',  				# not used now
			length_min      => '10',
			length_max      => '20',
			#method          => \&SIGNALduino_Cresta	# Call to process this message
		}, 			
);




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
  $hash->{AttrList}			= 
                       "Clients MatchList do_not_notify:1,0 dummy:1,0"
					  ." hexFile"
                      ." initCommands"
                      ." flashCommand"
  					  ." hardware:nano328,uno,promini328"
					  ." debug:0,1"
                      ." $readingFnAttributes";

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

  
  if (!exists &round)
  {
      Log3 $name, 1, "$name Signalduino can't be activated (sub round not found). Please update Fhem via update command";
	  return undef;
  }
  

  my $dev = $a[2];
  #Debug "dev: $dev" if ($debug);
  #my $hardware=AttrVal($name,"hardware","nano328");
  #Debug "hardware: $hardware" if ($debug);
 
  if($dev eq "none") {
    Log3 $name, 1, "$name device is none, commands will be echoed only";
    $attr{$name}{dummy} = 1;
    #return undef;
  }
  

  $dev .= "\@57600" if( $dev ne "none" && $dev !~ m/\@/ );
		
  
  $hash->{CMDS} = "";
  $hash->{Clients} = $clientsSIGNALduino;
  $hash->{MatchList} = \%matchListSIGNALduino;
 

  
  #if( !defined( $attr{$name}{hardware} ) ) {
  #  $attr{$name}{hardware} = "nano328";
  #}


  if( !defined( $attr{$name}{flashCommand} ) ) {
#    $attr{$name}{flashCommand} = "avrdude -p atmega328P -c arduino -P [PORT] -D -U flash:w:[HEXFILE] 2>[LOGFILE]"
    $attr{$name}{flashCommand} = "avrdude -c arduino -b 57600 -P [PORT] -p atmega328p -vv -U flash:w:[HEXFILE] 2>[LOGFILE]"
  }

  
  $hash->{DeviceName} = $dev;
  if($dev eq "none") {
  	return undef;
  }
  my $ret = DevIo_OpenDev($hash, 0, "SIGNALduino_DoInit");
  
  ## 
  $hash->{Interval} = "30";
  InternalTimer(gettimeofday()+2, "SIGNALduino_GetUpdate", $hash, 0);
  
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
  RemoveInternalTimer($hash);    
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
  

  if($cmd eq "raw") {
    Log3 $name, 4, "set $name $cmd $arg";
    SIGNALduino_SimpleWrite($hash, $arg);
  } elsif( $cmd eq "flash" ) {
    my @args = split(' ', $arg);
    my $log = "";
    my $hexFile = "";
    my @deviceName = split('@', $hash->{DeviceName});
    my $port = $deviceName[0];
	my $hardware=AttrVal($name,"hardware","nano328");

    my $defaultHexFile = "./FHEM/firmware/$hash->{TYPE}_$hardware.hex";
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
	    CUL_SimpleWrite($hash, $arg);
		#return "Unknown argument $cmd, choose one of ".$hash->{CMDS};
  }

  return undef;
}

#####################################
sub
SIGNALduino_Get($@)
{
  my ($hash, @a) = @_;
  my $type = $hash->{TYPE};
  my $name = $a[0];

  Log3 $name, 5, "\"get $type\" needs at least one parameter" if(@a < 2);
  return "\"get $type\" needs at least one parameter" if(@a < 2);
  if(!defined($gets{$a[1]})) {
    my @cList = map { $_ =~ m/^(file|raw)$/ ? $_ : "$_:noArg" } sort keys %gets;
    return "Unknown argument $a[1], choose one of " . join(" ", @cList);
  }

  my $arg = ($a[2] ? $a[2] : "");
  my ($msg, $err);

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

  #$hash->{READINGS}{$a[1]}{VAL} = $msg;
  #$hash->{READINGS}{$a[1]}{TIME} = TimeNow();
  readingsSingleUpdate($hash, $a[1], $msg, 0);

  
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

	my ($ver, $try) = ("", 0);
	#Dirty hack to allow initialisation of DirectIO Device for some debugging and tesing
  	Log3 $name, 1, $hash->{DEF};
 
  	if ((!$hash->{DEF} =~ m/\@DirectIO/) and (!$hash->{DEF} =~ m/none/) )
	{
		SIGNALduino_Clear($hash);
		

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
	
		#$debug = AttrVal($name, "verbose", 3) == 5;
		#Log3 $name, 3, "$name: setting debug to: " . $debug;

		
		# Cmd-String feststellen

		my $cmds = SIGNALduino_Get($hash, $name, "cmds", 0);
		$cmds =~ s/$name cmds =>//g;
		$cmds =~ s/ //g;
		$hash->{CMDS} = $cmds;
		Log3 $name, 3, "$name: Possible commands: " . $hash->{CMDS};
		readingsSingleUpdate($hash, "state", "Programming", 1);
		
		# Program the Filterlist on the arduino, based on the protocolList
		for my $key ( keys %ProtocolListSIGNALduino ) {
			my $command = "FA;".$ProtocolListSIGNALduino{$key}{id}.";".$ProtocolListSIGNALduino{$key}{sync}[1].";".$ProtocolListSIGNALduino{$key}{clockabs};
			#my $command = $ProtocolListSIGNALduino{$key}{id}.";".$ProtocolListSIGNALduino{$key}{sync}[1].";".$ProtocolListSIGNALduino{$key}{clockabs};
			my $replay;
			Debug "$name: $command" if ($debug);

			SIGNALduino_SimpleWrite($hash, $command);
			($err, $replay) = SIGNALduino_ReadAnswer($hash, "Update Filter ".$ProtocolListSIGNALduino{$key}{id}, 0, undef);
			Debug "$name: answert $replay" if ($debug);

		}
	}
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
    if($mSIGNALduinodata =~ m/\r\n$/ || $anydata || $mSIGNALduinodata =~ m/\n\n$/ ) {
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
  Log3 $name, 5, "SIGNALduino/RAW READ: $SIGNALduinodata/$buf"; 
  $SIGNALduinodata .= $buf;

  while($SIGNALduinodata =~ m/\n/) {
    my $rmsg;
    ($rmsg,$SIGNALduinodata) = split("\n", $SIGNALduinodata, 2);
    $rmsg =~ s/\r//;
    Log3 $name, 4, "SIGNALduino/msg READ: $rmsg"; 

    SIGNALduino_Parse($hash, $hash, $name, $rmsg) if($rmsg);
  }
  $hash->{PARTIAL} = $SIGNALduinodata;
}



sub SIGNALduino_GetUpdate($){
	my ($hash) = @_;
	my $name = $hash->{NAME};
	
	Log3 $name, 4, "$name: GetUpdate called ...";
	SIGNALduino_Get($hash,$name, "freeram");	
	
	InternalTimer(gettimeofday()+$hash->{Interval}, "SIGNALduino_GetUpdate", $hash, 1);
}


### Helper Subs >>>

sub SIGNALduino_splitMsg
{
  my $txt = shift;
  my $delim = shift;
  my @msg_parts = split(/$delim/,$txt);
  
  return @msg_parts;
}
# $value  - $set <= $tolerance
sub SIGNALduino_inTol($$$)
{
	#Debug "sduino abs \($_[0] - $_[1]\) <= $_[2] ";
	return (abs($_[0]-$_[1])<=$_[2]);
}


 # - - - - - - - - - - - -
 #=item SIGNALduino_PatternExists()
 #This functons, needs reference to $hash, @array of values to search and %patternList where to find the matches.
# 
# Will return -1 if pattern is not found or a string, containing the indexes which are in tolerance and have the smallest gap to what we searched
# =cut

sub SIGNALduino_PatternExists
{
	my ($hash,$search,$patternList) = @_;
	#my %patternList=$arg3;
	#Debug "plist: ".Dumper($patternList) if($debug); 
	#Debug "searchlist: ".Dumper($search) if($debug);

	my $searchpattern;
	my $valid=1;  
	my $pstr="";
	
	foreach $searchpattern (@{$search}) # z.B. [1, -4] 
	{
		#my $patt_id;
		# Calculate tolernace for search
		#my $tol=abs(abs($searchpattern)>=2 ?$searchpattern*0.3:$searchpattern*1.5);
		my $tol=abs(abs($searchpattern)>3 ? abs($searchpattern)>16 ? $searchpattern*0.15 : abs($searchpattern)>0.3:1);  #tol is minimum 1 or higer, depending on our searched pulselengh
		
		my %pattern_gap ; #= {};
		# Find and store the gap of every pattern, which is in tolerance
		%pattern_gap = map { $_ => abs($patternList->{$_}-$searchpattern) } grep { abs($patternList->{$_}-$searchpattern) <= $tol} (keys %$patternList);
		if (scalar keys %pattern_gap > 0) 
		{
			Debug "index => gap in tol (+- $tol) of pulse ($searchpattern) : ".Dumper(\%pattern_gap) if($debug);
			# Extract fist pattern, which is nearst to our searched value
			my $closestidx = (sort {$pattern_gap{$a} <=> $pattern_gap{$b}} keys %pattern_gap)[0];

			$pstr="$pstr$closestidx";
			$valid=1;
			Debug "closest pattern has index: $closestidx" if($debug);
		} else {
			# search is not found, return
			$valid=0;
			last;	
		}
		#return ($valid ? $pstr : -1);  # return $pstr if $valid or -1

	
		
		#foreach $patt_id (keys %$patternList) {
			#Debug "$patt_id. chk ->intol $patternList->{$patt_id} $searchpattern $tol"; 
			#$valid =  SIGNALduino_inTol($patternList->{$patt_id}, $searchpattern, $tol);
			#if ( $valid) #one pulse found in tolerance, search next one
			#{
			#	$pstr="$pstr$patt_id";
			#	# provide this index for further lookup table -> {$patt_id =  $searchpattern}
			#	Debug "pulse found";
			#	last ; ## Exit foreach loop if searched pattern matches pattern in list
			#}
		#}
		#last if (!$valid);  ## Exit loop if a complete iteration has not found anything
	}
	
	return ($valid ? $pstr : -1);  # return $pstr if $valid or -1
}

#SIGNALduino_MatchSignalPattern{$hash,@array, %hash, @array, $scalar}; not used >v3.1.3
sub SIGNALduino_MatchSignalPattern($\@\%\@$){

	my ( $hash, $signalpattern,  $patternList,  $data_array, $idx) = @_;
    my $name = $hash->{NAME};
	#print Dumper($patternList);		
	#print Dumper($idx);		
	#Debug Dumper($signalpattern) if ($debug);		
	my $tol="0.2";   # Tolerance factor
	my $found=0;
	foreach ( @{$signalpattern} )
	{
			#Debug " $idx check: ".$patternList->{$data_array->[$idx]}." == ".$_;		
			Debug "$name: idx: $idx check: abs(". $patternList->{$data_array->[$idx]}." - ".$_.") > ". ceil(abs($patternList->{$data_array->[$idx]}*$tol)) if ($debug);		
			  
			#print "\n";;
			#if ($patternList->{$data_array->[$idx]} ne $_ ) 
			### Nachkommastelle von ceil!!!
			if (!defined( $patternList->{$data_array->[$idx]})){
				Debug "$name: Error index ($idx) does not exist!!" if ($debug);

				return -1;
			}
			if (abs($patternList->{$data_array->[$idx]} - $_)  > ceil(abs($patternList->{$data_array->[$idx]}*$tol)))
			{
				return -1;		## Pattern does not match, return -1 = not matched
			}
			$found=1;
			$idx++;
	}
	if ($found)
	{
		return $idx;			## Return new Index Position
	}
	
}




sub SIGNALduino_b2h {
    my $num   = shift;
    my $WIDTH = 4;
    my $index = length($num) - $WIDTH;
    my $hex = '';
    do {
        my $width = $WIDTH;
        if ($index < 0) {
            $width += $index;
            $index = 0;
        }
        my $cut_string = substr($num, $index, $width);
        $hex = sprintf('%X', oct("0b$cut_string")) . $hex;
        $index -= $WIDTH;
    } while ($index > (-1 * $WIDTH));
    return $hex;
}

sub SIGNALduino_Split_Message($$)
{
	my $rmsg = shift;
	my $name = shift;
	my %patternList;
	my $clockidx;
	my $syncidx;
	my $rawData;
	my $clockabs;
	
	my @msg_parts = SIGNALduino_splitMsg($rmsg,';');			## Split message parts by ";"
	my %ret;

	foreach (@msg_parts)
	{
		#Debug "$name: checking msg part:( $_ )" if ($debug);

		if ($_ =~ m/^MS/ or $_ =~ m/^MC/ or $_ =~ m/^MU/) 		#### Synced Message start
		{
			$ret{messagetype} = $_;
		}
		elsif ($_ =~ m/^P\d=-?\d{2,}/ or $_ =~ m/^[SL][LH]=-?\d{2,}/) 		#### Extract Pattern List from array
		{
		   $_ =~ s/^P+//;  
		   $_ =~ s/^P\d//;  
		   my @pattern = split(/=/,$_);
		   
		   $patternList{$pattern[0]} = $pattern[1];
		   Debug "$name: extracted  pattern @pattern \n" if ($debug);
		}
		elsif($_ =~ m/D=\d+/ or $_ =~ m/^D=[A-F0-9]+/) 		#### Message from array

		{
			$_ =~ s/D=//;  
			$rawData = $_ ;
			Debug "$name: extracted  data $rawData\n" if ($debug);
			$ret{rawData} = $rawData;

		}
		elsif($_ =~ m/^SP=\d{1}/) 		#### Sync Pulse Index
		{
			(undef, $syncidx) = split(/=/,$_);
			Debug "$name: extracted  syncidx $syncidx\n" if ($debug);
			#return undef if (!defined($patternList{$syncidx}));
			$ret{syncidx} = $syncidx;

		}
		elsif($_ =~ m/^CP=\d{1}/) 		#### Clock Pulse Index
		{
			(undef, $clockidx) = split(/=/,$_);
			Debug "$name: extracted  clockidx $clockidx\n" if ($debug);;
			#return undef if (!defined($patternList{$clockidx}));
			$ret{clockidx} = $clockidx;
		}
		elsif($_ =~ m/^C=\d+/) 		#### Message from array
		{
			$_ =~ s/C=//;  
			$clockabs = $_ ;
			Debug "$name: extracted absolute clock $clockabs \n" if ($debug);
			$ret{clockabs} = $clockabs;
		}  else {
			Debug "$name: unknown Message part $_" if ($debug);;
		}
		#print "$_\n";
	}
	$ret{pattern} = {%patternList}; 
	return %ret;
}

sub SIGNALduino_Parse_Message($$$$@)
{
	my ($hash, $iohash, $name, $rmsg,@msg_parts) = @_;

	my $protocolid;
	my $syncidx;			# currently not used to decode message
	my $clockidx;			
	my $protocol=undef;
	my $rawData;


	#Debug "Message splitted:";
	#Debug Dumper(\@msg_parts);


	my %patternList;
	## Check for each received message part and parse it
	foreach (@msg_parts){
	   #Debug "$name: checking msg part:( $_ )" if ($debug);

	   if ($_ =~ m/^M[0-9]{1,}/) 		#### Message from known protocol list. Extract ID from data
	   {
		   #Debug "$name: Message Start found $_\n";
		   #$protocolid = $_ = s/\d+/r/;  
		   #$protocolid = $_ =~ s/[^0-9]+//g;
		   ($protocolid) = $_ =~ /([0-9]+)/; 

		   $protocol=$ProtocolListSIGNALduino{$protocolid}{name};
		   #Debug "$name: Serching Protocol ID:( $_ )" if ($debug);
		   return undef if (!$protocol);
		   Debug "$name: found $protocol with id: $protocolid Raw message: ($rmsg)\n" if ($debug);
	   }
	   elsif ($_ =~ m/^P\d=-?\d{2,}/) 		#### Extract Pattern List from array
	   {
   		   $_ =~ s/^P+//;  
		   $_ =~ s/^P\d//;  
		   my @pattern = split(/=/,$_);
		   
		   $patternList{$pattern[0]} = $pattern[1];
		   Debug "$name: extracted  pattern @pattern \n" if ($debug);
	   }
	   elsif($_ =~ m/D=\d+/) 		#### Message from array
	   {
			$_ =~ s/D=//;  
			$rawData = $_ ;
			Debug "$name: extracted  data $rawData\n" if ($debug);
	   }
	   elsif($_ =~ m/^SP=\d{1}/) 		#### Sync Pulse Index
	   {
			(undef, $syncidx) = split(/=/,$_);
			Debug "$name: extracted  syncidx $syncidx\n" if ($debug);
			return undef if (!defined($patternList{$syncidx}));

	   }
	   elsif($_ =~ m/^CP=\d{1}/) 		#### Clock Pulse Index
	   {
			(undef, $clockidx) = split(/=/,$_);
			Debug "$name: extracted  clockidx $clockidx\n" if ($debug);;
			
			return undef if (!defined($patternList{$clockidx}));
			
	   }  else {
			Debug "$name: unknown Message part $_" if ($debug);;

	   }

	   #print "$_\n";
	}

	if (defined($clockidx))
	{
		
		## Make a lookup table for our pattern index ids
		#print "List of pattern:";
		%patternList = map { $_ => floor($patternList{$_}/$patternList{$clockidx}) } keys %patternList; 
		#print Dumper(\%patternList);		
		
		#### Convert rawData in Message
		my @data_array = split( '', $rawData ); # migrate the data string to array
		my @bit_msg;							# array to store decoded signal bits
		
		## Iterate over the data_array and find zero, one, float and sync bits with the signalpattern

		if (defined($protocolid))
		{
			my $fail_cnt=0;

			for ( my $i=0;$i<@data_array;$i++)  ## Does this work also for tristate?
			{
				
				my $tmp_idx=$i;
				if ( ($tmp_idx=SIGNALduino_MatchSignalPattern($hash,@{$ProtocolListSIGNALduino{$protocolid}{zero}},%patternList,@data_array,$i)) != -1 ) {
					push(@bit_msg,0);
					Debug "$name: Pattern [@{$ProtocolListSIGNALduino{$protocolid}{zero}}] found at pos $i.  Adding 0 \n" if ($debug);
					$i=$tmp_idx-1;
				} elsif ( ($tmp_idx=SIGNALduino_MatchSignalPattern($hash,@{$ProtocolListSIGNALduino{$protocolid}{one}},%patternList,@data_array,$i)) != -1 ) {
					push(@bit_msg,1);
					Debug "$name: Pattern [@{$ProtocolListSIGNALduino{$protocolid}{one}}] found at pos $i.  Adding 1 \n" if ($debug);
					$i=$tmp_idx-1;
				} elsif ( ($tmp_idx=SIGNALduino_MatchSignalPattern($hash,@{$ProtocolListSIGNALduino{$protocolid}{sync}},%patternList,@data_array,$i)) != -1 ) {
					#push(@bit_msg,'S');		# Don't print Sync in bit_msg array
					#Debug "$name: Pattern [@{$ProtocolListSIGNALduino{$protocolid}{sync}}] found at pos $i. Skipping \n" if ($debug);
					$i=$tmp_idx-1;
				## aditional check for tristate protocols
				} elsif ( defined($ProtocolListSIGNALduino{$protocolid}{float}) && ($tmp_idx=SIGNALduino_MatchSignalPattern($hash,@{$ProtocolListSIGNALduino{$protocolid}{float}},%patternList,@data_array,$i)) != -1 ) {
					push(@bit_msg,'F');
					$i=$tmp_idx-1;
					#Debug "$name: Pattern [@{$ProtocolListSIGNALduino{$protocolid}{one}}] found at pos $i.  Adding F \n" if ($debug);
				} else {
				   # Nothing from Signal matched!
				   $fail_cnt++;
				}
				
			}
			if ($fail_cnt > 5)
			{
				Debug "$name: to many failures in pattern protocol matching... aborting" if ($debug);
				return undef;
			}

		} else {			# Handle unknown Protocol ID now

		}
		Debug "$name: decoded message raw (@bit_msg), ".@bit_msg." bits\n" if ($debug);;
		### Next step: Send RAW Message to clients. May we need to adapt some of them or modify our format to fit
		
		## Migrate Message to other format as needed, this is for adding support for existing logical modules. New modules shoul'd work with raw data instead
		if (defined($protocolid) && $ProtocolListSIGNALduino{$protocolid}{format} eq "twostate")
		{
			## Twostate Messages can be migrated into a hex string for futher processing in the logical clients
			
			#my $dmsg = join '', map { sprintf '%02x', $_ } @bit_msg;
			while (@bit_msg % 8 > 0)
			{
				push(@bit_msg,'0');
				Debug "$name: adding 0 bit to bit_msg array" if ($debug);
			}
			  
			my $dmsg = sprintf "%02x", oct "0b" . join "", @bit_msg;			## Array -> Sring -> bin -> hex
			$dmsg = "$dmsg"."$ProtocolListSIGNALduino{$protocolid}{postamble}" if (defined($ProtocolListSIGNALduino{$protocolid}{postamble}));
			$dmsg = "$ProtocolListSIGNALduino{$protocolid}{preamble}"."$dmsg" if (defined($ProtocolListSIGNALduino{$protocolid}{preamble}));
			
			Log3 $name, 5, "converted Data to ($dmsg)";
			
			## Dirty hack, to check a few things, bevore crating a logical module for complete decoding
			if ($protocolid eq 7 && $debug)
			{
			   my $id = oct ("0b".join('',@bit_msg[0..9]));
			   my $channel = oct ("0b".join('',@bit_msg[10..11]))+1;
   			   my $temp = oct ("0b".join('',@bit_msg[12..23]))/10;
			   Debug "$name: decoded protocol $protocolid: id=$id, channel=$channel, temp=$temp\n" if ($debug);
			}

			$hash->{"${name}_MSGCNT"}++;
			$hash->{"${name}_TIME"} = TimeNow();
			readingsSingleUpdate($hash, "state", $hash->{READINGS}{state}{VAL}, 0);
			$hash->{RAWMSG} = $rmsg;
			my %addvals = (RAWMSG => $dmsg);
			Dispatch($hash, $dmsg, \%addvals);  ## Dispatch to other Modules 

		} elsif (defined($protocolid) && $ProtocolListSIGNALduino{$protocolid}{format} eq "tristate")
		{
			## Let's do some stuff here to work with a tristate message
			
		}
	}
}


sub
SIGNALduino_Parse_MS($$$$%)
{
	my ($hash, $iohash, $name, $rmsg,%msg_parts) = @_;

	my $protocolid;
	my $syncidx=$msg_parts{syncidx};			
	my $clockidx=$msg_parts{clockidx};				
	my $protocol=undef;
	my $rawData=$msg_parts{rawData};
	my %patternList;
    #$patternList{$_} = $msg_parts{rawData}{$_] for keys %msg_parts{rawData};

	#$patternList = \%msg_parts{pattern};

	#Debug "Message splitted:";
	#Debug Dumper(\@msg_parts);


	
	if (defined($clockidx) and defined($syncidx))
	{
		
		## Make a lookup table for our pattern index ids
		#Debug "List of pattern:";
		my $clockabs= $msg_parts{pattern}{$msg_parts{clockidx}};
		$patternList{$_} = floor($msg_parts{pattern}{$_}/$clockabs) for keys $msg_parts{pattern};
 		#Debug Dumper(\%patternList);		

		#my $syncfact = $patternList{$syncidx}/$patternList{$clockidx};
		#$syncfact=$patternList{$syncidx};
		#Debug "SF=$syncfact";
		#### Convert rawData in Message
		my $signal_length = length($rawData);        # Length of data array

		## Iterate over the data_array and find zero, one, float and sync bits with the signalpattern
		## Find matching protocols
		my $id;
		foreach $id ( keys %ProtocolListSIGNALduino) {
			next if !(exists $ProtocolListSIGNALduino{$id}{sync});
			my $valid=1;
			#$debug=1;
			Debug "Testing against Protocol id $id -> $ProtocolListSIGNALduino{$id}{name}"  if ($debug);

			# Check Clock if is it in range
			$valid=SIGNALduino_inTol($ProtocolListSIGNALduino{$id}{clockabs},$clockabs,$clockabs*0.30) if ($ProtocolListSIGNALduino{$id}{clockabs} > 0);
			next if (!$valid) ;

			my $bit_length = ($signal_length-(scalar @{$ProtocolListSIGNALduino{$id}{sync}}))/((scalar @{$ProtocolListSIGNALduino{$id}{one}} + scalar @{$ProtocolListSIGNALduino{$id}{zero}})/2);

			#Check calculated min length
			$valid = $valid && $ProtocolListSIGNALduino{$id}{length_min} <= $bit_length if (exists $ProtocolListSIGNALduino{$id}{length_min}); 
			#Check calculated max length
			$valid = $valid && $ProtocolListSIGNALduino{$id}{length_max} >= $bit_length if (exists $ProtocolListSIGNALduino{$id}{length_max});

			next if (!$valid) ;
			Debug "expecting $bit_length bits in signal" if ($debug && $valid);

			#Debug Dumper(@{$ProtocolListSIGNALduino{$id}{sync}});
			Debug "Searching in patternList: ".Dumper(\%patternList) if($debug);

			Debug "searching sync: @{$ProtocolListSIGNALduino{$id}{sync}}[0] @{$ProtocolListSIGNALduino{$id}{sync}}[1]" if($debug); # z.B. [1, -18] 
			#$valid = $valid && SIGNALduino_inTol($patternList{$clockidx}, @{$ProtocolListSIGNALduino{$id}{sync}}[0], 3); #sync in tolerance
			#$valid = $valid && SIGNALduino_inTol($patternList{$syncidx}, @{$ProtocolListSIGNALduino{$id}{sync}}[1], 3); #sync in tolerance
			
			my $pstr;
			my %patternLookupHash=();

			$valid = $valid && ($pstr=SIGNALduino_PatternExists($hash,\@{$ProtocolListSIGNALduino{$id}{sync}},\%patternList)) >=0;
			Debug "Found matched sync with indexes: ($pstr)" if ($debug && $valid);
			$patternLookupHash{$pstr}="" if ($valid); ## Append Sync to our lookuptable

			Debug "sync not found " if (!$valid && $debug); # z.B. [1, -18] 

			next if (!$valid) ;

			#Debug "Found matched sync" if ($valid && $debug); # z.B. [1, -18] 
			#Debug "phash:".Dumper(%patternLookupHash);
			#my $pstr=SIGNALduino_PatternExists($hash,\@{$ProtocolListSIGNALduino{$id}{sync}},\%patternList);
			#$patternLookupHash{$pstr}="" if ($pstr != -1); ## Append Sync to our lookuptable
			#Debug "added $pstr " if ($debug && $valid);

			#Debug "phash:".Dumper(%patternLookupHash);

			#Debug "Found matched sync" if ($debug && $valid);

			$valid = $valid && ($pstr=SIGNALduino_PatternExists($hash,\@{$ProtocolListSIGNALduino{$id}{one}},\%patternList)) >=0;
			Debug "Found matched one with indexes: ($pstr)" if ($debug && $valid);
			$patternLookupHash{$pstr}="1" if ($valid); ## Append Sync to our lookuptable
			#Debug "added $pstr " if ($debug && $valid);
			Debug "one pattern not found" if ($debug && !$valid);


			$valid = $valid && ($pstr=SIGNALduino_PatternExists($hash,\@{$ProtocolListSIGNALduino{$id}{zero}},\%patternList)) >=0;
			Debug "Found matched zero with indexes: ($pstr)" if ($debug && $valid);
			$patternLookupHash{$pstr}="0" if ($valid); ## Append Sync to our lookuptable
			Debug "zero pattern not found" if ($debug && !$valid);

			#Debug "added $pstr " if ($debug && $valid);

			next if (!$valid) ;
			#Debug "Pattern Lookup Table".Dumper(%patternLookupHash);
			## Check somethin else

		
			#Anything seems to be valid, we can start decoding this.			

			Log3 $name, 5, "Found matched Protocol id $id -> $ProtocolListSIGNALduino{$id}{name}"  if ($valid);
			my $signal_width= @{$ProtocolListSIGNALduino{$id}{one}};
			#Debug $signal_width;
			
			
			my @bit_msg;							# array to store decoded signal bits

			#for (my $i=index($rawData,SIGNALduino_PatternExists($hash,\@{$ProtocolListSIGNALduino{$id}{sync}}))+$signal_width;$i<length($rawData);$i+=$signal_width)
			for (my $i=scalar@{$ProtocolListSIGNALduino{$id}{sync}};$i<length($rawData);$i+=$signal_width)
			{
				my $sig_str= substr($rawData,$i,$signal_width);
				#Debug $patternLookupHash{substr($rawData,$i,$signal_width)}; ## Get $signal_width number of chars from raw data string
				push(@bit_msg,$patternLookupHash{$sig_str}) if (exists $patternLookupHash{$sig_str}); ## Add the bits to our bit array
			}
			
			Debug "$name: decoded message raw (@bit_msg), ".@bit_msg." bits\n" if ($debug);;
			while (@bit_msg % 8 > 0)  ## can be reduced to 4 bits some times, beacause we need only full nibbles not full bytes
			{
				push(@bit_msg,'0');
				Debug "$name: padding 0 bit to bit_msg array" if ($debug);
			}
			#Check converted message against lengths
			$valid = $valid && $ProtocolListSIGNALduino{$id}{length_min} <= scalar @bit_msg  if (defined($ProtocolListSIGNALduino{$id}{length_min})); 
			$valid = $valid && $ProtocolListSIGNALduino{$id}{length_max} >= scalar @bit_msg  if (defined($ProtocolListSIGNALduino{$id}{length_max}));
			next if (!$valid);  ## Last chance to try next protocol if there is somethin invalid

			#my $dmsg = sprintf "%02x", oct "0b" . join "", @bit_msg;			## Array -> String -> bin -> hex
			my $dmsg = SIGNALduino_b2h(join "", @bit_msg);
			$dmsg = "$dmsg"."$ProtocolListSIGNALduino{$id}{postamble}" if (defined($ProtocolListSIGNALduino{$id}{postamble}));
			$dmsg = "$ProtocolListSIGNALduino{$id}{preamble}"."$dmsg" if (defined($ProtocolListSIGNALduino{$id}{preamble}));
			
			Log3 $name, 5, "converted Data to ($dmsg)";
			$hash->{"${name}_MSGCNT"}++;
			$hash->{"${name}_TIME"} = TimeNow();
			readingsSingleUpdate($hash, "state", $hash->{READINGS}{state}{VAL}, 0);
			$hash->{RAWMSG} = $rmsg;
			my %addvals = (RAWMSG => $dmsg);
			Dispatch($hash, $dmsg, \%addvals);  ## Dispatch to other Modules 
		
			#last if ($valid); try other protocols if we got some error

		
		}
		return 0;
		

	}
}



sub SIGNALduino_Parse_MU($$$$@)
{
	#my ($hash, $iohash, $name, $rmsg,@msg_parts) = @_;
	#my $rawData;
	#my $clockidx;
	#my %patternList;
	#my %patternListRaw;
	## Check for each received message part and parse it
	
	my ($hash, $iohash, $name, $rmsg,%msg_parts) = @_;

	my $protocolid;
	my $clockidx=$msg_parts{clockidx};				
	my $protocol=undef;
	my $rawData=$msg_parts{rawData};
	my %patternListRaw;
    Debug "$name: processing unsynced message\n" if ($debug);

	my $clockabs;  #Clock will be fetched from Protocol
	#$patternListRaw{$_} = floor($msg_parts{pattern}{$_}/$clockabs) for keys $msg_parts{pattern};
	$patternListRaw{$_} = $msg_parts{pattern}{$_} for keys $msg_parts{pattern};

	
	if (defined($clockidx))
	{
		
		## Make a lookup table for our pattern index ids
		#Debug "List of pattern:"; 		#Debug Dumper(\%patternList);		
		my $signal_length = length($rawData);        # Length of data array

		## Find matching protocols
		my $id;
		foreach $id ( keys %ProtocolListSIGNALduino) {
			next if (exists $ProtocolListSIGNALduino{$id}{sync}); ## We can skip messages with sync defined
			next if (defined($ProtocolListSIGNALduino{id}{format}) && $ProtocolListSIGNALduino{id}{format} ne "manchester");
			next if (!defined($ProtocolListSIGNALduino{$id}{clockabs}));
				
			my $valid=1;
			my $clockabs= $ProtocolListSIGNALduino{$id}{clockabs};
			my %patternList;
			
			%patternList = map { $_ => round($patternListRaw{$_}/$clockabs,1) } keys %patternListRaw; 
			my @keys = sort { $patternList{$a} <=> $patternList{$b} } keys %patternList;

			#Debug Dumper(\%patternList);	
			#Debug Dumper(@keys);	

			#$debug=1;
			
			
			Debug "Testing against Protocol id $id -> $ProtocolListSIGNALduino{$id}{name}"  if ($debug);

			
	
#			$valid=SIGNALduino_inTol($ProtocolListSIGNALduino{$id}{clockabs},$clockabs,$clockabs*0.30) if ($ProtocolListSIGNALduino{$id}{clockabs} > 0);

			next if (!$valid) ;
			
			my $bit_length = ($signal_length/((scalar @{$ProtocolListSIGNALduino{$id}{one}} + scalar @{$ProtocolListSIGNALduino{$id}{zero}})/2));
			Debug "Expect $bit_length bits in message"  if ($valid && $debug);

			#Check calculated min length
			$valid = $valid && $ProtocolListSIGNALduino{$id}{length_min} <= $bit_length if (exists $ProtocolListSIGNALduino{$id}{length_min}); 
			#Check calculated max length
			$valid = $valid && $ProtocolListSIGNALduino{$id}{length_max} >= $bit_length if (exists $ProtocolListSIGNALduino{$id}{length_max});

			next if (!$valid) ;
			Debug "expecting $bit_length bits in signal" if ($debug && $valid);

			Debug "Searching in patternList: ".Dumper(\%patternList) if($debug);
			next if (!$valid) ;

	
			my %patternLookupHash=();

			#Debug "phash:".Dumper(%patternLookupHash)
			my $pstr="";
			$valid = $valid && ($pstr=SIGNALduino_PatternExists($hash,\@{$ProtocolListSIGNALduino{$id}{one}},\%patternList)) >=0;
			Debug "Found matched one" if ($debug && $valid);
			$patternLookupHash{$pstr}="1" if ($valid); ## Append one to our lookuptable
			Debug "added $pstr " if ($debug && $valid);

			$valid = $valid && ($pstr=SIGNALduino_PatternExists($hash,\@{$ProtocolListSIGNALduino{$id}{zero}},\%patternList)) >=0;
			Debug "Found matched zero" if ($debug && $valid);
			$patternLookupHash{$pstr}="0" if ($valid); ## Append zero to our lookuptable
			Debug "added $pstr " if ($debug && $valid);

			next if (!$valid) ;
			#Debug "Pattern Lookup Table".Dumper(%patternLookupHash);
			## Check somethin else

		
			#Anything seems to be valid, we can start decoding this.			

			Log3 $name, 5, "Found matched Protocol id $id -> $ProtocolListSIGNALduino{$id}{name}"  if ($valid);
			my $signal_width= @{$ProtocolListSIGNALduino{$id}{one}};
			#Debug $signal_width;
			
			
			my @bit_msg;							# array to store decoded signal bits
			my $message_start = (index($rawData,SIGNALduino_PatternExists($hash,\@{$ProtocolListSIGNALduino{$id}{one}}),\%patternList) > index($rawData,SIGNALduino_PatternExists($hash,\@{$ProtocolListSIGNALduino{$id}{zero}}),\%patternList)) ? index($rawData,SIGNALduino_PatternExists($hash,\@{$ProtocolListSIGNALduino{$id}{one}},\%patternList)) : index($rawData,SIGNALduino_PatternExists($hash,\@{$ProtocolListSIGNALduino{$id}{zero}},\%patternList));
			#for (my $i=index($rawData,SIGNALduino_PatternExists($hash,\@{$ProtocolListSIGNALduino{$id}{sync}}))+$signal_width;$i<length($rawData);$i+=$signal_width)
			#Debug "Message starts at:".$message_start;
			for (my $i=$message_start;$i<length($rawData);$i+=$signal_width)
			{
				my $sig_str= substr($rawData,$i,$signal_width);
				#Debug $patternLookupHash{substr($rawData,$i,$signal_width)}; ## Get $signal_width number of chars from raw data string
				push(@bit_msg,$patternLookupHash{$sig_str}) if (exists $patternLookupHash{$sig_str}); ## Add the bits to our bit array
				next if !(exists $patternLookupHash{$sig_str}); ## Break if something that doesn't fit our searched pattern or we are at the end
			}
			
			Debug "$name: decoded message raw (@bit_msg), ".@bit_msg." bits\n" if ($debug);;
			while (@bit_msg % 4 > 0)
			{
				push(@bit_msg,'0');
				Debug "$name: padding 0 bit to bit_msg array" if ($debug);
			}
			#Check converted message against lengths
			$valid = $valid && $ProtocolListSIGNALduino{$id}{length_min} <= scalar @bit_msg  if (defined($ProtocolListSIGNALduino{$id}{length_min})); 
			$valid = $valid && $ProtocolListSIGNALduino{$id}{length_max} >= scalar @bit_msg  if (defined($ProtocolListSIGNALduino{$id}{length_max}));
			next if (!$valid);  ## Last chance to try next protocol if there is somethin invalid

			#my $dmsg = sprintf "%02x", oct "0b" . join "", @bit_msg;			## Array -> String -> bin -> hex
			my $dmsg = SIGNALduino_b2h(join "", @bit_msg);
			$dmsg =~ s/^0+//	 if (defined($ProtocolListSIGNALduino{$id}{remove_zero})); 
			
			$dmsg = "$dmsg"."$ProtocolListSIGNALduino{$id}{postamble}" if (defined($ProtocolListSIGNALduino{$id}{postamble}));
			$dmsg = "$ProtocolListSIGNALduino{$id}{preamble}"."$dmsg" if (defined($ProtocolListSIGNALduino{$id}{preamble}));
			
			Log3 $name, 5, "converted Data to ($dmsg)";
			$hash->{"${name}_MSGCNT"}++;
			$hash->{"${name}_TIME"} = TimeNow();
			readingsSingleUpdate($hash, "state", $hash->{READINGS}{state}{VAL}, 0);
			$hash->{RAWMSG} = $rmsg;
			my %addvals = (RAWMSG => $dmsg);
			Dispatch($hash, $dmsg, \%addvals);  ## Dispatch to other Modules 
		
			#last if ($valid); try other protocols if we got some error


		
		}
		return 0;
	}
}


sub
SIGNALduino_Parse_MC($$$$@)
{

	my ($hash, $iohash, $name, $rmsg,%msg_parts) = @_;
	my $clock=$msg_parts{clockabs};	     ## absolute clock
	my $rawData=$msg_parts{rawData};
	my $bitData;
	my $dmsg;
	
	return undef if ($clock) == 0;
	#my $protocol=undef;
	#my %patternListRaw = %msg_parts{patternList};
	
	Debug "$name: processing manchester messag len:".length($rawData) if ($debug);
	
	my $hlen = length($rawData);
	my $blen = $hlen * 4;
	$bitData= unpack("B$blen", pack("H$hlen", $rawData)); 
	Debug "$name: extracted data $bitData (bin)\n" if ($debug); ## Convert Message from hex to bits
	my $id;
	
	foreach $id ( keys %ProtocolListSIGNALduino) {

		next if (!defined($ProtocolListSIGNALduino{$id}{format}) or $ProtocolListSIGNALduino{$id}{format} ne "manchester");
		Debug "Testing against Protocol id $id -> $ProtocolListSIGNALduino{$id}{name}"  if ($debug);

		if ( $clock >$ProtocolListSIGNALduino{$id}{clockrange}[0] and $clock <$ProtocolListSIGNALduino{$id}{clockrange}[1] and length($rawData) > $ProtocolListSIGNALduino{$id}{length_min} and length($rawData) < $ProtocolListSIGNALduino{$id}{length_max} )
		{
			Debug "clock and length matched"  if ($debug);

		   	my $method = $ProtocolListSIGNALduino{$id}{method};
		    if (!exists &$method)
			{
				Log 4, "$name: Error: Unknown function=$method. Please define it in file $0";
			} else {
				my ($rcode,$res) = $method->($name,$bitData);
				if ($rcode != -1) {
					$dmsg = $res;
					Log3 $name, 5, "converted Data to ($dmsg)";
					$hash->{"${name}_MSGCNT"}++;
					$hash->{"${name}_TIME"} = TimeNow();
					readingsSingleUpdate($hash, "state", $hash->{READINGS}{state}{VAL}, 0);
					$hash->{RAWMSG} = $rmsg;
					my %addvals = (RAWMSG => $dmsg);
					Dispatch($hash, $dmsg, \%addvals);  ## Dispatch to other Modules 
				} else {
					Debug "protocol does not match return from method: ($res)"  if ($debug);

				}
			}
		}
			
	}
	return undef;    ## Exit bevor running old conversion code
	
	my $found=0;

	#Check OSV2
	# Test code: https://ideone.com/Pp80M8  https://ideone.com/63wjyx
	
	
	#Todo Migrate to protocol List, and parse data from protocol list instead of hardcoded data
	#  $ProtocolListSignalDuino{$id}{format} eq "manchester"  && $ProtocolListSignalDuino{$id}{clock} in tol $ clock,   $ProtocolListSignalDuino{$id}{minlength} $ProtocolListSignalDuino{$id}{maxlength}   how to find preamble and sync bits
	if ( $clock >390 and $clock <520 and length($rawData) > 37 and length($rawData) < 55 and index($bitData,"10011001",24) >= 24 and $bitData =~ m/^.?(10){12,16}/) #$rawData =~ m/^A{6,8}/
	{  # Valid OSV2 detected!	
		
		Debug "$name: OSV2 protocol detected \n" if ($debug);
		
		my $preamble_pos=index($bitData,"10011001",24);

		return undef if ($preamble_pos <=24);
		my $idx=0;
		my $osv2bits="";
		my $osv2hex ="";

		for ($idx=$preamble_pos;$idx<length($bitData);$idx=$idx+16)
		{
			if (length($bitData)-$idx  < 16 )
			{
			  last;
			}
			my $osv2byte = "";
			$osv2byte=NULL;
			$osv2byte=substr($bitData,$idx,16);
			#Debug "$name: byte(16bit) $idx: $osv2byte";

			my $rvosv2byte="";
			
			for (my $p=1;$p<length($osv2byte);$p=$p+2)
			{
				$rvosv2byte = substr($osv2byte,$p,1).$rvosv2byte;
			}
			$osv2hex=$osv2hex.sprintf('%02X', oct("0b$rvosv2byte")) ;
			#Debug "$name: -> reversed: $rvosv2byte\n";
			$osv2bits = $osv2bits.$rvosv2byte;
			#reverse $osv2bits;
			# Need to reverse every bit from a nibble. # Get 16 Bits, reverse, extract every second char conv to hex 
		}
		#Debug "$name: OSV2 bits $osv2bits \n" if ($debug);
		
		$osv2hex = sprintf("%02X", length($osv2hex)*4).$osv2hex;
		Debug "$name: OSV2 hex $osv2hex with length ".(length($osv2hex)/2)." bytes \n" if ($debug);
		$found=1;
		$dmsg=$osv2hex;
		
	}
	if ( $clock >380 and $clock <425 and length($rawData) > 13 and length($rawData) < 14 and $rawData =~ m/^A{2,3}/)
	{  # Valid AS detected!	
		Debug "$name: AS protocol detected \n" if ($debug);
		my $preamble_pos=index($bitData,"1100",16);
	}
	
	
	
	
}


sub
SIGNALduino_Parse($$$$@)
{
  my ($hash, $iohash, $name, $rmsg, $initstr) = @_;

	#print Dumper(\%ProtocolListSIGNALduino);

    #print "$protocol: ";
    #Log3 $name, 3, "id: $protocol=$ProtocolListSIGNALduino{$protocol}{id} ";
    	
	#M%id;P\d=.*;.*;D=.*;\003
	return undef if !($rmsg=~ m/^\002M.;.*;\003/); 			## Check if a Data Message arrived and if it's complete  (start & end control char are received)
	$rmsg=~ s/^\002(M.;.*;)\003/$1/;						# cut off start end end character from message for further processing they are not needed
	Debug "$name: incomming message: ($rmsg)\n" if ($debug);
	
	my %signal_parts=SIGNALduino_Split_Message($rmsg,$name);   ## Split message and save anything in an hash %signal_parts
	#Debug "raw data ". $signal_parts{rawData};
	
	
	my @msg_parts = SIGNALduino_splitMsg($rmsg,';');			## Split message parts by ";"
	# Message Synced type   -> M#
	if ($rmsg=~ m/^M\d+;(P\d=-?\d+;){4,7}D=\d+;CP=\d;SP=\d;/) 
	{
		Log3 $name, 3, "You are using an outdated version of signalduino code on your arduino. Please update";
		return SIGNALduino_Parse_Message($hash, $iohash, $name, $rmsg,@msg_parts);  
	}
	if ($rmsg=~ m/^MS;(P\d=-?\d+;){4,7}D=\d+;CP=\d;SP=\d;/) 
	{
		return SIGNALduino_Parse_MS($hash, $iohash, $name, $rmsg,%signal_parts);
	}

	# Message unsynced type   -> MU
  	elsif ($rmsg=~ m/^MU;(P\d=-?\d+;){4,7}D=\d+;CP=\d;/)
	{
		#return SIGNALduino_Parse_MU($hash, $iohash, $name, $rmsg,@msg_parts);
		return SIGNALduino_Parse_MU($hash, $iohash, $name, $rmsg,%signal_parts);

	}
	# Manchester encoded Data   -> MC
  	elsif ($rmsg=~ m/^MC;.*;/) 
	{
		#return SIGNALduino_Parse_MC($hash, $iohash, $name, $rmsg,@msg_parts);		
		return SIGNALduino_Parse_MC($hash, $iohash, $name, $rmsg,%signal_parts);		   
		
	}
	else {
		Debug "$name: unknown Messageformat, aborting\n" if ($debug);
		return undef;
	}
	#my $dmsg="";

	####

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
	my ($cmd,$name,$aName,$aVal) = @_;
	my $hash = $defs{$name};

		
	if( $aName eq "Clients" ) {		## Change clientList
		$hash->{Clients} = $aVal;
		$hash->{Clients} = $clientsSIGNALduino if( !$hash->{Clients}) ;				## Set defaults
		return "Setting defaults";
	} elsif( $aName eq "MatchList" ) {	## Change matchList
		my $match_list;
		if( $cmd eq "set" ) {
			$match_list = eval $aVal;
			if( $@ ) {
				Log3 $name, 2, $name .": $aVal: ". $@;
			}
		}


		if( ref($match_list) eq 'HASH' ) {
		  $hash->{MatchList} = $match_list;
		} else {
		  $hash->{MatchList} = \%matchListSIGNALduino;								## Set defaults
		  Log3 $name, 2, $name .": $aVal: not a HASH using defaults" if( $aVal );
		}
	}
	elsif ($aName eq "Verbose")
	{
		Log3 $name, 3, "$name: setting Verbose to: " . $aVal;
	}
	elsif ($aName eq "debug")
	{
		$debug = $aVal;
		Log3 $name, 3, "$name: setting debug to: " . $debug;
	}
	
  	return undef;
}



sub SIGNALduino_OSV2($$)
{
	my ($name,$bitData) = @_;
	
	if (index($bitData,"10011001",24) >= 24 and $bitData =~ m/^.?(10){12,16}/) 
	{  # Valid OSV2 detected!	
		
		Debug "$name: OSV2 protocol detected \n" if ($debug);
		my $preamble_pos=index($bitData,"10011001",24);

		return undef if ($preamble_pos <=24);
		my $idx=0;
		my $osv2bits="";
		my $osv2hex ="";
		for ($idx=$preamble_pos;$idx<length($bitData);$idx=$idx+16)
		{
			if (length($bitData)-$idx  < 16 )
			{
			  last;
			}
			my $osv2byte = "";
			$osv2byte=NULL;
			$osv2byte=substr($bitData,$idx,16);

			my $rvosv2byte="";
			
			for (my $p=1;$p<length($osv2byte);$p=$p+2)
			{
				$rvosv2byte = substr($osv2byte,$p,1).$rvosv2byte;
			}
			$osv2hex=$osv2hex.sprintf('%02X', oct("0b$rvosv2byte")) ;
			$osv2bits = $osv2bits.$rvosv2byte;
		}
		$osv2hex = sprintf("%02X", length($osv2hex)*4).$osv2hex;
		Log3 $name, 5, "$name: OSV2 protocol converted to hex: ($osv2hex) with length (".(length($osv2hex)*4).") bytes \n";
		#$found=1;
		#$dmsg=$osv2hex;
		return (1,$osv2hex);
	} 
	return (-1,undef);
}
sub	SIGNALduino_AS()
{
	my ($name,$bitData) = @_;

	if(index($bitData,"1100",16) >= 0) # $rawData =~ m/^A{2,3}/)
	{  # Valid AS detected!	
		my $message_start = index($bitData,"1100",16);
		Debug "$name: AS protocol detected \n" if ($debug);
		my $msgbits =substr($bitData,$message_start);
		
		my $ashex=sprintf('%02X', oct("0b$msgbits"));
		Log3 $name, 5, "$name: AS protocol converted to hex: ($ashex) with length (".(length($ashex)*4).") bytes \n";

		return (1,$bitData);
	}
	return (-1,undef);
}

sub	SIGNALduino_Cresta()
{
	my ($name,$bitData) = @_;
    Debug "$name: search in $bitData \n" if ($debug);
	if (index($bitData,"0101110") >= 0 )   # 0x75 but in reverse order
	{
		Debug "$name: Cresta protocol detected \n" if ($debug);

		my $message_start=index($bitData,"10101110");
		my $crestahex;  #=substr($bitData,$message_start);
		my $idx;
		
		for ($idx=$message_start;$idx<length($bitData);$idx=$idx+9)
		{
			my $byte = "";

			$byte= substr($bitData,$idx,8); ## Ignore every 9th bit
			Debug "$name: byte in order $byte " if ($debug);
			$byte = scalar reverse $byte;
			Debug "$name: byte reversed $byte , as hex: ".sprintf('%X', oct("0b$byte"))."\n" if ($debug);

			$crestahex=$crestahex.sprintf('%02X', oct("0b$byte"));
		}
		$crestahex = sprintf("%02X", length($crestahex)*4).$crestahex; # Number of bits
		Log3 $name, 5, "$name: Cresta protocol converted to hex: ($crestahex) with length (".(length($crestahex)*4).") bits \n";

		return  (1,$crestahex); ## Return only the original bits, include length
	}
	return (-1,undef);
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
  href="https://github.com/RFD-FHEM/SIGNALduino">link</a>) they are capable
  to receive and send different wireless protocols.
  <br><br>
  
  The following protocols are available:
  <br><br>
  
  
  Wireless switches  <br>
  IT  switches --> uses IT.pm<br>
  <br><br>
  
  Temperatur / humidity sensors suppored by 14_CUL_TCM97001 <br>
  PEARL NC7159, LogiLink WS0002,GT-WT-02,AURIOL,TCM97001, TCM27,GT-WT-02..  --> 14_CUL_TCM97001.pm <br>
  <br><br>

  It is possible to attach more than one device in order to get better
  reception, fhem will filter out duplicate messages.<br><br>

  Note: this module require the Device::SerialPort or Win32::SerialPort
  module. It can currently only attatched via USB.

  </td><td>
  <img src="ccc.jpg"/>
  </td></tr>
  </table>

  <a name="SIGNALduinodefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; SIGNALduino &lt;device&gt; </code> <br>
    <br>
    USB-connected devices (SIGNALduino):<br><ul>
      &lt;device&gt; specifies the serial port to communicate with the SIGNALduino.
	  The name of the serial-device depends on your distribution, under
      linux the cdc_acm kernel module is responsible, and usually a
      /dev/ttyACM0 or /dev/ttyUSB0 device will be created. If your distribution does not have a
      cdc_acm module, you can force usbserial to handle the SIGNALduino by the
      following command:<ul>modprobe usbserial vendor=0x03eb
      product=0x204b</ul>In this case the device is most probably
      /dev/ttyUSB0.<br><br>

      You can also specify a baudrate if the device name contains the @
      character, e.g.: /dev/ttyACM0@57600<br><br>This is also the default baudrate
	
	  It is recommended to specify the device via a name which does not change:
	  e.g. via by-id devicename: /dev/serial/by-id/usb-1a86_USB2.0-Serial-if00-port0@57600
	  
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
        href="http://<tbd>/commandref.html">this</a> document
        for details on SIGNALduino commands.
    </li><br>

    <li>flash [hexFile]<br>
    The SIGNALduino needs the right firmware to be able to receive and deliver the sensor data to fhem. In addition to the way using the
    arduino IDE to flash the firmware into the SIGNALduino this provides a way to flash it directly from FHEM.

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
            is the port the Signalduino is connectd to (e.g. /dev/ttyUSB0) and will be used from the defenition</li>
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

  </ul>
  <a name="SIGNALduinoget"></a>
  <b>Get</b>
  <ul>
    <li>version<br>
        return the SIGNALduino firmware version
        </li><br>
    <li>raw<br>
        Issue a SIGNALduino firmware command, and wait for one line of data returned by
        the SIGNALduino. See the SIGNALduino firmware code  for details on SIGNALduino
        commands.
        </li><br>
    <li>cmds<br>
        Depending on the firmware installed, SIGNALduinos have a different set of
        possible commands. Please refer to the sourcecode of the firmware of your
        SIGNALduino to interpret the response of this command. See also the raw-
        command.
        </li><br>
  </ul>

  <a name="SIGNALduinoattr"></a>
  <b>Attributes</b>
  <ul>
    <li>Clients<br>
      The received data gets distributed to a client (e.g. LaCrosse, EMT7110, ...) that handles the data.
      This attribute tells, which are the clients, that handle the data. If you add a new module to FHEM, that shall handle
      data distributed by the JeeLink module, you must add it to the Clients attribute.</li>

    <li>MatchList<br>
      can be set to a perl expression that returns a hash that is used as the MatchList<br>
      <code>attr myJeeLink MatchList {'5:AliRF' => '^\\S+\\s+5 '}</code></li>
    <li>hexfile<br>
      Full path to a hex filename of the arduino sketch e.g. /opt/fhem/RF_Receiver_nano328.hex
	</li>

	  
	<li><a href="#do_not_notify">do_not_notify</a></li>
    <li><a href="#attrdummy">dummy</a></li>

  </ul>
  <br>
</ul>

=end html
=cut