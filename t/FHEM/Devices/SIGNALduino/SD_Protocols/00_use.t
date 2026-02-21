#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Class;
use FHEM::Devices::SIGNALduino::SD_Protocols qw(:ALL);
use Test2::Tools::Exception qw/dies lives/;


my $obj;
my $className='FHEM::Devices::SIGNALduino::SD_Protocols';

plan(2);

subtest 'create object' => sub {
	plan(2);
	ok( !$@, 'use (import :ALL) succeeded' );
	$obj = new $className();
	
	isa_ok($obj,[$className],'check for correct class');  
};


subtest 'checkInvocant method' => sub {
	my $scalar = 'no ref, just a scalar';
	
	plan(4);
	like(dies { FHEM::Devices::SIGNALduino::SD_Protocols::_checkInvocant() } ,qr/The invocant is not defined/,'check for wrong caller');  
	like(dies { FHEM::Devices::SIGNALduino::SD_Protocols::_checkInvocant($scalar) } ,qr/The invocant is not a reference/,'check for not a ref');  
	like(dies { FHEM::Devices::SIGNALduino::SD_Protocols::_checkInvocant(\$scalar) } ,qr/The invocant is not an object/,'check for not a obj ref');  
	like(dies { FHEM::Devices::SIGNALduino::SD_Protocols::_checkInvocant($obj) } ,qr/The invocant is not a subclass of/,'check for subclass');  


};
