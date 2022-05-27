#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{is};

plan(3);

my ($rcode,$bitresult);
my $Protocols =
new lib::SD_Protocols( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );



subtest 'mc2dmc without arguments' => sub {
	plan(1);

	my $bitData='110010'; 
	$bitresult=$Protocols->mc2dmc();
	is($bitresult,q[no bitData provided],q[check result mc2dmc]);
};

subtest 'mc2dmc 1001 => 010' => sub {
	plan(1);

	my $bitData='1001'; 
	$bitresult=$Protocols->mc2dmc($bitData);
	is($bitresult,q[010],q[check result mc2dmc]);
};


subtest 'mc2dmc 110010 => 10100' => sub {
	plan(1);

	my $bitData='110010'; 
	$bitresult=$Protocols->mc2dmc($bitData);
	is($bitresult,q[10100],q[check result mc2dmc]);
};
