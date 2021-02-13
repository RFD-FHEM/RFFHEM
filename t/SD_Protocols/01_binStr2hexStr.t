#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{is like};

my $obj = new lib::SD_Protocols();


plan(2);
subtest 'called as function' => sub {
	plan(9);
		
	is(lib::SD_Protocols::binStr2hexStr('1111'),'F','verify F returned for b1111');
	is(lib::SD_Protocols::binStr2hexStr('1010'),'A','verify A returned for b1010');
	is(lib::SD_Protocols::binStr2hexStr('101011111010'),'AFA','verify A returned for b1010');
	is(lib::SD_Protocols::binStr2hexStr('11'),'3','verify C returned for b11');
	is(lib::SD_Protocols::binStr2hexStr('0000'),'0','verify C returned for b11');
	is(lib::SD_Protocols::binStr2hexStr('00000000'),'00','verify C returned for b11');
	is(lib::SD_Protocols::binStr2hexStr('0x00000000'),U(),'verify undef returned for not binary number');
	is(lib::SD_Protocols::binStr2hexStr('00000002'),U(),'verify undef returned for not binary number');
	is(lib::SD_Protocols::binStr2hexStr('111100001111000011110000111100001111000011110000111100001111000011110000111100001111000011110000111100001111000011110000111100001111000011110000111100001111000011110000111100001111000011110000'),'F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0','verify super long binary ');
};

subtest 'called as method' => sub {
	plan(9);
		
	is($obj->binStr2hexStr('1111'),'F','verify F returned for b1111');
	is($obj->binStr2hexStr('1010'),'A','verify A returned for b1010');
	is($obj->binStr2hexStr('101011111010'),'AFA','verify A returned for b1010');
	is($obj->binStr2hexStr('11'),'3','verify C returned for b11');
	is($obj->binStr2hexStr('0000'),'0','verify C returned for b11');
	is($obj->binStr2hexStr('00000000'),'00','verify C returned for b11');
	is($obj->binStr2hexStr('0x00000000'),U(),'verify undef returned for not binary number');
	is($obj->binStr2hexStr('00000002'),U(),'verify undef returned for not binary number');
	is($obj->binStr2hexStr('111100001111000011110000111100001111000011110000111100001111000011110000111100001111000011110000111100001111000011110000111100001111000011110000111100001111000011110000111100001111000011110000'),'F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0','verify super long binary ');
};