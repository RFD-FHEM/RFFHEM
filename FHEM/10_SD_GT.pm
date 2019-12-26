#################################################################
# $Id: 10_SD_GT.pm 0 2019-12-11 21:00:00Z elektron-bbs $
#
# The file is part of the SIGNALduino project.
#
# 2019 - HomeAuto_User & elektron-bbs
# for remote controls using protocol QUIGG Gt-9000
# based on code quigg_gt9000.c from pilight
#################################################################

package main;

use strict;
use warnings;

sub SD_GT_Initialize($) {
	my ($hash) = @_;
	$hash->{Match}      = "^P49#[A-Fa-f0-9]+";
	$hash->{DefFn}      = "SD_GT::Define";
	$hash->{UndefFn}    = "SD_GT::Undef";
	$hash->{ParseFn}    = "SD_GT::Parse";
	$hash->{SetFn}      = "SD_GT::Set";
	$hash->{AttrList}   = "IODev do_not_notify:1,0 ignore:0,1 showtime:1,0 $main::readingFnAttributes";
	$hash->{AutoCreate} = {"SD_GT_LEARN" => {FILTER => "%NAME", autocreateThreshold => "5:180", GPLOT => ""}};
}

#################################################################

package SD_GT;

use strict;
use warnings;
use GPUtils qw(:all);  # wird fuer den Import der FHEM Funktionen aus der fhem.pl benoetigt

## Import der FHEM Funktionen
BEGIN {
		GP_Import(qw(
		AssignIoPort
		AttrVal
		attr
		defs
		DoTrigger
		IOWrite
		IsIgnored
		Log3
		modules
		ReadingsVal
		readingsBeginUpdate
		readingsBulkUpdate
		readingsEndUpdate
		readingsSingleUpdate
		))
};

sub parseSystemcodeHex($$);
sub decodePayload($$$$);
sub checkVersion(@);
sub getSystemCodes($);

my %buttons = (
	'1' => {	# Version 1
						'hash' => [0x0, 0x9, 0xF, 0x4, 0xA, 0xD, 0x5, 0xB, 0x3, 0x2, 0x1, 0x7, 0xE, 0x6, 0xC, 0x8],
						'C' => {	# unit C
											'unit' => "A",
											'1' => "on",
											'5' => "on",
											'6' => "on",
											'A' => "on",
											'2' => "off",
											'7' => "off",
											'8' => "off",
											'B' => "off",
                    },
						'5' => {	# unit 5
											'unit' => "B",
											'0' => "on",
											'3' => "on",
											'E' => "on",
											'F' => "on",
											'4' => "off",
											'9' => "off",
											'C' => "off",
											'D' => "off",
                    },
						'E' => {	# unit 5
											'unit' => "C",
											'2' => "on",
											'7' => "on",
											'8' => "on",
											'B' => "on",
											'1' => "off",
											'5' => "off",
											'6' => "off",
											'A' => "off",
                    },
						'7' => {	# unit 7
											'unit' => "D",
											'4' => "on",
											'9' => "on",
											'C' => "on",
											'D' => "on",
											'0' => "off",
											'3' => "off",
											'E' => "off",
											'F' => "off",
                    },
						'2' => {	# unit 2
											'unit' => "all",
											'2' => "on",
											'7' => "on",
											'8' => "on",
											'B' => "on",
											'1' => "off",
											'5' => "off",
											'6' => "off",
											'A' => "off",
                    },
					},
	'2' => {	# Version 2
						'hash' => [0x0, 0x9, 0x5, 0xF, 0x3, 0x6, 0xC, 0x7, 0xE, 0xD, 0x1, 0xB, 0x2, 0xA, 0x4, 0x8],
						'0' => {	# unit 0
											'unit' => "A",
											'3' => "on",
											'4' => "on",
											'7' => "on",
											'B' => "on",
											'1' => "off",
											'2' => "off",
											'9' => "off",
											'A' => "off",
                    },
						'4' => {	# unit 4
											'unit' => "B",
											'3' => "on",
											'4' => "on",
											'7' => "on",
											'B' => "on",
											'1' => "off",
											'2' => "off",
											'9' => "off",
											'A' => "off",
                   },
						'C' => {	# unit C
											'unit' => "C",
											'3' => "on",
											'4' => "on",
											'7' => "on",
											'B' => "on",
											'1' => "off",
											'2' => "off",
											'9' => "off",
											'A' => "off",
                    },
						'2' => {	# unit 2
											'unit' => "D",
											'1' => "on",
											'2' => "on",
											'9' => "on",
											'A' => "on",
											'3' => "off",
											'4' => "off",
											'7' => "off",
											'B' => "off",
                    },
						'A' => {	# unit A
											'unit' => "all",
											'1' => "on",
											'2' => "on",
											'9' => "on",
											'A' => "on",
											'3' => "off",
											'4' => "off",
											'7' => "off",
											'B' => "off",
                    },
					}
);

