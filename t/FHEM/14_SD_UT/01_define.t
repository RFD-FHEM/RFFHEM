#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is};

our %defs;

InternalTimer(time()+1, sub {
	my $ioName = shift; 
	my $ioHash = $defs{$ioName};


	subtest 'SD_UT - define unknown_please_select_model SD_UT unknown' => sub {
		plan(1);
		
        my $sensorname=q[unknown_please_select_model];
        my $model=q[unknown];
        CommandDefine(undef,qq[$sensorname SD_UT $model]); 
        is(IsDevice($sensorname), 1, "check device created with define");
	};

	subtest 'SD_UT - delete unknown_please_select_model' => sub {
		plan(1);
		
        my $sensorname=q[unknown_please_select_model];
        CommandDelete(undef,qq[$sensorname]); 
        is(IsDevice($sensorname), 0, "check device deleted");
	};
	
	subtest 'SD_UT - wrong define unknown_please_select_model SD_UT unknown A1' => sub {
		plan(1);
		
        my $sensorname=q[unknown_please_select_model];
        my $model=q[unknown];
        CommandDefine(undef,qq[$sensorname SD_UT $model A1]); 
        is(IsDevice($sensorname), 0, "check sensor not created with define");
	};

	subtest 'SD_UT - model RH787T wrong HEX-Value one HEX-Value define RH787T_11 SD_UT RH787T 11' => sub {
		plan(1);
		
        my $sensorname=q[RH787T_11];
        my $model=q[RH787T];
        CommandDefine(undef,qq[$sensorname SD_UT $model 11]); 
        is(IsDevice($sensorname), 0, "check device not created with define");
	};

	subtest 'SD_UT - model RH787T wrong HEX-Value define RH787T_1 SD_UT RH787T G' => sub {
		plan(1);
		
        my $sensorname=q[RH787T_1];
        my $model=q[RH787T];
        CommandDefine(undef,qq[$sensorname SD_UT $model G]); 
        is(IsDevice($sensorname), 0, "check device not created with define");
	};

	subtest 'SD_UT - model OR28V wrong address define OR28V_2 SD_UT OR28V 199' => sub {
		plan(1);
		
        my $sensorname=q[OR28V_2];
        my $model=q[OR28V];
        CommandDefine(undef,qq[$sensorname SD_UT $model 199]); 
        is(IsDevice($sensorname), 0, "check device not created with define");
	};

	subtest 'SD_UT - model OR28V wrong address define OR28V_1 SD_UT OR28V 17' => sub {
		plan(1);
		
        my $sensorname=q[OR28V_1];
        my $model=q[OR28V];
        CommandDefine(undef,qq[$sensorname SD_UT $model 17]); 
        is(IsDevice($sensorname), 0, "check device not created with define");
	};

	done_testing();
	exit(0);

}, 'dummyDuino');

1;