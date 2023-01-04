package Test2::SIGNALduino::RDmsg;

use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is U };
use Test2::Todo;
use JSON; 
use File::Basename;
use Test2::API qw/context run_subtest/;
use base 'Exporter';

our @EXPORT = qw/dmsgCheck rmsgCheck/;
our $VERSION = 1.00;
our $testDataArray; 
our @JSONTestList = (
#	{
# 		testname	=> 'Test with pre-release SD_Device_ProtocolList',
#		url		=> 'https://raw.githubusercontent.com/RFD-FHEM/SIGNALduino_TOOL/pre-release/FHEM/lib/SD_Device_ProtocolList.json',
#		todo  => 'Checking with pre-release Version of SD_Device_ProtocolList which can fail',
#	},
#	{
#		testname	=> 'Test with master SD_Device_ProtocolList',
#		url		=> 'https://raw.githubusercontent.com/RFD-FHEM/SIGNALduino_TOOL/master/FHEM/lib/SD_Device_ProtocolList.json',
#		#todo  => 'Checking with master Version of SD_Device_ProtocolList which can fail',
#	}
);
my $EMPTY = q{};


sub loadJson {
	my $url = shift;

    my $json_text;
    if ($url =~ /^https:\/\//i)
    {
        use HTTP::Tiny;
        my $response = HTTP::Tiny->new->get($url);
        fail("Failed!\n") unless $response->{success};
        $json_text = $response->{content};
    }  else {
        $json_text = do {
        open(my $json_fh, "<:encoding(UTF-8)", $url)
            or fail(qq[Can't open $url: $!\n]);
        local $/;
        <$json_fh>
        };
    }

	$testDataArray = eval { decode_json($json_text) };
	if($@){
		fail("open json file $url was not possible $?"); 
		diag $json_text;
	}
}

sub filterTestDataArray {
  my $modulename = shift;

  $modulename =~ s/^[0-9][0-9]_//; # Remove leading digtis
  my @results;
  return  if (ref $testDataArray ne 'ARRAY');
  while ( (my $pID, my $testSet) = each  (@{$testDataArray}) )
  {
      if (defined $testSet->{module} && $testSet->{module} eq $modulename)
	  {
		  push @results, $testSet
	  }
  }

  return @results;
}

sub checkDmsgParseFn  {
    my $module = shift;
    my $tData = shift;
    my $ioHash = shift;

    my $tplan=0; 

    foreach my $testMocks ( @{$tData->{tests}} )
    {
        for my $element ( qw/internals readings/ )
        { 
            for my $name ( %{$tData->{$element} })
            {
                if (!exists $testMocks->{$element}{$name} && exists $tData->{$element}{$name}) {
                    $testMocks->{$element}{$name} = $tData->{$element}{$name};
                }
            }
        }
        if (!exists $testMocks->{returns}->{ParseFn} ) {
            $testMocks->{returns}->{ParseFn} = $testMocks->{internals}{NAME};
        }

        subtest qq[Starting Test $testMocks->{comment}] => sub {
            # Set some defaults from global element for each test

            $tplan=3; 
            if (defined $testMocks->{internals}{DEF} && defined $testMocks->{internals}{NAME}) {
                $tplan++;
                note('device will be defined temporary');
                is(::CommandDefMod(undef,qq[ -temporary $testMocks->{internals}{NAME} $module $testMocks->{internals}{DEF}]),U(),"Verify device return from defmod ",$tData);
            }

            ## execute custom commands
            foreach my $cmd ( @{$testMocks->{prep_commands}} )
            {
                note(qq[execute command: $cmd]);
                main::AnalyzeCommand(undef,$cmd);
            }

            if (defined $testMocks->{setreadings} && defined $testMocks->{internals}{NAME} ) {
                
                while ( (my $rName, my $rValue) = each (%{$testMocks->{setreadings}}) )
                {   
                    note(qq[reading $rName be set to $rValue]);
                    ::CommandSetReading(undef,qq[$testMocks->{internals}{NAME} $rName $rValue] );
                }
            }

            if (defined $testMocks->{attributes} && defined $testMocks->{internals}{NAME} ) {
                while ( (my $aName, my $aValue) = each (%{$testMocks->{attributes}}) )
                { 
                    note("device attribute $aName set for right result: $aValue");
                    ::CommandAttr(undef,"$testMocks->{internals}{NAME} $aName  $aValue"); # set attribute
                }
            }
            
            my $ret = $main::modules{$module}{ParseFn}->($ioHash,$tData->{dmsg});
            
            is($ret,$testMocks->{returns}->{ParseFn} ,'verify parseFn return expected result');

            SKIP: {
                skip 'readings' if ( !defined $ret || $ret eq $EMPTY || $ret eq q[NEXT] || scalar keys %{$testMocks->{readings}} < 1);
                
                subtest "Verify readings" => sub {
                    plan(scalar keys %{$testMocks->{readings}} );
                    while ( (my $rName, my $rValue) = each (%{$testMocks->{readings}}) )
                    {
                        is(::ReadingsVal($testMocks->{internals}{NAME} ,$rName,undef),$rValue,"check reading $rName");
                    }
                };
            } #skip
            
            SKIP : {
                skip 'internals' if ( !defined $ret || $ret eq $EMPTY || $ret eq q[NEXT] || scalar keys %{$testMocks->{internals}} < 1);
                subtest "Verify internals" => sub {
                    plan(scalar keys %{$testMocks->{internals}} );
                    while ( (my $iName, my $iValue) = each (%{$testMocks->{internals}}) )
                    {
                        is(::InternalVal($testMocks->{internals}{NAME} ,$iName, undef),$iValue,"check internal $iName");						
                    }
                };
            } #skip
            ::CommandDelete(undef,$testMocks->{internals}{NAME}) if (defined $testMocks->{internals}{NAME});
            plan($tplan);
        };  #subtest
    }; # loop

}; # checkDmsgParseFn

sub dmsgCheck {
    my $testDef = shift;
    my $modulename = shift;
    my $ioHash = shift;
    
    my $pID;
    my $tID;       
    my $testSet;          

    my $ctx = context();
    loadJson($testDef->{url});
    my @filt_testDataArray = filterTestDataArray($modulename);
    
    if (scalar @filt_testDataArray == 0) { pass('No testdata for module provided'); };

    my $todo;
    if ( exists $testDef->{todo}) {
        $todo = Test2::Todo->new(reason => $testDef->{todo} ); 
    }
    
    my $loaded = main::CommandReload(undef,$modulename);
    note(qq[CommandReload(undef,$modulename) = $loaded]);
    while ( ($pID, $testSet) = each @filt_testDataArray )
    {
        SKIP: {
            #skip 'Testset id not in scope' if (!defined $testSet->{id} || $testSet->{id} ne '61');
            skip 'Protocol does not exsists in ProtocolObject' if ( !$ioHash->{protocolObject}->protocolExists($testSet->{id}) );
            # skip 'Protocol is under development' if ( defined $ioHash->{protocolObject}->checkProperty($testSet->{id},'developId',undef) ); 
            my $mmRe = qr/$main::modules{$testSet->{module}}{Match}/;

            while ( (my $tID, my $tData) = each (@{$testSet->{data}}) ) 
            {
                SKIP: {

                    if ( !exists $tData->{tests} || scalar @{$tData->{tests}} == 0 ) { 
                        skip qq[no referencedata for test $tData->{comment}]; 
                    }
                    my $bool = run_subtest(qq[Checking parseFN for module: $testSet->{module} device: $testSet->{name} DataNr: $tID ($tData->{comment})], \&checkDmsgParseFn, {buffered => 1, inherit_trace => 1},$testSet->{module},$tData, $ioHash);
                }

                if ( $tData->{MatchCheckFail} )
                {
                   unlike($tData->{dmsg},$mmRe,qq[Verify Module unmatch for module: $testSet->{module} device: $testSet->{name} DataNr: $tID ($tData->{comment})]);
                } else {
                   like($tData->{dmsg},$mmRe,qq[Verify Module match for module: $testSet->{module} device: $testSet->{name} DataNr: $tID ($tData->{comment})]);
                }
            } # while testSet
        } # SKIP
    } # while filt_testDataArray

    $ctx->release;
}


sub rmsgCheck {

}


1;
