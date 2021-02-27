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
        plan        =>  2,
        testname    =>  q[Corrupt MS data, special chars],
        input       =>  q[MS;�=0;L=L=-1020;L=H=935;S=L=-525;S=H=444;D=354133323044313642333731303246303541423044364430;C==487;L==89;R==24;],
        rValue      =>  U(), 
        todoReason  =>  q[this test fails, because log3 can't handle utf8. this needs utf8::all cpanm module or something else]
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MS data, special char and structure broken],
        input =>  q[MS;P1=;L=L=-1015;L=H=944;S=L=-512;S=H=456;D=353531313436304235313330433137433244353036423130;C==487;L==89;R==45;],
        rValue => U(), 
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MS data, R= Argument "1q" isn't numeric],
        input =>  q[MS;P1=-8043;P2=505;P3=-1979;P4=-3960;D=2121232323242424232423242323232323242324232424232324242323232323232323232323232323242423;CP=2;SP=1;R=1q;],
        rValue => U(), 
    },
    {
        deviceName =>  q[dummyDuino],
        plan       =>  2,
        testname   =>  q[Correct MC CUL_TCM_97001],
        input      =>  q[MS;P1=502;P2=-9212;P3=-1939;P4=-3669;D=12131413141414131313131313141313131313131314141414141413131313141413131413;CP=1;SP=2;],
        rValue     =>  T()
    },
);
plan (scalar @mockData );  

InternalTimer(time()+1, sub() {
  while (@mockData)
  {
    my $element = pop(@mockData);
    next if (!exists($element->{testname}));
    FhemTestUtils_resetLogs();
    #CommandAttr(undef,"$element->{deviceName} debug 1");

    my $targetHash = $defs{$element->{deviceName}};
    my $todo =  (exists($element->{todoReason})) 
      ? Test2::Todo->new(reason => $element->{todoReason})
      : undef;

    subtest "checking $element->{testname} on $element->{deviceName}" => sub {
      my $p = $element->{plan} // 1;
      plan ($p);  
      my $ret = SIGNALduino_Parse_MS($targetHash,$element->{input});
      for my $i (1..$p)
      {
        $i == 1 && do { is($ret,$element->{rValue},'Verify return value for SIGNALduino_Parse_MS') } ;
        $i == 2 && do { is(FhemTestUtils_gotLog('PERL WARNING:'), 0, 'No Warnings in logfile'); } ;
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