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

	subtest 'Protocol 109 - autocreate via DMSG' => sub {
		plan(3);
		my $sensorname=q[SD_Rojaflex_3122FD2_9];
		for my $i (1..2) {
			Dispatch($ioHash,q[MN;D=083122FD290A010A8E;R=244;]);
			is(IsDevice($sensorname), 0, "check sensor not created with dispatch $i/3");
			$ioHash->{TIME} -=3;
		}
		Dispatch($ioHash,q[MN;D=083122FD290A010A8E;R=244;]);
		is(IsDevice($sensorname), 1, "check sensor created with dispatch 3");
		Dispatch($ioHash,q[MN;D=083122FD290A010A8E;R=244;]);
	};
	
	
	done_testing();
	exit(0);

}, 'dummyDuino');

1;