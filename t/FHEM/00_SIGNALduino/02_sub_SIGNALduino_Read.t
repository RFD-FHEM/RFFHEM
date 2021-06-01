#!/bin/perl
use strict;
use warnings;
use Test::Device::SerialPort;
use Test2::V0;
use Test2::Tools::Compare;
use Test2::Todo;
use Test2::Mock;


my %mockData = (
'9'    => 
	{	
		real	=>	"MU;P0=-28704;P1=450;P2=-1064;P3=1422;CP=1;R=13;D=012121212121212123212121212121212121212123232323232123212321232123232323232323232323232323232323232323232323232323232121212123210121212121212121232121212121212121212121232323232321232123212321232323232323232323232323232323232323232323232323232321212121232101212121212121212321212121212121212121212323232323212321232123212323232323232323232323232323232323232323232323232323212121212321;",
		raw 	=> 	'02 4d 75 3b a0 a0 f0 3b 91 c2 81 3b a2 a8 84 3b 93 8e 85 3b 43 31 3b 52 44 3b 44 01 21 21 21 21 21 21 21 23 21 21 21 21 21 21 21 21 21 21 21 23 23 23 23 23 21 23 21 23 21 23 21 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 21 21 21 21 23 21 01 21 21 21 21 21 21 21 23 21 21 21 21 21 21 21 21 21 21 21 23 23 23 23 23 21 23 21 23 21 23 21 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 21 21 21 21 3b 46 36 34 3b 44 23 21 01 21 21 21 21 21 21 21 23 21 21 21 21 21 21 21 21 21 21 21 23 23 23 23 23 21 23 21 23 21 23 21 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 23 21 21 21 21 23 21 3b 03',
	},
'7' => 	
	{
		real 	=> "MS;P2=476;P3=-3894;P4=-977;P5=-1966;D=23242525242524252524242524242424242524252524252525252525252424252524242524;CP=2;SP=3;R=240;O;m0;",
		raw 	=> '02 4d 73 3b 92 dc 81 3b a3 b6 8f 3b b4 d1 83 3b b5 ae 87 3b 44 23 24 25 25 24 25 24 25 25 24 24 25 24 24 24 24 24 25 24 25 25 24 25 25 25 25 25 25 25 24 24 25 25 24 24 25 24 3b 43 32 3b 53 33 3b 52 46 30 3b 4f 3b 6d 30 3b 03',
	},
);
our %defs;

