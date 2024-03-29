#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is};

our %defs;

InternalTimer(time()+1, sub {
	plan(3);
    my $targetHash = $defs{dummyDuino};

	subtest 'Test SIGNALduino_calcRSSI with fixed values' => sub {
		plan(3);

		my $rssiInput=0;
		subtest 'Test with fixed values '.$rssiInput => sub {
			plan(2);
			my ($rssi,$rssiStr)=SIGNALduino_calcRSSI($rssiInput);
			is($rssi,-74,'check return value for input '.$rssiInput);
			is($rssiStr,'RSSI = -74','check return string for input '.$rssiInput);
		};

		$rssiInput=83;
		subtest 'Test with fixed values '.$rssiInput => sub {
			plan(2);
			my ($rssi,$rssiStr)=SIGNALduino_calcRSSI($rssiInput);
			is($rssi,-32.5,'check return value for input '.$rssiInput);
			is($rssiStr,'RSSI = -32.5','check return string for input '.$rssiInput);
		};

		$rssiInput=228;
		subtest 'Test with fixed values '.$rssiInput => sub {
			plan(2);
			my ($rssi,$rssiStr)=SIGNALduino_calcRSSI($rssiInput);
			is($rssi,-88,'check return value for input '.$rssiInput);
			is($rssiStr,'RSSI = -88','check return string for input '.$rssiInput);
		};
	};

	subtest 'Test SIGNALduino_calcRSSI with values from sub SIGNALduino_Split_Message' => sub {
		my $rmsg='MS;P2=463;P3=-1957;P5=-3906;P6=-9157;D=26232523252525232323232323252323232323232325252523252325252323252325232525;CP=2;SP=6;R=75;';
		note($rmsg);
		my %signal_parts=SIGNALduino_Split_Message($rmsg,$targetHash->{NAME});
		my $rssi=$signal_parts{rssi};
		my $rssiStr;
		plan(2);

		($rssi,$rssiStr)=SIGNALduino_calcRSSI($rssi);
		is($rssi,-36.5,'check return value -36.5 for input '.$signal_parts{rssi});
		is($rssiStr,'RSSI = -36.5','check return string RSSI = -36.5 for input '.$signal_parts{rssi});
	};


	subtest 'Test SIGNALduino_calcRSSI with undef' => sub {
		plan(2);

		my ($rssi,$rssiStr)=SIGNALduino_calcRSSI(undef);
		is($rssi,undef,'check if return is undef');
		is($rssiStr,undef,'check if return is undef');
	};

	exit(0);

}, 0);

1;