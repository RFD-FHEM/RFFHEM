use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{ is unlike like U check item array DNE};
use Test2::Mock;

our %defs;
our %attr;

my @mockData;
BEGIN {
    @mockData = (
	    {
			testname	=> "get version",
			cc1101_available	=> 0,
			input		=> "version",
			check =>  array  {
			    	item("V");
			    	end();
    			}
	    },
	    {
			testname	=> "get freeram",
			cc1101_available	=> 0,
			input		=> "freeram",
			check =>  array  {
			    	item("R");
			    	end();
    			}
	    },
	    {
			testname	=> "get uptime",
			cc1101_available	=> 0,
			input		=> "uptime",
			check =>  array  {
			    	item("t");
			    	end();
    			}
	    },
	    {
			testname	=> "get ? ",
			cc1101_available	=> 0,
			input		=> "?",
			check 		=>  array  {end(); },
			return 		=> check_set match qr/^Unknown argument \?, choose one of.*/,!match qr/cc/
	    },
	    {
			testname	=> "get ?",
			cc1101_available	=> 1,
			dummy		=> 0,
			DIODev		=> 1,
			input		=> "?",
			check 		=>  array  {end(); },
			return 		=> check_set match qr/^Unknown argument \?, choose one of.*/,match qr/cc/
	    },
	    {
			testname	=> "get ?",
			cc1101_available	=> 1,
			dummy		=> 0,
			DIODev		=> 0,
			input		=> "?",
			check 		=>  array  {end(); },
			return 		=> check_set match qr/^Unknown argument \?, choose one of.*/,!match qr/cc/,
	    },
	    {
			testname	=> "get ?",
			cc1101_available	=> 1,
			dummy		=> 1,
			input		=> "?",
			check 		=>  array  {end(); },
			return 		=> match qr/^Unknown argument \?, choose one of availableFirmware:noArg rawmsg:textFieldNL$/		
	    },

	    {
			testname	=> "get ping ",
			cc1101_available	=> 0,
			input		=> "ping",
			check =>  array  {
			    	item("P");
			    	end();
    			}
	    },
	    {
			testname	=> "get config ",
			cc1101_available	=> 0,
			input		=> "config",
			check =>  array  {
			    	item("CG");
			    	end();
    			}
	    },
	    {
			testname	=> "get ccconf ",
			cc1101_available	=> 1,
			input		=> "ccconf",
			check =>  array  {
			    	item("C0DnF");
			    	end();
    			}
	    },
	    {
			testname	=> "get ccconf ",
			cc1101_available	=> 0,
			input		=> "ccconf",
			check =>  array  { end();	},
    		return 		=> "This command is only available with a cc1101 receiver"
	    },
	    {
			testname	=> "get ccreg 12",
			cc1101_available	=> 1,
			input		=> "ccreg 12",
			check =>  array  {
			    	item("C12");
			    	end();
    			}
	    },
	    {
			testname	=> "get ccreg 98 (invalid register)",
			cc1101_available	=> 1,
			input		=> "ccreg 98",
			check =>  array  {
			    	end();
    			},
    		return => "unknown Register 98, please choose a valid cc1101 register"
	    },
	    {
			testname	=> "get ccreg 99 (all)",
			cc1101_available	=> 1,
			input		=> "ccreg 99",
			check =>  array  {
			    	item("C99");
			    	end();
    			},
	    },
	    {
			testname	=> "get ccreg 12 ",
			cc1101_available	=> 0,
			input		=> "ccreg 12",
			check =>  array  { end();	},
    		return 		=> "This command is only available with a cc1101 receiver"
	    },
	    {
			testname	=> "get ccpatable ",
			cc1101_available	=> 1,
			input		=> "ccpatable",
			check =>  array  {
			    	item("C3E");
			    	end();
    			}
	    },
	    {
			testname	=> "get ccpatable ",
			cc1101_available	=> 0,
			input		=> "ccpatable",
			check =>  array  { end();	},
    		return 		=> "This command is only available with a cc1101 receiver"
			
	    },
	    {
			testname	=> "get raw e ",
			cc1101_available	=> 0,
			input		=> "raw e",
			check =>  array  { end();	},
    		return 		=> "Unknown argument raw, choose one of supported commands"
	    },
	    {
			testname	=> "get rawmsg MS;P0=1500;D=0;",
			cc1101_available	=> 0,
			input		=> "rawmsg MS;P0=1500;D=0;",
			check =>  array  { end();	},
 			return 		=> "Parse raw msg, no suitable protocol recognized."		
	    },
	    {
			testname			=> 	'get availableFirmware without hardware',
			cc1101_available	=>	 0,
			input				=> 	'availableFirmware',
			check 				=>  array  { end();	},
			pre_code			=> 	sub {
										my $target = shift;
										$attr{$target}{updateChannelFW} = 'stable';
										$attr{$target}{hardware} 		= '0';
									},
 			return 				=> qr/.*get availableFirmware failed.*/		
	    },
	    {
			testname			=> 	'get availableFirmware with hardware',
			cc1101_available	=>	 0,
			input				=> 	'availableFirmware',
			check 				=>  array  { end();	},
			pre_code			=> 	sub {
										my $target = shift;
										$attr{$target}{updateChannelFW} = 'stable';
										$attr{$target}{hardware} 		= 'nano328';
									},
 			return 				=> "availableFirmware: \n\nFetching stable firmware versions for nano328 from github\n"
	    },



    );
}

