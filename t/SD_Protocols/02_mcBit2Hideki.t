#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{is};
use Test2::Todo;

plan(6);

my $id=5012;
my ($rcode,$hexresult);
my $Protocols =
  new lib::SD_Protocols( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );

# Mock protocol for this test
$Protocols->{_protocols}->{5012}{length_min} = 71;
$Protocols->{_protocols}->{5012}{length_max} = 128;


subtest 'message good' => sub {
	plan(2);

	my $bitdata='101010001100001000110011101101010011101000111110000010100000011110000011';

	($rcode,$hexresult)=$Protocols->mcBit2Hideki(undef,$bitdata,$id,length $bitdata);
	is($rcode,1,'check returncode for Hideki transmission');
	is($hexresult,'75EF46351DBE3F3E','check result for single Hideki transmission');			
};


subtest 'message without preamble' => sub {
	plan(2);

	my $bitdata='010001100001000110011101101010011101000111110000010100000011110000011';

	($rcode,$hexresult)=$Protocols->mcBit2Hideki(undef,$bitdata,$id,length $bitdata);
	is($rcode,-1,'check returncode for Hideki transmission');
	is($hexresult,U(),'check result for single Hideki transmission');			
};


subtest 'message is to short' => sub {
	plan(2);

	my $bitdata='10101000110000100011001110110101001110100011111000001';

	($rcode,$hexresult)=$Protocols->mcBit2Hideki(undef,$bitdata,$id,length $bitdata);
	is($rcode,-1,'check returncode for Hideki transmission');
	is($hexresult,' message is to short','check result message to short');
};


subtest 'message is to long' => sub {
	plan(2);

	my $bitdata='10101000110000100011001110110101001110100011111000001010000001111000001100000000000000000000000000000000000000000000000000001111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000101010100000000000000000000000000';

	($rcode,$hexresult)=$Protocols->mcBit2Hideki(undef,$bitdata,$id,length $bitdata);
	is($rcode,-1,'check returncode for Hideki transmission');
	is($hexresult,' message is to long','check result message to long');
};


subtest 'message is inverted' => sub {
	plan(2);

	my $bitdata='10101000111001001111010001011010111011011111010000001010111110010111010110010101011101100110';

	($rcode,$hexresult)=$Protocols->mcBit2Hideki(undef,$bitdata,$id,length $bitdata);
	is($rcode,1,'check returncode for Hideki transmission');
	is($hexresult,'7536BA8A82BFC151AB6401','check result');
};


subtest 'message had 89 bits' => sub {
	plan(2);

	my $bitdata='01010001100100100110100010110101110100110111110000010101110111101101010110000000110111001000';

	($rcode,$hexresult)=$Protocols->mcBit2Hideki(undef,$bitdata,$id,89);
	is($rcode,1,'check returncode for Hideki transmission');
	is($hexresult,'75DBBA8A13BE11A9FE6203','check result');
};
