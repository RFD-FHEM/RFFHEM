package FHEM::Devices::SIGNALDuino::Dispatch; # Aktualisiert

use strict;
use warnings;
eval { require JSON; JSON->import; };

# Neue Subpackages einbinden (Aktualisiert)
require FHEM::Devices::SIGNALDuino::Logger;
require FHEM::Devices::SIGNALDuino::Matchlist; 

# Konstante beibehalten
use constant {
  SDUINO_DISPATCH_VERBOSE         => 5,
};


# Todo Add Clients and Matchlist dynamically to DevAttrList 
# { addToDevAttrList('PySignalDuino', 'Clients');; }

sub SIGNALduno_Dispatch {
  my ($hash, $rmsg, $dmsg, $rssi, $id, $freqafc) = @_;
  my $name = $hash->{NAME};

  if (!defined($dmsg))
  {
    # Logging-Aufruf ersetzt (Aktualisiert)
    FHEM::Devices::SIGNALDuino::Logger::Log($hash, 5, "$name: Dispatch, dmsg is undef. Skipping dispatch call");
    return;
  }

  my $DMSGgleich = 1;
  if ($dmsg eq $hash->{LASTDMSG}) {
    # Logging-Aufruf ersetzt (Aktualisiert)
    FHEM::Devices::SIGNALDuino::Logger::Log($hash, SDUINO_DISPATCH_VERBOSE, "$name: Dispatch, $dmsg, test gleich");
  } else {
    if ( defined $hash->{DoubleMsgIDs}{$id} ) {
      $DMSGgleich = 0;
      # Logging-Aufruf ersetzt (Aktualisiert)
      FHEM::Devices::SIGNALDuino::Logger::Log($hash, SDUINO_DISPATCH_VERBOSE, "$name: Dispatch, $dmsg, test ungleich");
    } else {
      # Logging-Aufruf ersetzt (Aktualisiert)
      FHEM::Devices::SIGNALDuino::Logger::Log($hash, SDUINO_DISPATCH_VERBOSE, "$name: Dispatch, $dmsg, test ungleich: disabled");
    }
    $hash->{LASTDMSG} = $dmsg;
    $hash->{LASTDMSGID} = $id;
  }

  if ($DMSGgleich) {
    # Dispatch if dispatchequals is provided in protocol definition or only if $dmsg is different from last $dmsg, or if 2 seconds are between transmits
    # HINWEIS: $hash->{protocolObject}->checkProperty($id,'dispatchequals','false') ist hier nicht verfügbar, wird ignoriert
    if (  ( $hash->{DMSG} ne $dmsg) 
        || ($hash->{TIME}+2 < time() )  )
    {
      $hash->{MSGCNT}++;
      $hash->{TIME} = time();
      $hash->{DMSG} = $dmsg;
      
      # HINWEIS: FHEM Funktionen DoTrigger und Dispatch müssen im main:: Paket liegen
      if (substr(ucfirst($dmsg),0,1) eq 'U') { 
        main::DoTrigger($name, 'DMSG ' . $dmsg);
        return if (substr($dmsg,0,1) eq 'U'); 
      }

      $hash->{RAWMSG} = $rmsg;
      my %addvals = (
        DMSG => $dmsg,
        Protocol_ID => $id
      );
      $addvals{RAWMSG} = $rmsg if (!defined &main::AttrVal || main::AttrVal($name,'suppressDeviceRawmsg',0) == 0);


      if(defined($rssi)) {
        $hash->{RSSI} = $rssi;
        $addvals{RSSI} = $rssi;
        $rssi .= ' dB,'
      }
      else {
        $rssi = '';
      }
      if(defined($freqafc)) { 
        $addvals{FREQAFC} = $freqafc;
      }

      $dmsg = lc($dmsg) if ($id eq '74' or $id eq '74.1');    
      # Logging-Aufruf ersetzt (Aktualisiert)
      FHEM::Devices::SIGNALDuino::Logger::Log($hash, SDUINO_DISPATCH_VERBOSE, "$name: Dispatch, $dmsg, $rssi dispatch");
      # Der Aufruf an die FHEM-Kernfunktion Dispatch ist erforderlich
      main::Dispatch($hash, $dmsg, \%addvals); 

    } else {
      # Logging-Aufruf ersetzt (Aktualisiert)
      FHEM::Devices::SIGNALDuino::Logger::Log($hash, 4, "$name: Dispatch, $dmsg, Dropped due to short time or equal msg");
    }
  }
}

# Neuer kombinierter Dispatcher für MQTT-JSON-Payloads
sub MqttSignalduino_DispatchFromJSON {
  my ($json_str, $name) = @_;
  
  # Logging-Aufruf ersetzt (Aktualisiert)
  if (!defined($json_str) || !defined($name)) {
    FHEM::Devices::SIGNALDuino::Logger::Log($name, 3, "MqttSignalduino_DispatchFromJSON: Missing arguments (JSON or Name)");
    return;
  }

  my $hash = $defs{$name}; # $defs muss global in FHEM verfügbar sein
  if (!defined($hash)) {
    # Logging-Aufruf ersetzt (Aktualisiert)
    FHEM::Devices::SIGNALDuino::Logger::Log($name, 3, "MqttSignalduino_DispatchFromJSON: Device $name not found");
    return;
  }
  
  # Sicherstellen, dass JSON.pm geladen ist
  my $data;
  eval {
    require JSON;
    $data = JSON::decode_json($json_str);
  };
  if ($@) {
    # Logging-Aufruf ersetzt (Aktualisiert)
    FHEM::Devices::SIGNALDuino::Logger::Log($name, 3, "MqttSignalduino_DispatchFromJSON: JSON decode error: $@");
    return;
  }

  my $rmsg = $data->{rawmsg} // undef;
  my $dmsg = $data->{payload} // undef; 
  my $rssi = $data->{metadata}->{rssi} // undef;
  my $id = $data->{protocol}->{id} // undef;
  my $freqafc = $data->{metadata}->{freqafc} // undef;

  if (!defined($dmsg) || !defined($id)) {
     # Logging-Aufruf ersetzt (Aktualisiert)
     FHEM::Devices::SIGNALDuino::Logger::Log($name, 4, "MqttSignalduino_DispatchFromJSON: Missing dmsg or protocol ID in JSON");
     return;
  }
  
  # Aufruf der zentralen Dispatch-Funktion
  # Logging-Aufruf ersetzt (Aktualisiert)
  FHEM::Devices::SIGNALDuino::Logger::Log($hash, 5, "MqttSignalduino_DispatchFromJSON: Calling SIGNALduno_Dispatch with dmsg=$dmsg, id=$id");
  SIGNALduno_Dispatch($hash, $rmsg, $dmsg, $rssi, $id, $freqafc);
}

1;
