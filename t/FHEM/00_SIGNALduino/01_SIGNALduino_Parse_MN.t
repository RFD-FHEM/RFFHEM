#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is item U D match hash array bag};
use Test2::Todo;


our %defs;

my @mockData = (
    {
        deviceName   => q[dummyDuino],
        plan         => 2,
        testname     => q[Good MN data],
        input        => q[MN;D=9AA6362CC8AAAA000012F8F4;R=4;],
        rValue       => U(), 
        todoReason   => q[This data should not be processed]
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Corrupt MN data, corrupt D=],
        input       => q[MN;D=9AA63&2CC8AAAA000012F8F4;R=4;],
        rValue      => U(), 
        todoReason  => q[This data should not be processed]
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Corrupt MN data, wrong delimiter ],
        input       => q[MN;D=9AA63&2CC8AAAA000012F8F4:R=4;],
        rValue      => U(), 
        todoReason  => q[This data should not be processed]
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Corrupt MN data, no D=  ],
        input       => q[MN;;R=4;],
        rValue      => U(), 
        todoReason  => q[This data should not be processed]
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Good MN data, without RSSI],
        input       => q[MN;D=9AA63&2CC8AAAA000012F8F4;],
        rValue      => U(), 
        todoReason  => q[This data should not be processed]
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Good MN data, without RSSI, but without set attribute rfmode],
        input       => q[MN;D=9AA6362CC8AAAA000012F8F4;R=4;],
        rValue      => F(), 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Good MN data, without RSSI, but without set attribute rfmode],
        input       => q[MN;D=0405019E8700AAAAAAAA0F13AA16ACC0540AAA49C814473A2774D208AC0B0167;N=3;R=6;],
        rValue      => F(), 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Good MN data, without RSSI, but without set attribute rfmode],
        input       => q[MN;D=07FA5E1721CC0F02FE000000000000;],
        rValue      => F(), 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Good MN data, without RSSI, with set attribute rfmode=Lacrosse_mode1],
        input       => q[MN;D=9AA6362CC8AAAA000012F8F4;R=4;],
        rValue      => 1,
        rfmode      => 'Lacrosse_mode1' 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Good MN data, without RSSI, with set attribute rfmode=PCA301],
        input       => q[MN;D=0405019E8700AAAAAAAA0F13AA16ACC0540AAA49C814473A2774D208AC0B0167;N=3;R=6;],
        rValue      => 1,
        rfmode      => 'PCA301' 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Good MN data, without RSSI, with set attribute rfmode=KOPP_FC],
        input       => q[MN;D=07FA5E1721CC0F02FE000000000000;],
        rValue      => 1,
        rfmode      => 'KOPP_FC' 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Good MN data, without RSSI, with set attribute rfmode=Lacrosse_mode2],
        input       => q[MN;D=9A05922F8180046818480800;N=2;],
        rValue      => 1,
        rfmode      => 'Lacrosse_mode2' 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Good MN data, without RSSI, but not matching regex],
        input       => q[MN;D=8AA6362CC8AAAA000012F8F4;R=4;],
        rValue      => 0,
        rfmode      => 'Lacrosse_mode2' 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[message to short],
        input       => q[MN;D=01050;N=3;],
        rValue      => 0,
        rfmode      => 'Lacrosse_mode2' 
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

    CommandAttr(undef, $element->{deviceName}.' rfmode '.$element->{rfmode} ) if ( defined $element->{rfmode} );

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
    CommandDeleteAttr(undef, $element->{deviceName}.' rfmode' ) if ( defined $element->{rfmode} );

  };

  done_testing();
  exit(0);

}, 0);

1;