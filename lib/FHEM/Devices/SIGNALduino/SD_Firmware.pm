package FHEM::Devices::SIGNALduino::SD_Firmware;

use strict;
use warnings;
use Carp;
use Symbol 'gensym';
use IPC::Open3;

our $VERSION = "0.01";

############################# package main
sub SIGNALduino_avrdude {
  my $name = shift;
  my $hash = $main::defs{$name};

  if (defined($hash->{helper}{stty_pid}))
  {
    waitpid( $hash->{helper}{stty_pid}, 0 );
    delete ( $hash->{helper}{stty_pid});
  }

  main::readingsSingleUpdate($hash,'state','FIRMWARE UPDATE running',1);
  $hash->{helper}{avrdudelogs} .= "$name closed\n";
  my $logFile = main::AttrVal('global', 'logdir', './log/') . "$hash->{TYPE}-Flash.log";

  if (-e $logFile) {
    unlink $logFile;
  }

  $hash->{helper}{avrdudecmd} =~ s/\Q[LOGFILE]\E/$logFile/g;
  local $SIG{CHLD} = 'DEFAULT';
  delete($hash->{FLASH_RESULT}) if (exists($hash->{FLASH_RESULT}));

  qx($hash->{helper}{avrdudecmd});

  if ($? != 0 )
  {
    main::readingsSingleUpdate($hash,'state','FIRMWARE UPDATE with error',1);    # processed in tests
    $hash->{logMethod}->($name ,3, "$name: avrdude, ERROR: avrdude exited with error $?");
    if (defined $main::FW_wname)
    {
      main::FW_directNotify("FILTER=$name", "FHEMWEB:$main::FW_wname", "FW_okDialog('ERROR: avrdude exited with error, for details see last flashlog.')", '');
    }
    $hash->{FLASH_RESULT}='ERROR: avrdude exited with error';              # processed in tests
  } else {
    $hash->{logMethod}->($name ,3, "$name: avrdude, Firmware update was successfull");
    main::readingsSingleUpdate($hash,'state','FIRMWARE UPDATE successfull',1);   # processed in tests
  }

  local $/=undef;
  if (-e $logFile) {
    open my $file, '<', $logFile;
    $hash->{helper}{avrdudelogs} .= "--- AVRDUDE ---------------------------------------------------------------------------------\n";
    $hash->{helper}{avrdudelogs} .= <$file>;
    $hash->{helper}{avrdudelogs} .= "--- AVRDUDE ---------------------------------------------------------------------------------\n\n";
    close $file;
  } else {
    $hash->{helper}{avrdudelogs} .= "WARNING: avrdude created no log file\n\n";
    main::readingsSingleUpdate($hash,'state','FIRMWARE UPDATE with error',1);
    $hash->{FLASH_RESULT}= 'WARNING: avrdude created no log file';         # processed in tests
  }

  main::DevIo_OpenDev($hash, 0, \&main::SIGNALduino_DoInit, \&main::SIGNALduino_Connect);
  $hash->{helper}{avrdudelogs} .= "$name reopen started\n";
  return $hash->{FLASH_RESULT};
}

