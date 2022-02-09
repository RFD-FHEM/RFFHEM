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

	subtest "set $sensorname $cmd with LastInputDev" => sub {
		plan(1);
        my $ret = SD_WS_Set($hash,$sensorname, $cmd); 
        like($ret, qr/replaceBatteryForSec/, q[check replaceBatteryForSec help]);
	};

    $cmd=q[];
	subtest "set $sensorname $cmd" => sub {
		plan(1);
		
        my $ret = SD_WS_Set($hash,$sensorname,split(/ /,$cmd)); 
        is($ret, qq[$sensorname, no set command specified], q[check error message ]);
	};

    $cmd=q[badCmd];
	subtest "set $sensorname $cmd" => sub {
		plan(1);
		
        my $ret = SD_WS_Set($hash,$sensorname,split(/ /,$cmd)); 
        is($ret, qq[$sensorname, invalid set command], q[check error message ]);
	};

    $cmd=q[replaceBatteryForSec];
	subtest "set $sensorname $cmd" => sub {
		plan(1);
		
        my $ret = SD_WS_Set($hash,$sensorname,split(/ /,$cmd)); 
        is($ret, U(), q[check return is undef]);
	};

    done_testing;
    exit(0);

}, 'SD_WS_WH2_Test_5');


1;