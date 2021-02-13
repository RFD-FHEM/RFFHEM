#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{ is };

my $Protocols =
	new lib::SD_Protocols( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );
my $target='some_device_name';

plan(4);

my $output;
my $rcode;


subtest 'Test good message' => sub {
	plan(2);

	# MS;P1=-354;P2=449;P3=646;P4=-558;P5=-10408;D=2521212121212121212121212134212121343421212121213421213421212121212121212121212121212121342121212134213434342134342134;CP=2;SP=5;R=15;O;
	my $rcode;
	my @bits=qw(0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 1 1 0 0 0 0 0 1 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 1 0 1 1 1 0 1 1 0 1);

	($rcode,@bits)=$Protocols->postDemo_FS20($target, @bits);
	is($rcode,1, 'check returncode for good message');
	is(join("",@bits),'0001100001001000000000000000000000010000','check result for good message');
};


my $return;

subtest 'Test bad message, all bit are zeros' => sub {
	plan(2);

	# MS;P1=-354;P2=449;P3=646;P4=-558;P5=-10408;D=2521212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121;CP=2;SP=5;R=15;O;
	my @bits=qw(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0);
	my $rcode;

	($rcode,$return)=$Protocols->postDemo_FS20($target, @bits);
	is($rcode,0, 'check returncode for bad message, all bit are zeros');
	is($return,undef,'check result for bad message, all bit are zeros');
};


subtest 'Test bad message, Detection aborted' => sub {
	plan(2);

	my @bits=qw(0 0 0 0 0 0 0 0 0 0 0 1 0 0 1 0 0 0 0 0 1 0 0 1 0 1 1 0 0 1 0 0 0 0 0 0 0 0 0 1 0 1 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 0 1);
	my $rcode;

	($rcode,$return)=$Protocols->postDemo_FS20($target, @bits);
	is($rcode,0, 'check returncode for bad message, Detection aborted');
	is($return,undef,'check result for bad message, Detection aborted');
};


subtest 'Test bad message, wrong length' => sub {
	plan(2);

	my @bits=qw(0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 1 0 0 0 0 0 1 0 0 1 0 1 1 0 0 1 0 0 0 0 0 0 0 0 0 1 0 1 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0);
	my $rcode;

	($rcode,$return)=$Protocols->postDemo_FS20($target, @bits);
	is($rcode,0, 'check returncode for bad message, wrong length');
	is($return,undef,'check result for bad message, wrong length');
};
