#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{is};

my $Protocols =
new lib::SD_Protocols( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );
	

my $rcode;
my $msg;


plan(2);

subtest 'input bits with F' => sub {
	plan(2);

	my @bits=qw(0 1 0 0 0 1 0 1 0 F 0 F 0 F 0 F 0 0 0 1 0 1 0 1);
	($rcode,@bits)=$Protocols->Convbit2itv1('undef',@bits);

	is($rcode,1,'check returncode from input with F');
	is(join("",@bits),'010001010101010100010101','check result for input with F');
};


subtest 'input bits without F' => sub {
	plan(2);

	# MS;P1=309;P2=-1130;P3=1011;P4=-429;P5=-11466;D=15123412121234123412141214121412141212123412341234;CP=1;SP=5;R=38;
	my @bits=qw(0 1 0 0 0 1 0 1 0 1 0 1 0 1 0 1 0 0 0 1 0 1 0 1);

	($rcode,@bits)=$Protocols->Convbit2itv1('undef',@bits);

	is($rcode,1,'check returncode from input without F');
	is(join("",@bits),'010001010101010100010101','check result for input without F');
};
