#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is};

our %defs;

InternalTimer(time()+1, sub {
	my $ioName = shift; 
	my $ioHash = $defs{$ioName};

	subtest 'attrib autocreate is undef for right result' => sub {
		is(AttrVal("autocreate" ,"autocreateThreshold",undef),undef,"check autocreate undef");
	};

	subtest 'Protocol 44 - autocreate via RAWMSG' => sub {
		plan(2);
		my $rmsg="MU;P0=32001;P1=-1939;P2=1967;P3=3896;P4=-3895;D=01213424242124212121242121242121212124212424212121212121242421212421242121242124242421242421242424242124212124242424242421212424212424212121242121212;CP=2;R=39;";
		my $sensorname="BresserTemeo_1";
		
		SIGNALduino_Parse_MU($ioHash, $rmsg);
		$ioHash->{TIME} -=3;
		is(!IsDevice($sensorname), 1, "Sensor not created with single dispatch");
		SIGNALduino_Parse_MU($ioHash, $rmsg);
		is(IsDevice($sensorname), 1,"check Sensor created with second dispatch",q[Devices (TYPE=SD_WS):]. join q{},devspec2array('TYPE=SD_WS') );
	};
	

	
	done_testing();
	exit(0);

}, 'dummyDuino');

1;