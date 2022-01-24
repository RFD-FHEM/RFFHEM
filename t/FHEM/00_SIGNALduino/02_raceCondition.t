#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is like};
use Test2::Todo;
use Test2::Tools::Exception qw/dies lives/;

our %defs;

subtest 'Delete $defs{name} and check if internal timers causes crash' => sub {
	CommandDefine(undef,"raceDuino SIGNALduino none");
	is(IsDevice('raceDuino'),T(),'check definition is created');
	delete $defs{raceDuino};
	is(IsDevice('raceDuino'),F(),'check definition is deleted');
	
	is(
	    lives { HandleTimeout() },
		T(),
	    'Got no exception'
	);
};


subtest 'CommandDelete and check if internal timers causes crash' => sub {
	CommandDefine(undef,"raceDuino SIGNALduino none");
	is(IsDevice('raceDuino'),T(),'check definition is created');
	CommandDelete(undef,'raceDuino');
	is(IsDevice('raceDuino'),F(),'check definition is deleted');
	
	is(
	    lives { HandleTimeout() },
		T(),
	    'Got no exception'
	);
};

CommandDefine(undef,"raceDuino SIGNALduino none");

subtest ' check if sub SIGNALduino_IdList causes crash if name does not exists' => sub {
	#my $todo = Test2::Todo->new(reason => 'This crash needs a fix');

	ok(
	    lives   { SIGNALduino_IdList('sduino_IdList:DeviceDoesNotExists'); },
	    'Got no exception'
	);
	
};

done_testing();
exit(0);

1;