#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{ is array bag call hash item end etc U D };
use Test2::Mock;

use FHEM::Devices::SIGNALduino::SD_IO qw(:all);

# Define empty responseSub as required as a callback reference
sub main::SIGNALduino_GetResponseUpdateReading {}


# Central main mock for functions 
my $mock_main = Test2::Mock->new (
    class    => 'main',
    autoload => 1,
    track => 1,
    add => [
        gettimeofday => sub { 1600000000 },
        myLogMethod => sub  {
            my ($hash_ref, $level, $msg) = @_;
            note "Log $level: $msg";
            
            return;
        },
    ]
);

# Separate mock for FHEM::Core::Timer::Helper::addTimer
my $timer_mock = Test2::Mock->new (
    class => 'FHEM::Core::Timer::Helper',
    track => 1,
    add => [
        addTimer => sub { return  },
    ]
);

# separate mock for SIGNALduino_ResetDevice
my $mock_sd_io = Test2::Mock->new(
    track   => 1,
    class   => 'FHEM::Devices::SIGNALduino::SD_IO',
    override => [
        SIGNALduino_ResetDevice => sub {}, # Mock the function so the real one is not called
    ]
);


# init a base hash for tests
my $base_hash = {
    NAME     => 'mySD',
    DevState => 'ACTIVE',
    logMethod => \&myLogMethod,
};

# prepare variables for tracking
my $hash;
my $AddSendQueue_calls;
my $ResetDevice_calls;
my $Log_calls;
my $Timer_calls;

# Helper functions for setup and teardown
sub _setup{
    $hash = { %$base_hash };
}

sub _getTrackingCalls {
    $AddSendQueue_calls = $mock_main->sub_tracking()->{SIGNALduino_AddSendQueue};
    $ResetDevice_calls  = $mock_sd_io->sub_tracking()->{SIGNALduino_ResetDevice};
    $Log_calls          = $mock_main->sub_tracking()->{myLogMethod};
    $Timer_calls        = $timer_mock->sub_tracking()->{addTimer};
}

sub _teardown {
    $mock_main->clear_sub_tracking();
    $timer_mock->clear_sub_tracking();
    $mock_sd_io->clear_sub_tracking();
}

# Testfall 'Disconnected State'
subtest 'Disconnected State' => sub {
    plan(4);

    _setup();
    $hash->{DevState} = 'disconnected';

    SIGNALduino_KeepAlive($hash);
    
    _getTrackingCalls();

    is(scalar @{$Log_calls},0,'No logMethod call for disconnected state');
    is(scalar @{$AddSendQueue_calls},0,'No SIGNALduino_AddSendQueue call for disconnected state');
    is(scalar @{$ResetDevice_calls},0,'No SIGNALduino_ResetDevice call for disconnected state');
    is(scalar @{$Timer_calls},0,'No addTimer call for disconnected state'); 

    _teardown();
};

subtest 'KeepAlive OK' => sub {
    plan(5);

    _setup();
    $hash->{keepalive}{ok} = 1;
    $hash->{keepalive}{retry} = 0;
    
    SIGNALduino_KeepAlive($hash);

    _getTrackingCalls();

    # Verifiziere logMethod-Aufruf
    is( $Log_calls->[0]->{args},
        array {
            item 'mySD'; 
            item '4';  
            item match qr/KeepAlive, ok/; 
            end(); 
        },
        'Log3 called with loglevel 4 and "KeepAlive, ok"');

    # Verifiziere, dass $hash->{keepalive}{ok} auf 0 gesetzt wurde
    is( $hash->{keepalive}{ok}, 0, 'keepalive{ok} set to 0');

    # Verifiziere den addTimer-Aufruf mit der korrekten Zeit (1600000000 + 60)
    is( $Timer_calls->[0]->{args},
        array { item 'mySD';
                item number_gt 1600000000;
                item \&SIGNALduino_KeepAlive;
                item hash {
                    etc();
                },
            },
        'addTimer called with correct timer settings'
    );
            
    # No AddSendQueue or ResetDevice should be called
    is(scalar @{$AddSendQueue_calls},0,'No SIGNALduino_AddSendQueue call for disconnected state');
    is(scalar @{$ResetDevice_calls},0,'No SIGNALduino_ResetDevice call for disconnected state');
    
    # Clear mocks for next test suite
    _teardown();
};

