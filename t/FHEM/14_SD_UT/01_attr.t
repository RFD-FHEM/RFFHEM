#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is};

our %defs;
our %attr;

InternalTimer(time()+1, sub {
    my $sensorname=shift;

	subtest "Protocol 109 - set $sensorname repetition 5" => sub {
		plan(1);
		
        CommandAttr(undef,qq[$sensorname repetition 5]); 
        is($attr{$sensorname}{repetition}, 5, q[check attribute repetition is 5]);
	};

	subtest "Protocol 109 - set $sensorname repetition n" => sub {
		plan(1);
		
        CommandAttr(undef,qq[$sensorname repetition n]); 
        isnt($attr{$sensorname}{repetition}, 'n', q[check attribute repetition is not n]);
	};


	subtest "Protocol 109 - set $sensorname inversePosition 1" => sub {
		plan(7);
        CommandAttr(undef,qq[$sensorname bidirectional 0]); 
        my $timestamp=TimeNow();

        is($attr{$sensorname}{inversePosition}, U(), q[check attribute inversePosition is 0]);
        CommandSetstate(undef,qq[$sensorname $timestamp state down]);
        setReadingsVal($defs{$sensorname}, q[pct], q[90], TimeNow()); 
        setReadingsVal($defs{$sensorname}, q[cpos], q[90], TimeNow()); 
        setReadingsVal($defs{$sensorname}, q[tpos], q[90], TimeNow()); 
  
        is(ReadingsVal($sensorname, q[state], undef), q[down],'reading state has correct start value');

        CommandAttr(undef,qq[$sensorname inversePosition 1]); 
        
        is($attr{$sensorname}{inversePosition}, 1, q[check attribute inversePosition is 1]);
        is(ReadingsVal($sensorname, q[state], undef), q[up],'reading state is reversed');
        is(ReadingsVal($sensorname, q[pct], undef), q[10],'reading pct is reversed');
        is(ReadingsVal($sensorname, q[cpos], undef), q[10],'reading cpos is reversed');
        is(ReadingsVal($sensorname, q[tpos], undef), q[10],'reading tpos is reversed');        
        
	};

	subtest "Protocol 109 - set $sensorname inversePosition 0" => sub {
		plan(7);
        my $timestamp=TimeNow();

        #my $ret = CommandSetstate(undef,qq[$sensorname state closed]);
        my $ret = CommandSetReading(undef,qq[$sensorname $timestamp state closed]);
        is ($ret,'','verify return value setState is empty');
        is(ReadingsVal($sensorname, q[state], undef), q[closed],'reading state has correct start value');

        CommandAttr(undef,qq[$sensorname inversePosition 0]); 
        is($attr{$sensorname}{inversePosition}, 0, q[check attribute inversePosition is 0]);

        is(ReadingsVal($sensorname, q[state], undef), q[open],'reading state is reversed');
        is(ReadingsVal($sensorname, q[pct], undef), q[90],'reading pct is reversed');
        is(ReadingsVal($sensorname, q[cpos], undef), q[90],'reading cpos is reversed');
        is(ReadingsVal($sensorname, q[tpos], undef), q[90],'reading tpos is reversed');        
	};

    my $cmd = q[bidirectional 1];
	subtest "Protocol 109 - set $sensorname $cmd" => sub {
		plan(1);
		
        CommandAttr(undef,qq[$sensorname $cmd]); 
        is($attr{$sensorname}{bidirectional}, 1, q[check attribute bidirectional is 1]);
	};

    $cmd = q[bidirectional 0];
	subtest "Protocol 109 - set $sensorname $cmd" => sub {
		plan(1);
		
        CommandAttr(undef,qq[$sensorname $cmd]); 
        is($attr{$sensorname}{bidirectional}, 0, q[check attribute bidirectional is 0]);
	};

    $cmd = q[bidirectional a];
	subtest "Protocol 109 - set $sensorname $cmd" => sub {
		plan(2);
		
        my $ret= CommandAttr(undef,qq[$sensorname $cmd]); 
        isnt($attr{$sensorname}{bidirectional}, 'a', q[check attribute bidirectional is not a]);
        like($ret, qr/Unallowed value/, q[return message containts error]);
	};

    $cmd = q[timeToClose a];
	subtest "Protocol 109 - set $sensorname $cmd" => sub {
		plan(2);
		
        my $ret= CommandAttr(undef,qq[$sensorname $cmd]); 
        isnt($attr{$sensorname}{timeToClose}, 'a', q[check attribute timeToClose is not a]);
        like($ret, qr/Unallowed value/, q[return message containts error]);
	};

    $cmd = q[timeToOpen 2000];
	subtest "Protocol 109 - set $sensorname $cmd" => sub {
		plan(2);
		
        my $ret= CommandAttr(undef,qq[$sensorname $cmd]); 
        isnt($attr{$sensorname}{timeToOpen}, 2000, q[check attribute timeToOpen is not 2000]);
        like($ret, qr/Unallowed value/, q[return message containts error]);
	};

    $cmd = q[timeToClose -10];
	subtest "Protocol 109 - set $sensorname $cmd" => sub {
		plan(2);
		
        my $ret= CommandAttr(undef,qq[$sensorname $cmd]); 
        isnt($attr{$sensorname}{timeToOpen}, -10, q[check attribute timeToOpen is not -10]);
        like($ret, qr/Unallowed value/, q[return message containts error]);
	};

    $cmd = q[timeToOpen 10];
	subtest "Protocol 109 - set $sensorname $cmd" => sub {
		plan(1);
		
        CommandAttr(undef,qq[$sensorname $cmd]); 
        is($attr{$sensorname}{timeToOpen}, 10, q[check attribute timeToOpen is 10]);
	};
    
    $cmd = q[timeToClose 10];
	subtest "Protocol 109 - set $sensorname $cmd" => sub {
		plan(1);
		
        CommandAttr(undef,qq[$sensorname $cmd]); 
        is($attr{$sensorname}{timeToClose}, 10, q[check attribute timeToClose is 10]);
	};

	done_testing();
	exit(0);

}, 'SD_Rojaflex_Test_11');

1;