sub Define($$) {
	my ($hash, $def) = @_;
	my @a = split("[ \t][ \t]*", $def);
	my $name = $hash->{NAME};

	return "SD_GT: wrong syntax: define <name> SD_GT <. . .>" if(int(@a) < 2);

	my $iodevice = $a[4] if($a[4]);

	$modules{SD_GT}{defptr}{$hash->{DEF}} = $hash;
	my $ioname = $modules{SD_GT}{defptr}{ioname} if (exists $modules{SD_GT}{defptr}{ioname} && not $iodevice);
	$iodevice = $ioname if not $iodevice;

	$attr{$name}{room}	= "SD_GT"	if ( not exists( $attr{$name}{room} ) );				# set room, if only undef --> new def

	AssignIoPort($hash, $iodevice);
}

sub Set($$$@) {
	my ($hash, $name, $cmd, @a) = @_;
	my $ioname = $hash->{IODev}{NAME};
	my $repeats = AttrVal($name,'repeats', '5');
	my $ret = undef;

  return "\"set $name\" needs at least one argument" unless(defined($cmd));

	if ($cmd eq "?") {
		if ($hash->{DEF} ne "LEARN") {
			$ret .= "off:noArg " if (ReadingsVal($name, "CodesOff", "") ne "");
			$ret .= "on:noArg " if (ReadingsVal($name, "CodesOn", "") ne "");
		}
		return $ret;
	}
	
	my $sendCodesStr;
	my @sendCodesAr;
	my $sendCodesCnt;
	my $sendCode = ReadingsVal($name, "SendCode", "");	# load last sendCode
	$sendCodesStr = ReadingsVal($name, "CodesOn", "") if ($cmd eq "on");
	$sendCodesStr = ReadingsVal($name, "CodesOff", "") if ($cmd eq "off");
	@sendCodesAr = split(",", $sendCodesStr);
	$sendCodesCnt = scalar(@sendCodesAr);
  return "$name: No codes available for sending, please press buttons on your remote for learning." if ($sendCodesCnt < 1);
	my ($index) = grep { $sendCodesAr[$_] eq $sendCode } (0 .. $sendCodesCnt - 1);
	$index = -1 if (not defined($index));
	$index++;
	$index = 0 if ($index >= $sendCodesCnt);
	$sendCode = $sendCodesAr[$index];	# new sendCode

	Log3 $name, 3, "$ioname: SD_GT set $name $cmd";
	Log3 $name, 4, "$ioname: SD_GT_Set $name $cmd ($sendCodesCnt codes $sendCodesStr - send $sendCode)";

	if ($hash->{DEF} =~ /_all$/) {	# send button all
		my $systemCode = ReadingsVal($name, "SystemCode", "");
		foreach my $d (keys %defs) {	# sucht angelegte SD_GT mit gleichem Sytemcode 
			if(defined($defs{$d}) && $defs{$d}{TYPE} eq "SD_GT" && $defs{$d}{DEF} =~ /$systemCode/ && $defs{$d}{DEF} =~ /[ABCD]$/ && ReadingsVal($d, "state", "") ne $cmd) {
				readingsSingleUpdate($defs{$d}, "state" , $cmd , 1);
				Log3 $name, 3, "$ioname: SD_GT set $d $cmd";
			}
		}
	}
	
	my $msg = "P49#0x" . $sendCode . "#R4";
	Log3 $name, 5, "$ioname: $name SD_GT_Set first set sendMsg $msg";
	IOWrite($hash, 'sendMsg', $msg);
	$msg = "P49.1#0x" . $sendCode . "#R4";
	Log3 $name, 5, "$ioname: $name SD_GT_Set second set sendMsg $msg";
	IOWrite($hash, 'sendMsg', $msg);

	readingsBeginUpdate($hash);
	readingsBulkUpdate($hash, "state", $cmd);
	readingsBulkUpdate($hash, "SendCode", $sendCode, 0);
	readingsEndUpdate($hash, 1);
	return $ret;
}

