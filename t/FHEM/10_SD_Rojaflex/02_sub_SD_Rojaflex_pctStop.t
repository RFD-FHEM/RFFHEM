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
    plan(1);    

    is (SD_Rojaflex::SD_Rojaflex_pctStop($sensorname), U(),'check return for SD_Rojaflex_pctStop');

	done_testing();
	exit(0);

}, 'SD_Rojaflex_Test_11');

1;