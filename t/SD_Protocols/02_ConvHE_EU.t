#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{is like};


plan(3);
my $Protocols =
  new lib::SD_Protocols( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );
my $target='some_devcice_name';

subtest 'Test HE_EU, protolength < 72' => sub {
	plan(2);

	my @bits=qw(1 1 0 0 0 1 1 1 1 0 0 0 1 1 1 1 0 0 1 1 0 1 1 0 0 1 1 0 1 1 0 1 1 1 0 0 1 0 0 0 1 1 1 1 0 0 1 0 1 1 1 0 0 1 0 1 1 0 0 0);
	my $rcode;
	note('input '.@bits.' bits');

	($rcode,@bits)=lib::SD_Protocols::ConvHE_EU($Protocols,$target,@bits);
	is($rcode,1,'check returncode for HE_EU transmission');
	is(@bits,72,'check result protolength');
};
	
subtest 'Test HE_EU, protolength == 72' => sub {
	plan(2);

	my @bits=qw(1 1 0 0 0 1 1 1 1 0 0 0 1 1 1 1 0 0 1 1 0 1 1 0 0 1 1 0 1 1 0 1 1 1 0 0 1 0 0 0 1 1 1 1 0 0 1 0 1 1 1 0 0 1 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0);
	my $rcode;

	note('input '.@bits.' bits');
	($rcode,@bits)=lib::SD_Protocols::ConvHE_EU($Protocols,$target,@bits);
	is($rcode,1,'check returncode for HE_EU transmission');
	is(@bits,72,'check result protolength');
};

subtest 'Test HE_EU, protolength > 72' => sub {
	plan(2);

	my @bits=qw(1 1 0 0 0 1 1 1 1 0 0 0 1 1 1 1 0 0 1 1 0 1 1 0 0 1 1 0 1 1 0 1 1 1 0 0 1 0 0 0 1 1 1 1 0 0 1 0 1 1 1 0 0 1 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0);
	my $rcode;

	note('input '.@bits.' bits');
	($rcode,@bits)=lib::SD_Protocols::ConvHE_EU($Protocols,$target,@bits);
	is($rcode,1,'check returncode for HE_EU transmission');
	is(@bits,74,'check result protolength');
};
