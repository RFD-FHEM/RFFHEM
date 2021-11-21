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

our @EXPORT = qw/dmsgCheck/;
our $VERSION = 1.00;
our $testDataArray; 
our @JSONTestList = (
	{
		testname	=> 'Test with pre-release SD_Device_ProtocolList',
		url		=> 'https://raw.githubusercontent.com/RFD-FHEM/SIGNALduino_TOOL/pre-release/FHEM/lib/SD_Device_ProtocolList.json',
		todo  => 'Checking with pre-release Version of SD_Device_ProtocolList which can fail',
	},
	{
		testname	=> 'Test with master SD_Device_ProtocolList',
		url		=> 'https://raw.githubusercontent.com/RFD-FHEM/SIGNALduino_TOOL/master/FHEM/lib/SD_Device_ProtocolList.json',
		#todo  => 'Checking with master Version of SD_Device_ProtocolList which can fail',
	}
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
		fail("open json file SD_Device_ProtocolList was not possible $?"); 
		#use Data::Dumper;
		diag $json_text;
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

sub checkParseFn  {
    my $module = shift;
    my $tData = shift;
    my $ioHash = shift;
    use Data::Dumper;

    my $tplan=3; # one for readings and one for internals and one for defmod

    if (defined $tData->{internals}{DEF} && defined $tData->{internals}{NAME}) {
        $tplan++;
        note("device will be defined temporary");
        is(::CommandDefMod(undef,"-temporary $tData->{internals}{NAME} $module $tData->{internals}{DEF}"),U(),"Verify device return from defmod ",$tData);
    }

    if (defined $tData->{attributes}{model} ) {
        note("device attribute model $tData->{attributes}{model} set for right result");
        ::CommandAttr(undef,"$tData->{internals}{NAME} model $tData->{attributes}{model}"); # set attribute
    }
    
    
    #print Dumper(%main::modules);
    #my $ret=$main::modules{$module}{ParseFn}->($ioHash,$tData->{dmsg});

    no strict "refs"; 
    my $ret=&{$main::modules{$module}{ParseFn}}($ioHash,$tData->{dmsg});
    use strict "refs"; 
    
    is($ret,$tData->{internals}{NAME},'verify parseFn return equal internal NAME');

    SKIP: {
        skip 'readings' if ( !defined $ret || $ret eq $EMPTY || $ret eq q[NEXT] || scalar keys %{$tData->{readings}} < 1);
         
        subtest "Verify readings" => sub {
            plan(scalar keys %{$tData->{readings}} );
            while ( (my $rName, my $rValue) = each (%{$tData->{readings}}) )
            {
                is(::ReadingsVal($tData->{internals}{NAME} ,$rName,undef),$rValue,"check reading $rName");
            }
        };
    } #skip
    
    SKIP : {
        skip 'internals' if ( !defined $ret || $ret eq $EMPTY || $ret eq q[NEXT] || scalar keys %{$tData->{internals}} < 1);
        subtest "Verify internals" => sub {
            plan(scalar keys %{$tData->{internals}} );
            while ( (my $iName, my $iValue) = each (%{$tData->{internals}}) )
            {
                is(::InternalVal($tData->{internals}{NAME} ,$iName, undef),$iValue,"check internal $iName");						
            }
        };
    
        ::CommandDelete(undef,$tData->{internals}{NAME});
    } #skip

    plan($tplan);
}; # subtest

sub dmsgCheck {
    my $testDef = shift;
    my $modulename = shift;
    my $ioHash = shift;
    
    my $pID;
    my $tID;       
    my $testSet;          
  #  use Data::Dumper;
  #  print Dumper($main::modules{FS10});

    my $ctx = context();
    loadJson($testDef->{url});
    my @filt_testDataArray = filterTestDataArray($modulename);
    
    if (scalar @filt_testDataArray == 0) { pass('No testdata for module provided'); };

    my $todo;
    if ( exists $testDef->{todo}) {
        $todo = Test2::Todo->new(reason => $testDef->{todo} ); 
    }


    while ( ($pID, $testSet) = each @filt_testDataArray )
    {
        SKIP: {
            #skip 'Testset id not in scope' if (!defined $testSet->{id} || $testSet->{id} ne '61');
            skip 'Protocol does not exsists in ProtocolObject' if ( !$ioHash->{protocolObject}->protocolExists($testSet->{id}) );
            # skip 'Protocol is under development' if ( defined $ioHash->{protocolObject}->checkProperty($testSet->{id},'developId',undef) );
            while ( (my $tID, my $tData) = each (@{$testSet->{data}}) ) 
            {
                my $bool = run_subtest(qq[Checking parseFN for module: $testSet->{module} device: $testSet->{name} TestNo: $tID ($tData->{comment})], \&checkParseFn, {buffered => 1, inherit_trace => 1},$testSet->{module},$tData, $ioHash);
            } # while testSet
        } # SKIP
    } # while filt_testDataArray

    $ctx->release;
}
 
1;
