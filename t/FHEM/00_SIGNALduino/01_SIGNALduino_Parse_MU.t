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
        testname =>  q[Corrupt Mu data, combined message],
        input =>  q[MU;P0=-2272;P1=228;P2=-356;P3=635;P4=-562;P5=433;D=012345234345252343452523434345252345234343434523434345252343452525252525234523452343452345252525;CP=5;R=4�;P3=;L=L=-2864;L=H=2980;S=L=-1444;S=H=1509;D=354146333737463037;C==1466;L==32;R==9;],
        rValue => U(),
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MU data, unknown specifier V=],
        input =>  q[MU;P0=-1440;P1=432;P2=-357;P3=635;P4=-559;D=012121212123412343412123434121234343412123412343434341234343412123434121212121212341231212343412341212121;CP=1;V=139;],
        rValue => U(), 
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MU data, missing D= part],
        input =>  q[MU;P0=-370;P1=632;P2=112;P3=-555;P4=428;P5=-780;P6=180;P7=-200;CP=4;R=77;],
        rValue => U(), 
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MU data, D= is to short (min two pattern)],
        input =>  q[MU;P0=-370;P1=632;P2=112;P3=-555;P4=428;P5=-780;P6=180;P7=-200;D=1;CP=4;R=77;],
        rValue => U(), 
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MU data, C= has letters ],
        input =>  q[MU;P0=536;P1=-1443;P2=1486;P3=-4208;P4=5776;P5=-6700;P6=2972;P7=-2880;D=01212121212121212123456767212121212121672167212121212121212121672167672;C=23RB;],
        rValue => U(), 
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MU data, wrong delemiter =],
        input =>  q[MU;P0=536;P1=-1443;P2=1486;P3=-4208;P4=5776;P5=-6700;P6=2972;P7=-2880;D=01212121212121212123456767212121212121672167212121212121212121672167672=C=23;],
        rValue => U(), 
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MU data, D= isn't numeric],
        input =>  q[MU;P0=-16320;P1=394;P2=-400;P5=628;P6=-625;D=0121212121212121212121212561A1256121212121256121256125656C212561256561256121256121256565612565656121212125612125612121256121256125612561;CP=1;R=84;],
        rValue => U(), 
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MU data, R= Argument "1q" isn't numeric],
        input =>  q[MU;P0=439;P1=-196;P3=-356;P4=634;P5=-556;P6=-7244;D=010303030303030303030303034503454503034545030345454503034503454545450345454503034545030303030345030345034545034503454506;CP=0;R=1q;],
        rValue => U(), 
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MU data, with MC part and control characters],
        input =>  q[MU;P0=-592;P1=251;P2=616;P3=-236;P4=844;P5=-860;=0;L=L=-1011;L=H=932;S=L=-529;S=H=444;D=353531454536304235313743433137434541423041444630;C==485;L==89;R==38;],
        rValue => U(), 
    },
    {
        deviceName => q[dummyDuino],
        plan       => 2,
        testname   =>  q[Test Protocol 44 - MU Data dispatched],
        input      =>  q[MU;P0=32001;P1=-1939;P2=1967;P3=3896;P4=-3895;D=01213424242124212121242121242121212124212424212121212121242421212421242121242124242421242421242424242124212124242424242421212424212424212121242121212;CP=2;R=39;],
        rValue     => 1,
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Test Protocol 46 - MU Data dispatched],
        input =>  q[MU;P0=-1943;P1=1966;P2=-327;P3=247;P5=-15810;D=01230121212301230121212121230121230351230121212301230121212121230121230351230121212301230121212121230121230351230121212301230121212121230121230351230121212301230121212121230121230351230;CP=1;],
        rValue => 4,
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Test Protocol 84 - MU Data dispatched],
        input =>  q[MU;P0=-21520;P1=235;P2=-855;P3=846;P4=620;P5=-236;P7=-614;D=012323232454545454545451717451717171745171717171717171717174517171745174517174517174545;CP=1;R=217;],
        rValue => 1,
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Test Protocol 85 - MU Data dispatched],
        input =>  q[MU;P0=7944;P1=-724;P2=742;P3=241;P4=-495;P5=483;P6=-248;D=01212121343434345656343434563434345634565656343434565634343434343434345634345634345634343434343434343434345634565634345656345634343456563421212121343434345656343434563434345634565656343434565634343434343434345634345634345634343434343434343434345634565634;CP=3;R=47;],
        rValue => 2,
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
      
      my $ret = SIGNALduino_Parse_MU($targetHash,$element->{input});
      for my $i (1..$p)
      {
        $i == 1 && do { is($ret,$element->{rValue},"Verify return value") } ;
        $i == 2 && do { is(FhemTestUtils_gotLog("PERL WARNING: Use of uninitialized value"), 0, "No Warnings in logfile"); } ;
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