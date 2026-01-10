#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{ is };
use Test2::Mock;

# Globale $defs für FHEM-Kontext (wird in MqttSignalduino_DispatchFromJSON benötigt)
my %defs;

# Mock für FHEM-Core-Funktionen
my $mock = Test2::Mock->new(
    track => 1,
    class => 'main',
    add => [
        # InternalVal wird im Originaltest zur Überprüfung verwendet
        InternalVal => sub { 
            my ($hashName, $key, $default) = @_;
            # In diesem Mock geben wir die Werte von $defs{$hashName} zurück
            return $defs{$hashName}{_INTERNAL_}{$key} // $default;
        },
        # DoTrigger wird von SIGNALduno_Dispatch aufgerufen
        DoTrigger => sub { 
            my ($name, $trigger) = @_;
            note "Mocked main::DoTrigger called: $name, $trigger";
        },
        # Dispatch wird von SIGNALduno_Dispatch aufgerufen
        Dispatch => sub { 
            my ($hash, $dmsg, $addvals) = @_;
            note "Mocked main::Dispatch called for: $dmsg";
            # Hier könnten weitere Checks auf $addvals durchgeführt werden
        },
        # AttrVal wird von SIGNALduno_Dispatch aufgerufen
        AttrVal => sub {
            my ($name, $key, $default) = @_;
            # Default-Verhalten simulieren: 0 für 'suppressDeviceRawmsg'
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
require FHEM::Devices::SIGNALDuino::Dispatch;

subtest 'Test of SIGNALduno_Dispatch in FHEM::Devices::SIGNALDuino::Dispatch' => sub {

    # Dummy-Hash für den Test
    my $deviceName = 'dummyDuino';
    my $targetHash = {
        NAME => $deviceName,
        LASTDMSG => '',
        LASTDMSGID => '',
        DMSG => '', # Wird in SIGNALduno_Dispatch gesetzt
        TIME => 0, # Wird in SIGNALduno_Dispatch gesetzt
        MSGCNT => 0, # Wird in SIGNALduno_Dispatch gesetzt
        # Für InternalVal Mock:
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

    # SIGNALduno_Dispatch($hash, $rmsg, $dmsg, $rssi, $id, $freqafc)
    FHEM::Devices::SIGNALDuino::Dispatch::Dispatch($targetHash, $rmsg, $dmsg, $rssi, $id);

    # Checks:
    # 1. main::Dispatch wurde einmal aufgerufen
    # 2. $dmsg wurde an main::Dispatch übergeben
    # 3. $targetHash->{LASTDMSG} wurde gesetzt
    # 4. $targetHash->{LASTDMSGID} wurde gesetzt

    is(scalar @{$tracking->{Dispatch}}, 1, "main::Dispatch was called once");
    is($tracking->{Dispatch}[0]{args}[1], $dmsg, "check dmsg passed to main::Dispatch" );
    is($targetHash->{LASTDMSG}, $dmsg, "check $deviceName LASTDMSG" );
    is($targetHash->{LASTDMSGID}, $id, "check $deviceName LASTDMSGID" );

    $mock->reset_all();
};
plan(1);
done_testing();