sub Undef($$) {
	my ($hash, $name) = @_;
	delete($modules{SD_GT}{defptr}{$hash->{DEF}}) if(defined($hash->{DEF}) && defined($modules{SD_GT}{defptr}{$hash->{DEF}}));
	return undef;
}

sub Parse($$) {
	my ($iohash, $msg) = @_;
	my $ioname = $iohash->{NAME};
	my ($protocol,$rawData) = split("#",$msg);
	$protocol=~ s/^[P](\d+)/$1/;	# extract protocol ID, $1 = ID
	my $devicedef;
	my $version = 0;
	my $systemCode = 0;
	my $level;	# A, B, C, D or all
	my $state;
	
	my ($systemCode1, $systemCode2) = getSystemCodes($rawData);
	Log3 $ioname, 4, "$ioname: SD_GT_Parse $rawData, possible codes version 1 $systemCode1 or version 2 $systemCode2";

	# sucht Version und SytemCode in bereits angelegten SD_GT
	foreach my $d (keys %defs) {
		if(defined($defs{$d}) && $defs{$d}{TYPE} eq "SD_GT") {
			$version = ReadingsVal($d, "Version", 0) ;
			$systemCode = ReadingsVal($d, "SystemCode", 0);
			Log3 $iohash, 4, "$ioname: SD_GT_Parse found $d, version $version, systemCode $systemCode";
			last if ($systemCode1 eq $systemCode && $version == 1);
			last if ($systemCode2 eq $systemCode && $version == 2);
		}
		$version = 0;			# reset version
		$systemCode = 0;	# reset systemCode
	}
	Log3 $ioname, 4, "$ioname: SD_GT_Parse $rawData, found version $version with systemCode $systemCode";

	if ($version == 0 && $systemCode eq 0) {	# Version und systemCode nicht gefunden
		$devicedef = "LEARN";
	} else {																	# Version und systemCode gefunden
		my $statecode = substr($rawData,4,1);
		my $unit = substr($rawData,5,1);
		$state = $buttons{$version}->{$unit}->{$statecode};
		$level = $buttons{$version}->{$unit}->{"unit"};
		$devicedef = $systemCode . "_" . $level;
		Log3 $ioname, 4, "$ioname: SD_GT_Parse code $rawData, device $devicedef";
	}

	my $def = $modules{SD_GT}{defptr}{$devicedef};
	$modules{SD_GT}{defptr}{ioname} = $ioname;
	if(!$def) {
		Log3 $ioname, 1, "$ioname: SD_GT_Parse UNDEFINED SD_GT_$devicedef device detected";
		return "UNDEFINED SD_GT_$devicedef SD_GT $devicedef";
	}
	my $hash = $def;
	my $name = $hash->{NAME};
	return "" if(IsIgnored($name));
	
	my $learnCodesStr;
	my @learnCodesAr;
	my $learnCodesCnt;

	if ($devicedef eq "LEARN") {
		$learnCodesStr = ReadingsVal($name, "LearnCodes", "");
		@learnCodesAr = split(",", $learnCodesStr);
		$learnCodesCnt = scalar(@learnCodesAr);
		Log3 $name, 3, "$ioname: $name $rawData, $learnCodesCnt learned codes $learnCodesStr";
		if ($learnCodesCnt == 0) {	# erster Code empfangen
			push(@learnCodesAr,$rawData);
			$learnCodesCnt++;
			Log3 $name, 3, "$ioname: $name code $rawData is first plausible code";
		} elsif (grep /$rawData/, @learnCodesAr) {	# Code schon vorhanden
			$state = "code already registered, please press another button";
			Log3 $name, 3, "$ioname: $name code $rawData already registered ($learnCodesStr)";
		} else {	# Code pruefen und evtl. uebernehmen
			push(@learnCodesAr,$rawData);
			($version, $systemCode) = checkVersion(@learnCodesAr);
			if ($version == 0) {	# Fehler Version oder Systemcode
				if ($learnCodesCnt == 1) {
					@learnCodesAr = ();
					$systemCode = 0;
				} else {
					pop @learnCodesAr; # Wir entfernen das letzte Element des Arrays
				}
				$state = "version not unique, please press another button";
				Log3 $name, 3, "$ioname: $name ERROR - version not unique";
			} else {	# Version und Code OK
				$learnCodesCnt++;
				Log3 $name, 3, "$ioname: $name code $learnCodesCnt $rawData, version $version, systemCode $systemCode";
			}
		}
		$state = "learned code $learnCodesCnt, please press another button" if (not defined $state);
	}

	my $CodesOn;
	my $CodesOff;
	if ($state eq "on") {
		$learnCodesStr = ReadingsVal($name, "CodesOn", "");
		@learnCodesAr = split(",", $learnCodesStr);
		push(@learnCodesAr,$rawData) if (not grep /$rawData/, @learnCodesAr);
	}
	if ($state eq "off") {
		$learnCodesStr = ReadingsVal($name, "CodesOff", "");
		@learnCodesAr = split(",", $learnCodesStr);
		push(@learnCodesAr,$rawData) if (not grep /$rawData/, @learnCodesAr);
	}
	
	Log3 $name, 4, "$ioname: SD_GT_Parse code $rawData, $name, button $level $state";

	if (defined $level && $level eq "all") {	# received button all) {
		foreach my $d (keys %defs) {	# sucht angelegte SD_GT mit gleichem Sytemcode 
			if(defined($defs{$d}) && $defs{$d}{TYPE} eq "SD_GT" && $defs{$d}{DEF} =~ /$systemCode/ && $defs{$d}{DEF} =~ /[ABCD]$/ && ReadingsVal($d, "state", "") ne $state) {
				readingsSingleUpdate($defs{$d}, "state" , $state , 1);
				DoTrigger($d, undef, 0);
				Log3 $name, 4, "$ioname: SD_GT_Parse received button $level, set $d $state";
			}
		}
	}
	
	$learnCodesStr = join(",", @learnCodesAr);
	my $systemCodeDec = hex($systemCode);

	readingsBeginUpdate($hash);
	readingsBulkUpdate($hash, "state", $state);
	readingsBulkUpdate($hash, "LearnCodes", $learnCodesStr) if ($devicedef eq "LEARN");
	readingsBulkUpdate($hash, "CodesOn", $learnCodesStr, 0) if ($state eq "on");
	readingsBulkUpdate($hash, "CodesOff", $learnCodesStr, 0) if ($state eq "off");
	if ($devicedef ne "LEARN" || $learnCodesCnt > 5) {
		readingsBulkUpdate($hash, "Version", $version, 0) if ($version != 0);
		readingsBulkUpdate($hash, "SystemCode", $systemCode, 0) if ($systemCode ne 0);
		readingsBulkUpdate($hash, "SystemCodeDec", $systemCodeDec, 0) if ($systemCodeDec != 0);
	}
	readingsEndUpdate($hash, 1);
	return $name;	
}

