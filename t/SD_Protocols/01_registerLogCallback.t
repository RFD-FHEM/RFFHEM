#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use lib::SD_Protocols;
use Test2::Tools::Compare qw{is};
use Carp qw(carp);


plan(4);


my $Protocols =
new lib::SD_Protocols( filetype => 'json', filename => './t/SD_Protocols/test_protocolData.json' );
my $hash->{NAME} = "testName";

sub createCallback {
	
	my $hash = shift // return ;
	(ref $hash ne 'HASH') // return ;

	return sub  {
		my $message = shift // carp "message must be provided";
		my $level = shift // 0;
		
		
		is ($level,5,'check loglevel','Verify loglevel');
		is ($message, q[Heavy debug message],'Verify message');
	    print qq[ $level ($hash->{NAME}): /sonstwas/ $message];
	};
};



my $myLocalLogCallback =createCallback($hash);

is (ref $myLocalLogCallback,'CODE',"check coderef is returned");


$Protocols->registerLogCallback($myLocalLogCallback);
is (ref $Protocols->{_logCallback},'CODE',"check coderef is stored in class object");


$Protocols->{_logCallback}->('Heavy debug message',5);
