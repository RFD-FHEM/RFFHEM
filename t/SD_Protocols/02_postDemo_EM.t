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

subtest 'Test CRC OK' => sub {
	plan(2);

	# MU;P1=-417;P2=385;P3=-815;P4=-12058;D=42121212121212121212121212121212121232321212121212121232321212121212121232323212323212321232121212321212123232121212321212121232323212121212121232121212121212121232323212121212123232321232121212121232123232323212321;CP=2;R=87;
	my @bits=qw(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 1 1 1 0 1 1 0 1 0 1 0 0 0 1 0 0 0 1 1 0 0 0 1 0 0 0 0 1 1 1 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 1 1 1 0 0 0 0 0 1 1 1 0 1 0 0 0 0 0 1 0 1 1 1 1 0 1 0);

	($rcode,@bits)=lib::SD_Protocols::postDemo_EM($Protocols,$target,@bits);
	is($rcode,1,'check returncode for postDemo_EM, CRC OK');
	is(join("",@bits),'000000010000000101011011100010000000100000000011000000001000001100000101','check result postDemo_EM, CRC OK');
};


subtest 'Test CRC ERROR' => sub {
	plan(2);

	# MU;P1=-417;P2=385;P3=-815;P4=-12058;D=42121212121212121212121212121212121232321212121212121232321212121212121232323212323212321232121212321212123232121212321212121232323212121212121232121212121212121232323212121212123232321232321212123232123232323212321;CP=2;R=87;
	my @bits=qw(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 1 1 1 0 1 1 0 1 0 1 0 0 0 1 0 0 0 1 1 0 0 0 1 0 0 0 0 1 1 1 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 1 1 1 0 0 0 0 0 1 1 1 0 1 1 0 0 0 1 1 0 1 1 1 1 0 1 0);

	($rcode,$output)=lib::SD_Protocols::postDemo_EM($Protocols,$target,@bits);
	is($rcode,0,'check returncode for postDemo_EM, CRC ERROR');
	is($output,undef,'check result postDemo_EM, CRC ERROR');
};


subtest 'Test length 89 not correct' => sub {
	plan(2);

	# MU;P1=-417;P2=385;P3=-815;P4=-12058;D=4212121212121212121212121212121212123232121212121212123232121212121212123232321232321232123212121232121212323212121232121212123232321212121212123212121212121212123232321212121212323232123212121212123212323232321232123212321;CP=2;R=87;
	my @bits=qw(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 1 1 1 0 1 1 0 1 0 1 0 0 0 1 0 0 0 1 1 0 0 0 1 0 0 0 0 1 1 1 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 1 1 1 0 0 0 0 0 1 1 1 0 1 0 0 0 0 0 1 0 1 1 1 1 0 1 0 1 0 1 0);
	note('input '.@bits.' bits');

	($rcode,$output)=lib::SD_Protocols::postDemo_EM($Protocols,$target,@bits);
	is($rcode,0,'check returncode for postDemo_EM, length not correct');
	is($output,undef,'check result postDemo_EM, length not correct');
};


subtest 'Test start not found ' => sub {
	plan(2);

	# MU;P1=-417;P2=385;P3=-815;P4=-12058;D=42121212121212121212121212121212121212121212121212121232321212121212121232323212323212321232121212321212123232121212321212121232323212121212121232121212121212121232323212121212123232321232121212121232123232323212321;CP=2;R=87;
	my @bits=qw(0 0 0 0 0 1 1 0 0 0 0 0 0 0 1 1 1 0 1 1 0 1 0 1 0 0 0 1 0 0 0 1 1 0 0 0 1 0 0 0 0 1 1 1 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 1 1 1 0 0 0 0 0 1 1 1 0 1 0 0 0 0 0 1 0 1 1 1 1 0 1 0);
	note('msg start 0000000001, index '.index(join("",@bits), '0000000001'));

	($rcode,@bits)=lib::SD_Protocols::postDemo_EM($Protocols,$target,@bits);
	is($rcode,0,'check returncode for postDemo_EM, Start not found');
	is($output,undef,'check result postDemo_EM, Start not found');
};
