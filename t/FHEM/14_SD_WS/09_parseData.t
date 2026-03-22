#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use File::Basename;

# Testtool which supports DMSG Tests from SIGNALDuino_tool
use Test2::SIGNALduino::RDmsg;

our %defs;
our $init_done;

my $module = basename (dirname(__FILE__));


sub runTest {
	my $ioName = shift;
	my $ioHash = $defs{$ioName};
    #use Data::Dumper;
    #print Dumper(@Test::RDmsg::JSONTestList);
	my $filepath = dirname(__FILE__);
	push @Test2::SIGNALduino::RDmsg::JSONTestList, {
		testname	=> qq[Testdata with $module data],
		url			=> qq[$filepath/testData.json],
	};

	plan( scalar @Test2::SIGNALduino::RDmsg::JSONTestList + 1 );
	for my $maintest  (@Test2::SIGNALduino::RDmsg::JSONTestList)
	{
		subtest $maintest->{testname} => sub {
			Test2::SIGNALduino::RDmsg::dmsgCheck($maintest,$module,$ioHash);
		};
	}

	subtest q[Regression: sanity check uses reading age, not state age] => sub {
		my $sensorname = q[SD_WS_115_regression];
		my $ret = CommandDefMod(undef, qq[ -temporary $sensorname SD_WS SD_WS_115_0]);
		is($ret, undef, q[temporary device defined]);

		setReadingsVal($defs{$sensorname}, q[humidity], q[32], FmtDateTime(CORE::time() - 7200));
		setReadingsVal($defs{$sensorname}, q[temperature], q[-7.4], FmtDateTime(CORE::time() - 60));
		setReadingsVal($defs{$sensorname}, q[state], q[T: -7.4 H: 32 W: 0], TimeNow());

		$ret = $main::modules{SD_WS}{ParseFn}->($ioHash, q[W115#9104143025BE18FFFFFF2928925A97FFF0000000000000000003]);
		is($ret, $sensorname, q[parse succeeds when humidity reading is older than state]);
		is(ReadingsVal($sensorname, q[humidity], undef), q[97], q[humidity reading updated]);
		is(ReadingsVal($sensorname, q[temperature], undef), q[-7.5], q[temperature reading updated]);

		CommandDelete(undef, $sensorname);
		done_testing();
	};
	exit(0);
}

sub waitDone {

	if ($init_done) 
	{
		runTest(@_);
	} else {
		InternalTimer(time()+0.2, &waitDone,@_);			
	}

}

waitDone('dummyDuino');

1;
