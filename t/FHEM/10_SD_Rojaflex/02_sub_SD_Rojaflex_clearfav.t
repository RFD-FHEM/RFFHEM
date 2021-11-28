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

	subtest "SD_Rojaflex_clearfav - 1..5 calls" => sub {
		plan(8);
        for my $i (1..3) {
            is (SD_Rojaflex::SD_Rojaflex_clearfav($sensorname), U(),'check return for SD_Rojaflex_clearfav ');
            is($hash->{clearfavcount},$i);
        }
        is (SD_Rojaflex::SD_Rojaflex_clearfav($sensorname), U(),'check return for SD_Rojaflex_clearfav ');
        is($hash->{clearfavcount},U());
        
    };


	done_testing();
	exit(0);

}, 'SD_Rojaflex_Test_11');

1;