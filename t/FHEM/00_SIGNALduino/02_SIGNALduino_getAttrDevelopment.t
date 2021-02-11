use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{ is };
use Test2::Mock;

our %defs;

InternalTimer(time(), sub {
	my $target = shift;
	my $targetHash = $defs{$target};
	CommandAttr(undef,"$target Whitelist_IDs 1,2,3");
	plan(4);

	subtest 'development attr set to 0' => sub {
		plan(2);

		CommandAttr(undef,"$target development 0");
		my ($attrDevelop,$devflag)=SIGNALduino_getAttrDevelopment($target);
		is($attrDevelop,0,"check develop attr");
		is($devflag,0,"check develop flag");
	};

	SKIP: {
		skip "attribute development not supported in stable version", 2 if (index($targetHash->{versionmodule},"dev") == -1);
	
		subtest 'development attr set to 1' => sub {
			plan(2);

			CommandAttr(undef,"$target development 1");
			my ($attrDevelop,$devflag)=SIGNALduino_getAttrDevelopment($target);
			is($attrDevelop,1,"check develop attr");
			is($devflag,1,"check develop flag");
		};

		subtest 'development attr set to y' => sub {
			plan(2);

			CommandAttr(undef,"$target development y");
			my ($attrDevelop,$devflag)=SIGNALduino_getAttrDevelopment($target);
			is($attrDevelop,"y","check develop attr");
			is($devflag,1,"check develop flag");
		};
	};

	subtest 'development attr set to y58' => sub {
		plan(2);
		
		CommandAttr(undef,"$target development y58");
		my ($attrDevelop,$devflag)=SIGNALduino_getAttrDevelopment($target);
		SKIP: {
			skip "attribute development not supported in stable version", 1 if (index($targetHash->{versionmodule},"dev") == -1);
			is($attrDevelop,"y58","check develop attr");
		}
		is($devflag,0,"check develop flag");
	};

	exit(0);
},'dummyDuino');

1;