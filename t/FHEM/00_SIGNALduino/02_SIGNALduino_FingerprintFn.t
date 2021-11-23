#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{ is };

our %defs;

InternalTimer(time(), sub {
	my $target = shift;
	my $targetHash = $defs{$target};
    plan(2);

    my $dmsg ='W84#FE42004526';
    my ($ret_name,$ret_dmsg) = SIGNALduino_FingerprintFn($targetHash->{NAME},$dmsg);
    is($ret_name ,'','check FingerprintFN name return');
    is($ret_dmsg ,$dmsg,'check FingerprintFN dmsg return');

	exit(0);
},'dummyDuino');

1;