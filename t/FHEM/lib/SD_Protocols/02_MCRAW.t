#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{is like};

plan(2);

my $id=9989;
my ($rcode,$hexstring);
my $Protocols =
  new lib::SD_Protocols( filetype => 'json', filename => './t/FHEM/lib/SD_Protocols/test_protocolData.json' );

subtest 'message good' => sub {
	plan(2);

	my $bitData="001010101010010010100111";

	($rcode,$hexstring)=$Protocols->MCRAW('some_name',$bitData,$id,length $bitData);
	is($rcode,1,'check returncode for MCRAW');
	is($hexstring,'2AA4A7','check result hex string');
};

subtest 'message to long' => sub {
	plan(2);

	my $bitData="0010101010100100101001110011";

	($rcode,$hexstring)=$Protocols->MCRAW('some_name',$bitData,$id,length $bitData);
	is($rcode,-1,'check returncode for MCRAW');
	is($hexstring,' message is to long','check result message is to long');
};
