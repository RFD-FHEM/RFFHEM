##############################################
# $Id: 10_SD_Rojaflex.pm 3 2021-05-30 16:00:00Z elektron-bbs $
#

package SD_Rojaflex;

use strict;
use warnings;
use GPUtils qw(GP_Import GP_Export);

our $VERSION = '0.3';

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
	# $cmd  - Vorgangsart, kann die Werte "del" (loeschen) oder "set" (setzen) annehmen
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
				readingsBeginUpdate($hash);
				readingsBulkUpdate($hash, 'pct', $pct, 1);
				readingsBulkUpdate($hash, 'state', $pct, 1) if ($pct > 0 && $pct < 100);
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
	my $state;
	my $motor = ReadingsVal($name, 'motor', 'stop');
	my $cpos  = ReadingsVal($name, 'cpos', 50);
	$cpos = 100 - $cpos if (AttrVal($name,'inversePosition',0) eq '1'); # inverse position
	my $tpos = ReadingsVal($name, 'tpos', 50);
	$tpos = 100 - $tpos if (AttrVal($name,'inversePosition',0) eq '1'); # inverse position

	return "$name, no set value specified" if ($na < 1);
	return "Dummydevice $hash->{NAME}: will not set data" if (IsDummy($hash->{NAME}));

	if ($cmd eq '?') {;
		$ret .= 'down:noArg ' if defined(ReadingsVal($name, 'MsgDown', undef));
		$ret .= 'stop:noArg ' if defined(ReadingsVal($name, 'MsgStop', undef));
		$ret .= 'up:noArg ' if defined(ReadingsVal($name, 'MsgUp', undef));
		# $ret .= 'pct:slider,0,1,100' if (defined(ReadingsVal($name, 'MsgDown', undef)) && defined(ReadingsVal($name, 'MsgStop', undef)) && defined(ReadingsVal($name, 'MsgUp', undef)));
		$ret .= 'pct:0,10,20,30,40,50,60,70,80,90,100' if (defined(ReadingsVal($name, 'MsgDown', undef)) && defined(ReadingsVal($name, 'MsgStop', undef)) && defined(ReadingsVal($name, 'MsgUp', undef)));
		return $ret; # return setlist
	}

	if ($cmd eq 'pct') {
		if ($na > 1) { # 0 = open ,100 = closed
			my $timeToClose = AttrVal($name,'timeToClose',30);
			my $timeToOpen = AttrVal($name,'timeToOpen',30);
			my $tmp = $a[1];
			$tmp = 100 - $tmp if (AttrVal($name,'inversePosition',0) eq '1'); # inverse position
			$tpos = $tmp;
			$cmd = 'up' if ($tmp eq '0'); # Fahr hoch
			$cmd = 'down' if ($tmp eq '100'); # Fahr runter
			Log3 $name, 3, "$ioname: SD_Rojaflex set $name pct $tmp";
			if($tmp > 0 && $tmp < 100) {
				my $duration;
				if($tmp > ($cpos + 1)) { # Rolladen steht höher soll position
					$cmd = 'down'; # Fahr runter
					$duration = ($tmp - $cpos) * $timeToClose / 100;
				}
				if($cpos > ($tmp + 1)) { # Rolladen steht niedriger soll position
				  $cmd = 'up';# Fahr hoch
					$duration = ($cpos - $tmp) * $timeToOpen / 100;
				}
				Log3 $name, 4, "$ioname: SD_Rojaflex set $name duration running time $duration s";
				InternalTimer( (gettimeofday() + $duration), \&SD_Rojaflex_pctStop, $name );
			}
		} else {
			$cmd = 'stop';
		}
	}
	
	my @setCodesAr;
	push @setCodesAr,'down' if defined(ReadingsVal($name, 'MsgDown', undef));
	push @setCodesAr,'stop' if defined(ReadingsVal($name, 'MsgStop', undef));
	push @setCodesAr,'up' if defined(ReadingsVal($name, 'MsgUp', undef));

	if (scalar @setCodesAr > 1) {
		if (grep {/$cmd/xms} @setCodesAr) { # Code vorhanden
			my $msg = 'SN;R=1;D=';
			$msg .= ReadingsVal($name, 'MsgDown', undef) if ($cmd eq 'down');
			$msg .= ReadingsVal($name, 'MsgStop', undef) if ($cmd eq 'stop');
			$msg .= ReadingsVal($name, 'MsgUp', undef) if ($cmd eq 'up');
			$msg .= ';';
			for my $i (1 .. AttrVal($name, 'repetition', 1)) {
				# Eine Wiederholung erfolgt bei der Fernbedienung nach 3,5 mS, so ist der Abstand groesser
				IOWrite($hash, 'raw', $msg) if (length($msg) == 28);
			}

			# Calculate target position and motor state
			if($cmd eq 'down') {
				$tpos  = '100' if ($na == 1); # nicht bei "set pct xx"
				$motor = 'down' if ($cpos ne $tpos); # Wenn nicht schon unten.
				$motor = 'stop' if ($cpos eq $tpos); # Wenn unten.
			}
			if($cmd eq 'up') {
				$tpos = '0' if ($na == 1); # nicht bei "set pct xx"
				$motor = 'up'   if ($cpos ne $tpos); # Wenn nicht schon oben.
				$motor = 'stop' if ($cpos eq $tpos); # Wenn oben.
			}
			if($cmd eq 'stop') {
				# $tpos = $cpos;
				$motor = 'stop';
			}

			# Wenn keine PositionUpdates vom Motor kommen, setze gleich die finale Position
			if (AttrVal($name,'noPositionUpdates',0) eq '1') {
				# Jump direct to the final position, because we have no position updates and set motor stop
				$cpos = $tpos;
				$motor = 'stop';
				# Save current position
				$cpos = 100 - $cpos if (AttrVal($name,'inversePosition',0) eq '1'); # inverse position
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
				Log3 $name, 3, "$ioname: $name, $state";
			} else {
				$state = "command \"$cmd\" is not supported";
				Log3 $name, 3, "$ioname: $name, $state";
			}	
		}
	} else {
		$state = 'no set commands available, press all buttons on the remote control';
		Log3 $name, 3, "$ioname: $name, $state";
	}

	$tpos = 100 - $tpos if (AttrVal($name,'inversePosition',0) eq '1'); # inverse position			
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

	my $housecode = substr($rawData,2,6);
	my $channel = hex(substr($rawData,9,1));
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
	my $cmd = substr($rawData,10,1); # (0x0 = stop, 0x1 = up,0x8 = down, 0xE = Request)
	my $dev = substr($rawData,11,1); # (0xA = remote control, 0x5 = tubular motor)

	my $motor = ReadingsVal($name, 'motor', 'stop');
	my $cpos  = ReadingsVal($name, 'cpos', 50);
	$cpos = 100 - $cpos if (AttrVal($name,'inversePosition',0) eq '1'); # inverse position
	my $tpos = ReadingsVal($name, 'tpos', 50);
	$tpos = 100 - $tpos if (AttrVal($name,'inversePosition',0) eq '1'); # inverse position

	if ($dev eq 'A') { # remote control
		$state = $codes{$cmd};
		$MsgDown = ReadingsVal($name, 'MsgDown', undef) if ($cmd eq '8');
		$MsgStop = ReadingsVal($name, 'MsgStop', undef) if ($cmd eq '0');
		$MsgUp   = ReadingsVal($name, 'MsgUp',   undef) if ($cmd eq '1');
		
		# Calculate target position and motor state
		if($cmd eq '8') { # down
			$tpos = '100';
			$motor = 'down' if ($cpos ne $tpos); #Wenn nicht schon unten
			$motor = 'stop' if ($cpos eq $tpos); #Wenn unten
		}
		if($cmd eq '1') { # up
			$tpos = '0';
			$motor = 'up'   if ($cpos ne $tpos); #Wenn nicht schon oben
			$motor = 'stop' if ($cpos eq $tpos); #Wenn oben
		}
		if($cmd eq '0') { # stop
			$motor = 'stop';
		}
	}

	if ($dev eq '5') { # tubular motor
		$cpos = hex(substr($rawData,12,2));
		$state = $cpos if ($cpos > 0 && $cpos < 100);
		$state = 'closed' if ($cpos == 100);
		$state = 'open' if ($cpos == 0);
		# Calculate target position and motor state
		if($cpos eq '0' && $motor eq 'up') { #open
			$motor = 'stop';
		}
		if($cpos eq '100' && $motor eq 'down') { #closed
			$motor = 'stop';
		}
		# if($motor eq 'stop') {
			# $tpos = $cpos;
		# }
	}
	
	$cpos = 100 - $cpos if (AttrVal($name,'inversePosition',0) eq '1'); # inverse position
	$tpos = 100 - $tpos if (AttrVal($name,'inversePosition',0) eq '1'); # inverse position
	
	readingsBeginUpdate($hash);
	readingsBulkUpdate($hash, 'state', $state) if (defined $state);
	readingsBulkUpdate($hash, 'motor', $motor) if (defined $motor);
	readingsBulkUpdate($hash, 'tpos', $tpos) if (defined $tpos);
	if ($dev eq 'A') { # remote control
		readingsBulkUpdate($hash, 'MsgDown', $rawData, 0) if ($cmd eq '8' && !defined $MsgDown);
		readingsBulkUpdate($hash, 'MsgStop', $rawData, 0) if ($cmd eq '0' && !defined $MsgStop);
		readingsBulkUpdate($hash, 'MsgUp', $rawData, 0) if ($cmd eq '1' && !defined $MsgUp);
	}
	if ($dev eq '5') { # tubular motor
		readingsBulkUpdate($hash, 'pct', $cpos) if (defined $cpos);
		readingsBulkUpdate($hash, 'cpos', $cpos) if (defined $cpos); # for Homekit
	}
	readingsEndUpdate($hash, 1);
	return $name;
}

