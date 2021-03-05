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


subtest 'test ConvLaCrosse, checksum ok' => sub 	{
	plan(2);
	subtest 'msg 9AA6362CC8AAAA000012F8F4 (ID 100)' => sub {		
		plan(2);
		my $hexMsg='9AA6362CC8AAAA000012F8F4';
		my @ret=$Protocols->ConvLaCrosse($hexMsg) ;
		is($#ret,0, 'ConvLaCrosse reported no error');
		is($ret[0],'OK 9 42 129 4 212 44','check result for right Lacrosse transmission');
	};
	
	subtest 'msg 9A05922F8180046818480800 (ID 103)' => sub {		
		plan(2);
		my $hexMsg='9A05922F8180046818480800';
		my @ret=$Protocols->ConvLaCrosse($hexMsg) ;
		is($#ret,0, 'ConvLaCrosse reported no error');
		is($ret[0],'OK 9 40 1 4 168 47','check result for right Lacrosse transmission');
	};
};


subtest 'test ConvLaCrosse, checksum wrong' => sub 	{
	plan(2);
	subtest 'msg 9AA6362CC8AAAA000012F8F4 (ID 100)' => sub {		
		plan(2);
		my $hexMsg='9BA6362CC8AAAA000012F8F4';
		my @ret=$Protocols->ConvLaCrosse($hexMsg) ;
		is($#ret,1, "ConvLaCrosse reported some error");
		like($ret[1],qr/!= checksum/,'check error message');
	};
	
	subtest 'msg 9B05922F8180046818480800 (ID 103)' => sub {		
		plan(2);
		my $hexMsg='9B05922F8180046818480800';
		my @ret=$Protocols->ConvLaCrosse($hexMsg) ;
		is($#ret,1, 'ConvLaCrosse reported some error');
		like($ret[1],qr/!= checksum/,'check error message');
	}
};


subtest 'test ConvLaCrosse, length to short ' => sub 	{
	plan(2);
	my $hexMsg='0105A';
	my @ret=$Protocols->ConvLaCrosse($hexMsg) ;
	is($#ret,1, "ConvLaCrosse reported some error");
	like($ret[1],qr/at least \d* chars/,'check error message');
};


subtest 'test ConvLaCrosse, not hexadezimal' => sub 	{
	plan(2);
	my $hexMsg='010503B7PA1041AAAAAAAAPF';
	my @ret=$Protocols->ConvLaCrosse($hexMsg) ;
	is($#ret,1, "ConvLaCrosse reported some error");
	like($ret[1],qr/!= checksum/,'check error message');
};
