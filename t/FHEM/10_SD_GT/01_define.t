#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is};

our %defs;

InternalTimer(time()+1, sub {
  my $ioName = shift; 
  my $ioHash = $defs{$ioName};


  subtest 'SD_GT - define SD_GT_Test_D SD_GT C07E2_D' => sub {
    plan(1);

        my $device=q[SD_GT_Test_D];
        my $def=q[C07E2_D];
        CommandDefine(undef,qq[$device SD_GT $def]); 
        is(IsDevice($device), 1, "check device created with define");
  };

  subtest 'SD_GT - delete device' => sub {
    plan(1);

        my $device=q[SD_GT_Test_D];
        CommandDelete(undef,qq[$device]); 
        is(IsDevice($device), 0, "check device deleted");
  };

  done_testing();
  exit(0);

}, 'dummyDuino');

1;