use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Mock;
use Test2::Tools::Subtest;
use Test2::API qw(context);
use Data::Dumper;

# Globale $defs aus FHEM simulieren
our %defs;

my $device_name = 'mySignalduino';
my $targetHash = {
    NAME     => $device_name,
    MSGCNT   => 0,
    TIME     => 0,
    DMSG     => 'init',
    LASTDMSG => 'init',
};

# Testdaten
my $valid_json = <<'EOF';
{
  "rawmsg": "r123456",
  "payload": "DMSG123",
  "metadata": {
    "rssi": -70,
    "freqafc": 433.92
  },
  "protocol": {
    "id": "1",
    "name": "DummyProtocol"
  }
}
EOF

# Erforderliche Module vor dem Test laden
require FHEM::Devices::SIGNALDuino::Logger;
require FHEM::Devices::SIGNALDuino::Message;
require JSON; # explizit laden, da DispatchFromJson es eval't

# Mocken der Log-Funktion, um Log-Ausgaben zu erfassen
my @log_calls;
my $log_mock = Test2::Mock->new(
    class   => 'FHEM::Devices::SIGNALDuino::Logger',
    override =>[
        Log => sub {
            my ($dev_or_name, $level, $msg) = @_;
            push @log_calls, { dev_or_name => $dev_or_name, level => $level, msg => $msg };
        },
    ],
);

# Hilfsfunktion zum Zurücksetzen der Log-Calls
sub reset_log_calls { @log_calls = (); }

# --- Testfall 1: Erfolgreicher DispatchFromJson Aufruf ---
subtest 'Erfolgreicher DispatchFromJson Aufruf' => sub {
    reset_log_calls();
    plan(9); # 6 in Dispatch-Mock + 3 Log-Checks
    
    # mock %defs
    $defs{$device_name} = $targetHash;
        
    my $dispatch_mock = Test2::Mock->new(
        class   => 'FHEM::Devices::SIGNALDuino::Message',
        override => {
            Dispatch => sub {
                my ($hash_arg, $rmsg_arg, $dmsg_arg, $rssi_arg, $id_arg, $freqafc_arg) = @_;
                
                # Verify Dispatch calles with correct parameters
                is( $hash_arg,    $targetHash,      "Dispatch: hash-Referenz ist korrekt" );
                is( $rmsg_arg,    "r123456",   "Dispatch: rawmsg ist korrekt" );
                is( $dmsg_arg,    "DMSG123",   "Dispatch: dmsg (payload) ist korrekt" );
                is( $rssi_arg,    -70,         "Dispatch: rssi ist korrekt" );
                is( $id_arg,      "1",         "Dispatch: protocol ID ist korrekt" );
                is( $freqafc_arg, 433.92,      "Dispatch: freqafc ist korrekt" );
            },
        },
    );

    # Execute function under test
    FHEM::Devices::SIGNALDuino::Message::json2Dispatch($valid_json, $device_name);
    $dispatch_mock->reset_all();

    # Verify Logmessages
    is( scalar @log_calls, 1, "Genau 1 Log-Eintrag für erfolgreichen Aufruf" );
    like( $log_calls[0]->{msg}, qr/Calling SIGNALduno_Dispatch with dmsg=DMSG123, id=1/, "Korrekte Log-Meldung vor Dispatch-Aufruf" );
    is( $log_calls[0]->{level}, 5, "Korrekter Log-Level 5" );

    $defs{$device_name} = $targetHash; # Reset
};

# --- Testfall 2: Fehlende Argumente (JSON-String) ---
subtest 'Fehlender JSON-String ($json_str undef)' => sub {
    reset_log_calls();
    plan(3);
    
    FHEM::Devices::SIGNALDuino::Message::json2Dispatch(undef, $device_name);

    is( scalar @log_calls, 1, "Genau 1 Log-Eintrag für fehlenden JSON-String" );
    like( $log_calls[0]->{msg}, qr/Missing arguments \(JSON or Name\)/, "Log: Fehlende Argumente erkannt" );
    is( $log_calls[0]->{level}, 3, "Korrekter Log-Level 3" );
};

