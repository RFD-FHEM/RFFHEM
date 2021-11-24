#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{is};

plan(4);

my $id=9986;
my ($rcode,$hexresult);
my $Protocols =
  new lib::SD_Protocols( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );

subtest 'message good' => sub {
	plan(2);

	my $bitData='00100011110000010010100111011001111001111';  # > 010001111001000001000111011000101000000000111111  > P96#47904762803F

	($rcode,$hexresult)=$Protocols->mcBit2Grothe('some_name',$bitData,$id,length $bitData);
	is($rcode,1,'check returncode for mcBit2Grothe');
	is($hexresult,'478253B3CF','check result hex string');
};

subtest 'message without preamble 01000111' => sub {
	plan(2);
	my $bitData='00101011110000010010100111011001111001111';

	($rcode,$hexresult)=$Protocols->mcBit2Grothe(undef,$bitData,$id,length $bitData);
	is($rcode,-1,'check returncode for mcBit2Grothe without preamble');
	is($hexresult,'Start pattern (01000111) not found','check result mcBit2Grothe without preamble');
};

subtest 'message to short' => sub {
	plan(2);
	my $bitData='001000111100000100101001110110011110011';

	($rcode,$hexresult)=$Protocols->mcBit2Grothe('some_name',$bitData,$id,length $bitData);
	is($rcode,-1,'check returncode for mcBit2Grothe message to short');
	is($hexresult,'message is to short','check result mcBit2Grothe message to short');
};
				
subtest 'message to long' => sub {
	plan(2);

	my $bitData='00100011110000010010100111011001111001111000000000000000000000000000';

	($rcode,$hexresult)=$Protocols->mcBit2Grothe('some_name',$bitData,$id,length $bitData);
	is($rcode,-1,'check returncode for mcBit2Grothe');
	is($hexresult,'message is to long','check result message is to long');
};
