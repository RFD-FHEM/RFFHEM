#!/usr/bin/env perl
use strict;
use warnings;


BEGIN {
	# Doesn't work without restart, so temp moved to a test
	AnalyzeCommand(undef,'update all https://raw.githubusercontent.com/fhem/lib_timer/master/controls_libtimer.txt');
}

done_testing();
exit(0);
1;