1;

__END__

=pod
=encoding utf8
=item device
=item summary devices communicating using the Rojaflex protocol
=item summary_DE Anbindung von Rojaflex Ger&auml;ten

=begin html

<a name="SD_Rojaflex"></a>
<h3>SD_Rojaflex</h3>
<ul>
	The SD_Rojaflex module decrypts and sends Rojaflex messages, which are processed by the SIGNALduino.
	The following types are supported at the moment: Rojaflex HSR-1, HSR-5, HSR-15, HSTR-5, HSTR-15, RHSM1.
	<br><br>

	<b>Define</b>
	<ul>
		<code>define &lt;name&gt; SD_Rojaflex &lt;housecode&gt;_&lt;channel&gt;</code>
		<br><br>
		<code>&lt;name&gt;</code> is any name that is assigned to the device.
		For a better overview it is recommended to use a name in the form &quot;SD_Rojaflex_AE22F3_12&quot;,
		where &quot;AE22F3&quot; is the used house code and &quot;12&quot; is the channel.
		<br><br>
		<code>&lt;hauscode&gt;</code> corresponds to the house code of the remote control or the device to be controlled.
		<br><br>
		<code>&lt;channel&gt;</code> represents the channel of the devices used.
	</ul>
	<br><br>

	<b>Set</b>
	<ul>
		<code>set &lt;name&gt; &lt;value&gt; [&lt;anz&gt;]</code>
		<br><br>
		<code>&lt;value&gt;</code> can be one of the following values::<br>
		<ul>
			<li>down</li>
			<li>up</li>
			<li>stop</li>
		</ul>
		<br><br>
	</ul>
	<br><br>

	<b>Attribute</b>
	<ul>
		<li><a href="#IODev">IODev</a></li>
		<li><a href="#do_not_notify">do_not_notify</a></li>
		<li><a href="#eventMap">eventMap</a></li>
		<li><a href="#ignore">ignore</a></li>
		<li><a href="#readingFnAttributes">readingFnAttributes</a></li>
		<li>repetition (Number of repetitions of the send commands)</li>
	</ul>
