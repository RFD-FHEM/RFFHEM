#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols qw(:ALL);
use Test2::Tools::Compare qw{is like};

plan(4);

# note: ConvPCA301 use Digest::CRC
my $Protocols =
  new lib::SD_Protocols( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );

subtest 'test ConvPCA301, checksum ok ' => sub 	{
	plan(2);
	subtest 'msg MN;D=010503B7A101AAAAAAAA7492AA9885E53246E91113F897A4F80D30C8DE602BDF' => sub {		
		my $hexMsg='010503B7A101AAAAAAAA7492AA9885E53246E91113F897A4F80D30C8DE602BDF';
		plan(2);
		my @ret=$Protocols->ConvPCA301($hexMsg) ;
		is($#ret,0, 'ID101_2_PCA301 reported no error');
		is($ret[0],'OK 24 1 5 3 183 161 1 170 170 170 170 7492','check retured message');
	};

	subtest 'msg MN;D=0405019E8700AAAAAAAA0F13AA16ACC0540AAA49C814473A2774D208AC0B0167;N=3;R=6;' => sub {		
		my $hexMsg='0405019E8700AAAAAAAA0F13AA16ACC0540AAA49C814473A2774D208AC0B0167';
		plan(2);
		my @ret=$Protocols->ConvPCA301($hexMsg) ;
		is($#ret,0, 'ID101_2_PCA301 reported no error');
		is($ret[0],'OK 24 4 5 1 158 135 0 170 170 170 170 0F13','check retured message');
	};
};


subtest 'test ConvPCA301, checksum wrong ' => sub 	{
	plan(2);
	my $hexMsg='010503B7A101AAAAAAAA74000A9885E53246E91113F897A4F80D30C8DE602BDF';
	my @ret=$Protocols->ConvPCA301($hexMsg) ;
	is($#ret,1, "ConvPCA301 reported some error");
	like($ret[1],qr/!= checksum/,'check error message');
};


subtest 'test ConvPCA301, length to short ' => sub 	{
	plan(2);
	my $hexMsg='010503B7A101AAAAAAAA';
	my @ret=$Protocols->ConvPCA301($hexMsg) ;
	is($#ret,1, "ConvPCA301 reported some error");
	like($ret[1],qr/at least/,'$Protocols->error message');
};


subtest 'test ConvPCA301, not hexadezimal' => sub 	{
	plan(2);
	my $hexMsg='010503B7PA1041AAAAAAAAPF';
	my @ret=$Protocols->ConvPCA301($hexMsg) ;
	is($#ret,1, "ConvPCA301 reported some error");
	like($ret[1],qr/!= checksum/,'check error message');
};

