#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is};

our %defs;
our %attr;


my $name = 'testDuino';

CommandDefMod(undef,"-temporary $name SIGNALduino none");
my $targetHash = $defs{$name};
plan (1);	

subtest 'Check internal defaults ' => sub {
	plan(5);

	#use lib::SD_Protocols;

	is(InternalVal($name,"DeviceName", undef),"none","check DeviceName");
	is(InternalVal($name,"DMSG", undef),"nothing","check DMSG");
	is(InternalVal($name,"LASTDMSG", undef),"nothing","check LASTDMSG");
	is(InternalVal($name,"versionmodul", undef),SDUINO_VERSION,"check versionmodul");
	is(InternalVal($name,"versionProtocols", undef),$targetHash->{protocolObject}->getProtocolVersion(),"check versionProtocols");
}; 

exit(0);
1;