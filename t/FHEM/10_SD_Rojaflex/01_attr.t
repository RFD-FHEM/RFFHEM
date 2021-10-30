#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is};

our %defs;
our %attr;

InternalTimer(time()+1, sub {
	my $ioName = shift; 
	my $ioHash = $defs{$ioName};

    my $sensorname=q[SD_Rojaflex_Test_11];

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
		plan(5);

        CommandSetstate(undef,qq[$sensorname up]);
        setReadingsVal($defs{$sensorname}, q[state], q[up], TimeNow()); 
        setReadingsVal($defs{$sensorname}, q[pct], q[90], TimeNow()); 
        setReadingsVal($defs{$sensorname}, q[cpos], q[90], TimeNow()); 
        setReadingsVal($defs{$sensorname}, q[tpos], q[90], TimeNow()); 


        CommandAttr(undef,qq[$sensorname inversePosition 1]); 
        
        is($attr{$sensorname}{inversePosition}, 1, q[check attribute inversePosition is 1]);
        is(ReadingsVal($sensorname, q[state], undef), q[down],'reading state is reversed');
        is(ReadingsVal($sensorname, q[pct], undef), q[10],'reading pct is reversed');
        is(ReadingsVal($sensorname, q[cpos], undef), q[10],'reading cpos is reversed');
        is(ReadingsVal($sensorname, q[tpos], undef), q[10],'reading tpos is reversed');        
	};



	subtest "Protocol 109 - set $sensorname inversePosition 0" => sub {
		plan(5);
		
        CommandAttr(undef,qq[$sensorname inversePosition 0]); 
        is($attr{$sensorname}{inversePosition}, 0, q[check attribute inversePosition is 0]);

        is(ReadingsVal($sensorname, q[state], undef), q[up],'reading state is reversed');
        is(ReadingsVal($sensorname, q[pct], undef), q[90],'reading pct is reversed');
        is(ReadingsVal($sensorname, q[cpos], undef), q[90],'reading cpos is reversed');
        is(ReadingsVal($sensorname, q[tpos], undef), q[90],'reading tpos is reversed');        

	};

	done_testing();
	exit(0);

}, 'dummyDuino');

1;