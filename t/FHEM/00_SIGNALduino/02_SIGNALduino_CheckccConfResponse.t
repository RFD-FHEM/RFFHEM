use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{ is };


our %defs;

InternalTimer(time(), sub {
  plan(2);

  subtest 'Test cconf response ASK/OOK (C0Dn11=10B07157C43023B900070018146C070091)' => sub {
    plan(3);
    my $target='dummyDuino';
    my $targetHash = $defs{$target};

    my ($ret)=SIGNALduino_CheckccConfResponse($targetHash,"C0Dn11=10B07157C43023B900070018146C070091");
    is($ret,"Freq: 433.920 MHz, Bandwidth: 325 kHz, rAmpl: 42 dB, sens: 8 dB, DataRate: 5.60 kBaud, Modulation: ASK/OOK","check return message");
    is(ReadingsVal($target,"cc1101_config",undef),"Freq: 433.920 MHz, Bandwidth: 325 kHz, rAmpl: 42 dB, sens: 8 dB, DataRate: 5.60 kBaud","check reading cc1101_config value");
    is(ReadingsVal($target,"cc1101_config_ext",undef),"Modulation: ASK/OOK","check reading cc1101_config_ext value");
  };

  subtest 'Test cconf response FSK (C0Dn11=10AA568AF80222F851070018166C434091)' => sub {
    plan(3);
    my $target='dummyDuino';
    my $targetHash = $defs{$target};

    my ($ret)=SIGNALduino_CheckccConfResponse($targetHash,"C0Dn11=10AA568AF80222F851070018166C434091");
    is($ret,"Freq: 433.300 MHz, Bandwidth: 203 kHz, rAmpl: 33 dB, sens: 8 dB, DataRate: 49.99 kBaud, Modulation: 2-FSK, Syncmod: 16/16 sync word bits detected, Deviation: 57.13 kHz","check return message");
    is(ReadingsVal($target,"cc1101_config",undef),"Freq: 433.300 MHz, Bandwidth: 203 kHz, rAmpl: 33 dB, sens: 8 dB, DataRate: 49.99 kBaud","check reading cc1101_config value");
    is(ReadingsVal($target,"cc1101_config_ext",undef),"Modulation: 2-FSK, Syncmod: 16/16 sync word bits detected, Deviation: 57.13 kHz");
  };

  exit(0);
}, 0);

1;