#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{ is };

our %defs;

InternalTimer(time()+1, sub {
    my $target		= shift;
    my $targetHash 	= $defs{$target};
	plan(6);


	subtest 'Test SIGNALduino_CheckCmdsResponse ' => sub {
		plan(1);
		my ($ret,undef)=SIGNALduino_CheckCmdsResponse($targetHash,"$target cmds => .*Use one of V R t X S P C r W s x e");
		is($ret," V R t X S P C r W s x e","check return value");
	}; 

	subtest 'Test with unset version' => sub {
		plan(2);

		my $mock = Test2::Mock->new(
			track => 1,
			class => 'main',
			override => [
				SIGNALduino_StartInit => sub { 0 },
			],
		);
		my $tracking = $mock->sub_tracking;
		delete($targetHash->{version});
		$targetHash->{ucCmd}->{cmd} = "version";

		my $ret=SIGNALduino_CheckCmdResp($targetHash);
		is(scalar @{$tracking->{SIGNALduino_StartInit}},1,"Version not found and SIGNALduino_StartInit called");
		is($targetHash->{ucCmd}->{cmd},undef,"ucCmd removed");

		$mock->restore('SIGNALduino_StartInit');
	}; 

	subtest 'Test with wrong version' => sub {
		plan(3);

		$targetHash->{version} = "SIGNALdummy";
		$targetHash->{ucCmd}->{cmd} = "version";

		my $ret=SIGNALduino_CheckCmdResp($targetHash);
		is(ReadingsVal($target,"state",undef),"closed","SIGNALDuino not found");
		is($targetHash->{ucCmd}->{cmd},"version","ucCmd not removed");
		is($targetHash->{DevState},"INACTIVE","check DevState");
	}; 

	subtest 'Test with old version' => sub {
		plan(3);

		$targetHash->{version} = "V 3.1.2 SIGNALduino cc1101 (chip CC1101) - compiled at Sep 22 2019 22:53:27";
		$targetHash->{ucCmd}->{cmd} = "version";

		my $ret=SIGNALduino_CheckCmdResp($targetHash);
		is(ReadingsVal($target,"state",undef),"closed","SIGNALDuino Firmware to old");
		is($targetHash->{ucCmd}->{cmd},"version","ucCmd not removed");
		is($targetHash->{DevState},"INACTIVE","check DevState");
	}; 
	
	subtest 'Test with good version without cc1101' => sub {
		plan(5);

		my $mock = Test2::Mock->new(
			track => 1,
			class => 'main',
			override => [
				SIGNALduino_SimpleWrite => sub { 0 },
			],
		);
		my $tracking = $mock->sub_tracking;

		$targetHash->{version} = "V 3.3.1 SIGNALduino - compiled at Sep 22 2019 22:53:27";
		$targetHash->{ucCmd}->{cmd} = "version";
		my $ret=SIGNALduino_CheckCmdResp($targetHash);
		is(ReadingsVal($target,"state",undef),"opened","SIGNALDuino firmware version ok");
		is(scalar @{$tracking->{SIGNALduino_SimpleWrite}},1,"SIGNALduino_SimpleWrite called");

		is($targetHash->{ucCmd}->{cmd},"version","ucCmd not removed");
		is($targetHash->{DevState},"initialized","check DevState");
		is($targetHash->{cc1101_available},undef,"check internal cc1101_available");
		$mock->restore('SIGNALduino_SimpleWrite');
	}; 

	subtest 'Test with good version' => sub {
		plan(5);

		my $mock = Test2::Mock->new(
			track => 1,
			class => 'main',
			override => [
				SIGNALduino_SimpleWrite => sub { 0 },
			],
		);
		my $tracking = $mock->sub_tracking;


		$targetHash->{version} = "V 3.3.1 SIGNALduino cc1101 (chip CC1101) - compiled at Sep 22 2019 22:53:27";
		$targetHash->{ucCmd}->{cmd} = "version";
		my $ret=SIGNALduino_CheckCmdResp($targetHash);
		is(ReadingsVal($target,"state",undef),"opened","SIGNALDuino firmware version ok");
		is(scalar @{$tracking->{SIGNALduino_SimpleWrite}},1,"SIGNALduino_SimpleWrite called");

		is($targetHash->{ucCmd}->{cmd},"version","ucCmd not removed");
		is($targetHash->{DevState},"initialized","check DevState");
		is($targetHash->{cc1101_available},1,"check internal cc1101_available");

		$mock->restore('SIGNALduino_SimpleWrite');
	}; 



	exit(0);
},'dummyDuino');

1;