subtest 'KeepAlive Retry & Max Retry' => sub {
    
    # Testfall 'KeepAlive NOT OK (Retry = 0 -> 1)'
    subtest 'Retry 0 -> 1' => sub {
        plan(5);
        _setup();

        $hash->{keepalive}{ok} = 0;
        $hash->{keepalive}{retry} = 0;
        
        SIGNALduino_KeepAlive($hash);
        
        _getTrackingCalls();

        # Verifiziere cmd und retry
        is( $hash->{ucCmd}->{cmd}, 'ping', 'ucCmd for ping command set');
        is( $hash->{keepalive}{retry}, 1, 'keepalive{retry} set to 1');

        # Verifiziere logMethod-Aufruf (logLevel 4, da retry == 1)
        is($Log_calls->[0]->{args},
            array {
                item 'mySD'; 
                item '4';
                item match qr/KeepAlive, not ok, retry = 1/; 
                end();
            },
            'Log3 called with loglevel 4 and "KeepAlive, not ok, retry = 1"'
        );

        # Verifiziere AddSendQueue-Aufruf
        is($AddSendQueue_calls->[0]->{args},
            array {
                item hash { etc(); };
                item 'P';
                end();
            },
            'SIGNALduino_AddSendQueue called with "P"'
        );

        # Verifiziere addTimer-Aufruf
        is($Timer_calls->[0]->{args},
            array { item 'mySD';
                item number_gt 1600000000;
                item \&SIGNALduino_KeepAlive;
                item hash {
                    etc();
                },
            },
            'addTimer called with correct timer settings'
        );
        _teardown();
    };

    # Testfall 'KeepAlive NOT OK (Retry = 1 -> 2)'
    subtest 'Retry 1 -> 2' => sub {
        plan(4);
        _setup();
        $hash->{keepalive}{ok} = 0;
        $hash->{keepalive}{retry} = 1;
        
        SIGNALduino_KeepAlive($hash);

        _getTrackingCalls();

        # Verifiziere retry
        is( $hash->{keepalive}{retry}, 2, 'keepalive{retry} set to 2');

        # Verifiziere logMethod-Aufruf (logLevel 3, da retry > 1)
        is($Log_calls->[0]->{args},
            array {
                item 'mySD'; 
                item '3';
                item match qr/KeepAlive, not ok, retry = 2/; 
                end();
            },
            'Log3 called with loglevel 3 and "KeepAlive, not ok, retry = 2"'
        );

        # Verifiziere AddSendQueue-Aufruf
        is($AddSendQueue_calls->[0]->{args},
            array {
                item hash { etc(); };
                item 'P';
                end();
            },
            'SIGNALduino_AddSendQueue called with "P"'
        );

        # Verifiziere addTimer-Aufruf
        is($Timer_calls->[0]->{args},
            array { item 'mySD';
                item number_gt 1600000000;
                item \&SIGNALduino_KeepAlive;
                item hash {
                    etc();
                },
            },
            'addTimer called with correct timer settings'
        );

        # Clear mocks for next test suite
        _teardown();
    };

    # Testfall 'KeepAlive NOT OK (Retry = Max Retry / Reset)'
    subtest 'Max Retry Reset' => sub {
        plan(5);
        _setup();

        $hash->{keepalive}{ok} = 0;
        $hash->{keepalive}{retry} = SDUINO_KEEPALIVE_MAXRETRY;
        
        SIGNALduino_KeepAlive($hash);

        _getTrackingCalls();

        # Verifiziere DevState
        is( $hash->{DevState}, 'INACTIVE', 'DevState set to INACTIVE');

        # Verifiziere logMethod-Aufruf (logLevel 3, da retry > 1)
        is($Log_calls->[0]->{args},
            array {
                item 'mySD'; 
                item '3';
                item match qr/KeepAlive, not ok, retry count reached. Reset/; 
                end();
            },
            'Log3 called with max retry reset message'
        );

        # Verifiziere ResetDevice-Aufruf
        is($ResetDevice_calls->[0]->{args},
            array {
                item hash { NAME => 'mySD', etc(); };
                end();
            },
            'SIGNALduino_ResetDevice called'
        );
        is(scalar @{$AddSendQueue_calls},0,'No SIGNALduino_AddSendQueue call');
        is(scalar @{$Timer_calls},0,'No addTimer call');


        # Clear mocks for next test suite
        _teardown();
    };
};

done_testing();
