#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{is};
use Test2::Todo;

plan(4);

my $id=5018;
my ($rcode,$hexresult);
my $Protocols =
  new lib::SD_Protocols( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );

# Mock protocol for this test
$Protocols->{_protocols}->{5018}{length_min} = 32;
$Protocols->{_protocols}->{5018}{length_max} = 32;


subtest 'message good' => sub {
	plan(2);

	my $bitdata='11100101101011100000000010111000';

	($rcode,$hexresult)=$Protocols->mcBit2OSV1(undef,$bitdata,$id,length $bitdata);
	is($rcode,1,'check returncode for single OSV1 transmission');
	is($hexresult,'500A4D3007500700002700','check result for single OSV1 transmission');			
};


subtest 'message ERROR checksum' => sub {
	plan(2);

	my $bitdata='11100101101000000000000010111000';

	($rcode,$hexresult)=$Protocols->mcBit2OSV1(undef,$bitdata,$id,length $bitdata);
	is($rcode,-1,'check returncode for single OSV1 transmission');
	is($hexresult,'OSV1 - ERROR checksum not equal: 172 != 29','check ERROR checksum');			
};


subtest 'message is to short' => sub {
	plan(2);

	my $bitdata='111001011010111000000000101110';

	($rcode,$hexresult)=$Protocols->mcBit2OSV1(undef,$bitdata,$id,length $bitdata);
	is($rcode,-1,'check returncode for single OSV1 transmission');
	is($hexresult,' message is to short','check result message to short');
};


subtest 'message is to long' => sub {
	plan(2);

	my $bitdata='1110010110101110000000001011100011';

	($rcode,$hexresult)=$Protocols->mcBit2OSV1(undef,$bitdata,$id,length $bitdata);
	is($rcode,-1,'check returncode for single OSV1 transmission');
	is($hexresult,' message is to long','check result message to long');
};