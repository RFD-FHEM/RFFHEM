#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{is};
use Carp qw(croak carp);

my $Protocols =
new lib::SD_Protocols( filetype => 'json', filename => './t/sssSD_Protocols/test_protocolData.json' );


plan(1);

my $blkctrInternal = '00';
my $Keycode        = '00';
my $TransCode1     = 'C2AD';
my $TransCode2     = '03';

note('example: KOPP_FC good input with calculated checksum');
my $return = $Protocols->PreparingSend_KOPP_FC($blkctrInternal, $Keycode, $TransCode1, $TransCode2);
is($return,'SN;R=13;N=4;D=07C2AD0000CC0F0302000000000000;','check function and result good input');
