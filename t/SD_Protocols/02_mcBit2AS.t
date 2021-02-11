#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{is};
use Test2::Todo;

plan(4);

my $id=5011;
my ($rcode,$hexresult);
my $Protocols =
  new lib::SD_Protocols( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );

# Mock protocol for this test
$Protocols->{_protocols}->{5011}{length_min} = 52;
$Protocols->{_protocols}->{5011}{length_max} = 56;


subtest 'message good' => sub {
	plan(2);

	my $bitdata='000000000000000011001010101010100000101010101010101010100000101010101010';

	($rcode,$hexresult)=$Protocols->mcBit2AS(undef,$bitdata,$id,length $bitdata);
	is($rcode,1,'check returncode for single AS transmission');
	is($hexresult,'CAAA0AAAAA0AAA','check result for single AS transmission');			
};


subtest 'message without preamble' => sub {
	plan(2);

	my $bitdata='000000000000101001010101010101010101010101010101000000000';

	($rcode,$hexresult)=$Protocols->mcBit2AS(undef,$bitdata,$id,length $bitdata);
	is($rcode,-1,'check returncode for single AS transmission');
	is($hexresult,U(),'check result for single AS transmission');			
};


subtest 'message is to short' => sub {
	plan(2);

	my $bitdata='000000000000000011001010101010101010101010101010';

	($rcode,$hexresult)=$Protocols->mcBit2AS(undef,$bitdata,$id,length $bitdata);
	is($rcode,-1,'check returncode for single OSV1 transmission');
	is($hexresult,' message is to short','check result message to short');
};


subtest 'message is to long' => sub {
	plan(2);

	my $bitdata='000000000000000011000000000000001010101010101010101010101010101000001010101010100000100001101111111110100000000000001010';

	($rcode,$hexresult)=$Protocols->mcBit2AS(undef,$bitdata,$id,length $bitdata);
	is($rcode,-1,'check returncode for single OSV1 transmission');
	is($hexresult,' message is to long','check result message to long');
};