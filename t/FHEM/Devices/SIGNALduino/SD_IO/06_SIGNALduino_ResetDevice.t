#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is U };
use Test2::Mock;

# Mock device hash and environment
my $target = 'cc1101dummyDuino';
our %defs = ($target => { 
    NAME => "$target", 
    cc1101_available => 1,
    logMethod => sub { my ($hash, $level, $msg) = @_; note "Log $level: $msg"; return }, # dummy logMethod
  }
);
our $targetHash = $defs{$target};

# --- Mocks for FHEM environment and dependencies ---
my $mock_main = Test2::Mock->new(
  track => 1,
  class => 'main',
  autoload => 1,
  add => [ 
    AttrVal => sub {
      my ($name, $attr, $default) = @_;
      return $targetHash->{attr}{$attr} // $default;
	},
	SDUINO_VERSION => sub { '4.0.0' },
  ]
);

# Mock FHEM::Core::Timer::Helper for this test - ugly hack due to lack of better mocking options
package FHEM::Core::Timer::Helper;
sub addTimer
{
	return ;
}
package main;

use FHEM::Devices::SIGNALduino::SD_IO qw(SIGNALduino_ResetDevice);

plan (2);	
my $mock_IO = Test2::Mock->new(
	track => 1,
	class => 'FHEM::Devices::SIGNALduino::SD_IO',
	override => [
		'SIGNALduino_Connect' => sub { note "SIGNALduino_Connect called"; return;},
	]
);	 	


subtest 'reset with specialReset flag set' => sub {
	plan(3);
	my $tracking = $mock_main->sub_tracking;	
	$targetHash->{helper}{resetInProgress}=1;

	SIGNALduino_ResetDevice($targetHash);

	is (scalar @{$tracking->{DevIo_OpenDev}},1,'check if DevIo_OpenDev is called once');
	is ($tracking->{InternalTimer},U(),'check if InternalTimer is not called once');
	is ($targetHash->{helper}{resetInProgress},U(),'check reset in progress flag deleted');
	
	$mock_main->clear_sub_tracking();
};

subtest 'reset for dummy device' => sub {
	plan(4);
	$mock_main->add('IsDummy' => sub { ok(1,'isDummy is called'); return 1; });
	SIGNALduino_ResetDevice($targetHash);
	
	my $tracking = $mock_main->sub_tracking;	

	is (scalar @{$tracking->{readingsSingleUpdate}},1,'check if readingsSingleUpdate is called once');
	is ($tracking->{readingsSingleUpdate}->[0]->{args},array {item D(); item 'state'; item 'opened'; etc();},'check if readingsSingleUpdate is called with correct arguments');
	is ($targetHash->{DevState},'initialized','check if DevState is set to initialized' );
	
	$mock_main->clear_sub_tracking();
	$mock_main->reset('IsDummy' );
};


done_testing();
exit(0);

1;