sub parseSystemcodeHex($$) {
	my $rawData = shift;
	my $version = shift;
	my $systemCode1dec = hex(substr($rawData,0,1));
	my $systemCode2enc = hex(substr($rawData,1,1));
	my $systemCode2dec = 0;	# calculate all codes with base syscode2 = 0
	my $systemCode3enc = hex(substr($rawData,2,1));
	my $systemCode3dec = decodePayload($systemCode3enc, $systemCode2enc, $systemCode1dec, $version);
	my $systemCode4enc = hex(substr($rawData,3,1));
	my $systemCode4dec = decodePayload($systemCode4enc, $systemCode3enc, $systemCode1dec, $version);
	my $systemCode5enc = hex(substr($rawData,4,1));
	my $systemCode5dec = decodePayload($systemCode5enc, $systemCode4enc, $systemCode1dec, $version);
	my $systemCode = ($systemCode1dec<<16) + ($systemCode2dec<<12) + ($systemCode3dec<<8) + ($systemCode4dec<<4) + $systemCode5dec;
	my $systemCodeHex = sprintf("%X", $systemCode);
	return $systemCodeHex;
}

sub checkVersion(@) {
	my (@rawData) = @_;
	my $anzahl = scalar(@rawData);
	my @codes;
	my $systemCode = "";
	my $version = 1;
	for (my $x = 0; $x < $anzahl; $x++) {
		$systemCode = parseSystemcodeHex($rawData[$x], $version);
		if ( not grep /$systemCode/, @codes) {
			push(@codes,$systemCode); 	
		}
	}
	$anzahl = scalar(@codes);
	if ($anzahl > 1) {
		$version = 2;
		@codes =();
		for (my $x = 0; $x < $anzahl; $x++) {
			$systemCode = parseSystemcodeHex($rawData[$x], $version);
			if ( not grep /$systemCode/, @codes) {
				push(@codes,$systemCode); 	
			}
		}
		$anzahl = scalar(@codes);
	}
	if ($anzahl > 1) {	# keine eindeutige Version erkannt
		$version = 0;
		$systemCode = 0;
	}
	return ($version, $systemCode);
}

