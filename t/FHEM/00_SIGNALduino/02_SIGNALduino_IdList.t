#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{like};
use Test2::Todo;
use Test2::Tools::Exception qw/lives/;

subtest ' check if sub SIGNALduino_IdList causes crash if name does not exists' => sub {
	#my $todo = Test2::Todo->new(reason => 'This crash needs a fix');

	is(
	    lives   { SIGNALduino_IdList('sduino_IdList:DeviceDoesNotExists'); },
	    T(),
	    'No exception'
	);
	
};

done_testing();
exit(0);


1;