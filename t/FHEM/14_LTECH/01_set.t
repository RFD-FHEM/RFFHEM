#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is};

our %defs;
our %attr;

InternalTimer(time()+1, sub {
	my $devicename = shift; 

    subtest 'Protocol 31 - define LTECH_Test_11' => sub {
		plan(1);
        CommandDefine(undef,qq[$devicename LTECH 04444EFF]); 
        is(IsDevice($devicename), 1, "check sensor created with define");
	};

    my $hash = $defs{$devicename};
    
    my $cmd=q[];
	subtest "Protocol 31 - set $devicename $cmd" => sub {
		plan(1);
		
        my $ret = FHEM::LTECH::Set($hash,$devicename,split(/ /,$cmd)); 
        is($ret, qq[Unknown argument $cmd, choose one of brightness:colorpicker,BRI,0,1,100 h:colorpicker,HUE,0,1,359 off:noArg on:noArg rgbcolor:colorpicker,HSV saturation:colorpicker,BRI,0,1,100 white:slider,0,1,255], q[check error message ]);
	};

    $cmd=q[badCmd];
	subtest "Protocol 31 - set $devicename $cmd" => sub {
		plan(1);
		
        my $ret = FHEM::LTECH::Set($hash,$devicename,split(/ /,$cmd)); 
        is($ret, qq[Unknown argument $cmd, choose one of brightness:colorpicker,BRI,0,1,100 h:colorpicker,HUE,0,1,359 off:noArg on:noArg rgbcolor:colorpicker,HSV saturation:colorpicker,BRI,0,1,100 white:slider,0,1,255], q[check error message ]);
	};


    $cmd=q[white ];
	subtest "Protocol 31 - set $devicename $cmd" => sub {
		plan(1);
		
        my $ret = FHEM::LTECH::Set($hash,$devicename,split(/ /,$cmd)); 
        is($ret, qq[Please provide valid number between 0 and 255], q[check error message ]);
	};

    $cmd=q[white -100];
	subtest "Protocol 31 - set $devicename $cmd" => sub {
		plan(1);
		
        my $ret = FHEM::LTECH::Set($hash,$devicename,split(/ /,$cmd)); 
        is($ret, qq[Please provide valid number between 0 and 255], q[check error message ]);
	};

    $cmd=q[white %a];
	subtest "Protocol 31 - set $devicename $cmd" => sub {
		plan(1);
		
        my $ret = FHEM::LTECH::Set($hash,$devicename,split(/ /,$cmd)); 
        is($ret, qq[Please provide valid number between 0 and 255], q[check error message ]);
	};

    $cmd=q[white 50];
	subtest "Protocol 31 - set $devicename $cmd" => sub {
		plan(2);
		
        my $ret = FHEM::LTECH::Set($hash,$devicename,split(/ /,$cmd)); 
        is($ret, U(), q[check return is undef]);
        is(ReadingsVal($devicename,'white_sel','00'),'50','check reading for devices');
	};

    $cmd=q[on];
	subtest "Protocol 31 - set $devicename $cmd" => sub {
		plan(2);
		
        my $ret = FHEM::LTECH::Set($hash,$devicename,split(/ /,$cmd)); 
        is($ret, U(), q[check return is undef]);
        is(ReadingsVal($devicename,'white','00'),'50','check reading for devices');
	};

    $cmd=q[brightness ];
	subtest "Protocol 31 - set $devicename $cmd" => sub {
		plan(1);
		
        my $ret = FHEM::LTECH::Set($hash,$devicename,split(/ /,$cmd)); 
        is($ret, qq[Please provide valid number between 0 and 100], q[check error message ]);
	};


    $cmd=q[brightness a%];
	subtest "Protocol 31 - set $devicename $cmd" => sub {
		plan(1);
		
        my $ret = FHEM::LTECH::Set($hash,$devicename,split(/ /,$cmd)); 
        is($ret, qq[Please provide valid number between 0 and 100], q[check error message ]);
	};


    $cmd=q[brightness 120];
	subtest "Protocol 31 - set $devicename $cmd" => sub {
		plan(1);
		
        my $ret = FHEM::LTECH::Set($hash,$devicename,split(/ /,$cmd)); 
        is($ret, qq[Please provide valid number between 0 and 100], q[check error message ]);
	};

    $cmd=q[brightness 50];
	subtest "Protocol 31 - set $devicename $cmd" => sub {
		plan(2);
		
        my $ret = FHEM::LTECH::Set($hash,$devicename,split(/ /,$cmd)); 
        is($ret, U(), q[check return is undef]);
        is(ReadingsVal($devicename,'rgbcolor','000000'),'7F7F7F','check reading for devices');
	};

    $cmd=q[saturation ];
	subtest "Protocol 31 - set $devicename $cmd" => sub {
		plan(1);
		
        my $ret = FHEM::LTECH::Set($hash,$devicename,split(/ /,$cmd)); 
        is($ret, qq[Please provide valid number between 0 and 100], q[check error message ]);
	};

    $cmd=q[saturation a%];
	subtest "Protocol 31 - set $devicename $cmd" => sub {
		plan(1);
		
        my $ret = FHEM::LTECH::Set($hash,$devicename,split(/ /,$cmd)); 
        is($ret, qq[Please provide valid number between 0 and 100], q[check error message ]);
	};


    $cmd=q[saturation 120];
	subtest "Protocol 31 - set $devicename $cmd" => sub {
		plan(1);
		
        my $ret = FHEM::LTECH::Set($hash,$devicename,split(/ /,$cmd)); 
        is($ret, qq[Please provide valid number between 0 and 100], q[check error message ]);
	};

    $cmd=q[saturation 100];
	subtest "Protocol 31 - set $devicename $cmd" => sub {
		plan(2);
		
        my $ret = FHEM::LTECH::Set($hash,$devicename,split(/ /,$cmd)); 
        is($ret, U(), q[check return is undef]);
        is(ReadingsVal($devicename,'rgbcolor','0000000'),'7F0000','check reading for devices');
	};
    
    $cmd=q[h ];
	subtest "Protocol 31 - set $devicename $cmd" => sub {
		plan(1);
		
        my $ret = FHEM::LTECH::Set($hash,$devicename,split(/ /,$cmd)); 
        is($ret, qq[Please provide valid number between 0 and 360], q[check error message ]);
	};


    $cmd=q[h a%];
	subtest "Protocol 31 - set $devicename $cmd" => sub {
		plan(1);
		
        my $ret = FHEM::LTECH::Set($hash,$devicename,split(/ /,$cmd)); 
        is($ret, qq[Please provide valid number between 0 and 360], q[check error message ]);
	};


    $cmd=q[h 370];
	subtest "Protocol 31 - set $devicename $cmd" => sub {
		plan(1);
		
        my $ret = FHEM::LTECH::Set($hash,$devicename,split(/ /,$cmd)); 
        is($ret, qq[Please provide valid number between 0 and 360], q[check error message ]);
	};


    $cmd=q[h 240];
	subtest "Protocol 31 - set $devicename $cmd" => sub {
		plan(2);
		
        my $ret = FHEM::LTECH::Set($hash,$devicename,split(/ /,$cmd)); 
        is($ret, U(), q[check return is undef]);

        is(ReadingsVal($devicename,'rgbcolor','000000'),'00007F','check reading for devices');
	};

    for my $cmd (qw (on off))
    {
        subtest "Protocol 31 - set $devicename $cmd" => sub {
            plan(1);
            
            my $ret = FHEM::LTECH::Set($hash,$devicename,split(/ /,$cmd)); 
            is($ret, U(), q[check return is undef]);
        };
    };

    done_testing();
	exit(0);

}, 'LTECH_Test_11');


1;