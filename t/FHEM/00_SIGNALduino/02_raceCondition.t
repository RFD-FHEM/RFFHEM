#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is like};
use Test2::Todo;
use Test2::Tools::Exception qw/dies lives/;


subtest 'Delete $defs{name} and check if internal timers causes crash' => sub {
	CommandDefine(undef,"raceDuino SIGNALduino none");
	is(IsDevice('raceDuino'),1,'check definition is created');
	delete $defs{raceDuino};
	is(IsDevice('raceDuino'),0,'check definition is deleted');
	
	my $todo = Test2::Todo->new(reason => 'This crash needs a fix');
	
	like(
	    lives   { HandleTimeout() },
	    qr/Can't use an undefined value/,
	    'Got exception'
	);
};


subtest 'CommandDelete and check if internal timers causes crash' => sub {
	CommandDefine(undef,"raceDuino SIGNALduino none");
	is(IsDevice('raceDuino'),1,'check definition is created');
	CommandDelete(undef,'raceDuino');
	is(IsDevice('raceDuino'),0,'check definition is deleted');
	
	my $todo = Test2::Todo->new(reason => 'This crash needs a fix');
	
	like(
	    lives   { HandleTimeout() },
	    qr/Can't use an undefined value/,
	    'Got exception'
	);
};

CommandDefine(undef,"raceDuino SIGNALduino none");

subtest ' check if sub SIGNALduino_IdList causes crash if name does not exists' => sub {
	my $todo = Test2::Todo->new(reason => 'This crash needs a fix');

	like(
	    lives   { SIGNALduino_IdList('sduino_IdList:DeviceDoesNotExists'); },
	    qr/Can't use an undefined value/,
	    'Got exception'
	);
	
};

done_testing();
exit(0);


1;