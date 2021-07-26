##############################################
# $Id: 10_SD_Rojaflex.pm 5 2021-07-26 21:00:00Z elektron-bbs $
#

package SD_Rojaflex;

use strict;
use warnings;
use GPUtils qw(GP_Import GP_Export);

our $VERSION = '0.8';

GP_Export(qw(
	Initialize
	)
);

# Import der FHEM Funktionen
BEGIN {
	GP_Import(qw(
		AssignIoPort
		AttrVal
		attr
		CommandSet
		defs
		gettimeofday
		InternalTimer
		IOWrite
		IsDummy
		IsIgnored
		Log3
		modules
		ReadingsVal
		RemoveInternalTimer
		readingsBeginUpdate
		readingsBulkUpdate
		readingsEndUpdate
	))
};

my %rev_codes; # reverse codes
my %codes = (
	'0' => 'stop',
	'1' => 'up',
	'8' => 'down',
	'9' => 'savefav',
	'D' => 'gotofav',
);

sub Initialize {
	my ($hash) = @_;
	for my $k (keys %codes) {
		$rev_codes{$codes{$k}} = $k; # reverse codes
	}
	$hash->{Match}      = '^P109#[a-fA-F0-9]{18}';
	$hash->{SetFn}      = \&Set;
	$hash->{DefFn}      = \&Define;
	$hash->{UndefFn}    = \&Undef;
	$hash->{ParseFn}    = \&Parse;
	$hash->{AttrFn}     = \&Attr;
	$hash->{AttrList}   = 'IODev '.
	                      'do_not_notify:0,1 '.
	                      'inversePosition:0,1 '.
	                      'repetition:1,2,3,4,5,6,7,8,9 '.
	                      'noPositionUpdates:0,1 '.
	                      'timeToClose '.
	                      'timeToOpen '.
	                      'ignore:1,0 dummy:0,1 showtime:0,1 '.
	                      "$main::readingFnAttributes";
	$hash->{AutoCreate} = {'SD_Rojaflex.*' => {FILTER => '%NAME', autocreateThreshold => '5:180', GPLOT => q{}}};
	return
}

sub Attr {
	my ( $cmd, $name, $attrName, $attrValue ) = @_;
	# $cmd - Vorgangsart, kann die Werte "del" (loeschen) oder "set" (setzen) annehmen
	# $name - Geraetename
	# $attrName - Attribut-Name
	# $attrValue - Attribut-Wert
	my $hash = $defs{$name};
	return "\"Attr: \" $name does not exist" if (!defined($hash));

	if ($cmd eq 'set') {
		if ($attrName eq 'repetition') {
			if ($attrValue !~ m/^[1-9]$/xms) { return "$name: Unallowed value $attrValue for the attribute repetition (must be 1 - 9)!" };
		}
		if ($attrName eq 'inversePosition') {
			my $oldinvers = AttrVal($name, 'inversePosition', 0);
			if ($attrValue ne $oldinvers) {
				my $pct = ReadingsVal($name, 'pct', 0);
				$pct = 100 - $pct;
				my $cpos = ReadingsVal($name, 'cpos', 0);
				$cpos = 100 - $cpos;
				my $tpos = ReadingsVal($name, 'tpos', 0);
				$tpos = 100 - $tpos;
				my $state;
				if ($pct > 0 && $pct < 100) {$state = $pct};
				if (ReadingsVal($name, 'state', 0) eq 'up') {$state = 'down'};
				if (ReadingsVal($name, 'state', 0) eq 'down') {$state = 'up'};
				if (ReadingsVal($name, 'state', 0) eq 'open') {$state = 'closed'};
				if (ReadingsVal($name, 'state', 0) eq 'closed') {$state = 'open'};
				readingsBeginUpdate($hash);
				readingsBulkUpdate($hash, 'pct', $pct, 1);
				readingsBulkUpdate($hash, 'cpos', $cpos, 1);
				readingsBulkUpdate($hash, 'tpos', $tpos, 1);
				readingsBulkUpdate($hash, 'state', $state, 1);
				readingsEndUpdate($hash, 1);
			}
		}
		if ($attrName eq 'noPositionUpdates') {
			if ($attrValue !~ m/^[0-1]$/xms) { return "$name: Unallowed value $attrValue for the attribute noPositionUpdates (must be 0 - 1)!" };
		}
		if ($attrName eq 'timeToClose' || $attrName eq 'timeToOpen') {
			if ($attrValue !~ m/^\d{1,3}$/xms || $attrValue < 1) { return "$name: Unallowed value $attrValue for the attribute $attrName (must be 1 - 999)!" };
		}
	}
	return;
}

