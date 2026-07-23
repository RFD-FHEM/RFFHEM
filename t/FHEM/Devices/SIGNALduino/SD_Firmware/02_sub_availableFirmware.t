#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Mock qw(mock);
use FindBin qw($RealBin);
use Cwd qw(getcwd);
use JSON ();
use File::Spec;
use File::Path qw(make_path);
use File::Temp qw(tempdir);

use FHEM::Devices::SIGNALduino::SD_Firmware qw(:all);

my $target = 'cc1101dummyDuino';
my @logs;

our %defs = (
  $target => {
    NAME      => $target,
    TYPE      => 'SIGNALduino',
    logMethod => sub {
      my ($name, $level, $msg) = @_;
      push @logs, { name => $name, level => $level, msg => $msg };
      return;
    },
  }
);
my $targetHash = $defs{$target};

our %modules = (
  SIGNALduino => {
    AttrList => 'hardware:mini,nano328,radinoCC1101 setListDummy'
  }
);

my $mock_channel  = 'stable';
my $mock_hardware = 'mini';

my $mock_main = Test2::Mock->new(
  track    => 1,
  class    => 'main',
  autoload => 1,
  add      => [
    HAS_JSON => sub { return 1; },
    HttpUtils_NonblockingGet => sub { return; },
    FW_directNotify => sub { return; },
    SIGNALduino_Set => sub { return; },
    AttrVal  => sub {
      my ($name, $attr, $default) = @_;
      return $mock_channel  if $attr eq 'updateChannelFW';
      return defined $mock_hardware ? $mock_hardware : $default if $attr eq 'hardware';
      return $default;
    },
  ],
);

my $mock_fw = Test2::Mock->new(
  track    => 1,
  class    => 'FHEM::Devices::SIGNALduino::SD_Firmware',
  override => [
    SIGNALduino_querygithubreleases => sub { return; },
  ],
);

sub reset_state {
  @logs = ();
  $mock_channel  = 'stable';
  $mock_hardware = 'mini';
  $mock_main->clear_sub_tracking;
  $mock_fw->clear_sub_tracking;
}

sub reset_set_flash_state {
  reset_state();
  $mock_hardware = 'nano328';
  delete $targetHash->{additionalSets}{flash};
  delete $targetHash->{FLASH_RESULT};
}

sub load_release_fixture_json {
  my $fixture = File::Spec->catfile($RealBin, '..', '..', '..', '00_SIGNALduino', 'test_firmware_releases.json');
  open my $fh, '<', $fixture or die "cannot open firmware fixture $fixture: $!";
  local $/ = undef;
  my $json = <$fh>;
  close $fh or die "cannot close firmware fixture $fixture: $!";
  return $json;
}

