#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is item U hash array validator};
use Test2::Todo;


use lib::SD_ProtocolData;


my $validFSKcheck = validator(sub {
    my %params = @_;
 
    my $got = $_;
 
    my $name = $params{name};
 
    return 1 if ( !exists $got->{modulation} ) || ( $got->{modulation} ne '2-FSK' && $got->{modulation} ne 'GFSK') ;
   	return 0 if ( !exists $got->{registers} ) ;
 
} );


my $check_hash = hash
{	
	field '100' => hash {
		field modulation => '2-FSK';
		field register => array { 
            item '0001';
            item '022E';
            item '0341';
            item '042D';
            item '05D4';
            item '0605';
            item '0780';
            item '0800';
            item '0D21';
            item '0E65';
            item '0F6A';
            item '1089';
            item '115C';
            item '1202';
            item '1322';
            item '14F8';
            item '1556';
            item '1916';
            item '1B43';
            item '1C68';
			end();
		};
		etc();
	};
	field '101' => hash {
		field modulation => '2-FSK';
		field register => array { 
	      item '0001';
          item '0246';
          item '0307';
          item '042D';
          item '05D4';
          item '06FF';
          item '0700';
          item '0802';
          item '0D21';
          item '0E6B';
          item '0FD0';
          item '1088';
          item '110B';
          item '1206';
          item '1322';
          item '14F8';
          item '1553';
          item '1700';
          item '1818';
          item '1916';
          item '1B43';
          item '1C68';
          item '1D91';
          item '23ED';
          item '2517';
          item '2611';
		  end();
		};
		etc();
	};
	field '102' => hash {
		field modulation => 'GFSK';
		field register => array { 
            item '0001';
            item '012E';
            item '0246';
            item '0304';
            item '04AA';
            item '0554';
            item '060F';
            item '07E0';
            item '0800';
            item '0900';
            item '0A00';
            item '0B06';
            item '0C00';
            item '0D21';
            item '0E65';
            item '0F6A';
            item '1097';
            item '1183';
            item '1216';
            item '1363';
            item '14B9';
            item '1547';
            item '1607';
            item '170C';
            item '1829';
            item '1936';
            item '1A6C';
            item '1B07';
            item '1C40';
            item '1D91';
            item '1E87';
            item '1F6B';
            item '20F8';
            item '2156';
            item '2211';
            item '23EF';
            item '240A';
            item '253D';
            item '261F';
            item '2741';
 		    end();
		};
		etc();
	};	
	field '103' => hash {
		field modulation => '2-FSK';
		field register => array { 
            item '0001';
            item '022E';
            item '0341';
            item '042D';
            item '05D4';
            item '0605';
            item '0780';
            item '0800';
            item '0D21';
            item '0E65';
            item '0F6A';
            item '10C8';
            item '1183';
            item '1202';
            item '1322';
            item '14F8';
            item '1542';
            item '1916';
            item '1B43';
            item '1C68';
 		    end();
		};
		etc();
	};	
	etc();
};

plan(3);

is(%lib::SD_ProtocolData::protocols,D(),q[%protocols is defined]);
is(\%lib::SD_ProtocolData::protocols,$check_hash,q[%protocols meets criteria]);

subtest '%protocols sanity check' => sub {
  foreach my $key ( sort keys %lib::SD_ProtocolData::protocols ) {
    is($lib::SD_ProtocolData::protocols->{$key},$validFSKcheck,qq[register set where modulation is 2-FSK $key]);
  }
};

done_testing();
exit(0);
