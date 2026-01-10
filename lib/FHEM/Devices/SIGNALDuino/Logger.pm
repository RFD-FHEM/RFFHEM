package FHEM::Devices::SIGNALDuino::Logger;

use strict;
use warnings;

sub Log {
    my ($hash, $level, $message) = @_;
    
    # Pruefen, ob $hash ein Hash und $hash->{logMethod} definiert ist
    if (ref($hash) eq 'HASH' && defined($hash->{logMethod})) {
        $hash->{logMethod}->($hash->{NAME}, $level, $message);
    }
    # Fallback: main::Log3 verwenden
    elsif (ref($hash) eq 'HASH' && defined($hash->{NAME})) {
        main::Log3 $hash->{NAME}, $level, $message;
    }
    # Fallback fuer Aufrufe, bei denen $hash ein String ($name) ist (z.B. vor $hash-Def.)
    elsif (defined($hash)) {
        main::Log3 $hash, $level, $message;
    }
    # Generischer Fall
    else {
        main::Log3 undef, $level, $message;
    }
}

1;
