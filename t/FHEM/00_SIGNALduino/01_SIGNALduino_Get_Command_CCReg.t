#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is field U D match hash bag };
use Test2::Todo;
use Test2::Mock;
use Data::Dumper qw(Dumper);

# Mock cc1101 
$defs{cc1101dummyDuino}{cc1101_available} = 1;

my ($mock);

BEGIN {

};

InternalTimer(time()+1, sub() {
  $mock = Test2::Mock->new(
    class => 'main',
    track => 1, # enable call tracking if desired
      override => [
          SIGNALduino_Get_Command => sub { return @_ },
      ],
  );

  subtest 'SIGNALduino_Get_Command_CCReg all regs (99)' => sub {
    plan (1); 
    my $targetHash = $defs{dummyDuino};

    SIGNALduino_Get_Command_CCReg($targetHash,'ccreg','99');
    my $tracking = $mock->sub_tracking;
    my $args = $tracking->{SIGNALduino_Get_Command}[0]{args};
    #print Dumper($args);
    delete $tracking->{SIGNALduino_Get_Command} ;

    is ($args,array { 
               item 1 => 'ccreg'; 
               item 2 => '99'; 
               end();
            },
            'verify called args SIGNALduino_Get_Command');
  };

  subtest 'SIGNALduino_Get_Command_CCReg one reg (12)' => sub {
    plan (1); 
    my $targetHash = $defs{dummyDuino};

    SIGNALduino_Get_Command_CCReg($targetHash,'ccreg','12');
    my $tracking = $mock->sub_tracking;
    my $args = $tracking->{SIGNALduino_Get_Command}[0]{args};
    #print Dumper($args);
    delete $tracking->{SIGNALduino_Get_Command} ;

    is ($args,array { 
               item 1 => 'ccreg'; 
               item 2 => '12'; 
               end();
            },
            'verify called args SIGNALduino_Get_Command');
  };

  subtest 'SIGNALduino_Get_Command_CCReg wrong reg (F1)' => sub {
    plan (1); 
    my $targetHash = $defs{dummyDuino};

    SIGNALduino_Get_Command_CCReg($targetHash,'ccreg','F1');
    my $tracking = $mock->sub_tracking;
    my $args = $tracking->{SIGNALduino_Get_Command}[0]{args};
    #print Dumper($args);
    delete $tracking->{SIGNALduino_Get_Command} ;

    is ($args,U(), 'verify called args SIGNALduino_Get_Command');
  };

  subtest 'SIGNALduino_Get_Command_CCReg wrong reg (C12)' => sub {
    plan (1); 
    my $targetHash = $defs{dummyDuino};

    SIGNALduino_Get_Command_CCReg($targetHash,'ccreg','C12');
    my $tracking = $mock->sub_tracking;
    my $args = $tracking->{SIGNALduino_Get_Command}[0]{args};
    #print Dumper($args);
    delete $tracking->{SIGNALduino_Get_Command} ;

    is ($args,U(), 'verify called args SIGNALduino_Get_Command');
  };

  subtest 'SIGNALduino_Get_Command_CCReg no reg ' => sub {
    plan (1); 
    my $targetHash = $defs{dummyDuino};

    SIGNALduino_Get_Command_CCReg($targetHash,'ccreg');
    my $tracking = $mock->sub_tracking;
    my $args = $tracking->{SIGNALduino_Get_Command}[0]{args};
    #print Dumper($args);
    delete $tracking->{SIGNALduino_Get_Command} ;

    is ($args,U(), 'verify called args SIGNALduino_Get_Command');
  };

  done_testing();
  $mock->restore('SIGNALduino_Get_Command');
  exit(0);

}, 0);

1;