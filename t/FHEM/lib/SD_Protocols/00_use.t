#!/usr/bin/env perl
use Test2::Tools::Class;

use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols qw(:ALL);


plan(2);
ok( !$@, 'use (import :ALL) succeeded' );

my $Protocols=lib::SD_Protocols->new();
isa_ok($Protocols, 'lib::SD_Protocols', "check class");
