#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is U };
use Test2::Mock;
use Test2::Todo;

# Testtool which supports DMSG Tests from SIGNALDuino_tool
use Test2::SIGNALduino::RDmsg;

use File::Find;
use File::Basename;
use JSON; 
use List::Util qw[min max];

our %defs;
our %attr;
our $init_done;
our %modules;

my $testSet;
my $id_matched=undef;
my $dmsg_matched=undef;
my $SD_Dispatch_calledCounter=undef;
my $tData;

sub findTestdata {
    my($filename, $dir, undef) = fileparse($File::Find::name);
    if ($filename =~ /.json$/i && $filename =~ /testData/i )
    {
        my $modulename = basename($dir);
        $modulename =~ s/^[0-9][0-9]_//; # Remove leading digtis

        push @Test2::SIGNALduino::RDmsg::JSONTestList, {
          testname	=> qq[Testdata with $modulename data],
          url		  	=> qq[$File::Find::name],
          module    => $modulename
        };
    }
}


sub runTest {
	my $target = shift;
	my $targetHash = $defs{$target};
	my $mock = Test2::Mock->new(
		track => 1,
		class => q[main]
	);	 	
	my $tracking = $mock->sub_tracking;

  note(q[versionmodul: ].InternalVal($target, q[versionmodul], q[unknown]));
  note(q[versionProtocols: ].InternalVal($target, q[versionProtocols], q[unknown]));
  CommandAttr(undef,"$target maxMuMsgRepeat 99");
  
  note(q[Searching local testdata]);
  find(\&findTestdata, dirname(__FILE__).q[/../]);

  for my $cl ( split /:/, $targetHash->{Clients})
  {
    next if ( grep { $cl eq $_->{module} } @Test2::SIGNALduino::RDmsg::JSONTestList );
    
    my $loaded = main::LoadModule($cl);
    if (exists $modules{$cl}{META}{resources}{x_testData} )
    {
      note(qq[Seatching remote testdata for $cl]);
      for my $testFile ( @{$modules{$cl}{META}{resources}{x_testData}} ) {
        push @Test2::SIGNALduino::RDmsg::JSONTestList, $testFile;
      }
    }
  }
  

  sub VerifyDispatch { 
      #diag @_;
      my $hash = shift // fail('no hash provided');
      my $rmsg = shift // fail('no rmsg provided');
      my $dmsg = shift // fail('no dmsg provided');
      my $rssi = shift;
      my $id   = shift // fail('no id provided');

      is($id,$testSet->{id},'SIGNALduno_Dispatch id matched');
      
      my $todo = Test2::Todo->new(reason => 'Not all dispatches generates the same expected dmsg' );
      is($dmsg,$tData->{dmsg},'SIGNALduno_Dispatch dmsg matched',diag $dmsg); 
      $todo->end;

      ($tData->{dmsg} eq $dmsg) ? $dmsg_matched=1 : '';  
  } 


  plan (scalar @Test2::SIGNALduino::RDmsg::JSONTestList);
	for my $maintest  (@Test2::SIGNALduino::RDmsg::JSONTestList)
  {
    Test2::SIGNALduino::RDmsg::loadJson( $maintest->{url} );
    
    SKIP: {
       if (!UNIVERSAL::isa($Test2::SIGNALduino::RDmsg::testDataArray, 'ARRAY') || scalar @{$Test2::SIGNALduino::RDmsg::testDataArray} == 0) { 
        skip qq[No testdata for $maintest->{testname} provided, guessing ok]; 
      }

      subtest $maintest->{testname} => sub {
      
        my $todo;
        if ( exists $maintest->{todo}) {
          $todo = Test2::Todo->new(reason => $maintest->{todo} ); 
        }
        my $pID;
        my $tID;                 
        $mock->override('SIGNALduno_Dispatch' => \&VerifyDispatch);

        while ( ($pID, $testSet) = each (@{$Test2::SIGNALduino::RDmsg::testDataArray}) )
        {
          SKIP: {
           # skip 'Testset id not in scope' if (!defined $testSet->{id} || $testSet->{id} ne '79');
            skip 'Protocol does not exsists in ProtocolObject' if (!$targetHash->{protocolObject}->protocolExists($testSet->{id}));
            subtest 'Protocol ID under test: '.$testSet->{id} => sub {
              plan(scalar @{$testSet->{data}} );
              while ( ($tID, $tData) = each (@{$testSet->{data}}) ) 
              {
                $mock->clear_sub_tracking;
                $dmsg_matched=undef;
                SKIP: {

                  skip 'rmsg or dmsg doese not exist' if (!exists $tData->{rmsg} || !exists $tData->{dmsg}  || $tData->{rmsg} eq q[] || !defined $tData->{rmsg});

                  subtest "$testSet->{name}: [subtest: $tID] " => sub {
                    if ( defined $tData->{dispatch_repeats} ) {
                      plan(3 + ($tData->{dispatch_repeats}+1) *2 );
                    } else {
                      note('Number ob tests can not be calculated, because number of repeats are unknown, running subtest without plan');
                    }
                    
                    CommandAttr(undef,"$target whitelist_IDs $testSet->{id}");
                    is(AttrVal($target,"whitelist_IDs",undef), $testSet->{id}, "whitelist_IDs is ".AttrVal($target,"whitelist_IDs",undef));
                    $id_matched=0;
                    $dmsg_matched=0;
                    $SD_Dispatch_calledCounter=0;
                    my $return = SIGNALduino_Parse($targetHash, $targetHash, $targetHash->{NAME}, qq[\002$tData->{rmsg}\003]);
                    #my $expected_repeat=min(AttrVal($target,"maxMuMsgRepeat",99),$tData->{dispatch_repeats});
                    SKIP: {
                      skip 'Test repeats' if ( !defined($tData->{dispatch_repeats}) ); 
                      is(scalar @{$tracking->{SIGNALduno_Dispatch}}-1,$tData->{dispatch_repeats}, 'no of SIGNALduno_Dispatch calls vs dispatch_repeats');
                    };
                    is($dmsg_matched,1,'dmsg matched once',q{parse returned}, $return);
                    
                  }; # inner subtest
                }; # inner SKIP
              };
            };
          }; # end of SKIP:
        };
        $mock->restore('SIGNALduno_Dispatch');
        if ( exists $maintest->{todo}) {
          $todo->end;
        }
      }; #subtest
    }; # SKIP#
  }; # end for loop

	
};


sub waitDone {

	if ($init_done) 
	{
  	runTest(@_);
    done_testing();
    exit(0);
	} else {
		InternalTimer(time()+0.2, &waitDone,@_);			
	}

}

waitDone('dummyDuino');

1;