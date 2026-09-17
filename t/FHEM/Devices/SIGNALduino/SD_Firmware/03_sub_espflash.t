#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use Test2::Mock qw(mock);
use File::Temp qw(tempdir);
use File::Spec;

use FHEM::Devices::SIGNALduino::SD_Firmware qw(:all);

my $target = 'espDummyDuino';
my @logs;

our %defs = (
  $target => {
    NAME       => $target,
    TYPE       => 'SIGNALduino',
    DeviceName => '10.2.11.40:23',
    logMethod  => sub {
      my ($name, $level, $msg) = @_;
      push @logs, { name => $name, level => $level, msg => $msg };
      return;
    },
  }
);
my $targetHash = $defs{$target};

my $mock_flashdevice = q{};
my $logdir = tempdir(CLEANUP => 1) . q{/};

my $mock_main = Test2::Mock->new(
  track    => 1,
  class    => 'main',
  autoload => 1,
  add      => [
    HttpUtils_NonblockingGet => sub { return; },
    DevIo_CloseDev           => sub { return; },
    DevIo_OpenDev            => sub { return; },
    readingsSingleUpdate     => sub { return; },
    FW_directNotify          => sub { return; },
    AttrVal                  => sub {
      my ($name, $attr, $default) = @_;
      return $mock_flashdevice if $attr eq 'flashDevice';
      return $logdir if $attr eq 'logdir';
      return $default;
    },
  ],
);

my $timer_mock = Test2::Mock->new(
  track => 1,
  class => 'FHEM::Core::Timer::Helper',
  add   => [
    addTimer => sub { return; },
  ],
);

sub reset_state {
  @logs = ();
  $mock_flashdevice = q{};
  $targetHash->{DeviceName} = '10.2.11.40:23';
  delete $targetHash->{FLASH_RESULT};
  delete $targetHash->{helper};
  $mock_main->clear_sub_tracking;
  $timer_mock->clear_sub_tracking;
}

sub write_image {
  my $content = shift // "\xE9ESPIMAGE\x00\xff\x10binary";   # \xE9 is the esp magic byte
  my $dir  = tempdir(CLEANUP => 1);
  my $file = File::Spec->catfile($dir, 'SIGNALESP_esp8266cc1101_3.5.0.bin');
  open my $fh, '>', $file or die "cannot create image: $!";
  binmode $fh;
  print {$fh} $content;
  close $fh or die "cannot close image: $!";
  return ($file, $content);
}

# The firmware serves the upload form at /update but takes the POST at /u, and the port
# from the definition is the telnet port of the firmware, not the web server.
subtest 'update url is derived from the address' => sub {
  plan(6);

  # from the definition: the port is the firmware's telnet port and must not be used
  is(FHEM::Devices::SIGNALduino::SD_Firmware::_esp_update_url('10.2.11.40:23', 0),
     'http://10.2.11.40/u', 'operational port is dropped');
  is(FHEM::Devices::SIGNALduino::SD_Firmware::_esp_update_url('signalesp', 0),
     'http://signalesp/u', 'host without a port');

  # spelled out in flashDevice: the user means that port
  is(FHEM::Devices::SIGNALduino::SD_Firmware::_esp_update_url('raspi:8080', 1),
     'http://raspi:8080/u', 'port from the attribute is kept');
  is(FHEM::Devices::SIGNALduino::SD_Firmware::_esp_update_url('http://host:8080/u', 1),
     'http://host:8080/u', 'complete URL wins');
  is(FHEM::Devices::SIGNALduino::SD_Firmware::_esp_update_url('HTTP://Host/u', 0),
     'HTTP://Host/u', 'scheme match is case insensitive');
  is(FHEM::Devices::SIGNALduino::SD_Firmware::_esp_update_url('[fe80::1]:23', 0),
     'http://[fe80::1]/u', 'ipv6 host survives the port removal');
};

subtest 'multipart body carries the image unchanged' => sub {
  plan(5);
  my $image = "binary\x00\x0d\x0a\xffdata";
  my ($body, $boundary) = FHEM::Devices::SIGNALduino::SD_Firmware::_esp_multipart_body('fw.bin', $image);

  like($boundary, qr/\ASIGNALduinoFlash[0-9a-f]{16}\z/, 'boundary has a stable shape');
  like($body, qr/\A--\Q$boundary\E\r\n/, 'body opens with the boundary');
  like($body, qr/name="update"; filename="fw\.bin"/, 'part is named update and carries the filename');
  like($body, qr/\r\n--\Q$boundary\E--\r\n\z/, 'body closes with the terminating boundary');
  ok(index($body, $image) >= 0, 'image bytes are embedded verbatim');
};

