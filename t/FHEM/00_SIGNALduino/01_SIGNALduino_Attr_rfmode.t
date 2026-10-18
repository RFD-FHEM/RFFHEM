#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is item U D like hash array bag match end};
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
    like($ret,qr/This rfmode is only available for a receiver with CC1101/,q[verify error message if not a cc1101 device]);
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
      is($ret,q[ERROR: protocol blafasel is not activated in 'Display protocollist'],q[verify return is not activated ]);
      is(FhemTestUtils_gotLog(".*rfmode value not found in protocols.*"), 1, 'Verify rfmode not found message');
    };

    subtest 'rfmode set to Lacrosse_mode1' => sub {
      my $ret = SIGNALduino_Attr_rfmode($defs{cc1101dummyDuino},'Lacrosse_mode1');  
      is($ret,U(),q[verify return undef ]);
      is(FhemTestUtils_gotLog(".*rfmode found on.*"), 1, 'Verify rfmode is found');
      is(FhemTestUtils_gotLog(".*register settings exist.*"), 1, 'Verify registers settinx exist');
      is(FhemTestUtils_gotLog(".*write value.*"), 20, 'Verify write value');
    }; 

    subtest 'rfmode set to Lacrosse_mode1 without protocol id enabled' => sub {
      CommandAttr(undef, qq[cc1101dummyDuino whitelist_IDs 1]);    
      my $ret = SIGNALduino_Attr_rfmode($defs{cc1101dummyDuino},'Lacrosse_mode1');  
      is($ret,q[ERROR: no MN protocols activated in 'Display protocollist'],q[verify return without id enabled ]);
      is(FhemTestUtils_gotLog(".*no MN protocols in 'Display protocollist' activated.*"), 1, 'Verify no MN protocol activated');
    };
  };

  subtest 'rfmode temporary (volatile) on initalized cc1101dummyDuino receiver' => sub {
    my $hash = $defs{cc1101dummyDuino};
    CommandDeleteAttr(undef, qq[cc1101dummyDuino whitelist_IDs]);
    CommandAttr(undef, qq[cc1101dummyDuino hardware esp32cc1101]);
    $hash->{cc1101_volatile} = 1;   # firmware supports w, CV and WR

    subtest 'Attr_rfmode persistent writes EEPROM commands' => sub {
      delete $hash->{QUEUE};
      my $ret = SIGNALduino_Attr_rfmode($hash,'WMBus_T');
      is($ret,U(),q[verify return undef]);
      is($hash->{QUEUE}, array {
          item 'CDW';
          item 'WS36';
          item 'WS3A';
          item match qr/^W[0-9A-F]{4}$/ for 1..23;
          item 'WS36';
          item 'WS3A';
          item 'WS34';
          item 'CET';
          item 'CEW';
          end();
        }, 'verify sendqueue uses W and C commands');
    };

    subtest 'set rfmodeTemp WMBus_T' => sub {
      delete $hash->{QUEUE};
      my $ret = SIGNALduino_Set($hash,'cc1101dummyDuino','rfmodeTemp','WMBus_T');
      is($ret,U(),q[verify return undef]);
      is($hash->{QUEUE}, array {
          item 'CVDW';
          item 'WS36';
          item 'WS3A';
          item 'w0206';
          item match qr/^w[0-9A-F]{4}$/ for 1..22;
          item 'WS36';
          item 'WS3A';
          item 'WS34';
          item 'CVET';
          item 'CVEW';
          end();
        }, 'verify sendqueue uses only volatile commands');
      is($hash->{rfmodeTemp},'WMBus_T',q[verify internal rfmodeTemp]);
      is(AttrVal('cc1101dummyDuino','rfmode',undef),U(),q[verify attribute rfmode is not changed]);
    };

    subtest 'set rfmodeTemp SlowRF' => sub {
      delete $hash->{QUEUE};
      my $ret = SIGNALduino_Set($hash,'cc1101dummyDuino','rfmodeTemp','SlowRF');
      is($ret,U(),q[verify return undef]);
      # default register values of the firmware (cc1101::initVal), EEPROM address = register + 2
      is($hash->{QUEUE}, array {
          item 'CVDW';
          item 'WS36';
          item 'WS3A';
          item $_ for qw(w020D w032E w042D w0547 w06D3 w0791 w083D w0904);
          item $_ for qw(w0A32 w0B00 w0C00 w0D06 w0E00 w0F10 w10B0 w1171);
          item $_ for qw(w1257 w13C4 w1430 w1523 w16B9 w1700 w1807 w1900);
          item $_ for qw(w1A18 w1B14 w1C6C w1D07 w1E00 w1F91 w2087 w216B);
          item $_ for qw(w22F8 w23B6 w2411 w25E9 w262A w2700 w281F w2941);
          item $_ for qw(w2A00);
          item 'WS36';
          item 'WS3A';
          item 'WS34';
          end();
        }, 'verify sendqueue writes the default registers without factory reset');
      is($hash->{rfmodeTemp},'SlowRF',q[verify internal rfmodeTemp]);
    };

    subtest 'set rfmodeTemp on not initialized receiver' => sub {
      delete $hash->{QUEUE};
      delete $hash->{rfmodeTemp};
      $hash->{DevState} = 'waitInit';
      my $ret = SIGNALduino_Set($hash,'cc1101dummyDuino','rfmodeTemp','WMBus_T');
      $hash->{DevState} = 'initialized';
      like($ret,qr/is not active/,q[verify error message from SIGNALduino_Set]);
      is($hash->{QUEUE},U(),q[verify sendqueue is empty]);
      is($hash->{rfmodeTemp},U(),q[verify internal rfmodeTemp is not set]);
    };

    subtest 'set rfmodeTemp blafasel' => sub {
      my $ret = SIGNALduino_Set($hash,'cc1101dummyDuino','rfmodeTemp','blafasel');
      is($ret,q[ERROR: The rfmode is not supported],q[verify error message]);
    };

    subtest 'set rfmodeTemp without argument' => sub {
      my $ret = SIGNALduino_Set($hash,'cc1101dummyDuino','rfmodeTemp');
      is($ret,q[ERROR: missing rfmode],q[verify error message]);
    };

    subtest 'set rfmodeRestore' => sub {
      delete $hash->{QUEUE};
      my $ret = SIGNALduino_Set($hash,'cc1101dummyDuino','rfmodeRestore');
      is($ret,U(),q[verify return undef]);
      is($hash->{QUEUE}, array { item 'WR'; end(); }, 'verify sendqueue has WR command');
      is($hash->{rfmodeTemp},U(),q[verify internal rfmodeTemp is removed]);
    };

    subtest 'firmware without w, CV and WR' => sub {
      delete $hash->{QUEUE};
      delete $hash->{rfmodeTemp};
      $hash->{cc1101_volatile} = 0;
      my $ret = SIGNALduino_Set($hash,'cc1101dummyDuino','rfmodeTemp','WMBus_T');
      like($ret,qr/firmware does not support a temporary rfmode/,q[verify error message rfmodeTemp]);
      $ret = SIGNALduino_Set($hash,'cc1101dummyDuino','rfmodeRestore');
      like($ret,qr/firmware does not support a temporary rfmode/,q[verify error message rfmodeRestore]);
      is($hash->{QUEUE},U(),q[verify sendqueue is empty]);
      is($hash->{rfmodeTemp},U(),q[verify internal rfmodeTemp is not set]);
      $hash->{cc1101_volatile} = 1;
    };

    subtest 'set rfmodeRestore without cc1101' => sub {
      my $ret = SIGNALduino_Set_rfmodeRestore($defs{dummyDuino},'rfmodeRestore');
      like($ret,qr/only available for a receiver with CC1101/,q[verify error message]);
    };

    subtest 'set rfmodeTemp without cc1101' => sub {
      my $ret = SIGNALduino_Set_rfmodeTemp($defs{someDuino},'rfmodeTemp','WMBus_T');
      like($ret,qr/only available for a receiver with CC1101/,q[verify error message]);
    };
    delete $hash->{QUEUE};
  };

  done_testing();
  exit(0);

}, 0);

1;