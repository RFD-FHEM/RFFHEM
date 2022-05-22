#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is U };
use Test2::Mock;
use Test2::Todo;

our %defs;
our %attr;

my $testSet;
my $id_matched=undef;
my $dmsg_matched=undef;
my $SD_Dispatch_calledCounter=undef;
my $tData;
my $testDataArray; 

InternalTimer(time()+1, sub {
	my $target = shift;
	my $targetHash = $defs{$target};
	my $mock = Test2::Mock->new(
		track => 1,
		class => 'main'
	);	 	
	my $tracking = $mock->sub_tracking;

  note("versionmodul: ".InternalVal($target, "versionmodul", "unknown"));
  note("versionProtocols: ".InternalVal($target, "versionProtocols", "unknown"));
  CommandAttr(undef,"$target maxMuMsgRepeat 99");
  
  use JSON; 
  use List::Util qw[min max];


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

  sub loadJson {
    my $url     = shift;
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

  my @TestList = (
     {
       testname	=> 'Test with pre-release SD_Device_ProtocolList',
       url		  => 'https://raw.githubusercontent.com/RFD-FHEM/SIGNALduino_TOOL/pre-release/FHEM/lib/SD_Device_ProtocolList.json',
       todo     => 'Checking with pre-release Version of SD_Device_ProtocolList which can fail',
     },
     {
       testname	=> 'Test with master SD_Device_ProtocolList',
       url	  	=> 'https://raw.githubusercontent.com/RFD-FHEM/SIGNALduino_TOOL/master/FHEM/lib/SD_Device_ProtocolList.json',
       todo     => 'Checking with master Version of SD_Device_ProtocolList which can fail',
     },
    {
      testname	=> 'Test with patched SD_Device_ProtocolList',
      url		    => 'https://raw.githubusercontent.com/RFD-FHEM/SIGNALduino_TOOL/patch-fixTests/FHEM/lib/SD_Device_ProtocolList.json',
    },
 );


  plan (scalar @TestList);

  for my $maintest  (@TestList)
  {
    subtest $maintest->{testname} => sub {

        loadJson( $maintest->{url} );

        my $todo;
        if ( exists $maintest->{todo}) {
          $todo = Test2::Todo->new(reason => $maintest->{todo} ); 
        }
        my $pID;
        my $tID;                 
        $mock->override('SIGNALduno_Dispatch' => \&VerifyDispatch);

        while ( ($pID, $testSet) = each  (@{$testDataArray}) )
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

                  skip 'rmsg or dmsg doese not exist' if (!exists $tData->{rmsg} || !exists $tData->{dmsg} );

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
                    SIGNALduino_Parse($targetHash, $targetHash, $targetHash->{NAME}, "\002".$tData->{rmsg}."\003") if (defined($tData->{rmsg}));
                    #my $expected_repeat=min(AttrVal($target,"maxMuMsgRepeat",99),$tData->{dispatch_repeats});
                    SKIP: {
                      skip 'Test repeats' if ( !defined($tData->{dispatch_repeats}) ); 
                      is(scalar @{$tracking->{SIGNALduno_Dispatch}}-1,$tData->{dispatch_repeats}, 'no of SIGNALduno_Dispatch calls vs dispatch_repeats');
                    };
                    is($dmsg_matched,1,'dmsg matched once');
                    
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
    };
  }; # end for loop

  # subtest 'Test with master SD_Device_ProtocolList' => sub {
  #   loadJson("https://raw.githubusercontent.com/RFD-FHEM/SIGNALduino_TOOL/master/FHEM/lib/SD_Device_ProtocolList.json");

  #   my $pID;
  #   my $tID;

  #   my $SD_Dispatch = $mock->mock("SIGNALduno_Dispatch"); 
  #   my $noTestRun=1;
  #   while ( ($pID, $testSet) = each  (@{$testDataArray}) )
  #   {
  #     #next if ($testSet->{id} != 45);
  #     #next if ($testSet->{name} ne "NC-3911-675" );
  #     next if (!$targetHash->{protocolObject}->protocolExists($testSet->{id}));
  #     next if ($targetHash->{protocolObject}->checkProperty($testSet->{id},'developId',undef));
  #     while ( ($tID, $tData) = each (@{$testSet->{data}}) ) 
  #     {
  #       next if (!defined($tData->{rmsg}) || !defined($tData->{dmsg}) || !defined($tData->{internals}) );

  #       subtest "[$pID]: $testSet->{name}: [$tID] " => sub {
  #         CommandAttr(undef,"$target whitelist_IDs $testSet->{id}");
  #         is(AttrVal($target,"whitelist_IDs",undef), $testSet->{id}, "whitelist_IDs is ".AttrVal($target,"whitelist_IDs",undef));
  #         $SD_Dispatch->reset();
  #         $SD_Dispatch->side_effect(\&VerifyDispatch);
  #         #SIGNALduino_Log3 $target, 5,  Dumper($tData);
  #         $id_matched=0;
  #         $dmsg_matched=0;
  #         $SD_Dispatch_calledCounter=0;
  #         SIGNALduino_Parse($targetHash, $targetHash, $targetHash->{NAME}, "\002".$tData->{rmsg}."\003") if (defined($tData->{rmsg}));
  #         if ($SD_Dispatch->called() >0 )  {
  #           $noTestRun=0;

  #           ok($id_matched,"SIGNALduno_Dispatch check id ") || note explain (($SD_Dispatch->called_with())[4] , " vs ", $testSet->{id});
  #           ok($dmsg_matched,"SIGNALduno_Dispatch check dmsg ") || note explain (($SD_Dispatch->called_with())[2] , " vs ", $testSet->{dmsg});

  #           my $expected_repeat=min(AttrVal($target,"maxMuMsgRepeat",99),$tData->{dispatch_repeats});
  #           {
  #              my $todo = Test2::Todo->new(reason => 'Checking dispatches (all dispatches are counted across all modules');
  #              is($tData->{dispatch_repeats}, $SD_Dispatch_calledCounter-1, "JSON (master) dispatch_repeats accuracy ".$testSet->{name}) if (defined($tData->{dispatch_repeats}));
  #              $todo->end;
  #           };
  #         } else { diag "SIGNALduno_Dispatch (master ID".$testSet->{id}.") was not called, this must be an error"; }
  #       };
  #     }
  #   };
  #   is($noTestRun,0,"Verify if a test was performed ");
  #   $SD_Dispatch->unmock;
  # };


	exit(0);
},'dummyDuino');

1;