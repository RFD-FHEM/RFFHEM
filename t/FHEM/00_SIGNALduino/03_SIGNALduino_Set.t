use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is bag check array like unlike};
use Test2::Mock;

our %defs;
our %attr;


my $tvar;

InternalTimer(time()+1, sub {
	my $target = shift;
	my $targetHash = $defs{$target};
	my $mock = Test2::Mock->new(
		track => 1,
		class => 'main'
	);	 	
	my $tracking = $mock->sub_tracking;

    # Todo:  
    #        sendMsg with L or remove this option
    # sendMsg is tested in test_set_sendMsg-definition.txt but can be removed
    # flash is tested in test_firmware_flash_1-definition.txt
    # reset is tested in test_reset_1-definition.txt
    
	my $check = bag {
		# Uses the next index, in this case index 0;
		item 'W0D23#W0B22';
	};
    
    #diag explain $check;
    # Simple commands
    my @mockData = (
    	{	
    		cc1101_available => 1,
			testname=>  "set raw W0D23#W0B22",
			input	=>	"raw W0D23#W0B22",
			check =>  sub { 
			    return bag  {
					# Uses the next index, in this case index 0;
					item 'W0D23#W0B22';
					end(); # Ensure no other indexes exist.
    			};
		    }
		},
    	{	
			testname=>  "set raw Config disable messagereduction",
			input	=>	"raw CDR",
			check =>  sub { 
			    return bag  {
					# Uses the next index, in this case index 0;
					item 'CDR';
					item 'CG';
					end(); # Ensure no other indexes exist.
    			};
		    }
		},
    	{	
			testname=>  "set raw Config enable messagereduction",
			input	=>	"raw CER",
			check =>  sub { 
			    return bag  {
					# Uses the next index, in this case index 0;
					item 'CER';
					item 'CG';
					end(); # Ensure no other indexes exist.
    			};
		    }
		},

    	{	
    		cc1101_available => 1,
			testname=>  "set disableMessagetype MC",
			input	=>	"disableMessagetype MC",
			check =>  sub { 
			    return bag  {
					item 'CDC';
    			};
		    }

		},
    	{	
    		cc1101_available => 1,
			testname=>  "set enableMessagetype MU",
			input	=>	"enableMessagetype MU",
			check =>  sub { 
			    return bag  {
					item 'CEU';
    			};
		    }
		},
		{
			testname	=> "set enableMessagetype MU (inactive device)",
			input		=> "enableMessagetype MU",
			pre_code 	=> sub { $targetHash->{DevState} = 'disconnected' },
			post_code	=> sub { $targetHash->{DevState} = 'initialized' },
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
		    return => "$targetHash->{NAME} is not active, may firmware is not supported, please flash or reset"
		},
		
		{	
    		cc1101_available => 1,
			testname=>  "set freq 868",
			input	=>	"cc1101_freq 868",
			check =>  sub { 
			    return array  {
			    	item match qr/^W0F21$/;
			    	item match qr/^W1062$/;
			    	item match qr/^W1176$/;
			    	item 'WS36';
			    	item 'WS34';
			    	end();
    			};
		    }
		},
		{	
    		cc1101_available => 0,
			testname=>  "set freq 868",
			input	=>	"cc1101_freq 868",
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
		    return => "This command is only available with a cc1101 receiver"
		},
		{	
    		cc1101_available => 1,
			testname=>  "set freq (defaults to 433)",
			input	=>	"cc1101_freq",
			check =>  sub { 
			    return array  {
       		    	item match qr/^W0F10$/;
			    	item match qr/^W10b0$/;
			    	item match qr/^W1171$/;
			    	item 'WS36';
			    	item 'WS34';
			    	end();
    			};
		    },	   
		},
		{	
    		cc1101_available => 0,
			testname=>  "set freq (defaults to 433)",
			input	=>	"cc1101_freq",
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
		    return => "This command is only available with a cc1101 receiver"
		},
		{	
			pre_code => sub { CommandAttr(undef,"$target cc1101_frequency 868") ; },
			post_code => sub { CommandDeleteAttr(undef,"$target cc1101_frequency") ; },

    		cc1101_available => 1,
			testname =>  "set freq (defaults to 868)",
			input	=>	"cc1101_freq",
			check =>  sub { 
			    return array  {
			    	item match qr/^W0F21$/;
			    	item match qr/^W1062$/;
			    	item match qr/^W1176$/;
			    	item 'WS36';
			    	item 'WS34';
			    	end();
    			};
		    },
		},

		{
    		cc1101_available => 1,
			testname=>  "set bWidth 102",
			input	=>	"cc1101_bWidth 102",
			check =>  sub { 
			    return array  {
			    	item 'C10';
			    	end();
    			};
		    }
		    #return => "Register 10 requested"
		},
		{
    		cc1101_available => 0,
			testname=>  "set bWidth 102",
			input	=>	"cc1101_bWidth 102",
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
		    return => "This command is only available with a cc1101 receiver"
		},
		{
    		cc1101_available => 1,
			testname=>  "set rAmpl 24",
			input	=>	"cc1101_rAmpl 24",
			check =>  sub { 
			    return array  {
			    	item match qr/W1D[\dA-Fa-f]{2}/;
			    	item 'WS36';
			    	item 'WS34';
			    	end();
    			};
		    }
		},
		{
    		cc1101_available => 1,
			testname=>  "set sens 8",
			input	=>	"cc1101_sens 8",
			check =>  sub { 
			    return array  {
			    	item match qr/W1F[\dA-Fa-f]{2}/;
			    	item 'WS36';
			    	item 'WS34';
			    	end();
    			};
		    }
		},
		{
    		cc1101_available => 1,
			testname=>  "set patable 5_dBm (cc1101_frequency=433)",
			input	=>	"cc1101_patable 5_dBm",
			pre_code 	=> sub { $attr{$target}{cc1101_frequency} = '433' },
			check =>  sub { 
			    return array  {
			    	item 'x84';
			    	item 'WS36';
			    	item 'WS34';
			    	end();
    			};
		    }
		},
		{
    		cc1101_available => 1,
			testname=>  "set patable 5_dBm (cc1101_frequency=432)",
			input	=>	"cc1101_patable 5_dBm",
			pre_code 	=> sub { $attr{$target}{cc1101_frequency} = '432' },
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
		    return => "$target: Frequency 432 MHz not supported (supported frequency ranges: 433.05-434.79 MHz, 863.00-870.00 MHz)."
		},
		{
    		cc1101_available => 1,
			testname=>  "set patable 5_dBm (cc1101_frequency=868)",
			input	=>	"cc1101_patable 5_dBm",
			pre_code 	=> sub { $attr{$target}{cc1101_frequency} = '868' },
			check =>  sub { 
			    return array  {
			    	item 'x81';
			    	item 'WS36';
			    	item 'WS34';
			    	end();
    			};
		    }
		},
		{
    		cc1101_available => 1,
			testname=>  "set patable 5_dBm (default cc1101_frequency)",
			input	=>	"cc1101_patable 5_dBm",
			pre_code 	=> sub { delete($attr{$target}{cc1101_frequency}) },
			
			check =>  sub { 
			    return array  {
			    	item 'x84';
			    	item 'WS36';
			    	item 'WS34';
			    	end();
    			};
		    }
		},
		{
			testname=>  "set sendMsg ID:0 (P0#0101#R3#C500)",
			input	=>	"sendMsg P0#0101#R3#C500",
			check =>  sub { 
			    return bag  {
			    	item 'SR;R=3;P0=500;P1=-8000;P2=-3500;P3=-1500;D=0103020302;';
    			};
		    }
		},
		{
			testname=>  "set sendMsg ID:17 (P17#0101#R3#C500)",
			input	=>	"sendMsg P17#0101#R3#C500",
			check =>  sub { 
			    return bag  {
			    	item 'SR;R=3;P0=500;P1=-5000;P2=-2500;P3=-500;P4=-20000;D=01030202030302020304;';
    			};
		    }
		},
		{
			testname=>  "set sendMsg ID:29 (P29#0xF7E#R4)",
			input	=>	"sendMsg P29#0xF7E#R4",
			check =>  sub { 
			    return bag  {
			    	item 'SR;R=4;P0=-8225;P1=235;P2=-470;P3=-235;P4=470;D=01212121213421212121212134;';
    			};
		    }
		},
		{
    		cc1101_available => 1,
			testname=>  "set sendMsg ID:43 (P43#0101#R3#C500#F10AB85550A) with fixed frequency",
			input	=>	"sendMsg P43#0101#R3#C500#F10AB85550A",
			check =>  sub { 
			    return bag  {
			    	item 'SC;R=3;SR;P0=-2560;P1=2560;P3=-640;D=10101010101010113;SM;C=895;D=0101;F=10AB85550A;';
    			};
		    }
		},
		{
    		cc1101_available => 0,
			testname=>  "set sendMsg ID:43 (P43#0101#R3#C500#F10AB85550A) with fixed frequency",
			input	=>	"sendMsg P43#0101#R3#C500#F10AB85550A",
			check =>  sub { 
			    return bag  {
			    	item 'SC;R=3;SR;P0=-2560;P1=2560;P3=-640;D=10101010101010113;SM;C=895;D=0101;';
    			};
		    }
		},
		{
    		cc1101_available => 1,
			testname=>  "set sendMsg ID:43 (P43#0101#R3#C500) with default frequency",
			input	=>	"sendMsg P43#0101#R3#C500",
			check =>  sub { 
			    return bag  {
			    	item 'SC;R=3;SR;P0=-2560;P1=2560;P3=-640;D=10101010101010113;SM;C=895;D=0101;F=10AB85550A;';
    			};
		    }
		},
		{
    		cc1101_available => 0,
			testname=>  "set sendMsg ID:43 (P43#0101#R3#C500) with default frequency",
			input	=>	"sendMsg P43#0101#R3#C500",
			check =>  sub { 
			    return bag  {
			    	item 'SC;R=3;SR;P0=-2560;P1=2560;P3=-640;D=10101010101010113;SM;C=895;D=0101;';
    			};
		    }
		},
		{
			testname=>  "set sendMsg ID:72 (P72#0101#R3#C500)",
			input	=>	"sendMsg P72#0101#R3#C500",
			check =>  sub { 
			    return bag  {
			    	item 'SR;R=3;P0=7000;P1=-2200;P2=1000;P3=-600;P4=500;P5=-1100;D=0145234523;';
    			};
		    },
		},
		{
			testname=>  "set sendMsg ID:3 (P3#is11111000000F#R6)",
			input	=>	"sendMsg P3#is11111000000F#R6",
			check =>  sub { 
			    return bag  {
			    	item 'SR;R=6;P0=250;P1=-7750;P2=750;P3=-250;P4=-750;D=01232323232323232323230404040404040404040404040423;';
    			};
		    },
		    todo => sub { return todo("this test isn't finished"); }
		},
		{
    		cc1101_available => 1,
			testname=>  "set cc1101_reg 0D23 2E22",
			input	=>	"cc1101_reg 0D23 2E22",
			check =>  sub { 
			    return array  {
			    	item 'W0F23';
			    	item 'W3022';
			    	item 'WS36';
			    	item 'WS34';
			    	end();
    			};
		    },
		},
		{
    		cc1101_available	=> 1,
			testname	=> "set cc1101_reg 0D23 3F55 (wrong register)",
			input		=> "cc1101_reg 0D23 3F55",
			check 		=> sub { 
			    return array  {
			    	end();
    			};
		    },
		    return => match qr/ERROR: unknown register position/,
		},
		{
    		cc1101_available => 0,
			testname=>  "set cc1101_reg 0D23 0B22",
			input	=>	"cc1101_reg 0D23 0B22",
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
		    return => "This command is only available with a cc1101 receiver",
		},
		{
    		cc1101_available => 1,
			testname=>  "set cc1101_regSet AP23 FF22 (wrong register, nonhex)",
			input	=>	"cc1101_reg AP23 FF22",
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
		    return =>  match qr/ERROR: wrong parameter value AP23/
		},
		{
			testname=>  "set bad command",
    		cc1101_available => 0,
			input	=>	"bla",
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
		    return => match qr/^Unknown argument bla, choose one of/
		},
		{
			testname=>  "set ? command (1.0)",
    		cc1101_available => 0,
			dummy => 0,
			input	=>	"?",
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
		    return => check_set match qr/^Unknown argument \?, choose one of.*/,!match qr/cc1101_[^L]/,!match qr/LaCrossePairForSec/
		},
		{
			cc1101_available 	=> 1,
			dummy 		=> 0,
			DIODev		=> 1,
			testname=>  "set ? command (1.1)",
			input	=>	"?",
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
		    return => check_set match qr/^Unknown argument \?, choose one of.*/,match qr/cc/,!match qr/LaCrossePairForSec/
		},
		{
			cc1101_available 	=> 1,
			testname=>  "set ? command (1.2)",
			input	=>	"?",
			dummy 		=> 0,
			DIODev		=> 1,
			pre_code 	=> sub { readingsSingleUpdate($targetHash,"cc1101_config_ext","Modulation: 2-FSK",0); },
			post_code	=> sub { CommandDeleteReading(undef,"$target cc1101_config_ext") ; },
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
		    return => check_set match qr/^Unknown argument \?, choose one of.*/,match qr/cc/,match qr/LaCrossePairForSec/
		},
		{
			testname	=>  "set ? command for dummy (1.3)",
			dummy 		=> 1,
			cc1101_available => 0,
			input		=>	"?",
			check 		=>  sub { 
			    return array  {
			    	end();
    			};
		    },
		    return => check_set match qr/close/,match qr/reset/,!match qr/cc1101_/,match qr/LaCrossePairForSec/
		},
		{
			testname	=>  "set ? command for dummy (1.4)",
			dummy 		=> 1,
			cc1101_available 	=> 1,
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
			input		=>	"?",
		    return 		=> check_set match qr/close/,match qr/reset/,!match qr/cc_1101/,match qr/LaCrossePairForSec/
		},
		{
			testname	=>  "set ? command for inactive device (1.5)",
			dummy		=> 0,
			cc1101_available 	=> 1,
			DIODev		=> 0,
			pre_code 	=> sub { $targetHash->{DevState} = 'disconnected' },
			post_code	=> sub { $targetHash->{DevState} = 'initialized' },
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
			input		=>	"?",
		    return 		=> check_set match qr/reset/,!match qr/cc/,!match qr/LaCrossePairForSec/
		},
		{
			cc1101_available 	=> 1,
			testname=>  "set ? command (1.6)",
			input	=>	"?",
			dummy 		=> 0,
			DIODev		=> 1,
			pre_code 	=> sub { readingsSingleUpdate($targetHash,"cc1101_config_ext","Modulation: ASK/OOK, Syncmod: No preamble/sync",0); },
			post_code	=> sub { CommandDeleteReading(undef,"$target cc1101_config_ext") ; },
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
		    return => check_set match qr/^Unknown argument \?, choose one of.*/,match qr/cc/,!match qr/LaCrossePairForSec/
		},
		{
			testname	=>  "set reset command for inactive device",
			cc1101_available 	=> 1,
			dummy 		=> 1,
			DIODev		=> 0,
			pre_code 	=> sub { $targetHash->{DevState} = 'disconnected' },
			post_code	=> sub { $targetHash->{DevState} = 'initialized' },
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
			input		=>	"reset",
		},
		{
			testname	=>  "set LaCrossePairForSec abc seconds",
			cc1101_available 	=> 1,
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
			input		=>	"LaCrossePairForSec abc",
			return 		=> match qr/^Usage:/,
		},
		{
			testname	=>  "set LaCrossePairForSec 30 seconds and wrong battery note",
			cc1101_available 	=> 1,
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
			input		=>	"LaCrossePairForSec 30 battery",
			return 		=> match qr/^Usage:/,
		},
		{
			testname	=>  "set LaCrossePairForSec 30 seconds",
			cc1101_available 	=> 1,
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
			input		=>	"LaCrossePairForSec 30",
		},
		{
			testname	=>  "set LaCrossePairForSec 30 seconds for dummy",
			dummy 		=> 1,
			cc1101_available 	=> 1,
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
			input		=>	"LaCrossePairForSec 30",
		},
		{
			testname	=>  "set LaCrossePairForSec 30 seconds for dummy",
			dummy 		=> 1,
			cc1101_available 	=> 0,
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
			input		=>	"LaCrossePairForSec 30",
		},
		{
			testname	=>  'set reset command for device',
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
			input		=>	'reset',
		},
		{
			testname	=>  'set flash without hardware parameter set',
			attr		=>  ( {hardware => undef} ),
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
			input		=>	'flash',
			return		=> 	qr/^Please define your hardware!/
		},
		{
			testname	=>  'set flash without argument passed (nano328)',
			attr		=>  ( {hardware => 'nano328'} ),
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
			input		=>	'flash',
			return		=> 	qr/^ERROR: argument failed! flash/
		},
		{
			testname	=>  'set flash without avrdude installed (nano328)',
			check =>  sub { 
			    return array  {
			    	end();
    			};
		    },
			pre_code => sub {
				$tvar = $ENV{PATH};
				$ENV{PATH}= '';
			},
			post_code => sub {
				$ENV{PATH} = $tvar;
			},			attr		=>  ( {hardware => 'nano328'} ),
			input		=>	'flash ./fhem/test.hex',
			return		=> 	'avrdude is not installed. Please provide avrdude tool example: sudo apt-get install avrdude'
		},


		
	);

	plan (scalar @mockData + 4);	
	my $todo=undef;
	
	foreach my $element (@mockData)
	{
		next if (!exists($element->{testname}));
		
		# Mock cc1101	
		$targetHash->{cc1101_available} = exists($element->{cc1101_available}) ? $element->{cc1101_available} : 0;

		# Mock dummy	
		CommandAttr(undef,"$target dummy $element->{dummy}") if (exists($element->{dummy}));	

		# Mock for DevIo_IsOpen
		$targetHash->{DIODev} = exists($element->{DIODev}) ? $element->{DIODev} : undef;

		#Mock attr
		while (my ($key,$value) = each %{$element->{attr}} ) {
			defined $value 
				?	CommandAttr(undef,qq[$target $key $value])
				:	CommandAttr(undef,qq[-r $target $key])
		}
		$element->{pre_code}->($target) if (exists($element->{pre_code}));
		$todo=$element->{todo}->() if (exists($element->{todo}));
		
		subtest "checking $element->{testname};". ($targetHash->{cc1101_available} ? " with cc1101" : " without cc1101"). " " . ($targetHash->{DIODev} ? " devIo open" : " devIo closed") => sub {
			plan (2);	
			
			my $ret = SIGNALduino_Set($targetHash,$target,split(" ",$element->{input}));
			like($ret,$element->{return},"Verify return value");
			is($targetHash->{QUEUE},$element->{check}->(),"Verify expected queue element entrys");

			@{$targetHash->{QUEUE}}=();
			
		};
		undef ($todo);
		$element->{post_code}->() if (exists($element->{post_code}));
	
	};
	
	subtest "checking set close " => sub {
			plan (3);	
			$mock->override('DevIo_CloseDev' => sub { pass('DevIo_CloseDev is called') } );
			$mock->override('RemoveInternalTimer' => sub { pass('RemoveInternalTimer is called') } );

			
			SIGNALduino_Set($targetHash,$target,"close");
			is(ReadingsVal($target,"state",""),"closed","check reading state");
			
			#ok($DevIo_CloseDev->called, "DevIo_CloseDev is called");
			#ok($RemoveInternalTimer->called, "RemoveInternalTimer is called");
			
			$mock->restore('DevIo_CloseDev');
			$mock->restore('RemoveInternalTimer');
	};
	
	subtest 'Test SIGNALduino without dummy attrib or value 0 / devio open' => sub {
		plan(1);
		subtest 'Test without hardware attribute' => sub {
			plan(2);
			subtest 'Test Attributes (hardware undef)' => sub {
				plan(4);
				$attr{$target}{dummy} = 0;
				is(AttrVal($target, "dummy", 0),0,"check attrib dummy is 0");
				$targetHash->{DIODev} = 1;
				CommandDeleteAttr($targetHash,"$target hardware") if (AttrVal($target, "hardware", undef));
				delete($targetHash->{cc1101_available}) if ($targetHash->{cc1101_available});
				is(AttrVal($target, "hardware", undef),undef,"check attrib hardware undef");
				ok(DevIo_IsOpen($targetHash),"check DevIo_IsOpen returns true");
				unlike(ReadingsVal($target,"cc1101_config_ext","0"),qr/2-FSK/,"check reading cc1101_config_ext");
			};
		
			subtest 'Test allowed - set commands' => sub {
				my $ret=SIGNALduino_Set($targetHash, $target, "?");
				my @tests = split(" ", substr($ret,index($ret,"one of")+7));
				my $tests = scalar(@tests);
				plan($tests);

				like($ret,qr/^Unknown argument \?, choose one .*close.*/,"check cmd close accepted");
				like($ret,qr/^Unknown argument \?, choose one .*disableMessagetype.*/,"check cmd disableMessagetype accepted");
				like($ret,qr/^Unknown argument \?, choose one .*enableMessagetype.*/,"check cmd enableMessagetype accepted");
				like($ret,qr/^Unknown argument \?, choose one .*flash.*/,"check cmd flash accepted");
				like($ret,qr/^Unknown argument \?, choose one .*raw.*/,"check cmd raw accepted");
				like($ret,qr/^Unknown argument \?, choose one .*reset.*/,"check cmd reset accepted");
				like($ret,qr/^Unknown argument \?, choose one .*sendMsg.*/,"check cmd sendMsg accepted");
			};

		};
	};


	subtest 'Test SIGNALduino with dummy attrib 1 / devio open' => sub {
		plan(3);
		subtest 'Test Attributes' => sub {
			plan(2);
			$attr{$target}{dummy} = "1";
			is(AttrVal($target, "dummy", 0),1,"check attrib dummy is 1");
			$targetHash->{DIODev} = 1;
			ok(DevIo_IsOpen($targetHash),"check DevIo_IsOpen returns true");
		};
			
		my $ret=SIGNALduino_Set($targetHash, $target, "?");
		subtest 'Test allowed - set commands' => sub {
			plan(2);

			like($ret,qr/^Unknown argument \?, choose one .*close.*/,"check cmd close accepted");
			like($ret,qr/^Unknown argument \?, choose one .*reset.*/,"check cmd reset accepted");
		};
		
		subtest 'Test "not allowed" - set commands' => sub {
			plan(6);

			unlike($ret,qr/.*cc1101_[^L].*/,"check cmd cc1101_.* execpt LaCrossePairForSec not allowed");
			unlike($ret,qr/.*disableMessagetype.*/,"check cmd disableMessagetype not allowed");
			unlike($ret,qr/.*enableMessagetype.*/,"check cmd enableMessagetype not allowed");
			unlike($ret,qr/.*flash.*/,"check cmd flash not allowed");
			unlike($ret,qr/.*raw.*/,"check cmd raw not allowed");
			unlike($ret,qr/.*sendMsg.*/,"check cmd sendMsg not allowed");
		};
	};
	
	subtest 'Test bWidth (325 Khz)' => sub {
		plan(3);
		
		subtest 'Test cc1101::CalcbWidthReg' => sub {
			plan(2);
			my ($ob,$bw) = cc1101::CalcbWidthReg($targetHash,57,325);
			is($ob,57,"check new register value");
			is($bw,325,"check calculated possible bWith value, will never be higher as provided");
		};
		@{$targetHash->{QUEUE}}=();
	
		subtest 'Test SIGNALduino_Set_bWidth (requesting value register 10)' => sub {
			plan(2);
			my $ret = SIGNALduino_Set_bWidth($targetHash,,"cc1101_bWidth","325");
			#is($ret,"Register 10 requested","Verify return message / request register 10");
			is($targetHash->{ucCmd}->{cmd},"set_bWidth","check getcmd command");
			is($targetHash->{ucCmd}->{arg},"325","check getcmd arg");
		};

		# Todo: ggf mock DevIo_SimpleRead to return "C10 = 57"
		# 		call SIGNALduino_Read($targetHash);		
				
		subtest 'Test SIGNALduino_Set_bWidth (Update registervalue)' => sub {
			plan(2);
			my ($ret,undef) = SIGNALduino_Set_bWidth($targetHash,"C10 = 57");
			
				
			is($ret,"Setting MDMCFG4 (10) to 57 = 325 KHz","Verify return message");
	
			is($targetHash->{QUEUE},
				array  {
				    	item 'C10';
				    	item 'W1257';
				    	item 'WS36';
				    	item 'WS34';
					    end();
					} ,"Verify expected queue element entrys");
		
			@{$targetHash->{QUEUE}}=();
		};
	};

	exit(0);
},'dummyDuino');

1;