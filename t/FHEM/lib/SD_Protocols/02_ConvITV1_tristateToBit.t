#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{ is };

plan(2);
my $obj = new lib::SD_Protocols();

subtest 'called as function' => sub {
	plan(2);

	my $msg='F00F00FFFFF0';
	my $rcode;

	($rcode,$msg)=lib::SD_Protocols::ConvITV1_tristateToBit($msg);
	is($rcode,1,'check returncode for ITV1_tristateToBit');
	is($msg,'010000010000010101010100','check result ITV1_tristateToBit');
};

subtest 'called as mthod' => sub {
	plan(2);

	my $msg='F00F00FFFFF0';
	my $rcode;

	($rcode,$msg)=$obj->ConvITV1_tristateToBit($msg);
	is($rcode,1,'check returncode for ITV1_tristateToBit');
	is($msg,'010000010000010101010100','check result ITV1_tristateToBit');
};