sub decodePayload($$$$) {
	my $payload = shift;
	my $index = shift;
	my $syscodetype = shift;
	my $version = shift;
	my $ret = -1;
	if ($version >= 1) {
		my @gt9000_hash = @{ $buttons{$version}->{"hash"} };
		$ret = int($payload) ^ int($gt9000_hash[$index]);
	}
	return $ret;
}

sub getSystemCodes($) {
	my ($rawData) = shift;
	my $systemCode1 = parseSystemcodeHex($rawData, 1);
	my $systemCode2 = parseSystemcodeHex($rawData, 2);
	return ($systemCode1, $systemCode2);
}

1;

=pod
=item device
=item summary Processing of messages from remote controls
=item summary_DE Verarbeitung der Nachrichten von Fernbedienungen

=begin html

<a name="SD_GT"></a>
<h3>SD_GT</h3>
<ul>
	The SD_GT module decodes and sends messages using the GT-9000 protocol.
	This protocol is used by a variety of remote controls, which are traded under different names.
	The messages are received and sent by a SIGNALduino.
	<br><br>
	The following models are currently known that use this protocol:
	<br><br>
	<ul>
		<li>EASY HOME RCT DS1 CR-A 3725</li>
		<li>Globaltronics GT-3000, GT-9000</li>
		<li>OBI Emil Lux / CMI Art.Nr.: 315606</li>
		<li>SilverCrest FSS B 20-A (3726) / 66538</li>
		<li>Tec Star Modell 2335191R</li>
		<li>uniTEC 48110 Funkfernschalterset (Receiver 55006x10, Transmitter: 50074)</li>
	</ul>
	<br>
	New devices are usually automatically created in FHEM via autocreate.
	Since the protocol uses encryption, manual setup is virtually impossible.
	<br><br>
	The remote control is set up in a learning process.
	After receiving at least 5 messages within 3 minutes, a new device "SD_GT_LEARN" will be created.
	Setting up the individual buttons of the remote control starts after receiving another 6 different messages.
	This learning process is signaled with the status "learned code 4, please press another button", whereby the counter displays the number of currently registered codes.
	<br>
	All buttons of the remote control must now be pressed several times.
	Upon successful decoding of the radio signals, the individual keys are created.
	<br><br>
	The programming of the remote control is finished, if all key levels (A, B, C, D and possibly all) are created and the commands "on" and "off" are displayed.
	For each device, the Readings "CodesOn" and "CodesOff" must be set up with at least one code each.
	Without these learned codes no sending is possible.
	<br>
	The device "SD_GT_LEARN" is no longer needed and can be deleted.
	<br><br>
	<p><strong>Readings:</strong></p>
	<ul>
		<li>CodesOff: one to four hexadecimal codes for "off" that have been taught and used for sending</li>
		<li>CodesOn: one to four hexadecimal codes for "on" that have been learned and used for sending</li>
		<li>SendCode: the last sent code</li>
		<li>SystemCode: System code hexadecimal, the same for all buttons on a remote control</li>
		<li>SystemCodeDec: System code in decimal representation</li>
		<li>Version: Version of the encryption used</li>
		<li>state: State, "on" or "off"</li>
	</ul>