InternalTimer(time()+1, sub {
	my $target = shift;
	my $targetHash = $defs{$target};
	plan (scalar @mockData + 3);	

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

		$element->{pre_code}->($target) if (exists $element->{pre_code} );
		$todo=$element->{todo}->() if (exists $element->{todo} );
		
		subtest "checking $element->{testname}". ($targetHash->{cc1101_available} ? " with cc1101" : " without cc1101"). " " . ($targetHash->{DIODev} ? " devIo open" : " devIo closed") => sub {
			plan (2);	
			
			my $ret = SIGNALduino_Get($targetHash,$target,split(" ",$element->{input}));
			like($ret,$element->{return},'Verify return value');
			is($targetHash->{QUEUE},$element->{check},"Verify expected queue element entrys");

			@{$targetHash->{QUEUE}}=();
			delete($targetHash->{ucCmd});
		};
		undef ($todo);
		$element->{post_code}->() if (exists($element->{post_code}));
	
	};
	
	subtest 'Test get rawmsg MS;P1=309;' => sub {
		plan (3);
		my $mock = Test2::Mock->new(
			track => 1,
			class => 'main',
			override => [
				SIGNALduino_Parse => sub { return ; },
			],
		);	 	
		my $tracking = $mock->sub_tracking;

		my $rawArg='MS;P1=309;';
		my $ret=SIGNALduino_Get($targetHash, $target, "rawmsg", $rawArg);
		is($ret,"Parse raw msg, no suitable protocol recognized.","Verify return value");
		
		is ($tracking->{SIGNALduino_Parse}, D(),'check SIGNALduino_Parse is called' );
		is( $tracking->{SIGNALduino_Parse}[0]{args}[3], "\002".$rawArg."\003" , 'check if SIGNALduino_Parse was called with arg' ) ;
		$mock->restore('SIGNALduino_Parse');
	}; 

	subtest 'Test device with dummy attrib 1' => sub {
		plan (3);

		subtest 'Test Attributes (hardware undef)' => sub {
			plan(2);
			is(AttrVal($target, "dummy", 0),1,"check attrib dummy is 1");
			delete $attr{$target}{hardware} if (AttrVal($target, "hardware", undef));
			is(AttrVal($target, "hardware", undef),undef,"check attrib hardware undef");
		};

		subtest 'Test allowed - get commands' => sub {
			my $ret=SIGNALduino_Get($targetHash, $target, "?");

			my @tests = split(" ", substr($ret,index($ret,"one of")+7));
			my $tests = scalar(@tests);
			plan($tests);

			like($ret,qr/^Unknown argument \?, .*availableFirmware:noArg.*/,"check cmd availableFirmware accepted");
			like($ret,qr/^Unknown argument \?, .*rawmsg/,"check cmd rawmsg accepted");
		};

		subtest 'Test not allowed - get commands' => sub {
			my $ret=SIGNALduino_Get($targetHash, $target, "?");
			plan(9);

			unlike($ret,qr/.*ccconf.*/,"check cmd ccconf not allowed");
			unlike($ret,qr/.*ccpatable.*/,"check cmd ccpatable not allowed");
			unlike($ret,qr/.*ccreg.*/,"check cmd ccreg not allowed");
			unlike($ret,qr/.*cmds.*/,"check cmd cmds not allowed");
			unlike($ret,qr/.*config.*/,"check cmd config not allowed");
			unlike($ret,qr/.*freeram.*/,"check cmd freeram not allowed");
			unlike($ret,qr/.*ping.*/,"check cmd ping not allowed");
			unlike($ret,qr/.*uptime.*/,"check cmd uptime not allowed");
			unlike($ret,qr/.*version.*/,"check cmd version not allowed");
		};
	};
	
	subtest 'Test device with hardware attribute and dummy is 0 / devio open' => sub {
		plan(2);
		subtest 'Test Attributes (hardware nano328)' => sub {
			plan(3);
			$attr{$target}{dummy} = "0";
			$attr{$target}{hardware} = "nano328";
			$targetHash->{DIODev} = 1;

			is(AttrVal($target, "dummy", 0),0,"check attrib dummy is 0");
			is(AttrVal($target, "hardware", undef),"nano328","check attrib hardware set nano328");
			ok(DevIo_IsOpen($targetHash),"check DevIo_IsOpen returns true");
			
		};
			
		subtest 'Test allowed - get commands' => sub {
			my $ret=SIGNALduino_Get($targetHash, $target, "?");
			
			note("if a new command is developed, the test must be expanded --> otherwise error");
			my @tests = split(" ", substr($ret,index($ret,"one of")+7));
			my $tests = scalar(@tests);
			plan($tests);

			like($ret,qr/^Unknown argument \?, .*availableFirmware:noArg.*/,"check cmd availableFirmware accepted");
			like($ret,qr/^Unknown argument \?, .*cmds.*/,"check cmd cmds accepted");
			like($ret,qr/^Unknown argument \?, .*config.*/,"check cmd config accepted");
			like($ret,qr/^Unknown argument \?, .*freeram.*/,"check cmd freeram accepted");
			like($ret,qr/^Unknown argument \?, .*ping.*/,"check cmd ping accepted");
			like($ret,qr/^Unknown argument \?, .*rawmsg.*/,"check cmd rawmsg accepted");
			like($ret,qr/^Unknown argument \?, .*uptime.*/,"check cmd uptime accepted");
			like($ret,qr/^Unknown argument \?, .*version.*/,"check cmd version accepted");
		};
	};

	exit(0);
},'dummyDuino');

1;