############################# package main
sub SIGNALduino_PrepareFlash {
  my ($hash,$hexFile) = @_;

  ref($hash) eq 'HASH' or carp "SIGNALduino_PrepareFlash: parameter 1 is not a hash reference";

  my $name=$hash->{NAME};
  my $hardware=main::AttrVal($name,'hardware','');
  my ($port,undef) = split('@', $hash->{DeviceName});
  my $baudrate= 57600;
  my $log = '';
  my $avrdudefound=0;
  my $tool_name = 'avrdude';
  my $path_separator = ':';
  if ($^O eq 'MSWin32') {
    $tool_name .= '.exe';
    $path_separator = ';';
  }
  for my $path ( split /$path_separator/, $ENV{PATH} ) {
    if ( -f "$path/$tool_name" && -x _ ) {
      $avrdudefound=1;
      last;
    }
  }
  $hash->{logMethod}->($name, 5, "$name: PrepareFlash, avrdude found = $avrdudefound");
  return 'avrdude is not installed. Please provide avrdude tool example: sudo apt-get install avrdude' if($avrdudefound == 0);

  $log .= "flashing Arduino $name\n";
  $log .= "hex file: $hexFile\n";
  $log .= "port: $port\n";

  # prepare default Flashcommand
  my $defaultflashCommand = ($hardware eq 'radinoCC1101'
    ? 'avrdude -c avr109 -b [BAUDRATE] -P [PORT] -p atmega32u4 -vv -D -U flash:w:[HEXFILE] 2>[LOGFILE]'
    : 'avrdude -c arduino -b [BAUDRATE] -P [PORT] -p atmega328p -vv -U flash:w:[HEXFILE] 2>[LOGFILE]');

  # get User defined Flashcommand
  my $flashCommand = main::AttrVal($name,'flashCommand',$defaultflashCommand);

  if ($defaultflashCommand eq $flashCommand)  {
    $hash->{logMethod}->($name, 5, "$name: PrepareFlash, standard flashCommand is used to flash.");
  } else {
    $hash->{logMethod}->($name, 3, "$name: PrepareFlash, custom flashCommand is manual defined! $flashCommand");
  }

  main::DevIo_CloseDev($hash);
  if ($hardware eq 'radinoCC1101' && $^O eq 'linux') {
    $hash->{logMethod}->($name, 3, "$name: PrepareFlash, forcing special reset for $hardware on $port");
    # Mit dem Linux-Kommando 'stty' die Port-Einstellungen setzen

    my($chld_out, $chld_in, $chld_err);
    my $pid;
    eval {
      $pid = IPC::Open3::open3($chld_in,$chld_out, $chld_err,  "stty -F $port ospeed 1200 ispeed 1200");
      close($chld_in);  # give end of file to kid, or feed him
    };
    if ($@) {
      $hash->{helper}{stty_output}=$@;
    } else {
      my @outlines = <$chld_out>;              # read till EOF
      my @errlines = <$chld_err>;              # XXX: block potential if massive
      $hash->{helper}{stty_pid}=$pid;
      $hash->{helper}{stty_output} = join(' ',@outlines).join(' ',@errlines);
    }
    $port =~ s/usb-Unknown_radino/usb-In-Circuit_radino/g;
    $hash->{logMethod}->($name ,3, "$name: PrepareFlash, changed usb port to \"$port\" for avrdude flashcommand compatible with radino");
  }
  $hash->{helper}{avrdudecmd} = $flashCommand;
  $hash->{helper}{avrdudecmd}=~ s/\Q[PORT]\E/$port/g;
  $hash->{helper}{avrdudecmd} =~ s/\Q[HEXFILE]\E/$hexFile/g;
  if ($hardware =~ '^nano' && $^O eq 'linux') {
    $hash->{logMethod}->($name ,5, "$name: PrepareFlash, try additional flash with baudrate 115200 for optiboot");
    $hash->{helper}{avrdudecmd} = $hash->{helper}{avrdudecmd}." || ". $hash->{helper}{avrdudecmd};
    $hash->{helper}{avrdudecmd} =~ s/\Q[BAUDRATE]\E/$baudrate/;
    $baudrate=115200;
  }
  $hash->{helper}{avrdudecmd} =~ s/\Q[BAUDRATE]\E/$baudrate/;
  $log .= "command: $hash->{helper}{avrdudecmd}\n\n";
  main::FHEM::Core::Timer::Helper::addTimer($name,main::gettimeofday() + 1,\&SIGNALduino_avrdude,$name);
  $hash->{helper}{avrdudelogs} = $log;
  return ;
}

