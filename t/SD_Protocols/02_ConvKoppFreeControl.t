#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols qw(:ALL);
use Test2::Tools::Compare qw{is like};

plan(2);

my $Protocols =
  new lib::SD_Protocols( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );

subtest 'test ConvKoppFreeControl, checksum ok' => sub 	{
	plan(1);
	subtest 'msg MN;D=07FA5E1721CC0F02FE000000000000; (ID 102)' => sub {		
		my $hexMsg='07FA5E1721CC0F02FE000000000000';
		plan(2);
		my @ret=$Protocols->ConvKoppFreeControl($hexMsg) ;
		is($#ret,0, 'ConvKoppFreeControl reported no error');
		is($ret[0],'kr07FA5E1721CC0F02','check result for right KoppFreeControl transmission',@ret);
	};
};


subtest 'test ConvKoppFreeControl, checksum wrong' => sub 	{
	plan(1);
	subtest 'msg MN;D=07FF5E1721CC0F02FE000000000000 (ID 102)' => sub {		
		plan(2);
		my $hexMsg='07FF5E1721CC0F02FE000000000000';
		my @ret=$Protocols->ConvKoppFreeControl($hexMsg) ;
		is($#ret,1, 'ConvKoppFreeControl reported some error');
		like($ret[1],qr/!= checksum/,'check error message');
	}
};
