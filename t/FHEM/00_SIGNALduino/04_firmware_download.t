#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is like unlike};
use Test2::Mock;

use File::Basename;
our %defs;
our %attr;
#my $modpath= dirname($0);
#GlobalAttr('add',undef,'modpath',$modpath);
#CommandDefine(undef,'define WEB FHEMWEB 8083 global');


InternalTimer(time()+1, sub {
	my $target = shift;
	my $targetHash = $defs{$target};
	plan (15);	

	my $mock = Test2::Mock->new(
		track => 1,
		class => 'main'
	);	 	
	my $tracking = $mock->sub_tracking;

	my $path=dirname(__FILE__);

	$mock->override('HttpUtils_NonblockingGet' => sub {  } ) ;

	$targetHash->{additionalSets}{flash} = "r1.2.4";

	subtest 'flash without hardware parameter set' => sub {
		plan(2);
		$attr{$target}{hardware} = undef;
		my $ret = SIGNALduino_Set($targetHash, $target, "flash" ,"r1.2.4");
		like($ret,qr/Please define your hardware/,"return value from SIGNALduino_Set");
		is($tracking->{HttpUtils_NonblockingGet}, U(), "HttpUtils_NonblockingGet not called");
	}; 
	
	subtest 'flash with esp8266cc1101 hardware parameter set' => sub {
		plan(3);
		$mock->clear_sub_tracking();
		$attr{$target}{hardware} = "ESP8266cc1101";
		my $ret = SIGNALduino_Set($targetHash, $target, "flash" ,"r1.2.4");
		is($ret,undef,"return value from SIGNALduino_Set");
		is(scalar @{$tracking->{HttpUtils_NonblockingGet}}, 1, "HttpUtils_NonblockingGet not called");
	
		like( $tracking->{HttpUtils_NonblockingGet}[0]{args}[0]{url}, qr/SIGNALDuino/, "Download URL set to SIGNALDuino Repo" );
	}; 
	
	subtest 'flash with esp8266 hardware parameter set' => sub {
		plan(3);
		$attr{$target}{hardware} = "ESP8266";
		$mock->clear_sub_tracking();
		my $ret = SIGNALduino_Set($targetHash, $target, "flash" ,"r1.2.4");
		is($ret,undef,"return value fromSIGNALduino_Set");
		is(scalar @{$tracking->{HttpUtils_NonblockingGet}}, 1, "HttpUtils_NonblockingGet not called");
		like( $tracking->{HttpUtils_NonblockingGet}[0]{args}[0]{url}, qr/SIGNALDuino/, "Download URL set to SIGNALDuino Repo" );
	}; 
	
	subtest 'flash with nano hardware parameter set' => sub {
		plan(3);
		$mock->clear_sub_tracking();
		$attr{$target}{hardware} = "nano328";
		my $ret = SIGNALduino_Set($targetHash, $target, "flash" ,"r1.2.4");
		is($ret,undef,"return value fromSIGNALduino_Set");
		is(scalar @{$tracking->{HttpUtils_NonblockingGet}}, 1, "HttpUtils_NonblockingGet not called");
		like( $tracking->{HttpUtils_NonblockingGet}[0]{args}[0]{url}, qr/SIGNALDuino/, "Download URL set to SIGNALDuino Repo" );
	};

	subtest 'flash with MAPLEMINI_F103CBcc1101 hardware parameter set' => sub {
		plan(3);
		$attr{$target}{hardware} = "MAPLEMINI_F103CBcc1101";
		$mock->clear_sub_tracking();
		my $ret = SIGNALduino_Set($targetHash, $target, "flash" ,"r1.2.4");
		is($ret,undef,"return value fromSIGNALduino_Set");
		is(scalar @{$tracking->{HttpUtils_NonblockingGet}}, 1, "HttpUtils_NonblockingGet not called");
		like( $tracking->{HttpUtils_NonblockingGet}[0]{args}[0]{url}, qr/SIGNALDuino/, "Download URL set to SIGNALDuino Repo" );
	}; 

	subtest 'flash with MAPLEMINI_F103CB hardware parameter set' => sub {
		plan(3);
		$attr{$target}{hardware} = "MAPLEMINI_F103CB";
		$mock->clear_sub_tracking();
		my $ret = SIGNALduino_Set($targetHash, $target, "flash" ,"r1.2.4");
		is($ret,undef,"return value fromSIGNALduino_Set");
		is(scalar @{$tracking->{HttpUtils_NonblockingGet}}, 1, "HttpUtils_NonblockingGet not called");
		like( $tracking->{HttpUtils_NonblockingGet}[0]{args}[0]{url}, qr/SIGNALDuino/, "Download URL set to SIGNALDuino Repo" );
	}; 
	
	subtest 'flash via url parameter' => sub {
		plan(3);
		$mock->clear_sub_tracking();
		$attr{$target}{hardware} = "nano328";
		my $ret = SIGNALduino_Set($targetHash, $target, "flash","https://github.com/RFD-FHEM/SIGNALDuino/releases/download/3.3.1/SIGNALDuino_nano3283.3.1.hex");
		is($ret,undef,"return value fromSIGNALduino_Set");
		is(scalar @{$tracking->{HttpUtils_NonblockingGet}}, 1, "HttpUtils_NonblockingGet not called");
		is( $tracking->{HttpUtils_NonblockingGet}[0]{args}[0]{url}, "https://github.com/RFD-FHEM/SIGNALDuino/releases/download/3.3.1/SIGNALDuino_nano3283.3.1.hex", "Download URL is hex file" );
	};

	$mock->restore('HttpUtils_NonblockingGet');
	
	subtest 'check prerelease without hardware parameter set' => sub {
		plan(2);
		my $param = {
			hash       => $targetHash,    
			command    => "queryReleases",
			url 	   => $path.'/test_firmware_releases.json'
		};
		$attr{$target}{hardware} = undef;
		$attr{$target}{updateChannelFW} = 'testing';

		my ($error, @json) = FileRead($path.'/test_firmware_releases.json');
		if (! defined $error ) {
			#diag "json @json";
			my $jsonstr=join ("\n",@json);
			SIGNALduino_githubParseHttpResponse($param,'',$jsonstr);
			ok(exists($targetHash->{additionalSets}{flash}),"check if additionalSets are created");
			unlike($targetHash->{additionalSets}{flash},qr/3.3.1-RC10/,"check if testing firmware isn't found");
		} else {
			diag("open json firmware file was not possible $error");
		}
	};
	
	subtest 'check prerelease with hardware parameter set to nano' => sub {
		plan(1);
		my $param = {
			hash       => $targetHash,    
			command    => "queryReleases"
		};
		$attr{$target}{hardware} = "nano328";
		$attr{$target}{updateChannelFW} = 'testing';

		my ($error, @json) = FileRead($path."/test_firmware_releases.json");
		if ($error eq "") {
			#diag "json @json";
			my $jsonstr=join ("\n",@json);
			SIGNALduino_githubParseHttpResponse($param,"",$jsonstr);
			like($targetHash->{additionalSets}{flash},qr/3.3.1-RC10/,"check if testing firmware is found");
		} else {
			diag("open json firmware file was not possible $error");
		}
	};

	subtest 'check prerelease with hardware parameter set to ESP8266' => sub {
		plan(1);
		my $param = {
			hash       => $targetHash,    
			command    => "queryReleases"
		};
		$attr{$target}{hardware} = "ESP8266";
		$attr{$target}{updateChannelFW} = 'testing';

		my ($error, @json) = FileRead($path."/test_firmware_releases.json");
		if ($error eq "") {
			#diag "json @json";
			my $jsonstr=join ("\n",@json);
			SIGNALduino_githubParseHttpResponse($param,"",$jsonstr);
			unlike($targetHash->{additionalSets}{flash},qr/3.3.1-RC10/,"check if testing firmware is found");
		} else {
			diag("open json firmware file was not possible $error");
		}
	};

	subtest 'check stable with hardware parameter set to nanocc1101' => sub {
		plan(1);
		my $param = {
			hash       => $targetHash,    
			command    => "queryReleases"
		};
		$attr{$target}{hardware} = "nanocc1101";
		$attr{$target}{updateChannelFW} = 'stable';

		my ($error, @json) = FileRead($path."/test_firmware_releases.json");
		if ($error eq "") {
			my $jsonstr=join ("\n",@json);
			SIGNALduino_githubParseHttpResponse($param,"",$jsonstr);
			unlike($targetHash->{additionalSets}{flash},qr/3.3.0/,"check if testing firmware is found");
		} else {
			diag("open json firmware file was not possible $error");
		}
	};

	subtest 'check stable with hardware parameter set to nano' => sub {
		plan(1);
		my $param = {
			hash       => $targetHash,    
			command    => "queryReleases"
		};
		$attr{$target}{hardware} = "nano328";
		$attr{$target}{updateChannelFW} = 'stable';

		my ($error, @json) = FileRead($path."/test_firmware_releases.json");
		if ($error eq "") {
			my $jsonstr=join ("\n",@json);
			SIGNALduino_githubParseHttpResponse($param,"",$jsonstr);
			like($targetHash->{additionalSets}{flash},qr/3.3.0/,"check if testing firmware is found");
		} else {
			diag("open json firmware file was not possible $error");
		}
	};

	subtest 'check stable with hardware parameter set to MAPLEMINI_F103CB' => sub {
		plan(1);
		my $param = {
			hash       => $targetHash,    
			command    => "queryReleases"
		};
		$attr{$target}{hardware} = "MAPLEMINI_F103CB";
		$attr{$target}{updateChannelFW} = 'stable';

		my ($error, @json) = FileRead($path."/test_firmware_releases.json");
		if ($error eq "") {
			my $jsonstr=join ("\n",@json);
			SIGNALduino_githubParseHttpResponse($param,"",$jsonstr);
			like($targetHash->{additionalSets}{flash},qr/3.4.0/,"check if testing firmware is found");
		} else {
			diag("open json firmware file was not possible $error");
		}
	};

	subtest 'check stable with hardware parameter set to MAPLEMINI_F103CBcc1101' => sub {
		plan(1);
		my $param = {
			hash       => $targetHash,    
			command    => "queryReleases"
		};
		$attr{$target}{hardware} = "MAPLEMINI_F103CBcc1101";
		$attr{$target}{updateChannelFW} = 'stable';

		my ($error, @json) = FileRead($path."/test_firmware_releases.json");
		if ($error eq "") {
			my $jsonstr=join ("\n",@json);
			SIGNALduino_githubParseHttpResponse($param,"",$jsonstr);
			like($targetHash->{additionalSets}{flash},qr/3.4.0/,"check if testing firmware is found");
		} else {
			diag("open json firmware file was not possible $error");
		}
	};

	subtest 'check stable with hardware parameter set to ESP32' => sub {
		plan(1);
		my $param = {
			hash       => $targetHash,    
			command    => "queryReleases"
		};
		$attr{$target}{hardware} = "ESP32";
		$attr{$target}{updateChannelFW} = 'stable';

		my ($error, @json) = FileRead($path."/test_firmware_releases.json");
		if ($error eq "") {
			my $jsonstr=join ("\n",@json);
			SIGNALduino_githubParseHttpResponse($param,"",$jsonstr);
			like($targetHash->{additionalSets}{flash},qr/3.4.0/,"check if testing firmware is found");
		} else {
			diag("open json firmware file was not possible $error");
		}
	};

	exit(0);
},'dummyDuino');

1;