############################# package main
 sub SIGNALduino_Set_flash {
  my ($hash, @a) = @_;
  my $name = $hash->{NAME};
  return "Please define your hardware! (attr $name hardware <model of your receiver>) " if (main::AttrVal($name,'hardware','') eq '');

  my @args = @a[1..$#a];
  return 'ERROR: argument failed! flash [hexFile|url]' if (!$args[0]);

  my %http_param = (
    timeout    => 5,
    hash       => $hash,                                                     # Muss gesetzt werden, damit die Callback funktion wieder $hash hat
    method     => 'GET',                                                     # Lesen von Inhalten
    header     => "User-Agent: perl_fhem\r\nAccept: application/json",       # Den Header gemaess abzufragender Daten aendern
  );

  my $hexFile = '';
  if( ( exists $hash->{additionalSets}{flash} ) && ( grep $args[0] eq $_ , split(',',$hash->{additionalSets}{flash}) ) )
  {
    $hash->{logMethod}->($hash, 3, "$name: Set_flash, $args[0] try to fetch github assets for tag $args[0]");
    my $ghurl = "https://api.github.com/repos/RFD-FHEM/SIGNALDuino/releases/tags/$args[0]";
    $hash->{logMethod}->($hash, 3, "$name: Set_flash, $args[0] try to fetch release $ghurl");

    $http_param{url}        = $ghurl;
    $http_param{callback}   = \&SIGNALduino_githubParseHttpResponse;  # Diese Funktion soll das Ergebnis dieser HTTP Anfrage bearbeiten
    $http_param{command}    = 'getReleaseByTag';
    main::HttpUtils_NonblockingGet(\%http_param);                         # Starten der HTTP Abfrage. Es gibt keinen Return-Code.
    return;
  } elsif ($args[0] =~ m/^https?:\/\// ) {
    $http_param{url}        = $args[0];
    $http_param{callback}   = \&SIGNALduino_ParseHttpResponse;        # Diese Funktion soll das Ergebnis dieser HTTP Anfrage bearbeiten
    $http_param{command}    = 'flash';
    main::HttpUtils_NonblockingGet(\%http_param);
    return;
  } else {
    $hexFile = $args[0];
  }
  $hash->{logMethod}->($name, 3, "$name: Set_flash, filename $hexFile provided, trying to flash");

  # Only for Arduino , not for ESP
  my $hardware = main::AttrVal($name,'hardware','');
  if ($hardware =~ m/(?:nano|mini|radino)/)
  {
    return SIGNALduino_PrepareFlash($hash,$hexFile);
  } else {
    if (defined $main::FW_wname)
    {
      main::FW_directNotify("FILTER=$name", "#FHEMWEB:$main::FW_wname", "FW_okDialog('<u>ERROR:</u><br>Sorry, flashing your $hardware is currently not supported.<br>The file is only downloaded in /opt/fhem/FHEM/firmware.')", '');
    }
    return "Sorry, Flashing your $hardware via Module is currently not supported.";    # processed in tests
  }
}

############################# package main
sub SIGNALduino_Get_availableFirmware {
  my ($hash, @a) = @_;

  if ( !main::HAS_JSON() )
  {
    $hash->{logMethod}->($hash->{NAME}, 1, "$hash->{NAME}: get $a[0] failed. Please install Perl module JSON. Example: sudo apt-get install libjson-perl");
    return "$a[0]: \n\nFetching from github is not possible. Please install JSON. Example:<br><code>sudo apt-get install libjson-perl</code>";
  }

  my $channel=main::AttrVal($hash->{NAME},'updateChannelFW','stable');
  my $hardware=main::AttrVal($hash->{NAME},'hardware',undef);

  my ($validHw) = $main::modules{$hash->{TYPE}}{AttrList} =~ /.*hardware:(.*?)\s/;
  $hash->{logMethod}->($hash->{NAME}, 1, "$hash->{NAME}: found availableFirmware for $validHw");

  if (!defined($hardware) || $validHw !~ /$hardware(?:,|$)/ )
  {
    $hash->{logMethod}->($hash->{NAME}, 1, "$hash->{NAME}: get $a[0] failed. Please set attribute hardware first");
    return "$a[0]: \n\n$hash->{NAME}: get $a[0] failed. Please choose one of $validHw attribute hardware";
  }
  SIGNALduino_querygithubreleases($hash);
  return "$a[0]: \n\nFetching $channel firmware versions for $hardware from github\n";
}

############################# package main
## Parses a HTTP Response for example for flash via http download
sub SIGNALduino_ParseHttpResponse {
  my ($param, $err, $data) = @_;
  my $hash = $param->{hash};
  my $name = $hash->{NAME};

  if($err ne '')                                              # wenn ein Fehler bei der HTTP Abfrage aufgetreten ist
  {
    $hash->{logMethod}->($name, 3, "$name: ParseHttpResponse, error while requesting ".$param->{url}." - $err");                  # Eintrag fuers Log
  }
  elsif($param->{code} eq '200' && $data ne '')               # wenn die Abfrage erfolgreich war ($data enthaelt die Ergebnisdaten des HTTP Aufrufes)
    {
      $hash->{logMethod}->($name, 3, "$name: ParseHttpResponse, url ".$param->{url}.' returned: '.length($data).' bytes Data');   # Eintrag fuers Log

      if ($param->{command} eq 'flash')
      {
        my $filename;

        if ($param->{httpheader} =~ /Content-Disposition: attachment;.?filename=\"?([-+.\w]+)?\"?/)
        {
          $filename = $1;
        } else {  # Filename via path if not specifyied via Content-Disposition
          $param->{path} =~ /\/([-+.\w]+)$/;    #(?:[^\/][\d\w\.]+)+$   \/([-+.\w]+)$
          $filename = $1;
        }
        $hash->{logMethod}->($name, 3, "$name: ParseHttpResponse, Downloaded $filename firmware from ".$param->{host});
        $hash->{logMethod}->($name, 5, "$name: ParseHttpResponse, Header = ".$param->{httpheader});

        $filename = 'FHEM/firmware/' . $filename;
        open(my $file, '>', $filename) or die $!;
        print $file $data;
        close $file;

        # Den Flash Befehl mit der soebene heruntergeladenen Datei ausfuehren
        #SIGNALduino_Log3 $name, 3, "$name: ParseHttpResponse, calling set ".$param->{command}." $filename";        # Eintrag fuers Log

        my $set_return = main::SIGNALduino_Set($hash,$name,$param->{command},$filename); # $hash->{SetFn}
        if (defined($set_return))
        {
          $hash->{logMethod}->($name ,3, "$name: ParseHttpResponse, Error while flashing: $set_return");
        }
      }
    } else {
      $hash->{logMethod}->($name, 3, "$name: ParseHttpResponse, undefined error while requesting ".$param->{url}." - $err - code=".$param->{code});   # Eintrag fuers Log
    }
}

############################# package main
sub SIGNALduino_querygithubreleases {
  my ($hash) = @_;
  my $name = $hash->{NAME};
  my $param = {
                url        => 'https://api.github.com/repos/RFD-FHEM/SIGNALDuino/releases',
                timeout    => 5,
                hash       => $hash,                                                    # Muss gesetzt werden, damit die Callback funktion wieder $hash hat
                method     => 'GET',                                                    # Lesen von Inhalten
                header     => "User-Agent: perl_fhem\r\nAccept: application/json",      # Den Header gemaess abzufragender Daten aendern
                callback   =>  \&SIGNALduino_githubParseHttpResponse,                   # Diese Funktion soll das Ergebnis dieser HTTP Anfrage bearbeiten
                command    => "queryReleases"
              };

  main::HttpUtils_NonblockingGet($param);                                                     # Starten der HTTP Abfrage. Es gibt keinen Return-Code.
}

############################# package main
#return -10 = hardeware attribute is not set
sub SIGNALduino_githubParseHttpResponse {
  my ($param, $err, $data) = @_;
  my $hash = $param->{hash};
  my $name = $hash->{NAME};
  my $hardware=main::AttrVal($name,'hardware',undef);

  if($err ne '')                                                                                                        # wenn ein Fehler bei der HTTP Abfrage aufgetreten ist
  {
    $hash->{logMethod}->($name, 3, "$name: githubParseHttpResponse, error while requesting ".$param->{url}." - $err (command: $param->{command}");   # Eintrag fuers Log
    #readingsSingleUpdate($hash, 'fullResponse', 'ERROR');                                                              # Readings erzeugen
  }
  elsif($data ne '' && defined($hardware))                                                                              # wenn die Abfrage erfolgreich war ($data enthaelt die Ergebnisdaten des HTTP Aufrufes)
  {

    my $json_array = JSON::decode_json($data);
    #print  Dumper($json_array);
    if ($param->{command} eq 'queryReleases') {
      #Log3 $name, 3, "$name: githubParseHttpResponse, url ".$param->{url}." returned: $data";                          # Eintrag fuers Log

      my $releaselist='';
      if (ref($json_array) eq "ARRAY") {
        foreach my $item( @$json_array ) {
          next if (main::AttrVal($name,'updateChannelFW','stable') eq 'stable' && $item->{prerelease});

          #Debug ' item = '.Dumper($item);

          foreach my $asset (@{$item->{assets}})
          {
            next if ($asset->{name} !~ m/$hardware/i);
            $releaselist.=$item->{tag_name}.',' ;
            last;
          }
        }
      }

      $releaselist =~ s/,$//;
      $hash->{additionalSets}{flash} = $releaselist;
    } elsif ($param->{command} eq 'getReleaseByTag' && defined($hardware)) {
      #Debug ' json response = '.Dumper($json_array);

      my @fwfiles;
      foreach my $asset (@{$json_array->{assets}})
      {
        my %fileinfo;
        if ( $asset->{name} =~ m/$hardware/i)
        {
          $fileinfo{filename} = $asset->{name};
          $fileinfo{dlurl} = $asset->{browser_download_url};
          $fileinfo{create_date} = $asset->{created_at};
          #Debug ' firmwarefiles = '.Dumper(@fwfiles);
          push @fwfiles, \%fileinfo;

          my $set_return = main::SIGNALduino_Set($hash,$name,'flash',$asset->{browser_download_url}); # $hash->{SetFn
          if(defined($set_return))
          {
            $hash->{logMethod}->(og3 $name, 3, "$name: githubParseHttpResponse, Error while trying to download firmware: $set_return");
          }
          last;
        }
      }

    }
  } elsif (!defined($hardware))  {
    $hash->{logMethod}->($name, 5, "$name: githubParseHttpResponse, hardware is not defined");
  }
  # wenn
  # Damit ist die Abfrage zuende.
  # Evtl. einen InternalTimer neu schedulen
  if (defined $main::FW_wname)
  {
     main::FW_directNotify("FILTER=$name", "#FHEMWEB:$main::FW_wname", "location.reload('true')", '');
  }
  return 0;
}

1;
