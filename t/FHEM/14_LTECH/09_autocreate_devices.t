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

	subtest 'Protocol 31 - autocreate via RAWMSG' => sub {
		plan(2);
		my $rmsg="MU;P0=310;P2=-574;P3=-281;P5=598;P6=1191;P7=-1217;D=030303030303030303030702025302020202020202530202025302025353530202530253535353535353530253535353535353020202020202020202020202020202025353535353535353530202020202020202020202025302020202020202020202530202025302530202025353025353536;CP=0;R=26;";
		my $sensorname="LTECH_04444EFF";
		
		SIGNALduino_Parse_MU($ioHash, $rmsg);
		$ioHash->{TIME} -=3;
		is(!IsDevice($sensorname), 1, "LED-Controller not created with single dispatch");
		SIGNALduino_Parse_MU($ioHash, $rmsg);
		is(IsDevice($sensorname), 1,"check LED-Controller created with second dispatch",q[Devices (TYPE=LTECH):]. join q{},devspec2array('TYPE=LTECH') );
	};
	

	
	done_testing();
	exit(0);

}, 'dummyDuino');

1;