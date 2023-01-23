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
        targetName      => 	q[SD_UT_Test_Buttons_six],				# Name of the definition which is tested
		testname        =>  q[set command fan_off],         # Name of our setcommand
        cmd   	        =>	q[set fan_off],      			# Command to execute for test
        # Check for arguments given to mocked sub
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P29#111110111110#R5' }; etc() } } } ,  
        returnCheck     => F(),    # Check for false return from command

        #todo => 1, # Enable Todo block
    },
    {	
        targetName      => 	q[SD_UT_Test_Buttons_six],
		testname        =>  q[set command 1_fan_low_speed],
        cmd	            =>	q[set 1_fan_low_speed],
        prep_commands   => [                               # Any FHEM custom command can be placed in here, which will be called before the test is run
			'attr $targetName repeats 4', 
        ],
        
        returnCheck     => F(),    
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P29#011111111110#R4' }; etc() } } } ,
    },
    {
        targetName      => 	q[SD_UT_Test_RCnoName20_10],
        testname        =>  q[set ? ],
        cmd             =>	q[set ?],

        returnCheck     => check_set( !match qr/hex_length/, match qr/time_1h:noArg/, match qr/time_2h:noArg/, match qr/time_4h:noArg/, match qr/light_on:noArg/, match qr/light_off:noArg/, match qr/fan_low:noArg/, match qr/fan_mid:noArg/, match qr/fan_high:noArg/, match qr/fan_stop:noArg/, match qr/fan_natural:noArg/ ),
        subCheck        => hash { end(); } ,
    },	
    {	
        targetName      => 	q[SD_UT_Test_RCnoName20_10],
		testname        =>  q[set command light_on],
        cmd	            =>	q[set light_on],
        
        returnCheck     => F(),    
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P20#00111110000000000001111000011001#R5' }; etc() } } } ,
    },
    {
        targetName      => 	q[SD_UT_Test_RCnoName20_10],
        testname        =>  q[set command fan_high with rollingcode overflow],
        cmd             =>	q[set fan_high],

        returnCheck    => F(),    
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P20#00111110000000000001010000000010#R5' }; etc() } } } ,
        prep_commands   => [                               # Any FHEM custom command can be placed in here, which will be called before the test is run
                    'setreading $targetName rollingCode 15', 
        ],
        hashCheck       => hash { field READINGS => hash {field rollingCode => hash { field VAL => 0; etc(); }; etc(); }; etc(); },
    },
    {
        targetName      => 	q[SD_UT_Test_RCnoName20_10],
        testname        =>  q[set unsupported command: Protocol ],
        cmd             =>	q[set Protocol],

        returnCheck     => q[SD_UT_Test_RCnoName20_10 Unkown set command!],
        subCheck        => hash { end(); } ,
    },	
    {
        targetName      => 	q[SD_UT_Test_OR28V_1],
        testname        =>  q[set command volume_minus],
        cmd             =>	q[set volume_minus],

        returnCheck    => F(),    
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P68#01011101100010000000#R5' }; etc() } } } ,
    },	
    {
        targetName      => 	q[SD_UT_Test_TC6861_3DC_1],
        testname        =>  q[set command on],
        cmd             =>	q[set on],

        returnCheck    => F(),    
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P121#P001100111101110001111110#R5' }; etc() } } } ,
    },	
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