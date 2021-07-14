use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{ is array bag };
use Test2::Todo;

our %defs;

InternalTimer(time(), sub {
	my $target = shift;
	my $targetHash = $defs{$target};

    
    subtest 'setPatable' => sub {
        plan(3);
        my @paval;
        CommandAttr(undef,qq[$target cc1101_frequency 433]);    
        subtest '-30dbm 433 Mhz' => sub {
            plan(2);

            my @paval;
            $paval[1] = '-30_dBm';
            is(cc1101::SetPatable($targetHash,@paval),U(),q[verify return]);
            is($targetHash->{QUEUE},array {
                item 'x12';
            } ,"Verify expected queue element entrys");
            @{$targetHash->{QUEUE}}=();

        };


        subtest '-36dbm 433 Mhz' => sub {
            plan(2);

            my $todo = Test2::Todo->new(reason => 'Fix needed, this shoud fail in some way');
            $paval[1] = '-36_dBm';
            is(cc1101::SetPatable($targetHash,@paval),D(),q[verify return]);
            is($targetHash->{QUEUE},array {
                end();
            } ,"Verify expected queue element entrys");
            $todo->end;
            @{$targetHash->{QUEUE}}=();
        };

        CommandAttr(undef,qq[$target cc1101_frequency 868]);    
        subtest '-35dbm 868 Mhz' => sub {
            plan(2);

            $paval[1] = '-30_dBm';
            is(cc1101::SetPatable($targetHash,@paval),U(),q[verify return]);
            is($targetHash->{QUEUE},array {
                item 'x03';
            } ,"Verify expected queue element entrys");
            @{$targetHash->{QUEUE}}=();
        };
    };

    my $todo = Test2::Todo->new(reason => 'Tests needs to be implemented');

    subtest 'SetRegisters' => sub {

    };

    subtest 'SetRegistersUser' => sub {

    };

    subtest 'SetDataRate' => sub {

    };

    subtest 'CalcDataRate' => sub {

    };

    subtest 'SetDeviatn' => sub {

    };

    subtest 'SetFreq' => sub {

    };

    subtest 'setrAmpl' => sub {

    };

    subtest 'GetRegister' => sub {

    };

    subtest 'CalcbWidthReg' => sub {

    };

    subtest 'SetSens' => sub {

    };

    $todo->end;
    plan(11);
	exit(0);
},'cc1101dummyDuino');

1;