use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{ is U};
use Test2::Mock;

our %defs;

InternalTimer(time(), sub {
	my $target = shift;
	my $targetHash = $defs{$target};
	my %patternListRaw;


	
	plan(5);
	subtest "don't match 1" => sub {
		plan(1);

		my $rmsg="MU;P0=7944;P1=-724;P2=742;P3=241;P4=-495;P5=483;P6=-248;D=01212121343434345656343434563434345634565656343434565634343434343434345634345634345634343434343434343434345634565634345656345634343456563421212121343434345656343434563434345634565656343434565634343434343434345634345634345634343434343434343434345634565634;CP=3;R=47;";
	    my %msg_parts = SIGNALduino_Split_Message($rmsg, $targetHash);
	    my $clockabs= 480;
		$patternListRaw{$_} = $msg_parts{pattern}{$_} for keys %{$msg_parts{pattern}};

		my %patternList = map { $_ => round($patternListRaw{$_}/$clockabs,1) } keys %patternListRaw;
		is(SIGNALduino_PatternExists($targetHash,[1,-2, 1,-1, 1,-2, 1,-2, 1,-2, 1,-2, 1,-2],\%patternList,\$rmsg ),"-1","verify return value");
	};
	subtest "don't match 2" => sub {
		plan(1);

		my $rmsg="MU;P0=740;P1=-2076;P2=381;P3=-4022;P4=-604;P5=152;P6=-1280;P7=-8692;D=012123232321245621212121232123232427212323212123232326;CP=2;R=228;";
	    my %msg_parts = SIGNALduino_Split_Message($rmsg, $targetHash);
	    my $clockabs= 480;
		$patternListRaw{$_} = $msg_parts{pattern}{$_} for keys %{$msg_parts{pattern}};

		my %patternList = map { $_ => round($patternListRaw{$_}/$clockabs,1) } keys %patternListRaw;
		is(SIGNALduino_PatternExists($targetHash,[1,-2, 1,-1, 1,-2, 1,-2, 1,-2, 1,-2, 1,-2],\%patternList,\$rmsg ),"-1","verify return value");
	};
	subtest "match 3" => sub {
		plan(1);

		my $rmsg="MU;P0=-2076;P1=479;P2=-963;P3=-492;P4=-22652;D=01213121213121212131313121313131312121313131313121212121313131212131313131313131313121313121313131313131313131312131212121313121412131212121212131213121213121212131313121313131312121313131313121212121313131212131313131313131313121313121313131313131313131;CP=1;R=26;O;";
	    my %msg_parts = SIGNALduino_Split_Message($rmsg, $targetHash);
	    my $clockabs= 480;
		$patternListRaw{$_} = $msg_parts{pattern}{$_} for keys %{$msg_parts{pattern}};

		my %patternList = map { $_ => round($patternListRaw{$_}/$clockabs,1) } keys %patternListRaw;
		is(SIGNALduino_PatternExists($targetHash,[1,-2, 1,-1, 1,-2, 1,-2, 1,-2, 1,-2, 1,-2],\%patternList,\$rmsg ),"12131212121212","verify return value");
	};

	subtest "match 4" => sub {
		plan(3);

		my $rmsg="MU;P0=7944;P1=-724;P2=742;P3=241;P4=-495;P5=483;P6=-248;D=01212121343434345656343434563434345634565656343434565634343434343434345634345634345634343434343434343434345634565634345656345634343456563421212121343434345656343434563434345634565656343434565634343434343434345634345634345634343434343434343434345634565634;CP=3;R=47;";
	    my %msg_parts = SIGNALduino_Split_Message($rmsg, $targetHash);
	    my $clockabs= 250;
		$patternListRaw{$_} = $msg_parts{pattern}{$_} for keys %{$msg_parts{pattern}};

		my %patternList = map { $_ => round($patternListRaw{$_}/$clockabs,1) } keys %patternListRaw;
		my $rawData = $msg_parts{rawData};
		is(SIGNALduino_PatternExists($targetHash,[3,-3,3,-3,3,-3],\%patternList,\$rawData ),"212121","verify return value start");
		is(SIGNALduino_PatternExists($targetHash,[2,-1],\%patternList,\$rawData ),"56","verify return value one");
		is(SIGNALduino_PatternExists($targetHash,[1,-2],\%patternList,\$rawData ),"34","verify return value zero");
	};

	subtest "match 5" => sub {
		plan(3);

		my $rmsg="MU;P0=-9524;P1=364;P2=-414;P3=669;P4=-755;P5=-16076;CP=1;R=83;D=0123412341234123412341412341414141412351234123412341234123414123414141414123;e;w=0;";
	    my %msg_parts = SIGNALduino_Split_Message($rmsg, $targetHash);
	    my $clockabs= 350;
		$patternListRaw{$_} = $msg_parts{pattern}{$_} for keys %{$msg_parts{pattern}};

		my %patternList = map { $_ => round($patternListRaw{$_}/$clockabs,1) } keys %patternListRaw;
		my $rawData = $msg_parts{rawData};
		is(SIGNALduino_PatternExists($targetHash,[-44,1],\%patternList,\$rawData ),"51","verify return value start");
		is(SIGNALduino_PatternExists($targetHash,[-2,1],\%patternList,\$rawData ),"41","verify return value one");
		is(SIGNALduino_PatternExists($targetHash,[-1,2],\%patternList,\$rawData ),"23","verify return value zero");
	};

	exit(0);
},'dummyDuino');

1;