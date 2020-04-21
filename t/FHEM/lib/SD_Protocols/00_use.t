#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols qw(:ALL);


plan(1);
ok( !$@, 'use (import :ALL) succeeded' );