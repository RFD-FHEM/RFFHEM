#!/usr/bin/env perl
use strict;
use warnings;
BEGIN { $ENV{PERL_JSON_BACKEND}='JSON::backportPP'; }

use Test2::V0;
use Test2::Tools::Class;
use lib::SD_Protocols qw(:ALL);
use Test2::Tools::Exception qw/dies lives/;
use Test2::Tools::Compare qw{hash bag is like};

my $className = 'lib::SD_Protocols';


subtest 'lib SD_Prococols test sub LoadHash() ' => sub {
	plan(5);
	my $Protocols = new $className( filename => './dummyDefault.pm' );
	my $ret = undef;

	is( $Protocols->{_protocolFilename},
		'./dummyDefault.pm', 'check internal filename variable' );

	$ret = $Protocols->LoadHash(' ');
	like( $ret, qr/does not exists/, 'use default, wrong filename' );

	$ret = $Protocols->LoadHash('customDummy.pm');
	like( $ret, qr/does not exists/, 'wrong costum filename' );

	$ret = $Protocols->LoadHash(
		'./t/SD_Protocols/test_loadprotohash-nok.pm');
	like( $ret, qr/syntax error at/, 'file with syntax error' );

	$ret = $Protocols->LoadHash(
		'./t/SD_Protocols/test_loadprotohash-ok.pm');
	is( $ret, U(), 'valid file without errors');
};

subtest 'lib SD_Prococols test sub new() ' => sub {
	plan(3);
	my $Protocols = new $className( filename => './dummyDefault.pm' );
	is( $Protocols->{_protocols}, U(), 'wrong filename' );

	$Protocols =
	  new $className( filename => './t/SD_Protocols/test_loadprotohash-nok.pm' );
	is( $Protocols->{_protocols}, U(), 'file with syntax error' );

	$Protocols =
	  new $className( filename => './t/SD_Protocols/test_loadprotohash-ok.pm' );
	ref_ok( $Protocols->{_protocols}, 'HASH', 'valid file without errors' );
};


subtest 'lib SD_Prococols protocolExists()' => sub {


	subtest 'from json' => sub {
		plan(5);
		my $Protocols =
		  new $className( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );
		is($Protocols->{_protocols},hash { field '9999' => T(); etc();},"Verify we have a hash loaded",diag $Protocols->{_protocols});
	    like(warning { $Protocols->protocolExists() },qr/Illegal parameter number, protocol id was not specified/,'check warning on missing parameter');
	
		ok($Protocols->protocolExists(9999),'check existing protocol ID');
		ok(!$Protocols->protocolExists(10),'check not existing protocol ID');
		like($Protocols->{_protocols}->{9999}{name},qr/Unittest/,"valid element hashref");
	};

	subtest 'from PerlModule' => sub {
		plan(5);
		my $Protocols =
		  new $className( filename => './t/SD_Protocols/test_loadprotohash-ok.pm' );
		is($Protocols->{_protocols},hash { field '9999' => T(); etc();},"Verify we have a hash loaded");
	    like(warning { $Protocols->protocolExists() },qr/Illegal parameter number, protocol id was not specified/,'check warning on missing parameter');
	
		ok($Protocols->protocolExists(9999),'check existing protocol ID');
		ok(!$Protocols->protocolExists(10),'check not existing protocol ID');
		like($Protocols->{_protocols}->{9999}{name},qr/Unittest/,"valid element hashref");
	};
	
};

subtest 'lib SD_Prococols getProtocolList()' => sub {
	plan(2);
	my $Protocols =
	  new $className( filename => './t/SD_Protocols/test_loadprotohash-ok.pm' );

	ref_ok($Protocols->getProtocolList, 'HASH', 'verify we got a hashref' );
	is($Protocols->getProtocolList,hash { 
	    field '9999' => T(); 
	    field '9987' => T();
	    etc();
	  },
	  "Verify we have got a hash with keys 9999, 9987");

};


subtest 'lib SD_Prococols getKeys()' => sub {
	plan(2);
	my $todo = todo 'here is a bug in getkeys i think';
	my $Protocols =
	new $className( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );


	my (@key_list) = $Protocols->getKeys;
	ref_ok(\@key_list , 'ARRAY', 'verify we got an array' );
	is(\@key_list ,bag { 
	    item '9999' => T(); 
	    item '9987' => T();
	    etc();
	  },
	  "Verify we have got a array with items 9999, 9987");

};


subtest 'lib SD_Prococols checkProperty()' => sub {
	plan(7);
	my $Protocols =
	  new $className( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );

	is($Protocols->checkProperty(9999,'developId'),'m','verify existing property is received without default');
	is($Protocols->checkProperty(9999,'developId','p'),'m','verify existing property is received with default');
	is($Protocols->checkProperty(9999,'bla','p'),'p','verify not existing property is received with default');
	is($Protocols->checkProperty(9999,'bla'),U(),'verify not existing property is received with undef default');
	is($Protocols->checkProperty(10,'developId'),U(),'verify not existing id returns undef');

	is($Protocols->checkProperty(10),U(),'verify returns undef with only one arg');
	is($Protocols->checkProperty(),U(),'verify returns undef with no arg');


};

subtest 'lib SD_Prococols getProperty()' => sub {
	plan(7);
	my $Protocols =
	  new $className( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );
	
	is($Protocols->getProperty(9999,'developId'),'m','verify existing property is received without default');
	is($Protocols->getProperty(9999,'bla'),U(),'verify not existing property is received with undef default');
	is($Protocols->getProperty(10,'developId'),U(),'verify not existing id returns undef');
	
	is($Protocols->getProperty(10),U(),'verify returns undef with only one arg');
	is($Protocols->getProperty(),U(),'verify returns undef with no arg');
	
	ok(defined($Protocols->getProperty(9991,'clockabs')),'verify clockabs can be retrieved');
	delete($Protocols->{_protocols}->{9991}->{clockabs});
	ok(!defined($Protocols->getProperty(9991,'clockabs')),'verify clockabs brings undef after deletion');
	
};

subtest 'lib SD_Prococols getProtocolVersion()' => sub {
	plan(1);
	my $Protocols =
	  new $className( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );

	is($Protocols->getProtocolVersion,'0.1','verify versionstring');
};

subtest 'lib SD_Prococols setDefaults()' => sub {
	plan(3);
	my $Protocols =
	  new $className( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );
	# Mock some Data

	subtest 'length_min default if clockabs is set' => sub {
		plan(2);
		delete($Protocols->{_protocols}->{9991}->{length_min});
		is($Protocols->setDefaults,U(),'verify return value');
		is($Protocols->{_protocols}->{9991}->{length_min},8,'verify length_min for 9991');
	};

	subtest 'method default for MC protocol' => sub {
		plan(3);
		delete($Protocols->{_protocols}->{9989}->{method});
		is($Protocols->setDefaults,U(),'verify return value');
		ref_ok($Protocols->{_protocols}->{9989}->{method},'CODE','verify method is a coderef now');
		is($Protocols->{_protocols}->{9989}->{method},\&lib::SD_Protocols::MCRAW,'verify method is default coderef');
	};
	subtest 'method explicit specified' => sub {
		plan(3);
		$Protocols->{_protocols}->{9989}->{method}='lib::SD_Protocols::ConvHE800';
		is($Protocols->setDefaults,U(),'verify return value');
		ref_ok($Protocols->{_protocols}->{9989}->{method},'CODE','verify method is a coderef now');
		is($Protocols->{_protocols}->{9989}->{method},\&lib::SD_Protocols::ConvHE800,'verify method is ConvHE800 coderef');
	};	
};





done_testing();

