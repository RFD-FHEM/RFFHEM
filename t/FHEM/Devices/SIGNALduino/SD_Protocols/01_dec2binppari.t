#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use FHEM::Devices::SIGNALduino::SD_Protocols;
use Test2::Tools::Compare qw{is};


my $obj = new FHEM::Devices::SIGNALduino::SD_Protocols();

plan(2);

subtest 'called as function' => sub {
	plan(2);
	my $input=32;
	my $result=FHEM::Devices::SIGNALduino::SD_Protocols::dec2binppari($input);
	is($result,'001000001',"check result input $input ");
	
	$input=204;
	$result=FHEM::Devices::SIGNALduino::SD_Protocols::dec2binppari($input);
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

