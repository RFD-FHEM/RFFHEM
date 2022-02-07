#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is field U D match hash bag };
use Test2::Todo;
use FHEM::Core::Timer::Helper;
our %defs;


InternalTimer(time()+1, sub() {
  my $targetHash = $defs{dummyDuino};
  my @respMsgs = (
    'SR;',
    'SC;',
    'SM;',
    'SN;',
  );
  
  my $mock = Test2::Mock->new(
    track => 1,
    class => 'main'
  );	 
  my $timer_mock = Test2::Mock->new(
    track => 1,
    class => 'FHEM::Core::Timer::Helper'
  );	 

  #$mock->override( 'InternalTimer' => sub {  } ) ;
  # $mock->override('RemoveInternalTimer' => sub {  } ) ;
  $timer_mock->override('addTimer' => sub {  } ) ;
  $timer_mock->override('removeTimer' => sub {  } ) ;
  $mock->override('SIGNALduino_HandleWriteQueue' => sub {  } ) ;

  my $tracking = $mock->sub_tracking();
  my $timer_tracking = $timer_mock->sub_tracking();

  for my $respMsg (@respMsgs) {
    $timer_mock->clear_sub_tracking();

    $targetHash->{ucCmd} = "something";
    subtest qq[verify accept "$respMsg"] => sub {
    
      subtest qq[sendworking=0, QUEUE = 0] => sub {
        plan (2);
        @{$targetHash->{QUEUE}} = ();
        $targetHash->{sendworking} = 0;
        SIGNALduino_CheckSendRawResponse($targetHash,$respMsg);

        is($targetHash->{ucCmd},U,'Verify ucCmd deleted');
        is(scalar @{$timer_tracking ->{addTimer}},0,'Verify addTimer is not called');
      };

      subtest qq[sendworking=0, QUEUE = 1] => sub {
        plan (2);
        @{$targetHash->{QUEUE}} = ('somepart');
        SIGNALduino_CheckSendRawResponse($targetHash,$respMsg);

        is($targetHash->{ucCmd},U,'Verify ucCmd deleted');
        is(scalar @{$timer_tracking ->{addTimer}},1,'Verify addTimer is called');
      };

      subtest qq[sendworking=1, QUEUE = 1] => sub {
        plan (2);
        $targetHash->{sendworking} = 1;
        SIGNALduino_CheckSendRawResponse($targetHash,$respMsg);

        is($targetHash->{ucCmd},U,'Verify ucCmd deleted');
        is(scalar @{$timer_tracking->{addTimer}},1,'Verify addTimer is not called');

      };
    };

  };

  for my $respMsg (qw /SR;D=AD0; /) {

    subtest qq[verify accept "$respMsg" sendworking=0, QUEUE = 0] => sub {
      $timer_mock->clear_sub_tracking();
      plan (4);


      @{$targetHash->{QUEUE}} = ();
      $targetHash->{sendworking} = 0;
      SIGNALduino_CheckSendRawResponse($targetHash,'SR;D=AD0;');

      is($targetHash->{ucCmd},U,'Verify ucCmd deleted'); 
      is(scalar @{$timer_tracking->{removeTimer}},1,'Verify RemoveInternalTimer called');
      is(scalar @{$tracking->{SIGNALduino_HandleWriteQueue}},1,'Verify SIGNALduino_HandleWriteQueue called');
      is(scalar @{$timer_tracking->{aDDTimer}},0,'Verify InternalTimer is not called');

      $timer_mock->restore('removeTimer');
      $mock->restore('SIGNALduino_HandleWriteQueue');
      $timer_mock->restore('addTimer');
    };  }

  $mock->reset_all;
  done_testing();
  exit(0);

}, 0);

1;