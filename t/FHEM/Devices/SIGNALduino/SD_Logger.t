use strict;
use warnings;
use Test2::V0;

# Initialize call tracking
my $log3_calls = [];

# Manually mock main::Log3
# We define it if it doesn't exist, or redefine it if it does
{
    no warnings 'redefine';
    *main::Log3 = sub {
        push @$log3_calls, { 
            sub_name => 'Log3', 
            args => [@_] 
        };
        return 1;
    };
}

use FHEM::Devices::SIGNALduino::SD_Logger;

# Test Case 1: Custom logMethod in hash
subtest 'Custom logMethod' => sub {
    my $called = 0;
    my $received_args = [];
    
    my $device_hash = {
        NAME => 'TestDevice',
        logMethod => sub {
            $called = 1;
            $received_args = [@_];
        }
    };
    
    $log3_calls = []; # Reset calls
    FHEM::Devices::SIGNALduino::SD_Logger::Log($device_hash, 3, 'Test Message 1');
    
    ok($called, 'Custom logMethod was called');
    is($received_args, ['TestDevice', 3, 'Test Message 1'], 'logMethod received correct arguments');
    
    # Verify Log3 was NOT called
    is($log3_calls, [], 'main::Log3 was NOT called');
};

# Test Case 2: Hash with NAME (Fallback to Log3)
subtest 'Hash with NAME' => sub {
    my $device_hash = {
        NAME => 'HashDevice'
    };
    
    $log3_calls = [];
    FHEM::Devices::SIGNALduino::SD_Logger::Log($device_hash, 4, 'Test Message 2');
    
    is(@$log3_calls, 1, 'main::Log3 was called exactly once');
    
    if (@$log3_calls) {
        my $call = $log3_calls->[0];
        is($call->{sub_name}, 'Log3', 'Called sub is Log3');
        is($call->{args}, ['HashDevice', 4, 'Test Message 2'], 'Log3 arguments match');
    }
};

# Test Case 3: Device Name as String (Fallback to Log3)
subtest 'Device Name String' => sub {
    $log3_calls = [];
    FHEM::Devices::SIGNALduino::SD_Logger::Log('StringDevice', 1, 'Test Message 3');
    
    is(@$log3_calls, 1, 'main::Log3 was called exactly once');
    
    if (@$log3_calls) {
        my $call = $log3_calls->[0];
        is($call->{sub_name}, 'Log3', 'Called sub is Log3');
        is($call->{args}, ['StringDevice', 1, 'Test Message 3'], 'Log3 arguments match');
    }
};

# Test Case 4: Generic Fallback (undef)
subtest 'Generic Fallback' => sub {
    $log3_calls = [];
    FHEM::Devices::SIGNALduino::SD_Logger::Log(undef, 5, 'Test Message 4');
    
    is(@$log3_calls, 1, 'main::Log3 was called exactly once');
    
    if (@$log3_calls) {
        my $call = $log3_calls->[0];
        is($call->{sub_name}, 'Log3', 'Called sub is Log3');
        is($call->{args}, [undef, 5, 'Test Message 4'], 'Log3 arguments match');
    }
};

# Test Case 5: Empty Hash (Fallback logic check)
subtest 'Empty Hash Fallback' => sub {
    my $empty_hash = {};
    $log3_calls = [];
    FHEM::Devices::SIGNALduino::SD_Logger::Log($empty_hash, 2, 'Test Message 5');
    
    is(@$log3_calls, 1, 'main::Log3 was called exactly once');
    
    if (@$log3_calls) {
        my $call = $log3_calls->[0];
        is($call->{sub_name}, 'Log3', 'Called sub is Log3');
        is($call->{args}, [$empty_hash, 2, 'Test Message 5'], 'Log3 arguments match');
    }
};

done_testing();