sub Set {
	my ($hash, $name, @a) = @_;
	my $ioname = $hash->{IODev}{NAME};
	my $ret = undef;
	my $na = scalar @a; # Anzahl in Array
	my $cmd = $a[0];
	my $protocol = 109;
	my $state;
	my $motor = ReadingsVal($name, 'motor', 'stop');
	my $cpos = ReadingsVal($name, 'cpos', 50);
	my $tpos = ReadingsVal($name, 'tpos', 50);
	if (AttrVal($name,'inversePosition',0) eq '1') {
		$cpos = 100 - $cpos; # inverse position
		$tpos = 100 - $tpos; # inverse position
	}

	return "$name, no set value specified" if ($na < 1);
	return "Dummydevice $hash->{NAME}: will not set data" if (IsDummy($hash->{NAME}));

	if ($cmd eq q(?)) {;
		if (defined(ReadingsVal($name, 'MsgDown', undef))) {$ret .= 'down:noArg '};
		if (defined(ReadingsVal($name, 'MsgStop', undef))) {$ret .= 'stop:noArg '};
		if (defined(ReadingsVal($name, 'MsgUp', undef))) {$ret .= 'up:noArg '};
		if (defined(ReadingsVal($name, 'MsgSave', undef))) {$ret .= 'savefav:noArg '};
		if (defined(ReadingsVal($name, 'MsgGoto', undef))) {$ret .= 'gotofav:noArg '};
		if (defined(ReadingsVal($name, 'MsgStop', undef)) && defined(ReadingsVal($name, 'MsgGoto', undef)) && defined(ReadingsVal($name, 'MsgSave', undef))) {$ret .= 'clearfav:noArg '};
		# if (defined(ReadingsVal($name, 'MsgDown', undef)) && defined(ReadingsVal($name, 'MsgStop', undef)) && defined(ReadingsVal($name, 'MsgUp', undef))) {$ret .= 'pct:slider,0,1,100'};
		if (defined(ReadingsVal($name, 'MsgDown', undef)) && defined(ReadingsVal($name, 'MsgStop', undef)) && defined(ReadingsVal($name, 'MsgUp', undef))) {$ret .= 'pct:0,10,20,30,40,50,60,70,80,90,100'};
		return $ret; # return setlist
	}

	my $timeToClose = AttrVal($name,'timeToClose',30);
	my $timeToOpen = AttrVal($name,'timeToOpen',30);

	if ($cmd eq 'pct') {
		if ($na > 1) { # 0 = open ,100 = closed
			$tpos = $a[1];
			if (AttrVal($name,'inversePosition',0) eq '1') {$tpos = 100 - $tpos}; # inverse position
			if ($tpos != $cpos) {
				if ($tpos eq '0') {$cmd = 'up'}; # Fahr hoch
				if ($tpos eq '100') {$cmd = 'down'}; # Fahr runter
				Log3 $name, 3, "$ioname: SD_Rojaflex set $name pct $tpos";
				if ($tpos > 0 && $tpos < 100) {
					my $duration;
					if ($tpos > $cpos) { # Rolladen steht höher soll position
						$cmd = 'down'; # Fahr runter
						$duration = ($tpos - $cpos) * $timeToClose / 100;
					}
					if ($tpos < $cpos) { # Rolladen steht niedriger soll position
						$cmd = 'up';# Fahr hoch
						$duration = ($cpos - $tpos) * $timeToOpen / 100;
					}
					Log3 $name, 4, "$ioname: SD_Rojaflex set $name duration running time $duration s";
					InternalTimer( (gettimeofday() + $duration), \&SD_Rojaflex_pctStop, $name );
				}
			} else {
				$cmd = 'stop';
			}
		} else {
			$cmd = 'stop';
		}
	}

	my %setCodesAr = ();
	if (defined(ReadingsVal($name, 'MsgDown', undef))) {$setCodesAr{down} = 'MsgDown'};
	if (defined(ReadingsVal($name, 'MsgStop', undef))) {$setCodesAr{stop} = 'MsgStop'};
	if (defined(ReadingsVal($name, 'MsgUp', undef))) {$setCodesAr{up} = 'MsgUp'};
	if (defined(ReadingsVal($name, 'MsgSave', undef))) {$setCodesAr{savefav} = 'MsgSave'};
	if (defined(ReadingsVal($name, 'MsgGoto', undef))) {$setCodesAr{gotofav} = 'MsgGoto'};
	if (defined(ReadingsVal($name, 'MsgStop', undef)) && defined(ReadingsVal($name, 'MsgGoto', undef)) && defined(ReadingsVal($name, 'MsgSave', undef))) {$setCodesAr{clearfav} = 'MsgGoto'};

	if (%setCodesAr) {
		if (exists($setCodesAr{$cmd})) { # Code vorhanden
			my $msg = ReadingsVal($name, $setCodesAr{$cmd}, '');
			if (length($msg) != 18) {
				Log3 $name, 3, "$ioname: SD_Rojaflex set, $setCodesAr{$cmd} wrong length (must be 18)";
				return $ret;
			}
			$msg = "P$protocol#$msg";
			Log3 $name, 4, "$ioname: $name sendMsg=$msg";
			for my $i (1 .. AttrVal($name, 'repetition', 1)) {
				# Eine Wiederholung erfolgt bei der Fernbedienung nach 3,5 mS, so ist der Abstand groesser
				IOWrite($hash, 'sendMsg', $msg);
			}
			if ($cmd eq 'clearfav') {
				my $timelongest = $timeToOpen;
				if ($timeToClose > $timeToOpen) {$timelongest = $timeToClose};
				Log3 $name, 4, "$ioname: SD_Rojaflex set $name clearFav running time $timelongest s";
				InternalTimer( (gettimeofday() + $timelongest), \&SD_Rojaflex_clearfav, $name );
				$hash->{clearfavcount} = 0;
			}

			# Calculate target position and motor state
			if ($cmd eq 'down') {
				if ($na == 1) {$tpos = '100'}; # nicht bei "set pct xx"
				if ($cpos ne $tpos) {$motor = 'down'}; # Wenn nicht schon unten.
				if ($cpos eq $tpos) {$motor = 'stop'}; # Wenn unten.
			}
			if ($cmd eq 'up') {
				if ($na == 1) {$tpos = '0'}; # nicht bei "set pct xx"
				if ($cpos ne $tpos) {$motor = 'up'}; # Wenn nicht schon oben.
				if ($cpos eq $tpos) {$motor = 'stop'}; # Wenn oben.
			}
			if ($cmd eq 'stop') {
				$motor = 'stop';
			}
			if ($cmd eq 'savefav') {
				$motor = 'stop';
			}
			# if ($cmd eq 'gotofav') {
				# $motor = 'run';
			# }

			# Wenn keine PositionUpdates vom Motor kommen, setze gleich die finale Position
			if (AttrVal($name,'noPositionUpdates',0) eq '1') {
				# Jump direct to the final position, because we have no position updates and set motor stop
				$cpos = $tpos;
				$motor = 'stop';
				# Save current position
				if (AttrVal($name,'inversePosition',0) eq '1') {$cpos = 100 - $cpos}; # inverse position
				readingsBeginUpdate($hash);
				readingsBulkUpdate($hash, 'pct', $cpos, 1);
				readingsBulkUpdate($hash, 'cpos', $cpos, 1);
				readingsEndUpdate($hash, 1);
			}

			$state = $cmd;
			Log3 $name, 3, "$ioname: SD_Rojaflex set $name $state";
		} else {
			if ($cmd eq 'down' || $cmd eq 'stop' || $cmd eq 'up') {
				$state = "command still unknown, press the button \"$cmd\" on the remote control";
			} elsif ($cmd eq 'savefav' || $cmd eq 'gotofav' || $cmd eq 'clearfav') {
				$state = q(command still unknown, execute commands for setting the intermediate position with the remote control);
			} else {
				$state = "command \"$cmd\" is not supported";
			}
			Log3 $name, 3, "$ioname: $name, $state";
		}
	} else {
		$state = 'no set commands available, press all buttons on the remote control';
		Log3 $name, 3, "$ioname: $name, $state";
	}

	if (AttrVal($name,'inversePosition',0) eq '1') {$tpos = 100 - $tpos}; # inverse position
	readingsBeginUpdate($hash);
	readingsBulkUpdate($hash, 'tpos', $tpos, 1);
	readingsBulkUpdate($hash, 'motor', $motor, 1);
	readingsBulkUpdate($hash, 'state', $state, 1);
	readingsEndUpdate($hash, 1);
	return $ret;
}

