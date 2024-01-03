#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use File::Basename;

# Testtool which supports DMSG Tests from SIGNALDuino_tool
use Test2::SIGNALduino::FHEM_Command;
use Test2::Tools::Compare qw{is U validator array hash};
use Test2::Mock;

our %defs;
our $init_done;
our $mock;

my $module = basename (dirname(__FILE__));

# This is the testdata, which will speify what to test and what to check
@mockData = (
    {
        # Default mocking for every testrun in our loop
        defaults    => {
            mocking =>  sub { $mock->override ( IOWrite => sub { return @_ } );  } 
        },
    },
    {
        targetName      =>  q[SD_GT_Set],
        testname        =>  q[set command on with all readings],
        cmd             =>  q[set on],

        prep_commands   => [                               # Any FHEM custom command can be placed in here, which will be called before the test is run
                    'setreading $targetName CodesOff C6B542',
                    'setreading $targetName CodesOn C22B92',
                    'setreading $targetName SystemCode C07E2',
                    'setreading $targetName SystemCodeDec 788450',
                    'setreading $targetName Version 2',
        ],

        returnCheck     => F(),
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P49#0xC22B92#R5' }; etc() } } } ,
    }
);

sub runTest {
    Test2::SIGNALduino::FHEM_Command::commandCheck($module);

    done_testing();
  exit(0);
}

sub waitDone {

  if ($init_done) 
  {
    runTest(@_);
  } else {
    InternalTimer(time()+0.2, &waitDone,@_);
  }

}

waitDone();

1;