subtest 'Get_availableFirmware tests' => sub {

  subtest 'without JSON module support' => sub {
    plan(4);
    reset_state();
    $mock_main->override('HAS_JSON' => sub { return 0; });

    my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_Get_availableFirmware($targetHash, 'availableFirmware');

    like($ret, qr/^availableFirmware:/, 'return starts with command name');
    like($ret, qr/Please install JSON/, 'return contains JSON hint');
    is(scalar(@{$mock_fw->sub_tracking->{SIGNALduino_querygithubreleases} // []}), 0, 'github query is not triggered');
    like($logs[0]->{msg}, qr/Please install Perl module JSON/, 'error is logged');

    $mock_main->restore('HAS_JSON');
  };

  subtest 'with missing hardware attribute' => sub {
    plan(3);
    reset_state();
    $mock_hardware = undef;

    my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_Get_availableFirmware($targetHash, 'availableFirmware');

    like($ret, qr/get availableFirmware failed\. Please choose one of mini,nano328,radinoCC1101 attribute hardware/, 'return asks for valid hardware');
    is(scalar(@{$mock_fw->sub_tracking->{SIGNALduino_querygithubreleases}}), 0, 'github query is not triggered');
    like($logs[-1]->{msg}, qr/Please set attribute hardware first/, 'missing hardware is logged');
  };

  subtest 'with unsupported hardware attribute' => sub {
    plan(3);
    reset_state();
    $mock_hardware = 'esp32';

    my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_Get_availableFirmware($targetHash, 'availableFirmware');

    like($ret, qr/Please choose one of mini,nano328,radinoCC1101 attribute hardware/, 'return contains supported hardware list');
    is(scalar(@{$mock_fw->sub_tracking->{SIGNALduino_querygithubreleases} }), 0, 'github query is not triggered');
    like($logs[-1]->{msg}, qr/Please set attribute hardware first/, 'unsupported hardware is logged');
  };

  subtest 'with valid hardware and default stable channel' => sub {
    plan(3);
    reset_state();
    $mock_hardware = 'mini';
    $mock_channel  = 'stable';

    my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_Get_availableFirmware($targetHash, 'availableFirmware');

    is($ret, "availableFirmware: \n\nFetching stable firmware versions for mini from github\n", 'return string for stable channel');
    is(scalar(@{$mock_fw->sub_tracking->{SIGNALduino_querygithubreleases}}), 1, 'github query is triggered once');
    like($logs[0]->{msg}, qr/found availableFirmware/, 'available hardware list is logged');
  };

  subtest 'with valid hardware and custom channel' => sub {
    plan(2);
    reset_state();
    $mock_hardware = 'radinoCC1101';
    $mock_channel  = 'testing';

    my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_Get_availableFirmware($targetHash, 'availableFirmware');

    is($ret, "availableFirmware: \n\nFetching testing firmware versions for radinoCC1101 from github\n", 'return string for custom channel');
    is(scalar(@{$mock_fw->sub_tracking->{SIGNALduino_querygithubreleases}}), 1, 'github query is triggered once');
  };
};

subtest 'Set_flash tests' => sub {
  subtest 'error when hardware is missing' => sub {
    plan(1);
    reset_set_flash_state();
    $mock_hardware = '';

    my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_Set_flash($targetHash, 'flash', './fhem/test.hex');

    like($ret, qr/^Please define your hardware!/, 'returns hardware hint');
  };

  subtest 'error when flash argument is missing' => sub {
    plan(2);
    reset_set_flash_state();

    my $ret_no_arg = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_Set_flash($targetHash, 'flash');
    my $ret_undef  = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_Set_flash($targetHash, undef);

    is($ret_no_arg, 'ERROR: argument failed! flash [hexFile|url]', 'returns error for missing argument');
    is($ret_undef,  'ERROR: argument failed! flash [hexFile|url]', 'returns error for undef argument');
  };

  subtest 'local file path calls PrepareFlash for supported hardware' => sub {
    plan(3);
    reset_set_flash_state();
    $mock_fw->override('SIGNALduino_PrepareFlash' => sub { return 'PF_OK'; });

    my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_Set_flash($targetHash, 'flash', './fhem/test.hex');
    my $calls = $mock_fw->sub_tracking->{SIGNALduino_PrepareFlash} // [];

    is(scalar(@{$calls}), 1, 'PrepareFlash called once');
    is($calls->[0]{args}[1], './fhem/test.hex', 'PrepareFlash called with provided hex path');
    is($ret, 'PF_OK', 'return value is passed through from PrepareFlash');

    $mock_fw->restore('SIGNALduino_PrepareFlash');
  };

  subtest 'non matching tag falls back to PrepareFlash' => sub {
    plan(3);
    reset_set_flash_state();
    $targetHash->{additionalSets}{flash} = '4.2.1,4.1.0';
    $mock_fw->override('SIGNALduino_PrepareFlash' => sub { return 'PF_FALLBACK'; });

    my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_Set_flash($targetHash, 'flash', '3.4');
    my $prepare_calls = $mock_fw->sub_tracking->{SIGNALduino_PrepareFlash} // [];
    my $http_calls = $mock_main->sub_tracking->{HttpUtils_NonblockingGet} // [];

    is(scalar(@{$prepare_calls}), 1, 'PrepareFlash called for non matching tag');
    is(scalar(@{$http_calls}), 0, 'HttpUtils_NonblockingGet not called for non matching tag');
    is($ret, 'PF_FALLBACK', 'return value from PrepareFlash is returned');

    $mock_fw->restore('SIGNALduino_PrepareFlash');
  };

  subtest 'matching tag triggers github release request' => sub {
    plan(8);
    reset_set_flash_state();
    $targetHash->{additionalSets}{flash} = '4.2.1,4.1.0';

    my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_Set_flash($targetHash, 'flash', '4.2.1');
    my $http_calls = $mock_main->sub_tracking->{HttpUtils_NonblockingGet} // [];
    my $req = $http_calls->[0]{args}[0];

    is($ret, undef, 'no immediate return value for async tag request');
    is(scalar(@{$http_calls}), 1, 'HttpUtils_NonblockingGet called once');
    is($req->{command}, 'getReleaseByTag', 'request command matches getReleaseByTag');
    is($req->{url}, 'https://api.github.com/repos/RFD-FHEM/SIGNALDuino/releases/tags/4.2.1', 'request URL matches github tag endpoint');
    is($req->{hash}, $targetHash, 'request hash points to device hash');
    is($req->{timeout}, 5, 'request timeout is set');
    is($req->{method}, 'GET', 'request method is GET');

    is($req->{callback}, \&FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_githubParseHttpResponse, 'callback is github response parser');
  };

  subtest 'url triggers direct firmware download request' => sub {
    plan(5);
    reset_set_flash_state();
    my $url = 'https://github.com/RFD-FHEM/SIGNALDuino/releases/download/3.4.0/SIGNALDuino_nanocc11013.4.0.hex';

    my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_Set_flash($targetHash, 'flash', $url);
    my $http_calls = $mock_main->sub_tracking->{HttpUtils_NonblockingGet} // [];
    my $req = $http_calls->[0]{args}[0];

    is($ret, undef, 'no immediate return value for async download');
    is(scalar(@{$http_calls}), 1, 'HttpUtils_NonblockingGet called once');
    is($req->{command}, 'flash', 'request command matches flash');
    is($req->{url}, $url, 'request URL matches provided URL');
    is($req->{callback}, \&FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_ParseHttpResponse, 'callback is flash response parser');
  };

  subtest 'unsupported hardware returns error and can trigger FW notify' => sub {
    plan(5);
    reset_set_flash_state();
    $mock_hardware = 'esp32';
    $mock_fw->override('SIGNALduino_PrepareFlash' => sub { return 'SHOULD_NOT_BE_USED'; });

    my $ret_without_web = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_Set_flash($targetHash, 'flash', './fhem/test.hex');
    {
      local $main::FW_wname = 'testweb';
      my $ret_with_web = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_Set_flash($targetHash, 'flash', './fhem/test.hex');
      is($ret_with_web, 'Sorry, Flashing your esp32 via Module is currently not supported.', 'returns unsupported message with FW context');
    }

    my $prepare_calls = $mock_fw->sub_tracking->{SIGNALduino_PrepareFlash} // [];
    my $http_calls = $mock_main->sub_tracking->{HttpUtils_NonblockingGet} // [];
    my $notify_calls = $mock_main->sub_tracking->{FW_directNotify} // [];

    is($ret_without_web, 'Sorry, Flashing your esp32 via Module is currently not supported.', 'returns unsupported message');
    is(scalar(@{$prepare_calls}), 0, 'PrepareFlash not called for unsupported hardware');
    is(scalar(@{$http_calls}), 0, 'HttpUtils_NonblockingGet not called for unsupported hardware');
    is(scalar(@{$notify_calls}), 1, 'FW_directNotify called when FW_wname is set');

    $mock_fw->restore('SIGNALduino_PrepareFlash');
  };
};

subtest 'ParseHttpResponse tests' => sub {
  subtest 'logs request error when http layer returns error' => sub {
    plan(1);
    reset_state();
    my $param = {
      hash => $targetHash,
      url  => 'https://example.invalid/fw.hex',
    };

    FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_ParseHttpResponse($param, 'timeout', '');

    like($logs[-1]{msg}, qr/error while requesting .*timeout/, 'request error is logged');
  };

  subtest 'downloads firmware from content-disposition and calls SIGNALduino_Set' => sub {
    plan(5);
    reset_state();
    my $tmpdir = tempdir(CLEANUP => 1);
    my $oldcwd = getcwd();
    make_path("$tmpdir/FHEM/firmware");
    chdir $tmpdir or die "cannot chdir to tempdir: $!";

    my $param = {
      hash       => $targetHash,
      url        => 'https://example.invalid/fw.hex',
      code       => '200',
      command    => 'flash',
      httpheader => 'Content-Disposition: attachment; filename="downloaded.hex"',
      host       => 'example.invalid',
      path       => '/releases/downloaded.hex',
    };
    my $payload = "HEXDATA\n";

    FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_ParseHttpResponse($param, '', $payload);

    my $set_calls = $mock_main->sub_tracking->{SIGNALduino_Set} // [];
    my $written_file = "$tmpdir/FHEM/firmware/downloaded.hex";

    is(scalar(@{$set_calls}), 1, 'SIGNALduino_Set called once');
    is($set_calls->[0]{args}[1], $target, 'SIGNALduino_Set called with device name');
    is($set_calls->[0]{args}[2], 'flash', 'SIGNALduino_Set called with flash command');
    is($set_calls->[0]{args}[3], 'FHEM/firmware/downloaded.hex', 'SIGNALduino_Set called with local firmware path');
    ok(-f $written_file, 'downloaded firmware file exists');

    chdir $oldcwd or die "cannot restore cwd: $!";
  };

  subtest 'falls back to path filename and logs flashing error from SIGNALduino_Set' => sub {
    plan(3);
    reset_state();
    my $tmpdir = tempdir(CLEANUP => 1);
    my $oldcwd = getcwd();
    make_path("$tmpdir/FHEM/firmware");
    chdir $tmpdir or die "cannot chdir to tempdir: $!";

    $mock_main->override('SIGNALduino_Set' => sub { return 'flash failed'; });
    my $param = {
      hash       => $targetHash,
      url        => 'https://example.invalid/fw.hex',
      code       => '200',
      command    => 'flash',
      httpheader => 'Server: test',
      host       => 'example.invalid',
      path       => '/files/from_path.hex',
    };

    FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_ParseHttpResponse($param, '', 'X');

    my $set_calls = $mock_main->sub_tracking->{SIGNALduino_Set} // [];
    is(scalar(@{$set_calls}), 1, 'SIGNALduino_Set called once');
    is($set_calls->[0]{args}[3], 'FHEM/firmware/from_path.hex', 'filename derived from request path');
    like($logs[-1]{msg}, qr/Error while flashing: flash failed/, 'set error is logged');

    $mock_main->restore('SIGNALduino_Set');
    chdir $oldcwd or die "cannot restore cwd: $!";
  };

  subtest 'logs undefined error branch when response is not successful' => sub {
    plan(1);
    reset_state();
    my $param = {
      hash => $targetHash,
      url  => 'https://example.invalid/fw.hex',
      code => '404',
    };

    FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_ParseHttpResponse($param, '', '');

    like($logs[-1]{msg}, qr/undefined error while requesting .*code=404/, 'undefined error branch is logged');
  };
};

subtest 'githubParseHttpResponse tests' => sub {
  my $fixture_json = load_release_fixture_json();

  subtest 'testing channel with missing hardware keeps existing flash list' => sub {
    plan(2);
    reset_state();
    $mock_channel = 'testing';
    $mock_hardware = undef;
    $targetHash->{additionalSets}{flash} = 'seed-version';
    my $param = {
      hash    => $targetHash,
      command => 'queryReleases',
    };

    FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_githubParseHttpResponse($param, '', $fixture_json);

    is($targetHash->{additionalSets}{flash}, 'seed-version', 'existing flash list remains unchanged');
    like($logs[-1]{msg}, qr/hardware is not defined/, 'missing hardware is logged');
  };

  subtest 'testing channel with nano hardware includes prerelease tag' => sub {
    plan(1);
    reset_state();
    $mock_channel = 'testing';
    $mock_hardware = 'nano328';
    my $param = {
      hash    => $targetHash,
      command => 'queryReleases',
    };

    FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_githubParseHttpResponse($param, '', $fixture_json);

    like($targetHash->{additionalSets}{flash}, qr/3\.3\.1-RC10/, 'testing prerelease is present');
  };

  subtest 'testing channel with ESP8266 hardware excludes prerelease tag' => sub {
    plan(1);
    reset_state();
    $mock_channel = 'testing';
    $mock_hardware = 'ESP8266';
    my $param = {
      hash    => $targetHash,
      command => 'queryReleases',
    };

    FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_githubParseHttpResponse($param, '', $fixture_json);

    unlike($targetHash->{additionalSets}{flash}, qr/3\.3\.1-RC10/, 'testing prerelease is absent');
  };

  subtest 'stable channel with nanocc1101 hardware excludes 3.3.0' => sub {
    plan(1);
    reset_state();
    $mock_channel = 'stable';
    $mock_hardware = 'nanocc1101';
    my $param = {
      hash    => $targetHash,
      command => 'queryReleases',
    };

    FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_githubParseHttpResponse($param, '', $fixture_json);

    unlike($targetHash->{additionalSets}{flash}, qr/3\.3\.0/, 'stable 3.3.0 is absent');
  };

  subtest 'stable channel with nano hardware includes 3.3.0' => sub {
    plan(1);
    reset_state();
    $mock_channel = 'stable';
    $mock_hardware = 'nano328';
    my $param = {
      hash    => $targetHash,
      command => 'queryReleases',
    };

    FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_githubParseHttpResponse($param, '', $fixture_json);

    like($targetHash->{additionalSets}{flash}, qr/3\.3\.0/, 'stable 3.3.0 is present');
  };

  subtest 'stable channel with MAPLEMINI_F103CB hardware includes 3.4.0' => sub {
    plan(1);
    reset_state();
    $mock_channel = 'stable';
    $mock_hardware = 'MAPLEMINI_F103CB';
    my $param = {
      hash    => $targetHash,
      command => 'queryReleases',
    };

    FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_githubParseHttpResponse($param, '', $fixture_json);

    like($targetHash->{additionalSets}{flash}, qr/3\.4\.0/, 'stable 3.4.0 is present');
  };

  subtest 'stable channel with MAPLEMINI_F103CBcc1101 hardware includes 3.4.0' => sub {
    plan(1);
    reset_state();
    $mock_channel = 'stable';
    $mock_hardware = 'MAPLEMINI_F103CBcc1101';
    my $param = {
      hash    => $targetHash,
      command => 'queryReleases',
    };

    FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_githubParseHttpResponse($param, '', $fixture_json);

    like($targetHash->{additionalSets}{flash}, qr/3\.4\.0/, 'stable 3.4.0 is present');
  };

  subtest 'stable channel with ESP32 hardware includes 3.4.0' => sub {
    plan(1);
    reset_state();
    $mock_channel = 'stable';
    $mock_hardware = 'ESP32';
    my $param = {
      hash    => $targetHash,
      command => 'queryReleases',
    };

    FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_githubParseHttpResponse($param, '', $fixture_json);

    like($targetHash->{additionalSets}{flash}, qr/3\.4\.0/, 'stable 3.4.0 is present');
  };
};

done_testing();
