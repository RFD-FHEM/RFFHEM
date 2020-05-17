#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{ is };
use Test2::Todo;

my $Protocols =
	new lib::SD_Protocols( filetype => 'json', filename => './t/FHEM/lib/SD_Protocols/test_protocolData.json' );
my $target='some_device_name';


my $output;
my $rcode;


plan(4);

subtest 'Test good message' => sub {
	plan(2);
	#MU;P0=32001;P1=-381;P2=835;P3=354;P4=-857;D=01212121212121212121343421212134342121213434342121343421212134213421213421212121342121212134212121213421212121343421343430;CP=2;R=53;
	my @bits=qw(1 0 1 0 0 0 0 0 1 0 0 1 0 0 0 0 0 1 1 1 0 1 0 0 0 0 1 1 0 0 0 0);

	($rcode,@bits)=$Protocols->postDemo_WS7053($target, @bits);
	is($rcode,1, 'check returncode for good message');
	is(join("",@bits),'1010000010010000011101000011011101000000','checkresultforgoodmessage');
};



subtest 'Test bad message, ident' => sub {
	plan(2);

	my @bits=qw(1 0 0 1 0 0 0 0 1 0 0 1 0 0 0 0 0 1 1 1 0 1 0 0 0 0 1 1 0 0 0 0);
	my $return;

	($rcode,$return)=$Protocols->postDemo_WS7053($target, @bits);
	is($rcode,0, 'check returncode for bad message, ident not found');
	is($return,undef,'check result for bad message, ident not found');
};

# Start the todo
my $todo = Test2::Todo->new(reason => 'This test is not prepared, just demo');


subtest 'Test bad message, length' => sub {
	plan(2);

	my @bits=qw(1 0 1 0 0 0 0 0 1 0 0 1 0 0 0 0 0 1 1 1 0 1 0 0 0 0 1 1 0 0 0);
	my $return;

	($rcode,$return)=$Protocols->postDemo_WS7053($target, @bits);
	is($rcode,0, 'check returncode for bad message, length to short');
	is($return,undef,'check result for bad message, length to short');
};


subtest 'Test bad message, parity' => sub {
	plan(2);

	my @bits=qw(1 0 1 0 0 0 0 0 1 0 0 1 0 0 0 0 0 1 1 1 0 1 0 0 0 0 1 1 0 0 0 0);
	my $return;

	($rcode,$return)=$Protocols->postDemo_WS7053($target, @bits);
	is($rcode,0, 'check returncode for bad message, parity not even');
	is($return,undef,'check result for bad message, parity not even');
};


# End the todo
$todo->end;