sub SD_Rojaflex_pctStop {
	my ($name) = @_;
	my $hash = $defs{$name};
	RemoveInternalTimer(\&SD_Rojaflex_pctStop, $name);
	CommandSet($hash, "$name stop");
	return;
}

sub SD_Rojaflex_clearfav {
	my ($name) = @_;
	my $hash = $defs{$name};
	RemoveInternalTimer(\&SD_Rojaflex_clearfav, $name);
	$hash->{clearfavcount} += 1;
	if ($hash->{clearfavcount} < 4) {
		CommandSet($hash, "$name stop");
		InternalTimer( (gettimeofday() + 1), \&SD_Rojaflex_clearfav, $name );
	} else {
		CommandSet($hash, "$name savefav");
		delete($hash->{clearfavcount});
	}
	return;
}

sub Define {
	# define <name> SD_Rojaflex <hauscode>_<channel>
	# define SD_Rojaflex_Test_11 SD_Rojaflex 7AE312_11
	# define <name> SD_Rojaflex <hauscode>_<channel> <iodevice>
	# define SD_Rojaflex_Test_11 SD_Rojaflex 7AE312_11 sduino434
	my ($hash, $def) = @_;
	my @a = split m{\s+}xms , $def;
	my $name = $hash->{NAME};
	my $iodevice;
	my $ioname;

	return 'Define SD_Rojaflex wrong syntax: define <name> SD_Rojaflex housecode_channel' if (int(@a) < 3);
	my ($housecode, $channel) = split /[_]/xms , $a[2], 2;
	return 'Define SD_Rojaflex wrong syntax, must be: housecode_channel' if (!defined $housecode || !defined $channel);
	return 'Define SD_Rojaflex wrong housecode format: specify a 6 digit hex value [a-fA-F0-9]' if ($housecode !~ m/^[a-fA-F0-9]{6}$/xms );
	return 'Define SD_Rojaflex wrong channel format: specify a decimal value [1-15] or "a" for all' if ($channel !~ m/^[0-9]{1,2}|[aA]$/xms );
	if (scalar @a == 4) { $iodevice = $a[3] };

	$hash->{DEF} = $a[2];
	$hash->{VersionModule} = $VERSION;

	$modules{SD_Rojaflex}{defptr}{$hash->{DEF}} = $hash;
	if (exists $modules{SD_Rojaflex}{defptr}{ioname} && !defined $iodevice) { $ioname = $modules{SD_Rojaflex}{defptr}{ioname} };
	if (!defined $iodevice) { $iodevice = $ioname }
	AssignIoPort($hash, $iodevice);

	Log3 $name, 4, "SD_Rojaflex_Define: $a[0] HC=$housecode CHN=$channel";
	return;
}

