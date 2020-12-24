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
        testname =>  q[Corrupt Mu data, combined message],
        input =>  q[MU;P0=-2272;P1=228;P2=-356;P3=635;P4=-562;P5=433;D=012345234345252343452523434345252345234343434523434345252343452525252525234523452343452345252525;CP=5;R=4�;P3=;L=L=-2864;L=H=2980;S=L=-1444;S=H=1509;D=354146333737463037;C==1466;L==32;R==9;],
        rValue => U(), 
        todoReason => q[This data should not be processed]
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MU data, unknown specifier V=],
        input =>  q[MU;P0=-1440;P1=432;P2=-357;P3=635;P4=-559;D=012121212123412343412123434121234343412123412343434341234343412123434121212121212341231212343412341212121;CP=1;V=139;],
        rValue => U(), 
        todoReason => q[This data should not be processed]
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MU data, missing D= part],
        input =>  q[MU;P0=-370;P1=632;P2=112;P3=-555;P4=428;P5=-780;P6=180;P7=;CP=4;R=77;],
        rValue => U(), 
        todoReason => q[This data should not be processed]
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MU data, C= has letters ],
        input =>  q[MU;P0=536;P1=-1443;P2=1486;P3=-4208;P4=5776;P5=-6700;P6=2972;P7=-2880;D=01212121212121212123456767212121212121672167212121212121212121672167672;C=23RB;],
        rValue => U(), 
        todoReason => q[This data should not be processed]
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MU data, wrong delemiter =],
        input =>  q[MU;P0=536;P1=-1443;P2=1486;P3=-4208;P4=5776;P5=-6700;P6=2972;P7=-2880;D=01212121212121212123456767212121212121672167212121212121212121672167672=C=23;],
        rValue => U(), 
        todoReason => q[This data should not be processed]
    },
    {
        deviceName => q[dummyDuino],
        plan => 2,
        testname =>  q[Corrupt MU data, D= isn't numeric],
        input =>  q[MU;P0=-16320;P1=394;P2=-400;P5=628;P6=-625;D=0121212121212121212121212561A1256121212121256121256125656C212561256561256121256121256565612565656121212125612125612121256121256125612561;CP=1;R=84;],
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
      
      my $ret = SIGNALduino_Parse_MU($targetHash,$targetHash,$element->{deviceName},$element->{input},%signal_parts);
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