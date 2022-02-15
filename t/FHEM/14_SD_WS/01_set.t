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

    ok($defs{dummyDuino},q[check dummyduino exists]);
    $hash->{LASTInputDev} = q[dummyDuino];

	subtest "set $sensorname $cmd with LastInputDev but without longids" => sub {
		plan(1);
        my $ret = SD_WS_Set($hash,$sensorname, $cmd); 
           is($ret,U(),q[verify return]);
	};

    CommandAttr(undef,q[dummyDuino longids 1]);
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
		plan(3);
		FhemTestUtils_resetLogs();

        my $ret = SD_WS_Set($hash,$sensorname,split(/ /,$cmd)); 
        is($ret,U(),q[verify return undef]);
        is(FhemTestUtils_gotLog($sensorname),L(),q[check log exists]);
        is($hash->{replaceBattery},10,q[check internal value]);
	};
    
    subtest "removeReplaceBattery (timeout)" => sub {
        plan(3);
		FhemTestUtils_resetLogs();

        is(SD_WS_TimerRemoveReplaceBattery($hash),undef,q[check internal value]);
        is(FhemTestUtils_gotLog($sensorname),L(),q[check log exists]);
        is($hash->{replaceBattery},U(),q[check internal value deleted]);
    };

    subtest "parse with removeReplaceBattery (modify)" => sub {
		plan(5);
		FhemTestUtils_resetLogs();

        my $ret = SD_WS_Set($hash,$sensorname,split(/ /,$cmd)); 
        is($ret,U(),q[verify return undef]);

        my $oldDEF= $hash->{DEF};
        my @found = devspec2array(q[TYPE=SD_WS:FILTER=i:replaceBattery>0]);
        #is(@found,U(),q[verify decspec2array result], Dumper $hash );
        #diag Dumper @found;

        $ret = SD_WS_Parse($defs{dummyDuino},q[W33#26C6F570804]);
        like($ret,qr/UNDEFINED/,q[check sensorname not returned]);

        # Mock sensor hash
        $hash->{dummyDuino_Protocol_ID} = q[33];
        $ret = SD_WS_Parse($defs{dummyDuino},q[W33#26C6F570804]);

        is($ret,$sensorname,q[check sensorname is returned]);
        is($hash->{replaceBattery},U(),q[check internal value deleted]);
        isnt($hash->{DEF},$oldDEF,q[check DEF is changed]);
    };

    done_testing;
    exit(0);

}, 'SD_WS_33_Test');


1;