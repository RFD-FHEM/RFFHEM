#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is item U D match hash array bag};
use Test2::Todo;

plan(2);
my $todo = Test2::Todo->new(reason => 'added to TEST 03_ProtocolData.t');
if (defined($todo)) {
  ok(1, "needs extension - all id´s with modulation, check register entry available");
  ok(1, "needs extension - all id´s with modulation, check register value");
  $todo->end;
}

done_testing();
exit(0);
