#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{ is like };
our %defs;

InternalTimer(time()+1, sub {
    my $target		= shift;
    my $targetHash 	= $defs{$target};
	plan(6);

	subtest 'Test SIGNALduino_CheckVersionResp ' => sub {
		plan(1);
		$targetHash->{ucCmd}->{cmd} = "version";
		my ($ret,undef)=SIGNALduino_CheckVersionResp($targetHash,"V 3.4.0-dev SIGNALESP cc1101 (chip CC1101) - compiled at Dec  4 2019 22:01:01");
		is($ret,"V 3.4.0-dev SIGNALESP cc1101 (chip CC1101) - compiled at Dec  4 2019 22:01:01","check return message");
	};
	
	subtest 'Test SIGNALduino_CheckVersionResp with incomplete MU before' => sub {
		plan(1);
		$targetHash->{ucCmd}->{cmd} = "version";
		my ($ret,undef)=SIGNALduino_CheckVersionResp($targetHash,"MU;P0-100;V 3.4.0-dev SIGNALESP cc1101 (chip CC1101) - compiled at Dec  4 2019 22:01:01");
		is($ret,"V 3.4.0-dev SIGNALESP cc1101 (chip CC1101) - compiled at Dec  4 2019 22:01:01","check return message");
	}; 

	subtest 'Test SIGNALduino_CheckVersionResp with stuff after' => sub {
		plan(1);
		$targetHash->{ucCmd}->{cmd} = "version";
		my ($ret,undef)=SIGNALduino_CheckVersionResp($targetHash,"V 3.4.0-dev SIGNALESP cc1101 (chip CC1101) - compiled at Dec  4 2019 22:01:01 STUFF HERE");
		is($ret,"V 3.4.0-dev SIGNALESP cc1101 (chip CC1101) - compiled at Dec  4 2019 22:01:01","check return message");
	}; 

	subtest 'Test SIGNALduino_CheckVersionResp with to old version' => sub {
		plan(1);
		$targetHash->{ucCmd}->{cmd} = "version";
		my ($ret,undef)=SIGNALduino_CheckVersionResp($targetHash,"V 3.1.0 SIGNALduino - compiled at Dec  4 2019 22:01:01");
		like($ret,qr/^$target: CheckVersionResp, Version of your arduino is not compatible, please flash new firmware. \(device closed\) Got for V: V 3\.1\.0.*/,"check return message");
	}; 

	subtest 'Test SIGNALduino_CheckVersionResp with no version' => sub {
		plan(1);
		$targetHash->{ucCmd}->{cmd} = "version";
		my ($ret,undef)=SIGNALduino_CheckVersionResp($targetHash,"no version from device");
		like($ret,qr/^$target: CheckVersionResp, Not an SIGNALduino device, got for V: no version from device/,"check return message");
	}; 

	subtest 'Test SIGNALduino_CheckVersionResp timeout' => sub {
		plan(1);
		# mock like SIGNALduino_StartInit
		$targetHash->{DevState} = 'waitInit';
		$targetHash->{ucCmd}->{responseSub} = \&SIGNALduino_CheckVersionResp;
		$targetHash->{ucCmd}->{cmd} = "version";
		# Simulate timeout behaviour
		my ($ret,undef)=SIGNALduino_CheckVersionResp($targetHash);
		like($ret,qr/^$target: CheckVersionResp, Not an SIGNALduino device, got for V: undef$/,"check return message");
	}; 

	exit(0);
},'dummyDuino');

1;
