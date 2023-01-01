#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is};

our %defs;
our $init_done;

InternalTimer(time()+0.4, sub {

	my $ioName = shift;
	my $ioHash = $defs{$ioName};

	subtest 'attrib autocreate is undef for right result' => sub {
		is(AttrVal("autocreate" ,"autocreateThreshold",undef),undef,"check autocreate undef");
	};

	subtest 'Protocol 44 - autocreate via DMSG' => sub {
		plan(2);
		my $sensorname="BresserTemeo_1";
		CommandDelete(undef,$sensorname);
		Dispatch($ioHash,"W44#D12160652EDE9F9B10");
		is(IsDevice($sensorname), 0, "Sensor not created with single dispatch");
		$ioHash->{TIME} -=3;
	
		Dispatch($ioHash,"W44#D12160652EDE9F9B10");
		is(IsDevice($sensorname), 1, "check Sensor created with second dispatch");
		$ioHash->{TIME} -=3;

		CommandDelete(undef,$sensorname);
	};

	subtest 'Protocol 44 - autocreate via RAWMSG' => sub {
		plan(2);
		my $rmsg="MU;P0=32001;P1=-1939;P2=1967;P3=3896;P4=-3895;D=01213424242124212121242121242121212124212424212121212121242421212421242121242124242421242421242424242124212124242424242421212424212424212121242121212;CP=2;R=39;";
		my $sensorname="BresserTemeo_1";
		

		my $ret=SIGNALduino_Parse_MU($ioHash, $rmsg);
		is(IsDevice($sensorname), 0, "Sensor not created with single dispatch");
		$ioHash->{TIME} -=3;
		$ret=SIGNALduino_Parse_MU($ioHash, $rmsg);
		is(IsDevice($sensorname), 1,"check Sensor created with second dispatch",q[Devices (TYPE=BresserTemeo): ],$ret,  devspec2array('TYPE=BresserTemeo') );

		CommandDelete(undef,$sensorname);
	};

	done_testing();
	exit(0);

}, 'dummyDuino');

1;