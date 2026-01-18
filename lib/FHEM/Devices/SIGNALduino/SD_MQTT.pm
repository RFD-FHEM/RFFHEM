package FHEM::Devices::SIGNALduino::SD_MQTT;

use strict;
use warnings;
use FHEM::Devices::SIGNALduino::SD_Logger;
use FHEM::Devices::SIGNALduino::SD_Message;

sub on_message {
    my ($hash, $topic, $value, $io_name) = @_;
    
    # Process message topic
    if ($topic =~ m{state/messages}) {
        FHEM::Devices::SIGNALduino::SD_Logger::Log($hash, 5, "SIGNALduino MQTT message ignored: topic=$topic, value=$value");
        FHEM::Devices::SIGNALduino::SD_Message::json2Dispatch($value, $hash->{NAME});
        return;
    }

    return;
}

1;

=pod

=head1 NAME

FHEM::Devices::SIGNALduino::SD_MQTT - MQTT handler for SIGNALduino

=head1 SYNOPSIS

    use FHEM::Devices::SIGNALduino::SD_MQTT;
    FHEM::Devices::SIGNALduino::SD_MQTT::on_message($hash, $topic, $value, $io_name);

=head1 DESCRIPTION

Handles incoming MQTT messages for SIGNALduino.

=head1 FUNCTIONS

=head2 on_message($hash, $topic, $value, $io_name)

Callback function for MQTT2_Dispatcher.

=cut
