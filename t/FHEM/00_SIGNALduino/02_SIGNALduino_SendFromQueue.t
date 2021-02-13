use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is like check hash within field U};
use Test2::Mock;

our %defs;
our %attr;

InternalTimer(time()+1, sub {
	my $target = shift;
	my $targetHash = $defs{$target};
	plan (13);	

	
	$targetHash->{cc1101_available} = 1;
	foreach (qw/SR SC SM SN/) {
		subtest "Test SendCommands ($_) SIGNALduino_SendFromQueue called" => sub {
			plan(3);
			my $check =  hash {
				    	field cmd => 'sendraw';
				    	field timenow => within(time(), 10);
				    	field responseSub => \&SIGNALduino_CheckSendRawResponse;
				    	end();
			};
	
			my $mock = Test2::Mock->new(
				track => 1,
				class => 'main',
				override => [
					SIGNALduino_SimpleWrite => sub { 0 },
				],
			);	 	
			my $tracking = $mock->sub_tracking;

			SIGNALduino_SendFromQueue($targetHash,"$_;");
			is(scalar @{$tracking->{SIGNALduino_SimpleWrite}},1,"SIGNALduino_SimpleWrite called");
			is($tracking->{SIGNALduino_SimpleWrite}[0]{args}[1], "$_;", "check msg given to SIGNALduino_SimpleWrite" );
			is($targetHash->{ucCmd},$check,"Verify ucCmd hash");
		
			$mock->restore('SIGNALduino_SimpleWrite');
		};
	};


	subtest "Test cmd (e) SIGNALduino_SendFromQueue called" => sub {
		plan(3);
		my $mock = Test2::Mock->new(
			track => 1,
			class => 'main',
			override => [
				SIGNALduino_Get => sub { 0 },
			],
		);	 	
		my $tracking = $mock->sub_tracking;

		SIGNALduino_SendFromQueue($targetHash,"e");
		is(scalar @{$tracking->{SIGNALduino_Get}},2,"SIGNALduino_Get called twice");
		is($tracking->{SIGNALduino_Get}[1]{args}[2], "ccpatable", "check get with ccpatable is executed" );
		$mock->restore('SIGNALduino_Get');
		is($attr{$target}{rfmode},U,'verify attr rfmode');
	};

	subtest 'Test cmd (e) SIGNALduino_SendFromQueue called rfmode != SlowRF' => sub {
		plan(1);
		$attr{$target}{rfmode}='HomeMatic';
		SIGNALduino_SendFromQueue($targetHash,'e');
		is($attr{$target}{rfmode},'SlowRF','verify reset of attr rfmode');
	};

	
	subtest "Test cmd (x) SIGNALduino_SendFromQueue called" => sub {
		plan(2);
		my $mock = Test2::Mock->new(
			track => 1,
			class => 'main',
			override => [
				SIGNALduino_Get => sub { 0 },
			],
		);	 	
		my $tracking = $mock->sub_tracking;

		SIGNALduino_SendFromQueue($targetHash,"x");
		is(scalar @{$tracking->{SIGNALduino_Get}},1,"SIGNALduino_Get called once");
		is($tracking->{SIGNALduino_Get}[0]{args}[2], "ccpatable", "check get with ccpatable is executed" );
		$mock->restore('SIGNALduino_Get');
	};
	foreach (qw/W0F W10 W11 W1D W12 W1F/) {

		subtest "Test cmd ($_) SIGNALduino_SendFromQueue called" => sub {
			plan(2);
			my $mock = Test2::Mock->new(
				track => 1,
				class => 'main',
				override => [
					SIGNALduino_Get => sub { 0 },
				],
			);	 	
			my $tracking = $mock->sub_tracking;
			
			SIGNALduino_SendFromQueue($targetHash,"$_");
			is(scalar @{$tracking->{SIGNALduino_Get}},1,"SIGNALduino_Get called once");
			is($tracking->{SIGNALduino_Get}[0]{args}[2], "ccconf", "check get with ccconf is executed" );
			$mock->restore('SIGNALduino_Get');
		};
	}

	delete($targetHash->{ucCmd});
	exit(0);
},'dummyDuino');

1;