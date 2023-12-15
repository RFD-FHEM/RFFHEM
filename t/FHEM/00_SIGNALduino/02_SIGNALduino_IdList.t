#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{like};
use Test2::Todo;
use Test2::Tools::Exception qw/lives/;
our %defs;
our $init_done;

sub runTest {
	my $target = shift;
	my $targetHash = $defs{$target};

	plan(11);

	subtest 'check if sub SIGNALduino_IdList causes crash if name does not exists' => sub {
		is(
			lives   { SIGNALduino_IdList('sduino_IdList:DeviceDoesNotExists'); },
			T(),
			'No exception'
		);
		
	};

	subtest 'check default Clientlist withoud whitelist_IDs' => sub {
		plan(5);

		like($targetHash->{Clients},qr/CUL_TCM97001/,'Clientlist has CUL_TCM07001');
		unlike($targetHash->{Clients},qr/CUL_TCM97001:CUL_TCM97001/,'Clientlist has no SD_GT ');
		like($targetHash->{Clients},qr/SD_GT/,'Clientlist has SD_GT ');
		like($targetHash->{Clients},qr/SD_RSL/,'Clientlist has SD_RSL');
		like($targetHash->{Clients},qr/SIGNALduino_un/,'Clientlist has SIGNALduino_un');
	};

	subtest 'check clientlist with whitelist_IDs 0' => sub {
		plan(4);
		CommandAttr(undef, qq[$target whitelist_IDs 0]);

		like($targetHash->{Clients},qr/CUL_TCM97001/,'Clientlist has CUL_TCM07001');
		unlike($targetHash->{Clients},qr/SD_GT/,'Clientlist has no SD_GT ');
		unlike($targetHash->{Clients},qr/SD_RSL/,'Clientlist has no SD_RSL');
		unlike($targetHash->{Clients},qr/SIGNALduino_un/,'Clientlist has no SIGNALduino_un');
	};


	subtest 'check clientlist with whitelist_IDs 0,0.1' => sub {
		plan(5);
		CommandAttr(undef, qq[$target whitelist_IDs 0,0.1]);

		like($targetHash->{Clients},qr/CUL_TCM97001/,'Clientlist has CUL_TCM07001');
		unlike($targetHash->{Clients},qr/CUL_TCM97001:CUL_TCM97001/,'Clientlist has no SD_GT ');
		unlike($targetHash->{Clients},qr/SD_GT/,'Clientlist has no SD_GT ');
		unlike($targetHash->{Clients},qr/SD_RSL/,'Clientlist has no SD_RSL');
		unlike($targetHash->{Clients},qr/SIGNALduino_un/,'Clientlist has no SIGNALduino_un');
	};

	subtest 'check clientlist with whitelist_IDs 0,0.1,49' => sub {
		plan(5);
		CommandAttr(undef, qq[$target whitelist_IDs 0,0.1,49]);

		like($targetHash->{Clients},qr/CUL_TCM97001/,'Clientlist has CUL_TCM07001');
		like($targetHash->{Clients},qr/SD_GT/,'Clientlist has SD_GT');
		unlike($targetHash->{Clients},qr/CUL_TCM97001:CUL_TCM97001/,'Clientlist has no SD_GT ');
		unlike($targetHash->{Clients},qr/SD_RSL/,'Clientlist has no SD_RSL');
		unlike($targetHash->{Clients},qr/SIGNALduino_un/,'Clientlist has no SIGNALduino_un');
	};

	subtest 'check clientlist after delete attr whitelist_IDs' => sub {
		plan(5);
		CommandDeleteAttr(undef, qq[$target whitelist_IDs]);

		like($targetHash->{Clients},qr/CUL_TCM97001:/,'Clientlist has CUL_TCM07001');
		like($targetHash->{Clients},qr/SD_GT:/,'Clientlist has SD_GT');
		unlike($targetHash->{Clients},qr/CUL_TCM97001:CUL_TCM97001/,'Clientlist has no SD_GT ');
		like($targetHash->{Clients},qr/SD_RSL/,'Clientlist has no SD_RSL');
		like($targetHash->{Clients},qr/SIGNALduino_un/,'Clientlist has no SIGNALduino_un');
	};

	subtest 'check whitespace breaks in clientlist with whitelist_IDs 0,0.1,1,3,8,12,49,60,61,64,68' => sub {
		plan(1);
		CommandAttr(undef, qq[$target whitelist_IDs 0,0.1,1,3,8,12,49,60,61,64,68]);
		print Dumper  ($targetHash->{Clients});
		like($targetHash->{Clients},qr/: :/,'Clientlist has Whitespace');
	};

	subtest 'check whitespace breaks in clientlist without whitelist_IDs attribute' => sub {
		plan(1);
		CommandDeleteAttr(undef, qq[$target whitelist_IDs]);
		
		like($targetHash->{Clients},qr/: :/,'Clientlist has Whitespace');
	};

	subtest 'check whitespace with two modules and name is included in other modules name also 54,47' => sub {
		plan(2);
		CommandAttr(undef, qq[$target whitelist_IDs 54,47]);
		like($targetHash->{Clients},qr/:SD_WS/,'Clientlist has SD_WS');
		like($targetHash->{Clients},qr/SD_WS_Maverick/,'Clientlist has SD_WS_MAVERICK');
	};

	subtest 'check last ":" is removed with attr whitelist_IDs 54,47' => sub {
		plan(1);
		CommandAttr(undef, qq[$target whitelist_IDs 54,47]);
		isnt(substr($targetHash->{Clients}, -1),':','Last ":" is removed');
	};

	subtest 'check last ":" is removed without attr whitelist_IDs' => sub {
		plan(1);
		CommandDeleteAttr(undef, qq[$target whitelist_IDs]);
		isnt(substr($targetHash->{Clients}, -1),':','Last ":" is removed');
		#print 'last char is '.substr($targetHash->{Clients}, -1);
	};


}


sub waitDone {

	if ($init_done) 
	{
		runTest(@_);
		done_testing();
		InternalTimer(time(), &CORE::exit(0),0);
	} else {
		InternalTimer(time()+0.2, &waitDone,@_);			
	}

}

waitDone('dummyDuino');


1;