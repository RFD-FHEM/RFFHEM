# $Id: Clients.pm 0 2026-01-10 15:36:13Z sidey79 $
# The file is part of the SIGNALduino project.
# Client functions for SIGNALduino device.

package FHEM::Devices::SIGNALDuino::Clients;
use strict;
use warnings;


# Die Liste der Standard-Clients, die in SIGNALduino aktiv sein sollen (z.B. IT, FS20).
my $clientlist = 
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

sub getClientsasStr {
    # Function will return the standard client list as string
    return $clientlist;
}

1;
