#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is field U D match hash bag };
use Test2::Todo;

our %defs;


InternalTimer(time()+1, sub() {
  my $targetHash = $defs{dummyDuino};
  my @respMsgs = (
    'SR;',
    'SC;',
    'SM;',
    'SN;',
  );
  my $mock;

  $mock = Test2::Mock->new(
    track => 1,
    class => 'main'
  );	 
  $mock->override( 'InternalTimer' => sub {  } ) ;
  $mock->override('RemoveInternalTimer' => sub {  } ) ;
  $mock->override('SIGNALduino_HandleWriteQueue' => sub {  } ) ;

  my $tracking = $mock->sub_tracking();
  
  for my $respMsg (@respMsgs) {
    $mock->clear_sub_tracking();

    $targetHash->{ucCmd} = "something";
    subtest qq[verify accept "$respMsg"] => sub {
    
      subtest qq[sendworking=0, QUEUE = 0] => sub {
        plan (2);
        @{$targetHash->{QUEUE}} = ();
        $targetHash->{sendworking} = 0;
        SIGNALduino_CheckSendRawResponse($targetHash,$respMsg);

        is($targetHash->{ucCmd},U,'Verify ucCmd deleted');
        is(scalar @{$tracking->{InternalTimer}},0,'Verify InternalTimer is not called');
      };

      subtest qq[sendworking=0, QUEUE = 1] => sub {
        plan (2);
        @{$targetHash->{QUEUE}} = ('somepart');
        SIGNALduino_CheckSendRawResponse($targetHash,$respMsg);

        is($targetHash->{ucCmd},U,'Verify ucCmd deleted');
        is(scalar @{$tracking->{InternalTimer}},1,'Verify InternalTimer is called');
      };

      subtest qq[sendworking=1, QUEUE = 1] => sub {
        plan (2);
        $targetHash->{sendworking} = 1;
        SIGNALduino_CheckSendRawResponse($targetHash,$respMsg);

        is($targetHash->{ucCmd},U,'Verify ucCmd deleted');
        is(scalar @{$tracking->{InternalTimer}},1,'Verify InternalTimer is not called');

      };
    };

  };

  for my $respMsg (qw /SR;D=AD0; /) {

    subtest qq[verify accept "$respMsg" sendworking=0, QUEUE = 0] => sub {
      $mock->clear_sub_tracking();
      plan (4);


      @{$targetHash->{QUEUE}} = ();
      $targetHash->{sendworking} = 0;
      SIGNALduino_CheckSendRawResponse($targetHash,'SR;D=AD0;');

      is($targetHash->{ucCmd},U,'Verify ucCmd deleted'); 
      is(scalar @{$tracking->{RemoveInternalTimer}},1,'Verify RemoveInternalTimer called');
      is(scalar @{$tracking->{SIGNALduino_HandleWriteQueue}},1,'Verify SIGNALduino_HandleWriteQueue called');
      is(scalar @{$tracking->{InternalTimer}},0,'Verify InternalTimer is not called');

      $mock->restore('RemoveInternalTimer');
      $mock->restore('SIGNALduino_HandleWriteQueue');
      $mock->restore('InternalTimer');
    };  }

  $mock->reset_all;
  done_testing();
  exit(0);

}, 0);

1;