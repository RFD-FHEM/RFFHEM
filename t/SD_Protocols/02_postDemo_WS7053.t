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


plan(4);

subtest 'Test good message' => sub {
	plan(2);
	#MU;P0=3381;P1=-672;P2=-4628;P3=1142;P4=-30768;D=010232023202020202023202023202020232023232320232320202020202020202040102320232020202020232020232020202320232323202323202020202020202020;CP=0;R=45;
	my @bits=qw(1 0 1 0 0 0 0 0 1 0 0 1 0 0 0 0 0 1 1 1 0 1 0 0 0 0 1 1 0 0 0 0);

	($rcode,@bits)=$Protocols->postDemo_WS7053($target, @bits);
	is($rcode,1, 'check returncode for good message');
	is(join("",@bits),'1010000010010000011101000011011101000000','checkresultforgoodmessage');
};


subtest 'Test bad message, ident' => sub {
	plan(2);
	#MU;P0=3381;P1=-672;P2=-4628;P3=1142;P4=-30768;D=010232023202023202023202023202020232023232320232320202020202020202040102320232020202020232020232020202320232323202323202020202020202020;CP=0;R=45;
	my @bits=qw(1 0 1 0 0 1 0 0 1 0 0 1 0 0 0 1 0 1 1 1 0 1 1 0 0 0 0 0 0 0 0 0);
	my $return;

	($rcode,$return)=$Protocols->postDemo_WS7053($target, @bits);
	is($rcode,0, 'check returncode for bad message, ident not found');
	is($return,undef,'check result for bad message, ident not found');
};


subtest 'Test bad message, length' => sub {
	plan(2);
	my @bits=qw(1 0 1 0 0 0 0 0 1 0 0 1 0 0 0 1 0 1 1 1 0 1 1 0 0 0 0 0 0 0 0);
	my $return;

	($rcode,$return)=$Protocols->postDemo_WS7053($target, @bits);
	is($rcode,0, 'check returncode for bad message, length to short');
	is($return,undef,'check result for bad message, length to short');
};


subtest 'Test bad message, parity' => sub {
	plan(2);
	#MU;P0=3381;P1=-672;P2=-4628;P3=1142;P4=-30768;D=0102320232020202020202020202020202020232323202323202020202020202020;CP=0;R=45;
	my @bits=qw(1 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 0 1 1 0 0 0 0 0 0 0 0 0);
	my $return;

	($rcode,$return)=$Protocols->postDemo_WS7053($target, @bits);
	is($rcode,0, 'check returncode for bad message, parity not even');
	is($return,undef,'check result for bad message, parity not even');
};
