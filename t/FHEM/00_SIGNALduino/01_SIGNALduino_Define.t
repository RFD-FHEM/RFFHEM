#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is field U D match hash bag object};
use Mock::Sub;
use Test2::Todo;

our %defs;

InternalTimer(time()+0.8, sub {

  my %hash;
  my $name=shift;

  $hash{CL}    = undef;
  $hash{TEMPORARY} = 1;
  $hash{TYPE}  = q{00_SIGNALduino};
  $hash{STATE} = q{???};

  my @mockData = (
  {
    DEF => q{/dev/serial/by-id/something4@115200},
    testname =>  q[USB|Linux|Valid:],
    check =>  hash {
         field STATE => q{disconnected}; 
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
         field STATE => q{disconnected}; 
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
         field STATE => q{disconnected}; 
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
         field STATE => q{disconnected}; 
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
         field STATE => q{disconnected}; 
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
         field STATE => q{disconnected}; 
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
         field STATE => q{disconnected}; 
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
         field STATE => q{disconnected}; 
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
         field STATE => q{disconnected}; 
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
         field STATE => q{disconnected}; 
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
         field STATE => q{disconnected}; 
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
         field STATE => q{disconnected}; 
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
         field STATE => q{disconnected}; 
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
         field STATE => q{disconnected}; 
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
         field STATE => q{disconnected}; 
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
         field STATE => q{disconnected}; 
         field DeviceName => q{ESP-0CAD2F:23};
         field DEF => q{ESP-0CAD2F:23};
         etc();
      },
      rValue => U(), 
  },    
  { 
  	plan => 3,
  	DEF => q{none},
    testname =>  q[none|Valid:],
    check =>  hash {
         field STATE => q{opened}; 
         field DeviceName => q{none};
         field DEF => q{none};
         field protocolObject => object { 
            prop isa => 'lib::SD_Protocols';
            prop reftype => 'HASH';
            call [qw(_logging testmessage 1)] => validator(sub {
              return is(FhemTestUtils_gotLog(qr/\sdefTest:.*testmessage/),1,q[verify logging message]);
            });
         };
         etc();
      },
      rValue => U(), 
  },     
  { 
  	plan => 3,
    DEF => q{/dev/some@directio},
    testname =>  q[DirectIO|Linux|Valid:],
    check =>  hash {
         field STATE => q{disconnected}; 
         field DeviceName => q{/dev/some@directio};
         field DEF => q{/dev/some@directio};
         field protocolObject => object { 
            prop isa => 'lib::SD_Protocols';
            prop reftype => 'HASH';
            call [qw(_logging testmessage 1)] => validator(sub {
              return is(FhemTestUtils_gotLog(qr/\sdefTest:.*testmessage/),1,q[verify logging message]);
            });
         };
         
         etc();
      },
      rValue => U(), 
  },     

  { 
    NAME => q{logTest},
  	plan => 3,
    DEF => q{/dev/some@directio},
    testname =>  q[logtest DirectIO|Linux|Valid:],
    check =>  hash {
         field STATE => q{disconnected}; 
         field DeviceName => q{/dev/some@directio};
         field DEF => q{/dev/some@directio};
         field protocolObject => object { 
            prop isa => 'lib::SD_Protocols';
            prop reftype => 'HASH';
            call [qw(_logging testmessage 1)] => validator(sub {
              return is(FhemTestUtils_gotLog(qr/\slogTest:.*testmessage/),1,q[verify logging message]);
            });
         };
         
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
      $hash{NAME}  = $element->{NAME} // $name;
      FhemTestUtils_resetLogs();
      $hash{DEF}   = $element->{DEF};
 	    plan( $element->{plan} // 2 );

      my $ret = SIGNALduino_Define(\%hash,qq{$hash{NAME} $hash{TYPE} $hash{DEF} });
      is ($ret, $element->{rValue}, 'check returnvalue SIGNALduino_Define');
      is(\%hash, $element->{check}, 'check hash fields after SIGNALduino_Define');

    };
  
  }
  

}, q{defTest});

InternalTimer(time()+0.9, sub {

  my $name=shift;
  my $hash = $defs{$name};

  
  subtest "Check logging of given definition" => sub {
    plan(1);

    $hash->{protocolObject}->_logging('verifymessage');
    is(FhemTestUtils_gotLog(qr/$name:.*verifymessage/),1,q[verify logging message]);
  };
  
  done_testing();
  exit(0);
}, q{dummyDuino});


1;