subtest 'EspFlash posts the image' => sub {
  plan(8);
  reset_state();
  my ($file, $image) = write_image();

  my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_EspFlash($targetHash, $file);

  my $calls = $mock_main->sub_tracking->{HttpUtils_NonblockingGet} // [];
  is($ret, undef, 'returns undef, the result arrives in the callback');
  is(scalar(@{$calls}), 1, 'one request is issued');

  my $req = $calls->[0]{args}[0];
  is($req->{url}, 'http://10.2.11.40/u', 'posts to the upload endpoint');
  is($req->{method}, 'POST', 'uses POST');
  like($req->{header}, qr{\AContent-Type: multipart/form-data; boundary=SIGNALduinoFlash}, 'declares the boundary');
  ok(index($req->{data}, $image) >= 0, 'body carries the image');
  is(scalar(@{$mock_main->sub_tracking->{DevIo_CloseDev} // []}), 1, 'connection is closed before the upload');
  ok($req->{timeout} > 60, 'timeout is generous enough for an upload');
};

subtest 'EspFlash honours flashDevice' => sub {
  plan(2);
  reset_state();
  $mock_flashdevice = 'http://espflash.local:8080/u';
  my ($file) = write_image();

  FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_EspFlash($targetHash, $file);

  my $req = $mock_main->sub_tracking->{HttpUtils_NonblockingGet}[0]{args}[0];
  is($req->{url}, 'http://espflash.local:8080/u', 'flashDevice wins over the definition');
  unlike($req->{url}, qr/10\.2\.11\.40/, 'address from the definition is not used');
};

subtest 'unreadable firmware aborts without dying' => sub {
  plan(4);
  reset_state();

  my $survived = lives {
    my $ret = FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_EspFlash($targetHash, '/no/such/firmware.bin');
    like($ret, qr/\AERROR: cannot read/, 'returns the error');
  };
  my $died_with = $@;

  ok($survived, 'EspFlash returns instead of dying') or diag("died with: $died_with");
  like($logs[-1]{msg}, qr/cannot read firmware file/, 'cause is logged');
  is(scalar(@{$mock_main->sub_tracking->{HttpUtils_NonblockingGet} // []}), 0, 'nothing is uploaded');
};

subtest 'response evaluation' => sub {
  my $success = q{<div class='msg S'><strong>Update successful.  </strong> <br/> Device rebooting now...</div>};
  my $failure = q{<div class='msg D'><strong>Update failed!</strong><Br/>Reboot device and try again</div>OTA Error: Bad Size};

  subtest 'successful upload' => sub {
    plan(3);
    reset_state();
    my $param = { hash => $targetHash, url => 'http://10.2.11.40/u', code => 200 };

    FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_EspFlashResponse($param, q{}, $success);

    ok(!exists $targetHash->{FLASH_RESULT}, 'no FLASH_RESULT on success');
    like($logs[-1]{msg}, qr/firmware update was successfull/, 'success is logged');
    is(scalar(@{$timer_mock->sub_tracking->{addTimer} // []}), 1, 'reconnect is scheduled');
  };

  # The device answers 200 even when it rejects the image, so the body has to decide.
  subtest 'device rejects the image despite HTTP 200' => sub {
    plan(4);
    reset_state();
    my $param = { hash => $targetHash, url => 'http://10.2.11.40/u', code => 200 };

    FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_EspFlashResponse($param, q{}, $failure);

    like($targetHash->{FLASH_RESULT}, qr/\AERROR: device did not confirm the update/, 'failure is detected');
    like($targetHash->{FLASH_RESULT}, qr/Bad Size/, 'reason from the device is kept');
    is($logs[-1]{level}, 1, 'logged as an error');
    is(scalar(@{$timer_mock->sub_tracking->{addTimer} // []}), 1, 'reconnect is scheduled anyway');
  };

  # Anything that is not an explicit success has to count as failure - the upload form,
  # a captive portal, or an empty body because the device rebooted before answering.
  subtest 'unexpected answer is not taken for success' => sub {
    plan(2);
    reset_state();
    my $param = { hash => $targetHash, url => 'http://10.2.11.40/u', code => 200 };

    FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_EspFlashResponse($param, q{}, q{});

    like($targetHash->{FLASH_RESULT}, qr/did not confirm the update/, 'empty body is not success');
    like($targetHash->{FLASH_RESULT}, qr/unexpected answer/, 'names the reason');
  };

  # The reason comes from the device and ends up in a javascript string literal.
  subtest 'reason from the device is escaped for the dialog' => sub {
    plan(2);
    reset_state();
    my $param = { hash => $targetHash, url => 'http://10.2.11.40/u', code => 200 };
    my $evil = q{<div>Update failed!</div>OTA Error: x');alert(1);//};

    {
      local $main::FW_wname = 'testweb';
      FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_EspFlashResponse($param, q{}, $evil);
    }

    my $notify = $mock_main->sub_tracking->{FW_directNotify}[0]{args};
    like($notify->[1], qr/\A\#FHEMWEB:/, 'uses the channel FHEMWEB actually listens on');
    unlike($notify->[2], qr/\Q');alert(1)\E/, 'payload cannot close the javascript string');
  };

  subtest 'transport error' => sub {
    plan(2);
    reset_state();
    my $param = { hash => $targetHash, url => 'http://10.2.11.40/u' };

    FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_EspFlashResponse($param, 'connect timed out', q{});

    like($targetHash->{FLASH_RESULT}, qr/firmware upload failed - connect timed out/, 'error is reported');
    is($logs[-1]{level}, 1, 'logged as an error');
  };

  subtest 'unexpected http status' => sub {
    plan(1);
    reset_state();
    my $param = { hash => $targetHash, url => 'http://10.2.11.40/u', code => 404 };

    FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_EspFlashResponse($param, q{}, 'Not found');

    like($targetHash->{FLASH_RESULT}, qr/device answered with HTTP 404/, 'status is reported');
  };
};

subtest 'reopen reconnects the device' => sub {
  plan(1);
  reset_state();

  FHEM::Devices::SIGNALduino::SD_Firmware::SIGNALduino_EspReopen($target);

  is(scalar(@{$mock_main->sub_tracking->{DevIo_OpenDev} // []}), 1, 'DevIo_OpenDev is called');
};

done_testing();
