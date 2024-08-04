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
        targetName      =>  q[SD_UT_Test_Buttons_six],    # Name of the definition which is tested
        testname        =>  q[set command fan_off],       # Name of our setcommand
        cmd             =>  q[set fan_off],               # Command to execute for test
        # Check for arguments given to mocked sub
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P29#111110111110#R5' }; etc() } } } ,  
        returnCheck     => F(),    # Check for false return from command

        #todo => 1, # Enable Todo block
    },
    {
        targetName      =>  q[SD_UT_Test_Buttons_six],
        testname        =>  q[set command 1_fan_low_speed],
        cmd             =>  q[set 1_fan_low_speed],
        prep_commands   => [                               # Any FHEM custom command can be placed in here, which will be called before the test is run
      'attr $targetName repeats 4', 
        ],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P29#011111111110#R4' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_RCnoName20_10],
        testname        =>  q[set ? ],
        cmd             =>  q[set ?],

        returnCheck     => check_set( !match qr/hex_length/, match qr/time_1h:noArg/, match qr/time_2h:noArg/, match qr/time_4h:noArg/, match qr/light_on:noArg/, match qr/light_off:noArg/, match qr/fan_low:noArg/, match qr/fan_mid:noArg/, match qr/fan_high:noArg/, match qr/fan_stop:noArg/, match qr/fan_natural:noArg/ ),
        subCheck        => hash { end(); } ,
    },
    {
        targetName      =>  q[SD_UT_Test_RCnoName20_10],
        testname        =>  q[set command light_on],
        cmd             =>  q[set light_on],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P20#00111110000000000001111000011001#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_RCnoName20_10],
        testname        =>  q[set command fan_high with rollingcode overflow],
        cmd             =>  q[set fan_high],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P20#00111110000000000001010000000010#R5' }; etc() } } } ,
        prep_commands   => [                               # Any FHEM custom command can be placed in here, which will be called before the test is run
                    'setreading $targetName rollingCode 15', 
        ],
        hashCheck       => hash { field READINGS => hash {field rollingCode => hash { field VAL => 0; etc(); }; etc(); }; etc(); },
    },
    {
        targetName      =>  q[SD_UT_Test_RCnoName20_10],
        testname        =>  q[set unsupported command: Protocol ],
        cmd             =>  q[set Protocol],

        returnCheck     => q[SD_UT_Test_RCnoName20_10 Unkown set command!],
        subCheck        => hash { end(); } ,
    },
    {
        targetName      =>  q[SD_UT_Test_CREATE_6601L_1B90],
        testname        =>  q[set ? ],
        cmd             =>  q[set ?],

        returnCheck     => check_set( !match qr/hex_length/, match qr/fan_4:noArg/, match qr/time_4h:noArg/, match qr/light_color:noArg/, match qr/fan_1:noArg/, match qr/time_1h:noArg/, match qr/light_on_off:noArg/, match qr/time_2h:noArg/, match qr/fan_on_off:noArg/, match qr/fan_6:noArg/, match qr/fan_2:noArg/, match qr/fan_direction:noArg/, match qr/fan_3:noArg/, match qr/fan_5:noArg/, match qr/beeper_on_off:noArg/ ),
        subCheck        => hash { end(); } ,
        prep_commands   => [                               # Any FHEM custom command can be placed in here, which will be called before the test is run
                    'attr $targetName model CREATE_6601L',
        ],
    },
    {
        targetName      =>  q[SD_UT_Test_CREATE_6601L_1B90],
        testname        =>  q[set command beeper_on_off rollingCode 0-7],
        cmd             =>  q[set beeper_on_off],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P20#00011011100100000000010001001001#R5' }; etc() } } } ,
        prep_commands   => [                               # Any FHEM custom command can be placed in here, which will be called before the test is run
                    'setreading $targetName rollingCode 3', 
                    'attr $targetName model CREATE_6601L',
        ],
        hashCheck       => hash { field READINGS => hash {field rollingCode => hash { field VAL => 4; etc(); }; etc(); }; etc(); },
    },
    {
        targetName      =>  q[SD_UT_Test_CREATE_6601L_1B90],
        testname        =>  q[set command fan_5 rollingCode 8-15],
        cmd             =>  q[set fan_5],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P20#00011011100100000000010011010000#R5' }; etc() } } } ,
        prep_commands   => [                               # Any FHEM custom command can be placed in here, which will be called before the test is run
                    'setreading $targetName rollingCode 4', 
                    'attr $targetName model CREATE_6601L',
        ],
        hashCheck       => hash { field READINGS => hash {field rollingCode => hash { field VAL => 13; etc(); }; etc(); }; etc(); },
    },
    {
        targetName      =>  q[SD_UT_Test_OR28V_1],
        testname        =>  q[set command volume_minus],
        cmd             =>  q[set volume_minus],

        returnCheck    => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P68#01011101100010000000#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_OR28V_2],
        testname        =>  q[set command volume_minus],
        cmd             =>  q[set volume_minus],
        prep_commands   => [                               # Any FHEM custom command can be placed in here, which will be called before the test is run
                    'setreading $targetName state volume_minus', 
        ],
        returnCheck    => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P68#01101101100010000001#R5' }; etc() } } } ,
    },    
    {
        targetName      =>  q[SD_UT_Test_Chilitec_22640_AA80],
        testname        =>  q[set command power_on],
        cmd             =>  q[set power_on],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P14#10101010100000001000#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_DC_1961_TG_1846],
        testname        =>  q[set command light_on_off],
        cmd             =>  q[set light_on_off],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P20#00011000010001101010100000010010#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_Visivo_7DF825],
        testname        =>  q[set command up],
        cmd             =>  q[set up],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P24#10011111011111011111100000100101000000101001110000010000#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_xavax_DAAB],
        testname        =>  q[set command Ch1_on],
        cmd             =>  q[set Ch1_on],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P26#11011010101010110010010101010100100001110P#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_Buttons_five_E],
        testname        =>  q[set command fan_off],
        cmd             =>  q[set fan_off],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P29#111110111110#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_QUIGG_DMV_891],
        testname        =>  q[set command Ch1_on],
        cmd             =>  q[set Ch1_on],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P34#10001001000111101110P#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_TR_502MSV_FFF],
        testname        =>  q[set command Ch1_on],
        cmd             =>  q[set Ch1_on],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P34#11111111111111101110P#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_Tedsen_SKX1xx_F1FF11F],
        testname        =>  q[set command Button_1],
        cmd             =>  q[set Button_1],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P46#101110101111101100#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_Tedsen_SKX2xx_1F10110],
        testname        =>  q[set command Button_1],
        cmd             =>  q[set Button_1],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P46#111011001111001000#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_Tedsen_SKX6xx_1F10FF0],
        testname        =>  q[set command Button_6],
        cmd             =>  q[set Button_6],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P46#111011001010001011#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_AC114_01B_00587B],
        testname        =>  q[set command down],
        cmd             =>  q[set down],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P56#10100011000000000101100001111011000000010000000001000011000101111P#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_HS1_868_BS_F62A9C01C],
        testname        =>  q[set command send],
        cmd             =>  q[set send],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P69#00000000111101100010101010011100000000011100#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_HSM4_E6BE910],
        testname        =>  q[set command button_1],
        cmd             =>  q[set button_1],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P69#00000000111001101011111010010001000001111100#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_LED_XM21_0_FFFFFFFFFFFFFF],
        testname        =>  q[set command on],
        cmd             =>  q[set on],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P76#1111111111111111111111111111111111111111111111111111111111111111#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_BeSmart_S4_534],
        testname        =>  q[set command light_toggle],
        cmd             =>  q[set light_toggle],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P78#01010011010010010000#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_SA_434_1_mini_604],
        testname        =>  q[set command send],
        cmd             =>  q[set send],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P81#011000000100#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_RH787T_0],
        testname        =>  q[set command 1_fan_minimum_speed],
        cmd             =>  q[set 1_fan_minimum_speed],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P83#000001110111#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_CAME_TOP_432EV_EE],
        testname        =>  q[set command right_button],
        cmd             =>  q[set right_button],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P86#111011101101#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_Novy_840029_55],
        testname        =>  q[set command speed_plus],
        cmd             =>  q[set speed_plus],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P86#010101010101#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_Novy_840039_55],
        testname        =>  q[set command ambient_light_on],
        cmd             =>  q[set ambient_light_on],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P86#010101010110111110#R5#C375' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_SF01_01319004_A150],
        testname        =>  q[set command plus],
        cmd             =>  q[set plus],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P86#101000010101001100#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_SF01_01319004_Typ2_2638],
        testname        =>  q[set command delay],
        cmd             =>  q[set delay],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P86#001001100011100001#R5' }; etc() } } } ,
    },
    ### RC_10 | Special feature, Reading x_n5-8_on and x_n5-8_off must be present before sending can occur ###
    {
        targetName      =>  q[SD_UT_Test_RC_10_7869_A],
        testname        =>  q[set command on with all readings],
        cmd             =>  q[set on],

        prep_commands   => [                               # Any FHEM custom command can be placed in here, which will be called before the test is run
                    'setreading $targetName x_n4 0000',
                    'setreading $targetName x_n5-8_on 1111001001010',
                    'setreading $targetName x_n5-8_off 1110001001000',
        ],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P90#0111100001101001000011110010010101#R5' }; etc() } } } ,
    },
    ### RC_10 | Special feature, Reading x_n5-8_on and x_n5-8_off must be present before sending can occur ###
    {
        targetName      =>  q[SD_UT_Test_RC_10_7869_all],
        testname        =>  q[set command on without reading x_n5-8_off],
        cmd             =>  q[set on],

        returnCheck     => q[ERROR! SD_UT_Test_RC_10_7869_all: To send, please push button on and off again on remote.],
        subCheck        => hash { end(); } ,
    },
    {
        targetName      =>  q[SD_UT_Test_Krinner_LUMIX_A06C360],
        testname        =>  q[set command on],
        cmd             =>  q[set on],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P92#10100000011011000011011000000001#R5' }; etc() } } } ,
    },
    ### UTfrequency example ###
    {
        targetName      =>  q[SD_UT_Test_Krinner_LUMIX_A06C360_UTfrequency],
        testname        =>  q[set command on with attr UTfrequency],
        cmd             =>  q[set on],

        prep_commands   => [                               # Any FHEM custom command can be placed in here, which will be called before the test is run
                    'attr $targetName UTfrequency 868',
        ],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P92#10100000011011000011011000000001#R5#F216276' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_KL_RF01_16F6],
        testname        =>  q[set command light_color_cold_white],
        cmd             =>  q[set light_color_cold_white],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P93#000101101111011000010000111011110#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_Techmar_7709F5DE],
        testname        =>  q[set command Group_5_on],
        cmd             =>  q[set Group_5_on],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P95#01110111000010011111010111011110000100011110111000#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_Momento_0000064],
        testname        =>  q[set command play/pause],
        cmd             =>  q[set play/pause],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P97#0000000000000000000001100100001001001000#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_Navaris_211073],
        testname        =>  q[set command send],
        cmd             =>  q[set send],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P99#001000010001000001110011#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_TR60C1_0],
        testname        =>  q[set command light_off_fan_off],
        cmd             =>  q[set light_off_fan_off],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P104#0000111110000000#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_TR60C1_0_2],
        testname        =>  q[set command length < 10],
        cmd             =>  q[set fan_4],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P104#0000011110000000#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_BF_301_FAD0],
        testname        =>  q[set command down],
        cmd             =>  q[set down],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P105#1111101011010000100010001000001110100011#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_TR401_0_2],
        testname        =>  q[set command off],
        cmd             =>  q[set off],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P114#101100011111#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_Meikee_24_20D3],
        testname        =>  q[set command on],
        cmd             =>  q[set on],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P118#001000001101001100000010#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_TC6861_3DC_1],
        testname        =>  q[set command on],
        cmd             =>  q[set on],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P121#P001100111101110001111110#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_RCnoName127_3603A],
        testname        =>  q[set command fan_1],
        cmd             =>  q[set fan_1],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P127#001101100000001110100000101111#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_RCnoName128_8A7F],
        testname        =>  q[set button_left],
        cmd             =>  q[set button_left],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P128#100010100111111111111110#R5' }; etc() } } } ,
    },
    {
        targetName      =>  q[SD_UT_Test_HA_HX2_85EF],
        testname        =>  q[set command on],
        cmd             =>  q[set on],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P132#100001011110111110101010#R5' }; etc() } } } ,
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