#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw{is field U D match hash bag };
use Test2::Todo;

use File::Basename;
our %defs;
our %attr;

InternalTimer(time()+1, sub() {
  my $target = shift;
  my $targetHash = $defs{$target};

  my $path=dirname(__FILE__);
	my $LoadResult =  $targetHash->{protocolObject}->LoadHash($path."/test_loadprotohash-ok.pm");

	is($LoadResult,undef,"load test protocol hash ");


  subtest 'Verify returns of SIGNALduino_FW_getProtocolList ' => sub {
    plan(4);
    my $ret;
    $ret = SIGNALduino_FW_getProtocolList($target);

    like($ret,qr,<div>MC</div>,,'MC is located in return');
    like($ret,qr,<div>MS</div>,,'MS is located in return');
    like($ret,qr,<div>MU</div>,,'MU is located in return');    
    like($ret,qr,<div>MN</div>,,'MN is located in return');    
  };

  done_testing();
  exit(0);

}, 'dummyDuino');

1;