#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{ is array bag };
use Test2::Todo;

our %defs;

InternalTimer(time(), sub {
  my $target = shift;
  my $targetHash = $defs{$target};
  $targetHash->{cc1101_available} = 1;

    subtest 'setPatable' => sub {
        plan(3);
        my @paval;
        CommandAttr(undef,qq[$target cc1101_frequency 433]);
        subtest '-30dbm 433 Mhz' => sub {
            plan(2);

            my @paval;
            $paval[1] = '-30_dBm';
            is(cc1101::SetPatable($targetHash,@paval),U(),q[verify return]);
            is($targetHash->{QUEUE},array {
                item 'x12';
                etc();
            } ,q[Verify expected queue element entrys]);
            @{$targetHash->{QUEUE}}=();
        };


        subtest '-36dbm 433 Mhz' => sub {
            plan(2);

            my $todo = Test2::Todo->new(reason => 'Fix needed, this shoud fail in some way');
            $paval[1] = '-36_dBm';
            is(cc1101::SetPatable($targetHash,@paval),D(),q[verify return]);
            is($targetHash->{QUEUE},array {
                end();
            } ,q[Verify expected queue element entrys]);
            $todo->end;
            @{$targetHash->{QUEUE}}=();
        };

        CommandAttr(undef,qq[$target cc1101_frequency 868]);
        subtest '-35dbm 868 Mhz' => sub {
            plan(2);

            $paval[1] = '-30_dBm';
            is(cc1101::SetPatable($targetHash,@paval),U(),q[verify return]);
            is($targetHash->{QUEUE},array {
                item 'x03';
                etc();
            } ,q[Verify expected queue element entrys]);
            @{$targetHash->{QUEUE}}=();
        };
    };


    subtest 'SetRegisters' => sub {
      # sub input:  HASH(0x1b29c88), 0815 04D3 0591
      # -> transfer to sub SIGNALduino_AddSendQueue:  W06D3
      # -> transfer to sub SIGNALduino_AddSendQueue:  W0791
      # -> transfer to sub SIGNALduino_WriteInit:     HASH(0x1b29c88)
      # sub output: return
      plan(2);
      is(cc1101::SetRegisters($targetHash,qw(0815 04D3 0591)),U(),q[verify return]);
      is($targetHash->{QUEUE},array {
        item 'W06D3';
        item 'W0791';
        etc();
      } ,q[Verify expected queue element entrys]);
      @{$targetHash->{QUEUE}}=();

    };

    subtest 'SetRegistersUser' => sub {
      # sub input:  HASH(0x1b29c88)
      # -> check cc1101_reg_user (value: 04D3,0591)
      # -> transfer to sub SetRegisters: HASH(0x1b29c88),(04D3,0591)
      # sub output: return

      plan(2);
      CommandAttr(undef,qq[$target cc1101_reg_user 04D3,0591]);
      is(cc1101::SetRegistersUser($targetHash),U(),q[verify return]);
      is($targetHash->{QUEUE},array {
        item 'W06D3';
        item 'W0791';
        etc();
      } ,q[Verify expected queue element entrys]);
      @{$targetHash->{QUEUE}}=();
    };

    subtest 'SetDataRate' => sub {
      ## first call
      # sub input:  HASH(0x1b29c88), cc1101_dataRate 3.75
      # sub output: return

      ## second call
      # sub input:  input HASH(0x1b29c88), C10 = 67
      # -> transfer to sub SIGNALduino_AddSendQueue:  HASH(0x1b29c88), W1267
      # -> transfer to sub SIGNALduino_AddSendQueue:  HASH(0x1b29c88), W132e
      # -> transfer to sub SIGNALduino_WriteInit:     HASH(0x1b29c88)
      # sub output: "Setting MDMCFG4..MDMCFG3 to 67 2e = 3.75 kHz", undef
      plan(4);
      is(cc1101::SetDataRate($targetHash,(undef,q[3.75])),U(),q[verify return]);

      is($targetHash->{ucCmd},hash {
        field 'cmd' => 'set_dataRate';
        field 'arg' => '3.75';
        etc();
      } ,q[Verify expected ucCMD element entrys]);
      @{$targetHash->{QUEUE}}=();

      is(cc1101::SetDataRate($targetHash,q[C10 = 67]),U(),q[verify return]);
      is($targetHash->{QUEUE},array {
        item 'W1267';
        item 'W132e';
        etc();
      } ,q[Verify expected queue element entrys]);
      @{$targetHash->{QUEUE}}=();
    };

    subtest 'CalcDataRate' => sub {
      # sub input:  57, 150
      # sub output: 5c, 7a
      plan(1);
      my @ret = cc1101::CalcDataRate($targetHash,qw(57 150));
      is([$ret[0], $ret[1]], array {
        item '5c';
        item '7a';
        etc();
      }, q[verify return values], @ret);
    };

    subtest 'SetDeviatn' => sub {
      # sub input:  HASH(0x1b29c88) , cc1101_deviatn 150
      # sub output: return

      plan(1);
      my @SetDeviatn = ('cc1101_deviatn','150');
      is(cc1101::SetDeviatn($targetHash,@SetDeviatn),U(),q[verify return]);
      @{$targetHash->{QUEUE}}=();
    };

    subtest 'SetFreq' => sub {
      # sub input:                                    HASH(0x1b29c88), cc1101_freq 444.685
      # -> transfer to sub SIGNALduino_AddSendQueue:  HASH(0x1b29c88), W0F11
      # -> transfer to sub SIGNALduino_AddSendQueue:  HASH(0x1b29c88), W101a
      # -> transfer to sub SIGNALduino_AddSendQueue:  HASH(0x1b29c88), W116f
      # sub output:                                   return

      plan(2);
      my @SetFreq = ('cc1101_freq','444.685');
      is(cc1101::SetFreq($targetHash,@SetFreq),U(),q[verify return]);
      is($targetHash->{QUEUE},array {
        item 'W0F11';
        item 'W101a';
        item 'W116f';
        etc();
      } ,"Verify expected queue element entrys");
      @{$targetHash->{QUEUE}}=();
    };

    subtest 'setrAmpl' => sub {
      # sub input:                                    HASH(0x1b29c88), cc1101_rAmpl 40
      # -> transfer to sub SIGNALduino_AddSendQueue:  HASH(0x1b29c88), W1D06
      # -> transfer to sub SIGNALduino_WriteInit:     HASH(0x1b29c88)
      # sub output:                                   return

      plan(2);
      my @setrAmpl = ('cc1101_rAmpl','40');
      is(cc1101::setrAmpl($targetHash,@setrAmpl),U(),q[verify return]);
      is($targetHash->{QUEUE},array {
        item 'W1D06';
        etc();
      } ,"Verify expected queue element entrys");
      @{$targetHash->{QUEUE}}=();
    };

    subtest 'GetRegister' => sub {
      # sub input:                                    HASH(0x1b29c88) 10
      # -> transfer to sub SIGNALduino_AddSendQueue:  C10
      # sub output:                                   return

      plan(2);
      my @GetRegister = ('10');
      is(cc1101::GetRegister($targetHash,@GetRegister),U(),q[verify return]);
      is($targetHash->{QUEUE},array {
        item 'C10';
        end();
      } ,"Verify expected queue element entrys");
      @{$targetHash->{QUEUE}}=();
    };

    subtest 'CalcbWidthReg' => sub {
      # sub input:  HASH(0x1b29c88), 0B, 270
      # sub output: 6B,270
      plan(1);
      my @ret = cc1101::CalcbWidthReg($targetHash,qw(0B 270));
      is([$ret[0],$ret[1]],array {
          item '6b'; 
          item '270'; 
          end();
        }, q[verify return values], @ret);
    };

    subtest 'SetSens' => sub {
      # sub input:                                    HASH(0x1b29c88), cc1101_sens 12
      # -> transfer to sub SIGNALduino_AddSendQueue:  HASH(0x1b29c88), W1F92
      # -> transfer to sub SIGNALduino_WriteInit:     HASH(0x1b29c88)
      # sub output:                                   return

      plan(2);
      my @SetSens = ('cc1101_sens','12');
      is(cc1101::SetSens($targetHash,@SetSens),U(),q[verify return]);
      is($targetHash->{QUEUE},array {
        item 'W1F92';
        etc();
      } ,"Verify expected queue element entrys");
      @{$targetHash->{QUEUE}}=();
    };

    plan(11);
    exit(0);
},'cc1101dummyDuino');

1;