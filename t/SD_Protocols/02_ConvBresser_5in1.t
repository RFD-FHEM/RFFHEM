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

subtest 'test ConvBresser_5in1, checksum ok ' => sub 	{
    my $hexMsg='E7527FF78FF7EFF8FDD7BBCAFF18AD80087008100702284435000002';
    plan(2);
    my @ret=$Protocols->ConvBresser_5in1($hexMsg) ;
    is($#ret,0, 'ConvBresser_5in1 reported no error');
    is($ret[0],'AD8008700810070228443500','check retured message');

};

subtest 'test ConvBresser_5in1, inverted data' => sub 	{
	plan(2);
	my $hexMsg='E7527FF78FF7EFF7FDD7BBCAFF18AD80087008100702284435000002';
	my @ret=$Protocols->ConvBresser_5in1($hexMsg) ;
	is($#ret,1, "ConvBresser_5in1 reported some error");
	like($ret[1],qr/inverted data at pos/,'check error message');
};

subtest 'test ConvBresser_5in1, wrong checksum ' => sub 	{
	plan(2);
	my $hexMsg='E8837FFF1FFFEFEAFF6989FF07177C8000E000101500967600F80001';
	my @ret=$Protocols->ConvBresser_5in1($hexMsg) ;
	is($#ret,1, "ConvBresser_5in1 reported some error");
	like($ret[1],qr/ != checksum/,'check error message');
};



subtest 'test ConvBresser_5in1, length to short ' => sub 	{
	plan(2);
	my $hexMsg='E7527FF78FF7EFF8FDD7BBCAFF18AD800870081007022844350';
	my @ret=$Protocols->ConvBresser_5in1($hexMsg) ;
	is($#ret,1, "ConvBresser_5in1 reported some error");
	like($ret[1],qr/to short/,'check error message');
};
