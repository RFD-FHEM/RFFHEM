# $Id: SD_MQTT.pm 0 2026-01-10 15:36:13Z sidey79 $
# The file is part of the SIGNALduino project.
# MQTT helper for SIGNALduino device messages.


package FHEM::Devices::SIGNALduino::SD_MQTT;

use strict;
use warnings;
use FHEM::Devices::SIGNALduino::SD_Logger;
use FHEM::Devices::SIGNALduino::SD_Message;
eval {
    require FHEM::Utility::MQTT2_Dispatcher;
    FHEM::Utility::MQTT2_Dispatcher->import(qw(:DEFAULT));
} ;
eval { require FHEM::Core::Timer::Helper; } ;

sub Init {
    my $name = shift;
    my $hash = $main::defs{$name};

    if (!$main::init_done) {
        FHEM::Devices::SIGNALduino::SD_Logger::Log($hash, 3, "$name: InitMQTT, init not done, delayed...");
        FHEM::Core::Timer::Helper::addTimer($name, time() + 0, \&Init, $name, 0);
        return;
    }

    my $mqtt_topic = $hash->{mqttSubscribe};
    if (defined($mqtt_topic)) {
        FHEM::Devices::SIGNALduino::SD_Logger::Log($hash, 3, "$name: InitMQTT, registering listener for $mqtt_topic");

        if (defined($hash->{Listener})) {
             del_mqtt($hash->{Listener});
             delete $hash->{Listener};
        }

        $hash->{Listener} = on_mqtt($mqtt_topic, sub {
             on_message($hash, @_);
        }) or do {
             FHEM::Devices::SIGNALduino::SD_Logger::Log($hash, 2, "$name: Error creating MQTT listener: $@");
        };
    } else {
        FHEM::Devices::SIGNALduino::SD_Logger::Log($hash, 2, "$name: InitMQTT, no mqttSubscribe topic found");
    }
}

sub on_message {
    my ($hash, $topic, $value, $io_name) = @_;
    
    # Process message topic
    if ($topic =~ m{state/messages}) {
        FHEM::Devices::SIGNALduino::SD_Message::json2Dispatch($value, $hash->{NAME});
        return;
    }
    FHEM::Devices::SIGNALduino::SD_Logger::Log($hash, 5, "SIGNALduino MQTT message ignored: topic=$topic, value=$value");
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
