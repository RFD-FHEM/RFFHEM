#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{ is array bag call hash item end etc U D };
use Test2::Mock qw(mock);
use Test2::Todo;

#use FHEM::Devices::SIGNALduino::SD_IO qw(:all);
use FHEM::Devices::SIGNALduino::SD_CC1101 qw(:all);

# Mock device hash and environment
my $target = 'cc1101dummyDuino';
our %defs = ($target => { 
    NAME => "$target", 
    cc1101_available => 1,
    logMethod => sub { my ($hash, $level, $msg) = @_; note "Log $level: $msg"; return }, # dummy logMethod
  }
);
our $targetHash = $defs{$target};

# --- Mocks for FHEM environment and dependencies ---
my $mock_main = Test2::Mock->new(
  track => 1,
  class => 'main',
  autoload => undef,
  add => [ 
    AttrVal => sub {
      my ($name, $attr, $default) = @_;
      if ($attr eq 'cc1101_frequency') {
        return $targetHash->{attr}{cc1101_frequency} || $default;
      } elsif ($attr eq 'cc1101_reg_user') {
        return $targetHash->{attr}{cc1101_reg_user} || $default;
      }
      return $default;
    },
  ]  
);

# --- Test execution ---

subtest 'setPatable' => sub {
    plan(3);
    my @paval;
    #CommandAttr(undef,qq[$target cc1101_frequency 433]);
    $targetHash->{attr}{cc1101_frequency} = "433";


    subtest '-30dbm 433 Mhz' => sub {
        plan(3);

        my @paval;
        $paval[1] = '-30_dBm';
        is(SetPatable($targetHash,@paval),U(),q[verify return]);
        
        my $tracking_add = $mock_main->sub_tracking()->{SIGNALduino_AddSendQueue};
        is($tracking_add->[0]->{args}, array { item D(); item 'x12'; }, 'Check if AddSendQueue called with correct argument');
        is(@{$mock_main->sub_tracking()->{SIGNALduino_WriteInit}},1,'check if WriteInit is called once');
        
        $mock_main->clear_sub_tracking();
    };

    subtest '-36dbm 433 Mhz' => sub {
        plan(3);

        $paval[1] = '-36_dBm';
        # This is expected to return an error string
        like(SetPatable($targetHash,@paval),qr/Frequency 433 MHz not supported/,q[verify return (error expected)]);
        # No calls expected for failed SetPatable
        #my $tracking_add = $mock_main->sub_tracking()->{SIGNALduino_AddSendQueue};
        is(@{$mock_main->sub_tracking()->{SIGNALduino_AddSendQueue}},0,'check if AddSendQueue is not called');
        is(@{$mock_main->sub_tracking()->{SIGNALduino_WriteInit}},0,'check if WriteInit is not called');
        $mock_main->clear_sub_tracking();
    };

    #CommandAttr(undef,qq[$target cc1101_frequency 868]);
    $targetHash->{attr}{cc1101_frequency} = 868;
    subtest '-35dbm 868 Mhz' => sub {
        plan(3);
           
        $paval[1] = '-30_dBm';
        is(SetPatable($targetHash,@paval),U(),q[verify return]);

        my $tracking_add = $mock_main->sub_tracking()->{SIGNALduino_AddSendQueue};
        is($tracking_add->[0]->{args}, array { item D(); item 'x03'; }, 'Check if AddSendQueue called with correct argument');
        is(@{$mock_main->sub_tracking()->{SIGNALduino_WriteInit}},1,'check if WriteInit is called once');
        $mock_main->clear_sub_tracking();

    };

};

