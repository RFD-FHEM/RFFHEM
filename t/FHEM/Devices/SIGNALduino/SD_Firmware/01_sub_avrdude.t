#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{ is array bag call hash item end etc U D };
use Test2::Mock qw(mock);
use Test2::Todo;
use File::Temp qw(tempdir);
use File::Spec;

#use FHEM::Devices::SIGNALduino::SD_IO qw(:all);
use FHEM::Devices::SIGNALduino::SD_Firmware qw(:all);

# Mock device hash and environment
my $target = 'cc1101dummyDuino';
our %defs = ($target => { 
    NAME => $target, 
    cc1101_available => 1,
    logMethod => sub { my ($hash, $level, $msg) = @_; note "Log $level: $msg"; return }, # dummy logMethod
  }
);
my $targetHash = $defs{$target};

my $mock_avrdude_dir = tempdir(CLEANUP => 1);
for my $tool_name (qw(avrdude avrdude.exe)) {
  my $tool_path = File::Spec->catfile($mock_avrdude_dir, $tool_name);
  open my $tool_fh, '>', $tool_path or die "Cannot create $tool_path: $!";
  print {$tool_fh} "#!/bin/sh\n";
  close $tool_fh or die "Cannot close $tool_path: $!";
  chmod 0755, $tool_path;
}

sub build_mock_path {
  my ($os) = @_;
  my $path_separator = $os eq 'MSWin32' ? ';' : ':';
  my $current_path = $ENV{PATH} // '';
  return join($path_separator, $mock_avrdude_dir, $current_path);
}

# --- Mocks for FHEM environment and dependencies ---
my $mock_main = Test2::Mock->new(
  track => 1,
  class => 'main',
  autoload => 1,
  add => [
    AttrVal => sub {
      my ($name, $attr, $default) = @_;
      if($attr eq 'logdir') {      return '/tmp/';    }
      return $default;
    },
  ],
);
my $timer_mock = Test2::Mock->new(
  track => 1,
  class => 'FHEM::Core::Timer::Helper',
  add => [
    addTimer => sub { note "addTimer called" },
  ],
);	 

my $mock_open3 = Test2::Mock->new(
  track => 1,
  class => 'IPC::Open3',
  override => [
    open3 => sub {
        my ($wtr, $rdr, $err, @cmd) = @_;
        return 12345; # dummy pid
    },
  ],
);

# --- Test execution ---
$targetHash->{TYPE} = "SIGNALduino";


