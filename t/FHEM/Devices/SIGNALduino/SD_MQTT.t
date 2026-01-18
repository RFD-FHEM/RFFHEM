use Test2::V0;
use lib 'lib';

my $mock_Timer = mock 'FHEM::Core::Timer::Helper' => (
    track => 1, # Enable call tracking if needed, though we use overrides below
    add => {
        addTimer => sub {
            my ($name, $time, $func, $param, $repeat) = @_;
            return 1; # Mocked behavior
        },
    },
);

my $mock_MQTT = mock 'FHEM::Devices::SIGNALduino::SD_MQTT' => (
    track => 1, # Enable call tracking if needed, though we use overrides below
    add => {
        on_mqtt => sub {
            my ($self, $subscription, $fn) = @_;
            return 1; # Mocked behavior
        },
        del_mqtt => sub {
            my ($self, $listener) = @_;
            return 1; # Mocked behavior
        },
    },
);


# Load the module to be tested
require FHEM::Devices::SIGNALduino::SD_MQTT;

# Create mocks
my $mock_logger = mock 'FHEM::Devices::SIGNALduino::SD_Logger' => (
    track => 1, # Enable call tracking if needed, though we use overrides below
);

my $mock_message = mock 'FHEM::Devices::SIGNALduino::SD_Message' => (
    track => 1,
);

my $hash = { NAME => 'MySIGNALduino' };
my $io_name = 'MyIO';

subtest 'Topic matches /state/messages/' => sub {
    plan(4);
    my $topic = 'some/state/messages/test';
    my $value = '{"foo":"bar"}';
    
    my $log_called = 0;
    my $dispatch_called = 0;
    
    # Override Log to verify arguments
    $mock_logger->override(
        Log => sub {
            $log_called++;
            return;
        }
    );
    
    # Override json2Dispatch to verify arguments
    $mock_message->override(
        json2Dispatch => sub {
            my ($val, $name) = @_;
            $dispatch_called++;
            is($val, $value, 'json2Dispatch: Value matches');
            is($name, $hash->{NAME}, 'json2Dispatch: Name matches');
            return;
        }
    );
    
    FHEM::Devices::SIGNALduino::SD_MQTT::on_message($hash, $topic, $value, $io_name);
    
    is($log_called,0, 'SD_Logger::Log was called');
    ok($dispatch_called, 'SD_Message::json2Dispatch was called');
};

subtest 'Init (delayed)' => sub {
    plan(5);

    my $addTimer_called = 0;
    my $log_called = 0;

    # Set up delayed init context
    local $main::init_done = 0;
    local $main::defs{$hash->{NAME}} = $hash;

    $mock_Timer->override(
        addTimer => sub {
            my ($name, $time, $func, $param, $repeat) = @_;
            $addTimer_called++;
            is($func, \&FHEM::Devices::SIGNALduino::SD_MQTT::Init, 'addTimer: function is Init');
            return 1;
        }
    );

    $mock_logger->override(
        Log => sub {
            my ($h, $lvl, $msg) = @_;
            $log_called++;
            is($lvl, 3, 'Log: Level is 3');
            like($msg, qr/: InitMQTT, init not done, delayed.../, 'Log: Message indicates delayed init');
            return;
        }
    );

    FHEM::Devices::SIGNALduino::SD_MQTT::Init($hash->{NAME});

    is($addTimer_called, 1, 'FHEM::Core::Timer::Helper::addTimer was called once');
    is($log_called, 1, 'SD_Logger::Log was called once');

    $mock_Timer->restore('addTimer');
    $mock_logger->restore('Log');
};

subtest 'Init (successful registration)' => sub {
    plan(8);

    my $on_mqtt_called = 0;
    my $del_mqtt_called = 0;
    my $log_called = 0;

    local $main::init_done = 1;
    local $main::defs{$hash->{NAME}} = $hash;

    $hash->{mqttSubscribe} = 'fhem/signalduino/state/messages/+';
    $hash->{Listener} = 'old_listener_handle'; # Existing listener for del_mqtt test

    $mock_MQTT->override(
        on_mqtt => sub {
            my ($subscription, $fn) = @_;
            $on_mqtt_called++;
            is($subscription, $hash->{mqttSubscribe}, 'on_mqtt: Subscription topic matches');
            return 'new_listener_handle'; # Return new listener handle
        },
        del_mqtt => sub {
            my ( $listener) = @_;
            $del_mqtt_called++;
            is($listener, 'old_listener_handle', 'del_mqtt: Called with old listener handle');
            return 1;
        }
    );

    $mock_logger->override(
        Log => sub {
            my ($h, $lvl, $msg) = @_;
            $log_called++;
            is($lvl, 3, 'Log: Level is 3');
            like($msg, qr/: InitMQTT, registering listener for /, 'Log: Message indicates registration');
            return;
        }
    );

    FHEM::Devices::SIGNALduino::SD_MQTT::Init($hash->{NAME});

    is($del_mqtt_called, 1, 'del_mqtt was called once to remove old listener');
    is($on_mqtt_called, 1, 'on_mqtt was called once for new registration');
    is($hash->{Listener}, 'new_listener_handle', 'New listener handle stored in $hash->{Listener}');
    is($log_called, 1, 'SD_Logger::Log was called once (Level 3)');

    $mock_Timer->restore('addTimer');
    $mock_logger->restore('Log');
    $mock_MQTT->restore('on_mqtt');
    $mock_MQTT->restore('del_mqtt');
};

subtest 'Init (no subscribe topic)' => sub {
    plan(4);

    my $on_mqtt_called = 0;
    my $log_called = 0;

    local $main::init_done = 1;
    local $main::defs{$hash->{NAME}} = $hash;

    delete $hash->{mqttSubscribe}; # Ensure no subscribe topic
    delete $hash->{Listener};      # Ensure no old listener

    $mock_MQTT->override(
        on_mqtt => sub { $on_mqtt_called++; return 1; },
    );

    $mock_logger->override(
        Log => sub {
            my ($h, $lvl, $msg) = @_;
            $log_called++;
            is($lvl, 2, 'Log: Level is 2 (Error)');
            like($msg, qr/: InitMQTT, no mqttSubscribe topic found/, 'Log: Message indicates missing topic');
            return;
        }
    );

    FHEM::Devices::SIGNALduino::SD_MQTT::Init($hash->{NAME});

    is($on_mqtt_called, 0, 'on_mqtt was NOT called');
    is($log_called, 1, 'SD_Logger::Log was called once (Level 2)');
    $mock_MQTT->restore('on_mqtt');
    $mock_logger->restore('Log');
};

subtest 'Topic does NOT match /state/messages/' => sub {
    plan(3);
    my $topic = 'some/other/topic';
    my $value = '{"foo":"bar"}';

    my $log_called = 0;
    my $dispatch_called = 0;

    # Override with simple counters
    $mock_logger->override(
        Log => sub { 
            my ($h, $lvl, $msg) = @_;
            like($msg, qr/ignored: topic=$topic/, 'Log: Message indicates missing topic');
            $log_called++;
        }
    );

    $mock_message->override(
        json2Dispatch => sub { $dispatch_called++; }
    );

    FHEM::Devices::SIGNALduino::SD_MQTT::on_message($hash, $topic, $value, $io_name);

    is($log_called, 1, 'SD_Logger::Log was called');
    is($dispatch_called, 0, 'SD_Message::json2Dispatch was NOT called');
    $mock_logger->restore('Log');
    $mock_message->restore('json2Dispatch');
};

done_testing;
