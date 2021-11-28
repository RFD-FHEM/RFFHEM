#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is};

our %defs;
our %attr;

InternalTimer(time()+1, sub {
	my $sensorname = shift; 
	my $hash = $defs{$sensorname};


    my $cmd=q[?];
	subtest "Protocol 109 - set $sensorname $cmd" => sub {
		plan(4);
		
        my $ret = CommandSet(undef,qq[$sensorname $cmd]); 
        like($ret, qr/down/, q[check down help]);
        like($ret, qr/stop/, q[check stop help]);
        like($ret, qr/up/, q[check up help]);
        like($ret, qr/pct/, q[check pct help]);

	};


    $cmd=q[];
	subtest "Protocol 109 - set $sensorname $cmd" => sub {
		plan(1);
		
        my $ret = SD_Rojaflex::Set($hash,$sensorname,split(/ /,$cmd)); 
        is($ret, qq[$sensorname, no set command specified], q[check error message ]);
	};

    $cmd=q[badCmd];
	subtest "Protocol 109 - set $sensorname $cmd" => sub {
		plan(1);
		
        my $ret = SD_Rojaflex::Set($hash,$sensorname,split(/ /,$cmd)); 
        is($ret, qq[$sensorname, invalid set command], q[check error message ]);
	};


    $cmd=q[pct -100];
	subtest "Protocol 109 - set $sensorname $cmd" => sub {
		plan(1);
		
        my $ret = SD_Rojaflex::Set($hash,$sensorname,split(/ /,$cmd)); 
        is($ret, qq[$sensorname, invalid parameter for command pct, must be 0-100], q[check error message ]);
	};

    $cmd=q[pct];
	subtest "Protocol 109 - set $sensorname $cmd" => sub {
		plan(1);
		
        my $ret = SD_Rojaflex::Set($hash,$sensorname,split(/ /,$cmd)); 
        is($ret, qq[$sensorname, invalid parameter for command pct, must be 0-100], q[check error message ]);
	};

    $cmd=q[pct a%];
	subtest "Protocol 109 - set $sensorname $cmd" => sub {
		plan(1);
		
        my $ret = SD_Rojaflex::Set($hash,$sensorname,split(/ /,$cmd)); 
        is($ret, qq[$sensorname, invalid parameter for command pct, must be 0-100], q[check error message ]);
	};


    $cmd=q[pct 50];
	subtest "Protocol 109 - set $sensorname $cmd" => sub {
		plan(1);
		
        my $ret = SD_Rojaflex::Set($hash,$sensorname,split(/ /,$cmd)); 
        is($ret, U(), q[check return is undef]);
	};

    $cmd=q[pct 25 - tpos > cpos];
	subtest "Protocol 109 - set $sensorname $cmd" => sub {
		plan(1);

        setReadingsVal($defs{$sensorname}, q[cpos], q[10], TimeNow()); 
        setReadingsVal($defs{$sensorname}, q[tpos], q[90], TimeNow()); 
		
        my $ret = SD_Rojaflex::Set($hash,$sensorname,split(/ /,$cmd)); 
        is($ret, U(), q[check return is undef]);
	};

    $cmd=q[pct 25 - tpos < cpos];
	subtest "Protocol 109 - set $sensorname $cmd" => sub {
		plan(1);

        setReadingsVal($defs{$sensorname}, q[cpos], q[90], TimeNow()); 
        setReadingsVal($defs{$sensorname}, q[tpos], q[10], TimeNow()); 
		
        my $ret = SD_Rojaflex::Set($hash,$sensorname,split(/ /,$cmd)); 
        is($ret, U(), q[check return is undef]);
	};

    for my $cmd (qw (up down stop clearfav gotofav))
    {
        subtest "Protocol 109 - set $sensorname $cmd" => sub {
            plan(1);
            
            my $ret = SD_Rojaflex::Set($hash,$sensorname,split(/ /,$cmd)); 
            is($ret, U(), q[check return is undef]);
        };
    };



}, 'SD_Rojaflex_Test_11');

InternalTimer(time()+1.01, sub {
	my $sensorname = shift; 
	my $hash = $defs{$sensorname};


    for my $cmd (qw (up down stop clearfav gotofav))
    {
        subtest "Protocol 109 - set $sensorname $cmd (channel 0)" => sub {
            plan(3);
            
            my $ret = SD_Rojaflex::Set($hash,$sensorname,split(/ /,$cmd)); 
            is($ret, U(), q[check return is undef]);

            is(ReadingsVal('SD_Rojaflex_Test_11','state','na'),$cmd,'check reading for devices');
            is(ReadingsVal('SD_Rojaflex_Test_0','state','na'),$cmd,'check reading for devices');
        };
    };

}, 'SD_Rojaflex_Test_0');


InternalTimer(time()+1.02, sub {
	my $sensorname = shift; 
	my $hash = $defs{$sensorname};


    for my $cmd (qw (up down stop clearfav gotofav))
    {
        subtest "Protocol 109 - set $sensorname $cmd (channel 0)" => sub {
            plan(2);
            
            my $ret = SD_Rojaflex::Set($hash,$sensorname,split(/ /,$cmd)); 
            is($ret, U(), q[check return is undef]);

            is(ReadingsVal('SD_Rojaflex_Test_09','state','na'),$cmd,'check reading for device');
        };
    };

	done_testing();
	exit(0);
}, 'SD_Rojaflex_Test_09');

1;