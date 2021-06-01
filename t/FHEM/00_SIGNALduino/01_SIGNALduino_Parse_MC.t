#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is item U D match hash array bag};
use Test2::Todo;


our %defs;

my @mockData = (
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MC data, special chars],
        input =>  q[MC;LL=-2883;LH=2982;��j����ښ!�1509;D=AF7EFF2E;C=1466;L=31;R=14;],
        rValue => U(), 
        todoReason => q[This data should not be processed]
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MC data, special char in pattern specifier],
        input =>  q[MC;LL=-2895;LH=2976;S�=-1401;SH=1685;D=AFBEFFCE;C=1492;L=31;R=23;],
        rValue => U(), 
        todoReason => q[This data should not be processed]

    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MC data, wrong delimiter],
        input =>  q[MC;LL=-2901;LH=2958{SL=-1412;SH=1509;D=AFBEFFCE;C=1463;L=31;R=17;],
        rValue => U(), 
        todoReason => q[This data should not be processed]
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MC data, pattern specifier duplicated],
        input =>  q[MC;LH=-2889;LH=2963;SL=-1420;SH=1514;D=AF377F87;C=1464;L=32;R=11;],
        rValue => U(), 
        todoReason => q[This data should not be processed]
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MC data, delimiter wrong],
        input =>  q[MC;LL=-2872:LH=2985;SL=-1401;SH=1527;D=AFFB7F2B;C=1464;L=32;R=10;],
        rValue => U(), 
        todoReason => q[This data should not be processed]
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MC data, special chars in pattern specifier],
        input =>  q[MC;LL=-2868;LHO&��ښ1�-1416;SH=1525;D=AFBB7F4B;C=1468;L=32;R=16;],
        rValue => U(), 
        todoReason => q[This data should not be processed]
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MC data, data isn't hexadezimal],
        input =>  q[MC;LL=-2738;LH=3121;SL=-1268;SH=1667;D=GGD9FF0E;C=1465;L=32;R=246;],
        rValue => U(), 
        todoReason => q[This data should not be processed]
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[To long MC data (protocol 57)],
        input =>  q[MC;LL=-762;LH=544;SL=-402;SH=345;D=DB6D5B54;C=342;L=30;R=32;],
        rValue => U(), 
        todoReason => q[This data should not be processed / dispatched]
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[To short MC data (protocol 57)],
        input =>  q[MC;LL=-762;LH=544;SL=-402;SH=345;D=DB6;C=342;L=12;R=32;],
        rValue => U(), 
        todoReason => q[This data should not be processed / dispatched]
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Good MC Data (protocol 57)],
        input =>  q[MC;LL=-653;LH=679;SL=-310;SH=351;D=D55B58;C=332;L=21;],
        rValue => 1, 
    },

);
plan (scalar @mockData );  

BEGIN {
};

InternalTimer(time()+1, sub() {
  while (@mockData)
  {
    my $element = pop(@mockData);
    next if (!exists($element->{testname}));
    FhemTestUtils_resetLogs();

    my $targetHash = $defs{$element->{deviceName}};
    my $todo =  (exists($element->{todoReason})) 
      ? Test2::Todo->new(reason => $element->{todoReason})
      : undef;

    subtest "checking $element->{testname} on $element->{deviceName}" => sub {
      my $p = $element->{plan} // 1;
      plan ($p);  
      
      my $ret = SIGNALduino_Parse_MC($targetHash,$element->{input});
      for my $i (1..$p)
      {
        $i == 1 && do { is($ret,$element->{rValue},"Verify return value") } ;
        $i == 2 && do { is(FhemTestUtils_gotLog("PERL WARNING:"), 0, "No Warnings in logfile"); } ;
      }

    };
    if (defined($todo)) {
      $todo->end;
    }

  };
 
  done_testing();
  exit(0);

}, 0);

1;