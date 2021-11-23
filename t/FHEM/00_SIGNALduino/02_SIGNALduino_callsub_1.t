#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{ is };
use Test2::Tools::ClassicCompare qw/is_deeply/;

our %defs;

InternalTimer(time(), sub {
	plan(4);
    my $target='dummyDuino';
    my $targetHash = $defs{$target};

	my $bad_testmethod = sub {	my ($name, @bit_msg) = @_;	return 1,"bad var"; };
	my $good_testmethod = sub {	my ($name, @bit_msg) = @_;	return 1,qw(0 1 0 1); };
	my @bit_msg = qw /1 0 1 0/;
	my @expected_bit_msg = qw /0 1 0 1/;

    subtest 'SIGNALduino_callsub scenario good sub without eval check' => sub {	
        plan(4);
        my ($rcode,@retvalue) = SIGNALduino_callsub($targetHash->{protocolObject},'testMethod',$good_testmethod,undef,"dummyDuino",@bit_msg);
        is ($rcode,1,"Check returncode of SIGNALduino_callsub");
		is_deeply( \@retvalue, \@expected_bit_msg, "Check return values of SIGNALduino_callsub");

        ($rcode,@retvalue) = SIGNALduino_callsub($targetHash->{protocolObject},'testMethod',$good_testmethod,0,"dummyDuino",@bit_msg);
        is ($rcode,1,"Check returncode of SIGNALduino_callsub");
		is_deeply( \@retvalue, \@expected_bit_msg, "Check return values of SIGNALduino_callsub");
    }; 

	subtest 'SIGNALduino_callsub scenario good sub with eval check' => sub {	
        plan(2);

        my ($rcode,@retvalue) = SIGNALduino_callsub($targetHash->{protocolObject},'testMethod',$good_testmethod,1,$target,@bit_msg);
        is ($rcode,1,"Check returncode of SIGNALduino_callsub");
		is_deeply( \@retvalue, \@expected_bit_msg, "Check return values of SIGNALduino_callsub");
    }; 

    subtest 'SIGNALduino_callsub scenario bad sub with eval check' => sub {	
        plan(2);

        my ($rcode,@retvalue) = SIGNALduino_callsub($targetHash->{protocolObject},'testMethod',$bad_testmethod,1,$target,@bit_msg);
        is ($rcode,0,"Check if returncode of SIGNALduino_callsub ");
        is ($retvalue[0],undef,"Check returnvalue of SIGNALduino_callsub ");
    }; 

    subtest 'SIGNALduino_callsub scenario bad sub without eval check' => sub {	
        plan(2);

        my ($rcode,@retvalue) = SIGNALduino_callsub($targetHash->{protocolObject},'testMethod',$bad_testmethod,undef,$target,@bit_msg);
        is ($rcode,1,"Check if returncode of SIGNALduino_callsub ");
        is ($retvalue[0],"bad var","Check returnvalue of SIGNALduino_callsub ");
    }; 

    exit(0);
}, 0);

1;