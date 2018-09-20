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
    	UnitTest_Test_2($own_hash);
    	
    	InternalTimer(gettimeofday()+4, 'UnitTest_Test_3',$own_hash,0);       # verzoegern bis alle Attribute eingelesen sind
    	
    	
    }
    # Examples:
    # $event = "readingname: value" 
    # or
    # $event = "INITIALIZED" (for $devName equal "global")
    #
    # processing $event with further code
  }
}


#
# Verify if the given device is a signalduino and if it is opened
#

sub UnitTest_Test_1
{
	my ($own_hash) = @_;
	
	my $targetHash = $defs{$own_hash->{targetDevice}};
	#print Dumper($targetHash);
	
    is( $targetHash->{TYPE}, "SIGNALduino", 'SIGNALduino detected' );
    is( ReadingsVal($targetHash->{NAME},"state",""),"opened", 'SIGNALduino is opened' );


    # Bad tests, bevause the result depends on the time which is over till now
	#ok( keys %{$targetHash->{msIdList}} == 0, 'msIdList not yet initialized' );
	#ok( $targetHash->{muIdList} eq "SIGNALduino", 'SIGNALduino detected' );
	#ok( $targetHash->{mcIdList} eq "SIGNALduino", 'SIGNALduino detected' );
	
}


#
# Verify if the SIGNALDuino_Shutdown sub writes the correct chars to the serial port
#
sub UnitTest_Test_2
{
	use Test::Device::SerialPort;
	my ($own_hash) = @_;
	my $targetHash = $defs{$own_hash->{targetDevice}};

    ## Mock a dummy serial device
	my $PortObj = Test::Device::SerialPort->new('/dev/ttyS0');
	$PortObj->baudrate(57600);
    $PortObj->parity('none');
    $PortObj->databits(8);
    $PortObj->stopbits(1);
	$targetHash->{USBDev} = $PortObj;
	CallFn($targetHash->{NAME}, "ShutdownFn", $targetHash);
	
    is( $targetHash->{USBDev}->{_tx_buf}, "XQ\n", 'SIGNALDuino_Shutdown sends correct characters' );
    
    #cleanup
    $targetHash->{USBDev} = undef;
}

#
# Verify MS Decoder with NC_WS Data
# DMSG s5C080FC32000
# T: 25.2 H: 50

sub UnitTest_Test_3
{
	my ($own_hash) = @_;
	my $targetHash = $defs{$own_hash->{targetDevice}};

	my $mock = Mock::Sub->new;
 	my $Dispatch = $mock->mock('Dispatch');
	sleep 3;
	my $rmsg="MS;P1=502;P2=-9212;P3=-1939;P4=-3669;D=12131413141414131313131313141313131313131314141414141413131313141413131413;CP=1;SP=2;";
	my %signal_parts=SIGNALduino_Split_Message($rmsg,my $targetHash->{NAME});   ## Split message and save anything in an hash %signal_parts
	
	
	$attr{$targetHash->{NAME}}{debug} = 1;
	SIGNALduino_Parse_MS($targetHash, $targetHash, $targetHash->{NAME}, $rmsg,%signal_parts);
	$attr{$targetHash->{NAME}}{debug} = 0;	
	
	is($Dispatch->called_count, 1, "Called Dispatch from parse MS");
	
	if ($Dispatch->called_count){		
		my @called_args = $Dispatch->called_with;
		is( @called_args[1], "s5C080FC32000", 'Parse_MS dispatched message for Module CUL_TCM_97001' );
	}
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