subtest 'avrdude tests' => sub {

  subtest 'without installed avrdude and without logfile placeholder' => sub {
    plan(6);
    $targetHash->{helper}{avrdudecmd}=q[perl -e '{ exit(127); }' ];

    my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_avrdude($target);

    is($ret,"WARNING: avrdude created no log file", "check return value");		
    is($targetHash->{FLASH_RESULT},$ret, "check internal value");
    is($targetHash->{helper}->{avrdudecmd},q[perl -e '{ exit(127); }' ], "check avrdudecmd unchanged");
    
    like($mock_main->sub_tracking()->{readingsSingleUpdate}->[0]->{args}->[2], qr/FIRMWARE UPDATE running/, "check state 1. reading update");
    like($mock_main->sub_tracking()->{readingsSingleUpdate}->[1]->{args}->[2], qr/FIRMWARE UPDATE with error/, "check state 2. reading update");
    like($mock_main->sub_tracking()->{readingsSingleUpdate}->[2]->{args}->[2], qr/FIRMWARE UPDATE with error/, "check state 3. reading update");
    
    $mock_main->clear_sub_tracking;
  };

  subtest 'without installed avrdude with logfile placeholder' => sub {
    plan(5);
    # Initial setup for test
    $targetHash->{helper}{avrdudecmd}=q[perl -e '{ echo "dummy avrdudecmd"; exit(127); }' 2>> [LOGFILE]];
    my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_avrdude($target);
    is($ret, "ERROR: avrdude exited with error", "check return value");		
    is($targetHash->{FLASH_RESULT},$ret, "check internal value");		
    is($targetHash->{helper}->{avrdudecmd},q[perl -e '{ echo "dummy avrdudecmd"; exit(127); }' 2>> /tmp/SIGNALduino-Flash.log], "check avrdudecmd unchanged");

    like($mock_main->sub_tracking()->{readingsSingleUpdate}->[0]->{args}->[2], qr/FIRMWARE UPDATE running/, "check state 1. reading update");
    like($mock_main->sub_tracking()->{readingsSingleUpdate}->[1]->{args}->[2], qr/FIRMWARE UPDATE with error/, "check state 2. reading update");
    $mock_main->clear_sub_tracking;
  };


  subtest 'without installed avrdude but stty' => sub {
    plan(5);
    # Initial setup for test
    $targetHash->{helper}{stty_pid} = 12345;  # to cover the branch in SD_Firmware.pm
    $targetHash->{helper}{avrdudecmd}=q[perl -e '{ echo "dummy avrdudecmd"; exit(127); }' 2>> [LOGFILE]];
    my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_avrdude($target);
    is($ret, "ERROR: avrdude exited with error", "check return value");		
    is($targetHash->{FLASH_RESULT},$ret, "check internal value");		
    is($targetHash->{helper}->{avrdudecmd},q[perl -e '{ echo "dummy avrdudecmd"; exit(127); }' 2>> /tmp/SIGNALduino-Flash.log], "check avrdudecmd unchanged");

    like($mock_main->sub_tracking()->{readingsSingleUpdate}->[0]->{args}->[2], qr/FIRMWARE UPDATE running/, "check state 1. reading update");
    like($mock_main->sub_tracking()->{readingsSingleUpdate}->[1]->{args}->[2], qr/FIRMWARE UPDATE with error/, "check state 2. reading update");
    $mock_main->clear_sub_tracking;
  };

  subtest 'without installed avrdude with non existing logdir' => sub {
    plan(5);
    $mock_main->override('AttrVal' => sub {
        my ($name, $attr, $default) = @_;
        if($attr eq 'logdir') {      return '/non/existing/path/';    }
        return $default;
    });

    # Initial setup for test
    $targetHash->{helper}{avrdudecmd}=q[perl -e '{ echo "dummy avrdudecmd"; exit(127); }' 2>> [LOGFILE]];
    my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_avrdude($target);
    is($ret, "WARNING: avrdude created no log file", "check return value");		
    is($targetHash->{FLASH_RESULT},$ret, "check internal value");		
    is($targetHash->{helper}->{avrdudecmd},q[perl -e '{ echo "dummy avrdudecmd"; exit(127); }' 2>> /non/existing/path/SIGNALduino-Flash.log], "check avrdudecmd unchanged");

    like($mock_main->sub_tracking()->{readingsSingleUpdate}->[0]->{args}->[2], qr/FIRMWARE UPDATE running/, "check state 1. reading update");
    like($mock_main->sub_tracking()->{readingsSingleUpdate}->[1]->{args}->[2], qr/FIRMWARE UPDATE with error/, "check state 2. reading update");
    $mock_main->clear_sub_tracking;
    $mock_main->restore('AttrVal');
  };

  subtest 'with installed avrdude (nano328) and logfile written' => sub {
    plan(5);
    
    $targetHash->{helper}{avrdudecmd}=q[perl -e '{ exit(0); }' 2>> [LOGFILE]];
    my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_avrdude($target);
    is($ret,U(), 'check return value');
    like($mock_main->sub_tracking()->{readingsSingleUpdate}->[0]->{args}->[2], qr/FIRMWARE UPDATE running/, "check state 1. reading update");
    like($mock_main->sub_tracking()->{readingsSingleUpdate}->[1]->{args}->[2], qr/FIRMWARE UPDATE successfull/, "check 2. state reading update");
    like($targetHash->{helper}{avrdudelogs}, qr(--- AVRDUDE ---------------------------------------------------------------------------------), "check avrdudelogs content");
    is(@{$mock_main->sub_tracking()->{DevIo_OpenDev}}, 1, "check DevIo_OpenDev called");


  };
};

