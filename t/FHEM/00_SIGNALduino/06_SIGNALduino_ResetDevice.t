#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is U };
use Test2::Mock;

our %defs;
our %attr;

InternalTimer(time()+1, sub {
	my $target = shift;
	my $targetHash = $defs{$target};
	plan (2);	
	my $mock = Test2::Mock->new(
		track => 1,
		class => 'main'
	);	 	
	my $tracking = $mock->sub_tracking;

	subtest 'reset with specialReset flag set' => sub {
		plan(3);

		$targetHash->{helper}{resetInProgress}=1;
		$mock->override('SIGNALduino_Connect');
		$mock->override('InternalTimer');

		SIGNALduino_ResetDevice($targetHash);

		is (scalar @{$tracking->{SIGNALduino_Connect}},1,'check if SIGNALduino_Connect is called once');
		$mock->restore('SIGNALduino_Connect');

		is ($tracking->{InternalTimer},U(),'check if InternalTimer is not called once');
		$mock->restore('InternalTimer');

		is ($targetHash->{helper}{resetInProgress},U(),'check reset in progress flag deleted');
	};

	subtest 'reset for dummy device' => sub {
		plan(2);
		$attr{$target}{dummy} = 1;
		$targetHash->{READINGS}{state}{VAL} = $targetHash->{STATE} = 'disconnected';
		is (ReadingsVal($target,"state",""),'disconnected','check dummy state disconnected');

		SIGNALduino_ResetDevice($targetHash);
		is (ReadingsVal($target,"state",""),"opened","check dummy state opened");
	};

	# CommandDefMod(undef,"$target $targetHash->{TYPE} $targetHash->{DEF}");

	exit(0);
},'dummyDuino');

1;