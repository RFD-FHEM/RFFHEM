#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{ is };

our %defs;

InternalTimer(time(), sub {
	my $target = shift;
	my $targetHash = $defs{$target};
    plan(8);
    my %validationHash;
    SIGNALduino_Initialize(\%validationHash);

    is(FhemTestUtils_gotLog("Error"), 0, q[No errors in logfile]);
    like($validationHash{AttrList},qr/rfmode:/,q[search RF Mode] );
    
    for ( "SlowRF", "KOPP_FC", "Bresser_5in1" , "Bresser_6in1", "Lacrosse_mode1", "PCA301" )
    {
        like($validationHash{AttrList},qr/rfmode:.*$_/,qq[RF Mode $_ found] );
    }
    
	exit(0);
},'dummyDuino');

1;
