#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{is};
use Test2::Todo;

plan(4);

my $id=5052;
my ($rcode,$hexresult);
my $Protocols =
  new lib::SD_Protocols( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );

# Mock protocol for this test
$Protocols->{_protocols}->{5052}{length_min} = 30;
$Protocols->{_protocols}->{5052}{length_max} = 30;


subtest 'valid Oregon PIR header detected 0{14}' => sub {
	plan(2);

	my $bitdata='00000000000000010010101011100111';

	($rcode,$hexresult)=$Protocols->mcBit2OSPIR(undef,$bitdata,$id,length $bitdata);
	is($rcode,1,'check returncode for single Oregon PIR transmission');
	is($hexresult,'00012AE7','check result for single Oregon PIR transmission');			
};


subtest 'valid Oregon PIR header detected 1{14}' => sub {
	plan(2);

	my $bitdata='11111111111111110010101011100111';

	($rcode,$hexresult)=$Protocols->mcBit2OSPIR(undef,$bitdata,$id,length $bitdata);
	is($rcode,1,'check returncode for single Oregon PIR transmission');
	is($hexresult,'FFFF2AE7','check result for single HOregon PIRideki transmission');			
};


subtest 'no Oregon PIR header found' => sub {
	plan(2);

	my $bitdata='11000000000000010010101011100111';

	($rcode,$hexresult)=$Protocols->mcBit2OSPIR(undef,$bitdata,$id,length $bitdata);
	is($rcode,-1,'check returncode for single Oregon PIR transmission');
	is($hexresult,U(),'check result for Oregon PIR message to short');
};

my $todo = Test2::Todo->new(reason => 'Max Length is currently not checked');

subtest 'message is to long' => sub {
	plan(2);

	my $bitdata='000000000000000100101010111001110000000000000001001010101110011100000000000000010010101011100111';

	($rcode,$hexresult)=$Protocols->mcBit2OSPIR(undef,$bitdata,$id,length $bitdata);
	is($rcode,-1,'check returncode for long Oregon PIR transmission');
	is($hexresult,' message is to long','check result for Oregon PIR message to long');
};

$todo->end;
