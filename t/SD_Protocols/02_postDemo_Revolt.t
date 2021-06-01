#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{ is };

my $Protocols =
	new lib::SD_Protocols( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );
my $target='some_device_name';

plan(2);

my $output;
my $rcode;

subtest 'Test CRC OK' => sub {
	plan(2);
	# MU;P0=143;P1=-218;P2=11620;P3=-332;P5=264;D=01230151515101015151015101515101510151515101015101010101010101010101010101010101010101015151010151010101010101010101010101010101010101010101010101010151015101010151010101015151015101510101010101510151015151010150;CP=0;R=0;
	my @bits=qw(0 1 1 1 0 0 1 1 0 1 0 1 1 0 1 0 1 1 1 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 1 0 0 0 1 0 0 0 0 1 1 0 1 0 1 0 0 0 0 0 1 0 1 0 1 1 0 0 1);

	($rcode,@bits)=lib::SD_Protocols::postDemo_Revolt($Protocols,$target,@bits);
	is($rcode,1,'check returncode for postDemo_Revolt, CRC OK');
	is(join("",@bits),'0111001101011010111001000000000000000000001100100000000000000000000000000101000100001101','check result postDemo_Revolt, CRC OK');
};


subtest 'Test CRC ERROR' => sub {
	plan(2);
	# MU;P1=10300;P2=-348;P3=112;P4=-254;P5=233;D=1234543434343434343434343434343434343434343434343434343454345454343454345434343454343454345434343454545434343434345454343434343434343434343434343454345454343454345434343454343454345434343454545434343434345450;CP=3;R=0;
	my @bits=qw(0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 1 1 0 0 1 0 1 0 0 0 1 0 0 1 0 1 0 0 0 1 1 1 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 1 1 0 0 1 0 1 0 0 0 1 0 0 1 0 1 0 0 0 1 1 1 0 0 0 0 0 1 1);

	($rcode,$output)=lib::SD_Protocols::postDemo_Revolt($Protocols,$target,@bits);
	is($rcode,0,'check returncode for postDemo_Revolt, CRC ERROR');
	is($output,undef,'check result postDemo_Revolt, CRC ERROR');
};
