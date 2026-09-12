#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Mock;
use File::Path qw(make_path remove_tree);

our %defs;

InternalTimer(time()+0.2, sub {
  my $target = shift;
  my $targetHash = $defs{$target};
  my $devspec_arg;
  my @warnings;
  my $logdir = '/tmp/rffhem_test_SIGNALduino_FW_Detail/';
  my $flashlog = $targetHash->{TYPE}.'-Flash.log';
  make_path($logdir);
  open(my $fh, '>', $logdir.$flashlog) or die "cannot create flashlog: $!";
  print {$fh} "test\n";
  close($fh);

  my $mock = Test2::Mock->new(
    class => 'main',
    override => [
      devspec2array => sub($;$$) {
        $devspec_arg = $_[0];
        return undef;
      },
      AttrVal => sub($$$) {
        return $logdir;
      },
    ],
  );

  subtest 'SIGNALduino_FW_Detail handles undef result from devspec2array' => sub {
    plan(6);
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $ret = SIGNALduino_FW_Detail('', $targetHash->{NAME}, '', {});

    is($devspec_arg, 'TYPE=FileLog', 'devspec2array called with expected filter');
    like($ret, qr/Information menu/, 'html contains information menu');
    like($ret, qr/id='showProtocolList'/, 'html contains protocol list link');
    unlike($ret, qr/Last Flashlog/, 'no flashlog link is shown without filelog device');
    like($ret,qr/No device of TYPE=FileLog found/, 'html contains message about missing filelog device');
    is(scalar @warnings, 0, 'no warning when devspec2array returns undef',@warnings);
  };

  $mock->restore('devspec2array');
  unlink($logdir.$flashlog);
  @warnings = ();

  my $mock_log_missing = Test2::Mock->new(
    class => 'main',
    override => [
      devspec2array => sub($;$$) {
        $devspec_arg = $_[0];
        return ('dummyFileLog');
      },
      IsDevice => sub($) {
        return 1;
      },
      AttrVal => sub($$$) {
        return $logdir;
      },
    ],
  );

  subtest 'SIGNALduino_FW_Detail handles missing flashlog file' => sub {
    plan(6);
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $ret = SIGNALduino_FW_Detail('', $targetHash->{NAME}, '', {});

    is($devspec_arg, 'TYPE=FileLog', 'devspec2array called with expected filter');
    like($ret, qr/Information menu/, 'html contains information menu');
    like($ret, qr/id='showProtocolList'/, 'html contains protocol list link');
    unlike($ret, qr/Last Flashlog/, 'no flashlog link is shown without logfile');
    unlike($ret, qr/No device of TYPE=FileLog found/, 'html does not contain missing filelog device message');
    is(scalar @warnings, 0, 'no warning when logfile is missing',@warnings);
  };

  $mock_log_missing->restore('devspec2array');
  $mock_log_missing->restore('IsDevice');
  $mock_log_missing->restore('AttrVal');

  # "logdir" may be configured without a trailing separator. Concatenating it with the
  # file name looked for "<logdir>SIGNALduino-Flash.log" next to the directory, so the
  # menu entry stayed hidden even though the log had just been written.
  my $logdir_no_sep = '/tmp/rffhem_test_SIGNALduino_FW_Detail_nosep';
  make_path($logdir_no_sep);
  open(my $fh_nosep, '>', $logdir_no_sep . '/' . $flashlog) or die "cannot create flashlog: $!";
  print {$fh_nosep} "test\n";
  close($fh_nosep);

  my $mock_log_nosep = Test2::Mock->new(
    class => 'main',
    override => [
      devspec2array => sub($;$$) {
        return ('dummyFileLog');
      },
      IsDevice => sub($) {
        return 1;
      },
      AttrVal => sub($$$) {
        return $logdir_no_sep;
      },
    ],
  );

  subtest 'SIGNALduino_FW_Detail finds the flashlog when logdir has no trailing separator' => sub {
    plan(3);
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $ret = SIGNALduino_FW_Detail('', $targetHash->{NAME}, '', {});

    like($ret, qr/Last Flashlog/, 'flashlog link is shown');
    like($ret, qr/file=\Q$flashlog\E/, 'link points at the flashlog file');
    is(scalar @warnings, 0, 'no warning raised', @warnings);
  };

  $mock_log_nosep->restore('devspec2array');
  $mock_log_nosep->restore('IsDevice');
  $mock_log_nosep->restore('AttrVal');
  remove_tree($logdir_no_sep);

  $mock->restore('AttrVal');
  remove_tree($logdir);
  done_testing();
  exit(0);
}, 'dummyDuino');

1;
