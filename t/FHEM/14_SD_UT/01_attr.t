#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is};

our %defs;
our %attr;

InternalTimer(time()+0.4, sub {
    my $sensorname=shift;

    my $attr = q[repeats];
    subtest qq[set $sensorname $attr 1..99] => sub {
        plan(99);
        for my $v (1..99) {
            CommandAttr(undef,qq[$sensorname $attr $v]); 
            is($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is $v]);
        }
     };

    $attr = q[repeats];
    subtest qq[set $sensorname $attr 0,100,n] => sub {
        plan(3);
       for my $v (qw(0 100 n)) {
            CommandAttr(undef,qq[$sensorname $attr $v]); 
            isnt($attr{$sensorname}{repetition}, $v, qq[check attribute repetition is not $v]);
       }
    };

    $attr = q[UTfrequency];
    subtest qq[set $sensorname $attr 0.00] => sub {
        plan(4);
        for my $v (qw(300.00 433.92 933 999.99)) {
            CommandAttr(undef,qq[$sensorname $attr $v]); 
            is($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is $v]);
        }
     };

    $attr = q[UTfrequency];
    subtest qq[set $sensorname $attr 0.00] => sub {
        plan(5);
        for my $v (qw(0 0.00 1000 1000.00 14333.01)) {
            CommandAttr(undef,qq[$sensorname $attr $v]); 
            isnt($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is not $v]);
        }
     };

    $attr = q[model];
    $defs{$sensorname}{lastMSG} = q[010];

    subtest qq[Change module with hexlength 3 with attribute] => sub {
      plan(18);
      for my $v (qw(Buttons_five Buttons_six RH787T SA_434_1_mini Unitec_47031 CAME_TOP_432EV TR401 Novy_840029 Novy_840039)) {
        $defs{$sensorname}{bitMSG} = undef;
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        isnt($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is not $v]);

        $defs{$sensorname}{bitMSG} = q[111110111110];
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        is($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is $v]);
      }
    };

}, 'SD_UT_Test_Buttons_six');

InternalTimer(time()+0.41, sub {
    my $sensorname=shift;

    my $attr = q[model];
    $defs{$sensorname}{lastMSG} = q[1846A865];

    subtest qq[Change module with hexlength 8 with attribute] => sub {
      plan(8);
      for my $v (qw(DC_1961_TG Krinner_LUMIX RCnoName127 RCnoName20)) {
        $defs{$sensorname}{bitMSG} = undef;
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        isnt($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is not $v]);

        $defs{$sensorname}{bitMSG} = q[00011000010001101010100001100101];
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        is($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is $v]);
      }
    };

}, 'SD_UT_Test_hlen8');

InternalTimer(time()+0.42, sub {
    my $sensorname=shift;

    my $attr = q[model];
    $defs{$sensorname}{lastMSG} = q[1846];

    subtest qq[Change module with hexlength 4 with attribute] => sub {
      plan(2);
      for my $v (qw(TR60C1)) {
        $defs{$sensorname}{bitMSG} = undef;
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        isnt($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is not $v]);

        $defs{$sensorname}{bitMSG} = q[0000111110000000];
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        is($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is $v]);
      }
    };

}, 'SD_UT_Test_hlen4');

InternalTimer(time()+0.43, sub {
    my $sensorname=shift;

    my $attr = q[model];
    $defs{$sensorname}{lastMSG} = q[18469];

    subtest qq[Change module with hexlength 5 with attribute] => sub {
      plan(22);
      for my $v (qw(Chilitec_22640 OR28V QUIGG_DMV SF01_01319004 SF01_01319004_Typ2 Tedsen_SKX1xx Tedsen_SKX2xx Tedsen_SKX4xx Tedsen_SKX6xx TR_502MSV BeSmart_S4)) {
        $defs{$sensorname}{bitMSG} = undef;
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        isnt($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is not $v]);

        $defs{$sensorname}{bitMSG} = q[10101010100000001000];
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        is($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is $v]);
      }
    };

}, 'SD_UT_Test_hlen5');

InternalTimer(time()+0.44, sub {
    my $sensorname=shift;

    my $attr = q[model];
    $defs{$sensorname}{lastMSG} = q[16F610];

    subtest qq[Change module with hexlength 6 with attribute] => sub {
      plan(10);
      for my $v (qw(CREATE_6601TL HA_HX2 Navaris RCnoName128 TC6861)) {
        $defs{$sensorname}{bitMSG} = undef;
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        isnt($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is not $v]);

        $defs{$sensorname}{bitMSG} = q[100001011110111110101010];
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        is($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is $v]);
      }
    };

}, 'SD_UT_Test_hlen6');

