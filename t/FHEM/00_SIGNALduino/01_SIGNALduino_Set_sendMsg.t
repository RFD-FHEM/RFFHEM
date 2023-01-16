#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is item U D match hash array bag};
use Mock::Sub;
use Test2::Todo;

# Mock cc1101 
$defs{cc1101dummyDuino}{cc1101_available} = 1;


#SIGNALduino_Set_sendMsg $hash set P0#0101#R3#C500
# ->Split into  ($protocol,$data,$repeats,$clock,$frequency);
# catch SIGNALduino_AddSendQueue
    my @mockData = (
    {
      deviceName => q[dummyDuino],
      plan => 1,
      testname =>  q[Unknown protocol set sendMsg ID:109990 (P109990#0101#R3#C500)],
      input =>  q[sendMsg P109990#0101#R3#C500],
      check =>  array  {
          item D();
            item 'SR;R=3;P0=500;P1=-8000;P2=-3500;P3=-1500;D=0103020302;';
          },
        rValue => match qr/unknown protocol/, 
    },
    {
  #   todoReason => "reason",
      deviceName => q[dummyDuino],
      testname =>  q[set sendMsg ID:0 (P0#0101#R3#C500)],
      input =>  q[sendMsg P0#0101#R3#C500],
      check =>  array  {
          item D();
            item 'SR;R=3;P0=500;P1=-8000;P2=-3500;P3=-1500;D=0103020302;';
          },
    },
    {
  #   todoReason => "reason",
      deviceName => q[cc1101dummyDuino],
      testname =>  q[set sendMsg ID:0 (P0#0101#R3#C500)],
      input =>  q[sendMsg P0#0101#R3#C500],
      check =>  array  {
          item D();
            item 'SR;R=3;P0=500;P1=-8000;P2=-3500;P3=-1500;D=0103020302;';
          },
    },
    {
      deviceName => q[dummyDuino],
      testname=>  "set sendMsg ID:17 (P17#0101#R3#C500)",
      input =>  "sendMsg P17#0101#R3#C500",
      check =>  array {
            item D();
            item 'SR;R=3;P0=500;P1=-5000;P2=-2500;P3=-500;P4=-20000;D=01030202030302020304;';
          },
       
    },
    {
      deviceName => q[dummyDuino],
      testname=>  "set sendMsg ID:29 (P29#0xF7E#R4)",
      input =>  "sendMsg P29#0xF7E#R4",
      check =>  array  {
          item D();
            item 'SR;R=4;P0=-8225;P1=235;P2=-470;P3=-235;P4=470;D=01212121213421212121212134;';
          },  
    },
    {
      deviceName => q[cc1101dummyDuino],
        testname=>  "set sendMsg ID:43 (P43#0101#R3#C500) with default frequency",
      input =>  "sendMsg P43#0101#R3#C500",
      check =>  array  {
          item D();
            item 'SC;R=3;SR;P0=-2560;P1=2560;P3=-640;D=10101010101010113;SM;C=895;D=0101;F=10AB85550A;';
        },
    },
    {
      deviceName => q[dummyDuino],
      testname=>  "set sendMsg ID:43 (P43#0101#R3#C500#F10AB855530) with custom frequency but without cc1101",
      input =>  "sendMsg P43#0101#R3#C500#F10AB855530",
      check =>  array  {
            item D();
            item 'SC;R=3;SR;P0=-2560;P1=2560;P3=-640;D=10101010101010113;SM;C=895;D=0101;';
        },
    },
    {
      deviceName => q[cc1101dummyDuino],
      testname=>  "set sendMsg ID:43 (P43#0101#R3#C500#F10AB855530) with custom frequency",
      input =>  "sendMsg P43#0101#R3#C500#F10AB855530",
      check =>  array  {
            item D();
            item 'SC;R=3;SR;P0=-2560;P1=2560;P3=-640;D=10101010101010113;SM;C=895;D=0101;F=10AB855530;';
        },
    },
    {
      deviceName => q[cc1101dummyDuino],
        testname=>  "set sendMsg ID:3 (P3#is11111F0FF00F#R6) with 433.89 MhZ frequency",
      input =>  "sendMsg P3#is11111F0FF0F0#R6#F10b025",
      check =>  array  {
          item D();
            item 'SR;R=6;P0=250;P1=-7750;P2=750;P3=-250;P4=-750;D=01232323232323232323230423040404230423040404230404;F=10b025;';
        },
    },
    {
      deviceName => q[cc1101dummyDuino],
        testname =>  "set sendMsg ID:112 (P112#0101#R1) xFSK protocol",
           input =>  "sendMsg P112#08C114844#R1",
           check =>  array  {
           item D();
             item 'SN;R=1;D=08C114844;';
        },
    },

  );
  plan (scalar @mockData + 2);  

my ($mock, $SIGNALduino_AddSendQueue);

BEGIN {
  $mock = Mock::Sub->new;
  $SIGNALduino_AddSendQueue = $mock->mock('main::SIGNALduino_AddSendQueue');
};

InternalTimer(time()+1, sub() {
  is($defs{cc1101dummyDuino},hash {
      field cc1101_available => 1; 
      etc();
    },
    'check mocked cc1101dummyDuino hash');
  is($defs{dummyDuino},hash   {
      field cc1101_available => U(); 
      etc();
    },
    'check mocked dummyDuino hash');

  while (@mockData)
  {
    my $element = pop(@mockData);
    next if (!exists($element->{testname}));
    my $targetHash = $defs{$element->{deviceName}};
    my $todo =  (exists($element->{todoReason})) 
      ? Test2::Todo->new(reason => $element->{todoReason})
      : undef;
    #$element->{pre_code}->() if (exists($element->{pre_code}));
    #$todo=$element->{todo}->() if (exists($element->{todo}));

    subtest "checking $element->{testname} on $element->{deviceName}" => sub {
      my $p = $element->{plan} // 4;
      plan ($p);  

      my $ret = SIGNALduino_Set_sendMsg($targetHash,split(" ",$element->{input}));
      for my $i (1..$p)
      {
        $i == 1 && do { is($ret,$element->{rValue},"Verify return value") } ;
        $i == 2 && do { is($SIGNALduino_AddSendQueue->called,1,"Verify SIGNALduino_AddSendQueue is called") };
        $i == 3 && do {
          is($SIGNALduino_AddSendQueue->called,1,"Verify SIGNALduino_AddSendQueue is called");
          my @called_args = $SIGNALduino_AddSendQueue->called_with;
          is(\@called_args,$element->{check},"Verify SIGNALduino_AddSendQueue parameters");
        };
      }

      $SIGNALduino_AddSendQueue->reset;
    };
    if (defined($todo)) {
      $todo->end;
    }

    #$element->{post_code}->() if (exists($element->{post_code}));

  };
  $SIGNALduino_AddSendQueue->unmock;

  done_testing();
  exit(0);

}, 0);

1;