#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is U};
use Test2::Tools::Ref;
use Test2::Mock;

our %defs;

InternalTimer(time(), sub {
	my $target = shift;
	my $targetHash = $defs{$target};
	plan(4);

	my $mock = Test2::Mock->new(
		track => 1,
		class => 'main',
		override => [
			InternalTimer => sub { 0 },
		],
	);	
	my $tracking = $mock->sub_tracking;

	subtest 'Test return values SIGNALduino_Get_delayed without existing command' => sub {
		plan(2);
		delete($targetHash->{ucCmd});
	
		SIGNALduino_Get_delayed("dummy_func:$target:dummy_command");
		ok($targetHash->{ucCmd}->{timenow}<=time(),'check timenow is set');
		is($tracking->{InternalTimer},U(),'InternalTimer not called');

		$mock->clear_sub_tracking;
	};

	
	subtest 'Test return values SIGNALduino_Get_delayed without timenow' => sub {
		plan(3);

		$targetHash->{ucCmd}{cmd} = "dummyCmd";
		delete($targetHash->{ucCmd}->{timenow});


		SIGNALduino_Get_delayed("dummy_func:$target:dummy_command");
		ok($targetHash->{ucCmd}->{timenow}<=time(),"check timenow is set");

		if (defined $tracking->{InternalTimer}) {
			is($tracking->{InternalTimer}[0]{args}[1], \&SIGNALduino_Get_delayed, "InternalTimer called with SIGNALduino_Get_delayed" );
			is($tracking->{InternalTimer}[0]{args}[2], "SIGNALduino_Get_delayed:$target:dummy_command", "InternalTimer called with SIGNALduino_Get_delayed" );
		}
		$mock->clear_sub_tracking;

	};
	
	
	subtest 'Test return values SIGNALduino_Get_delayed timeout not reached' => sub {
		plan(3);

		my $reftimenow = $targetHash->{ucCmd}->{timenow};

		SIGNALduino_Get_delayed("dummy_func:$target:dummy_command");
		is($targetHash->{ucCmd}->{timenow},$reftimenow,"check timenow isn't changed");

		if ( defined $tracking->{InternalTimer} ) {
			is( $tracking->{InternalTimer}[0]{args}[1]  , \&SIGNALduino_Get_delayed, "InternalTimer called with SIGNALduino_Get_delayed" );
			is( $tracking->{InternalTimer}[0]{args}[2] , "SIGNALduino_Get_delayed:$target:dummy_command", "InternalTimer called with SIGNALduino_Get_delayed" );
		}
		$mock->clear_sub_tracking;
	};
	
	subtest 'Test return values SIGNALduino_Get_delayed timeout reached' => sub {
		plan(3);

		$targetHash->{ucCmd}->{timenow} = time()-11;
		$mock->override('SIGNALduino_Get' => sub  { 0 } );	

		
		SIGNALduino_Get_delayed("dummy_func:$target:dummy_command");
		is($targetHash->{ucCmd}->{timenow},U,"check timenow is undefined");

		is($tracking->{InternalTimer},U(),'InternalTimer not called');
		is(scalar @{$tracking->{SIGNALduino_Get}},1,'SIGNALduino_Get is called');
		
		$mock->restore('InternalTimer');
		$mock->restore('SIGNALduino_Get');
		$mock->clear_sub_tracking;
	};
	
	delete($targetHash->{ucCmd});
	
	
	exit(0);
},'dummyDuino');

1;