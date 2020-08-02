#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is item U D match hash array bag};
use Mock::Sub;
use Test2::Todo;

use lib::SD_Protocols

InternalTimer(time()+1, sub() {
  my $todo = Test2::Todo->new(reason => 'added TEST for 03_ProtocolData.t');
  if (defined($todo)) {
    ok(1, "needs extension - all id´s with modulation, check register entry available");
    ok(1, "needs extension - all id´s with modulation, check register value");
    $todo->end;
  }

  done_testing();
  exit(0);

}, 0);

1;