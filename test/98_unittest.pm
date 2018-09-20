#
#  98_unittest.pm 
#

package main;
use strict;
use warnings;
# Laden evtl. abhängiger Perl- bzw. FHEM-Module
use Mock::Sub (no_warnings => 1);
use Test::More;
use Data::Dumper qw(Dumper);


# Variablen



# FHEM Modulfunktionen

sub UnitTest_Initialize() {
	my ($hash) = @_;
	$hash->{DefFn}         = "UnitTest_Define";
	$hash->{UndefFn}       = "UnitTest_Undef";
	$hash->{NotifyFn}      = "UnitTest_Notify";
	
}

sub UnitTest_Define() {
	my ( $hash, $def ) = @_;
   
    my @param = split('[ \t]+', $def);
    
    if(@param != 3) {
        my $msg = "wrong syntax: define <name> UnitTest <name of target device>";
    	Log3 undef, 2, $msg;
    	return $msg;
    }
    $hash->{name}  = $param[0];
    $hash->{targetDevice}  = $param[2];
    
    Log3 $param[0], 2, "Defined unittest for target: ".$hash->{targetDevice};
    
    return undef;

}

sub UnitTest_Undef($$)    
{                     
	return undef;                  
}

sub UnitTest_Notify($$)
{
  my ($own_hash, $dev_hash) = @_;
  my $ownName = $own_hash->{NAME}; # own name / hash

  return "" if(IsDisabled($ownName)); # Return without any further action if the module is disabled

  my $devName = $dev_hash->{NAME}; # Device that created the events

  my $events = deviceEvents($dev_hash,1);
  
  return if( !$events );

  foreach my $event (@{$events}) {
    $event = "" if(!defined($event));
    if ($devName eq "global" && $event eq "INITIALIZED")
    {
    	UnitTest_Test_1($own_hash);
    }
    # Examples:
    # $event = "readingname: value" 
    # or
    # $event = "INITIALIZED" (for $devName equal "global")
    #
    # processing $event with further code
  }
}

sub UnitTest_Test_1
{
	my ($own_hash) = @_;
	
	my $targetHash = $defs{$own_hash->{targetDevice}};
	#print Dumper($targetHash);
	
    ok( $targetHash->{TYPE} eq "SIGNALduino", 'SIGNALduino detected' );
    ok( ReadingsVal($targetHash->{NAME},"state","") eq "opened", 'SIGNALduino is opened' );


    # Bad tests, bevause the result depends on the time which is over till now
	#ok( keys %{$targetHash->{msIdList}} == 0, 'msIdList not yet initialized' );
	#ok( $targetHash->{muIdList} eq "SIGNALduino", 'SIGNALduino detected' );
	#ok( $targetHash->{mcIdList} eq "SIGNALduino", 'SIGNALduino detected' );
	
}

sub UnitTest_mock_log3
{
	# Placeholder function for mocking a fhem sub
	
	my ($own_hash) = @_;
	
	my $mock = Mock::Sub->new;
 	my $Log = $mock->mock('Log3');
 	
    Log3 undef, 2, "test Message";


	$Log->name;         # name of sub that's mocked
	$Log->called;       # was the sub called?
	$Log->called_count; # how many times was it called?
	$Log->called_with;  # array of params sent to sub
	print Dumper($Log);
	
	
}

# Eval-Rückgabewert für erfolgreiches
# Laden des Moduls
1;


# Beginn der Commandref

=pod
=item [helper|device|command]
=item summary Helpermodule which supports unit tesing
=item summary_DE Hilfsmodul was es ermöglicht unit test auszuführen

=begin html
 Englische Commandref in HTML
=end html

=begin html_DE
 Deustche Commandref in HTML
=end html

# Ende der Commandref
=cut