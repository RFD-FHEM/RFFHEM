#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{ is };


my $Protocols =
	new lib::SD_Protocols( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );
my $target='some_device_name';


my $output;
my $rcode;


plan(2);

my @bits=qw(0 1 0 0 0 1 0 1 0 1 0 0 1 0 1 0 1 0 0 0 0 1 0 0 0 1 1 1 1 0 1 1 1 1 0 1 0 1 1 1 0);
note('calculates the hex (in bits) and adds it at the beginning of the message');
note("input @bits");

($rcode,@bits)=$Protocols->postDemo_lengtnPrefix($target,@bits);
is($rcode,1,'check returncode for X10 transmission');
note("output @bits");
is(join("",@bits),'0010100101000101010010101000010001111011110101110','check result X10 transmission');

