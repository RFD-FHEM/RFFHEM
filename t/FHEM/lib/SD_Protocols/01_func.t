#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Class;
use lib::SD_Protocols qw(:ALL);
use Test2::Tools::Exception qw/dies lives/;

my $className = 'lib::SD_Protocols';

subtest 'lib SD_Prococols test sub LoadHash() ' => sub {
	plan(5);
	my $Protocols = new $className( filename => './dummyDefault.pm' );
	my $ret = undef;

	is( $Protocols->{_protocolFilename},
		'./dummyDefault.pm', 'check internal filename variable' );

	$ret = $Protocols->LoadHash(' ');
	like( $ret, qr/does not exsits/, 'use default, wrong filename' );

	$ret = $Protocols->LoadHash('customDummy.pm');
	like( $ret, qr/does not exsits/, 'wrong costum filename' );

	$ret = $Protocols->LoadHash(
		'./t/FHEM/lib/SD_Protocols/test_loadprotohash-nok.pm');
	like( $ret, qr/syntax error at/, 'file with syntax error' );

	$ret = $Protocols->LoadHash(
		'./t/FHEM/lib/SD_Protocols/test_loadprotohash-ok.pm');
	is( $ret, U(), 'valid file without errors' );
};

subtest 'lib SD_Prococols test sub new() ' => sub {
	plan(3);
	my $Protocols = new $className( filename => './dummyDefault.pm' );
	is( $Protocols->{_protocols}, U(), 'wrong filename' );

	$Protocols =
	  new $className( filename => './t/FHEM/lib/SD_Protocols/test_loadprotohash-nok.pm' );
	is( $Protocols->{_protocols}, U(), 'file with syntax error' );

	$Protocols =
	  new $className( filename => './t/FHEM/lib/SD_Protocols/test_loadprotohash-ok.pm' );
	ref_ok( $Protocols->{_protocols}, 'HASH', 'valid file without errors' );
};


subtest 'lib SD_Prococols protocolExists' => sub {
	plan(3);
	my $Protocols =
	  new $className( filename => './t/FHEM/lib/SD_Protocols/test_loadprotohash-ok.pm' );

    like(warning { $Protocols->protocolExists() },qr/Illegal parameter number, protocol id was not specified/,'check warning on missing parameter');

	ok($Protocols->protocolExists(9999),'check existing protocol ID');
#	ok($Protocols->protocolExists(10),'check not existing protocol ID');

	like($Protocols->{_protocols}->{9999}{name},qr/Unittest/,"valid element hashref");

	#is($ret->{error},undef,"valid file error check");
};
done_testing();
