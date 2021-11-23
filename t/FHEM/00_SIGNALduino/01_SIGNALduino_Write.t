#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is field U D match array hash bag };
use Test2::Todo;
use Test2::Mock;
use Data::Dumper;

# Mock cc1101 
$defs{cc1101dummyDuino}{cc1101_available} = 1;

my ($mock);

our %defs;

InternalTimer(time()+1, sub {
  $mock = Test2::Mock->new(
    track => 1, # enable call tracking if desired
      class => 'lib::SD_Protocols',
      override => [
          PreparingSend_FS20_FHT => sub { 0 },
      ],
  );

  subtest "SIGNALduino_Write FS20" => sub {
    plan (1); 
    my $targetHash = $defs{dummyDuino};

    SIGNALduino_Write($targetHash,'04','01010100110011');
    my $tracking = $mock->sub_tracking;
    my $args = $tracking->{PreparingSend_FS20_FHT}[0]{args};
    delete $tracking->{PreparingSend_FS20_FHT} ;

    is ($args,array { 
               item 1 => 74; 
               item 2 => 6; 
               item 3 => '00110011'; 
            },
            'verify called args PreparingSend_FS20_FHT');
  };

  subtest "SIGNALduino_Write FHT" => sub {
    plan (1); 
    my $targetHash = $defs{dummyDuino};

    SIGNALduino_Write($targetHash,'04','0201830110110011');
    my $tracking = $mock->sub_tracking;
    my $args = $tracking->{PreparingSend_FS20_FHT}[0]{args};
    delete $tracking->{PreparingSend_FS20_FHT} ;

    is ($args,array { 
               item 1 => 73; 
               item 2 => 12; 
               item 3 => '0110110011';
            }, 
            'verify called args PreparingSend_FS20_FHT');
  };    
  done_testing();
  $mock->restore('PreparingSend_FS20_FHT');
  exit(0);

}, 0);

1;