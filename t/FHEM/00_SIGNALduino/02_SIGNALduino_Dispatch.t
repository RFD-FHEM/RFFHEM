use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{ is };
use Test2::Mock;

our %defs;

InternalTimer(time(), sub {
	my $target = shift;
	my $targetHash = $defs{$target};
    plan(3);

    note("Test can be extended to JSON MU data");
    note("Test expand to check input RSSI (only negative) ?");
	my $mock = Test2::Mock->new(
		track => 1,
		class => 'main',
		around => [
			SIGNALduno_Dispatch => sub { 
                my $orig = shift;
                my $self = shift;
                return $self->$orig(@_);
            },
		],
	);
	my $tracking = $mock->sub_tracking;

    my $rmsg="MS;P2=463;P3=-1957;P5=-3906;P6=-9157;D=26232523252525232323232323252323232323232325252523252325252323252325232525;CP=2;SP=6;R=75;";
    my $dmsg="s5C080EB2B000";
    SIGNALduno_Dispatch($targetHash, $rmsg, $dmsg, "-36.4","0.3");
    is($tracking->{SIGNALduno_Dispatch}[0]{args}[2], $dmsg, "Dispatch check dmsg" );
	$mock->restore('SIGNALduno_Dispatch');
    is(InternalVal($targetHash->{NAME},"LASTDMSG",""), $dmsg, "check Internal LASTDMSG" );
    is(InternalVal($targetHash->{NAME},"LASTDMSGID",""), "0.3", "check Internal LASTDMSGID" );

	exit(0);
},'dummyDuino');

1;
