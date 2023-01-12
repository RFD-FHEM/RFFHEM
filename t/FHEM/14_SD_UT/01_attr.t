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
    my $v = q[Buttons_five];
    subtest qq[Change module attribute to buttons_five] => sub { 
        plan(2);
        $defs{$sensorname}{lastMSG} = q[010];
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        isnt($attr{$sensorname}{$attr}, $v, qq[check attribute $attr isnt $v]);
        
        $defs{$sensorname}{bitMSG} = q[010];
        CommandAttr(undef,qq[$sensorname $attr $v]);     
        is($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is $v]);
    };

    $attr = q[model];
    my $v = q[Buttons_six];
    subtest qq[Change module attribute to buttons_six] => sub { 
        plan(2);
        $defs{$sensorname}{bitMSG} = undef;
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        isnt($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is not $v]);
        
        $defs{$sensorname}{bitMSG} = q[010];
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        is($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is $v]);
    };



}, 'SD_UT_Test_Buttons_six');

InternalTimer(time()+0.41, sub {
    my $sensorname=shift;

    my $attr = q[model];
    my $v = q[DC_1961_TG];
    subtest qq[Change module attribute to DC_1961_TG] => sub { 
        plan(2);
        $defs{$sensorname}{lastMSG} = q[1846A865];
        CommandAttr(undef,qq[$sensorname $attr $v]); 
        isnt($attr{$sensorname}{$attr}, $v, qq[check attribute $attr isnt $v]);
        
        $defs{$sensorname}{bitMSG} = q[010];
        CommandAttr(undef,qq[$sensorname $attr $v]);     
        is($attr{$sensorname}{$attr}, $v, qq[check attribute $attr is $v]);
    };

 	done_testing();
	exit(0);

}, 'SD_UT_Test_TC6861_3DC_1');


1;