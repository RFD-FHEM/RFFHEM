#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{is};


my $obj = new lib::SD_Protocols();

plan(2);

subtest 'called as function' => sub {
	plan(2);
	my $input=32;
	my $result=lib::SD_Protocols::dec2binppari($input);
	is($result,'001000001',"check result input $input ");
	
	$input=204;
	$result=lib::SD_Protocols::dec2binppari($input);
	is($result,'110011000',"check result input $input ");
};

subtest 'called as method' => sub {
	plan(2);
	my $input=32;
	my $result=$obj->dec2binppari($input);
	is($result,'001000001',"check result input $input  ");
	
	$input=204;
	$result=$obj->dec2binppari($input);
	is($result,'110011000',"check result input $input ");
};

