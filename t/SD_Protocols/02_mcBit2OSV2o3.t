#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{is};
use Test2::Todo;

plan(2);

my $id=5010;
my ($rcode,$hexresult);
my $Protocols =
  new lib::SD_Protocols( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );

# Mock protocol for this test
$Protocols->{_protocols}->{5010}{length_min} = 64;
$Protocols->{_protocols}->{5010}{length_max} = 220;

subtest 'OSV2 Tests' => sub {
	plan(6);

	my $bitdata='1010101010101010101010101010101011001100101011001101001010110010101011010011001100101101001101010101001101001011001101001011010101010101010100110101001100101011001101010111';				
	($rcode,$hexresult) = $Protocols->mcBit2OSV2o3(undef,$bitdata,$id,length $bitdata);
	is($rcode,1,'check returncode for single OSV2 transmission');
	is($hexresult,'44BADC5313641940741','check result for single OSV2 transmission');
	
	my $todo = Test2::Todo->new(reason => 'need other osv2 cases');

		$bitdata='010101010110011001010110011010010101100101010110100110011001011010011010101010011010010110011010010110101010101010101001101010011001010110011010101111010101010101010101010101010101011001100101011001101001010110010101011010011001100101101001101010101001101001011001101001011010101010101010100110101001100101011001101010111';				
		($rcode,$hexresult)=$Protocols->mcBit2OSV2o3(undef,$bitdata,$id,length $bitdata);
		is($rcode,1,'check returncode for first incomplete and second complete OSV2 transmission');
		is($hexresult,'44BADC5313641940741','check result for incomplete and second complete OSV2 transmission');

		$bitdata='10101010101010101010101010101010110011001010110011010010101100101010110100110011001011010011010101010011010010110011010010110101010101010101001101010011001010110011010101111010101010101010101010101010101011001100101011001101001010110010101011010011001100101101001101010101001101001011001101001011010101010101010100110101001100101011001101010111';				
		($rcode,$hexresult)=$Protocols->mcBit2OSV2o3(undef,$bitdata,$id,length $bitdata);
		is($rcode,1,'check returncode for double OSV2 transmission');
		is($hexresult,'44BADC5313641940741','check result for double OSV2 transmission');

	$todo->end;
	
};

subtest 'OSV3 Tests' => sub {
	plan(12);
	
	my $bitdata='11111111111111010111110001010000101000100000100000110000000100000001000010000001110100100011001';
	($rcode,$hexresult)=$Protocols->mcBit2OSV2o3(undef,$bitdata,$id,length $bitdata);
	is($rcode,1,'check result for single OSV3 transmission');
	is($hexresult,'50FA281441302020042E31','check result for single OSV3 transmission');

	$bitdata='11111111111111010111110001010000101000100000100000110000000100000001000010000001110100100011001111111111111111111111110101111100010100001010001000001000';
	($rcode,$hexresult)=$Protocols->mcBit2OSV2o3(undef,$bitdata,$id,length $bitdata);
	is($rcode,1,'check result for seconds OSV3 transmission to short');
	is($hexresult,'50FA281441302020042E31','check result for seconds OSV3 transmission to short');

	$bitdata='01010000101000100000100000110000000100000001000010000001110100100011001111111111111111111111110101111100010100001010001000001000001100000001000000010000100000011101001000110011';
	
	($rcode,$hexresult)=$Protocols->mcBit2OSV2o3(undef,$bitdata,$id,length $bitdata);
	is($rcode,1,'check result for first is incomplete, seconds OSV3 transmission is okay');
	is($hexresult,'50FA281441302020042E31','check result for first is incomplete, seconds OSV3 transmission is okay');

	$bitdata='01010000101000100000100000110000000100000001000010000001110100100011001111111111111111111111110101111100010100001010001000001000001100000001000000010000100000011101001000110011';
	
	($rcode,$hexresult)=$Protocols->mcBit2OSV2o3(undef,,$bitdata,$id,length $bitdata);
	is($rcode,1,'check result for two complete transmissions');
	is($hexresult,'50FA281441302020042E31','check result for two complete transmissions');

	$bitdata='11111111111010111110001010000101000100000100000110000000100000001000010000001110100100011001111111111111111111111110101111100010100001010001000001000';
	($rcode,$hexresult)=$Protocols->mcBit2OSV2o3(undef,$bitdata,$id,length $bitdata);
	is($rcode,-1,'check result first preamble to short second message to short');
	isnt($hexresult,'50FA281441302020042E31','check result first preamble to short second message to short');
	
	my $todo = Test2::Todo->new(reason => 'codechange needed to detect second message');
	
		$bitdata='11111111111111010111110001010000101000100011001111111111111111111111110101111100010100001010001000001000001100000001000000010000100000011101001000110011';
		($rcode,$hexresult)=$Protocols->mcBit2OSV2o3(undef,$bitdata,$id,length $bitdata);
		is($rcode,1,'check result first transmission to short second message is okay');
		is($hexresult,'50FA281441302020042E31','heck result first transmission to short second message is okay');

	$todo->end;

};