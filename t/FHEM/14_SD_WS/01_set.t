#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is};

our %defs;
our %attr;

InternalTimer(time()+0.6, sub {
	my $sensorname = shift; 
	my $hash = $defs{$sensorname};

    my $cmd=q[?];
	subtest "set $sensorname $cmd without LastInputDev" => sub {
		plan(1);
		
        my $ret = SD_WS_Set($hash,$sensorname, $cmd); 
        is($ret,U(),q[verify return]);
        #like($ret, qr/replaceBatteryForSec/, q[check replaceBatteryForSec help]);
	};

    ok($defs{dummyDuino},"check dummyduino exists");
    $hash->{LASTInputDev} = 'dummyDuino';

	subtest "set $sensorname $cmd with LastInputDev but without longids" => sub {
		plan(1);
        my $ret = SD_WS_Set($hash,$sensorname, $cmd); 
           is($ret,U(),q[verify return]);
	};

    CommandAttr(undef,'dummyDuino longids 1');
    subtest "set $sensorname $cmd with LastInputDev and longids" => sub {
		plan(1);
        my $ret = SD_WS_Set($hash,$sensorname, $cmd); 
        like($ret,qr/replaceBatteryForSec/,q[check replaceBatteryForSec help]);
	};

    $cmd=q[];
  	subtest "set $sensorname $cmd" => sub {     
        plan(2);
        my $ret = SD_WS_Set($hash,$sensorname, $cmd); 
        like($ret,qr/Unknown/,q[verify string part unknown]);
        like($ret,qr/replaceBatteryForSec/,q[verify string part replaceBatteryForSec]);
    };

    $cmd=q[badCmd];
    subtest "set $sensorname $cmd with LastInputDev and longids" => sub {
		plan(2);
        my $ret = SD_WS_Set($hash,$sensorname, $cmd); 
        like($ret,qr/Unknown/,q[verify string part unknown]);
        like($ret,qr/replaceBatteryForSec/,q[verify string part replaceBatteryForSec]);
	};


    $cmd=q[replaceBatteryForSec];
	subtest "set $sensorname $cmd" => sub {
		plan(2);
		
        my $ret = SD_WS_Set($hash,$sensorname,split(/ /,$cmd)); 
        like($ret,qr/no/i,q[verify string part no]);
        like($ret,qr/too small/,q[verify string part small]);
	};

    $cmd=q[replaceBatteryForSec -1];
	subtest "set $sensorname $cmd" => sub {
		plan(2);
		
        my $ret = SD_WS_Set($hash,$sensorname,split(/ /,$cmd)); 
        like($ret,qr/no/i,q[verify string part no]);
        like($ret,qr/too small/,q[verify string part small]);
	};

    $cmd=q[replaceBatteryForSec 10];
	subtest "set $sensorname $cmd" => sub {
		plan(2);
		FhemTestUtils_resetLogs();

        my $ret = SD_WS_Set($hash,$sensorname,split(/ /,$cmd)); 
        is($ret,U(),q[verify return undef]);
        is(FhemTestUtils_gotLog($sensorname),L(),q[check log exists])

	};

    done_testing;
    exit(0);

}, 'SD_WS_WH2_Test_5');


1;