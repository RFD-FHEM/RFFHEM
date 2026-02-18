#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{ is array bag call hash item end etc U D };
use Test2::Mock qw(mock);
use Test2::Todo;

use FHEM::Devices::SIGNALduino::SD_IO qw(:all);


subtest 'SIGNALduino_SimpleWrite_XQ' => sub {
    my $dName = 'sduino';
    my $log_args;
    plan(4);

    # 1. Prepare hash with custom logMethod for manual argument capture
    my $hash = {
        NAME        => $dName,
        logMethod   => sub {
            my ($hash_ref, $level, $msg) = @_;
            $log_args = [ $hash_ref, $level, $msg ];
            return;
        }
    };

    # 2. Mock SIGNALduino_SimpleWrite using the Test2::Mock tracking style (track => 1)
    my $mock_sd_io = Test2::Mock->new(
        track   => 1,
        class   => 'FHEM::Devices::SIGNALduino::SD_IO',
        override => [
            SIGNALduino_SimpleWrite => sub {}, # Mock the function so the real one is not called
        ]
    );

    SIGNALduino_SimpleWrite_XQ($hash);

    # 3. Verify logMethod call (manuelle Überprüfung, da es ein Code-Referenz im Hash ist)
    is( $log_args->[1], 3, 'Check log level (3)' );
    like( $log_args->[2], qr/sduino: SimpleWrite_XQ, disable receiver \(XQ\)/, 'Check log message' );

    # 4. Verify SIGNALduino_SimpleWrite call using sub_tracking()
    my $tracking_sw = $mock_sd_io->sub_tracking()->{SIGNALduino_SimpleWrite};

    is( scalar @{$tracking_sw}, 1, 'SIGNALduino_SimpleWrite called once' );

    # The arguments are in $tracking_sw->[0]->{args}
    is( $tracking_sw->[0]->{args}, array {
        item D(); # $hash - D() is used to match the hash reference without checking deep structure
        item 'XQ';
        end
    }, 'Check arguments of SIGNALduino_SimpleWrite: $hash and "XQ"' );

    $mock_sd_io->clear_sub_tracking();
};

subtest 'SIGNALduino_SimpleWrite_Standard' => sub {
    my $dName = 'sduino';
    my $message = 'A00';
    my $log_level;
    my $log_msg;
    my $write_args;
    plan(3);
    # 1. Mock USBDev and logMethod
    # DummyUSBDev class needs to be defined for Test2::Mock
    # Using Test2::Mock with a class name allows overriding methods for objects blessed into that class.
    package DummyUSBDev;
    use Test2::V0;
    
    # Define empty write sub so it can be overridden
    sub write { return }

    my $mock_usbdev = Test2::Mock->new(
        track   => 1,
        class   => 'DummyUSBDev',
        override => [
            write => sub {
                my ($self, $msg) = @_;
                $write_args = $msg;
                return;
            }
        ]
    );

    my $hash = {
        NAME        => $dName,
        logMethod   => sub {
            my ($hash_ref, $level, $msg) = @_;
            $log_level = $level;
            $log_msg = $msg;
            return;
        },
        USBDev      => bless({}, 'DummyUSBDev'), # Mocked device object
    };

    # 2. Call the function
    FHEM::Devices::SIGNALduino::SD_IO::SIGNALduino_SimpleWrite($hash, $message);

    # 3. Verify logMethod call (Level 5, Nachricht ohne \n)
    is( $log_level, 5, 'Check log level (5)' );
    like( $log_msg, qr/sduino: SimpleWrite, A00/, 'Check log message (no newline)' );

    # 4. Verify USBDev->write call (Nachricht mit \n)
    is( $write_args, "${message}\n", 'Check USBDev->write argument (with newline)' );

    done_testing;
};
    
subtest 'SIGNALduino_SimpleWrite_Nonl' => sub {
    my $dName = 'sduino';
    my $message = 'B00';
    my $nonl = 1;
    my $log_level;
    my $log_msg;
    my $write_args;

    plan(3);
    # 1. Mock USBDev and logMethod
    package DummyUSBDev2;
    use Test2::V0;

    # Define empty write sub so it can be overridden
    #sub write { return }

    my $mock_usbdev = Test2::Mock->new (
        track   => 1,
        class   => 'DummyUSBDev2',
        add => [
            write => sub {
                my ($self, $msg) = @_;
                $write_args = $msg;
                return;
            }
        ]
    );

    my $hash = {
        NAME        => $dName,
        logMethod   => sub {
            my ($hash_ref, $level, $msg) = @_;
            $log_level = $level;
            $log_msg = $msg;
            return;
        },
        USBDev      => bless({}, 'DummyUSBDev2'), # Mocked device object
    };

    # 2. Call the function
    FHEM::Devices::SIGNALduino::SD_IO::SIGNALduino_SimpleWrite($hash, $message, $nonl);

    # 3. Verify logMethod call (Level 5, Nachricht ohne \n)
    is( $log_level, 5, 'Check log level (5)' );
    like( $log_msg, qr/^sduino: SimpleWrite, B00/, 'Check log message (no newline)' );

    # 4. Verify USBDev->write call (Nachricht ohne \n)
    is( $write_args, $message, 'Check USBDev->write argument (without newline)' );

    done_testing;
};



done_testing;