subtest 'SetRegisters' => sub {
  plan(5);
  is(SetRegisters($targetHash,qw(0815 04D3 0591)),U(),q[verify return]);
  
  my $tracking_add = $mock_main->sub_tracking()->{SIGNALduino_AddSendQueue};

  is(scalar @{$tracking_add},2,'check if AddSendQueue called two times');
  is($tracking_add->[0]->{args}, array { item D(); item 'W06D3'; }, 'Check if AddSendQueue called with correct argument');
  is($tracking_add->[1]->{args}, array { item D(); item 'W0791'; }, 'Check if AddSendQueue called with correct argument');
  is(@{$mock_main->sub_tracking()->{SIGNALduino_WriteInit}},1,'check if WriteInit is called once');

  $mock_main->clear_sub_tracking();
};

subtest 'SetRegistersUser' => sub {
  plan(5);
  #CommandAttr(undef,qq[$target cc1101_reg_user 04D3,0591]);
  $targetHash->{attr}{cc1101_reg_user} = "04D3,0591";
  is(SetRegistersUser($targetHash),U(),q[verify return]);

  my $tracking_add = $mock_main->sub_tracking()->{SIGNALduino_AddSendQueue};

  is(scalar @{$tracking_add},2,'check if AddSendQueue called two times');
  is($tracking_add->[0]->{args}, array { item D(); item 'W06D3'; }, 'Check if AddSendQueue called with correct argument');
  is($tracking_add->[1]->{args}, array { item D(); item 'W0791'; }, 'Check if AddSendQueue called with correct argument');
  is(@{$mock_main->sub_tracking()->{SIGNALduino_WriteInit}},1,'check if WriteInit is called once');

  $mock_main->clear_sub_tracking();

};


subtest 'SetDataRate' => sub {
  plan(2);

  subtest 'First Call: GetRegister and setting ucCmd' => sub {
    plan(5);
    # Reset cc1101_frequency to default for CalcDataRate
    $targetHash->{attr}{cc1101_frequency} = 433;

    # First call (GetRegister and setting ucCmd)
    is(SetDataRate($targetHash,(undef,q[3.75])),U(),q[verify return]);
    my $tracking_add = $mock_main->sub_tracking()->{SIGNALduino_AddSendQueue};

    is(scalar @{$tracking_add},1,'check if AddSendQueue called two times');
    is($tracking_add->[0]->{args}, array { item D(); item 'C10'; }, 'Check if AddSendQueue called with correct argument (request register 10)');
    is($targetHash->{ucCmd}->{cmd},'set_dataRate','Check if ucCmd cmd is set correctly');
    is($targetHash->{ucCmd}->{arg},3.75,'Check if ucCmd arg is set correctly');

    $mock_main->clear_sub_tracking();
  };

  subtest 'Second Call: processing C10 response' => sub {
    plan(4);
    # Reset cc1101_frequency to default for CalcDataRate
    $targetHash->{attr}{cc1101_frequency} = 433;

    my $mock_cc1101 = Test2::Mock->new(
      class => 'FHEM::Devices::SIGNALduino::SD_CC1101',
      override => [ 
        'CalcDataRate' => sub {
          my ($hash, $args) = @_;
          return (q[67], q[2e]); # Mocked return values 3.75 kHz step from 3.74412536621094 to 3.75652313232422 kHz
        },
      ],
    );
    is(SetDataRate($targetHash,q[C10 = 67]),U(),q[verify return]); # C10 = 67 is the response for GetRegister

    my $tracking_add = $mock_main->sub_tracking()->{SIGNALduino_AddSendQueue};
    is($tracking_add->[0]->{args}, array { item D(); item 'W1267'; }, 'Check if AddSendQueue called with correct argument');
    is($tracking_add->[1]->{args}, array { item D(); item 'W132e'; }, 'Check if AddSendQueue called with correct argument');
    is(@{$mock_main->sub_tracking()->{SIGNALduino_WriteInit}},1,'check if WriteInit is called');

    $mock_main->clear_sub_tracking();
    $mock_cc1101->restore('CalcDataRate');
  };
};

subtest 'CalcDataRate' => sub {
  plan(1);
  my @ret = CalcDataRate($targetHash,qw(57 150));
  is([$ret[0], $ret[1]], array {
    item '5c';
    item '7a';
    end();
  }, q[verify return values], @ret);
};

