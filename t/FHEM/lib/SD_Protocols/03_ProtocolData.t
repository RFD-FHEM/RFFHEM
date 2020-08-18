#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is item U D match hash array bag};
use Test2::Todo;


use lib::SD_ProtocolData;
plan(2);


my $check_hash = hash
{
	
	field '100' => hash {
		field modulation => '2-FSK';
		field register => array { 
            item '0001';
            item '0246';
            item '0301';
            item '042D';
            item '05D4';
            item '06FF';
            item '0700';
            item '0802';
            item '0D21';
            item '0E65';
            item '0F6A';
            item '1089';
            item '115C';
            item '1206';
            item '1322';
            item '14F8';
            item '1556';
            item '1700';
            item '1818';
            item '1916';
            item '1B43';
            item '1C68';
            item '1D91';
            item '23EC';
            item '2517';
            item '2611';
            item '2B3E';
			end();
		};
		etc();
	};
	etc();
};


is(%lib::SD_ProtocolData::protocols,D(),q[%protocols is defined]);
is(\%lib::SD_ProtocolData::protocols,$check_hash,q[%protocols meets criteria]);


done_testing();
exit(0);
