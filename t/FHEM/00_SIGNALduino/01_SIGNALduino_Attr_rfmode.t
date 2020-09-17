#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is item U D like hash array bag};
use Mock::Sub;
use Test2::Todo;

# Mock cc1101
$defs{cc1101dummyDuino}{cc1101_available} = 1;


my $queuEmptyHashCheck =  hash  {
  field QUEUE => DNE();
  etc();
};

InternalTimer(time()+1, sub() {
  is($defs{cc1101dummyDuino},hash {
        field cc1101_available => 1; 
        field DevState => 'initialized'; 
        etc();
      },
    'check mocked cc1101dummyDuino hash');
  is($defs{dummyDuino},hash   {
        field cc1101_available => U();
        field DevState => 'initialized'; 
        etc();
      },
    'check mocked dummyDuino hash');
  is($defs{someDuino},hash  {
        field cc1101_available => U(); 
        field DevState => 'initialized'; 
        etc();
      },
    'check mocked someDuino hash');

  is(IsDummy('someDuino'),0, 'check someDuino is not a dummy');

  subtest 'Call without cc1101 receiver' => sub {
    my $ret = SIGNALduino_Attr_rfmode($defs{someDuino},'SlowRF');
    like($ret,qr/This attribute is only available for a receiver with CC1101/,q[verify error message if not a cc1101 device]);
  };

  subtest 'Call as uninitalized dummy receiver' => sub {
  $defs{dummyDuino}{DevState} = '0';
    my $ret = SIGNALduino_Attr_rfmode($defs{dummyDuino},'SlowRF');
    is($ret,U(),q[verify return undef if not initalized]);
  $defs{dummyDuino}{DevState} = 'initialized';
  };

  subtest 'Call as uninitalized cc1101dummyDuino receiver' => sub {
  $defs{cc1101dummyDuino}{DevState} = '0';
    my $ret = SIGNALduino_Attr_rfmode($defs{cc1101dummyDuino},'SlowRF');
    is($ret,U(),q[verify return undef if not initalized]);
    is($defs{cc1101dummyDuino},$queuEmptyHashCheck,'verify sendqueue is empty');
  $defs{cc1101dummyDuino}{DevState} = 'initialized';
  };

  subtest 'Call as initalized cc1101dummyDuino receiver' => sub {

    subtest 'rfmode set to SlowRF ' => sub {
    my $ret = SIGNALduino_Attr_rfmode($defs{cc1101dummyDuino},'SlowRF');
    is($ret,U(),q[verify return undef if initalized]);
    is($defs{cc1101dummyDuino},hash {
               field QUEUE => bag 
                 { 
                        item 'e'; 
                        etc();
                   }; 
           etc();}, 'verify sendqueue has e command');
    };

    subtest 'rfmode set to blafasel' => sub {
      my $ret = SIGNALduino_Attr_rfmode($defs{cc1101dummyDuino},'blafasel');  
      is($ret,U(),q[verify return undef ]);
      is(FhemTestUtils_gotLog(".*rfmode value not found in protocols.*"), 1, 'Verify rfmode not found message');
    };

    subtest 'rfmode set to Lacrosse_mode1' => sub {
      my $ret = SIGNALduino_Attr_rfmode($defs{cc1101dummyDuino},'Lacrosse_mode1');  
      is($ret,U(),q[verify return undef ]);
      is(FhemTestUtils_gotLog(".*rfmode found on.*"), 1, 'Verify rfmode is found');
      is(FhemTestUtils_gotLog(".*register settings exist.*"), 1, 'Verify registers settinx exist');
      is(FhemTestUtils_gotLog(".*write value.*"), 27, 'Verify write value');
    }; 

    subtest 'rfmode set to Lacrosse_mode1 without protocol id enabled' => sub {
      CommandAttr(undef, qq[cc1101dummyDuino whitelist_IDs 1]);    
      my $ret = SIGNALduino_Attr_rfmode($defs{cc1101dummyDuino},'Lacrosse_mode1');  
      is($ret,U(),q[verify return undef ]);
      is(FhemTestUtils_gotLog(".*no MN protocols in 'Display protocollist' activated.*"), 1, 'Verify no MN protocol activated');
    };
  };

  done_testing();
  exit(0);

}, 0);

1;