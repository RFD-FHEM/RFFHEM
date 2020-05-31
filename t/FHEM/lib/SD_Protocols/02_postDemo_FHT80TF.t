#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{ is };

my $Protocols =
	new lib::SD_Protocols( filetype => 'json', filename => './t/FHEM/lib/SD_Protocols/test_protocolData.json' );
my $target='some_device_name';


my $output;
my $rcode;


plan(3);

subtest 'Test good message' => sub {
	plan(2);

	# MU;P0=3548;P1=-412;P2=372;P3=580;P4=-614;D=012121212121212121212121343434342134343434343421213421342134212121343434343421342121212121212134343434212134343434212;CP=2;R=55;
	my @bits=qw(0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 0 1 1 1 1 1 1 0 0 1 0 1 0 1 0 0 0 1 1 1 1 1 0 1 0 0 0 0 0 0 0 1 1 1 1 0 0 1 1 1 1 0);

	($rcode,@bits)=$Protocols->postDemo_FHT80TF($target, @bits);
	is($rcode,1, 'check returncode for good message');
	is(join("",@bits),'11101111100101010011111000000001','check result for good message');
};


subtest 'Test bad message, protolength not 45' => sub {
	plan(2);

	# MU;P0=3548;P1=-412;P2=372;P3=580;P4=-614;D=012121212121212121212121343434342134343434343421213421342134212121343434343421342121212121213434343434212134343434212;CP=2;R=55;
	my @bits=qw(0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 0 1 1 1 1 1 1 0 0 1 0 1 0 1 0 0 0 1 1 1 1 1 0 1 0 0 0 0 0 0 1 1 1 1 1 0 0 1 1 1 1 0);
	my $return;

	($rcode,$return)=$Protocols->postDemo_FHT80TF($target, @bits);
	is($rcode,0, 'check returncode for bad message');
	is($return,undef,'check result for bad message');
};


subtest 'Test bad message, all bit are zeros' => sub {
	plan(2);

	# MU;P0=3548;P1=-412;P2=372;P3=580;P4=-614;D=012121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212;CP=2;R=55;
	my @bits=qw(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0);
	my $return;

	($rcode,$return)=$Protocols->postDemo_FHT80TF($target, @bits);
	is($rcode,0, 'check returncode for bad message');
	is($return,undef,'check result for bad message');
};
