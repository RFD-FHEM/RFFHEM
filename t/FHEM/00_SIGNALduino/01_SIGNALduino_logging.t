#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{ is U};
use Test2::Mock;

our %defs;

InternalTimer(time()+1, sub {
	my $target = shift;
	my $targetHash = $defs{$target};

	my $mock = Test2::Mock->new(
		track => 1,
		class => 'main',
		override => [
			DoTrigger => sub($$@) { 0 },
		],
	);

	plan(2);
	subtest "Check logMethod with with attr eventlogging 0" => sub {
		plan(2);

		CommandAttr(undef,"$target eventlogging 0");
		is ($targetHash->{logMethod},\&::Log3,"Check {logMethod} points to ::Log3");
		my $logmsg = "check with eventlogging=0";
		my $tracking = $mock->sub_tracking;
		$mock->clear_sub_tracking;
		$targetHash->{logMethod}->($targetHash, 2, $logmsg);
		is($tracking->{DoTrigger}, U(), "check if DoTrigger is not called from Log3 ");
		$mock->clear_sub_tracking;
	};

	subtest "Check logMethod with attr eventlogging 1" => sub {
		plan(2);
		CommandAttr(undef,"$target eventlogging 1");
		my $logmsg = "check with eventlogging=1";
		is ($targetHash->{logMethod},\&::SIGNALduino_Log3,"Check {logMethod} points to ::SIGNALduino_Log3");

		$mock->clear_sub_tracking;
		my $tracking = $mock->sub_tracking;
		$targetHash->{logMethod}->($targetHash, 2, $logmsg);
		is(scalar @{$tracking->{DoTrigger}}, 1, "check if DoTrigger is called from SIGNALduino_Log3");
		$mock->clear_sub_tracking;
	};

	$mock->restore('DoTrigger');

	CommandAttr(undef,"$target eventlogging 0");

	exit(0);
},'dummyDuino');

1;