my $target = 'dummyDuino';
my $targetHash = $defs{$target};

 InternalTimer(time()+1, sub {
	plan (7);
	
	my $id=9;
	fhem("attr $target debug 1");
	my $PortObj = Test::Device::SerialPort->new('/dev/ttyS0');
	my $mock = Test2::Mock->new(
		track => 1, # enable call tracking if desired
		class => 'main',
		override => [
			SIGNALduino_Parse => sub { 0 },
		],
	);
	my $tracking = $mock->sub_tracking;



	$targetHash->{USBDev} = $PortObj;

	for $id (qw/9 7/) 
	{
		$mock->clear_sub_tracking;
		subtest "Checking read function without mred ID=$id" => sub {
			plan (2);
	
			$PortObj->{"_fake_input"} = $mockData{$id}{real}."\n";
			SIGNALduino_Read($targetHash);

			is(scalar @{$tracking->{SIGNALduino_Parse}}, 1, "check number of parse attempts ");
			is( ($tracking->{SIGNALduino_Parse}[0]{args}[3]), $mockData{$id}{real}, 'check rmsg send to SIGNALduino_Parse' ); 
			$mock->clear_sub_tracking;
		};
	
		subtest "Checking read function with mred ID=$id" => sub {
			plan (2);
					
			$PortObj->{"_fake_input"} = "";
			$mockData{$id}{raw} =~ tr/ //d;
			$PortObj->{"_fake_input"} .= pack('H*', $mockData{$id}{raw});
			$PortObj->{"_fake_input"}.="\n";

			SIGNALduino_Read($targetHash);
			is(scalar @{$tracking->{SIGNALduino_Parse}}, 1, "check number of parse attempts ");
			my $todo = Test2::Todo->new(reason => 'This test must be doublechecked');
			is( ($tracking->{SIGNALduino_Parse}[0]{args}[3]), $mockData{$id}{real}, 'check rmsg send to SIGNALduino_Parse' ); 
			$todo->end;
		};
	};
	
	subtest "Verify splitting of received getcmd" => sub {
		plan (4);
	
		$mock->clear_sub_tracking;
		$PortObj->{"_fake_input"} = "V 3.4.0-dev SIGNALESP cc1101 (chip CC1101) - compiled at Dec";
		SIGNALduino_Read($targetHash);
		is($targetHash->{PARTIAL},"V 3.4.0-dev SIGNALESP cc1101 (chip CC1101) - compiled at Dec", "check PARTIAL");

		$PortObj->{"_fake_input"} = "  4 2019 22:01:01";
		SIGNALduino_Read($targetHash);
		is($targetHash->{PARTIAL},"V 3.4.0-dev SIGNALESP cc1101 (chip CC1101) - compiled at Dec  4 2019 22:01:01", "check PARTIAL append");

		$PortObj->{"_fake_input"} = "\nMs;???;???;???;???;";
		$targetHash->{getcmd}->{cmd} = "version";
		SIGNALduino_Read($targetHash);
		is($targetHash->{PARTIAL},"Ms;???;???;???;???;", "check linebreak split");
		is( ($tracking->{SIGNALduino_Parse}[0]{args}[3]), 'V 3.4.0-dev SIGNALESP cc1101 (chip CC1101) - compiled at Dec  4 2019 22:01:01', 'check rmsg send to SIGNALduino_Parse' ); 

	};
	
	
	subtest 'Verify splitting of received getcmd with incomplete partial' => sub {
		plan (3);
		$mock->clear_sub_tracking;
		fhem("attr $target debug 1");
		
		$targetHash->{getcmd}->{cmd} = "version";
		$targetHash->{PARTIAL}="MU;P0=-28704;P1=450;P2=-1064;P3=1422;CP=1;R=13;D=";
		
		$PortObj->{"_fake_input"} = "MU;P0=-28704;P1=450;P2=-1064;P3=1422;CP=1;R=13;D=01;\nMU;P0=-28704;P1=450;P2=-1064;P3=1422;CP=1;R=13;D=23;\nV 3.4.0-dev SIGNALduino cc1101 (chip CC1101) - compiled at Dec  4 2019 22:02:15\n";
		SIGNALduino_Read($targetHash);
		is( $targetHash->{PARTIAL}, "", 'check internal PARTIAL' ); 
		is( $targetHash->{getcmd}->{cmd},"version","verify getcmd is version");
		is( ($tracking->{SIGNALduino_Parse}[2]{args}[3]), 'V 3.4.0-dev SIGNALduino cc1101 (chip CC1101) - compiled at Dec  4 2019 22:02:15', 'check rmsg send to SIGNALduino_Parse' ); 
		
	}; 
	

	subtest 'Verify sendraw split and regex' => sub {
		my $todo = Test2::Todo->new(reason => 'test is not completed see github #823');

		
		plan (2);
		$mock->clear_sub_tracking;
		fhem("attr $target debug 1");
		
		$targetHash->{getcmd}->{cmd} = "sendraw";
       	$targetHash->{ucCmd}->{timenow} = time();
       	$targetHash->{ucCmd}->{responseSub} = \&SIGNALduino_CheckSendRawResponse;
		#$targetHash->{PARTIAL}="SR;";
		
		$PortObj->{"_fake_input"} = "SR;F\nR=6;P0=250;P1=-7750;P2=750;P3=-250;P4=-750";
		# \nF\nR=6;P0=250;P1=-7750;P2=750;P3=-250;P4=-750;
		SIGNALduino_Read($targetHash);
		is( $targetHash->{PARTIAL}, "SR;", 'check internal PARTIAL' ); 
		is( $targetHash->{getcmd}->{cmd},"sendraw","verify getcmd is sendraw");
		
		#$PortObj->{"_fake_input"} = "R=6;P0=250;P1=-7750;P2=750;P3=-250;P4=-750;F\n";
		#SIGNALduino_Read($targetHash);
		#is( $targetHash->{PARTIAL}, "", 'check internal PARTIAL' ); 
		#is($targetHash->{getcmd}->{cmd},"sendraw","verify getcmd is sendraw");
		$todo->end;

	}; 

	$mock->restore('SIGNALduino_Parse');
	
	fhem("attr $target debug 0");
	$targetHash->{USBDev} = undef;
	#done_testing();

	exit(0);

 },0);

 1;