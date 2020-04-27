#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Class;
use lib::SD_Protocols qw(:ALL);

plan(2);
ok( !$@, 'use (import :ALL) succeeded' );
my $className='lib::SD_Protocols';
my $Protocols = new $className();

isa_ok($Protocols,[$className],'check for correct class');  