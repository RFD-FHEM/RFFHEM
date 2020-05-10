#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{is isnt};

my $Protocols =
new lib::SD_Protocols( filetype => 'json', filename => './t/FHEM/lib/SD_Protocols/test_protocolData.json' );
	

my $rcode;
my $msg;
my @bits;


plan(4);

@bits=qw(0 1);
($rcode,@bits)=$Protocols->bit2Arctec(q[undef],@bits);
is($rcode,1,'check returncode from bit2Arctec');
is(join("",@bits),'0110','check result bit2Arctec');

@bits=qw(0 0 0 1 0 1 0 0 1 1 0 0 1 1 1 1 1 1 0 0 0 0 0 1 1 0 0 0 0 0 0 0);
($rcode,@bits)=$Protocols->bit2Arctec(q[undef],@bits);
is($rcode,1,'check returncode from bit2Arctec');
is(join("",@bits),'0101011001100101101001011010101010100101010101101001010101010101','check result bit2Arctec');

