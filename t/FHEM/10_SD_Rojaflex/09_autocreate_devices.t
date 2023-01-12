#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is};

our %defs;
our $init_done;

InternalTimer(time()+0.4, sub {

	my $ioName = shift; 
	my $ioHash = $defs{$ioName};

	subtest 'attrib autocreate is undef for right result' => sub {
		is(AttrVal("autocreate" ,"autocreateThreshold",undef),undef,"check autocreate undef");
	};

	subtest 'Protocol 109 - autocreate via DMSG' => sub {
		plan(5);
		my $sensorname=q[SD_Rojaflex_3122FD2_9];
		for my $i (1..4) {
			Dispatch($ioHash,q[P109#083122FD298A018A8E]);
			is(IsDevice($sensorname), 0, "check sensor not created with dispatch $i/4");
			$ioHash->{TIME} -=3;
		}
		Dispatch($ioHash,q[P109#083122FD298A018A8E]);
		is(IsDevice($sensorname), 1, "check sensor created with dispatch 5");
		Dispatch($ioHash,q[P109#083122FD298A018A8E]);
	};
	done_testing();
	exit(0);

}, 'dummyDuino');

1;