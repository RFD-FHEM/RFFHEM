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
		testname	=> q[Testdata with additional Rojaflex data],
		url			=> qq[$filepath/testData.json],
	};

	plan( scalar @Test2::SIGNALduino::RDmsg::JSONTestList +1);
	for my $maintest  (@Test2::SIGNALduino::RDmsg::JSONTestList)
	{
		subtest $maintest->{testname} => sub {
			dmsgCheck($maintest,$module,$ioHash);
		};
	}

	subtest 'parseFn channel 0 message' => sub {
        my $sensorname = 'SD_Rojaflex_3122FD2_0';
		::CommandDefMod(undef,"-temporary $sensorname SD_Rojaflex 3122FD2_0");
		::CommandDefMod(undef,"-temporary SD_Rojaflex_3122FD2_5 SD_Rojaflex 3122FD2_5");
		::CommandDefMod(undef,"-temporary SD_Rojaflex_3122FD2_4 SD_Rojaflex 3122FD2_4");
		::CommandAttr(undef,"SD_Rojaflex_3122FD2_4 bidirectional 0");
		
		my $dmsg = 'P109#083122FD208A018A85';
		my $ret = SD_Rojaflex::Parse($ioHash, $dmsg);
		
		plan(4);
		is($ret,$sensorname,q[check return value has sensorname]);
		is($defs{$sensorname}->{READINGS},
		hash { 
			field motor => 
			hash {
				field VAL => 'down'; 
				etc();
			};
			field state => 
			hash {
				field VAL => 'down'; 
				etc();
			};
			field tpos => 
			hash {
				field VAL => '100'; 
				etc();
			};
			etc(); 
		},'check some device readings channel 0');
	    

		is($defs{'SD_Rojaflex_3122FD2_5'}->{READINGS},
		hash { 
			field motor => 
			hash {
				field VAL => 'down'; 
				etc();
			};
			field state => 
			hash {
				field VAL => 'down'; 
				etc();
			};
			field tpos => 
			hash {
				field VAL => '100'; 
				etc();
			};
			etc(); 
		},'check some device readings channel 5 (bidirectional)');

		is($defs{'SD_Rojaflex_3122FD2_4'}->{READINGS},
		hash { 
			field motor => 
			hash {
				field VAL => 'down'; 
				etc();
			};
			field state => 
			hash {
				field VAL => 'down'; 
				etc();
			};
			field tpos => 
			hash {
				field VAL => '100'; 
				etc();
			};
			field pct => 
			hash {
				field VAL => '50'; 
				etc();
			};
			etc(); 
		},'check some device readings channel 4');

	};

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