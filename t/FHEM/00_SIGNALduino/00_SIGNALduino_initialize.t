#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{ is };
use Test2::Mock;

our %defs;

InternalTimer(time(), sub {
	my $target = shift;
	my $targetHash = $defs{$target};
    plan(8);
    my %dummyHash;
    SIGNALduino_Initialize(\%dummyHash);

    is(FhemTestUtils_gotLog("Error"), 0, q[No errors in logfile]);
    like($dummyHash{AttrList},qr/rfmode:/,q[search RF Mode] );
    
    for ( "SlowRF", "KOPP_FC", "Bresser_5in1" , "Bresser_6in1", "Lacrosse_mode1", "PCA301" )
    {
        like($dummyHash{AttrList},qr/rfmode:.*$_/,qq[RF Mode $_ found] );
    }
    
	exit(0);
},'dummyDuino');

1;