sub Undef {
	my ($hash, $name) = @_;
	if (defined($hash->{CODE}) && defined($modules{SD_Rojaflex}{defptr}{$hash->{CODE}})) { delete($modules{SD_Rojaflex}{defptr}{$hash->{CODE}}) };
	return;
}

sub Parse {
	my ($iohash, $msg) = @_;
	my $ioname = $iohash->{NAME};
	my ($protocol,$rawData) = split /[#]/xms , $msg;
	$protocol =~ s/^[P](\d+)/$1/xms; # extract protocol
	my $EMPTY = q{};

	Log3 $ioname, 4, "$ioname: SD_Rojaflex_Parse, Protocol $protocol, rawData $rawData";

	my $housecode = substr $rawData,2,6;
	my $channel = hex substr $rawData,9,1;
	my $deviceCode = $housecode . q{_} . $channel;

	Log3 $ioname, 4, "$ioname: SD_Rojaflex_Parse, deviceCode $deviceCode, housecode $housecode, channel $channel";

	my $def = $modules{SD_Rojaflex}{defptr}{$iohash->{NAME} . q{_} . $deviceCode};
	$modules{SD_Rojaflex}{defptr}{ioname} = $ioname;
	if (!$def) { $def = $modules{SD_Rojaflex}{defptr}{$deviceCode} };

	if (!$def) {
		Log3 $ioname, 3, "$ioname: SD_Rojaflex_Parse, UNDEFINED device detected, Protocol $protocol, deviceCode $deviceCode, housecode $housecode, channel $channel, please define it";
		return "UNDEFINED SD_Rojaflex_$deviceCode SD_Rojaflex $deviceCode";
	}

	my $hash = $def;
	my $name = $hash->{NAME};
	return $EMPTY if (IsIgnored($name));

	my $state;
	my $MsgDown;
	my $MsgStop;
	my $MsgUp;
	my $MsgSave;
	my $MsgGoto;
	my $cmd = substr $rawData,10,1; # (0x0 = stop, 0x1 = up,0x8 = down, 0xE = Request, 0x9 = save/clear Pos, 0xD = goto Pos)
	my $dev = substr $rawData,11,1; # (0xA = remote control, 0x5 = tubular motor)
	my $motor = ReadingsVal($name, 'motor', 'stop');
	my $cpos = ReadingsVal($name, 'cpos', 50);
	my $tpos = ReadingsVal($name, 'tpos', 50);
	if (AttrVal($name,'inversePosition',0) eq '1') {
		$cpos = 100 - $cpos; # inverse position
		$tpos = 100 - $tpos; # inverse position
	}

	if ($dev eq 'A') { # remote control
		$state = $codes{$cmd};
		if ($cmd eq '8') {$MsgDown = ReadingsVal($name, 'MsgDown', undef)};
		if ($cmd eq '0') {$MsgStop = ReadingsVal($name, 'MsgStop', undef)};
		if ($cmd eq '1') {$MsgUp = ReadingsVal($name, 'MsgUp', undef)};
		if ($cmd eq '9') {$MsgSave = ReadingsVal($name, 'MsgSave', undef)};
		if ($cmd eq 'D') {$MsgGoto = ReadingsVal($name, 'MsgGoto', undef)};

		# Calculate target position and motor state
		if ($cmd eq '8') { # down
			$tpos = '100';
			if ($cpos ne $tpos) {$motor = 'down'}; # Wenn nicht schon unten
			if ($cpos eq $tpos) {$motor = 'stop'}; # Wenn unten
		}
		if ($cmd eq '1') { # up
			$tpos = '0';
			if ($cpos ne $tpos) {$motor = 'up'}; # Wenn nicht schon oben
			if ($cpos eq $tpos) {$motor = 'stop'}; # Wenn oben
		}
		if ($cmd eq '0') { # stop
			$motor = 'stop';
		}
	}

	if ($dev eq '5') { # tubular motor
		$cpos = hex substr $rawData,12,2;
		if ($cpos > 0 && $cpos < 100) {$state = $cpos};
		if ($cpos == 100) {$state = 'closed'};
		if ($cpos == 0) {$state = 'open'};
		# Calculate target position and motor state
		if ($cpos eq '0' && $motor eq 'up') {$motor = 'stop'}; # open
		if ($cpos eq '100' && $motor eq 'down') {$motor = 'stop'}; # closed
	}

	if (AttrVal($name,'inversePosition',0) eq '1') {
		$cpos = 100 - $cpos; # inverse position
		$tpos = 100 - $tpos; # inverse position
	}

	readingsBeginUpdate($hash);
	if (defined $state) {readingsBulkUpdate($hash, 'state', $state)};
	if (defined $motor) {readingsBulkUpdate($hash, 'motor', $motor)};
	if (defined $tpos) {readingsBulkUpdate($hash, 'tpos', $tpos)};
	if ($dev eq 'A') { # remote control
		if ($cmd eq '8' && !defined $MsgDown) {readingsBulkUpdate($hash, 'MsgDown', $rawData, 0)};
		if ($cmd eq '0' && !defined $MsgStop) {readingsBulkUpdate($hash, 'MsgStop', $rawData, 0)};
		if ($cmd eq '1' && !defined $MsgUp) {readingsBulkUpdate($hash, 'MsgUp', $rawData, 0)};
		if ($cmd eq '9' && !defined $MsgSave) {readingsBulkUpdate($hash, 'MsgSave', $rawData, 0)};
		if ($cmd eq 'D' && !defined $MsgGoto) {readingsBulkUpdate($hash, 'MsgGoto', $rawData, 0)};
	}
	if ($dev eq '5') { # tubular motor
		if (defined $cpos) {
			readingsBulkUpdate($hash, 'pct', $cpos);
			readingsBulkUpdate($hash, 'cpos', $cpos)
		}
	}
	readingsEndUpdate($hash, 1);
	return $name;
}

1;

=pod
=encoding utf8
=item device
=item summary devices communicating using the Rojaflex protocol
=item summary_DE Anbindung von Rojaflex Ger&auml;ten

=begin html

<a id="SD_Rojaflex"></a>
<h3>SD_Rojaflex</h3>
<ul>
	The SD_Rojaflex module decrypts and sends messages that are processed by the SIGNALduino.<br>
	Currently supported are the following types: Rojaflex HSR-15.
	<br><br>

	<a id="SD_Rojaflex-define"></a>
	<b>Define</b>
	<ul>
		Newly received devices are usually automatically created in FHEM via autocreate in the following form:<br>
		<code>SD_Rojaflex_3122FD_9</code><br><br>
		But it is also possible to define the devices yourself:<br>
		<code>define &lt;name&gt; SD_Rojaflex &lt;housecode&gt;_&lt;channel&gt;</code>
		<br><br>
		<code>&lt;name&gt;</code> is any name assigned to the device.
		For a better overview, we recommend a name in the form &quot;SD_Rojaflex_AE22F3_12&quot; to use,
		in which &quot;AE22F3&quot; the house code used and &quot;12&quot; represents the channel.
		<br><br>
		<code>&lt;housecode&gt;</code> corresponds to the house code of the remote control used or of the device that is to be controlled.
		<br><br>
		<code>&lt;channel&gt;</code> represents the channel of the devices used.
		A special feature is channel 0. This is used to control all drives with the same house code simultaneously.
	</ul>
	<br>

	<a id="SD_Rojaflex-set"></a>
	<b>Set</b>
	<ul>
		Before the set commands can be used, all codes must be learned once with the associated remote control.
		You can tell that the codes have been learned from the readings "MsgDown", "MsgStop", "MsgUp" etc. (see Readings).
		<br><br>
		<code>set &lt;name&gt; &lt;value&gt; [&lt;num&gt;]</code>
		<br><br>
		<code>&lt;value&gt;</code> can be one of the following values:<br>
		<ul>
			<a id="SD_Rojaflex-set-clearfav"></a>
			<li>clearfav - Deletes the saved position.</li>
			<a id="SD_Rojaflex-set-down"></a>
			<li>down - Moves the drive completely down.</li>
			<a id="SD_Rojaflex-set-gotofav"></a>
			<li>gotofav - Moves the drive to the saved position.</li>
			<a id="SD_Rojaflex-set-pct"></a>
			<li>pct - Moves the drive to the position specified in percent.</li>
			<a id="SD_Rojaflex-set-savefav"></a>
			<li>savefav - Saves the current position.</li>
			<a id="SD_Rojaflex-set-stop"></a>
			<li>stop - Stops the drive.</li>
			<a id="SD_Rojaflex-set-up"></a>
			<li>up - Moves the drive completely upwards.</li>
		</ul>
		Optionally with &lt;num&gt; the number of repetitions of the messages when sending in the range from 1 to 9 can be specified.<br>
		At <code>&lt;pct&gt;</code> a percentage value can be selected as the target position from a drop-down list.
	</ul>
	<br>

	<a id="SD_Rojaflex-attr"></a>
	<b>Attributes</b>
	<ul>
		<a id="SD_Rojaflex-attr-IODev"></a>
		<li><a href="#IODev">IODev</a> - Sets the device that is to be used to send the signals.</li>
		<a id="SD_Rojaflex-attr-do_not_notify"></a>
		<li><a href="#do_not_notify">do_not_notify</a> - Disable FileLog/notify/inform notification for a device. This affects the received signal, the set and trigger commands.</li>
		<a id="SD_Rojaflex-attr-inversePosition"></a>
		<li>inversePosition - Reverses the readings of positions pct, cpos, and tpos.</li>
		<a id="SD_Rojaflex-attr-dummy"></a>
		<li>dummy - If the attribute is set, it is no longer possible to send.</li>
		<a id="SD_Rojaflex-attr-ignore"></a>
		<li><a href="#ignore">ignore</a> - The device will be ignored in the future if this attribute is set.</li>
		<a id="SD_Rojaflex-attr-noPositionUpdates"></a>
		<li>noPositionUpdates - If there is no feedback from the drive, the readings pct, cpos and tpos are calculated.</li>
		<a id="SD_Rojaflex-attr-repetition"></a>
		<li>repetition - Number of repetitions of the send commands.</li>
		<a id="SD_Rojaflex-attr-showtime"></a>
		<li><a href="#showtime">showtime</a> - Used in FHEMWEB to show the time of the last activity instead of the status in the overall view.</li>
		<a id="SD_Rojaflex-attr-timeToClose"></a>
		<li>timeToClose - Duration for complete closing in seconds.</li>
		<a id="SD_Rojaflex-attr-timeToOpen"></a>
		<li>timeToOpen - Time for complete opening in seconds.</li>
	</ul>
	<br>

	<b>Readings</b>
	<ul>
		<li>IODev - Device used for sending.</li>
		<li>MsgDown - Message that is sent when set down.</li>
		<li>MsgStop - Message that is sent when set stop.</li>
		<li>MsgUp - Message that is sent when set up.</li>
		<li>MsgGoto - Message that is sent when set gotofav.</li>
		<li>MsgSave - Message that is sent when set savefav.</li>
		<li>cpos - Current position in percent.</li>
		<li>motor - State of the drive.</li>
		<li>pct - Current position in percent.</li>
		<li>state - Current status.</li>
		<li>tpos - Target position in percent.</li>
	</ul>

</ul>

=end html

=begin html_DE

<a id="SD_Rojaflex"></a>
<h3>SD_Rojaflex</h3>
<ul>
	Das SD_Rojaflex-Modul entschl&uuml;sselt und sendet Nachrichten, die vom SIGNALduino verarbeitet werden.<br>
	Unterst&uuml;tzt werden z.Z. folgende Typen: Rojaflex HSR-15.
	<br><br>

	<a id="SD_Rojaflex-define"></a>
	<b>Define</b>
	<ul>
		Neu empfangene Geräte werden in FHEM normalerweise per autocreate automatisch in folgender Form angelegt:<br>
		<code>SD_Rojaflex_3122FD_9</code><br><br>
		Es ist aber auch möglich, die Geräte selbst zu definieren:<br>
		<code>define &lt;name&gt; SD_Rojaflex &lt;hauscode&gt;_&lt;kanal&gt;</code>
		<br><br>
		<code>&lt;name&gt;</code> ist ein beliebiger Name, der dem Ger&auml;t zugewiesen wird.
		Zur besseren &Uuml;bersicht wird empfohlen einen Namen in der Form &quot;SD_Rojaflex_AE22F3_12&quot; zu verwenden,
		wobei &quot;AE22F3&quot; den verwendeten Hauscode und &quot;12&quot; den Kanal darstellt.
		<br><br>
		<code>&lt;hauscode&gt;</code> entspricht dem Hauscode der verwendeten Fernbedienung bzw. des Ger&auml;tes, das gesteuert werden soll.
		<br><br>
		<code>&lt;kanal&gt;</code> stellt den Kanal der verwendeten Ger&auml;te dar.
		Eine Besonderheit ist Kanal 0. Dieser wird verwendet, um sämtliche Antriebe mit gleichem Hauscode simultan zu steuern.
	</ul>
	<br>

	<a id="SD_Rojaflex-set"></a>
	<b>Set</b>
	<ul>
		Bevor die Set-Befehle verwendet werden können, müssen sämtliche Kodes einmal mit der zugehörigen Fernbedienung angelernt werden.
		Das die Kodes angelernt wurden, erkennt man an den Readings "MsgDown", "MsgStop", "MsgUp" u.s.w. (siehe Readings).
		<br><br>
		<code>set &lt;name&gt; &lt;value&gt; [&lt;anz&gt;]</code>
		<br><br>
		<code>&lt;value&gt;</code> kann einer der folgenden Werte sein:<br>
		<ul>
			<a id="SD_Rojaflex-set-clearfav"></a>
			<li>clearfav - Löscht die gespeicherte Position.</li>
			<a id="SD_Rojaflex-set-down"></a>
			<li>down - Fährt den Antrieb komplett nach unten.</li>
			<a id="SD_Rojaflex-set-gotofav"></a>
			<li>gotofav - Fährt den Antrieb auf die gespeicherte Position.</li>
			<a id="SD_Rojaflex-set-pct"></a>
			<li>pct - Fährt den Antrieb auf die in Prozent angegebene Position.</li>
			<a id="SD_Rojaflex-set-savefav"></a>
			<li>savefav - Speichert die aktuelle Position.</li>
			<a id="SD_Rojaflex-set-stop"></a>
			<li>stop - Stoppt den Antrieb.</li>
			<a id="SD_Rojaflex-set-up"></a>
			<li>up - Fährt den Antrieb komplett nach oben.</li>
		</ul>
		Optional kann mit &lt;anz&gt; die Anzahl Wiederholungen der Nachrichten beim Senden im Bereich von 1 bis 9 angegeben werden.<br>
		Bei <code>&lt;pct&gt;</code> kann als Zielposition aus einer Dropdown-Liste ein prozentualer Wert gewählt werden.
	</ul>
	<br>

	<a id="SD_Rojaflex-attr"></a>
	<b>Attribute</b>
	<ul>
		<a id="SD_Rojaflex-attr-IODev"></a>
		<li><a href="#IODev">IODev</a> - Setzt das Gerät, welches zum Senden der Signale verwendet werden soll.</li>
		<a id="SD_Rojaflex-attr-do_not_notify"></a>
		<li><a href="#do_not_notify">do_not_notify</a> - Deaktiviert die Benachrichtigungen FileLog/notify/inform für das Gerät. Dies betrifft das empfangene Signal, die Set- und Triggerbefehle.</li>
		<a id="SD_Rojaflex-attr-inversePosition"></a>
		<li>inversePosition - Kehrt die Readings der Positionen pct, cpos und tpos um.</li>
		<a id="SD_Rojaflex-attr-dummy"></a>
		<li>dummy - Wenn das Attribut gesetzt ist, kann nicht mehr gesendet werden.</li>
		<a id="SD_Rojaflex-attr-ignore"></a>
		<li><a href="#ignore">ignore</a> - Das Gerät wird in Zukunft ignoriert, wenn dieses Attribut gesetzt ist.</li>
		<a id="SD_Rojaflex-attr-noPositionUpdates"></a>
		<li>noPositionUpdates - Falls vom Antrieb keine Rückmeldungen erfolgen, werden die Readings pct, cpos und tpos errechnet.</li>
		<a id="SD_Rojaflex-attr-repetition"></a>
		<li>repetition - Anzahl Wiederholungen der Sendebefehle.</li>
		<a id="SD_Rojaflex-attr-showtime"></a>
		<li><a href="#showtime">showtime</a> - Wird im FHEMWEB verwendet, um die Zeit der letzten Aktivität anstelle des Status in der Gesamtansicht anzuzeigen.</li>
		<a id="SD_Rojaflex-attr-timeToClose"></a>
		<li>timeToClose - Dauer für komplettes Schließen in Sekunden.</li>
		<a id="SD_Rojaflex-attr-timeToOpen"></a>
		<li>timeToOpen - Dauer für komplettes Öffnen in Sekunden.</li>
	</ul>
	<br>

	<b>Readings</b>
	<ul>
		<li>IODev - Gerät, das zum Senden verwendet wird.</li>
		<li>MsgDown - Nachricht, die bei set down gesendet wird.</li>
		<li>MsgStop - Nachricht, die bei set stop gesendet wird.</li>
		<li>MsgUp - Nachricht, die bei set up gesendet wird.</li>
		<li>MsgGoto - Nachricht, die bei set gotofav gesendet wird.</li>
		<li>MsgSave - Nachricht, die bei set savefav gesendet wird.</li>
		<li>cpos - Aktuelle Position in Prozent.</li>
		<li>motor - Zustand des Antriebes.</li>
		<li>pct - Aktuelle Position in Prozent.</li>
		<li>state - Aktueller Status.</li>
		<li>tpos - Zielposition in Prozent.</li>
	</ul>

</ul>

=end html_DE
=cut
