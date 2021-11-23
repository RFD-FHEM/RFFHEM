#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{ is like unlike check array U};
use Test2::Tools::Ref;
use Test::Device::SerialPort;

my $GlobalTestVar = undef;

sub dummyCb { $GlobalTestVar = $_[1]; 	}

our %defs;

InternalTimer(time()+1, sub {


		#use Data::Dumper;
		#diag (Dumper $targetHash);

	subtest 'Test return values SIGNALduino_Get_Callback with wrong parameters' => sub {
		plan(3);
		my $target = 'dummyDuino';
		my $targetHash = $defs{$target};

		my $ret = SIGNALduino_Get_Callback($target,\&dummyCb, "ccreg");
		is($ret,q["get _Get_Callback" needs at least two parameters],q[check return to less parameters]);

		$ret = SIGNALduino_Get_Callback('autocreate',\&dummyCb, "ccreg 12");
		is($ret,q["autocreate" is not a definition of type SIGNALduino],q[check return to less parameters]);
			
		$ret = SIGNALduino_Get_Callback("nonexistingdevice",\&dummyCb, "ccreg 12");
		is($ret,q["nonexistingdevice" is not a definition of type SIGNALduino],q[check return to less parameters]);
		
		delete($targetHash->{ucCmd});
	};

	subtest 'Test return values SIGNALduino_Get_Callback with correct parameters' => sub {
		plan(4);
		my $target = 'cc1101dummyDuino';
		my $targetHash = $defs{$target};

		$targetHash->{cc1101_available} = 1;
		
		my $ret = SIGNALduino_Get_Callback($target,\&dummyCb, "ccreg 12");
		is($ret,U,"check return SIGNALduino_Get_Callback");
		
		is($targetHash->{QUEUE},
			array  {
					item 'C12';
					end();
				} ,"Verify expected queue element entrys", $targetHash->{QUEUE});
		ref_is($targetHash->{ucCmd}{responseSub}, \&dummyCb, "Verify callback stored in target hash");
		is($targetHash->{ucCmd}{cmd}, "ccreg", "Verify called command stored in target hash");

		delete($targetHash->{cc1101_available});
	};

	subtest 'Test SIGNALduino_read with callback' => sub {
		plan(2);
		my $target = 'cc1101dummyDuino';
		my $targetHash = $defs{$target};

		my $PortObj = Test::Device::SerialPort->new('/dev/ttyS0');
		$targetHash->{USBDev} = $PortObj;
		$PortObj->{'_fake_input'} = "C12 = B4\n";

		is($GlobalTestVar,U,'verify testvar is undef before calling');
		SIGNALduino_Read($targetHash);
		is($GlobalTestVar,'C12 = B4','verify callback has changed testvar with response',$GlobalTestVar);
	};

    done_testing(); 
	exit(0);
},1); 

1;