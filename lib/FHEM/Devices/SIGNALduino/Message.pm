# $Id: Message.pm 0 2026-01-10 15:36:13Z sidey79 $
# The file is part of the SIGNALduino project.
# Message functions for SIGNALduino device messages.

package FHEM::Devices::SIGNALduino::Message;

use strict;
use warnings;
eval { require JSON; JSON->import; };

# Neue Subpackages einbinden (Aktualisiert)
require FHEM::Devices::SIGNALduino::Logger;
require FHEM::Devices::SIGNALduino::Matchlist; 
require FHEM::Devices::SIGNALduino::Clients;

# Konstante beibehalten
use constant {
  SDUINO_DISPATCH_VERBOSE         => 5,
};

our main::%defs;  # Globale Definitionen für FHEM
# Todo Add Clients and Matchlist dynamically to DevAttrList 
# { addToDevAttrList('PySignalDuino', 'Clients');; }

sub Dispatch {
  my ($hash, $rmsg, $dmsg, $rssi, $id, $freqafc) = @_;
  my $name = $hash->{NAME};

  if (!defined($dmsg))
  {
    # Logging-Aufruf ersetzt (Aktualisiert)
    FHEM::Devices::SIGNALduino::Logger::Log($hash, 5, "$name: Dispatch, dmsg is undef. Skipping dispatch call");
    return;
  }

  my $DMSGgleich = 1;
  if ($dmsg eq $hash->{LASTDMSG}) {
    # Logging-Aufruf ersetzt (Aktualisiert)
    FHEM::Devices::SIGNALduino::Logger::Log($hash, SDUINO_DISPATCH_VERBOSE, "$name: Dispatch, $dmsg is equal to last DMSG");
  } else {
    if ( defined $hash->{DoubleMsgIDs}{$id} ) {
      $DMSGgleich = 0;
      # Logging-Aufruf ersetzt (Aktualisiert)
      FHEM::Devices::SIGNALduino::Logger::Log($hash, SDUINO_DISPATCH_VERBOSE, "$name: Dispatch, $dmsg is unequal to last DMSG (DoubleMsgID is enabled)");
    } else {
      # Logging-Aufruf ersetzt (Aktualisiert)
      FHEM::Devices::SIGNALduino::Logger::Log($hash, SDUINO_DISPATCH_VERBOSE, "$name: Dispatch, $dmsg, is unequal to last DMSG (DoubleMsgID is disabled)");
    }
    $hash->{LASTDMSG} = $dmsg;
    $hash->{LASTDMSGID} = $id;
  }

  if ($DMSGgleich) {
    # Dispatch only if $dmsg is different from last $dmsg, or if 2 seconds are between transmits AND protocol property dispatchequals is not set to true
    if ( ( ( $hash->{DMSG} ne $dmsg)
         || ($hash->{TIME}+2 < time() ) )
        && ( !defined $hash->{protocolObject} || $hash->{protocolObject}->checkProperty($id,'dispatchequals','false') ne 'true' ) )
    {
      $hash->{MSGCNT}++;
      $hash->{TIME} = time();
      $hash->{DMSG} = $dmsg;
      
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
      FHEM::Devices::SIGNALduino::Logger::Log($hash, SDUINO_DISPATCH_VERBOSE, "$name: Dispatch, $dmsg, $rssi dispatch");
      main::Dispatch($hash, $dmsg, \%addvals); 
    } else {
      FHEM::Devices::SIGNALduino::Logger::Log($hash, 4, "$name: Dispatch, $dmsg, Dropped due to short time or equal msg");
    }
  }
}

sub json2Dispatch {
  my ($json_str, $name) = @_;

  if (!defined($json_str) || !defined($name)) {
    FHEM::Devices::SIGNALduino::Logger::Log($name, 3, "json2Dispatch: Missing arguments (JSON or Name)");
    return;
  }

  my $hash = $main::defs{$name}; 
  if (!defined($hash)) {
    FHEM::Devices::SIGNALduino::Logger::Log($name, 3, "json2Dispatch: Device $name not found");
    return;
  }
  
  my $json;
  eval {
    require JSON;
    $json = JSON::decode_json($json_str);
  };
  if ($@) {
    FHEM::Devices::SIGNALduino::Logger::Log($name, 3, "json2Dispatch: JSON decode error: $@");
    return;
  }

  my $message = $json->{data} // undef;

  if (!defined($message)) {
     FHEM::Devices::SIGNALduino::Logger::Log($name, 4, "json2Dispatch: Missing 'data' in JSON structure");
     return;
  }
  
  if (!defined($json->{protocol}) || !defined($json->{protocol}->{id})) {
     FHEM::Devices::SIGNALduino::Logger::Log($name, 4, q[json2Dispatch: Missing ' "protocol":{id:}" ' in JSON structure]);
     return;
  }

  my $rmsg = $json->{raw} // undef;
  my $dmsg = (defined $json->{protocol}->{preamble} && defined $message)
             ? $json->{protocol}->{preamble} . $message
             : $message;
  my $id = $json->{protocol}->{id} // undef;
  my $rssi = $json->{metadata}->{rssi} // undef;
  my $freqafc = $json->{metadata}->{freq_afc} // undef;

  if (!defined($dmsg) || !defined($id)) {
     FHEM::Devices::SIGNALduino::Logger::Log($name, 4, "json2Dispatch: No dmsg could be created from JSON");
     return;
  }
  
  if (!defined($hash->{MatchList}) || !defined($hash->{Clients}) ) {
    FHEM::Devices::SIGNALduino::Logger::Log($hash, 4, "json2Dispatch: Matchlist/Clientlist initialization");
    
    FHEM::Devices::SIGNALduino::Matchlist::UpdateMatchList($hash,undef);
    $hash->{Clients} = FHEM::Devices::SIGNALduino::Clients::getClientsasStr($hash);
  }

  # Call central dispatch function
  FHEM::Devices::SIGNALduino::Logger::Log($hash, 5, "json2Dispatch: Calling FHEM Dispatch with dmsg=$dmsg, id=$id");
  Dispatch($hash, $rmsg, $dmsg, $rssi, $id, $freqafc);
}

1;
