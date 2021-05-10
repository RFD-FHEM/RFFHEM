##############################################
# $Id: 10_SD_Rojaflex.pm 1 2021-05-10 16:00:00Z elektron-bbs $
#

package SD_Rojaflex;

use strict;
use warnings;
use GPUtils qw(GP_Import GP_Export);

our $VERSION = '0.1';

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
		CommandDefine
		CommandDelete
		IOWrite
		IsDummy
		IsIgnored
		Log3
		modules
		SetExtensions
		readingsSingleUpdate
	))
};

my %rev_codes; # reverse codes
my %codes = (
	'0' => 'stop',
	'1' => 'up',
	'8' => 'down',
	'E' => 'request',
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
	                      'do_not_notify:1,0 repetition:1,2,3,4,5,6,7,8,9 '.
	                      'ignore:1,0 dummy:1,0 showtime:1,0 '.
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

	if ($cmd eq 'set') {
		if ($attrName eq 'repetition') {
			if ($attrValue !~ m/^[1-9]$/xms) { return "$name: Unallowed value $attrValue for the attribute repetition (must be 1 - 9)!" };
		}
	}
	return;
}

sub Set {
	my ($hash, $name, @a) = @_;
	my $ioname = $hash->{IODev}{NAME};
	my $ret = undef;
	my $na = int @a; # Anzahl in Array

	return 'no set value specified' if ($na < 1); # if ($na < 2 || $na > 3);
	return "Dummydevice $hash->{NAME}: will not set data" if (IsDummy($hash->{NAME}));

	my $state;
	readingsSingleUpdate($hash, 'state', $state, 1);
	return $ret;
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

	Log3 $ioname, 3, "$ioname: SD_Rojaflex_Parse, Protocol $protocol, rawData $rawData";

	my $housecode = substr($rawData,2,6);
	my $channel = hex(substr($rawData,9,1));
	my $deviceCode = $housecode . q{_} . $channel;

	Log3 $ioname, 3, "$ioname: SD_Rojaflex_Parse, deviceCode $deviceCode, housecode $housecode, channel $channel";

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
	Log3 $name, 3, "$ioname: SD_Rojaflex_Parse, $name data=$rawData";

	my $state;
	my $cmd = substr($rawData,10,1); # (0x0 = stop, 0x1 = up,0x8 = down, 0xE = Request)
	$state = $codes{$cmd};

	readingsSingleUpdate($hash, 'state', $state, 1);
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
			<li>request</li>
		</ul>
		<br><br>
		The <a href="#setExtensions">set extensions</a> are supported.
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
			<li>request</li>
		</ul>
		Optional kann mit &lt;anz&gt; die Anzahl der Wiederholungen im Bereich von 1 bis 9 angegeben werden.
		<br><br>
		Die <a href="#setExtensions">set extensions</a> werden unterst&uuml;tzt.
	</ul>
	<br><br>

	<b>Attribute</b>
	<ul>
		<li><a href="#IODev">IODev</a></li>
		<li><a href="#do_not_notify">do_not_notify</a></li>
		<li><a href="#eventMap">eventMap</a></li>
		<li><a href="#ignore">ignore</a></li>
		<li><a href="#readingFnAttributes">readingFnAttributes</a></li>
		<li>repetition (Anzahl Wiederholungen der Sendebefehle)</li>
	</ul>
</ul>

=end html_DE
=cut
