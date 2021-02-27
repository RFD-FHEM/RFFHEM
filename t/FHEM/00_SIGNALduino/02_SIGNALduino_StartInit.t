use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is};
use Test2::Mock;

our %defs;
our %attr;

InternalTimer(time()+1, sub {
	my $target = shift;
	my $targetHash = $defs{$target};
	plan (2);	
	my $mock = Test2::Mock->new(
		track => 1,
		class => 'main'
	);	 	
	my $tracking = $mock->sub_tracking;


	subtest 'Test with initretry=1' => sub {
		plan(4);

		$mock->override('SIGNALduino_SimpleWrite' => sub {  } ) ;
	 	$targetHash->{initretry} = 1;

		my $ret=SIGNALduino_StartInit($targetHash);
		is(scalar @{$tracking->{SIGNALduino_SimpleWrite}},1,'SIGNALduino_SimpleWrite called');
	    is( $tracking->{SIGNALduino_SimpleWrite}[0]{args}[1], "V", "SIGNALduino_SimpleWrite called with V" );
		is($targetHash->{ucCmd}->{cmd},"version","ucCmd is- version");
		is($targetHash->{DevState},"waitInit","check DevState");
		$mock->restore('SIGNALduino_SimpleWrite');
	}; 

	subtest 'Test with initretry=3' => sub {
		plan(5);

		$mock->override('SIGNALduino_ResetDevice' => sub { 0 } ) ;
		$targetHash->{initretry} = 3;

		is($targetHash->{initResetFlag},undef,'check initResetFlag before beginning');
		my $ret=SIGNALduino_StartInit($targetHash);
		is(scalar @{$tracking->{SIGNALduino_ResetDevice}},1,'SIGNALduino_ResetDevice called');
		is($targetHash->{DevState},"INACTIVE","check DevState");
		is($targetHash->{initResetFlag},1,"check initResetFlag");
		$mock->restore('SIGNALduino_ResetDevice');

		$mock->override('SIGNALduino_CloseDevice' => sub { 0 } ) ;

		$ret=SIGNALduino_StartInit($targetHash);
		is(scalar @{$tracking->{SIGNALduino_CloseDevice}},1,"SIGNALduino_CloseDevice called");
		$mock->restore('SIGNALduino_CloseDevice');
	}; 

	exit(0);
},'dummyDuino');

1;