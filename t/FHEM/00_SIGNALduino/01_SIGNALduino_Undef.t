#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is field U D match hash bag };
use Mock::Sub;
use Test2::Todo;


our %defs;

InternalTimer(time(), sub() {

    my $name = $_[0];
    my $hash = $defs{$name};
    plan(6);

    CommandDefMod(undef,'SD_WS_51_TEST SD_WS SD_WS_51_TH_10');

    $defs{SD_WS_51_TEST}{IODev} = $hash;
    is($defs{SD_WS_51_TEST}{IODev},D(),q[IODev does exists]);

    ok(IsDevice($name),'Device exists');
    is (SIGNALduino_Undef($hash),U(),q[check return from undef fn ]);
    is(IsDevice($name),T(),'Device still exists');
    is($defs{SD_WS_51_TEST}{IODev},U(),q[IODev does exists]);

  
    is(FHEM::Core::Timer::Helper::removeTimer($name),0,'No timers left to remove');
    done_testing();
    exit(0);  
  
}, 'dummyDuino');

1;