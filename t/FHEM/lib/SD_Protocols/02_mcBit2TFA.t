#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{is};

plan(5);

my $id=5058;
my ($rcode,$hexresult);
my $Protocols =
  new lib::SD_Protocols( filetype => 'json', filename => './t/FHEM/lib/SD_Protocols/test_protocolData.json' );

# Mock protocol for this test
$Protocols->{_protocols}->{5058}{length_min} = 51;
$Protocols->{_protocols}->{5058}{length_max} = 52;

subtest 'MCTFA single transmission' => sub {
	plan(2);

	my $bitData='1111111111010100010111001000000101000100001101001110110010010000'; 
	($rcode,$hexresult)=$Protocols->mcBit2TFA('some_name',$bitData,$id,length $bitData);
	is($rcode,-1,'check returncode for mcBit2Grothe');
	is($hexresult,' no duplicate found','check result mcBit2Grothe');
};

subtest 'MCTFA double transmission' => sub {
	plan(2);
	my $bitData='111111111101010001011100100000010100010000110100111011001001000011111111111010100010111001000000101000100001101001110110010010000';

	($rcode,$hexresult)=$Protocols->mcBit2TFA(undef,$bitData,$id,length $bitData);
	is($rcode,1,'check returncode for mcBit2Grothe without preamble');
	is($hexresult,'45C814434EC90','check result mcBit2Grothe');
};

subtest 'MCTFA double+ transmission' => sub {
	plan(2);
	my $bitData='1111111111010100010111001000000101000100001101001110110010010000111111111110101000101110010000001010001000011010011101100100100001111111111101010001011100100001';

	($rcode,$hexresult)=$Protocols->mcBit2TFA('some_name',$bitData,$id,length $bitData);
	is($rcode,1,"check returncode");
	is($hexresult,"45C814434EC90","check result message");
};
				
subtest 'MCTFA double to short' => sub {
	plan(2);

	my $bitData='1111111111010100010111001000010000000011111111111010100010111001000010000000';

	($rcode,$hexresult)=$Protocols->mcBit2TFA('some_name',$bitData,$id,length $bitData);
	is($rcode,-1,"check returncode");
	like($hexresult,qr/message is to short/,"check result message");
};

				
subtest 'MCTFA double to long' => sub {
	plan(2);
	my $bitData='11111111110101000101110010000100000000000101110010000100000000000101110010000100000000000101110010000100000000000101110010000100000000000101110010000100000000000101110010000100000000111111111110101000101110010000100000000000101110010000100000000000101110010000100000000000101110010000100000000000101110010000100000000000101110010000100000000000101110010000100000000';

	($rcode,$hexresult)=$Protocols->mcBit2TFA('some_name',$bitData,$id,length $bitData);
	is($rcode,-1,"check returncode");
	like($hexresult,qr/message is to long/,"check result message");
};