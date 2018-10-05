##############################################
# 98_unittest.pm 
#
# The file is part of the development SIGNALduino project
# https://github.com/RFD-FHEM/RFFHEM/blob/dev-r33/test/install.md
#												 

package main;
use strict;
use warnings;
# Laden evtl. abhängiger Perl- bzw. FHEM-Module
use Mock::Sub (no_warnings => 1);
use Test::More;
use Data::Dumper qw(Dumper);


# FHEM Modulfunktionen

sub UnitTest_Initialize() {
	my ($hash) = @_;
	$hash->{DefFn}         = "UnitTest_Define";
	$hash->{UndefFn}       = "UnitTest_Undef";
	$hash->{NotifyFn}      = "UnitTest_Notify";
	
}

sub UnitTest_Define() {
	my ( $hash, $def ) = @_;
   
    my ($name,$type,$target,$cmd) = split('[ \t]+', $def,4);

	#if (!$cmd || (not $cmd =~ m/^[(].*[)]$/g)) {
	if (!$cmd || $cmd !~ m/(\n.*)[(](.*|.*\n.*){1,}[)][;]$/g) {
        my $msg = "wrong syntax: define <name> UnitTest <name of target device> (Test Code in Perl)";
    	Log3 undef, 2, $msg;
    	return $msg;
    }
	Log3 $name, 2, "Defined unittest for target: ".$hash->{targetDevice} if ($hash->{targetDevice});
    Log3 $name, 5, "DEV is $cmd";
    
    ($hash->{'.testcode'}) = $cmd =~ /(\{[^}{]*(?:(?R)[^}{]*)*+\})/;
    Log3 $name, 5, "Loaded this code ".$hash->{'.testcode'} if ($hash->{'.testcode'});
    
    $hash->{name}  = $name;
    $hash->{targetDevice}  = $target;
    
	readingsSingleUpdate($hash, "state", "waiting", 1);
		
	## Test starten wenn Fhem bereits initialisiert wurde	
	if  ($init_done) {
	   	InternalTimer(gettimeofday()+1, 'UnitTest_Test_generic',$hash,0);       
	}   	
    $hash->{test_output}="";
    $hash->{test_failure}="";
    $hash->{todo_output}="";

    ### Attributes ###
    if ( $init_done == 1 ) {
		$attr{$name}{room}	= "UnitTest";
    }

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
    	#UnitTest_Test_1($own_hash);
    	#UnitTest_Test_2($own_hash);
    	
    	
    	InternalTimer(gettimeofday()+4, 'UnitTest_Test_generic',$own_hash,0);       # verzoegern bis alle Attribute eingelesen sind, da das SIGNALduino Modul keinen Event erzeugt, wenn dies erfolgt ist
    	
    }
    # Examples:
    # $event = "readingname: value" 
    # or
    # $event = "INITIALIZED" (for $devName equal "global")
    #
    # processing $event with further code
  }
}


sub UnitTest_Test_generic
{
	
	# Define some generic vars for our Test
	my $hash = shift;
	my $name = $hash->{NAME};
	my $target = $hash->{targetDevice};
	my $targetHash = $defs{$target};
	Log3 $name, 3, "---- Test $name starts here ---->";
	
	# Redirect Test Output to internals
	Test::More->builder->output(\$hash->{test_output});
	Test::More->builder->failure_output(\$hash->{test_failure});
	Test::More->builder->todo_output(\$hash->{todo_output});
	
	# Disable warnings for prototype mismatch
	$SIG{__WARN__} = sub {CORE::say $_[0] if $_[0] !~ /Prototype/};
	
	Log3 $name, 5, "Running now this code ".$hash->{'.testcode'} if ($hash->{'.testcode'});
	
	readingsSingleUpdate($hash, "state", "running", 1);
	my $ret ="";
	$ret =eval $hash->{'.testcode'} if ($hash->{'.testcode'});
	if ($@) {
		Log3 $name, 5, "return from eval was ".$ret." with error $@" if $ret;
	}

	# enable warnings for prototype mismatch
	$SIG{__WARN__} = sub {CORE::say $_[0]};
	
	#$hash->{test_output} =~ tr{\n]{ };
	#$hash->{test_output} =~ s{\n}{\\n}g;
    
    my @test_output_list = split "\n",$hash->{test_output};	
    foreach my $logine(@test_output_list) {
    		Log3 $name, 3, $logine;
    	
    }
    my @test_failure_list = split "\n",$hash->{test_failure};	
    foreach my $logine(@test_failure_list) {
    		Log3 $name, 3, $logine;
    }
    my @test_todo_list = split "\n",$hash->{test_todo} if $hash->{test_todo};
    foreach my $logine(@test_todo_list) {
    		Log3 $name, 3, $logine;
    }
	
	Log3 $name, 3, "<---- Test $name ends here ----";
	
	readingsBeginUpdate($hash);
	readingsBulkUpdate($hash, "state", "finished", 1);
	readingsBulkUpdate($hash, "test_output", "$hash->{test_output}" , 1);
	readingsBulkUpdate($hash, "test_failure", $hash->{test_failure} , 1);
	readingsBulkUpdate($hash, "todo_output", $hash->{todo_output} , 1);
	readingsEndUpdate($hash,1);


}

