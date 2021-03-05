use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{ U };

our %defs;

InternalTimer(time(), sub {
	my $target = shift;
	my $targetHash = $defs{$target};

	plan(1);
	$targetHash->{LaCrossePair} = 1;
	SIGNALduino_RemoveLaCrossePair($targetHash);
	is(InternalVal($target,'LaCrossePair',undef),U(),'Verify LaCrossePair is removed');
	

	exit(0);
},'dummyDuino');

1;