#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{is};




plan(2);

my $input=32;
my $result=lib::SD_Protocols::_dec2binppari($input);
is($result,'001000001',"check result input $input");

$input=204;
$result=lib::SD_Protocols::_dec2binppari($input);
is($result,'110011000',"check result input $input");
