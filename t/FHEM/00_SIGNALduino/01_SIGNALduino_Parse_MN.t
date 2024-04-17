#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is item U D match hash array bag};
use Test2::Todo;



our %defs;
our %modules;

my @mockData = (
    {
        deviceName   => q[dummyDuino],
        plan         => 2,
        testname     => q[Good MN data],
        input        => q[MN;D=9AA6362CC8AAAA000012F8F4;R=4;],
        rValue       => T(), 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Corrupt MN data, corrupt D=],
        input       => q[MN;D=9AA63&2CC8AAAA000012F8F4;R=4;],
        rValue      => U(), 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Corrupt MN data, wrong delimiter ],
        input       => q[MN;D=9AA63&2CC8AAAA000012F8F4:R=4;],
        rValue      => U(), 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Corrupt MN data, no D=  ],
        input       => q[MN;;R=4;],
        rValue      => U(), 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Good MN data, without RSSI],
        input       => q[MN;D=9AA63&2CC8AAAA000012F8F4;],
        rValue      => U(), 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Good MN data, with RSSI, but without set attribute rfmode],
        input       => q[MN;D=9AA6362CC8AAAA000012F8F4;R=4;],
        rValue      => T(), 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Good MN data, with RSSI, but without set attribute rfmode],
        input       => q[MN;D=0405019E8700AAAAAAAA0F13AA16ACC0540AAA49C814473A2774D208AC0B0167;R=6;],
        rValue      => T(), 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Good MN data, without RSSI, but without set attribute rfmode],
        input       => q[MN;D=07FA5E1721CC0F02FE000000000000;],
        rValue      => T(), 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Good MN data, with RSSI, with set attribute rfmode=Lacrosse_mode1],
        input       => q[MN;D=9AA6362CC8AAAA000012F8F4;R=4;],
        rValue      => T(),
        rfmode      => 'Lacrosse_mode1' 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Good MN data, without RSSI, with set attribute rfmode=PCA301],
        input       => q[MN;D=0405019E8700AAAAAAAA0F13AA16ACC0540AAA49C814473A2774D208AC0B0167;R=6;],
        rValue      => 3,
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
        input       => q[MN;D=9A05922F8180046818480800;],
        rValue      => T(),
        rfmode      => 'Lacrosse_mode2' 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Good MN data, with RSSI, but not matching regex],
        input       => q[MN;D=8AA6362CC8AAAA000012F8F4;R=4;],
        rValue      => 0,
        rfmode      => 'Lacrosse_mode2' 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[message to short],
        input       => q[MN;D=01050;],
        rValue      => 0,
        rfmode      => 'Lacrosse_mode2' 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[message ok],
        input       => q[MN;D=3BF120B00C1618FF77FF0458152293FFF06B0000;R=242;],
        rValue      => 1,
        rfmode      => 'Bresser_6in1' 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[message ok with FREQEST],
        input       => q[MN;D=3BF120B00C1618FF77FF0458152293FFF06B0000;R=210;A=235;],
        rValue      => 1,
        rfmode      => 'Bresser_6in1' 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[message ok with negative FREQEST],
        input       => q[MN;D=3BF120B00C1618FF77FF0458152293FFF06B0000;R=210;A=-35;],
        rValue      => 1,
        rfmode      => 'Bresser_6in1' 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Good MN data, with RSSI, with set attribute rfmode=WMBus_T, Medium OMS MUC, DMSG started with b],
        input       => q[MN;D=2547F536721602000231D27C7A000008000F80130001090086B41E00175914011B0806020400000000001945000E;R=14;A=0;],
        rValue      => 2,
        rfmode      => 'WMBus_T' 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Good MN data, with RSSI, with set attribute rfmode=WMBus_T, Medium Heat Cost Allocator, DMSG started with b],
        input       => q[MN;D=3E44F53611275600010884B57AA9002025D27FDD54048072F9A9D06C2E2E5249A41E363DE1F27AF3DE4DD325507C67A9E33CDDC4A70F800C0001090086B41E0063B414011E070416C500FC;R=252;A=0;],
        rValue      => 2,
        rfmode      => 'WMBus_T' 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Good MN data, with RSSI, with set attribute rfmode=WMBus_T, Medium Cold water, DMSG started with bY],
        input       => q[MN;D=Y25442D2C769390751B168D20955084E7204D4874442AA58272A51FCE1430C0A769C3BEF95A2096D1;R=209;A=-6;],
        rValue      => 2,
        rfmode      => 'WMBus_T' 
    },
    {
        deviceName  => q[dummyDuino],
        plan        => 2,
        testname    => q[Good MN data, with RSSI, with set attribute rfmode=WMBus_T, Medium Heat Cost Allocator, DMSG started with bY],
        input       => q[MN;D=Y304497264202231800087A2A0020A53848C8EA9DD3055EA724A2E2AE04E995205589AADC82F6305A620959E6424F406B3B00F6;R=246;A=0;],
        rValue      => 2,
        rfmode      => 'WMBus_T' 
    },
);


plan (scalar @mockData);  

InternalTimer(time()+0.9, sub() {
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
      
      my $ret = SIGNALduino_Parse_MN($targetHash,$element->{input});
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