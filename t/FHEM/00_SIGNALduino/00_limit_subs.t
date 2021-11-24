#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;

use Test2::V0;
use Test2::Tools::Compare qw{ is };

my $module = basename (dirname(__FILE__));

#is(CommandReload(undef,$module), undef, "$module loaded");

plan(2);
subtest 'limit_to_number tests' => sub {

    plan(5);

    is(_limit_to_number(1),1,'limit 1 ok');
    is(_limit_to_number(10000),10000, 'limit 1000 ok');
    is(_limit_to_number('774d'),U(),'limit 774d ok');
    is(_limit_to_number('d774'),U(),'limit d774 ok');
    is(_limit_to_number(qw/10 20/),'10','limit (10,20) ok');

};

subtest '_limit_to_hex tests' => sub {

    plan(7);

    is(_limit_to_hex('AF'),'AF','limit AF ok'); 
    is(_limit_to_hex('af'),'af','limit af ok');
    is(_limit_to_hex('DG'),U(),'limit DG ok');
    is(_limit_to_hex('0D'),'0D','limit 0D ok');
    is(_limit_to_hex('PA0'),U(),'limit PA0 ok');
    is(_limit_to_hex('0xA0'),U(),'limit 0xA0 ok');
    is(_limit_to_hex(qw/DF SP/),'DF','limit (SL,SP) ok');

};

exit(0);  # necessary

1;