# --- Testfall 3: Fehlende Argumente (Device-Name) ---
subtest 'Fehlender Device-Name ($name undef)' => sub {
    reset_log_calls();
    plan(3);
    
    FHEM::Devices::SIGNALDuino::Message::json2Dispatch($valid_json, undef);

    is( scalar @log_calls, 1, "Genau 1 Log-Eintrag für fehlenden Namen" );
    like( $log_calls[0]->{msg}, qr/Missing arguments \(JSON or Name\)/, "Log: Fehlende Argumente erkannt" );
    is( $log_calls[0]->{level}, 3, "Korrekter Log-Level 3" );
};

# --- Testfall 4: Device nicht in %defs gefunden ---
subtest 'Device nicht in %defs gefunden' => sub {
    reset_log_calls();
    plan(3);
    
    delete $defs{$device_name}; # Sicherstellen, dass es nicht existiert
    
    FHEM::Devices::SIGNALDuino::Message::json2Dispatch($valid_json, $device_name);

    is( scalar @log_calls, 1, "Genau 1 Log-Eintrag für nicht gefundenes Device" );
    like( $log_calls[0]->{msg}, qr/Device $device_name not found/, "Log: Device nicht gefunden" );
    is( $log_calls[0]->{level}, 3, "Korrekter Log-Level 3" );
};


# --- Testfall 5: Ungültiger JSON-String ---
subtest 'Ungültiger JSON-String' => sub {
    reset_log_calls();
    plan(3);
    
    my $invalid_json = '{"rawmsg": "r123456"'; # Fehlende schließende Klammer
    
    # Vorbereitung: %defs setzen
    $defs{$device_name} = $targetHash;
    
    FHEM::Devices::SIGNALDuino::Message::json2Dispatch($invalid_json, $device_name);

    is( scalar @log_calls, 1, "Genau 1 Log-Eintrag für JSON-Decodierfehler" );
    like( $log_calls[0]->{msg}, qr/JSON decode error: /, "Log: JSON decode error erkannt" );
    is( $log_calls[0]->{level}, 3, "Korrekter Log-Level 3" );
    
    delete $defs{$device_name}; # Zurücksetzen
};

# --- Testfall 6: Fehlendes 'payload' (dmsg) ---
subtest 'Fehlendes \'payload\' (dmsg)' => sub {
    reset_log_calls();
    plan(3);
    
    my $missing_dmsg_json = <<'EOF';
{
  "rawmsg": "r123456",
  "metadata": {
    "rssi": -70
  },
  "protocol": {
    "id": "1"
  }
}
EOF
    
    # Vorbereitung: %defs setzen
    $defs{$device_name} = $targetHash;
    
    FHEM::Devices::SIGNALDuino::Message::json2Dispatch($missing_dmsg_json, $device_name);

    is( scalar @log_calls, 1, "Genau 1 Log-Eintrag für fehlende dmsg/ID" );
    like( $log_calls[0]->{msg}, qr/Missing dmsg or protocol ID in JSON/, "Log: Fehlende dmsg/ID erkannt" );
    is( $log_calls[0]->{level}, 4, "Korrekter Log-Level 4" );
    
    delete $defs{$device_name}; # Zurücksetzen
};

# --- Testfall 7: Fehlendes 'protocol->id' ---
subtest 'Fehlendes \'protocol->id\'' => sub {
    reset_log_calls();
    plan(3);
    
    my $missing_id_json = <<'EOF';
{
  "rawmsg": "r123456",
  "payload": "DMSG123",
  "metadata": {
    "rssi": -70
  },
  "protocol": {
    "name": "DummyProtocol"
  }
}
EOF
    
    # Vorbereitung: %defs setzen
    $defs{$device_name} = $targetHash;
    
    FHEM::Devices::SIGNALDuino::Message::json2Dispatch($missing_id_json, $device_name);

    is( scalar @log_calls, 1, "Genau 1 Log-Eintrag für fehlende protocol ID" );
    like( $log_calls[0]->{msg}, qr/Missing dmsg or protocol ID in JSON/, "Log: Fehlende dmsg/ID erkannt" );
    is( $log_calls[0]->{level}, 4, "Korrekter Log-Level 4" );
    
    delete $defs{$device_name}; # Zurücksetzen
};

# Aufräumen des Log-Mocks
$log_mock->reset_all();


done_testing;