#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{ is };
our %defs;

InternalTimer(time()+1, sub {
	my $target = shift;
	my $targetHash = $defs{$target};
	plan(1);
		
	subtest 'Test SIGNALduino_GetResponseUpdateReading (ping OK) ' => sub {
		plan(1);
		my ($ret,undef)=SIGNALduino_GetResponseUpdateReading($targetHash,'OK');
		is($ret,'OK','check return message');
	};

	exit(0);
},'dummyDuino');

1;