</ul>

=end html

=begin html_DE

<a name="SD_Rojaflex"></a>
<h3>SD_Rojaflex</h3>
<ul>
	Das SD_Rojaflex-Modul entschl&uuml;sselt und sendet Nachrichten vom Typ Rojaflex, die vom SIGNALduino verarbeitet werden.
	Unterst&uuml;tzt werden z.Z. folgende Typen: Rojaflex HSR-1, HSR-5, HSR-15, HSTR-5, HSTR-15, RHSM1.
	<br><br>

	<b>Define</b>
	<ul>
		<code>define &lt;name&gt; SD_Rojaflex &lt;hauscode&gt;_&lt;kanal&gt;</code>
		<br><br>
		<code>&lt;name&gt;</code> ist ein beliebiger Name, der dem Ger&auml;t zugewiesen wird.
		Zur besseren &Uuml;bersicht wird empfohlen einen Namen in der Form &quot;SD_Rojaflex_AE22F3_12&quot; zu verwenden,
		wobei &quot;AE22F3&quot; den verwendeten Hauscode und &quot;12&quot; den Kanal darstellt.
		<br><br>
		<code>&lt;hauscode&gt;</code> entspricht dem Hauscode der verwendeten Fernbedienung bzw. des Ger&auml;tes, das gesteuert werden soll.
		<br><br>
		<code>&lt;kanal&gt;</code> stellt den Kanal der verwendeten Ger&auml;te dar.
	</ul>
	<br><br>

	<b>Set</b>
	<ul>
		<code>set &lt;name&gt; &lt;value&gt; [&lt;anz&gt;]</code>
		<br><br>
		<code>&lt;value&gt;</code> kann einer der folgenden Werte sein:<br>
		<ul>
			<li>down</li>
			<li>up</li>
			<li>stop</li>
		</ul>
		Optional kann mit &lt;anz&gt; die Anzahl der Wiederholungen im Bereich von 1 bis 9 angegeben werden.
	</ul>
	<br><br>

	<b>Attribute</b>
	<ul>
		<li><a href="#IODev">IODev</a>Setzt das Gerät, welches zum Senden der Signale verwendet werden soll.</li>
		<li><a href="#do_not_notify">do_not_notify</a></li>
		<a name="inversePosition"></a>
		<li>inversePosition - Die Readings der Positionen pct, cpos und tpos umkehren.</li>
		<a name="dummy"></a>
		<li>dummy - Wenn das Attribut gesetzt ist, kann nicht mehr gesendet werden.</li>
		<li><a href="#ignore">ignore</a> - Das Gerät wird in Zuknft ignoriert, wenn diese Attribut gesetzt ist.</li>
		<a name="noPositionUpdates"></a>
		<li>noPositionUpdates - Falls vom Antrieb keine Rückmeldungen erfolgen, werden die Readings pct, cpos und tpos errechnet.</li>
		<a name="repetition"></a>
		<li>repetition - Anzahl Wiederholungen der Sendebefehle</li>
		<li><a href="#showtime">showtime</a> - Wird im FHEMWEB verwendet, um die Zeit der letzten Aktivitätanstelle des Status in der Gesamtansicht anzuzeigen.</li>
		<a name="timeToClose"></a>
		<li>timeToClose - Dauer für komplettes Schließen in Sekunden.</li>
		<a name="timeToOpen"></a>
		<li>timeToOpen - Dauer für komplettes Öffnen in Sekunden.</li>
	</ul>
	<br><br>

	<b>Readings</b>
	<ul>
		<li>IODev - Gerät, das zum Senden verwendet wird.</li>
		<li>MsgDown - Nachricht, die bei set down gesendet wird.</li>
		<li>MsgStop - Nachricht, die bei set stop gesendet wird.</li>
		<li>MsgUp - Nachricht, die bei set up gesendet wird.</li>
		<li>cpos - aktuelle Position in Prozent</li>
		<li>motor - Zustand des Antriebes</li>
		<li>pct - aktuelle Position in Prozent</li>
		<li>state - aktueller Status</li>
		<li>tpos - Zielposition in Prozent</li>
	</ul>

</ul>

=end html_DE
=cut
