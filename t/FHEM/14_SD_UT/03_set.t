#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use File::Basename;

# Testtool which supports DMSG Tests from SIGNALDuino_tool
use Test2::SIGNALduino::FHEM_Command;
use Test2::Tools::Compare qw{is U validator array hash};
use Test2::Mock;

our %defs;
our $init_done;
our $mock;

my $module = basename (dirname(__FILE__));

# This is the testdata, which will speify what to test and what to check
@mockData = (
    {
        # Default mocking for every testrun in our loop
        defaults    => {
            mocking =>  sub { $mock->override ( IOWrite => sub { return @_ } );  } 
        },
    },
    {	
        targetName 		=> 	q[SD_UT_Test_6],
		testname        =>  q[set command fan_off],                 # Name of our setcommand
        cmd   	        =>	q[set fan_off],      # Command to execute for test
        prep_hash       => {                                # All Items listed here will be added to the devicehash bevore the test starts
            cc1101_available  =>  1,
            DIODev   =>  'open',
        },
        prep_commands   => [                                # Any FHEM custom command can be placed in here
			'set $targetName ?', 
        ],

        # Check for arguments given to mocked sub
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P29#111110111110#R5' }; etc() } } } ,  
        returnCheck     => F(),    # Check for false return from command

        #todo => 1, # Enable Todo block
    },
    {	
        targetName 		=> 	q[SD_UT_Test_6],
		testname        =>  q[set command 1_fan_low_speed],
        cmd	            =>	q[set 1_fan_low_speed],
        
        returnCheck     => F(),    
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P29#011111111110#R5' }; etc() } } } ,
    },
    {	
        targetName 		=> 	q[SD_UT_Test_1],
		testname        =>  q[set command light_on],
        cmd	            =>	q[set light_on],
        
        returnCheck     => F(),    
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P20#00111110000000000001111000011001#R5' }; etc() } } } ,
    }

	
);
        
sub runTest {
    Test2::SIGNALduino::FHEM_Command::commandCheck($module);

    done_testing();
	exit(0);
}

sub waitDone {

	if ($init_done) 
	{
		runTest(@_);
	} else {
		InternalTimer(time()+0.2, &waitDone,@_);			
	}

}

waitDone();

1;