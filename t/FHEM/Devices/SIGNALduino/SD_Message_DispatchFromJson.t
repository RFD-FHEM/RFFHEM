use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Mock;
use Test2::Tools::Subtest;
use Test2::API qw(context);
use Data::Dumper;

# Globale $defs aus FHEM simulieren
our main::%defs;

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
  "raw": "r123456",
  "data": "DMSG123",
  "metadata": {
    "rssi": -70,
    "freq_afc": 433.92
  },
  "protocol": {
    "id": "1",
    "name": "DummyProtocol",
    "preamble": "P1#"
  }
}
EOF

# Erforderliche Module vor dem Test laden
require FHEM::Devices::SIGNALduino::SD_Logger;
require FHEM::Devices::SIGNALduino::SD_Message;
require FHEM::Devices::SIGNALduino::SD_Matchlist;
require FHEM::Devices::SIGNALduino::SD_Clients;
require JSON; # explizit laden, da DispatchFromJson es eval't

# Mocken der Log-Funktion, um Log-Ausgaben zu erfassen
my @log_calls;
my $log_mock = Test2::Mock->new(
    class   => 'FHEM::Devices::SIGNALduino::SD_Logger',
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
    plan(11); # 6 in Dispatch-Mock + 5 Log-Checks
    
    # mock %defs
    $defs{$device_name} = $targetHash;
        
    my $dispatch_mock = Test2::Mock->new(
        class   => 'FHEM::Devices::SIGNALduino::SD_Message',
        override => {
            Dispatch => sub {
                my ($hash_arg, $rmsg_arg, $dmsg_arg, $rssi_arg, $id_arg, $freqafc_arg) = @_;
                
                # Verify Dispatch calles with correct parameters
                is( $hash_arg,    $targetHash,      "Dispatch: hash-Referenz ist korrekt" );
                is( $rmsg_arg,    'r123456',   "Dispatch: raw ist korrekt" );
                is( $dmsg_arg,    'P1#DMSG123',   "Dispatch: dmsg (data) ist korrekt" );
                is( $rssi_arg,    -70,         "Dispatch: rssi ist korrekt" );
                is( $id_arg,      '1',         "Dispatch: protocol ID ist korrekt" );
                is( $freqafc_arg, 433.92,      "Dispatch: freq_afc ist korrekt" );
            },
        },
    );

    # Execute function under test
    FHEM::Devices::SIGNALduino::SD_Message::json2Dispatch($valid_json, $device_name);
    $dispatch_mock->reset_all();

    # Verify Logmessages
    is( scalar @log_calls, 2, "Genau 2 Log-Einträge für erfolgreichen Aufruf (Init + Calling)" );
    
    # Init Log
    like( $log_calls[0]->{msg}, qr/json2Dispatch: Matchlist\/Clientlist initialization/, "Log: Initialisierung" );
    is( $log_calls[0]->{level}, 4, "Korrekter Log-Level 4 (Init)" );

    # Calling Log
    like( $log_calls[1]->{msg}, qr/Calling .* with dmsg=P1#DMSG123, id=1/, "Korrekte Log-Meldung vor Dispatch-Aufruf" );
    is( $log_calls[1]->{level}, 5, "Korrekter Log-Level 5 (Calling)" );

    $defs{$device_name} = $targetHash; # Reset
};

# --- Testfall 2: Fehlende Argumente (JSON-String) ---
subtest 'Fehlender JSON-String ($json_str undef)' => sub {
    reset_log_calls();
    plan(3);
    
    FHEM::Devices::SIGNALduino::SD_Message::json2Dispatch(undef, $device_name);

    is( scalar @log_calls, 1, "Genau 1 Log-Eintrag für fehlenden JSON-String" );
    like( $log_calls[0]->{msg}, qr/Missing arguments \(JSON or Name\)/, "Log: Fehlende Argumente erkannt" );
    is( $log_calls[0]->{level}, 3, "Korrekter Log-Level 3" );
};

# --- Testfall 3: Fehlende Argumente (Device-Name) ---
subtest 'Fehlender Device-Name ($name undef)' => sub {
    reset_log_calls();
    plan(3);
    
    FHEM::Devices::SIGNALduino::SD_Message::json2Dispatch($valid_json, undef);

    is( scalar @log_calls, 1, "Genau 1 Log-Eintrag für fehlenden Namen" );
    like( $log_calls[0]->{msg}, qr/Missing arguments \(JSON or Name\)/, "Log: Fehlende Argumente erkannt" );
    is( $log_calls[0]->{level}, 3, "Korrekter Log-Level 3" );
};

# --- Testfall 4: Device nicht in %defs gefunden ---
subtest 'Device nicht in %defs gefunden' => sub {
    reset_log_calls();
    plan(3);
    
    delete $defs{$device_name}; # Sicherstellen, dass es nicht existiert
    
    FHEM::Devices::SIGNALduino::SD_Message::json2Dispatch($valid_json, $device_name);

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
    
    FHEM::Devices::SIGNALduino::SD_Message::json2Dispatch($invalid_json, $device_name);

    is( scalar @log_calls, 1, "Genau 1 Log-Eintrag für JSON-Decodierfehler" );
    like( $log_calls[0]->{msg}, qr/JSON decode error: /, "Log: JSON decode error erkannt" );
    is( $log_calls[0]->{level}, 3, "Korrekter Log-Level 3" );
    
    delete $defs{$device_name}; # Zurücksetzen
};

# --- Testfall 6: Fehlendes 'payload' (dmsg) ---
subtest q[Fehlendes 'data' (dmsg)] => sub {
    reset_log_calls();
    plan(3);
    
    my $missing_dmsg_json = <<'EOF';
{
  "raw": "r123456",
  "protocol_id": "1",
  "metadata": {
    "rssi": -70,
    "freq_afc": 433.92
  },
  "protocol": {
    "id": "1"
  }
}
EOF
    
    # Vorbereitung: %defs setzen
    $defs{$device_name} = $targetHash;
    
    FHEM::Devices::SIGNALduino::SD_Message::json2Dispatch($missing_dmsg_json, $device_name);

    is( scalar @log_calls, 1, "Genau 1 Log-Eintrag für fehlende dmsg/ID" );
    like( $log_calls[0]->{msg}, qr/Missing 'data' in JSON/, "Log: Fehlendes data erkannt" );
    is( $log_calls[0]->{level}, 4, "Korrekter Log-Level 4" );
    
    delete $defs{$device_name}; # Zurücksetzen
};

# --- Testfall 7: Fehlendes 'protocol->id' ---
subtest q[Fehlendes 'protocol->id'] => sub {
    reset_log_calls();
    plan(3);
    
    my $missing_id_json = <<'EOF';
{
  "raw": "r123456",
  "data": "DMSG123",
  "metadata": {
    "rssi": -70,
    "freq_afc": 433.92
  },
  "protocol": {
    "name": "DummyProtocol"
  }
}
EOF
    
    # Vorbereitung: %defs setzen
    $defs{$device_name} = $targetHash;
    
    FHEM::Devices::SIGNALduino::SD_Message::json2Dispatch($missing_id_json, $device_name);

    is( scalar @log_calls, 1, "Genau 1 Log-Eintrag für fehlende protocol ID" );
    like( $log_calls[0]->{msg}, qr/Missing ' "protocol":{id:}" ' in JSON/, "Log: Fehlende dmsg/ID erkannt" );
    is( $log_calls[0]->{level}, 4, "Korrekter Log-Level 4" );
    
    delete $defs{$device_name}; # Zurücksetzen
};

# --- Testfall 8: Initialisierung erzwingen (matchlist und clients sind undefiniert) ---
subtest 'Testfall 8: Initialisierung erzwingen (matchlist und clients sind undefiniert)' => sub {
    reset_log_calls();
    plan(4);

    # Mock Matchlist und Clients
    my $match_mock = Test2::Mock->new(
        class => 'FHEM::Devices::SIGNALduino::SD_Matchlist',
        override => {
            getMatchListasRef => sub { return { 'TEST_PATTERN' => 1 }; }
        }
    );
    my $clients_mock = Test2::Mock->new(
        class => 'FHEM::Devices::SIGNALduino::SD_Clients',
        override => {
            getClientsasStr => sub { return 'ClientA,ClientB'; }
        }
    );

    # Mock Dispatch, da es am Ende aufgerufen wird
    my $dispatch_mock = Test2::Mock->new(
        class   => 'FHEM::Devices::SIGNALduino::SD_Message',
        override => {
            Dispatch => sub { return; }
        },
    );

    # Setup targetHash ohne matchlist/clients
    delete $targetHash->{MatchList};
    delete $targetHash->{Clients};
    $defs{$device_name} = $targetHash;

    # Execute
    FHEM::Devices::SIGNALduino::SD_Message::json2Dispatch($valid_json, $device_name);

    # Checks
    my ($init_log) = grep { $_->{msg} =~ /json2Dispatch: Matchlist\/Clientlist initialization/ } @log_calls;
    ok( $init_log, "Log: 'Matchlist/Clientlist initialization' gefunden" );
    is( $init_log->{level}, 4, "Log-Level ist 4" );

    is( $targetHash->{MatchList}, { 'TEST_PATTERN' => 1 }, 'matchlist korrekt initialisiert' );
    is( $targetHash->{Clients}, 'ClientA,ClientB', 'clients korrekt initialisiert' );
    
    $match_mock->reset_all();
    $clients_mock->reset_all();
    $dispatch_mock->reset_all();
};

# --- Testfall 9: Initialisierung überspringen (matchlist und clients sind definiert) ---
subtest 'Testfall 9: Initialisierung überspringen (matchlist und clients sind definiert)' => sub {
    reset_log_calls();
    plan(4);

    # Setup targetHash MIT matchlist/clients
    $targetHash->{MatchList} = { 'EXIST' => 1 };
    $targetHash->{Clients} = 'ExistingClients';
    $defs{$device_name} = $targetHash;

    # Mocks, die NICHT aufgerufen werden sollen
    my $match_mock = Test2::Mock->new(
        class => 'FHEM::Devices::SIGNALduino::SD_Matchlist',
        override => {
            getMatchListasRef => sub { fail "Should not be called"; }
        }
    );
    my $clients_mock = Test2::Mock->new(
        class => 'FHEM::Devices::SIGNALduino::SD_Clients',
        override => {
            getClientsasStr => sub { fail "Should not be called"; }
        }
    );

    # Mock Dispatch
    my $dispatch_mock = Test2::Mock->new(
        class   => 'FHEM::Devices::SIGNALduino::SD_Message',
        override => {
            Dispatch => sub { return; }
        },
    );

    # Execute
    eval { FHEM::Devices::SIGNALduino::SD_Message::json2Dispatch($valid_json, $device_name); };
    is( $@, '', "Kein Fehler durch unerwarteten Aufruf der Mocks" );

    # Checks
    my ($init_log) = grep { $_->{msg} =~ /json2Dispatch: Matchlist\/Clientlist initialization/ } @log_calls;
    ok( !$init_log, "Log: 'Matchlist/Clientlist initialization' NICHT gefunden" );

    is( $targetHash->{MatchList}, { 'EXIST' => 1 }, "matchlist nicht überschrieben" );
    is( $targetHash->{Clients}, 'ExistingClients', "clients nicht überschrieben" );

    $match_mock->reset_all();
    $clients_mock->reset_all();
    $dispatch_mock->reset_all();
};

# Aufräumen des Log-Mocks
$log_mock->reset_all();


done_testing;