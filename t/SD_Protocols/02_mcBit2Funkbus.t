#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{is};

plan(3);

my $id=119;
my ($rcode,$hexresult);
my $Protocols =
new lib::SD_Protocols( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );

# Mock protocol for this test
$Protocols->{_protocols}->{119}{length_min} = 47;
$Protocols->{_protocols}->{119}{length_max} = 52;

subtest 'mcBit2Funkbus good message' => sub {
	plan(2);

	my $bitData='1001110101001111001111110111010101010101101000000000'; 
	($rcode,$hexresult)=$Protocols->mcBit2Funkbus(q[some_name],$bitData,$id,length $bitData);
	is($rcode,1,q[check returncode for mcBit2Funkbus]);
	is($hexresult,q[2C175F30008F],q[check result mcBit2Funkbus]);
};

subtest 'mcBit2Funkbus wrong parity' => sub {
	plan(2);

	my $bitData='100111010100111100111111011101010101010110110000000'; 
	($rcode,$hexresult)=$Protocols->mcBit2Funkbus(q[some_name],$bitData,$id,length $bitData);
	is($rcode,-1,q[check returncode for mcBit2Funkbus]);
	is($hexresult,q[parity error],q[check result mcBit2Funkbus]);
};

subtest 'mcBit2Funkbus wrong checksum' => sub {
	plan(2);

	my $bitData='1001110101001111101111110111010101010101101000000000'; 
	($rcode,$hexresult)=$Protocols->mcBit2Funkbus(q[some_name],$bitData,$id,length $bitData);
	is($rcode,-1,q[check returncode for mcBit2Funkbus]);
	is($hexresult,q[checksum error],q[check result mcBit2Funkbus]);
};