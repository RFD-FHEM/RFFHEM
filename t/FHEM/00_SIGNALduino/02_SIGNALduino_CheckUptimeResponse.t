#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{ is };

our %defs;

InternalTimer(time()+1, sub {
    my $target		= shift;
    my $targetHash 	= $defs{$target};
	plan(3);

	subtest 'Test SIGNALduino_CheckUptimeResponse (uptime 86410) ' => sub {
		plan(1);
		my ($ret,undef)=SIGNALduino_CheckUptimeResponse($targetHash,"86410");
		is($ret,"1 00:00:10","check return message");
	};

	subtest 'Test SIGNALduino_CheckUptimeResponse (uptime 10) ' => sub {
		plan(1);
		my ($ret,undef)=SIGNALduino_CheckUptimeResponse($targetHash,"10");
		is($ret,"0 00:00:10","check return message");
	};

	subtest 'Test SIGNALduino_CheckUptimeResponse (uptime 8641000) ' => sub {
		plan(1);
		my ($ret,undef)=SIGNALduino_CheckUptimeResponse($targetHash,"8641001");
		is($ret,"100 00:16:41","check return message");
	};

	exit(0);
},'dummyDuino');

1;