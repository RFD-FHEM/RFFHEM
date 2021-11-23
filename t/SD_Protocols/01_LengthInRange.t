#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{is like};

plan(4);

my $id=9990;
my ($rcode,$message);
my $Protocols =
  new lib::SD_Protocols( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );


subtest 'length inside range' => sub {
	plan(7);

	for my $l (2..8)
	{
		subtest qq[testLength = $l] => sub {
			plan(2);
			($rcode,$message)=$Protocols->LengthInRange($id,$l);
			is($rcode,1,'check returncode for LengthInRange');
			is($message,q{},'check error string');
		}
	}
};

subtest 'length to short' => sub {
	plan(3);

	for my $l (-1..1) {
		subtest qq[testLength = $l] => sub {
			plan(2);
			($rcode,$message)=$Protocols->LengthInRange($id,0);
			is($rcode,0,'check returncode for LengthInRange');
			is($message,q{message is to short},'check error string');
		}
	}
};


subtest 'length to high' => sub {
	plan(2);

	($rcode,$message)=$Protocols->LengthInRange($id,9);
	is($rcode,0,'check returncode for LengthInRange');
	is($message,q{message is to long},'check error string');
};

subtest 'protocol does not exsts' => sub {
	plan(2);

	($rcode,$message)=$Protocols->LengthInRange(556565,5);
	is($rcode,0,'check returncode for LengthInRange');
	is($message,q{protocol does not exists},'check error string');
};
