use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{ like unlike };
our %defs;

InternalTimer(time()+1, sub {
	plan(2);
    my $target='dummyDuino';
    my $targetHash = $defs{$target};


	subtest 'Test ccregAll response' => sub {
		plan(5);

		my ($ret)=SIGNALduino_CheckCcregResponse($targetHash,"ccreg 00: 0D 2E 2D 47 D3 91 3D 04 32 00 00 06 00 10 B0 71 ccreg 10: 57 C4 30 23 B9 00 07 00 18 14 6C 07 00 91 87 6B ccreg 20: F8 B6 11 EF 0C 3C 1F 41");
		like($ret,qr/^Configuration register overview:/m,"check begin of return message");
		like($ret,qr/^0x0D/m,"check first part of return message");
		like($ret,qr/57$/m,"check second part of return message");
		like($ret,qr/MDMCFG2/m,"check registername in output");
		like($ret,qr/^Configuration register detail:/m,"check heading - Detail part of return message");
	}; 

	subtest 'Test ccreg 12 response (C12 = 30)' => sub {
		plan(4);

		my ($ret)=SIGNALduino_CheckCcregResponse($targetHash,"C12 = 30");
		like($ret,qr/^Configuration register detail:/m,"check begin of return message");
		like($ret,qr/^0x12/m,"begin of detail line in output");
		like($ret,qr/MDMCFG2/m,"check registername in output");
		like($ret,qr/0x30/m,"check registervalue in output");
	}; 
    exit(0);
}, 0);

1;