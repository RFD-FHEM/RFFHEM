use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is bag check array like unlike U};
use Test2::Mock;
use Test2::Todo;

our %defs;
our %attr;


InternalTimer(time()+1, sub {
	my $target = shift;
	my $targetHash = $defs{$target};
	my $mock = Test2::Mock->new(
		track => 1,
		class => 'main'
	);	 	

	my $tracking = $mock->sub_tracking;
	my $preparedavrdudecmd;

    plan(5);
    
    SKIP: {

        skip('sub SIGNALduino_avrdude does not check parameters', 1);
        subtest 'check error returns' => sub {
            my @p=();
            plan(1);

            like(SIGNALduino_avrdude(), qr/Error/, 'Verify error without argument');
        };
    };

    subtest 'without installed avrdude' => sub {
        plan(6);
        CommandAttr(undef,"$target hardware nano328");
        CommandAttr(undef,'global logdir /tmp/');
		$targetHash->{helper}{avrdudecmd}=q[perl -e '{ exit(127); }' 2>> [LOGFILE]];
        $mock->override('DevIo_OpenDev' => sub {} );
		$mock->clear_sub_tracking;

		$targetHash->{helper}{stty_pid} = "999494";	
		my $ret = SIGNALduino_avrdude($target);

		is($ret, "ERROR: avrdude exited with error", "check return value");		
		is($targetHash->{FLASH_RESULT},$ret, "check internal value");		
		is($targetHash->{helper}{stty_pid}, undef, "check stty_pid value");		

		is(ReadingsVal($target,'state',''),'FIRMWARE UPDATE with error','check reading state');
		is($targetHash->{helper}{avrdudecmd},q[perl -e '{ exit(127); }' 2>> /tmp/SIGNALduino-Flash.log],'check exitcode (127 = command not found)');
        is(scalar @{$tracking->{DevIo_OpenDev}},1,'DevIo_OpenDev called');

	};

    subtest 'whithoud LOGFILE placeholder in avrdudecmd' => sub {
        plan(6);
		$mock->clear_sub_tracking;

		$targetHash->{helper}{avrdudecmd} = q[perl -e '{ exit(127); }' 2];
		my $ret = SIGNALduino_avrdude($target);
		is($ret, 'WARNING: avrdude created no log file', 'check return value without LOGFILE placeholder');		
		is($targetHash->{FLASH_RESULT},$ret, 'check internal value');		
		is($targetHash->{helper}{stty_pid}, undef, 'check stty_pid value');		
        is(scalar @{$tracking->{DevIo_OpenDev}},1,'DevIo_OpenDev called');
        is(ReadingsVal($target,'state',''),'FIRMWARE UPDATE with error','check reading state');
        is(scalar @{$tracking->{DevIo_OpenDev}},1,'DevIo_OpenDev called');

	};
    
	subtest 'whithoud invalid global logdir path' => sub {
        plan(5);
		$mock->clear_sub_tracking;

		$targetHash->{helper}{avrdudecmd} = q[perl -e '{ exit(127); }' 2>> [LOGFILE]];
		CommandAttr(undef,'global logdir /tmp/jiddsidio/');
		my $ret = SIGNALduino_avrdude($target);

		is($ret, 'WARNING: avrdude created no log file', 'check return value with wrong path');		
		is($targetHash->{FLASH_RESULT},$ret, 'check internal value');		
		is($targetHash->{helper}{stty_pid}, undef, 'check stty_pid value');		
        is(ReadingsVal($target,'state',''),'FIRMWARE UPDATE with error','check reading state');
        is(scalar @{$tracking->{DevIo_OpenDev}},1,'DevIo_OpenDev called');
    };

    subtest 'with installed avrdude (nano328)' => sub {
        plan(6);
        CommandAttr(undef,"$target hardware nano328");
        CommandAttr(undef,'global logdir /tmp/');
		$targetHash->{helper}{avrdudecmd}=q[perl -e '{ exit(0); }' 2>> [LOGFILE]];
        $mock->override('DevIo_OpenDev' => sub {} );
		$mock->clear_sub_tracking;

		$targetHash->{helper}{stty_pid} = "999494";	
		my $ret = SIGNALduino_avrdude($target);

		is($ret,U(), 'check return value');		
		is($targetHash->{FLASH_RESULT},$ret, 'check internal value');		
		is($targetHash->{helper}{stty_pid}, undef, 'check stty_pid value');		

		is(ReadingsVal($target,'state',''),'FIRMWARE UPDATE successfull','check reading state');
		is($targetHash->{helper}{avrdudecmd},q[perl -e '{ exit(0); }' 2>> /tmp/SIGNALduino-Flash.log],'check exitcode (0 = successfull)');
        is(scalar @{$tracking->{DevIo_OpenDev}},1,'DevIo_OpenDev called');

	};

	$mock->restore('DevIo_OpenDev');	
	exit(0);
},'dummyDuino');

1;
