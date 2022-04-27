#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is};

our %defs;

InternalTimer(time()+1, sub {
	my $ioName = shift; 
	my $ioHash = $defs{$ioName};


	subtest 'Protocol 31 - define LTECH_Test_01 LTECH 04444EFF' => sub {
		plan(1);
		
        my $sensorname=q[LTECH_Test_01];
        CommandDefine(undef,qq[$sensorname LTECH 04444EFF]); 
        is(IsDevice($sensorname), 1, "check sensor created with define");
	};

	subtest 'Protocol 31 - delete SD_Rojaflex_Test_11' => sub {
		plan(1);
		
        my $sensorname=q[LTECH_Test_01];
        CommandDelete(undef,qq[$sensorname]); 
        is(IsDevice($sensorname), 0, "check sensor deleted");
	};
	
	done_testing();
	exit(0);

}, 'dummyDuino');

1;