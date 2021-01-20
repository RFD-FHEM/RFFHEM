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
        testname =>  q[Good MN data],
        input =>  q[MN;D=9AA6362CC8AAAA000012F8F4;R=4;],
        rValue => U(), 
        todoReason => q[This data should not be processed]
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MN data, corrupt D=],
        input =>  q[MN;D=9AA63&2CC8AAAA000012F8F4;R=4;],
        rValue => U(), 
        todoReason => q[This data should not be processed]
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MN data, wrong delimiter ],
        input =>  q[MN;D=9AA63&2CC8AAAA000012F8F4:R=4;],
        rValue => U(), 
        todoReason => q[This data should not be processed]
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MN data, no D=  ],
        input =>  q[MN;;R=4;],
        rValue => U(), 
        todoReason => q[This data should not be processed]
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Good MN data, without RSSI],
        input =>  q[MN;D=9AA63&2CC8AAAA000012F8F4;],
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
      
      my $ret = SIGNALduino_Parse_MN($targetHash,$element->{input},\%signal_parts);
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