InternalTimer(time()+0.44, sub {
    my $sensorname=shift;

    my $attr = q[model];
    $defs{$sensorname}{lastMSG} = q[16F610EF0];

    subtest qq[Change module with hexlength 9 with attribute] => sub {
      plan(10);
      for my $v (qw(KL_RF01 MD_2003R MD_210R MD_2018R RC_10)) {
        $defs{$sensorname}{bitMSG} = undef;
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        isnt($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is not $v]);

        $defs{$sensorname}{bitMSG} = q[000101101111011000010000111011110000];
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        is($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is $v]);
      }
    };

}, 'SD_UT_Test_hlen9');

InternalTimer(time()+0.45, sub {
    my $sensorname=shift;

    my $attr = q[model];
    $defs{$sensorname}{lastMSG} = q[DAAB255487];

    subtest qq[Change module with hexlength 10 with attribute] => sub {
      plan(4);
      for my $v (qw(BF_301 xavax)) {
        $defs{$sensorname}{bitMSG} = undef;
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        isnt($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is not $v]);

        $defs{$sensorname}{bitMSG} = q[1111101011010000100010001000001110100011];
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        is($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is $v]);
      }
    };

}, 'SD_UT_Test_hlen10');

InternalTimer(time()+0.46, sub {
    my $sensorname=shift;

    my $attr = q[model];
    $defs{$sensorname}{lastMSG} = q[1846ABCDEF0];

    subtest qq[Change module with hexlength 11 with attribute] => sub {
      plan(4);
      for my $v (qw(HSM4 HS1_868_BS)) {
        $defs{$sensorname}{bitMSG} = undef;
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        isnt($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is not $v]);

        $defs{$sensorname}{bitMSG} = q[00000000111001101011111010010001000001111100];
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        is($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is $v]);
      }
    };

}, 'SD_UT_Test_hlen11');

InternalTimer(time()+0.47, sub {
    my $sensorname=shift;

    my $attr = q[model];
    $defs{$sensorname}{lastMSG} = q[1846ABCDEF0AD];

    subtest qq[Change module with hexlength 13 with attribute] => sub {
      plan(2);
      for my $v (qw(Techmar)) {
        $defs{$sensorname}{bitMSG} = undef;
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        isnt($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is not $v]);

        $defs{$sensorname}{bitMSG} = q[0111011100001001111101011101111000001001111101100000];
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        is($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is $v]);
      }
    };

}, 'SD_UT_Test_hlen13');

InternalTimer(time()+0.48, sub {
    my $sensorname=shift;

    my $attr = q[model];
    $defs{$sensorname}{lastMSG} = q[1846ABCDEF0AD0];

    subtest qq[Change module with hexlength 14 with attribute] => sub {
      plan(2);
      for my $v (qw(Visivo)) {
        $defs{$sensorname}{bitMSG} = undef;
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        isnt($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is not $v]);

        $defs{$sensorname}{bitMSG} = q[10011111011111011111100000100101000000101001110000010000];
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        is($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is $v]);
      }
    };

}, 'SD_UT_Test_hlen14');

InternalTimer(time()+0.49, sub {
    my $sensorname=shift;

    my $attr = q[model];
    $defs{$sensorname}{lastMSG} = q[FFFFFFFFFFFFFFFF];

    subtest qq[Change module with hexlength 15 with attribute] => sub {
      plan(2);
      for my $v (qw(LED_XM21_0)) {
        $defs{$sensorname}{bitMSG} = undef;
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        isnt($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is not $v]);

        $defs{$sensorname}{bitMSG} = q[1111111111111111111111111111111111111111111111111111111111111111];
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        is($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is $v]);
      }
    };

}, 'SD_UT_Test_hlen15');

InternalTimer(time()+0.50, sub {
    my $sensorname=shift;

    my $attr = q[model];
    $defs{$sensorname}{lastMSG} = q[FFFFFFFFFFFFFFFFF];

    subtest qq[Change module with hexlength 17 with attribute] => sub {
      plan(2);
      for my $v (qw(AC114_01B)) {
        $defs{$sensorname}{bitMSG} = undef;
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        isnt($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is not $v]);

        $defs{$sensorname}{bitMSG} = q[10100011000000000101100001111011000000010000000001000011000101111000];
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        is($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is $v]);
      }
    };

 	done_testing();
	exit(0);

}, 'SD_UT_Test_hlen17');

1;