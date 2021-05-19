#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is field U D match hash bag };
use Mock::Sub;
use Test2::Todo;

our %defs;
our %attr;
# Mock cc1101 
$defs{cc1101dummyDuino}{cc1101_available} = 1;


#SIGNALduino_Set_sendMsg $hash set P0#0101#R3#C500
# ->Split into  ($protocol,$data,$repeats,$clock,$frequency);
# catch SIGNALduino_AddSendQueue
my @mockData = (
  {
    cmd => q[set],
    deviceName => q[dummyDuino],
    plan => 2,
    testname =>  q[unsupported attr cc1101_reg_user nonHex],
    input =>  q[cc1101_reg_user nonHex],
    attrCheck =>  hash  {
        field cc1101_reg_user => DNE();
        etc();
      },
      rValue => match qr/only available for a receiver with CC1101/,  
  },
  {
  #   todoReason => "reason",
    cmd => q[set],
    deviceName => q[cc1101dummyDuino],
    plan => 2,
    testname =>  q[nonex value for attr cc1101_reg_user nonHex],
    input =>  q[cc1101_reg_user nonHex],
    attrCheck =>  hash  {
        field cc1101_reg_user => DNE();
        etc();
      },
      rValue => match qr/ERROR: Your attribute value is wrong/,
  },
  {
    cmd => q[set],
    deviceName => q[cc1101dummyDuino],
    plan => 2,
    testname =>  q[wrong hex value for attr cc1101_reg_user 30AF],
    input =>  q[cc1101_reg_user 30AF],
    attrCheck =>  hash  {
        field cc1101_reg_user => DNE();
        etc();
    },
      rValue => match qr/ERROR: Your attribute value is wrong/,
  },
  {
    cmd => q[set],
    deviceName => q[cc1101dummyDuino],
    plan => 2,
    testname =>  q[hex value for attr cc1101_reg_user 10AF],
    input =>  q[cc1101_reg_user 10AF],
    attrCheck =>  hash  {
        field cc1101_reg_user => '10AF';
        etc();
        },
      rValue => U(),
  },
  {
    cmd => q[set],
    deviceName => q[cc1101dummyDuino],
    plan => 2,
    testname =>  q[unsupported mode attr rfmode blafasel],
    input =>  q[rfmode blafasel],
    attrCheck =>  hash  {
        field rfmode => DNE;
        etc();
        },
      rValue => 'ERROR: The rfmode is not supported',
  },
  {
    cmd => q[set],
    deviceName => q[cc1101dummyDuino],
    plan => 2,
    testname =>  q[unsupported mode attr rfmode Lacrosse],
    input =>  q[rfmode Lacrosse],
    attrCheck =>  hash  {
        field rfmode => DNE;
        etc();
        },
      rValue => 'ERROR: The rfmode is not supported',
  },
  {
    cmd => q[set],
    deviceName => q[cc1101dummyDuino],
    plan => 3,
    testname =>  q[supported mode attr rfmode SlowRF],
    input =>  q[rfmode SlowRF],
    attrCheck =>  hash  {
        field rfmode => 'SlowRF';
        etc();
      },
    hashCheck =>  hash  {
        field QUEUE => bag { item 'e'; etc() ; };
        etc();
      },
      rValue => U(),
  },
  {
    cmd => q[set],
    deviceName => q[cc1101dummyDuino],
    plan => 3,
    testname =>  q[supported mode change attr rfmode from HomeMatic to SlowRF],
    input =>  q[rfmode SlowRF],
    pre_code => sub {
      CommandAttr(undef, qq[cc1101dummyDuino rfmode HomeMatic]);
    },
    attrCheck =>  hash  {
        field rfmode => 'SlowRF';
        etc();
        },
    hashCheck =>  hash  {
        field QUEUE => bag { item 'e'; etc() ; };
        etc();
        },
      rValue => U(),
  },
);
plan (scalar @mockData + 2);  

my ($mock);

BEGIN {
  $mock = Mock::Sub->new;
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
    #my $targetHash = $defs{$element->{deviceName}};
    my $todo =  (exists($element->{todoReason})) 
      ? Test2::Todo->new(reason => $element->{todoReason})
      : undef;

    $element->{pre_code}->() if (exists($element->{pre_code}));
    #$todo=$element->{todo}->() if (exists($element->{todo}));

    subtest "checking $element->{testname} on $element->{deviceName}" => sub {
      my $p = $element->{plan} // 4;
      plan ($p);

      my ($attrname,$value) = split(" ",$element->{input});
      if (!exists $element->{pre_code}) {
        delete $attr{$element->{deviceName}}{$attrname}; 
        delete $defs{$element->{deviceName}}{QUEUE}; 
      }

      for my $i (1..$p)
      {
        $i == 1 && do {
          my $ret = SIGNALduino_Attr($element->{cmd},$element->{deviceName},$attrname,$value);
          is($ret,$element->{rValue},"Verify return value");
          next;
        };
        $i == 2 && do {
          CommandAttr(undef, qq[$element->{deviceName} $element->{input}]);
          is($attr{$element->{deviceName}},$element->{attrCheck},'Verify $attr content');
          next;
        };
        $i == 3 && do {
          is($defs{$element->{deviceName}},$element->{hashCheck},'Verify $hash content');
          next;
        };
      }
    };
    if (defined($todo)) {
      $todo->end;
    }

    #$element->{post_code}->() if (exists($element->{post_code}));

  };

  done_testing();
  exit(0);

}, 0);

1;