#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is};

our %defs;

InternalTimer(time()+1, sub {
	my $ioName = shift; 
	my $ioHash = $defs{$ioName};

	subtest 'attrib autocreate is undef for right result' => sub {
		is(AttrVal("autocreate" ,"autocreateThreshold",undef),undef,"check autocreate undef");
	};

	subtest 'Protocol 38 - autocreate via DMSG' => sub {
		plan(3);
		my $sensorname="SD_WS_38_T_1";
		for my $i (1..2) {
			Dispatch($ioHash,"W38#8B922397E");
			is(IsDevice($sensorname), 0, "check sensor not created with dispatch $i/3");
			$ioHash->{TIME} -=3;
		}
		Dispatch($ioHash,"W38#8B922397E");
		is(IsDevice($sensorname), 1, "check sensor created with dispatch 3");
		Dispatch($ioHash,"W38#8B922397E");
	};
	
	subtest 'Protocol 84 - autocreate via DMSG' => sub {
		plan(2);
		my $sensorname="SD_WS_84_TH_1";
		CommandDelete(undef,$sensorname);
		Dispatch($ioHash,"W84#FE42004526");
		is(IsDevice($sensorname), 0, "Sensor not created with single dispatch");
		$ioHash->{TIME} -=3;
	
		Dispatch($ioHash,"W84#FE42004526");
		is(IsDevice($sensorname), 1, "check Sensor created with second dispatch");
		$ioHash->{TIME} -=3;
	};
	
	subtest 'Protocol 85 - autocreate via RAWMSG' => sub {
		plan(4);
		my $rmsg="MU;P0=7944;P1=-724;P2=742;P3=241;P4=-495;P5=483;P6=-248;D=01212121343434345656343434563434345634565656343434565634343434343434345634345634345634343434343434343434345634565634345656345634343456563421212121343434345656343434563434345634565656343434565634343434343434345634345634345634343434343434343434345634565634;CP=3;R=47;O;";      
		my $sensorname="SD_WS_85_THW_1";
		CommandDelete(undef,$sensorname);
	
		for my $i (1..3) {
			SIGNALduino_Parse_MU($ioHash, $rmsg);
			is(IsDevice($sensorname), 0, "Sensor not created with dispatch $i/3");
			$ioHash->{TIME} -=3;
		}
		SIGNALduino_Parse_MU($ioHash, $rmsg);
		is(IsDevice($sensorname), 1,"check Sensor created with dispatch 4");
	};
	
	done_testing();
	exit(0);

}, 'dummyDuino');

1;