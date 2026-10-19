#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{ is };
use Cwd qw(getcwd abs_path);
use File::Temp qw(tempdir);

our %defs;

InternalTimer(time(), sub {
	my $target = shift;
	my $targetHash = $defs{$target};
    my %validationHash;
    SIGNALduino_Initialize(\%validationHash);

    is(FhemTestUtils_gotLog("Error"), 0, q[No errors in logfile]);
    like($validationHash{AttrList},qr/rfmode:/,q[search RF Mode] );
    
    my ($attrRFmodes) = grep {$_ =~ /^rfmode:/ } split (" ", $validationHash{AttrList}) ; 
    my @rfmodes = split (",",$attrRFmodes);
    
    # Itmes must be in sorted order
    is(\@rfmodes,bag {
            item 'rfmode:Avantek';
            item 'Bresser_5in1';
            item 'Bresser_6in1';
            item 'Fine_Offset_WH51_434';
            item 'Fine_Offset_WH51_868';
            item 'KOPP_FC';
            item 'Lacrosse_mode1';
            item 'Lacrosse_mode2';
            item 'PCA301';
            item 'Rojaflex';
            item 'SlowRF';            
            etc();
        }    
     ,q[Test rfmodes and order]);
     
     FhemTestUtils_resetLogs();
},'dummyDuino');


InternalTimer(time()+0.05, sub {
    # Protocol hash must be found via modpath, not relative to the working directory
    my %validationHash;
    my $cwd = getcwd();
    my $modpath = $attr{global}{modpath};
    $attr{global}{modpath} = abs_path($modpath);
    my $tmpdir = tempdir( CLEANUP => 1 );
    chdir $tmpdir;
    SIGNALduino_Initialize(\%validationHash);
    chdir $cwd;
    $attr{global}{modpath} = $modpath;

    is(FhemTestUtils_gotLog("Error loading Protocol Hash"), 0, q[Protocol hash loaded with working directory outside modpath]);
    ok(defined $validationHash{protocolObject}, q[protocolObject is set]);
    FhemTestUtils_resetLogs();
},'dummyDuino');


InternalTimer(time()+0.11, sub {
	my $target = shift;
	my $targetHash = $defs{$target};
    my %validationHash;
    no warnings qw(redefine);
    CommandReload(undef,"00_SIGNALduino.pm");
    use warnings qw(redefine);
    SIGNALduino_Initialize(\%validationHash);

    is(FhemTestUtils_gotLog("Error"), 0, q[No JSON errors in logfile]);
    done_testing();

    eval q[ no Test::Without::Module qw( JSON ) ];

	exit(0);
},'dummyDuino');

1;
