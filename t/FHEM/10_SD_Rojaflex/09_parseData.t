use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is U };
use Test2::Todo;
use JSON; 
use File::Basename;

our %defs;
our %attr;
our %modules;

my $testSet;
my $tData;
my $testDataArray; 
my $module = basename (dirname(__FILE__));



sub loadJson {
	my $url = shift;
	use HTTP::Tiny;
	my $response = HTTP::Tiny->new->get($url);
	fail("Failed!\n") unless $response->{success};

	$testDataArray = eval { decode_json($response->{content}) };
	if($@){
		fail("open json file SD_Device_ProtocolList was not possible $?"); 
		use Data::Dumper;
		diag Dumper ($response);
	}
}

sub filterTestDataArray {
  my $modulename = shift;

  $modulename =~ s/^[0-9][0-9]_//; # Remove leading digtis
  my @results;

  while ( (my $pID, my $testSet) = each  (@{$testDataArray}) )
  {
	  if (defined $testSet->{module} && $testSet->{module} eq $modulename)
	  {
		  push @results, $testSet
	  }
  }

  return @results;
}

my @TestList = (
	{
		testname	=> 'Test with pre-release SD_Device_ProtocolList',
		url		=> 'https://raw.githubusercontent.com/RFD-FHEM/SIGNALduino_TOOL/pre-release/FHEM/lib/SD_Device_ProtocolList.json',
		todo  => 'Checking with pre-release Version of SD_Device_ProtocolList which can fail',
	},
	{
		testname	=> 'Test with master SD_Device_ProtocolList',
		url		=> 'https://raw.githubusercontent.com/RFD-FHEM/SIGNALduino_TOOL/master/FHEM/lib/SD_Device_ProtocolList.json',
		#todo  => 'Checking with master Version of SD_Device_ProtocolList which can fail',
	},
#	{
#		testname	=> 'Test with patched SD_Device_ProtocolList',
#		url		=> 'https://raw.githubusercontent.com/RFD-FHEM/SIGNALduino_TOOL/patch-fixTests/FHEM/lib/SD_Device_ProtocolList.json',
#	},

);

InternalTimer(time()+1, sub {
	my $ioName = shift;
	my $ioHash = $defs{$ioName};

	plan (scalar @TestList +3);

	for my $maintest  (@TestList)
	{
		subtest $maintest->{testname} => sub {

			loadJson( $maintest->{url} );
			my @filt_testDataArray = filterTestDataArray($module);
			
			if (scalar @filt_testDataArray == 0) { pass('No testdata for module provided'); };

			my $todo;
			if ( exists $maintest->{todo}) {
				$todo = Test2::Todo->new(reason => $maintest->{todo} ); 
			}
			my $pID;
			my $tID;                 

			while ( ($pID, $testSet) = each @filt_testDataArray )
			{
				SKIP: {
					# skip 'Testset id not in scope' if (!defined $testSet->{id} || $testSet->{id} ne '79');
					skip 'Protocol does not exsists in ProtocolObject' if ( !$ioHash->{protocolObject}->protocolExists($testSet->{id}) );
					# skip 'Protocol is under development' if ( defined $ioHash->{protocolObject}->checkProperty($testSet->{id},'developId',undef) );
					while ( (my $tID, my $tData) = each (@{$testSet->{data}}) ) 
					{
						subtest "Checking module: $testSet->{module} device: $testSet->{name} TestNo: $tID " => sub {
							
							plan(3); # one for readings and one for internals and one for defmod
							note("device will be defined temporary");
							is(CommandDefMod(undef,"-temporary $tData->{internals}{NAME} $testSet->{module} $tData->{internals}{DEF}"),U(),"Verify device defmod",$tData);

							if ($tData->{attributes}{model}) {
								note("device attribute model $tData->{attributes}{model} set for right result");
								CommandAttr(undef,"$tData->{internals}{NAME} model $tData->{attributes}{model}"); # set attribute
							}

							no strict "refs"; 
							&{$modules{$testSet->{module}}{ParseFn}}($ioHash,$tData->{dmsg});
							use strict "refs"; 

							subtest "Verify readings" => sub {
								plan(scalar keys %{$tData->{readings}} );
								while ( (my $rName, my $rValue) = each (%{$tData->{readings}}) )
								{
									is(ReadingsVal($tData->{internals}{NAME} ,$rName,'0'),$rValue,"check reading $rName");
								}
							};
							
							subtest "Verify internals" => sub {
								plan(scalar keys %{$tData->{internals}} );
								while ( (my $iName, my $iValue) = each (%{$tData->{internals}}) )
								{
									is(InternalVal($tData->{internals}{NAME} ,$iName,'0'),$iValue,"check internal $iName");						
								}
							};
							CommandDelete(undef,$tData->{internals}{NAME});
						} # subtest
					} # while testSet
				} # SKIP
			} # while filt_testDataArray
		}; #subtest maintest
	} # for TestList


	subtest 'parse with to short data' => sub {
		my $dmsg = '109#083122FD2C1A011AB';
		my $ret = SD_Rojaflex::Parse($ioHash, $dmsg);
		
		plan(1);
		is($ret,U(),q[check return value for error])
	};

	subtest 'parse channel 0 message' => sub {
		my $dmsg = 'P109#083122FD208A018A85';
		my $ret = SD_Rojaflex::Parse($ioHash, $dmsg);
		my $sensorname = 'SD_Rojaflex_3122FD2_0';
		
		plan(3);
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
		},'check some device readings channel 5');

	};

	subtest 'parse tubular message channel 5' => sub {
		my $dmsg = 'P109#083122FD251A011AAA';
		my $ret = SD_Rojaflex::Parse($ioHash, $dmsg);
		my $sensorname = 'SD_Rojaflex_3122FD2_5';
		my $hash=$defs{$sensorname}; 
		plan(2);

		is($ret,$sensorname,q[check return value has sensorname]);
		is($defs{$sensorname}->{READINGS},
		hash { 
			field motor => 
			hash {
				field VAL => 'up'; 
				etc();
			};
			field state => 
			hash {
				field VAL => 'up'; 
				etc();
			};
			field tpos => 
			hash {
				field VAL => '0'; 
				etc();
			};
			etc(); 
		},'check some device readings channel 5');

	};

	exit(0);
	doneTesting();
},'dummyDuino');

1;