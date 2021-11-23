#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{is};
use Test2::Todo;

plan(4);

my $id=5043;
my ($rcode,$hexresult);
my $Protocols =
  new lib::SD_Protocols( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );

# Mock protocol for this test
$Protocols->{_protocols}->{5043}{length_min} = 56;
$Protocols->{_protocols}->{5043}{length_max} = 57;


my $target = undef;

subtest 'mcbitnum != 57' => sub {
	plan(2);
	my $bitdata='10011000110110111101000101010011110101100011000110111011';

	($rcode,$hexresult)=$Protocols->mcBit2SomfyRTS($target,$bitdata,$id,length $bitdata);
	is($rcode,1,"check returncode for SomfyRTS transmission");
	is($hexresult,'98DBD153D631BB','check result SomfyRTS');
};


subtest 'mcbitnum == 57' => sub {
	plan(2);
	my $bitdata='110011000110110111101000101010011110101100011000110111011';

	($rcode,$hexresult)=$Protocols->mcBit2SomfyRTS($target,$bitdata,$id,length $bitdata);
	is($rcode,1,"check returncode for SomfyRTS transmission");
	is($hexresult,'98DBD153D631BB','check result SomfyRTS');
};


subtest 'mcbitnum not defined' => sub {
	plan(2);
	my $bitdata='10011000110110111101000101010011110101100011000110111011';

	($rcode,$hexresult)=$Protocols->mcBit2SomfyRTS($target,$bitdata,$id,undef);
	is($rcode,1,"check returncode for SomfyRTS transmission");
	is($hexresult,'98DBD153D631BB','check result SomfyRTS');
};

my $todo = Test2::Todo->new(reason => 'needs some code enhancement');

subtest 'message to long' => sub {
	plan(2);
	my $bitdata='100110001101101111010001010100111101011000110001101110111010';

	($rcode,$hexresult)=$Protocols->mcBit2SomfyRTS($target,$bitdata,$id,undef);
	is($rcode,-1,"check returncode for SomfyRTS transmission");
	is($hexresult,U(),'check result SomfyRTS');
};
$todo->end;

