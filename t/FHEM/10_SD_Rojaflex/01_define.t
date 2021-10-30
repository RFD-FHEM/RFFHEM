#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is};

our %defs;

InternalTimer(time()+1, sub {
	my $ioName = shift; 
	my $ioHash = $defs{$ioName};


	subtest 'Protocol 109 - define SD_Rojaflex_Test_11 SD_Rojaflex 7AE3121_11' => sub {
		plan(1);
		
        my $sensorname=q[SD_Rojaflex_Test_11];
        CommandDefine(undef,qq[$sensorname SD_Rojaflex 7AE3121_11]); 
        is(IsDevice($sensorname), 1, "check sensor created with define");
	};

	subtest 'Protocol 109 - delete SD_Rojaflex_Test_11' => sub {
		plan(1);
		
        my $sensorname=q[SD_Rojaflex_Test_11];
        CommandDelete(undef,qq[$sensorname]); 
        is(IsDevice($sensorname), 0, "check sensor deleted");
	};
	
	subtest 'Protocol 109 - define SD_Rojaflex_Test_11 SD_Rojaflex 7AE312111' => sub {
		plan(1);
		
        my $sensorname=q[SD_Rojaflex_Test_11];
        CommandDefine(undef,qq[$sensorname SD_Rojaflex 7AE312111]); 
        is(IsDevice($sensorname), 0, "check sensor not created with define");
	};
	
	subtest 'Protocol 109 - define SD_Rojaflex_Test_11 SD_Rojaflex 7AG3121_11' => sub {
		plan(1);
		
        my $sensorname=q[SD_Rojaflex_Test_11];
        CommandDefine(undef,qq[$sensorname SD_Rojaflex 7AG3121_11]); 
        is(IsDevice($sensorname), 0, "check sensor not created with define");
	};

	subtest 'Protocol 109 - define SD_Rojaflex_Test_A1 SD_Rojaflex 7AG3121_A1' => sub {
		plan(1);
		
        my $sensorname=q[SD_Rojaflex_Test_A1];
        CommandDefine(undef,qq[$sensorname SD_Rojaflex 7AG3121_A1]); 
        is(IsDevice($sensorname), 0, "check sensor not created with define");
	};

	done_testing();
	exit(0);

}, 'dummyDuino');

1;