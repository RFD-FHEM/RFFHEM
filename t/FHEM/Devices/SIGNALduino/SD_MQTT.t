use Test2::V0;
use lib 'lib';

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
    plan(7);
    my $topic = 'some/state/messages/test';
    my $value = '{"foo":"bar"}';
    
    my $log_called = 0;
    my $dispatch_called = 0;
    
    # Override Log to verify arguments
    $mock_logger->override(
        Log => sub {
            my ($h, $lvl, $msg) = @_;
            $log_called++;
            is($h, $hash, 'Log: Hash matches');
            is($lvl, 5, 'Log: Level is 5');
            like($msg, qr/SIGNALduino MQTT message ignored: topic=\Q$topic\E, value=\Q$value\E/, 'Log: Message matches');
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
    
    ok($log_called, 'SD_Logger::Log was called');
    ok($dispatch_called, 'SD_Message::json2Dispatch was called');
};

subtest 'Topic does NOT match /state/messages/' => sub {
    plan(2);
    my $topic = 'some/other/topic';
    my $value = '{"foo":"bar"}';
    
    my $log_called = 0;
    my $dispatch_called = 0;
    
    # Override with simple counters
    $mock_logger->override(
        Log => sub { $log_called++; }
    );
    
    $mock_message->override(
        json2Dispatch => sub { $dispatch_called++; }
    );
    
    FHEM::Devices::SIGNALduino::SD_MQTT::on_message($hash, $topic, $value, $io_name);
    
    is($log_called, 0, 'SD_Logger::Log was NOT called');
    is($dispatch_called, 0, 'SD_Message::json2Dispatch was NOT called');
};

done_testing;
