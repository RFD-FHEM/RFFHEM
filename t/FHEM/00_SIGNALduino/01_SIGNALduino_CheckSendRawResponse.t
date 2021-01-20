#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is field U D match hash bag };
use Mock::Sub;
use Test2::Todo;


my $mock;
my $InternalTimer;

BEGIN {
  $mock = Mock::Sub->new;
};

InternalTimer(time()+1, sub() {
  my $targetHash = $defs{dummyDuino};
  my @respMsgs = (
    'SR;',
    'SC;',
    'SM;',
    'SN;',
  );
  $InternalTimer = $mock->mock('InternalTimer');

  for my $respMsg (@respMsgs) {
    $targetHash->{ucCmd} = "something";
    $InternalTimer->reset;

    subtest qq[verify accept "$respMsg"] => sub {

      subtest qq[sendworking=0, QUEUE = 0] => sub {
        plan (2);
          @{$targetHash->{QUEUE}} = ();
        $targetHash->{sendworking} = 0;
        SIGNALduino_CheckSendRawResponse($targetHash,$respMsg);

        is($targetHash->{ucCmd},U,'Verify ucCmd deleted');
        is($InternalTimer->called,0,'Verify internalTimer called');
      };

      subtest qq[sendworking=0, QUEUE = 1] => sub {
        plan (2);
        @{$targetHash->{QUEUE}} = ('somepart');
        SIGNALduino_CheckSendRawResponse($targetHash,$respMsg);

        is($targetHash->{ucCmd},U,'Verify ucCmd deleted');
        is($InternalTimer->called,1,'Verify internalTimer called');
      };

      subtest qq[sendworking=1, QUEUE = 1] => sub {
        plan (2);
        $targetHash->{sendworking} = 1;
        SIGNALduino_CheckSendRawResponse($targetHash,$respMsg);

        is($targetHash->{ucCmd},U,'Verify ucCmd deleted');
        is($InternalTimer->called,1,'Verify internalTimer is not called once more');
      };
    };

  };
    
  $InternalTimer->unmock;
  done_testing();
  exit(0);

}, 0);

1;