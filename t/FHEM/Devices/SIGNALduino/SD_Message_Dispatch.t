#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{ is };
use Test2::Mock;

use vars qw(%defs);             # Mock FHEM device/button definitions

# Mock FHEM-Core functions
my $mock = Test2::Mock->new(
    track => 1,
    class => 'main',
    add => [
        # DoTrigger 
        DoTrigger => sub { 
            my ($name, $trigger) = @_;
            note "Mocked main::DoTrigger called: $name, $trigger";
        },
        # Dispatch 
        Dispatch => sub { 
            my ($hash, $dmsg, $addvals) = @_;
            note "Mocked main::Dispatch called for: $dmsg";
            # additional checks possible
        },
        # AttrVal 
        AttrVal => sub {
            my ($name, $key, $default) = @_;
            # Default  simulating: 0 for 'suppressDeviceRawmsg'
            note 'Mocked main::AttrVal called: ' . $key;
            return ($key eq 'suppressDeviceRawmsg') ? 0 : $default;
        },
        Log3 => sub {
            my ($name, $level, $message) = @_;
            note "Mocked main::Log3 called: Level $level, Message: $message";
        }
    ],
);
my $tracking = $mock->sub_tracking;


# Modul laden
require FHEM::Devices::SIGNALduino::SD_Message;

subtest 'Test of SIGNALduno_Dispatch in FHEM::Devices::SIGNALduino::SD_Message' => sub {

    # Dummy-Hash für den Test
    my $deviceName = 'dummyDuino';
    my $targetHash = {
        NAME => $deviceName,
        LASTDMSG => '',
        LASTDMSGID => '',
        DMSG => '', # Is modified in Message::Dispatch 
        TIME => 0, # Is modified in Message::Dispatch gesetzt
        MSGCNT => 0, # Is modified in Message::Dispatch gesetzt
        INTERNAL => {
            LASTDMSG => '',
            LASTDMSGID => '',
        },
    };
    $defs{$deviceName} = $targetHash;

    my $rmsg="MS;P2=463;P3=-1957;P5=-3906;P6=-9157;D=26232523252525232323232323252323232323232325252523252325252323252325232525;CP=2;SP=6;R=75;";
    my $dmsg="s5C080EB2B000";
    my $rssi="-36.4";
    my $id="0.3";

    plan(4);

    FHEM::Devices::SIGNALduino::SD_Message::Dispatch($targetHash, $rmsg, $dmsg, $rssi, $id);

    is(scalar @{$tracking->{Dispatch}}, 1, "main::Dispatch was called once");
    is($tracking->{Dispatch}[0]{args}[1], $dmsg, "check dmsg passed to main::Dispatch" );
    is($targetHash->{LASTDMSG}, $dmsg, "check $deviceName LASTDMSG" );
    is($targetHash->{LASTDMSGID}, $id, "check $deviceName LASTDMSGID" );

    $mock->reset_all();
};
plan(1);
done_testing();
