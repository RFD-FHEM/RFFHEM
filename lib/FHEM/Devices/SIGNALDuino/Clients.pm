package FHEM::Devices::SIGNALDuino::Clients;
use strict;
use warnings;

our $VERSION = "1.00"; # Annahme für Versionsnummer

# Die Liste der Standard-Clients, die in SIGNALduino aktiv sein sollen (z.B. IT, FS20).
# Der Inhalt wurde von SD::Matchlist verschoben.
my $clientsSIGNALduino = 
            ':CUL_EM:'
            .'CUL_FHTTK:'
            .'CUL_TCM97001:'
            .'CUL_TX:'
            .'CUL_WS:'
            .'Dooya:'
            .'FHT:'
            .'FLAMINGO:'
            .'FS10:'
            .'FS20:'
            .' :'         # Zeilenumbruch
            .'Fernotron:'
            .'Hideki:'
            .'IT:'
            .'KOPP_FC:'
            .'LaCrosse:'
            .'OREGON:'
            .'PCA301:'
            .'RFXX10REC:'
            .'Revolt:'
            .'SD_AS:'
            .'SD_Rojaflex:'
            .' :'         # Zeilenumbruch
            .'SD_BELL:'
            .'SD_GT:'
            .'SD_Keeloq:'
            .'SD_RSL:'
            .'SD_UT:'
            .'SD_WS07:'
            .'SD_WS09:'
            .'SD_WS:'
            .'SD_WS_Maverick:'
            .'SOMFY:'
            .' :'         # Zeilenumbruch
            .'Siro:'
            .'SIGNALduino_un:'
          ;

sub getClientsasRef {
    # Diese Funktion gibt die Standard-Clients als Doppelpunkt-getrennte Zeichenkette zurück.
    return \$clientsSIGNALduino;
}

1;
