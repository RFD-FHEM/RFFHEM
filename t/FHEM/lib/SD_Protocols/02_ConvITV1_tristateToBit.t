#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{ is };

plan(1);
my $Protocols =
  new lib::SD_Protocols( filetype => 'json', filename => './t/FHEM/lib/SD_Protocols/test_protocolData.json' );

subtest 'Test ConvITV1_tristateToBit' => sub {
	plan(2);

	note('Convert 0 -> 00   1 -> 11 F => 01 to be compatible with IT Module');
	my $msg='F00F00FFFFF0';
	my $rcode;

	note("input $msg");
	($rcode,$msg)=$Protocols->ConvITV1_tristateToBit($msg);
	is($rcode,1,'check returncode for ITV1_tristateToBit');
	is($msg,'010000010000010101010100','check result ITV1_tristateToBit');
	note("output $msg");
};