subtest 'PrepareFlash tests' => sub {


  sub setup_prepare_flash_test {
      $targetHash->{DeviceName} = '/dev/serial0';       # Default Port
      $targetHash->{FLASH_FILE} = '/tmp/firmware.hex';
      delete $targetHash->{flashCommand};               # cleanup
      delete $targetHash->{hexfile};                    # cleanup
      delete $targetHash->{helper};
      $targetHash->{helper}{FLASH_DEVICE} = 'mini';     # Default Hardware
      
      # Reset mocks
      $mock_main->clear_sub_tracking;
      $timer_mock->clear_sub_tracking;
  }

  subtest 'PrepareFlash 1: avrdude not in PATH (Error)' => sub {
      plan(1);
      setup_prepare_flash_test();
      my $original_PATH = $ENV{PATH};
      local $^O = 'linux';
      
      local $ENV{PATH} = ''; # Simulate avrdude not in PATH

      my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_PrepareFlash($targetHash,'/tmp/firmware.hex');
            
      like($ret, qr/avrdude is not installed/, "Return value contains 'avrdude is not installed...'");
      
      $ENV{PATH} = $original_PATH; # Restore PATH
  };

  subtest 'PrepareFlash 2: Default Flash (mini, MSWin32)' => sub {
      plan(5);
      local $^O = 'MSWin32';
      setup_prepare_flash_test();
      local $ENV{PATH} = build_mock_path($^O);
    
      my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_PrepareFlash($targetHash,'/tmp/firmware.hex');
      
      is($ret, undef, "Return value is undef (Success)");
      like($targetHash->{helper}{avrdudecmd}, qr/-p atmega328p/, "avrdudecmd contains atmega328p ");
      like($targetHash->{helper}{avrdudecmd}, qr/-b 57600/, "avrdudecmd contains 57600 baud");
      
      is(@{$mock_main->sub_tracking()->{DevIo_CloseDev}}, 1, "check DevIo_CloseDev called");

      is(scalar @{$timer_mock->sub_tracking()->{addTimer}},1,'Verify addTimer is not called');
  };

  subtest 'PrepareFlash 3: Radino Flash (radinoCC1101, MSWin32, special programmer)' => sub {
      plan(5);
      local $^O = 'MSWin32';
      setup_prepare_flash_test();
      local $ENV{PATH} = build_mock_path($^O);
      $targetHash->{helper}{FLASH_DEVICE} = 'radinoCC1101';
      $mock_main->override('AttrVal' => sub {
          my ($name, $attr, $default) = @_;
          if($attr eq 'hardware') { return 'radinoCC1101' }
          return $default;
      });

      my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_PrepareFlash($targetHash,'/tmp/firmware.hex');
      
      is($ret, undef, "Return value is undef (Success)");
      like($targetHash->{helper}{avrdudecmd}, qr/-p atmega32u4/, "avrdudecmd contains atmega32u4");
      like($targetHash->{helper}{avrdudecmd}, qr/-c avr109/, "avrdudecmd contains avr109 programmer");
      is(@{$mock_main->sub_tracking()->{DevIo_CloseDev}}, 1, "check DevIo_CloseDev called");
      is(scalar @{$timer_mock->sub_tracking()->{addTimer}},1,'Verify addTimer is not called');

      $mock_main->restore('AttrVal'); # Restore original AttrVal behavior
  };

  subtest 'PrepareFlash 4: Custom flashCommand with placeholders' => sub {
      plan(2);
      local $^O = 'linux';
      setup_prepare_flash_test();
      local $ENV{PATH} = build_mock_path($^O);
      $targetHash->{DeviceName} = '/dev/serial0'; # Ensure this is set
      
      $mock_main->override('AttrVal' => sub {
          my ($name, $attr, $default) = @_;
          if($attr eq 'flashCommand') { return 'my_command [PORT] [BAUDRATE] [HEXFILE]' }
          if($attr eq 'hexfile') { return 'my.hex' }
          if($attr eq 'logdir') { return '/tmp/'; }
          return $default;
      });

      my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_PrepareFlash($targetHash,'my.hex');
      
      is($ret, undef, "Return value is undef (Success)");
      # Default command: /usr/bin/avrdude -c wiring -p atmega328p -P /dev/serial0 -b 57600 -D -U flash:w:/tmp/firmware.hex:i 2>> [LOGFILE]
      # Custom command: my_command /dev/serial0 57600 my.hex 2>> [LOGFILE]
      like($targetHash->{helper}{avrdudecmd},
        qr{my_command /dev/serial0 57600 my.hex},
        "my_command used with correct placeholders replaced");

      $mock_main->restore('AttrVal'); # Restore original AttrVal behavior       
  };

  subtest 'PrepareFlash 5: Nano328 + Linux (Optiboot 57600/115200)' => sub {
      plan(2);
      local $^O = 'linux';
      setup_prepare_flash_test();
      local $ENV{PATH} = build_mock_path($^O);
      $mock_main->override('AttrVal' => sub {
          my ($name, $attr, $default) = @_;
          if($attr eq 'hardware') { return 'nano328' }
          return $default;
      });
      
      my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_PrepareFlash($targetHash,'my.hex');
      
      is($ret, undef, "Return value is undef (Success)");
      like($targetHash->{helper}{avrdudecmd}, qr/-b 57600.*\|\|.*-b 115200/, "avrdudecmd contains both 57600 and 115200 baudrate commands");
      $mock_main->restore('AttrVal'); # Restore original AttrVal behavior       
  };

  subtest 'PrepareFlash 6: Radino + Linux (stty Reset, Port fix)' => sub {
      plan(5);
      local $^O = 'linux';
      setup_prepare_flash_test();
      local $ENV{PATH} = build_mock_path($^O);
      $mock_main->override('AttrVal' => sub {
          my ($name, $attr, $default) = @_;
          if($attr eq 'hardware') { return 'radinoCC1101'; }
          return $default;
      });
      
      # Simulate a by-id port name that needs fixing and stty reset
      $targetHash->{DeviceName} = '/dev/serial/by-id/usb-Unknown_radinoCC1101_v3.4.0-if00';

      my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_PrepareFlash($targetHash,'my.hex');
      
      is($ret, undef, "Return value is undef (Success)");

      # Expected port name fix: usb-Unknown -> usb-In-Circuit
      like($targetHash->{helper}{avrdudecmd}, qr/-P \/dev\/serial\/by-id\/usb-In-Circuit_radinoCC1101_v3.4.0-if00/, "avrdudecmd uses fixed port name");

      is(scalar @{$mock_open3->sub_tracking()->{open3}}, 1, "ipc::open3 called for stty");
      #The stty command is expected to use the original DeviceName (before fixing)
      like($mock_open3->sub_tracking()->{open3}->[0]->{args}->[3], qr{stty -F /dev/serial/by-id/usb-Unknown_radinoCC1101_v3.4.0-if00 ospeed 1200 ispeed 1200}, "stty command called on original port name");
      is(@{$mock_main->sub_tracking()->{DevIo_CloseDev}}, 1, "check DevIo_CloseDev called");
      $mock_open3->clear_sub_tracking;
  };

  subtest 'PrepareFlash 7: Port with Baudrate in DeviceName' => sub {
      plan(3);
      local $^O = 'linux';
      setup_prepare_flash_test();
      local $ENV{PATH} = build_mock_path($^O);
      $targetHash->{helper}{FLASH_DEVICE} = 'mini';
      $targetHash->{DeviceName} = '/dev/ttyACM0@1200'; # Baudrate im Namen, wird ignoriert/entfernt

      my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_PrepareFlash($targetHash,'my.hex');
      
      is($ret, undef, "Return value is undef (Success)");
      
      # Expected command: Port is /dev/ttyACM0, Baudrate is 57600
      like($targetHash->{helper}{avrdudecmd}, qr{-P /dev/ttyACM0}, "avrdudecmd uses only port part ");
      like($targetHash->{helper}{avrdudecmd}, qr{-b 57600}, "avrdudecmd uses default baudrate");
  };

};

done_testing();
