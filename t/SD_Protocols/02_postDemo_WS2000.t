#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{ is };
use Test2::Todo;

my $Protocols =
	new lib::SD_Protocols( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );
my $target='some_device_name';


my $output;
my $rcode;


plan(8);

subtest 'Test good message' => sub {
	plan(2);
	#MU;P0=32001;P1=-381;P2=835;P3=354;P4=-857;D=01212121212121212121343421212134342121213434342121343421212134213421213421212121342121212134212121213421212121343421343430;CP=2;R=53;
	my @bits=qw(0 0 0 0 0 0 0 0 0 1 1 0 0 0 1 1 0 0 0 1 1 1 0 0 1 1 0 0 0 1 0 1 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 1 0 1 1);

	($rcode,@bits)=$Protocols->postDemo_WS2000($target, @bits);
	is($rcode,1, 'check returncode for good message');
	is(join("",@bits),'00010001000100110000001000000000','checkresultforgoodmessage');
};


subtest 'Test bad message, all bits are zeos' => sub {
	plan(2);

	my @bits=qw(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0);
	my $return;

	($rcode,$return)=$Protocols->postDemo_WS2000($target, @bits);
	is($rcode,0, 'check returncode for bad message, all bits are 0');
	is($return,undef,'check result for bad message, all bits are 0');
};

subtest 'Test bad message, every 5. bit' => sub {
	plan(2);
	#MU;P0=-14912;P1=822;P2=-430;P3=343;P4=-898;D=01212121212121212121234341212121212121212341212121234341212343434121212341212121234123434123412123412343434123434341234123;CP=3;
	my @bits=qw(0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 1 0 0 0 0 1 1 0 0 1 1 1 0 0 0 1 0 0 0 0 1 0 1 1 0 1 0 0 1 0 1 1 1 0 1 1 1 0 1 0);
	my $return;

	($rcode,$return)=$Protocols->postDemo_WS2000($target, @bits);
	is($rcode,0, 'check returncode for bad message, check every 5. bit fails');
	is($return,undef,'check result for bad message, check every 5. bit fails');
};

subtest 'Test bad message, preamble' => sub {
	plan(2);

	my @bits=qw(0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 1 1 0 0 0 1 1 1 0 0 1 1 0 0 0 1 0 1 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 1 0 1 1);
	my $return;

	($rcode,$return)=$Protocols->postDemo_WS2000($target, @bits);
	is($rcode,0, 'check returncode for bad message, preambele to long');
	is($return,undef,'check result for bad message, preambele to long');
};

subtest 'Test bad message, type to big' => sub {
	plan(2);
	#MU;P0=-14912;P1=822;P2=-430;P3=343;P4=-898;D=01212121212121212121212341212123412121212341212121234341212343434121212341212121234123434123412123412343434123434341234123;CP=3;
	my @bits=qw(0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 1 0 0 0 0 1 0 0 0 0 1 1 0 0 1 1 1 0 0 0 1 0 0 0 0 1 0 1 1 0 1 0 0 1 0 1 1 1 0 1 1 1 0 1 0);
	my $return;
	
	($rcode,$return)=$Protocols->postDemo_WS2000($target, @bits);
	is($rcode,0, 'check returncode for bad message, type is to big');
	is($return,undef,'check result for bad message, type is to big');
};


subtest 'Test bad message, length' => sub {
	plan(2);
	#MU;P0=-14912;P1=822;P2=-430;P3=343;P4=-898;D=012121212121212121212343412121234121212123412121212343412123434341212123412121212341234341234121234123434341234343412341;CP=3;
	my @bits=qw(0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 1 0 0 0 0 1 0 0 0 0 1 1 0 0 1 1 1 0 0 0 1 0 0 0 0 1 0 1 1 0 1 0 0 1 0 1 1 1 0 1 1 1 0 1);
	my $return;

	($rcode,$return)=$Protocols->postDemo_WS2000($target, @bits);
	is($rcode,0, 'check returncode for bad message, length mismatch');
	is($return,undef,'check result for bad message, length mismatch');
};


subtest 'Test bad message, xor mismatch' => sub {
	plan(2);
	#MU;P0=-14912;P1=822;P2=-430;P3=343;P4=-898;D=01212121212121212121234343412123412121212341212121234341212343434121212341212121234123434123412123412343434123434341234123;CP=3;
	my @bits=qw(0 0 0 0 0 0 0 0 0 0 1 1 1 0 0 1 0 0 0 0 1 0 0 0 0 1 1 0 0 1 1 1 0 0 0 1 0 0 0 0 1 0 1 1 0 1 0 0 1 0 1 1 1 0 1 1 1 0 1 0);
	my $return;

	($rcode,$return)=$Protocols->postDemo_WS2000($target, @bits);
	is($rcode,0, 'check returncode for bad message, xor mismatch');
	is($return,undef,'check result for bad message, xor mismatch');
};

subtest 'Test bad message, sum mismatch' => sub {
	plan(2);
	#MU;P0=-14912;P1=822;P2=-430;P3=343;P4=-898;D=01212121212121212121234341212123412121212341212121234341212343434121212341212121234123434123412123412343434123434341234343;CP=3;
	my @bits=qw(0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 1 0 0 0 0 1 0 0 0 0 1 1 0 0 1 1 1 0 0 0 1 0 0 0 0 1 0 1 1 0 1 0 0 1 0 1 1 1 0 1 1 1 0 1 1);
	my $return;

	($rcode,$return)=$Protocols->postDemo_WS2000($target, @bits);
	is($rcode,0, 'check returncode for bad message, sum mismatch');
	is($return,undef,'check result for bad message, sum mismatch');
};

