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


plan(4);

subtest 'Test good message' => sub {
	plan(2);

	# MU;P0=13312;P1=-2785;P2=4985;P3=1124;P4=-6442;P5=3181;P6=-31980;D=0121345434545454545434545454543454545434343454543434545434545454545454343434545434343434545621213454345454545454345454545434545454343434545434345454345454545454543434345454343434345456212134543454545454543454545454345454543434345454343454543454545454545;CP=3;R=73;O;
	my @bits=qw(1 0 1 0 0 0 0 0 1 0 0 0 0 1 0 0 0 1 1 1 0 0 1 1 0 0 1 0 0 0 0 0 0 1 1 1 0 0 1 1 1 1 0 0);

	($rcode,@bits)=$Protocols->postDemo_WS7035($target, @bits);
	is($rcode,1, 'check returncode for good message');
	is(join("",@bits),'1010000010000100011100110010011100111100','check result for good message');
};


subtest 'Test bad message, Ident not 1010 0000' => sub {
	plan(2);

	# MU;P0=13312;P1=-2785;P2=4985;P3=1124;P4=-6442;P5=3181;P6=-31980;D=0134345434545454545434545454543454545434343454543434545434545454545454343434545434343434545621213434345454545454345454545434545454343434545434345454345454545454543434345454343434345456212134543454545454543454545454345454543434345454343454543454545454545;CP=3;R=73;O;
	my @bits=qw(1 1 1 0 0 0 0 0 1 0 0 0 0 1 0 0 0 1 1 1 0 0 1 1 0 0 1 0 0 0 0 0 0 1 1 1 0 0 1 1 1 1 0 0);
	my $return;

	($rcode,$return)=$Protocols->postDemo_WS7035($target, @bits);
	is($rcode,0, 'check returncode for bad message, Ident not 1010 0000');
	is($return,undef,'check result for bad message, Ident not 1010 0000');
};


subtest 'Test bad message, Parity not even' => sub {
	plan(2);

	# MU;P0=13312;P1=-2785;P2=4985;P3=1124;P4=-6442;P5=3181;P6=-31980;D=0121345434545454545434545454543454545454343454543434545434545454545454343434545434343434545;CP=3;R=73;
	my @bits=qw(1 0 1 0 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 1 0 0 1 1 0 0 1 0 0 0 0 0 0 1 1 1 0 0 1 1 1 1 0 0);
	my $return;

	($rcode,$return)=$Protocols->postDemo_WS7035($target, @bits);
	is($rcode,0, 'check returncode for bad message, Parity not even');
	is($return,undef,'check result for bad message, Parity not even');
};


subtest 'Test bad message, wrong checksum' => sub {
	plan(2);

	# MU;P0=13312;P1=-2785;P2=4985;P3=1124;P4=-6442;P5=3181;P6=-31980;D=0121345434545454545434545454543454545434343454543434545434545454545454343434545434343434345;CP=3;R=73;
	my @bits=qw(1 0 1 0 0 0 0 0 1 0 0 0 0 1 0 0 0 1 1 1 0 0 1 1 0 0 1 0 0 0 0 0 0 1 1 1 0 0 1 1 1 1 1 0);
	my $return;

	($rcode,$return)=$Protocols->postDemo_WS7035($target, @bits);
	is($rcode,0, 'check returncode for bad message, wrong checksum');
	is($return,undef,'check result for bad message, wrong checksum');
};
