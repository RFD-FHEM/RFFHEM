#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{ is };

our %defs;
our %attr;


InternalTimer(time(), sub {
    my $target='dummyDuino';
    my $targetHash = $defs{$target};

	my $savedFreq = AttrVal($target,"cc1101_frequency",undef);
	plan(4);

	subtest 'Test ccPatable response default Mhz (C3E = 00 84 00 00 00 00 00 00)' => sub {
		plan(2);
		delete($attr{$target}{cc1101_frequency});
		my ($ret)=SIGNALduino_CheckccPatableResponse ($targetHash,"C3E = 00 84 00 00 00 00 00 00");
		is($ret,"C3E = 00 84 00 00 00 00 00 00 => 5_dBm","check return value");
		is (ReadingsVal($target,"cc1101_patable",undef),"C3E = 00 84 00 00 00 00 00 00 => 5_dBm", "check reading value");
	};
	
	subtest "Test ccPatable 433 Mhz Range " => sub {
		foreach my $i (433..435) {
			subtest "Test ccPatable response $i Mhz (C3E = 00 84 00 00 00 00 00 00)" => sub {
				plan(2);
			
				$attr{$target}{cc1101_frequency} = $i;
				my ($ret)=SIGNALduino_CheckccPatableResponse ($targetHash,"C3E = 00 84 00 00 00 00 00 00");
				is($ret,"C3E = 00 84 00 00 00 00 00 00 => 5_dBm","check return value");
				is (ReadingsVal($target,"cc1101_patable",undef),"C3E = 00 84 00 00 00 00 00 00 => 5_dBm", "check reading value");
			};
		};
	};	

	subtest "Test ccPatable 868 Mhz Range " => sub {
		foreach my $i (863..870) {
			subtest "Test ccPatable response $i Mhz (C3E = 00 67 00 00 00 00 00 00)" => sub {
				plan(2);
			
				$attr{$target}{cc1101_frequency} = $i;
				my ($ret)=SIGNALduino_CheckccPatableResponse ($targetHash,"C3E = 00 67 00 00 00 00 00 00");
				is($ret,"C3E = 00 67 00 00 00 00 00 00 => -5_dBm","check return value");
				is (ReadingsVal($target,"cc1101_patable",undef),"C3E = 00 67 00 00 00 00 00 00 => -5_dBm", "check reading value");
			};
		};
	};	

	subtest "Test ccPatable unsupported values " => sub {
		subtest 'Test ccPatable 900 Mhz ' => sub {
			plan(2);
			$attr{$target}{cc1101_frequency} = 900;
			my ($ret)=SIGNALduino_CheckccPatableResponse ($targetHash,"C3E = 00 84 00 00 00 00 00 00");
			is($ret,"C3E = 00 84 00 00 00 00 00 00","check return value");
			is (ReadingsVal($target,"cc1101_patable",undef),"C3E = 00 84 00 00 00 00 00 00", "check reading value");
		};
	};

	$attr{$target}{cc1101_frequency} = $savedFreq if(defined($savedFreq));
	delete($attr{$target}{cc1101_frequency}) if(! defined($savedFreq));

    exit(0);
}, 0);

1;