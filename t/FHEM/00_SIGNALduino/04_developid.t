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
	plan (10);	
	my $path=dirname(__FILE__);
	my $LoadResult =  $targetHash->{protocolObject}->LoadHash($path."/test_loadprotohash-ok.pm");
	is($LoadResult,undef,"load test protocol hash ");

	my %ProtocolListTest = %{$targetHash->{protocolObject}->getProtocolList()};
	subtest 'verify protocolList loaded correctly'=> sub {
		plan(4);
		foreach my $id (qw/9999 9998 9997 9996/)
		{
			is($targetHash->{protocolObject}->protocolExists($id),1,"id $id exists");
		}
	};

	my $msg;
	my $regex;
	my $regex_matched=0;
	my $logfilter="skipped";
	
	# mock sub directly
    $targetHash->{logMethod}=sub { 
		if (!$regex_matched && $_[2] =~ /$logfilter/) 
		{
			if ($_[2] =~ $regex) 
			{
				$regex_matched=1;
			} 
		}
		Log3 $_[0], $_[1] ,$_[2];
	};
	
	my $subTestName='SIGNALduino_IdList developid "m" skip scenarios';
	subtest $subTestName => sub {
		plan(3);
		$regex_matched=0;
		$regex=$ProtocolListTest{'9999'}{id};

		$msg="attr whitelist=10, development=\"\"" ;
		SIGNALduino_IdList("x:$target","10","","");
		ok($regex_matched,$msg) or diag("check log entrys for skipped with id 9999, they where not found");
		$regex_matched=0;
		
		$msg="attr whitelist=10, development=1" ;
		SIGNALduino_IdList("x:$target","10","",1);
		ok($regex_matched,$msg) or diag("check log entrys for skipped with id 9999, they where not found");
		$regex_matched=0;

		$msg="attr blacklist=9999, development=0" ;
		SIGNALduino_IdList("x:$target","",9999,0);
		ok($regex_matched,$msg) or diag("check log entrys for skipped with id 9999, they where not found");
		$regex_matched=0;
	};
	
	$subTestName='SIGNALduino_IdList developid "y" skip scenarios';
	subtest $subTestName => sub {
		plan(4);
		$regex_matched=0;
		$regex=$ProtocolListTest{'9997'}{id};

		$msg="attr whitelist=\"\", development=\"\"" ;
		SIGNALduino_IdList("x:$target","","","");
		ok($regex_matched,$msg) or diag("check log entrys for skipped with id 9997, they where not found");
		$regex_matched=0;
		
		$msg="attr whitelist=\"\", development=0" ;
		SIGNALduino_IdList("x:$target","","",0);
		ok($regex_matched,$msg) or diag("check log entrys for skipped with id 9997, they where not found");
		$regex_matched=0;

		$msg="attr whitelist=\"\", development=\"y75\"" ;
		SIGNALduino_IdList("x:$target","","","y75");
		ok($regex_matched,$msg) or diag("check log entrys for skipped with id 9997 they where not found");
		$regex_matched=0;

		
		$msg="attr whitelist=\"\", development=\"m9997\"" ;
		SIGNALduino_IdList("x:$target","","","m9997");  
		ok($regex_matched,$msg) or diag("check log entrys for skipped with id 9997, they where not found");
		$regex_matched=0;
	};

	$subTestName='SIGNALduino_IdList developid "p" skip scenarios';
	subtest $subTestName => sub {

		plan(4);
		$regex=$ProtocolListTest{'9996'}{id};

		$msg="attr whitelist=\"\", development=\"\"" ;
		SIGNALduino_IdList("x:$target","","","");
		ok($regex_matched,$msg) or diag("check log entrys for skipped with id 9996, they where not found");
		$regex_matched=0;
	
		$msg="attr whitelist=\"\", development=0" ;
		SIGNALduino_IdList("x:$target","","","0");
		ok($regex_matched,$msg) or diag("check log entrys for skipped with id 9996, they where not found");
		$regex_matched=0;

		$msg="attr whitelist=\"\", development=\"p75\"" ;
		SIGNALduino_IdList("x:$target","","","p75"); 
		ok($regex_matched,$msg) or diag("check log entrys for skipped with id 9996, they where not found");
		$regex_matched=0;

		$msg="attr whitelist=\"\", development=\"m9996\"" ;
		SIGNALduino_IdList("x:$target","","","m9996"); 
		ok($regex_matched,$msg) or diag("check log entrys for skipped with id 9996, they where not found");
		$regex_matched=0;

	};
	
	SKIP: {
		skip ("attribute development not supported in stable version", 2) if ( index($targetHash->{versionmodul},"dev") == -1);
	
		$subTestName='SIGNALduino_IdList developid "m" not skipped scenarios';
		subtest $subTestName => sub {
			plan(2);
			$regex_matched=0;
			$regex=$ProtocolListTest{'9999'}{id};

			$msg="attr whitelist=\"\", development=\"m9999\"" ;
			SIGNALduino_IdList("x:$target","","","m9999");  
				isnt($regex_matched,1,$msg) or diag("check log entrys for skipped with id 9999, they should not be there");
			$regex_matched=0;

			$msg="attr whitelist=\"\", development=\"75 m9999 u73\"" ;
			SIGNALduino_IdList("x:$target","","","m75 m9999 u73"); 
			isnt($regex_matched,1,$msg) or diag("check log entrys for skipped with id 9999, they should not be there");
			$regex_matched=0;
		};
	
	
		$subTestName='SIGNALduino_IdList developid "y" not skipped scenarios';
		subtest $subTestName => sub {
			plan(5);
			$regex_matched=0;
			$regex=$ProtocolListTest{'9997'}{id};

			$msg="attr whitelist=\"\", development=\"1\"" ;
			SIGNALduino_IdList("x:$target","","","1");  
			isnt($regex_matched,1,$msg) or diag("check log entrys for skipped with id 9997, they should not be there");
			$regex_matched=0;

			$msg="attr whitelist=\"\", development=\"y\"" ;
			SIGNALduino_IdList("x:$target","","","y");  
			isnt($regex_matched,1,$msg) or diag("check log entrys for skipped with id 9997, they should not be there");
			$regex_matched=0;

			$msg="attr whitelist=\"\", development=\"y9997\"" ;
			SIGNALduino_IdList("x:$target","","","y9997");  
			isnt($regex_matched,1,$msg) or diag("check log entrys for skipped with id 9997, they should not be there");
			$regex_matched=0;

			$msg="attr whitelist=\"\", development=\"m75 y9997 u73\"" ;
			SIGNALduino_IdList("x:$target","","","m75 y9997 u73"); 
			isnt($regex_matched,1,$msg) or diag("check log entrys for skipped with id 9997, they should not be there");
			$regex_matched=0;

			$msg="attr whitelist=\"9999\", development=\"\"" ;
			SIGNALduino_IdList("x:$target","9997","",""); 
			isnt($regex_matched,1,$msg) or diag("check log entrys for skipped with id 9997, they should not be there");
			$regex_matched=0;

			$regex_matched=0;
		};
	
		$subTestName='SIGNALduino_IdList multiple development statements';
		subtest $subTestName => sub {

			plan(2);
			$regex_matched=0;
			$regex=$ProtocolListTest{'9997'}{id};

			$msg="attr whitelist=\"\", development=\"y m9999\"" ;
			SIGNALduino_IdList("x:$target","","","y m9999");  
			isnt($regex_matched,1,$msg) or diag("check log entrys for skipped with id $regex, this should not be skipped");
			$regex_matched=0;

			$regex=$ProtocolListTest{'9999'}{id};
			SIGNALduino_IdList("x:$target","","","y m9999");  
			isnt($regex_matched,1,$msg) or diag("check log entrys for skipped with id $regex, this should not be skipped");
			$regex_matched=0;
		};
	};
	
	$subTestName='SIGNALduino_IdList developid "p" not skipped scenarios';
	subtest $subTestName => sub {
		$ProtocolListTest{'9996'}{developId}="p";
		plan(2);
		$regex_matched=0;
		$regex=$ProtocolListTest{'9996'}{id};

		$msg="attr whitelist=\"9996\", development=\"\"" ;
		SIGNALduino_IdList("x:$target","9996","","");  
		isnt($regex_matched,1,$msg) or diag("check log entrys for skipped with id 9996, they should not be there");
		$regex_matched=0;

		$msg="attr whitelist=\"9996\", development=\"m75 p9996 u73\"" ;
		SIGNALduino_IdList("x:$target","9996","","m75 u73"); 
		isnt($regex_matched,1,$msg) or diag("check log entrys for skipped with id 9996, they should not be there");
		$regex_matched=0;
	};
	
	$subTestName='SIGNALduino_IdList developId "m" dispatch enabled/disabled tests';
	subtest $subTestName => sub {
		$logfilter="IdList, development protocol is active";

		plan(2);
		$regex_matched=0;
		$regex=$ProtocolListTest{'9999'}{id};

		$msg="attr whitelist=\"\", development=\"\"" ;
		SIGNALduino_IdList("x:$target","","","");  
		is($regex_matched,1,$msg) or diag("check log entrys for development protocol is active with id $regex, there should be a note");
		$regex_matched=0;

		SKIP : {
			skip ('attribute development not supported in stable version', 1) if (index($targetHash->{versionmodul},'dev') == -1);
			$msg="attr whitelist=\"\", development=\"m9999\"" ;
			SIGNALduino_IdList("x:$target","","","m9999");  
			isnt($regex_matched,1,$msg) or diag("check log entrys for development protocol is active with id $regex, there shouldn't be a note");
			$regex_matched=0;
		}
	};
	subtest 'test normal hash reloaded correctly' => sub {
		plan(5);

		my $LoadResult =  $targetHash->{protocolObject}->LoadHash("$attr{global}{modpath}/FHEM/lib/SD_ProtocolData.pm");
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