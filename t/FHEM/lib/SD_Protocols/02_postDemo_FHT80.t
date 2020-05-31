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

	# MU;P0=2084;P1=-413;P2=396;P5=585;P6=-583;D=012121212121212121212121562121215621565621562121215621565656212156565656565621212156565621565656212121215621215621212156212121212121562;CP=2;R=85;
	my @bits=qw(0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 1 0 1 1 0 1 0 0 0 1 0 1 1 1 0 0 1 1 1 1 1 1 0 0 0 1 1 1 0 1 1 1 0 0 0 0 1 0 0 1 0 0 0 1 0 0 0 0 0 0 1);

	($rcode,@bits)=$Protocols->postDemo_FHT80($target, @bits);
	is($rcode,1, 'check returncode for good message');
	is(join("",@bits),'000101100001011101111110000000000111011100010010','check result for good message');
};


subtest 'Test bad message, all bit are zeros' => sub {
	plan(2);

	# MU;P0=2084;P1=-413;P2=396;P5=585;P6=-583;D=012121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212;CP=2;R=85;
	my @bits=qw(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0);
	my $return;

	($rcode,$return)=$Protocols->postDemo_FHT80($target, @bits);
	is($rcode,0, 'check returncode for bad message, all bit are zeros');
	is($return,undef,'check result for bad message, all bit are zeros');
};


subtest 'Test bad message, wrong length' => sub {
	plan(2);

	my @bits=qw(0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 1 0 1 1 0 1 0 0 0 1 0 1 1 1 0 0 0 0 0 0 0 0 0 0 1 0 1 0 1 0 1 0 0 0 0 0 0 0 0 0 0 0 1);
	my $return;

	($rcode,$return)=$Protocols->postDemo_FHT80($target, @bits);
	is($rcode,0, 'check returncode for bad message, wrong length');
	is($return,undef,'check result for bad message, wrong length');
};