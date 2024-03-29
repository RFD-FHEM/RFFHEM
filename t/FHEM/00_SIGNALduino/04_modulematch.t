#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is isnt};
use Test2::Mock;

use File::Basename;
our %defs;
our %attr;

InternalTimer(time()+1, sub {
	my $target = shift;
	my $targetHash = $defs{$target};
	plan (6);	

	my $path=dirname(__FILE__);
	my $LoadResult =  $targetHash->{protocolObject}->LoadHash($path."/test_loadprotohash-ok.pm");

	is($LoadResult,undef,"load test protocol hash ");
  	my $local_ProtocolListSIGNALduino = $targetHash->{protocolObject}->getProtocolList();

	subtest 'verify protocolList loaded correctly'=> sub {

		foreach my $id (qw/9999 9998/)
		{
			is($targetHash->{protocolObject}->protocolExists($id),1,"id $id exists");
		}
	};

	subtest 'SIGNALduino_moduleMatch scenarios without whitlistIDs and development attr' => sub {
		plan(4);
		$local_ProtocolListSIGNALduino->{'9999'}{developId}="m";
		SIGNALduino_IdList("x:$target","","","");

		is(SIGNALduino_moduleMatch($target,'9999',"X3332222"),-1,"check returncode without modulematch");

		$local_ProtocolListSIGNALduino->{'9999'}{modulematch}="^X[A-Fa-f0-9]+";
		is(SIGNALduino_moduleMatch($target,'9999',"X3332222"),-1,"check returncode with matching modulematch");
		is(SIGNALduino_moduleMatch($target,'9999',"Y3332222"),0,"check returncode with not matching modulematch");
		is(SIGNALduino_moduleMatch($target,'9999',"X3332222"),-1,"check returncode with matching modulematch");
	};
	
	
	subtest 'SIGNALduino_moduleMatch scenarios with whitlistIDs, whithout development attr' => sub {
		plan(4);
		SIGNALduino_IdList("x:$target","9999","","");

		is(SIGNALduino_moduleMatch($target,'9999',"X3332222"),1,"check returncode without modulematch");

		is(SIGNALduino_moduleMatch($target,'9999',"X3332222"),1,"check returncode with matching modulematch");
		is(SIGNALduino_moduleMatch($target,'9999',"Y3332222"),0,"check returncode with not matching modulematch");


		is(SIGNALduino_moduleMatch($target,'9998',"X33322221"),1,"check returncode without modulematch");
		

	};
	
	subtest 'SIGNALduino_moduleMatch scenarios without whitlistIDs but development attr' => sub {
		plan(3);

		SIGNALduino_IdList("x:$target","","","m");
		is(SIGNALduino_moduleMatch($target,'9999',"X3332222"),-1,"check returncode with matching modulematch but wrong development attr");

		SIGNALduino_IdList("x:$target","","","m9999");
		$local_ProtocolListSIGNALduino->{'9999'}{modulematch}="^X[A-Fa-f0-9]+";
		SKIP : {
			skip ("attribute development not supported in stable version", 1) if (index($targetHash->{versionmodul},"dev") == -1);
			is(SIGNALduino_moduleMatch($target,'9999',"X3332222"),1,"check returncode with matching modulematch and right development attr");
		}
		is(SIGNALduino_moduleMatch($target,'9999',"Y3332222"),0,"check returncode with not matching modulematch");
	};
	subtest 'test normal hash reloaded correctly' => sub {
		plan(5);

		$LoadResult =  $targetHash->{protocolObject}->LoadHash("$attr{global}{modpath}/FHEM/lib/SD_ProtocolData.pm");
		is($LoadResult,undef,"load test protocol hash ");

		SIGNALduino_IdList("x:$target","","","");  
		foreach my $id (qw/9999 9998 9997 9996/)
		{
			isnt($targetHash->{protocolObject}->protocolExists($id),1,"id $id does not exists");
		}
	};

	exit(0);
},'dummyDuino');

1;