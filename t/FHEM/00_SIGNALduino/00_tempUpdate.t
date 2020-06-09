#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;


BEGIN {
	# Doesn't work without restart, so temp moved to a test
	AnalyzeCommand(undef,'update all https://raw.githubusercontent.com/fhem/lib_timer/master/controls_libtimer.txt');
}
pass();
done_testing();

exit(0);
1;