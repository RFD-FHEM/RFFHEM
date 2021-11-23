#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols qw(:ALL);
use Test2::Tools::Compare qw{is like};
use Test2::Todo;

plan(4);

my $Protocols =
  new lib::SD_Protocols( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );

subtest 'test ConvBresser_6in1, checksum ok ' => sub 	{
    my $hexMsg='3BF120B00C1618FF77FF0458152293FFF06B0000';
    plan(2);
    my @ret=$Protocols->ConvBresser_6in1($hexMsg) ;
    is($#ret,0, 'ConvBresser_6in1 reported no error');
    is($ret[0],'3BF120B00C1618FF77FF0458152293FFF06B0000','check retured message');

};

subtest 'test ConvBresser_6in1, wrong checksum ' => sub 	{
	plan(2);
	my $hexMsg='3AF120B00C1618FF77FF0458152293FFF06B0000';
	my @ret=$Protocols->ConvBresser_6in1($hexMsg) ;
	is($#ret,1, "ConvBresser_6in1 reported some error");
	like($ret[1],qr/ != checksum/,'check error message');
};

subtest 'test ConvBresser_6in1, wrong sum ' => sub 	{
	plan(2);
	my $hexMsg='FD0620A00C1618FF77FF0458152293FFF06B0000';
	my @ret=$Protocols->ConvBresser_6in1($hexMsg) ;
	is($#ret,1, "ConvBresser_6in1 reported some error");
	like($ret[1],qr/ != 255/,'check error message');
};


subtest 'test ConvBresser_6in1, length to short ' => sub 	{
	plan(2);
	my $hexMsg='E7527FF78FF7EFF8FDD7';
	my @ret=$Protocols->ConvBresser_6in1($hexMsg) ;
	is($#ret,1, "ConvBresser_6in1 reported some error");
	like($ret[1],qr/to short/,'check error message');
};
