#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{ is };

our %defs;

InternalTimer(time(), sub {
	my $target = shift;
	my $targetHash = $defs{$target};
    plan(3);
    my %validationHash;
    SIGNALduino_Initialize(\%validationHash);

    is(FhemTestUtils_gotLog("Error"), 0, q[No errors in logfile]);
    like($validationHash{AttrList},qr/rfmode:/,q[search RF Mode] );
    
    my ($attrRFmodes) = grep {$_ =~ /^rfmode:/ } split (" ", $validationHash{AttrList}) ; 
    my @rfmodes = split (",",$attrRFmodes);
    
    # Itmes must be in sorted order
    is(\@rfmodes,array {
            item 'rfmode:Avantek';
            item 'Bresser_5in1';
            item 'Bresser_6in1';
            item 'KOPP_FC';
            item 'Lacrosse_mode1';
            item 'Lacrosse_mode2';
            item 'PCA301';
            item 'Rojaflex';
            item 'SlowRF';
            
            etc();
        }    
     ,q[Test rfmodes and order]);
   
	exit(0);
},'dummyDuino');

1;
