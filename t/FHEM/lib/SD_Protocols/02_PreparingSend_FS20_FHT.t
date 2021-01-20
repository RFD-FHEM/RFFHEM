#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{is};

my $Protocols =
new lib::SD_Protocols( filetype => 'json', filename => './t/FHEM/lib/SD_Protocols/test_protocolData.json' );


plan(2);

my $id=73;
my $sum=12;
my $msg='202c4132';

note("example: FHT set to desired-temp 25.5");
my $newmsg=$Protocols->PreparingSend_FS20_FHT($id, $sum, $msg);
is($newmsg,'P73#00000000000010010000010010110010100000100011001011100101110P#R2','check result send newmsg');

note("example: FHT set manu-temp 11.0");
$msg='202c4516';
$newmsg=$Protocols->PreparingSend_FS20_FHT($id, $sum, $msg);
is($newmsg,'P73#00000000000010010000010010110010100010110001011011011001110P#R2','check result send newmsg');
