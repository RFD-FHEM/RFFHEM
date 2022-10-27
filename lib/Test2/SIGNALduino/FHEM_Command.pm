package Test2::SIGNALduino::FHEM_Command;

#  tests are defined via array of hashes @mock, which is injectd from the calling scope
#   First Element in array can be a element which holds defaults
#   currently only mocking is suppored as a defauld
#    {
#        # Default mocking for every testrun in our loop
#        defaults    => {
#            mocking =>  sub { $mock->override ( IOWrite => sub { return @_ } );  } 
#        },
#    },

#    Defining a Test needs some*, but not all elements. More hints on Test2::SIGNALduino::FHEM_Command
#    {	
#      * targetName 	=> 	q[SD_UT_Test_6],			    # Name of the definition which is tested, must be defined before test starts
#	   * testname       =>  q[set command fan_off],         # Name of our setcommand
#      * cmd   	        =>	q[set fan_off],      			# Command to execute for test
#        # Check for arguments given to mocked sub
         # Anything from test2:compare can be used: https://metacpan.org/pod/Test2::Tools::Compare to verify called arguments for mocked sub
#      * subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P29#111110111110#R5' }; etc() } } } ,  
#      * returnCheck     => F(),                            # Check for false return from command
#        prep_hash       => {                               # All Items listed here will be added to the devicehash bevore the test starts
#            cc1101_available  =>  1,
#            DIODev   =>  'open',
#        },
#        prep_commands   => [                               # Any FHEM custom command can be placed in here, which will be called before the test is run
#			'set $targetName ?', 
#        ],
#        todo => 1, # Enable Todo block if item exists
#        hashCheck => hash { etc(); };                      # check againt hash values from the target device, skipped if key does not exists
#    },

#
#
#

use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is U validator};
use Test2::Todo;
use Test2::Mock;
use Test2::API qw/context run_subtest/;
use base 'Exporter';
our $mock;
our @mockData;

our @ISA = 'Exporter';
our @EXPORT = qw/@mockData $mock/;
our $VERSION = 1.00;

my $EMPTY = q{};



sub filterTestDataArray {
  my $modulename = shift;

  $modulename =~ s/^[0-9][0-9]_//; # Remove leading digtis
  my @results;

  return @results;
}


sub checkGet  {
    my $element = shift;
    my $targetHash = shift;

    my $cmd = qq[$targetHash->{NAME} $element->{cmd}];
    my $ret = main::CommandGet($targetHash,$cmd);

    my $result  = is($mock->sub_tracking,$element->{subCheck},q[verify subroutine tracking]);
    $result    &= is($ret,$element->{returnCheck},q[verify return value from command]);
    SKIP: {
        skip q[no reference value provided], ! exists $element->{hashCheck};
        $result    &= is($targetHash,$element->{hashCheck},q[verify hash values from targetdevice]);
    }
    
    return $result;
 }

sub checkAttr  {
    my $element = shift;
    my $targetHash = shift;

    my $cmd = qq[$targetHash->{NAME} $element->{cmd}];
    my $ret = main::CommandAttr($targetHash,$cmd);

    my $result  = is($mock->sub_tracking,$element->{subCheck},q[verify subroutine tracking]);
    $result    &= is($ret,$element->{returnCheck},q[verify return value from command]);
    SKIP: {
        skip q[no reference value provided], ! exists $element->{hashCheck};
        $result    &= is($targetHash,$element->{hashCheck},q[verify hash values from targetdevice]);
    }
    
    return $result;
 }


# check set command as subtest
sub checkSet  {
    my $element = shift;
    my $targetHash = shift;

    my $cmd = qq[$targetHash->{NAME} $element->{cmd}];
    my $ret = main::CommandSet($targetHash,$cmd);

    my $result  = is($mock->sub_tracking,$element->{subCheck},q[verify subroutine tracking]);
    $result    &= is($ret,$element->{returnCheck},q[verify return value from command]);
    SKIP: {
        skip (q[no reference value provided]) unless (exists $element->{hashCheck}) ;
        $result    &= is($targetHash,$element->{hashCheck},q[verify hash values from targetdevice]);
    }

    return $result;
}; # subtest

sub commandCheck {
    my $modulename = shift;

    my @filt_testDataArray = @mockData;
    # print Dumper(@filt_testDataArray);

    if (scalar @filt_testDataArray == 0) { pass("No testdata for module $modulename provided"); };

    $mock = Test2::Mock->new(
        track => 1, # enable call tracking if desired
        class => 'main',
    );  
    
    # Diable prototype mismatch warnings for redefined subs
    local $SIG{__WARN__} = sub { warn $_[0] unless $_[0] =~ /redefined|Prototype mismatch:/ };
    
    foreach my $element (@filt_testDataArray)
	{
		next if (!exists($element->{testname}));
    	$mock->clear_sub_tracking();
	    my $targetHash = $::defs{$element->{targetName}};
    
        # prepare internals or anything else in deviceHash
        $targetHash  = {%$targetHash, %$element{prep_hash}} if (exists($element->{prep_hash}));	

        ## exevute custom commands
        foreach my $cmd ( @{$element->{prep_commands}} )
        {
            $cmd =~ s/\$targetName/$targetHash->{NAME}/g;
            main::AnalyzeCommand(undef,$cmd);
        }
        
		#$element->{pre_code}->($target) if (exists($element->{pre_code}));
     	
        #my $ctx = context();

        my $todo;
        if ( exists $element->{todo}) {
            $todo = Test2::Todo->new(reason => $element->{todo} ); 
        }
        
        if(defined $element->{mocking}) {
            $element->{mocking}->() ;
        } elsif(defined $filt_testDataArray[0]{defaults}->{mocking})
        {
            $filt_testDataArray[0]{defaults}->{mocking}->();
        } 


        my ($op, $cmd) = split " ", $element->{cmd}, 2; 
        $element->{cmd} = $cmd;
        my $retVal = undef;
        if ( $op eq q[set] ) {
            $retVal = run_subtest(qq[Checking set commands for module: $modulename device: $targetHash->{NAME}: Test: $element->{testname} ], \&checkSet, {buffered => 1, inherit_trace => 1},$element, $targetHash);    
        } elsif ( $op eq q[get] ) {
            $retVal = run_subtest(qq[Checking set commands for module: $modulename device: $targetHash->{NAME}: Test: $element->{testname} ], \&checkGet, {buffered => 1, inherit_trace => 1},$element, $targetHash);    
        } elsif ( $op eq q[attr] ) {
            $retVal = run_subtest(qq[Checking set commands for module: $modulename device: $targetHash->{NAME}: Test: $element->{testname} ], \&checkAttr, {buffered => 1, inherit_trace => 1},$element, $targetHash);    
        }

        $mock->reset_all;
		undef ($todo);
        #$element->{post_code}->() if (exists($element->{post_code}));
        
        # Release Test2 context
        #$ctx->pass_and_release() if $retVal;
        #$ctx->fail_and_release($element->{testname}, $element) unless $retVal;
	};

    $mock = undef;
}
 
1;