#
# Demo code yust demonstrating how test code is written
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
	
	my $Dispatch;
   	my $mock;
   	$mock = Mock::Sub->new; 
    $Dispatch = $mock->mock('Dispatch');
    
        		
    my $rmsg="MS;P1=502;P2=-9212;P3=-1939;P4=-3669;D=12131413141414131313131313141313131313131314141414141413131313141413131413;CP=1;SP=2;";
	my %signal_parts=SIGNALduino_Split_Message($rmsg,$targetHash->{NAME});   ## Split message and save anything in an hash %signal_parts
    SIGNALduino_Parse_MS($targetHash, $targetHash, $targetHash->{NAME}, $rmsg,%signal_parts);
    is($Dispatch->called_count, 1, "Called Dispatch from parse MS");
	
	if ($Dispatch->called_count){		
		my @called_args = $Dispatch->called_with;
		is( $called_args[1], "s5C080FC32000", 'Parse_MS dispatched message for Module CUL_TCM_97001' );
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
 <a name="UnitTest"></a>
 <h3>UnitTest</h3><br>
  
  The Module runs perl code (unit tests) which is specified in the definition. The code which is in braces will be evaluated.<br><br>
  <small><u><b>Necessary components PERL:</u></b></small> <ul>Mock::Sub Test::More & Test::More Test::Device::SerialPort <br>(install via <code>cpan Mock::Sub Test::More Test::Device::SerialPort</code> on system)</ul><br>
  <a name="UnitTestdefine"></a>
  <b>Define</b><br>
 
  <ul><code>define &lt;NameOfThisDefinition&gt; UnitTest &lt;Which device is under test&gt; ( { PERL CODE GOES HERE }  )</code></ul>
  
  <ul><u>example:</u><br>
  <code>define test1 UnitTest dummyDuino ( { Log3 undef, 2, "this is a Log Message inside our Test";; } )
  </code></ul><br>
  <a name="UnitTestinternals"></a>
  <b>Internals</b>
  <ul>
   <li> state - finished / waiting, Status of the current unittest (waiting, the test is running)
   <li> test_failure - Failures from our unittest will go in here
   <li> test_output - ok / nok Messages will be visible here
   <li> todo_output - diagnostics output of a todo test
  </ul><br><br>
  <a name="code_example"></a>
  <b>code example:</b><br>
  <ul>
  dummyDuino<br>
  &nbsp;&nbsp;(<br>
  &nbsp;&nbsp;&nbsp;&nbsp;{<br>
    
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;my $mock = Mock::Sub->new;<br>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;my $Log3= $mock->mock("SIGNALduino_Log3");<br>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;SIGNALduino_IdList("x:$target","","","");<br>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;my $ref_called_count = $Log3->called_count;<br><br>
    
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;my $id = 9999;<br>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$main::ProtocolListSIGNALduino{$id} =
        {
            name			=> 'test protocol',		
			comment			=> 'none' ,
			id          	=> '9999',
			developId		=> 'm',
	 },<br>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;SIGNALduino_IdList("x:$target","","","m9999");<br>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;is($Log3->called_count-$ref_called_count,$ref_called_count+1,"SIGNALduino_Log3 output increased");<br>
  &nbsp;&nbsp;&nbsp;&nbsp;}<br>
  &nbsp;&nbsp;);
  </ul><br>
  <a href="https://github.com/RFD-FHEM/RFFHEM/blob/dev-r33/test/install.md">Other instructions can be found here.</a>
=end html

=begin html_DE
 <a name="UnitTest"></a>
 <h3>UnitTest</h3><br>
  
  Das Modul f&uuml;hrt einen Perl-Code (unit tests) aus, der in der Definition festgelegt wird. Der Code in geschweiften Klammern wird ausgewertet.<br>
    <small><u><b>Ben&ouml;tigte Bestandteile PERL:</u></b></small> <ul>Mock::Sub Test::More & Test::More Test::Device::SerialPort <br>(install via <code>cpan Mock::Sub Test::More Test::Device::SerialPort</code> auf dem System)</ul><br>
  <a name="UnitTestdefine"></a>
  <b>Define</b><br>
 
  <ul><code>define &lt;NameDerDefinition&gt; UnitTest &lt;Which device is under test&gt; ( { PERL CODE GOES HERE }  )</code></ul>
  
  <ul><u>Beispiel:</u><br>
  <code>define test1 UnitTest dummyDuino ( { Log3 undef, 2, "this is a Log Message inside our Test";; } )
  </code></ul><br>
  <a name="UnitTestinternals"></a>
  <b>Internals</b>
  <ul>
   <li> state - finished / waiting, Status des aktuellen Unittest (waiting, der Test l&auml;ft aktuell)
   <li> test_failure - Fehler aus unserem Unittest werden hier ausgegeben
   <li> test_output - ok / nok, Nachrichten werden hier sichtbar sein
   <li> todo_output - Diagnoseausgabe eines Todo-Tests
  </ul><br><br>
  <a name="Code_Beispiel"></a>
  <b>Code Beispiel:</b><br>
  <ul>
  dummyDuino<br>
  &nbsp;&nbsp;(<br>
  &nbsp;&nbsp;&nbsp;&nbsp;{<br>
    
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;my $mock = Mock::Sub->new;<br>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;my $Log3= $mock->mock("SIGNALduino_Log3");<br>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;SIGNALduino_IdList("x:$target","","","");<br>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;my $ref_called_count = $Log3->called_count;<br><br>
    
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;my $id = 9999;<br>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$main::ProtocolListSIGNALduino{$id} =
        {
            name			=> 'test protocol',		
			comment			=> 'none' ,
			id          	=> '9999',
			developId		=> 'm',
	 },<br>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;SIGNALduino_IdList("x:$target","","","m9999");<br>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;is($Log3->called_count-$ref_called_count,$ref_called_count+1,"SIGNALduino_Log3 output increased");<br>
  &nbsp;&nbsp;&nbsp;&nbsp;}<br>
  &nbsp;&nbsp;);
  </ul><br>
  <a href="https://github.com/RFD-FHEM/RFFHEM/blob/dev-r33/test/install.md">Eine weitere Anleitung finden Sie hier.</a>
=end html_DE

# Ende der Commandref
=cut