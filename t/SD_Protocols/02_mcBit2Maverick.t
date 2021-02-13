#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{is};
use Test2::Todo;

plan(2);

my $id=5047;
my ($rcode,$hexresult);
my $Protocols =
  new lib::SD_Protocols( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );

# Mock protocol for this test
$Protocols->{_protocols}->{5047}{length_min} = 100;
$Protocols->{_protocols}->{5047}{length_max} = 100;



subtest 'valid Maverick header detected' => sub {
	plan(2);

	my $bitdata='10101010100110011001010101011001100101011001100110101001010110011001100101100110100110011010100101101001';

	($rcode,$hexresult)=$Protocols->mcBit2Maverick(undef,$bitdata,$id,length $bitdata);
	is($rcode,1,'check returncode for single Maverick transmission');
	is($hexresult,'599599A959996699A969','check Maverick single HOregon PIRideki transmission');			
};


subtest 'no Maverick header found' => sub {
	plan(2);

	my $bitdata='11111110100110011001010101011001100101011001100110101001010110011001100101100110100110011010100101101001';

	($rcode,$hexresult)=$Protocols->mcBit2Maverick(undef,$bitdata,$id,length $bitdata);
	is($rcode,-1,'check returncode for single Maverick transmission');
	is($hexresult,U(),'check result for Maverick message to short');
};