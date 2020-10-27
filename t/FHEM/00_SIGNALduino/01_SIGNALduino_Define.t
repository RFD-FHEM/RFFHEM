#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is field U D match hash bag };
use Mock::Sub;
use Test2::Todo;

my ($mock);

BEGIN {
  $mock = Mock::Sub->new;
};

InternalTimer(time()+1, sub() {

  #$hash{FUUID} = genUUID();
  #$hash{NR}    = $devcount++;
  #$hash{CFGFN} = $currcfgfile

  my %hash;
  $hash{CL}    = undef;
  $hash{TEMPORARY} = 1;
  $hash{NAME}  = q{defTest};
  $hash{TYPE}  = q{00_SIGNALduino};
  $hash{STTAE} = q{???};
  
  # Prepare HASH for test
  $hash{DEF}   = q{/dev/serial/by-id/something4@115200};
  subtest "checking $hash{DEF} on $hash{NAME}" => sub {

	plan(2);

    my $ret = SIGNALduino_Define(\%hash,qq{$hash{NAME} $hash{TYPE} $hash{DEF} });

    is ($ret, undef, 'check retutnvalue SIGNALduino_Define');
    is(\%hash,hash {
        field STTAE => q{???}; 
        field DeviceName => q{/dev/serial/by-id/something4@115200};
        field DEF => q{/dev/serial/by-id/something4@115200};
        etc();
      },
      'check hash after SIGNALduino_Define'
    );
    delete $hash{DeviceName};
  };

  # Prepare HASH for test
  $hash{DEF}   = q{/dev/serial/by-id/something4};
  subtest "checking $hash{DEF} on $hash{NAME}" => sub {
	plan (2);

    my $ret = SIGNALduino_Define(\%hash,qq{$hash{NAME} $hash{TYPE} $hash{DEF} });

    is ($ret, undef, 'check retutnvalue SIGNALduino_Define');
    is(\%hash,hash {
        field STTAE => q{???}; 
        field DeviceName => q{/dev/serial/by-id/something4\@57600};
        field DEF => q{/dev/serial/by-id/something4};
        etc();
      },
      'check hash after SIGNALduino_Define'
    );
    delete $hash{DeviceName};
  };

  # Prepare HASH for test
  $hash{DEF}   = q{/dev/serial/by-id/something4@57600};
  subtest "checking $hash{DEF} on $hash{NAME}" => sub {
	plan (2);

    my $ret = SIGNALduino_Define(\%hash,qq{$hash{NAME} $hash{TYPE} $hash{DEF} });

    is ($ret, undef, 'check retutnvalue SIGNALduino_Define');
    is(\%hash,hash {
        field STTAE => q{???}; 
        field DeviceName => q{/dev/serial/by-id/something4@57600};
        field DEF => q{/dev/serial/by-id/something4@57600};
        etc();
      },
      'check hash after SIGNALduino_Define'
    );
    delete $hash{DeviceName};
  };

  # Prepare HASH for test
  $hash{DEF}   = q{/dev/serial/by-path/platform-3f980000.usb-usb-0:1.1.3:1.0-port0@57600};
  subtest "checking $hash{DEF} on $hash{NAME}" => sub {
	plan (2);

    my $ret = SIGNALduino_Define(\%hash,qq{$hash{NAME} $hash{TYPE} $hash{DEF} });

    is ($ret, undef, 'check retutnvalue SIGNALduino_Define');
    is(\%hash,hash {
        field STTAE => q{???}; 
        field DeviceName => q{/dev/serial/by-path/platform-3f980000.usb-usb-0:1.1.3:1.0-port0@57600};
        field DEF => q{/dev/serial/by-path/platform-3f980000.usb-usb-0:1.1.3:1.0-port0@57600};
        etc();
      },
      'check hash after SIGNALduino_Define'
    );
    delete $hash{DeviceName};
  };  
  
  # Prepare HASH for test
  $hash{DEF}   = q{/dev/ttyACM1@57600};
  subtest "checking $hash{DEF} on $hash{NAME}" => sub {
	plan (2);

    my $ret = SIGNALduino_Define(\%hash,qq{$hash{NAME} $hash{TYPE} $hash{DEF} });

    is ($ret, undef, 'check retutnvalue SIGNALduino_Define');
    is(\%hash,hash {
        field STTAE => q{???}; 
        field DeviceName => q{/dev/ttyACM1@57600};
        field DEF => q{/dev/ttyACM1@57600};
        etc();
      },
      'check hash after SIGNALduino_Define'
    );
    delete $hash{DeviceName};
  };  
  
  
  # Prepare HASH for test
  $hash{DEF}   = q{Hostname:65536};
  subtest "checking $hash{DEF} on $hash{NAME}" => sub {
	plan (2);

    my $ret = SIGNALduino_Define(\%hash,qq{$hash{NAME} $hash{TYPE} $hash{DEF} });

    is ($ret, D(), 'check retutnvalue SIGNALduino_Define');
    is(\%hash,hash {
        field STTAE => q{???}; 
        field DeviceName => U();
        field DEF => q{Hostname:65536};
        etc();
      },
      'check hash after SIGNALduino_Define'
    );
    delete $hash{DeviceName};
  };  
  
  
    # Prepare HASH for test
  $hash{DEF}   = q{192:168:122:56:45476};
  subtest "checking $hash{DEF} on $hash{NAME}" => sub {
	plan (2);

    my $ret = SIGNALduino_Define(\%hash,qq{$hash{NAME} $hash{TYPE} $hash{DEF} });

    is ($ret, D(), 'check retutnvalue SIGNALduino_Define');
    is(\%hash,hash {
        field STTAE => q{???}; 
        field DeviceName => U();
        field DEF => q{192:168:122:56:45476};
        etc();
      },
      'check hash after SIGNALduino_Define'
    );
    delete $hash{DeviceName};
  };  
  
  $hash{DEF}   = q{192.168.122.56:44323};
  subtest "checking $hash{DEF} on $hash{NAME}" => sub {
	plan (2);

    my $ret = SIGNALduino_Define(\%hash,qq{$hash{NAME} $hash{TYPE} $hash{DEF} });

    is ($ret, U(), 'check retutnvalue SIGNALduino_Define');
    is(\%hash,hash {
        field STTAE => q{???}; 
        field DeviceName => q{192.168.122.56:44323};
        field DEF => q{192.168.122.56:44323};
        etc();
      },
      'check hash after SIGNALduino_Define'
    );
    delete $hash{DeviceName};
  };  
  
  $hash{DEF}   = q{192.168.122.56};
  subtest "checking $hash{DEF} on $hash{NAME}" => sub {
	plan (2);

    my $ret = SIGNALduino_Define(\%hash,qq{$hash{NAME} $hash{TYPE} $hash{DEF} });

    is ($ret, D(), 'check retutnvalue SIGNALduino_Define');
    is(\%hash,hash {
        field STTAE => q{???}; 
        field DeviceName => U();
        field DEF => q{192.168.122.56};
        etc();
      },
      'check hash after SIGNALduino_Define'
    );
    delete $hash{DeviceName};
  };  

  $hash{DEF}   = q{192.168.122:44323};
  subtest "checking $hash{DEF} on $hash{NAME}" => sub {
	plan (2);

    my $ret = SIGNALduino_Define(\%hash,qq{$hash{NAME} $hash{TYPE} $hash{DEF} });

    is ($ret, D(), 'check retutnvalue SIGNALduino_Define');
    is(\%hash,hash {
        field STTAE => q{???}; 
        field DeviceName => U();
        field DEF => q{192.168.122:44323};
        etc();
      },
      'check hash after SIGNALduino_Define'
    );
    delete $hash{DeviceName};
  };  


  $hash{DEF}   = q{sernetgw:44323};
  subtest "checking $hash{DEF} on $hash{NAME}" => sub {
	plan (2);

    my $ret = SIGNALduino_Define(\%hash,qq{$hash{NAME} $hash{TYPE} $hash{DEF} });

    is ($ret, U(), 'check retutnvalue SIGNALduino_Define');
    is(\%hash,hash {
        field STTAE => q{???}; 
        field DeviceName => q{sernetgw:44323};
        field DEF => q{sernetgw:44323};
        etc();
      },
      'check hash after SIGNALduino_Define'
    );
    delete $hash{DeviceName};
  };  

  $hash{DEF}   = q{sernetgw.local.host:44323};
  subtest "checking $hash{DEF} on $hash{NAME}" => sub {
	plan (2);

    my $ret = SIGNALduino_Define(\%hash,qq{$hash{NAME} $hash{TYPE} $hash{DEF} });

    is ($ret, U(), 'check retutnvalue SIGNALduino_Define');
    is(\%hash,hash {
        field STTAE => q{???}; 
        field DeviceName => q{sernetgw.local.host:44323};
        field DEF => q{sernetgw.local.host:44323};
        etc();
      },
      'check hash after SIGNALduino_Define'
    );
    delete $hash{DeviceName};
  };
  
  $hash{DEF}   = q{sernetgw.local.host};
  subtest "checking $hash{DEF} on $hash{NAME}" => sub {
	plan (2);

    my $ret = SIGNALduino_Define(\%hash,qq{$hash{NAME} $hash{TYPE} $hash{DEF} });

    is ($ret, D(), 'check retutnvalue SIGNALduino_Define');
    is(\%hash,hash {
        field STTAE => q{???}; 
        field DeviceName => U();
        field DEF => q{sernetgw.local.host};
        etc();
      },
      'check hash after SIGNALduino_Define'
    );
    delete $hash{DeviceName};
  };
  
  $hash{DEF}   = q{COM3};
  subtest "checking $hash{DEF} on $hash{NAME}" => sub {
	plan (2);

    my $ret = SIGNALduino_Define(\%hash,qq{$hash{NAME} $hash{TYPE} $hash{DEF} });

    is ($ret, U(), 'check retutnvalue SIGNALduino_Define');
    is(\%hash,hash {
        field STTAE => q{???}; 
        field DeviceName => q{COM3\@57600};
        field DEF => q{COM3};
        etc();
      },
      'check hash after SIGNALduino_Define'
    );
    delete $hash{DeviceName};
  };

  $hash{DEF}   = q{none};
  subtest "checking $hash{DEF} on $hash{NAME}" => sub {
	plan (2);

    my $ret = SIGNALduino_Define(\%hash,qq{$hash{NAME} $hash{TYPE} $hash{DEF} });

    is ($ret, U(), 'check retutnvalue SIGNALduino_Define');
    is(\%hash,hash {
        field STTAE => q{???}; 
        field DeviceName => q{none};
        field DEF => q{none};
        etc();
      },
      'check hash after SIGNALduino_Define'
    );
    delete $hash{DeviceName};
  };


  $hash{DEF}   = q{/dev/some@directio};
  subtest "checking $hash{DEF} on $hash{NAME}" => sub {
	plan (2);

    my $ret = SIGNALduino_Define(\%hash,qq{$hash{NAME} $hash{TYPE} $hash{DEF} });

    is ($ret, U(), 'check retutnvalue SIGNALduino_Define');
    is(\%hash,hash {
        field STTAE => q{???}; 
        field DeviceName => q{/dev/some@directio};
        field DEF => q{/dev/some@directio};
        etc();
      },
      'check hash after SIGNALduino_Define'
    );
    delete $hash{DeviceName};
  };

    
  done_testing();
  exit(0);

}, 0);

1;