subtest 'SetDeviatn' => sub {
  plan(3);
  my @SetDeviatn = ('cc1101_deviatn','150');
  is(SetDeviatn($targetHash,@SetDeviatn),U(),q[verify return]);

  my $tracking_add = $mock_main->sub_tracking()->{SIGNALduino_AddSendQueue};
  is($tracking_add->[0]->{args}, array { item D(); item 'W1764'; }, 'Check if AddSendQueue called with correct argument');
  is(@{$mock_main->sub_tracking()->{SIGNALduino_WriteInit}},1,'check if WriteInit is called');

  $mock_main->clear_sub_tracking();
};


subtest 'SetFreq' => sub {
  plan(5);
  my @SetFreq = ('cc1101_freq','444.685');
  is(SetFreq($targetHash,@SetFreq),U(),q[verify return]);

  my $tracking_add = $mock_main->sub_tracking()->{SIGNALduino_AddSendQueue};
  is($tracking_add->[0]->{args}, array { item D(); item 'W0F11'; }, 'Check if AddSendQueue called with correct argument');
  is($tracking_add->[1]->{args}, array { item D(); item 'W101a'; }, 'Check if AddSendQueue called with correct argument');
  is($tracking_add->[2]->{args}, array { item D(); item 'W116f'; }, 'Check if AddSendQueue called with correct argument');
  is(@{$mock_main->sub_tracking()->{SIGNALduino_WriteInit}},1,'check if WriteInit is called');

  $mock_main->clear_sub_tracking();

};

subtest 'setrAmpl' => sub {
  plan(3);
  my @setrAmpl = ('cc1101_rAmpl','40');
  is(setrAmpl($targetHash,@setrAmpl),U(),q[verify return]);
  
  my $tracking_add = $mock_main->sub_tracking()->{SIGNALduino_AddSendQueue};
  is($tracking_add->[0]->{args}, array { item D(); item 'W1D06'; }, 'Check if AddSendQueue called with correct argument');
  is(@{$mock_main->sub_tracking()->{SIGNALduino_WriteInit}},1,'check if WriteInit is called');
  
  $mock_main->clear_sub_tracking();
};



subtest 'GetRegister' => sub {
  plan(2);
  my @GetRegister = ('10');
  is(GetRegister($targetHash,@GetRegister),U(),q[verify return]);
  
  my $tracking_add = $mock_main->sub_tracking()->{SIGNALduino_AddSendQueue};
  is($tracking_add->[0]->{args}, array { item D(); item 'C10'; }, 'Check if AddSendQueue called with correct argument');
 
  $mock_main->clear_sub_tracking();
};


subtest 'CalcbWidthReg' => sub {

  # Mock FHEM::Core::Utils::Math::round for this test - ugly hack due to lack of better mocking options
  package FHEM::Core::Utils::Math;
  sub round
  {
    my $number = shift;
    my $decimalPoint 	= shift;
    return sprintf("%.${decimalPoint}f",$number);
  }
  package main;

  plan(1);
  my @ret = CalcbWidthReg($targetHash,qw(0B 270));
  is([$ret[0],$ret[1]], array {
      item '6b'; 
      item '270'; 
      end();
    }, q[verify return values], @ret);
};


subtest 'SetSens' => sub {
  plan(3);
  my @SetSens = ('cc1101_sens','12');
  is(SetSens($targetHash,@SetSens),U(),q[verify return]);

  my $tracking_add = $mock_main->sub_tracking()->{SIGNALduino_AddSendQueue};
  is($tracking_add->[0]->{args}, array { item D(); item 'W1F92'; }, 'Check if AddSendQueue called with correct argument');
  is(@{$mock_main->sub_tracking()->{SIGNALduino_WriteInit}},1,'check if WriteInit is called');
  
  $mock_main->clear_sub_tracking();
};


plan(11); # Main plan count, covering all 11 subtests

1;
