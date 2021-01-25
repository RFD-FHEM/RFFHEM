#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is item U D match hash array bag};
use Mock::Sub;
use Test2::Todo;



my @mockData = (
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MS data, special chars],
        input =>  q[MS;�=0;L=L=-1020;L=H=935;S=L=-525;S=H=444;D=354133323044313642333731303246303541423044364430;C==487;L==89;R==24;],
        rValue => U(), 
        todoReason => q[This data should not be processed]

    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MC data, special char and structure broken],
        input =>  q[MS;P1=;L=L=-1015;L=H=944;S=L=-512;S=H=456;D=353531313436304235313330433137433244353036423130;C==487;L==89;R==45;],
        rValue => U(), 
        todoReason => q[This data should not be processed]

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
      my %signal_parts=SIGNALduino_Split_Message($element->{input},$element->{deviceName});   
      
      my $ret = SIGNALduino_Parse_MS($targetHash,$targetHash,$element->{deviceName},$element->{input},%signal_parts);
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