</ul>

=end html

=begin html_DE

<a name="SD_GT"></a>
<h3>SD_GT</h3>
<ul>
	Das SD_GT-Modul dekodiert und sendet Nachrichten unter Verwendung des Protokolls vom Typ GT-9000.
	Dieses Protokoll wird von einer Vielzahl Fernbedienungen verwendet, die unter verschiedene Namen gehandelt werden.
	Die Nachrichten werden von einem SIGNALduino empfangen und gesendet.
	<br><br>
	Folgende Modelle sind zur Zeit bekannt, die dieses Protokoll verwenden:
	<br><br>
	<ul>
		<li>EASY HOME RCT DS1 CR-A 3725</li>
		<li>Globaltronics GT-3000, GT-9000</li>
		<li>OBI Emil Lux / CMI Art.Nr.: 315606</li>
		<li>SilverCrest FSS B 20-A (3726) / 66538</li>
		<li>Tec Star Modell 2335191R</li>
		<li>uniTEC 48110 Funkfernschalterset (Receiver 55006x10, Transmitter: 50074)</li>
	</ul>
	<br>
	Neue Ger&auml;te werden in FHEM normalerweise per autocreate automatisch angelegt.
	Da das Protokoll eine Verschl&uuml;sselung nutzt, ist ein manuelles Einrichten praktisch nicht m&ouml;glich.
	<br><br>
	Das Einrichten der Fernbedienung erfolgt in einem Lernprozess.
	Nach dem Empfang von mindestens 5 Nachrichten innerhalb von 3 Minuten wird ein neues Ger&auml;t "SD_GT_LEARN" angelegt.
	Das Einrichten der einzelnen Tasten der Fernbedienung beginnt nach dem Empfang weiterer 6 verschiedener Nachrichten.
	Dieser Lernprozess wird mit dem Status "learned code 4, please press another button" signalisiert, wobei der Z&auml;hler die Anzahl der aktuell registrierten Codes anzeigt.
	<br>
	Es m&uuml;ssen jetzt s&auml;mtliche Tasten der Fernbedienung mehrmals bet&auml;tigt werden.
	Bei erfolgreicher Dekodierung der Funksignale werden dabei die einzelnen Tasten angelegt.
	<br><br>
	Das Anlernen der Fernbedienung ist beendet, wenn alle Tastenebenen (A, B, C, D und evtl. all) angelegt sind und jeweils die Befehle "on" und "off" angezeigt werden.
	Bei jedem Ger&auml;t m&uuml;ssen die Readings "CodesOn" und "CodesOff" mit jeweils mindestens einem Code eingerichtet sein.
	Ohne diese gelernten Codes ist kein Senden m&ouml;glich.
	<br>
	Das Ger&auml;t "SD_GT_LEARN" wird jetzt nicht mehr ben&ouml;tigt und kann gel&ouml;scht werden.
	<br><br>
	<p><strong>Readings:</strong></p>
	<ul>
		<li>CodesOff: ein bis vier hexadezimale Codes f&uuml;r "off", die angelernt wurden und zum Senden verwendet werden</li>
		<li>CodesOn: ein bis vier hexadezimale Codes f&uuml;r "on", die angelernt wurden und zum Senden verwendet werden</li>
		<li>SendCode: der zuletzt gesendete Code</li>
		<li>SystemCode: Systemcode hexadezimal, bei allen Tasten einer Fernbedienung gleich</li>
		<li>SystemCodeDec: Systemcode in dezimaler Darstellng</li>
		<li>Version: Version der verwendeten Verschl&uuml;sselung</li>
		<li>state: Zustand, "on" oder "off"</li>
	</ul>
</ul>

=end html_DE

=cut
