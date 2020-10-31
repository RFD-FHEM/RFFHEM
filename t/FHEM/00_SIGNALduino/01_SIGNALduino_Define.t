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

  my %hash;
  $hash{CL}    = undef;
  $hash{TEMPORARY} = 1;
  $hash{NAME}  = q{defTest};
  $hash{TYPE}  = q{00_SIGNALduino};
  $hash{STTAE} = q{???};
  #$hash{FUUID} = genUUID();
  #$hash{NR}    = $devcount++;
  #$hash{CFGFN} = $currcfgfile

  my @mockData = (
  {
    DEF => q{/dev/serial/by-id/something4@115200},
    testname =>  q[USB|Linux|Valid:],
    check =>  hash {
         field STTAE => q{???}; 
         field DeviceName => q{/dev/serial/by-id/something4@115200};
         field DEF => q{/dev/serial/by-id/something4@115200};
         etc();
      },
      rValue => U(), 
  },
  { 
  	DEF => q{/dev/serial/by-id/something4},
    testname =>  q[USB|Linux|Valid:],
    check =>  hash {
         field STTAE => q{???}; 
         field DeviceName => q{/dev/serial/by-id/something4@57600};
         field DEF => q{/dev/serial/by-id/something4};
         etc();
      },
      rValue => U(), 
  },
  { 
  	DEF => q{/dev/serial/by-id/something4@57600},
    testname =>  q[USB|Linux|Valid:],
    check =>  hash {
         field STTAE => q{???}; 
         field DeviceName => q{/dev/serial/by-id/something4@57600};
         field DEF => q{/dev/serial/by-id/something4@57600};
         etc();
      },
      rValue => U(), 
  },
  { 
  	DEF => q{/dev/ttyUSB0},
    testname =>  q[USB|Linux|Valid:],
    check =>  hash {
         field STTAE => q{???}; 
         field DeviceName => q{/dev/ttyUSB0@57600};
         field DEF => q{/dev/ttyUSB0};
         etc();
      },
      rValue => U(), 
  },  
  { 
  	DEF => q{/dev/serial/by-path/platform-3f980000.usb-usb-0:1.1.3:1.0-port0@57600},
    testname =>  q[USB|Linux|Valid:],
    check =>  hash {
         field STTAE => q{???}; 
         field DeviceName => q{/dev/serial/by-path/platform-3f980000.usb-usb-0:1.1.3:1.0-port0@57600};
         field DEF => q{/dev/serial/by-path/platform-3f980000.usb-usb-0:1.1.3:1.0-port0@57600};
         etc();
      },
      rValue => U(), 
  },  
  
  { 
  	DEF => q{/dev/ttyACM1@57600},
    testname =>  q[USB|Linux|Valid:],
    check =>  hash {
         field STTAE => q{???}; 
         field DeviceName => q{/dev/ttyACM1@57600};
         field DEF => q{/dev/ttyACM1@57600};
         etc();
      },
      rValue => U(), 
  },  

  { 
  	DEF => q{COM3},
    testname =>  q[USB|Windows|Valid:],
    check =>  hash {
         field STTAE => q{???}; 
         field DeviceName => q{COM3@57600};
         field DEF => q{COM3};
         etc();
      },
      rValue => U(), 
  },    
  { 
  	DEF => q{Hostname:65536},
    testname =>  q[Hostname|Linux|Invalid:],
    check =>  hash {
         field STTAE => q{???}; 
         field DeviceName => U();
         field DEF => q{Hostname:65536};
         etc();
      },
      rValue => D(), 
  },  
  
  { 
  	DEF => q{192:168:122:56:45476},
    testname =>  q[Hostname|Linux|Invalid:],
    check =>  hash {
         field STTAE => q{???}; 
         field DeviceName => U();
         field DEF => q{192:168:122:56:45476};
         etc();
      },
      rValue => D(), 
  },  
  
  { 
  	DEF => q{192.168.122.56:44323},
    testname =>  q[Hostname|Linux|Valid:],
    check =>  hash {
         field STTAE => q{???}; 
         field DeviceName => q{192.168.122.56:44323};
         field DEF => q{192.168.122.56:44323};
         etc();
      },
      rValue => U(), 
  },     
  { 
  	DEF => q{192.168.122:44323},
    testname =>  q[Hostname|Linux|Invalid:],
    check =>  hash {
         field STTAE => q{???}; 
         field DeviceName => U();
         field DEF => q{192.168.122:44323};
         etc();
      },
      rValue => D(), 
  },     
  { 
  	DEF => q{sernetgw:44323},
    testname =>  q[Hostname|Linux|Valid:],
    check =>  hash {
         field STTAE => q{???}; 
         field DeviceName => q{sernetgw:44323};
         field DEF => q{sernetgw:44323};
         etc();
      },
      rValue => U(), 
  },     
  { 
  	DEF => q{sernetgw.local.host:44323},
    testname =>  q[Hostname|Linux|Valid:],
    check =>  hash {
         field STTAE => q{???}; 
         field DeviceName => q{sernetgw.local.host:44323};
         field DEF => q{sernetgw.local.host:44323};
         etc();
      },
      rValue => U(), 
  },    
  { 
  	DEF => q{sernetgw.local.host},
    testname =>  q[Hostname|Linux|inValid:],
    check =>  hash {
         field STTAE => q{???}; 
         field DeviceName => U();
         field DEF => q{sernetgw.local.host};
         etc();
      },
      rValue => D(), 
  },
  
  { 
  	DEF => q{ESP-DB7D13-Testboard:23},
    testname =>  q[Hostname|Linux|Valid:],
    check =>  hash {
         field STTAE => q{???}; 
         field DeviceName => q{ESP-DB7D13-Testboard:23};
         field DEF => q{ESP-DB7D13-Testboard:23};
         etc();
      },
      rValue => U(), 
  },  

  { 
  	DEF => q{ESP-0CAD2F:23},
    testname =>  q[Hostname|Linux|Valid:],
    check =>  hash {
         field STTAE => q{???}; 
         field DeviceName => q{ESP-0CAD2F:23};
         field DEF => q{ESP-0CAD2F:23};
         etc();
      },
      rValue => U(), 
  },    
    
    
  { 
  	DEF => q{none},
    testname =>  q[none|Valid:],
    check =>  hash {
         field STTAE => q{???}; 
         field DeviceName => q{none};
         field DEF => q{none};
         etc();
      },
      rValue => U(), 
  },     

  { 
  	DEF => q{/dev/some@directio},
    testname =>  q[DirectIO|Linux|Valid:],
    check =>  hash {
         field STTAE => q{???}; 
         field DeviceName => q{/dev/some@directio};
         field DEF => q{/dev/some@directio};
         etc();
      },
      rValue => U(), 
  },     
  
  );
  
  

  while (@mockData)
  {
    my $element = pop(@mockData);
    next if (!exists($element->{testname}));
    delete $hash{DeviceName};

    subtest "$element->{testname} checking define $element->{DEF}" => sub {
      $hash{DEF}   = $element->{DEF};
 	  plan(2);

      my $ret = SIGNALduino_Define(\%hash,qq{$hash{NAME} $hash{TYPE} $hash{DEF} });
      is ($ret, $element->{rValue}, 'check returnvalue SIGNALduino_Define');
      is(\%hash, $element->{check}, 'check hash fields after SIGNALduino_Define');
     	  
    };
  
  }
  done_testing();
  exit(0);
  


    
  done_testing();
  exit(0);

}, 0);

1;