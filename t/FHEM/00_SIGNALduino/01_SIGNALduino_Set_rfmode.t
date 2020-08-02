#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is item U D match hash array bag};
use Mock::Sub;
use Test2::Todo;

# Mock cc1101
$defs{cc1101dummyDuino}{cc1101_available} = 1;


InternalTimer(time()+1, sub() {
  is($defs{cc1101dummyDuino},hash {
        field cc1101_available => 1; 
        etc();
      },
    'check mocked cc1101dummyDuino hash');
  is($defs{dummyDuino},hash 	{
        field cc1101_available => U(); 
        etc();
      },
    'check mocked dummyDuino hash');

  my $todo = Test2::Todo->new(reason => 'added TEST for Set_rfmode');
  if (defined($todo)) {
    ok(1, "needs extension");
    $todo->end;
  }

  done_testing();
  exit(0);

}, 0);

1;