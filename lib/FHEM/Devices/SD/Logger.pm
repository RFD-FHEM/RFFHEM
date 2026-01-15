# $Id: Logger.pm 0 2026-01-10 15:36:13Z sidey79 $
# The file is part of the SIGNALduino project.
# Logging helper functions for Packages in FHEM::Devices::SD.

package FHEM::Devices::SD::Logger;

use strict;
use warnings;


sub Log {
    my ($hash, $level, $message) = @_;
    
    if (ref($hash) eq 'HASH' && defined($hash->{logMethod})) {
        $hash->{logMethod}->($hash->{NAME}, $level, $message);
    }
    # Fallback: main::Log3 
    elsif (ref($hash) eq 'HASH' && defined($hash->{NAME})) {
        main::Log3($hash->{NAME}, $level, $message);
    }
    # Fallback if $hash is a device name
    elsif (defined($hash)) {
        main::Log3($hash, $level, $message);
    }
    # generic fallback
    else {
        main::Log3 (undef, $level, $message);
    }
}

1;
