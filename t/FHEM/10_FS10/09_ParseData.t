use strict;
use warnings;
use Test2::V0;
use File::Basename;

# Testtool which supports DMSG Tests from SIGNALDuino_tool
use Test2::RDmsg;

our %defs;
our $init_done;

my $module = basename (dirname(__FILE__));


sub runTest {
	my $ioName = shift;
	my $ioHash = $defs{$ioName};
    #use Data::Dumper;
    #print Dumper(@Test::RDmsg::JSONTestList);
	my $filepath = dirname(__FILE__);
	push @Test2::RDmsg::JSONTestList, {
		testname	=> q[Testdata with corrupt FS10 data],
		url			=> qq[$filepath/testData.json],
	};

	plan( scalar @Test2::RDmsg::JSONTestList);
	for my $maintest  (@Test2::RDmsg::JSONTestList)
	{
		subtest $maintest->{testname} => sub {
			Test2::RDmsg::dmsgCheck($maintest,$module,$ioHash);
		};
	}
	exit(0);
}

sub waitDone {

	if ($init_done) 
	{
		runTest(@_);
	} else {
		InternalTimer(time()+0.5, &waitDone,@_);			
	}

}

waitDone('dummyDuino');


1;