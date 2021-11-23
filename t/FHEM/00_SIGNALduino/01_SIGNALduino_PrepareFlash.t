#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is bag check array like unlike U};
use Test2::Mock;
use Test2::Todo;

our %defs;
our %attr;


InternalTimer(time()+1, sub {
	my $target = shift;
	my $targetHash = $defs{$target};
	my $mock = Test2::Mock->new(
		track => 1,
		class => 'main'
	);	 	

	my $tracking = $mock->sub_tracking;
	my $preparedavrdudecmd;
    my $opath = $ENV{'PATH'};

    plan(4);
    
    SKIP: {

        skip('sub SIGNALduino_PrepareFlash does not check parameters', 1);
        subtest 'check error returns' => sub {
            my @p=();
            plan(1);

            like(SIGNALduino_PrepareFlash(), qr/Error/, 'Verify error without argument');
        };
    };

    subtest 'without installed avrdude' => sub {
        plan(1);
        CommandAttr(undef,"$target hardware nano328");
        $ENV{'PATH'}= '';
		my $ret = SIGNALduino_PrepareFlash($targetHash,'some.hex');
		is($ret, 'avrdude is not installed. Please provide avrdude tool example: sudo apt-get install avrdude', 'check return value');		
        $ENV{'PATH'}= $opath;
	};

    subtest 'with installed avrdude (nano328)' => sub {
        plan(11);

        CommandAttr(undef,"$target hardware nano328");
        CommandAttr(undef,'global logdir /tmp/');
        my $filename = '/tmp/avrdude';
        open(my $FH, '>', $filename) or die $!;
        print $FH q[#!/bin/bash
                   # Return 0 when command exists without error
                   CMD="$*"
                   echo "${BASH_SOURCE[0]} $CMD"
                   exit 0];
        close ($FH);
        chmod 0755, $filename;
        $ENV{'PATH'}= '/tmp';

        $mock->override('InternalTimer' => sub { pass('InternalTimer called'); } );
        $mock->override('DevIo_CloseDev' => sub { pass('CloseDDevIo_CloseDevev called'); } );

		my $ret = SIGNALduino_PrepareFlash($targetHash,'some.hex');
 		is($ret,U(), 'check return value');		
        like($targetHash->{helper}{avrdudecmd},qr/^avrdude -c arduino/,'check avrdude -c arduino');
        like($targetHash->{helper}{avrdudecmd},qr/-b 115200/,'check 115200 baud');
        like($targetHash->{helper}{avrdudecmd},qr/-b 57600/,'check 57600 baud');
        like($targetHash->{helper}{avrdudecmd},qr/-p atmega328p/,'check -p atmega328p');
        like($targetHash->{helper}{avrdudecmd},qr/ || avrdude /,'check || avrdude append');
        like($targetHash->{helper}{avrdudecmd},qr/ flash:w:some.hex /,'check flash:w:some.hex');
        is($targetHash->{helper}{stty_output},U(),'check no stty_output saved in hash');
        is($targetHash->{helper}{stty_pid},U(),'check no stty pid saved in hash');
        $ENV{'PATH'}= $opath;

        $mock->restore('InternalTimer');
        $mock->restore('DevIo_CloseDev');
	};


 subtest 'with installed avrdude (radinocc1101)' => sub {
        plan(10);

        CommandAttr(undef,"$target hardware radinoCC1101");
        CommandAttr(undef,'global logdir /tmp/');
        my $filename = '/tmp/avrdude';
        open(my $FH, '>', $filename) or die $!;
        print $FH q[#!/bin/bash
                   # Return 0 when command exists without error
                   CMD="$*"
                   echo "${BASH_SOURCE[0]} $CMD"
                   exit 0];
        close ($FH);
        chmod 0755, $filename;
        $ENV{'PATH'}= '/tmp';

        $mock->override('InternalTimer'     => sub { pass('InternalTimer called'); } );
        $mock->override('DevIo_CloseDev'    => sub { pass('CloseDDevIo_CloseDevev called'); } );


		my $ret = SIGNALduino_PrepareFlash($targetHash,'some.hex');
 		is($ret,U(), 'check return value');		
        like($targetHash->{helper}{avrdudecmd},qr/^avrdude -c avr109 /,'check avrdude -c arduino');
        like($targetHash->{helper}{avrdudecmd},qr/-b 57600/,'check 57600 baud');
        like($targetHash->{helper}{avrdudecmd},qr/-p atmega32u4 /,'check -p atmega328p');
        like($targetHash->{helper}{avrdudecmd},qr/ || avrdude /,'check || avrdude append');
        like($targetHash->{helper}{avrdudecmd},qr/ flash:w:some.hex /,'check flash:w:some.hex');
        like($targetHash->{helper}{stty_output},qr/^open3: exec of stty -F /,'check stty_output saved in hash');
        is($targetHash->{helper}{stty_pid},U(),'check no stty pid saved in hash');
        $ENV{'PATH'}= $opath;

        $mock->restore('InternalTimer');
        $mock->restore('DevIo_CloseDev');
	};

	exit(0);
},'dummyDuino');

1;
