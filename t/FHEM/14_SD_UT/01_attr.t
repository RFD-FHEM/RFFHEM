#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is};

our %defs;
our %attr;

InternalTimer(time()+1, sub {
    my $sensorname=shift;



    my $attr = q[repeats];
    for my $v (qw(1 5 17 20 99)) {
        subtest "Protocol 109 - set $sensorname $attr $v" => sub {
            plan(1);
            CommandAttr(undef,qq[$sensorname $attr $v]); 
            is($attr{$sensorname}{$attr}, $v, q[check attribute $attr is $v]);
        };
    }


    $attr = q[repeats];
    my $val = q[n];
	subtest "Protocol 109 - set $sensorname $attr $val" => sub {
		plan(1);
		
        CommandAttr(undef,qq[$sensorname $attr $val]); 
        isnt($attr{$sensorname}{repetition}, 'n', q[check attribute repetition is not n]);
	};



	
	done_testing();
	exit(0);

}, 'SD_UT_Test_1');

1;