#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{ is };
use Test2::Mock;

# Modul laden
require FHEM::Devices::SIGNALDuino::Dispatch;
# Mock-Objekt für den Dispatcher erstellen
my $dispatcher = 'FHEM::Devices::SIGNALDuino::Dispatch';

# Globale $defs für FHEM-Kontext (wird in MqttSignalduino_DispatchFromJSON benötigt)
our %defs;

# Mock für FHEM-Core-Funktionen
my $mock = Test2::Mock->new(
    track => 1,
    class => 'main',
    around => [
        # InternalVal wird im Originaltest zur Überprüfung verwendet
        InternalVal => sub { 
            my $orig = shift;
            my ($hashName, $key, $default) = @_;
            # In diesem Mock geben wir die Werte von $defs{$hashName} zurück
            return $defs{$hashName}{_INTERNAL_}{$key} // $default;
        },
        # DoTrigger wird von SIGNALduno_Dispatch aufgerufen
        DoTrigger => sub { 
            my $orig = shift;
            my ($name, $trigger) = @_;
            note "Mocked main::DoTrigger called: $name, $trigger";
        },
        # Dispatch wird von SIGNALduno_Dispatch aufgerufen
        Dispatch => sub { 
            my $orig = shift;
            my ($hash, $dmsg, $addvals) = @_;
            note "Mocked main::Dispatch called for: $dmsg";
            # Hier könnten weitere Checks auf $addvals durchgeführt werden
        },
        # AttrVal wird von SIGNALduno_Dispatch aufgerufen
        AttrVal => sub {
            my $orig = shift;
            my ($name, $key, $default) = @_;
            # Default-Verhalten simulieren: 0 für 'suppressDeviceRawmsg'
            return ($key eq 'suppressDeviceRawmsg') ? 0 : $default;
        }
    ],
);
my $tracking = $mock->sub_tracking;


plan(4);

note("Test of SIGNALduno_Dispatch in FHEM::Devices::SIGNALDuino::Dispatch");

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

# SIGNALduno_Dispatch($hash, $rmsg, $dmsg, $rssi, $id, $freqafc)
$dispatcher->SIGNALduno_Dispatch($targetHash, $rmsg, $dmsg, $rssi, $id);

# Checks:
# 1. main::Dispatch wurde einmal aufgerufen (ersetzt den Mock auf SIGNALduno_Dispatch selbst)
# 2. $dmsg wurde an main::Dispatch übergeben
# 3. $targetHash->{LASTDMSG} wurde gesetzt
# 4. $targetHash->{LASTDMSGID} wurde gesetzt

is(scalar @{$tracking->{Dispatch}}, 1, "main::Dispatch was called once");
is($tracking->{Dispatch}[0]{args}[1], $dmsg, "check dmsg passed to main::Dispatch" );
is($targetHash->{LASTDMSG}, $dmsg, "check $deviceName LASTDMSG" );
is($targetHash->{LASTDMSGID}, $id, "check $deviceName LASTDMSGID" );

$mock->restore();
done_testing();
