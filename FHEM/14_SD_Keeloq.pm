######################################################################################################################
# $Id: 14_SD_Keeloq.pm 32 2019-08-30 12:00:00Z v3.4-dev_02.12. $
#
# The file is part of the SIGNALduino project.
# The purpose of this module is support for KeeLoq devices.
# It is an attempt to implement the project "Bastelbudenbuben" in Perl without personal testing.
# For the sake of fairness to the manufacturer, I advise every user to perform extensions at their own risk.
# The user must purchase the keys themselves.
#
# KeeLoq is a registered trademark of Microchip Technology Inc.
#
######################################################################################################################

package main;

# Laden evtl. abhängiger Perl- bzw. FHEM-Hilfsmodule
use strict;
use warnings;
use POSIX;
use Data::Dumper qw (Dumper);

my %models = (
	"JaroLift" =>	{	Button => { "up"					=>	"1000",
															"stop"				=>	"0100",	# new LearnVersion (2)
															"down"				=>	"0010",
															"learn"				=>	"0001",	# old LearnVersion
															"shade"				=>	"0100", # 20x stop	(stop with 20x repeats) mod to 15 repeats after test | old 0101
															"shade_learn"	=>	"",			# 4x stop		(stop 4x push)
															"updown"			=>	"1010"	# new LearnVersion (1)
														},
									Channel => {	1		=>	"0000",
																2		=>	"0001",
																3		=>	"0010",
																4		=>	"0011",
																5		=>	"0100",
																6		=>	"0101",
																7		=>	"0110",
																8		=>	"0111",
																9		=>	"1000",
																10	=>	"1001",
																11	=>	"1010",
																12	=>	"1011",
																13	=>	"1100",
																14	=>	"1101",
																15	=>	"1110",
																16	=>	"1111"
															},
									hex_lengh	=> "3",
									Protocol 	=> "P87",
									Typ				=> "remote"
								},

	"PR3_4207_002" => {	Button => {	"one"   =>  "0010",
																	"two"   =>  "0100",
																	"three"	=>  "1000",
																	"four"	=>  "0001"
																	},
												Protocol 	=> "P88",
												Typ				=> "remote"
											},	
	
	"RP_S1_HS_RF11" => {	Button => {	"one"			=>	"1000",
																		"two"			=>	"0010",
																		"one+two"	=>	"1010"
																	},
												Protocol 	=> "P88",
												Typ				=> "remote"
											},

	"Roto" => {	Button => {	"up"		=>	"0100",
													"down"	=>	"1001",
													"stop"	=>	"0001"
												},
							Protocol 	=> "P88",
							Typ				=> "remote"
						},

	"Waeco_MA650_TX" => {	Button => {	"blue"			=>	"0010",
																		"grey"			=>	"0100",
																		"blue+grey"	=>	"0110"
																	},
												Protocol 	=> "P88",
												Typ				=> "remote"
											},

	"unknown" =>	{	Protocol	=> "any",
									hex_lengh	=> "",
									Typ				=> "not_exist"
								}
);

my @jaro_addGroups;
my $KeeLoq_NLF;

###################################
sub SD_Keeloq_Initialize() {
  my ($hash) = @_;
  $hash->{Match}				= "^P(?:87|88)#.*";
	$hash->{DefFn}				= "SD_Keeloq::Define";
  $hash->{UndefFn}			= "SD_Keeloq::Undef";
  $hash->{AttrFn}				= "SD_Keeloq::Attr";
  $hash->{SetFn}				= "SD_Keeloq::Set";
  $hash->{ParseFn}			= "SD_Keeloq::Parse";
  $hash->{AttrList}			= "IODev MasterMSB MasterLSB KeeLoq_NLF model:".join(",", sort keys %models)." stateFormat Channels:0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16 ShowShade:0,1 ShowIcons:0,1 ShowLearn:0,1 ".
													"UI:aus,Einzeilig,Mehrzeilig ChannelFixed:1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16 ChannelNames Repeats:1,2,3,4,5,6,7,8,9 ".
													"addGroups Serial_send LearnVersion:old,new ".$readingFnAttributes;
	$hash->{FW_detailFn}	= "SD_Keeloq::summaryFn";
	$hash->{FW_addDetailToSummary}	= 1;
	$hash->{FW_deviceOverview}			= 1;
}

###################################
package SD_Keeloq;

use strict;
use warnings;
use POSIX;
use GPUtils qw(:all);  # wird für den Import der FHEM Funktionen aus der fhem.pl benötigt

## Import der FHEM Funktionen
BEGIN {
	GP_Import(qw(
		AssignIoPort
		AttrVal
		FW_ME
		FW_makeImage
		FW_subdir
		FmtDateTime
		IOWrite
		InternalVal
		Log3
		ReadingsVal
		attr
		defs
		init_done
		modules
		readingsBeginUpdate
		readingsBulkUpdate
		readingsDelete
		readingsEndUpdate
		readingsSingleUpdate
		setReadingsVal
	))
};

###################################
sub Define() {
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);

	#return "a0=$a[0] a1=$a[1] a2=$a[2] a3=$a[3]"; # for TEST

  # Argument            				   0	     1       2        3
	return "wrong syntax: define <name> SD_Keeloq <Serial> <optional IODEV>" if(int(@a) < 3 || int(@a) > 4);
	return "ERROR: your <Serial> $a[2] is wrong! Please use only hexadecimal input." if (not $a[2] =~ /^[0-9a-fA-F]{6,7}/s);

	# Users report serial numbers with 00 at the end | https://github.com/HomeAutoUser/Jaro/issues/6 | https://forum.fhem.de/index.php/topic,13596.msg962983.html#msg962983
	# return "ERROR: your <Serial> $a[2] is wrong! Please use only hexadecimal input with END 00." if (length $a[2] == 6 && not $a[2] =~ /^[0-9a-fA-F]{4}00/s);

	$hash->{STATE} = "Defined";
	my $name = $hash->{NAME};
	my $model;
	if (length $a[2] == 6) {
		$model = "JaroLift";
	} else {
		$model = "unknown";
	};
	
	my $iodevice = $a[3] if($a[3]);

	$modules{SD_Keeloq}{defptr}{$hash->{DEF}} = $hash;
	my $ioname = $modules{SD_Keeloq}{defptr}{ioname} if (exists $modules{SD_Keeloq}{defptr}{ioname} && not $iodevice);
	$iodevice = $ioname if not $iodevice;
	
	$attr{$name}{room}		= "SD_Keeloq" if ( not exists($attr{$name}{room}) );
	$attr{$name}{model}		= $model if ( not exists($attr{$name}{model}) );
	
	AssignIoPort($hash, $iodevice);
	return undef;
}

###################################
sub Attr(@) {
	my ($cmd, $name, $attrName, $attrValue) = @_;
	my $hash = $defs{$name};
	my $addGroups = AttrVal($name, "addGroups", "");
	my $MasterMSB = AttrVal($name, "MasterMSB", "");
	my $MasterLSB = AttrVal($name, "MasterLSB", "");
	my $Serial_send = AttrVal($name, "Serial_send", "");
	my $model = AttrVal($name, "model", "unknown");
	my $DDSelected = ReadingsVal($name, "DDSelected", "");

	if ($init_done == 1) {
		if ($cmd eq "set") {
			if (($attrName eq "MasterLSB" && $MasterMSB ne "") || ($attrName eq "MasterMSB" && $MasterLSB ne "")) {
					if ($Serial_send eq "") {
						readingsSingleUpdate($hash, "user_info", "messages can be received!", 1);
						readingsSingleUpdate($hash, "user_modus", "limited_functions", 1);
					} else {
						readingsSingleUpdate($hash, "user_info", "messages can be received and send!", 1);
						readingsSingleUpdate($hash, "user_modus", "all_functions", 1);
					}
			}

			### JaroLift ###
			if ($model eq "JaroLift") {
				if ($attrName eq "addGroups") {
					return "ERROR: wrong $attrName syntax!\nexample: South:1,3,5 North:2,4" if not ($attrValue =~ /^[a-zA-Z0-9_\-äÄüÜöÖ:,\s]+[^,.:\D]$/s);
					SD_Keeloq_translate($attrValue);
					$attr{$name}{addGroups} = $attrValue;
				}

				if ($attrName eq "ChannelNames") {
					return "ERROR: wrong $attrName syntax! [only a-z | umlauts | numbers | , | _ | - | ]\nexample: South,North" if not ($attrValue =~ /\A[a-zA-Z\d,_-äÄüÜöÖ\s]+\Z/s);
					SD_Keeloq_translate($attrValue);
					$attr{$name}{ChannelNames} = $attrValue;
				}

				if ($attrName eq "Channels" && $attrValue == 0 && $addGroups eq "") {
					return "ERROR: you can use Channels = $attrValue only with defined attribut addGroups!";
				}
				
				if ($attrName eq "UI" && $attrValue eq "Einzeilig" && not exists $attr{$name}{Channels} && not exists $attr{$name}{ChannelFixed}) {
					setReadingsVal($hash,"DDSelected",1,FmtDateTime(time()));
				}
				
				if ($attrName eq "ChannelFixed"&& $attrValue > $attr{$name}{Channels}) {
					return "ERROR: your $attrName attribut with value $attrValue is wrong!\nIt is no compatible with ".$attr{$name}{Channels}." channel option.";
				}
				
				if ($attrName eq "Serial_send" && $attrValue !~ /^[0-9a-fA-F]{4}00/) {
					return "ERROR: your $attrName attribut with value $attrValue is wrong!\nOnly support values with 00 at END!";
				}
			}

			### Roto | Waeco_MA650_TX###
			if ($model eq "Roto" || $model eq "Waeco_MA650_TX" || $model eq "unknown") {
				if ($attrName eq "addGroups" || $attrName eq "Channels" || $attrName eq "ChannelNames" || $attrName eq "ChannelFixed" || $attrName eq "LearnVersion" || $attrName eq "ShowIcons" || $attrName eq "ShowLearn" || $attrName eq "ShowShade") {
					return "ERROR: the attribute $attrName are not support on typ $model";
				} elsif ($attrName eq "UI") {
					return "ERROR: the attribute $attrName with the value $attrValue are not support at this moment on typ $model";
				}
			}

			### all typ´s ###
			if ($attrName eq "MasterLSB" || $attrName eq "MasterMSB" || $attrName eq "KeeLoq_NLF") {
				return "ERROR: wrong $attrName key format! [only in hex format | example: 0x23ac34de]" if not ($attrValue =~ /^0x[a-fA-F0-9]{8}+$/s);
			}

			if ($attrName eq "Serial_send") {
				if (ReadingsVal($name, "serial_receive", 0) eq $attrValue) {
					return "ERROR: your value must be different from the reading serial_receive!";
				}

				if ($MasterMSB ne "" && $MasterLSB ne "" && $attrValue ne "") {
					readingsSingleUpdate($hash, "user_info", "messages can be received and send!", 1);
					readingsSingleUpdate($hash, "user_modus", "all_functions", 1);
				}
			}

			### Check, eingegebener Sender als Device definiert?
			if ($attrName eq "IODev") {
				my @sender = ();
				foreach my $d (sort keys %defs) {
					if(defined($defs{$d}) && $defs{$d}{TYPE} eq "SIGNALduino" && $defs{$d}{DevState} eq "initialized") {
						push(@sender,$d);
					}
				}
				return "ERROR: Your $attrName is wrong!\n\nDevices to use: \n- ".join("\n- ",@sender) if (not grep /^$attrValue$/, @sender);
			}
		}

		if ($cmd eq "del") {
			if ($attrName eq "MasterLSB" || $attrName eq "MasterMSB") {
				readingsSingleUpdate($hash, "user_info", "Please input MasterMSB and MasterLSB Key!", 1);
				readingsSingleUpdate($hash, "user_modus", "only_limited_received", 1);
			}

			if ($attrName eq "Serial_send") {
				readingsSingleUpdate($hash, "user_info", "messages can be received!", 1);
				readingsSingleUpdate($hash, "user_modus", "limited_functions", 1);
			}

			if ($DDSelected ne "") {
				if ($attrName eq "Channels") {
					setReadingsVal($hash,"DDSelected",1,FmtDateTime(time()));
				}

				if ($attrName eq "UI") {
					readingsDelete($hash, "DDSelected");
				}
			} elsif ($DDSelected eq "" && $attrName eq "ChannelFixed") {
				setReadingsVal($hash,"DDSelected",1,FmtDateTime(time()));
			}

			if ($attrName eq "addGroups" && $attr{$name}{Channels} == 0) {
				$attr{$name}{Channels} = 1;
			}
		}

		Log3 $name, 3, "SD_Keeloq: $cmd attr $attrName to $attrValue" if (defined $attrValue);
		Log3 $name, 3, "SD_Keeloq: $cmd attr $attrName" if (not defined $attrValue);
	}
	return undef;
}

###################################
sub Set($$$@) {
	my ( $hash, $name, @a ) = @_;
	my $ioname = $hash->{IODev}{NAME};
	my $addGroups = AttrVal($name, "addGroups", "");
	my $Channels = AttrVal($name, "Channels", 1);
	my $ChannelFixed = AttrVal($name, "ChannelFixed", "none");
	my $MasterMSB = AttrVal($name, "MasterMSB", "");
	my $MasterLSB = AttrVal($name, "MasterLSB", "");
	$KeeLoq_NLF = AttrVal($name, "KeeLoq_NLF", "");
	my $Serial_send = AttrVal($name, "Serial_send", "");
	my $Repeats = AttrVal($name, "Repeats", "3");
	my $learning = AttrVal($name, "LearnVersion", "old");
	my $model = AttrVal($name, "model", "unknown");
	my $ret;

	my $cmd = $a[0];
	my $cmd2 = $a[1];

	### Typ JaroLift ###
	my @channel_split;
	my $channel;
	my $bit64to71;
	### together ###
	my $bit0to7;
	my $DeviceKey;			# needed for KeeLoq
	my $buttonbits;			#	Buttonbits
	my $button;					#	Buttontext


	### Einzeilig mit Auswahlfeld ###
	if ($a[0] eq "OptionValue") {
		$a[0] = $hash->{READINGS}{DDSelected}{VAL};
	}

	### only with Serial_send create setlist for user
	if ($Serial_send ne "" && $MasterMSB ne "" && $MasterLSB ne "" && $KeeLoq_NLF ne "") {
		### Typ JaroLift ###
		if ($model eq "JaroLift") {
			### only all options without ChannelFixed ###
			if ($ChannelFixed eq "none") {
				my $ret_part2;
				## for addGroups if no Channels
				if ($addGroups ne "") {
					@jaro_addGroups = split / /, $addGroups;
					foreach (@jaro_addGroups){
						$_ =~ s/:\d.*//g;
						$ret_part2.= "$_,";
					}
				}

				foreach my $rownr (1..$Channels) {
					$ret_part2.= "$rownr,";
				}

				$ret_part2 = substr($ret_part2,0,-1);		# cut last ,
				foreach (keys %{$models{$model}{Button}}) {
					$ret.=" $_:multiple,".$ret_part2;
				}
			} else {
				foreach (keys %{$models{$model}{Button}}) {
					$ret.=" $_:$ChannelFixed";
				}
			}
		### Typ PR3_4207_002 | RP_S1_HS_RF11 | Roto | Waeco_MA650_TX ###
		} elsif ($model eq "PR3_4207_002" || $model eq "RP_S1_HS_RF11" || $model eq "Roto" || $model eq "Waeco_MA650_TX") {
			foreach (keys %{$models{$model}{Button}}) {
				$ret.=" $_:noArg";
			}
		}
	}

	return $ret if ( $a[0] eq "?");

	### Typ JaroLift ###
	if ($model eq "JaroLift") {
		return "ERROR: no set value specified!" if(int(@a) <= 1);
		return "ERROR: too much set value specified!" if(int(@a) > 2);

		@channel_split = split(",", $cmd2);

		if (scalar @channel_split == 1) {
			if ($cmd2 =~ /^\d$/ && ($cmd2 < 1 || $cmd2 > 16) ) {
				return "ERROR: your channel $cmd2 is not support! (not in list - failed 1)";
			}
		} elsif (scalar @channel_split > 1) {
			foreach (@channel_split){
				if ($_ !~ /^\d/) {
					if ( not grep( /$_/, $addGroups)) {
						return "ERROR: one channel $cmd2 is not support! (not in list - failed 2)";
					}
				} else {
					return "ERROR: your channels $cmd2 are not support! (not in list - failed 3)" if ($_<1 && $_>16);			
				}
			}
		}
	### Typ PR3_4207_002 || RP_S1_HS_RF11 | Roto | Waeco_MA650_TX ###
	} elsif ($model eq "PR3_4207_002" || $model eq "RP_S1_HS_RF11" || $model eq "Roto" || $model eq "Waeco_MA650_TX") {
		return "ERROR: no set value specified!" if(int(@a) != 1);
	}

	return "ERROR: no value, set Attributes MasterMSB please!" if ($MasterMSB eq "");
	return "ERROR: no value, set Attributes MasterLSB please!" if ($MasterLSB eq "");
	return "ERROR: no value, set Attributes KeeLoq_NLF please!" if ($KeeLoq_NLF eq "");
	return "ERROR: no value, set Attributes Serial_send please!" if($Serial_send eq "");

	if ($cmd ne "?") {
		if ($model eq "JaroLift") {
			return "ERROR: your device is under development!" if ($model eq "Roto");
			return "ERROR: you have no I/O DEV defined! Please define one device to send or dummy." if (AttrVal($name, "IODev", "") eq "");
			Log3 $name, 4, "######## DEBUG SET - START ########";
			Log3 $name, 4, "$ioname: SD_Keeloq_Set - cmd=$cmd cmd2=$cmd2 args cmd2=".scalar @channel_split." addGroups=$addGroups" if ($cmd ne "?" && defined $cmd2);

			my @channels;
			my @channel_from_addGroups;
			my $foreachCount;

			if ($learning ne "old" && $cmd eq "learn") {
				$foreachCount = 2;	# LearnVersion new
			} else {
				$foreachCount = 1;	# LearnVersion old
			}

			if ($cmd eq "shade_learn") {
				$foreachCount = 4;
				$cmd = "stop";
			}

			foreach my $i (1..$foreachCount) {
				Log3 $name, 4, "$ioname: SD_Keeloq_Set - check, foreachCount=$foreachCount cmd=$cmd";
				## LearnVersion new - part 1
				if ($learning ne "old" && $cmd eq "learn" && $i == 1) {
					$cmd = "updown";
				## LearnVersion new - part 2
				} elsif ($learning ne "old" && $cmd eq "updown" && $i == 2) {
					$cmd = "stop";
					$bit0to7 = undef;
					$bit64to71 = undef;
					$DeviceKey = undef;
					$Serial_send = AttrVal($name, "Serial_send", "");
				## shade_learn ##
				} elsif ($cmd eq "stop" && $i >= 2) {
					$bit0to7 = undef;
					$bit64to71 = undef;
					$DeviceKey = undef;
					$Serial_send = AttrVal($name, "Serial_send", "");
				}

				$button = $cmd;
				$buttonbits = $models{$model}{Button}{$cmd};
				Log3 $name, 4, "$ioname: SD_Keeloq_Set - check, foreachLoop=$i LearnVersion=$learning" if ((defined $cmd2 && $learning eq "old") || (defined $cmd2 && $learning eq "new"));

				if ($addGroups ne "") {
					@channel_from_addGroups = split(" ", $addGroups);
					foreach my $found (@channel_from_addGroups){
						if ($found =~ /^$cmd2:/) {
							Log3 $name, 4, "$ioname: SD_Keeloq_Set - check, group for setlist -> found $cmd2 in addGroups";
							$found =~ s/$cmd2\://g;
							@channels = split(",", $found);
							$channel = $channels[0];
							last;
						}
					}
				}

				return "ERROR: command $cmd is not support!\n\ncommands are: ".join(" | ", sort keys %{$models{$model}{Button}}) if (not grep { /$cmd/ } keys %{$models{$model}{Button}});
				if ($cmd2 =~ /^\d$/) {
					return "ERROR: channel $cmd2 is not activated! you have activated $Channels Channels." if ($cmd2 > $Channels);
				}

				#### CHECK cmd ####
				### multi control ###
				if ( grep( /,/, $cmd2 ) ) {
					Log3 $name, 4, "$ioname: SD_Keeloq_Set - check, multiple selection: yes";
					my @multicontrol = split(",", $cmd2);
					foreach my $found_multi (@multicontrol){
						## channel ##
						if ($found_multi =~ /^\d+$/) {
							Log3 $name, 4, "$ioname: SD_Keeloq_Set - selection $found_multi is channel solo";
							push(@channels,$found_multi);
							$channel = $multicontrol[0];
						## group ##
						} elsif (grep /$found_multi/, @channel_from_addGroups) {
							Log3 $name, 4, "$ioname: SD_Keeloq_Set - selection $found_multi is group solo";
							foreach my $found (@channel_from_addGroups) {
								if ($found =~ /^$found_multi:/) {
									Log3 $name, 4, "$ioname: SD_Keeloq_Set - check, group for setlist -> found $found_multi in addGroups";
									$found =~ s/$found_multi\://g;
									@channels = split(",", $found);
									$channel = $channels[0];
									last;
								}
							}
						}
					}
				### single control ###
				} else {
					Log3 $name, 4, "$ioname: SD_Keeloq_Set - check, multiple selection: no";
					if ($cmd2 !~ /^\d{1,2}$/) {
						## single group ##
						if ( not grep( /$cmd2/, $addGroups ) ) {
							return "ERROR: $cmd2 is not support!";
						}
						if ( grep( /$cmd2:/, $addGroups ) ) {
							Log3 $name, 4, "$ioname: SD_Keeloq_Set - no numerics";
						}
					## single channel ##
					} else {
						@channels = split /,/, $cmd2;
						$channel = $channels[0];
					}
				}
				Log3 $name, 4, "$ioname: SD_Keeloq_Set - channel via setlist       => button=$button buttonbits=$buttonbits channel=$channel";
				#### CHECK cmd END ####

				### create channelpart1
				foreach my $nr (1..8) {
					if ( grep( /^$nr$/, @channels ) ) {
						$bit0to7.="1";
					} else {
						$bit0to7.="0";
					}
					Log3 $name, 5, "$ioname: SD_Keeloq_Set - create channelpart1 ".sprintf("%02d", $nr)." $bit0to7";
				}

				### create channelpart2
				foreach my $nr (9..16) {
					if ( grep( /^$nr$/, @channels ) ) {
						$bit64to71.="1";
					} else {
						$bit64to71.="0";
					}
					Log3 $name, 5, "$ioname: SD_Keeloq_Set - create channelpart2 ".sprintf("%02d", $nr)." $bit64to71";
				}

				$bit0to7 = reverse $bit0to7;
				$bit64to71 = reverse $bit64to71;		# JaroLift only

				### DeviceKey (die ersten Stellen aus der Vorage, der Rest vom Sendenen Kanal)
				$Serial_send = sprintf ("%24b", hex($Serial_send));																				# verified

				$DeviceKey = $Serial_send.$models{$model}{Channel}{$channel};															# verified
				$DeviceKey = oct("0b".$DeviceKey);																												# verified

				######## KEYGEN #############
				my $counter_send = ReadingsVal($name, "counter_send", 0);
				$counter_send++;
				my $keylow = $DeviceKey | 0x20000000;
				my $device_key_lsb = SD_Keeloq_decrypt($keylow, hex($MasterMSB), hex($MasterLSB),$name);	# verified
				$keylow = $DeviceKey | 0x60000000;
				my $device_key_msb = SD_Keeloq_decrypt($keylow, hex($MasterMSB), hex($MasterLSB),$name);	# verified

				### KEELOQ
				my $disc = $bit0to7."0000".$models{$model}{Channel}{$channel};	# Hopcode									# verified

				my $result = (SD_Keeloq_bin2dec($disc) << 16) | $counter_send;														# verified
				my $encoded = SD_Keeloq_encrypt($result, $device_key_msb, $device_key_lsb,$name);					# verified

				### Zusammenführen
				my $bits = reverse (sprintf("%032b", $encoded)).reverse($models{$model}{Channel}{$channel}).reverse($Serial_send).reverse($buttonbits).reverse($bit64to71);
				$Repeats = 15 if ($cmd eq "shade");			# special, command shade = 20 repeats = 2,34 s / 15 = 1,75s / userreport: 12 repeats ok
				my $msg = "P87#$bits"."P#R".$Repeats;

				Log3 $name, 5, "$ioname: SD_Keeloq_Set - Channel                   = $channel";
				Log3 $name, 5, "$ioname: SD_Keeloq_Set - Channelpart1 (Group 0-7)  = $bit0to7";
				Log3 $name, 5, "$ioname: SD_Keeloq_Set - Channelpart2 (Group 8-15) = $bit64to71";
				Log3 $name, 5, "$ioname: SD_Keeloq_Set - Button                    = $button";
				Log3 $name, 5, "$ioname: SD_Keeloq_Set - Button_bits               = $buttonbits";
				Log3 $name, 5, "$ioname: SD_Keeloq_Set - DeviceKey                 = $DeviceKey";
				Log3 $name, 5, "$ioname: SD_Keeloq_Set - Device_key_lsb            = $device_key_lsb";
				Log3 $name, 5, "$ioname: SD_Keeloq_Set - Device_key_msb            = $device_key_msb";
				Log3 $name, 5, "$ioname: SD_Keeloq_Set - disc                      = $disc";
				Log3 $name, 5, "$ioname: SD_Keeloq_Set - result (decode)           = $result";
				Log3 $name, 5, "$ioname: SD_Keeloq_Set - Counter                   = $counter_send";
				Log3 $name, 5, "$ioname: SD_Keeloq_Set - encoded (encrypt)         = ".sprintf("%032b", $encoded)."\n";

				my $binsplit = SD_Keeloq_binsplit_JaroLift($bits);

				Log3 $name, 5, "$ioname: SD_Keeloq_Set                                           encoded     <- | ->     decrypts";
				Log3 $name, 5, "$ioname: SD_Keeloq_Set                       Grp 0-7 |digitS/N|      counter    | ch |          serial        | bt |Grp 8-15";
				Log3 $name, 5, "$ioname: SD_Keeloq_Set - bits (send split) = $binsplit";
				Log3 $name, 5, "$ioname: SD_Keeloq_Set - bits (send)       = $bits";
				Log3 $name, 4, "$ioname: SD_Keeloq_Set - sendMSG           = $msg";
				Log3 $name, 4, "######## DEBUG SET - END ########";

				IOWrite($hash, 'sendMsg', $msg);
				Log3 $name, 3, "$ioname: $name set $cmd $cmd2";

				readingsBeginUpdate($hash);
				readingsBulkUpdate($hash, "button", $button, 1);
				readingsBulkUpdate($hash, "channel", $channel, 1);
				readingsBulkUpdate($hash, "counter_send", $counter_send, 1);
				readingsBulkUpdate($hash, "state", "send $button", 1);

				my $group_value;
				foreach (@channels) {
					readingsBulkUpdate($hash, "LastAction_Channel_".sprintf ("%02s",$_), $button);
					$group_value.= $_.",";
				}

				$group_value = substr($group_value,0,length($group_value)-1);
				$group_value = "no" if (scalar @channels == 1);

				readingsBulkUpdate($hash, "channel_control", $group_value);
				readingsEndUpdate($hash, 1);
			}
		} else {
			return "ERROR: the function are in development!"
		}
	}
}

###################################
sub Parse($$) {
	my ($iohash, $msg) = @_;
	my $ioname = $iohash->{NAME};
	my ($protocol,$rawData) = split("#",$msg);
	$protocol=~ s/^P(\d+)/$1/; 										# extract protocol
	my $hlen = length($rawData);
	my $blen = $hlen * 4;
	my $bitData = unpack("B$blen", pack("H$hlen", $rawData));

	my $encrypted = 1;
	my $info = "Please input KeeLoq_NLF, MasterMSB and MasterLSB Key!";
	my $state;

	## JAROLIFT ##
	## CD287247200065F100 ##
	## 110011010010100001110010010001110010000000000000011001011111000100000000 ##
	#
	# 8 bit grouping channel 0-7
	# 8 bit two last digits of S/N transmitted
	# 16 bit countervalue
	####################### 32bit encrypted
	# 28 bit serial
	# 4 bit button
	# 8 bit for grouping 8-16
	####################### 40bit

  # Kanal  S/N           DiscGroup_8-16             DiscGroup_1-8     SN(last two digits)
  # 0       0            0000 0000                   0000 0001           0000 0000
  # 1       1            0000 0000                   0000 0010           0000 0001
  # 2       2            0000 0000                   0000 0100           0000 0010
  # 3       3            0000 0000                   0000 1000           0000 0011
  # 4       4            0000 0000                   0001 0000           0000 0100
  # 5       5            0000 0000                   0010 0000           0000 0101
  # 6       6            0000 0000                   0100 0000           0000 0110
  # 7       7            0000 0000                   1000 0000           0000 0111
  # 8       8            0000 0001                   0000 0000           0000 0111
  # 9       9            0000 0010                   0000 0000           0000 0111
  # 10      10           0000 0100                   0000 0000           0000 0111
  # 11      11           0000 1000                   0000 0000           0000 0111
  # 12      12           0001 0000                   0000 0000           0000 0111
  # 13      13           0010 0000                   0000 0000           0000 0111
  # 14      14           0100 0000                   0000 0000           0000 0111
  # 15      15           1000 0000                   0000 0000           0000 0111

	# button = 0x0; // 1000=0x8 up, 0100=0x4 stop, 0010=0x2 down, 0001=0x1 learning, 0011=0x3 shade, 0110=0x6 shade_learn, 1010=0xA updown
	# !!! There are supposedly 2 versions of the protocol? old and new !!!

	# http://www.bastelbudenbuben.de/2017/04/25/protokollanalyse-von-jarolift-tdef-motoren/
	# https://github.com/madmartin/Jarolift_MQTT/wiki/About-Serials

	################################################################################################

	## PR3_4207_002 | RP_S1_HS_RF11 | Roto | Waeco_MA650_TX ##
	## D13E68A890EAFEF20 ##
	## 11010001001111100110100010101000100100001110101011111110111100100000 ##
	#
	# 16 bit Sync Counter
	# 12 bit Discrimination
	# 4 bit Button
	####################### 32bit encrypted
	# 28 bit serial
	# 4 bit button
	# 1 bit VLOW: Voltage LOW indicator
	# 1 bit RPT: Repeat indicator
	# 2 bit Padding
	####################### 34bit

	my $serialWithoutCh;
	my $model = "unknown";
	my $devicedef;
	
	if ($hlen == 17) {
		$model = "unknown";
		$serialWithoutCh = reverse (substr ($bitData , 32 , 28));						# 28bit serial
		$serialWithoutCh = sprintf ("%07s", sprintf ("%X", oct( "0b$serialWithoutCh" )));
		$devicedef = $serialWithoutCh;
	} elsif ($hlen == 18) {
		$model = "JaroLift";
		$serialWithoutCh = reverse (substr ($bitData , 36 , 24));						# 24bit serial without last 4 bit ### Serial without last nibble, fix at device at every channel
		$serialWithoutCh = sprintf ("%06s", sprintf ("%X", oct( "0b$serialWithoutCh" )));
		$devicedef = $serialWithoutCh;
	} else {
		Log3 $iohash, 4, "$ioname: SD_Keeloq_Parse Unknown device with wrong length of $hlen! (rawData=$rawData)";
		return "";
	}

	$modules{SD_Keeloq}{defptr}{ioname} = $ioname;
	my $def = $modules{SD_Keeloq}{defptr}{$devicedef};

	if(!$def) {
		Log3 $iohash, 2, "$ioname: SD_Keeloq_Parse Unknown device $model with Code $devicedef detected, please define (rawdate=$rawData)";
		return "UNDEFINED SD_Keeloq_".$serialWithoutCh." SD_Keeloq ".$devicedef;
	}

	my $hash = $def;
	my $name = $hash->{NAME};
	my $MasterMSB = AttrVal($name, "MasterMSB", "");
	my $MasterLSB = AttrVal($name, "MasterLSB", "");
	$KeeLoq_NLF = AttrVal($name, "KeeLoq_NLF", "");
	my $UI = AttrVal($name, "UI", "Mehrzeilig");
	$model = AttrVal($name, "model", "unknown");

	$hash->{lastMSG} = $rawData;
	$hash->{bitMSG} = $bitData;

	if ($MasterMSB ne "" && $MasterLSB ne "" && $KeeLoq_NLF ne "") {
		$encrypted = 0;
		$info = "none";
	}

	Log3 $name, 4, "$ioname: SD_Keeloq_Parse device $model with rawData=$rawData, hlen=$hlen";

	### JaroLift only ###
	my $bit0to7;
	my $bit8to15;
	my $bit64to71;
	my $group_value;
	my $group_value8_15;
	my $channel;
	my $channel_bin;

	### PR3_4207_002 | RP_S1_HS_RF11 | Roto | Waeco_MA650_TX only ###
	my $bit0to15;
	my $bit16to27;
	my $bit28to31;
	my $VLOW;
	my $RPT;

	## together ##
	my $buttonbits;
	my $binsplit;
	my ($counter) = @_ = ( reverse (substr ($bitData , 16 , 16)) , "encrypted" )[$encrypted];		# without MasterMSB | MasterLSB encrypted
	my ($modus) = @_ = ( "all_functions" , "only_limited" )[$encrypted];												# modus read for user

	my $serial = reverse (substr ($bitData , 32 , 28));																					# 28bit serial
	my $button = reverse (substr ($bitData , 60 , 4));																					# 4bit button same JaroLift & Roto

	Log3 $name, 5, "######## DEBUG PARSE - START ########";

	if (AttrVal($name, "verbose", "5") == 5) {
		if (defined $hash->{LASTInputDev}) {
			my $LASTInputDev = $hash->{LASTInputDev};
			my $RAWMSG_Internal = $LASTInputDev."_RAWMSG";
			Log3 $name, 5, "$ioname: SD_Keeloq_Parse - RAWMSG = ".$hash->{$RAWMSG_Internal};
		}
		Log3 $name, 5, "$ioname: SD_Keeloq_Parse - bitData = $bitData\n";
	}

	### JaroLift ###
	if($model eq "JaroLift") {
		($bit0to7) = @_ = ( reverse (substr ($bitData , 0 , 8)) , "encrypted" )[$encrypted];			# without MasterMSB | MasterLSB encrypted
		($bit8to15) = @_ = ( reverse (substr ($bitData , 8 , 8)) , "encrypted" )[$encrypted];			# without MasterMSB | MasterLSB encrypted
		$bit64to71 = reverse (substr ($bitData , 64 , 8));

		$binsplit = SD_Keeloq_binsplit_JaroLift($bitData);

		Log3 $name, 5, "$ioname: SD_Keeloq_Parse - typ = $model";
		Log3 $name, 5, "$ioname: SD_Keeloq_Parse                                 encoded     <- | ->     decrypts";
		Log3 $name, 5, "$ioname: SD_Keeloq_Parse             Grp 0-7 |digitS/N|      counter    | ch |          serial        | bt |Grp 8-15";
		Log3 $name, 5, "$ioname: SD_Keeloq_Parse - bitData = $binsplit";
		Log3 $name, 5, "$ioname: SD_Keeloq_Parse - bitData = |->     must be calculated!     <-| ".reverse (substr ($bitData , 32 , 4)) ." ". reverse (substr ($bitData , 36 , 24)) ." ".$button ." ". $bit64to71;

		my @groups8_15 = split //, reverse $bit64to71;
		foreach my $i (0..7) {																						# group - ch8-ch15
			if ($groups8_15[$i] eq 1) {
				$group_value.= ($i+9).",";
			}
		}

		$group_value8_15 = ($bit64to71 =~ s/(0)/$1/g);										# count 0
		if ($group_value8_15 == 8) {
			$group_value = "< 9";
		}
		$group_value = substr($group_value,0,-1) if ($group_value =~ /,$/);		# cut last ,
		Log3 $name, 5, "$ioname: SD_Keeloq_Parse - group_value_text 8-15 (1)            = $group_value\n";

		($button) = grep { $models{$model}{Button}{$_} eq $button } keys %{$models{$model}{Button}};			# search buttontext --> buttons
		$channel = reverse (substr ($bitData , 32 , 4));
		($channel) = grep { $models{$model}{Channel}{$_} eq $channel } keys %{$models{$model}{Channel}};	# search channeltext --> channels

		foreach my $keys (keys %{$models{$model}{Channel}}) {																							# search channel bits --> channels
			$channel_bin = $models{$model}{Channel}{$keys} if ($keys eq $channel);
		}
	### PR3_4207_002 | RP_S1_HS_RF11 | Roto | Waeco_MA650_TX ###
	} elsif ($model eq "PR3_4207_002" || $model eq "RP_S1_HS_RF11" || $model eq "Roto" || $model eq "Waeco_MA650_TX") {
		$VLOW = substr ($bitData , 64 , 1);
		$RPT = substr ($bitData , 65 , 1);

		my $binsplit = SD_Keeloq_binsplit_Roto($bitData);

		Log3 $name, 5, "$ioname: SD_Keeloq_Parse - typ = $model";
		Log3 $name, 5, "$ioname: SD_Keeloq_Parse                                encoded     <- | ->     decrypts";
		Log3 $name, 5, "$ioname: SD_Keeloq_Parse                sync counter |discriminat.| bt |           serial           | bt |V|R|padding";
		Log3 $name, 5, "$ioname: SD_Keeloq_Parse - bitData = $binsplit";
		Log3 $name, 5, "$ioname: SD_Keeloq_Parse - bitData = |->     must be calculated!    <-| ". $serial ." ".$button ." ". $VLOW ." ". $RPT."\n";

		$buttonbits = $button;
		($button) = grep { $models{$model}{Button}{$_} eq $button } keys %{$models{$model}{Button}};					# search buttontext --> buttons
		$bit0to15 = reverse (substr ($bitData , 0 , 16));
		$bit16to27 = reverse (substr ($bitData , 16 , 12));
		$bit28to31 = reverse (substr ($bitData , 28 , 4));
	}

	$serial = oct( "0b$serial" ); ## need to DECODE & view Debug 

	my $counter_decr;
	my $channel_decr;
	my $bit0to7_decr;
	my $Decoded;

	###### DECODE ######
	if ($encrypted == 0) {
		Log3 $name, 5, "######## DEBUG PARSE - for LSB & MSB Keys ########";

		### Hopcode
		my $Hopcode;
		if ($model eq "JaroLift") {
			$Hopcode = $bit0to7.$bit8to15.$counter;		
		} elsif ($model ne "JaroLift" && $model ne "unknown") {
			$Hopcode = $bit0to15.$bit16to27.$bit28to31;		
		}

		$Hopcode = reverse $Hopcode;																									# invert
		Log3 $name, 5, "$ioname: SD_Keeloq_Parse - input to decode                      = $Hopcode";
		my $Hopcode_decr = SD_Keeloq_bin2dec($Hopcode);
		Log3 $name, 5, "$ioname: SD_Keeloq_Parse - HopCode - decrypts                   = $Hopcode_decr";

		my $keylow = $serial | 0x20000000;
		Log3 $name, 5, "$ioname: SD_Keeloq_Parse - decrypts (1)                         = $keylow";

		my $rx_device_key_lsb = SD_Keeloq_decrypt($keylow, hex($MasterMSB), hex($MasterLSB), $name);
		$keylow =  $serial | 0x60000000;
		Log3 $name, 5, "$ioname: SD_Keeloq_Parse - decrypts (2)                         = $keylow";

		my $rx_device_key_msb = SD_Keeloq_decrypt($keylow, hex($MasterMSB), hex($MasterLSB),$name);
		Log3 $name, 5, "$ioname: SD_Keeloq_Parse - rx_device_key_lsb                    = $rx_device_key_lsb";
		Log3 $name, 5, "$ioname: SD_Keeloq_Parse - rx_device_key_msb                    = $rx_device_key_msb";

		$Decoded = SD_Keeloq_decrypt($Hopcode_decr, $rx_device_key_msb, $rx_device_key_lsb,$name);
		Log3 $name, 5, "$ioname: SD_Keeloq_Parse - Decoded (HopCode,MSB,LSB)            = $Decoded";
		$Decoded = SD_Keeloq_dec2bin($Decoded);
		Log3 $name, 5, "$ioname: SD_Keeloq_Parse - Decoded (bin)                        = $Decoded\n";

		if ($model eq "JaroLift") {
			my $Decoded_split;
			for my $i(0..31){
				$Decoded_split.= substr($Decoded,$i,1);
				if (($i+1) % 8 == 0 && $i < 17) {
					$Decoded_split.= " ";
				}
			}

			### Disc Group 1-8
			$bit0to7_decr = substr($Decoded, 0, 8);
			$bit0to7 = $bit0to7_decr;

			### Counter
			$counter = substr($Decoded, 16, 16);
			$counter_decr = SD_Keeloq_bin2dec($counter);

			my $group_value0_7 = "";
			my @groups0_7 = split //, reverse $bit0to7;
			foreach my $i (0..7) {																																												# group - ch0-ch7
				if ($groups0_7[$i] eq 1) {
					$group_value0_7.= ($i+1).",";
				}
			}

			$group_value = "" if($group_value8_15 == 8 && $group_value0_7 ne "");																					# group reset text " < 9"
			$group_value = "16" if($group_value8_15 == 8 && $group_value0_7 eq "");																				# group text "16"
			$group_value0_7 = substr($group_value0_7,0,-1) if ($group_value0_7 =~ /,$/ && $group_value0_7 ne "");					# cut last ,

			$group_value = $group_value0_7.",".$group_value;																															# put together part1 with part2
			$group_value = substr($group_value,1,length($group_value)-1) if ($group_value =~ /^,/);												# cut first ,
			$group_value = substr($group_value,0,-1) if ($group_value =~ /,$/);																						# cut last ,
			$group_value = "no" if ($group_value =~ /^\d+$/);																															# no group, only one channel

			### ChannelDecrypted
			$channel_decr = substr($Decoded, 12, 4);
			($channel_decr) = grep { $models{$model}{Channel}{$_} eq $channel_decr } keys %{$models{$model}{Channel}};		# search channels
			$bit8to15 = $channel_decr;		

			Log3 $name, 5, "$ioname: SD_Keeloq_Parse                                          Grp 0-7 |digitS/N|    counter";
			Log3 $name, 5, "$ioname: SD_Keeloq_Parse - Decoded (bin split)                  = $Decoded_split\n";
			Log3 $name, 5, "######## DEBUG only with LSB & MSB Keys ########";
			Log3 $name, 5, "$ioname: SD_Keeloq_Parse - channelpart1 (group 0-7)             = $bit0to7";
			Log3 $name, 5, "$ioname: SD_Keeloq_Parse - group_value_text 0-7  (2)            = $group_value0_7";
			Log3 $name, 5, "$ioname: SD_Keeloq_Parse - group_value_text 0-15 (3)            = $group_value";
			Log3 $name, 5, "$ioname: SD_Keeloq_Parse - last_digits (bin)                    = ".substr($Decoded, 8, 8)." (only 4 bits ".substr($Decoded, 12, 4)." = decrypts ch reversed ".reverse (substr ($bitData , 32 , 4)).")";
			Log3 $name, 5, "$ioname: SD_Keeloq_Parse - last_digits (channel from encoding)  = $bit8to15";
			Log3 $name, 5, "$ioname: SD_Keeloq_Parse - countervalue (receive)               = $counter_decr\n";

			if ($group_value eq "no") {
				$state = "receive $button on single control"
			} elsif ($group_value eq "< 9") {
				$state = "receive $button on single control or group control"
			} else {
				$state = "receive $button group control"
			}
		}

		if ($model ne "JaroLift" && $model ne "unknown") {
			my $Decoded_split;
			for my $i(0..31){
				$Decoded_split.= substr($Decoded,$i,1);
				if ($i == 15 || $i == 27) {
					$Decoded_split.= " ";
				}
			}

			my $bit0to15_decr = substr($Decoded, 0, 16);
			my $bit16to27_decr = substr($Decoded, 16, 12);
			my $bit28to31_decr = substr($Decoded, 28, 4);
			$counter_decr = SD_Keeloq_bin2dec($bit0to15_decr);

			Log3 $name, 5, "$ioname: SD_Keeloq_Parse                                             sync counter |discriminat.| bt";
			Log3 $name, 5, "$ioname: SD_Keeloq_Parse - Decoded (bin split)                  = $Decoded_split\n";
			Log3 $name, 5, "######## DEBUG only with LSB & MSB Keys ########";
			Log3 $name, 5, "$ioname: SD_Keeloq_Parse - sync counter (bits)	                = $bit0to15_decr";
			Log3 $name, 5, "$ioname: SD_Keeloq_Parse - sync counter (dez) 	                = $counter_decr";
			Log3 $name, 5, "$ioname: SD_Keeloq_Parse - discrimination                       = $bit16to27_decr";
			Log3 $name, 5, "$ioname: SD_Keeloq_Parse - button (in encoded part)             = $bit28to31_decr = $buttonbits ???";

			$state = "receive $button"
		}
	} else {
		$state = "receive";
		$state = "Please change your model via attribut!" if ($model eq "unknown");
	}
	###### DECODE END ######

	Log3 $name, 5, "######## DEBUG without LSB & MSB Keys ########";
	Log3 $name, 5, "$ioname: SD_Keeloq_Parse - decrypts button                      = $button";
	Log3 $name, 5, "$ioname: SD_Keeloq_Parse - decrypts ch + serial                 = $serial (at each channel changes)" if ($model eq "JaroLift");
	Log3 $name, 5, "$ioname: SD_Keeloq_Parse - decrypts ch + serial (bin)           = ".sprintf("%028b", $serial) if ($model eq "JaroLift");
	Log3 $name, 5, "$ioname: SD_Keeloq_Parse - decrypts serial (hex)                = $serialWithoutCh (for each channel)";
	Log3 $name, 5, "$ioname: SD_Keeloq_Parse - decrypts serial (bin)                = ".sprintf("%b", hex($serialWithoutCh))." (for each channel)";
	Log3 $name, 5, "$ioname: SD_Keeloq_Parse - decrypts channel (from serial | bin) = $channel_bin" if (defined $channel_bin);	# JaroLift
	Log3 $name, 5, "$ioname: SD_Keeloq_Parse - decrypts channel (from serial)       = $channel" if (defined $channel);					# JaroLift
	Log3 $name, 5, "$ioname: SD_Keeloq_Parse - decrypts channelpart2 (group 8-15)   = $bit64to71" if (defined $bit64to71);			# JaroLift
	Log3 $name, 5, "$ioname: SD_Keeloq_Parse - decrypts channel_control             = $group_value" if (defined $group_value);	# JaroLift
	Log3 $name, 5, "$ioname: SD_Keeloq_Parse - decrypts Voltage LOW indicator       = $VLOW" if (defined $VLOW);								# RP_S1_HS_RF11 | Roto | Waeco_MA650_TX
	Log3 $name, 5, "$ioname: SD_Keeloq_Parse - decrypts Repeat indicator            = $RPT" if (defined $RPT);									# RP_S1_HS_RF11 | Roto | Waeco_MA650_TX
	Log3 $name, 5, "$ioname: SD_Keeloq_Parse - user_modus                           = $modus";
	Log3 $name, 5, "$ioname: SD_Keeloq_Parse - user_info                            = $info";
	Log3 $name, 5, "######## DEBUG END ########\n";
	
	$VLOW = $VLOW eq "0" ? "ok" : "low" if (defined $VLOW);		# only chip HCS301 - RP_S1_HS_RF11 | Roto | Waeco_MA650_TX
	$RPT = $RPT eq "0" ? "no" : "yes" if (defined $RPT);			# only chip HCS301 - RP_S1_HS_RF11 | Roto | Waeco_MA650_TX

	readingsBeginUpdate($hash);
	readingsBulkUpdate($hash, "button", $button);
	readingsBulkUpdate($hash, "channel", $channel);
	readingsBulkUpdate($hash, "DDSelected", "ch".$channel) if ($UI eq "Einzeilig");					# to jump receive value in combobox if a other value select before receive
	readingsBulkUpdate($hash, "channel_control", $group_value) if (defined $group_value);		# JaroLift
	readingsBulkUpdate($hash, "counter_receive", $counter_decr) if (defined $counter_decr);
	readingsBulkUpdate($hash, "last_digits", $bit8to15) if (defined $bit8to15);							# JaroLift
	readingsBulkUpdate($hash, "repeat_message", $RPT) if (defined $RPT);										# RP_S1_HS_RF11 | Roto | Waeco_MA650_TX
	readingsBulkUpdate($hash, "batteryState", $VLOW) if (defined $VLOW);										# RP_S1_HS_RF11 | Roto | Waeco_MA650_TX
	readingsBulkUpdate($hash, "serial_receive", $serialWithoutCh, 0);
	readingsBulkUpdate($hash, "state", $state);
	readingsBulkUpdate($hash, "user_modus", $modus);
	readingsBulkUpdate($hash, "user_info", $info);

	if ($model eq "JaroLift") {
		readingsBulkUpdate($hash, "LastAction_Channel_".sprintf ("%02s",$channel), $button) if ($group_value eq "no");
		if ($group_value ne "no" && $group_value ne "< 9") {
			my @group_value = split /,/, $group_value;
			foreach (@group_value) {
				readingsBulkUpdate($hash, "LastAction_Channel_".sprintf ("%02s",$_), $button);
			}
		}
	}
	readingsEndUpdate($hash, 1);

	return $name;
}

#####################################
sub Undef($$) {
	my ($hash, $name) = @_;
	delete($modules{SD_Keeloq}{defptr}{$hash->{DEF}}) if(defined($hash->{DEF}) && defined($modules{SD_Keeloq}{defptr}{$hash->{DEF}}));
	delete($modules{SD_Keeloq}{defptr}{ioname}) if (exists $modules{SD_Keeloq}{defptr}{ioname});
	return undef;
}

###################################
sub SD_Keeloq_bin2dec($) {
	my $bin = shift;
	my $dec = oct("0b" . $bin);
	return $dec;
}

###################################
sub SD_Keeloq_dec2bin($) {
	my $bin = unpack("B32", pack("N", shift));
	return $bin;
}

###################################
sub SD_Keeloq_translate($) {
	my $text = shift;
	my %translate = ("ä" => "&auml;", "Ä" => "&Auml;", "ü" => "&uuml;", "Ü" => "&Uuml;", "ö" => "&ouml;", "Ö" => "&Ouml;", "ß" => "&szlig;" );
	my $keys = join ("|", keys(%translate));
	$text =~ s/($keys)/$translate{$1}/g;
	return $text;
}

###################################
sub SD_Keeloq_encrypt($$$$) {
	my $x = shift;
	my $_keyHigh = shift;
	my $_keyLow = shift;
	my $name = shift;
	$KeeLoq_NLF = AttrVal($name, "KeeLoq_NLF", "");
	$KeeLoq_NLF = oct($KeeLoq_NLF);

	my $r = 0;
	my $index = 0;
	my $keyBitVal = 0;
	my $bitVal = 0;

	while ($r < 528){
		my $keyBitNo = $r & 63;
		if ($keyBitNo < 32){
			$keyBitVal = SD_Keeloq_bitRead($_keyLow, $keyBitNo);
		} else {
			$keyBitVal = SD_Keeloq_bitRead($_keyHigh, $keyBitNo - 32);
		}
		$index = 1 * SD_Keeloq_bitRead($x,1) + 2 * SD_Keeloq_bitRead($x,9) + 4 * SD_Keeloq_bitRead($x,20) + 8 * SD_Keeloq_bitRead($x,26) + 16 * SD_Keeloq_bitRead($x,31);
		$bitVal = SD_Keeloq_bitRead($x,0) ^ SD_Keeloq_bitRead($x, 16) ^ SD_Keeloq_bitRead($KeeLoq_NLF,$index) ^ $keyBitVal;
		$x = ($x >> 1 & 0xffffffff) ^ $bitVal <<31;
		$r = $r + 1;
	}
	return $x;
}

###################################
sub SD_Keeloq_decrypt($$$$) {
	my $x = shift;
	my $_keyHigh = shift;
	my $_keyLow = shift;
	my $name = shift;
	$KeeLoq_NLF = AttrVal($name, "KeeLoq_NLF", "");
	$KeeLoq_NLF = oct($KeeLoq_NLF);

	my $r = 0;
	my $index = 0;
	my $keyBitVal = 0;
	my $bitVal = 0;

	while ($r < 528){
		my $keyBitNo = (15-$r) & 63;

		if ($keyBitNo < 32){
			$keyBitVal = SD_Keeloq_bitRead($_keyLow, $keyBitNo);
		} else {
			$keyBitVal = SD_Keeloq_bitRead($_keyHigh, $keyBitNo -32);
		}

		$index = 1 * SD_Keeloq_bitRead($x,0) + 2 * SD_Keeloq_bitRead($x,8) + 4 * SD_Keeloq_bitRead($x,19) + 8 * SD_Keeloq_bitRead($x,25) + 16 * SD_Keeloq_bitRead($x,30);
		$bitVal = SD_Keeloq_bitRead($x,31) ^ SD_Keeloq_bitRead($x, 15) ^ SD_Keeloq_bitRead($KeeLoq_NLF,$index) ^ $keyBitVal;
		$x = ($x << 1 & 0xffffffff) ^ $bitVal;
		#if ($r == 5){
		#exit 1;
		#}
		#$x = ctypes.c_ulong((x>>1) ^ bitVal<<31).value
		$r = $r + 1;
	}
	return $x;
}

###################################
sub SD_Keeloq_bitRead($$) {
	my $wert = shift;
	my $bit = shift;

	return ($wert >> $bit) & 0x01;
}

#####################################
sub SD_Keeloq_binsplit_JaroLift($) {
	my $bits = shift;
	my $binsplit;

	for my $i(0..71) {
		$binsplit.= substr($bits,$i,1);
		$binsplit.= " " if (($i+1) % 8 == 0 && $i < 32);
		$binsplit.= " " if ($i == 35 || $i == 59 || $i == 63);
	}
	return $binsplit;
}

#####################################
sub SD_Keeloq_binsplit_Roto($) {
	my $bits = shift;
	my $binsplit;

	for my $i(0..65) {
		$binsplit.= substr($bits,$i,1);
		$binsplit.= " " if (($i+1) % 16 == 0 && $i < 27);
		$binsplit.= " " if ($i == 27 || $i == 31 || $i == 59 || $i == 63 || $i == 64 || $i == 65);
	}
	return $binsplit;
}

#####################################
sub summaryFn($$$$) {
	my ($FW_wname, $d, $room, $pageHash) = @_;										# pageHash is set for summaryFn.
	my $hash   = $defs{$d};
	my $name = $hash->{NAME};
	return SD_Keeloq_attr2html($name, $hash);
}

#####################################
# Create HTML-Code
sub SD_Keeloq_attr2html($@) {
	my ($name, $hash) = @_;
	my $addGroups = AttrVal($name, "addGroups", "");							# groups with channels
	my $Channels = AttrVal($name, "Channels", 1);
	my $ChannelFixed = AttrVal($name, "ChannelFixed", "ch1");  
	my $ChannelNames = AttrVal($name, "ChannelNames", "");
  my $DDSelected = ReadingsVal($name, "DDSelected", "");
	my $ShowShade = AttrVal($name, "ShowShade", 1);
  my $ShowIcons = AttrVal($name, "ShowIcons", 1);
  my $ShowLearn = AttrVal($name, "ShowLearn", 1);
  my $UI = AttrVal($name, "UI", "aus");
	my $Serial_send = AttrVal($name, "Serial_send", "");

	my @groups = split / /, $addGroups;														# split define groupnames
	my @grpInfo;																									# array of name and channels of group | name:channels
	my $grpName;																									# name of group
	my $html;


	### without UI
	if ($UI eq "aus" || $Serial_send eq "") {
		return;
	}

	### ChannelNames festlegen
	my @ChName = ();																												# name standard
	my @ChName_alias = ();																									# alias name from attrib ChannelNames
	@ChName_alias = split /,/, $ChannelNames if ($ChannelNames ne "");			# overwrite array with values
	for my $rownr (1..16) {
		if ( scalar(@ChName_alias) > 0 && scalar(@ChName_alias) >= $rownr) {
			push(@ChName,"Kanal $rownr") if ($ChName_alias[$rownr-1] eq "");
			push(@ChName,$ChName_alias[$rownr-1]) if ($ChName_alias[$rownr-1] ne "");
		} else {
			push(@ChName,"Kanal $rownr");
		}
	}

	### Mehrzeilig ###
	if ($UI eq "Mehrzeilig") {
		if (not exists $attr{$name}{ChannelFixed}) {
			$html = "<div><table class=\"block wide\">"; 
			foreach my $rownr (1..$Channels) {
				$html.= "<tr><td>";
				$html.= $ChName[$rownr-1]."</td>";
				$html.= SD_Keeloq_attr2htmlButtons("$rownr", $name, $ShowIcons, $ShowShade, $ShowLearn);
				$html.= "</tr>";
			}
		} else {
			$html = "<div><table class=\"block wide\">";
			$html.= "<tr><td>";
			$html.= $ChName[$ChannelFixed-1]."</td>";
			$html.= SD_Keeloq_attr2htmlButtons($ChannelFixed, $name, $ShowIcons, $ShowShade, $ShowLearn);
			$html.= "</tr>";
		}

		### Gruppen hinzu
		foreach my $grp (@groups) {
			my @grpInfo = split /:/, $grp;
			my $grpName = $grpInfo[0];
			$html.= "<tr><td>";
			$html.= $grpName."</td>";
			$html.= SD_Keeloq_attr2htmlButtons($grpInfo[1], $name, $ShowIcons, $ShowShade, 0);
			$html.= "</tr>";
		}

		$html.= "</table></div>";
		return $html;
	}

	### Einzeilig ###
	if ($UI eq "Einzeilig") {
		if (not exists $attr{$name}{ChannelFixed}) {
			$html = "<div><table class=\"block wide\"><tr><td>"; 
			my $changecmd = "cmd.$name=setreading $name DDSelected ";
			$html.= "<select name=\"val.$name\" onchange=\"FW_cmd('$FW_ME$FW_subdir?XHR=1&$changecmd ' + this.options[this.selectedIndex].value)\">";
			foreach my $rownr (1..$Channels) {
				if ($DDSelected eq "$rownr"){
					$html.= "<option selected value=".($rownr).">".($ChName[$rownr-1])."</option>";
				} else {
					$html.= "<option value=".($rownr).">".($ChName[$rownr-1])."</option>";
				}
			}

			### Gruppen hinzu
			foreach my $grp (@groups) { 
				my @grpInfo = split /:/, $grp;
				my $grpName = $grpInfo[0];
				if ($DDSelected eq $grpInfo[1]) {
					$html.= "<option selected value=".$grpInfo[1].">".$grpName."</option>";
				} else {
					$html.= "<option value=".$grpInfo[1].">".$grpName."</option>";
				}
			}

			$html.= "</select></td>";
			$html.= SD_Keeloq_attr2htmlButtons($DDSelected, $name, $ShowIcons, $ShowShade, $ShowLearn);
			$html.= "</table></div>";
		}

		### Einzeilig with attrib ChannelFixed ###
		if (exists $attr{$name}{ChannelFixed}) {
			$html = "<div><table class=\"block wide\"><tr><td>$ChName[$ChannelFixed-1]</td>";
			$html.= SD_Keeloq_attr2htmlButtons($ChannelFixed, $name, $ShowIcons, $ShowShade, $ShowLearn);
			$html.= "</tr></table></div>";
		}
		return $html;
	}

	return;
}

#####################################
sub SD_Keeloq_attr2htmlButtons($$$$$) {
	my ($channel, $name, $ShowIcons, $ShowShade, $ShowLearn) = @_;		# $name = name of device | $channel = 1 ... 16 or channelgroup example 2,4
	my $html = "";

	### UP
	my $cmd = "cmd.$name=set $name up $channel";
	$html.= "<td><a onClick=\"FW_cmd('$FW_ME$FW_subdir?XHR=1&$cmd')\">Hoch</a></td>" if (!$ShowIcons);
	$html.= "<td><a onClick=\"FW_cmd('$FW_ME$FW_subdir?XHR=1&$cmd')\">".FW_makeImage("fts_shutter_up")."</a></td>" if ($ShowIcons == 1);

	### STOP
	$cmd = "cmd.$name=set $name stop $channel";
	$html.= "<td><a onClick=\"FW_cmd('$FW_ME$FW_subdir?XHR=1&$cmd')\">Stop</a></td>" if (!$ShowIcons);
	$html.= "<td><a onClick=\"FW_cmd('$FW_ME$FW_subdir?XHR=1&$cmd')\">".FW_makeImage("rc_STOP")."</a></td>" if ($ShowIcons == 1);

	### DOWN
	$cmd = "cmd.$name=set $name down $channel";
	$html.= "<td><a onClick=\"FW_cmd('$FW_ME$FW_subdir?XHR=1&$cmd')\">Runter</a></td>" if (!$ShowIcons);
	$html.= "<td><a onClick=\"FW_cmd('$FW_ME$FW_subdir?XHR=1&$cmd')\">".FW_makeImage("fts_shutter_down")."</a></td>" if ($ShowIcons == 1);

	### SHADE
	$cmd = "cmd.$name=set $name shade $channel";
	$html.= "<td><a onClick=\"FW_cmd('$FW_ME$FW_subdir?XHR=1&$cmd')\">Beschattung</a></td>" if (($ShowShade) && (!$ShowIcons));
	$html.= "<td><a onClick=\"FW_cmd('$FW_ME$FW_subdir?XHR=1&$cmd')\">".FW_makeImage("fts_shutter_shadding_run")."</a></td>" if ($ShowIcons == 1 && $ShowShade == 1);

	### LEARN
	$cmd = "cmd.$name=set $name learn $channel";
	$html.= "<td><a onClick=\"FW_cmd('$FW_ME$FW_subdir?XHR=1&$cmd')\">Lernen</a></td>" if (($ShowLearn) && (!$ShowIcons));
	$html.= "<td><a onClick=\"FW_cmd('$FW_ME$FW_subdir?XHR=1&$cmd')\">".FW_makeImage("fts_shutter_manual")."</a></td>" if ($ShowIcons == 1 && $ShowLearn == 1);

	return $html;
}

# Eval-Rückgabewert für erfolgreiches
# Laden des Moduls
1;


# Beginn der Commandref

=pod
=item device
=item summary 14_SD_Keeloq supports wireless devices with KeeLoq method
=item summary_DE 14_SD_Keeloq unterst&uuml;tzt Funkger&auml;te mit dem KeeLoq Verfahren

=begin html

<a name="SD_Keeloq"></a>
<h3>SD_Keeloq</h3>
<ul>The SD_Keeloq module is used to process devices that work according to the KeeLoq method. It was made after presentation of Bastelbudenbuben project. 
	To decode and encode the signal keys are needed which must be set via attribute! Without a key you can use the module to receive the unencrypted data.<br><br>

	The created device is partially displayed with the serial number of the remote control and the state of the device.<br><br>

	<b><i>After entering the correct key, you will receive all states and the sending or controlling is possible!<br>
	An anchoring of the keys in the module is NOT included and everyone has to manage it himself.</i></b><br>
	- KeeLoq is a registered trademark of Microchip Technology Inc.-<br><br>
	
	<u>The following devices are supported:</u><br>
	<ul> - JaroLift radio wall transmitter (example: TDRC 16W / TDRCT 04W)&nbsp;&nbsp;&nbsp;<small>(model: JaroLift | protocol 87)</small><br></ul>
	<ul> - RADEMACHER remote with two button&nbsp;&nbsp;&nbsp;<small>(model: RP_S1_HS_RF11 | protocol 88)&nbsp;&nbsp;[HCS301 chip]</small><br></ul>
	<ul> - Roto remote with three button&nbsp;&nbsp;&nbsp;<small>(model: Roto | protocol 88)&nbsp;&nbsp;[HCS301 chip]</small><br></ul>
	<ul> - SCS Sentinel remote with four button&nbsp;&nbsp;&nbsp;<small>(model: PR3_4207_002 | protocol 88)&nbsp;&nbsp;[HCS301 chip]</small><br></ul>
	<ul> - Waeco_MA650_TX remote with two button&nbsp;&nbsp;&nbsp;<small>(model: Waeco_MA650_TX | protocol 88)&nbsp;&nbsp;[HCS301 chip]</small><br></ul>
	<br>
	<b><i>Each model has a different length of the serial number! Please enter the serial number in hexadecimal.<br>
	For the models RP_S1_HS_RF11 / Roto & Waeco_MA650_TX the length is 7 and for the model JaroLift 6.</i></b>
	<br><br><br>

	<b>Define</b><br>
	<ul><code>define &lt;NAME&gt; SD_Keeloq &lt;Serial&gt; </code><br><br>
	example: <ul><li>define SD_Keeloq_Device1 SD_Keeloq 9AA000</li>
	<li>define SD_Keeloq_Device2 SD_Keeloq F7F5709</li></ul>
	</ul><br><br>

	<b>Set</b>&nbsp;&nbsp;(only JaroLift)<br>
	<ul><code>set &lt;Devicename&gt; &lt;command&gt; &lt;NAME&gt;</code><br><br>
	<i><b>NAME:</b>1-16</i> or created <i>addGroups</i></ul><br>

	<ul><b>command:</b><br>
		<ul>
			<li><b>learn</b><br>
			Teaching an engine. Please put the motor in learn mode according to the manufacturer's instructions.<br>
			<li><b>down</b><br>
			engine down<br>
			<li><b>up</b><br>
			engine up<br>
			<li><b>stop</b><br>
			engine stop<br>
			<li><b>updown</b><br>
			Simultaneously pressing the up and down keys for programming purposes.<br>
			<li><b>shade</b><br>
			Bring shutters into shading position. (not supported by all receivers!)<br>
			<br>
		</ul>
	example: <ul>set SD_Keeloq_Device1 down 7<br>
	set SD_Keeloq_Device1 down northside</ul>
	</ul><br><br>

	<b>Get</b><br>
	<ul>N/A</ul><br><br>

	<b>Attribute</b><br><br>
	<ul>
		<u><b>ONLY for the model JaroLift!</b></u>
		<li><a name="addGroups"><b>addGroups</b></a><br>
		Add groups in the ad and setlist. (Please name without spaces!) &lt;group name&gt;:&lt;ch1&gt;,&lt;ch2&gt;<br>
		<i>example:</i> northside:1,2,3 southside:4,5,6</li>
		<br>
		<li><a name="ChannelFixed"><b>ChannelFixed</b></a><br>
		Selection of the fixed channel. This option only works if <code>UI = Einzeilig</code>
		</li>
		<br>
		<li><a name="ChannelNames"><b>ChannelNames</b></a><br>
		Adjust the labeling of the individual channels. Comma separated values.<br>
		<i>example:</i> kitchen, living_room, bedroom, childrens
		</li>
		<br>
		<li><a name="Channels"><b>Channels</b></a><br>
		Selection of how many channels should be displayed in the UI. (Standard 1)<br>
		To show only groups, set channels: 0 and addGroups. The value Channels: 0 is only accepted if addGroups are defined.
		</li>
		<br>
		<li><a name="LearnVersion"><b>LearnVersion</b></a><br>
		Learning variant, as this differs depending on the age of the devices. (Standard old)<br>
		<ul>- old Version: send <code>learn</code></ul>
		<ul>- new Version: send <code>updown</code> and additionally followed by <code>stop</code></ul>
		</li>
		<br>		
		<li><a name="Serial_send"><b>Serial_send</b></a><br>
		A serial number to send. It MUST be unique throughout the system and end at 00. WITHOUT the attribute Serial_send, the user does not receive a setlist --> only reception possible!<br>
		<i>example:</i> 9AC000
		</li>
		<br>
		<li><a name="ShowIcons"><b>ShowIcons</b></a><br>
		Show instead of caption icons. (Standard 0)<br>
		</li>
		<br>
		<li><a name="ShowLearn"><b>ShowLearn</b></a><br>
		Label or button for teaching the shutters. (Standard 1)
		</li>
		<br>
		<li><a name="ShowShade"><b>ShowShade</b></a><br>
		Not supported by all recipients. Hide button to drive in shading position. (Standard 1)
		</li>
		<br>
		<li><a name="UI"><b>UI</b></a><br>
		Display (UserInterface) in FHEM (Standard off)
		<br>
		<ul><li>Mehrzeilig:<br>
		Selected number of channels is displayed in tabular form instead of the STATE icon.</li>
		<li>Einzeilig:<br>
		Only one line with a selection box for the channel is displayed.</li>
		<li>aus:<br>
		Nothing is displayed. (Only controllable via SET commands).
		</li></ul>

		<br>
		<u><b>for all models</b></u>
		<li><a name="KeeLoq_NLF"><b>KeeLoq_NLF</b></a><br>
		Key for decoding and encoding. The specification is hexadecimal, 8 digits + leading with 0x.<br>
		<i>example:</i> 0xaaaaaaaa
		</li>
		<br>
		<li><a name="MasterLSB"><b>MasterLSB</b></a><br>
		Key for decoding and encoding the Keeloq rolling code. The specification is hexadecimal, 8 digits + leading with 0x.<br>
		<i>example:</i> 0xbbbbbbbb
		</li>
		<br>
		<li><a name="MasterMSB"><b>MasterMSB</b></a><br>
		Key for decoding and encoding the Keeloq rolling code. The specification is hexadecimal, 8 digits + leading with 0x.<br>
		<i>example:</i> 0xcccccccc
		</li>
		<br>
		<li><a name="Repeats"><b>Repeats</b></a><br>
		This attribute can be used to adjust how many retries are sent. (Standard 3)
		</li>
	</ul>
	<br><br>
	<b>Generated shared readings | JaroLift / PR3_4207_002 / RP_S1_HS_RF11 / Roto & Waeco_MA650_TX</b><br><br>
	<ul>
	<li>button<br>
	Pressed button on the remote control or in the FHEM device</li>
	<li>serial_receive<br>
	Serial number of the received device</li>
	<li>user_info<br>
	Information text for the user. Tips and actions are given.</li>
	<li>user_modus<br>
	Information about the device status (all_functions: it can be received and sent with the device | limited_functions: it can only be received)</li><br>
	</ul>
	<b>Generated readings JaroLift specific</b><br><br>
	<ul>
	<li>_LastAction_Channel_xx<br>
	Last executed action of the channel</li>
	<li>last_digits<br>
	Channel from the encrypted part of the received message</li>
	<li>channel<br>
	Channel to be controlled</li>
	<li>channel_control<br>
	With several controlled channels, removable channels, otherwise "no".</li>
	<li>counter_receive<br>
	Counter of the receive command</li>
	<li>counter_send<br>
	Counter of the send command</li>
	</ul>
</ul>
=end html
=begin html_DE

<a name="SD_Keeloq"></a>
<h3>SD_Keeloq</h3>
<ul>Das SD_Keeloq Modul dient zur Verarbeitung von Ger&auml;ten welche nach dem KeeLoqverfahren arbeiten. Es wurde nach Vorlage des Bastelbudenbuben Projektes gefertigt. 
	Zur De- und Encodierung des Signals werden Keys ben&ouml;tigt welche via Attribut gesetzt werden m&uuml;ssen! Ohne Schl&uuml;ssel kann man das Modul zum empfangen der unverschl&uuml;sselten Daten nutzen.<br><br>

	Das angelegte Device wird mit der Seriennummer der Fernbedienung und dem Zustand des Ger&auml;tes teilweise dargestellt.<br><br>

	<b><i>Nach Eingabe der richtigen Schl&uuml;ssel erh&auml;lt man alle Zust&auml;nde und das Senden bzw. steuern ist m&ouml;glich!<br>
	Eine Verankerung der Schl&uuml;ssel im Modul ist NICHT enthalten und jeder muss diese selbst verwalten.</i></b><br>
	- KeeLoq is a registered trademark of Microchip Technology Inc.-<br><br>
	
	<u>Es werden bisher folgende Ger&auml;te unterst&uuml;tzt:</u><br>
	<ul> - JaroLift Funkwandsender (Bsp: TDRC 16W / TDRCT 04W)&nbsp;&nbsp;&nbsp;<small>(Modulmodel: JaroLift | Protokoll 87)</small><br></ul>
	<ul> - RADEMACHER Fernbedienung mit 2 Tasten&nbsp;&nbsp;&nbsp;<small>(Modulmodel: RP_S1_HS_RF11 | Protokoll 88)&nbsp;&nbsp;[HCS301 chip]</small><br></ul>
	<ul> - Roto Fernbedienung mit 3 Tasten&nbsp;&nbsp;&nbsp;<small>(Modulmodel: Roto | Protokoll 88)&nbsp;&nbsp;[HCS301 chip]</small><br></ul>
	<ul> - SCS Sentinel Fernbedienung mit 4 Tasten&nbsp;&nbsp;&nbsp;<small>(Modulmodel: PR3_4207_002 | Protokoll 88)&nbsp;&nbsp;[HCS301 chip]</small><br></ul>
	<ul> - Waeco_MA650_TX Fernbedienung mit 2 Tasten&nbsp;&nbsp;&nbsp;<small>(Modulmodel: Waeco_MA650_TX | Protokoll 88)&nbsp;&nbsp;[HCS301 chip]</small><br></ul>
	<br>
	<b><i>Jedes Model besitzt eine andere L&auml;nge der Seriennummer! Bitte geben Sie die Serialnummer hexadezimal ein.<br>
	Bei den Modellen RP_S1_HS_RF11 / Roto & Waeco_MA650_TX ist die L&auml;nge jeweils 7 und bei dem Model JaroLift 6.</i></b>
	<br><br><br>

	<b>Define</b><br>
	<ul><code>define &lt;NAME&gt; SD_Keeloq &lt;Serial&gt; </code><br><br>
	Beispiele: <ul><li>define SD_Keeloq_Device1 SD_Keeloq 9AA000</li>
	<li>define SD_Keeloq_Device2 SD_Keeloq F7F5709</li></ul>
	</ul><br><br>

	<b>Set</b>&nbsp;&nbsp;(nur JaroLift)<br>
	<ul><code>set &lt;Devicename&gt; &lt;command&gt; &lt;NAME&gt;</code><br><br>
	<i><b>NAME:</b>1-16</i> oder angelegte <i>addGroups</i></ul><br>

	<ul><b>command:</b><br>
		<ul>
			<li><b>learn</b><br>
			Anlernen eines Motors. Bitte den Motor dazu nach Herstellerangaben in den Anlernmodus versetzen.<br>
			<li><b>down</b><br>
			Motor nach unten<br>
			<li><b>up</b><br>
			Motor nach oben<br>
			<li><b>stop</b><br>
			Motor stop<br>
			<li><b>updown</b><br>
			Gleichzeitges Dr&uuml;cken der Auf- und Abtaste zu Programmierzwecken.<br>
			<li><b>shade</b><br>
			Rolladen in Beschattungsposition bringen. (wird nicht von allen Empf&auml;ngern unterst&uuml;tzt!)<br>
			<br>
		</ul>
	Beispiele: <ul>set SD_Keeloq_Device1 down 7<br>
	set SD_Keeloq_Device1 down Nordseite</ul>
	</ul><br><br>

	<b>Get</b><br>
	<ul>N/A</ul><br><br>

	<b>Attribute</b><br><br>
	<ul>
		<u><b>NUR f&uuml;r das Modell JaroLift!</b></u>
		<li><a name="addGroups"><b>addGroups</b></a><br>
		Gruppen in der Anzeige und Setlist hinzuf&uuml;gen. (Namen bitte ohne Leerzeichen!) &lt;Gruppenname&gt;:&lt;ch1&gt;,&lt;ch2&gt;<br>
		<i>Beispiel:</i> Nordseite:1,2,3 S&uuml;dseite:4,5,6</li>
		<br>
		<li><a name="ChannelFixed"><b>ChannelFixed</b></a><br>
		Auswahl des fest eingestellten Kanals. Diese Option greift nur, wenn <code>UI = Einzeilig</code>
		</li>
		<br>
		<li><a name="ChannelNames"><b>ChannelNames</b></a><br>
		Beschriftung der einzelnen Kan&auml;le anpassen. Kommagetrennte Werte.<br>
		<i>Beispiel:</i> K&uuml;che,Wohnen,Schlafen,Kinderzimmer
		</li>
		<br>
		<li><a name="Channels"><b>Channels</b></a><br>
		Auswahl, wie viele Kan&auml;le in der UI angezeigt werden sollen. (Standard 1)<br>
		Um nur Gruppen anzuzeigen, Channels:0 und addGroups setzen. Der Wert Channels:0 wird nur akzeptiert wenn addGroups definiert sind.
		</li>
		<br>
		<li><a name="LearnVersion"><b>LearnVersion</b></a><br>
		Anlernvariante, da diese sich je nach alter der Ger&auml;te unterscheidet. (Standard old)<br>
		<ul>- old Version: senden von <code>learn</code></ul>
		<ul>- new Version: senden von <code>updown</code> und zus&auml;tzlich gefolgt von <code>stop</code></ul>
		</li>
		<br>		
		<li><a name="Serial_send"><b>Serial_send</b></a><br>
		Eine Serialnummer zum Senden. Sie MUSS eindeutig im ganzen System sein und auf 00 enden. OHNE Attribut Serial_send erh&auml;lt der User keine Setlist --> nur Empfang m&ouml;glich!<br>
		<i>Beispiel:</i> 9AC000
		</li>
		<br>
		<li><a name="ShowIcons"><b>ShowIcons</b></a><br>
		Anstelle der Beschriftung Icons anzeigen. (Standard 0)<br>
		</li>
		<br>
		<li><a name="ShowLearn"><b>ShowLearn</b></a><br>
		Beschriftung, bzw. Button, f&uuml;r das Anlernen des Rollos anzeigen. (Standard 1)
		</li>
		<br>
		<li><a name="ShowShade"><b>ShowShade</b></a><br>
		Nicht von allen Empf&auml;ngern unterst&uuml;tzt. Button zum fahren in Beschattungsposition ausblenden. (Standard 1)
		</li>
		<br>
		<li><a name="UI"><b>UI</b></a><br>
		Anzeigeart (UserInterface) in FHEM (Standard aus)
		<br>
		<ul><li>Mehrzeilig:<br>
		Ausgew&auml;hlte Anzahl an Kan&auml;len wird tabellarisch statt des STATE-Icons angezeigt</li>
		<li>Einzeilig:<br>
		Es wird nur eine Zeile mit einem Auswahlfeld f&uuml;r den Kanal angezeigt.</li>
		<li>aus:<br>
		Es wird nichts angezeigt. (Nur &uuml;ber SET-Befehle steuerbar).
		</li></ul>

		<br>
		<u><b>f&uuml;r alle Modelle</b></u>
		<li><a name="KeeLoq_NLF"><b>KeeLoq_NLF</b></a><br>
		Key zur De- und Encodierung. Die Angabe erfolgt hexadezimal, 8 stellig + f&uuml;hrend mit 0x.<br>
		<i>Beispiel:</i> 0xaaaaaaaa
		</li>
		<br>
		<li><a name="MasterLSB"><b>MasterLSB</b></a><br>
		Key zur De- und Encodierung des Keeloq Rolling Codes. Die Angabe erfolgt hexadezimal, 8 stellig + f&uuml;hrend mit 0x.<br>
		<i>Beispiel:</i> 0xbbbbbbbb
		</li>
		<br>
		<li><a name="MasterMSB"><b>MasterMSB</b></a><br>
		Key zur De- und Encodierung des Keeloq Rolling Codes. Die Angabe erfolgt hexadezimal, 8 stellig + f&uuml;hrend mit 0x.<br>
		<i>Beispiel:</i> 0xcccccccc
		</li>
		<br>
		<li><a name="Repeats"><b>Repeats</b></a><br>
		Mit diesem Attribut kann angepasst werden, wie viele Wiederholungen gesendet werden. (Standard 3)
		</li>
	</ul>
	<br><br>
	<b>Generierte gemeinsamgenutzte Readings | JaroLift / PR3_4207_002 / RP_S1_HS_RF11 / Roto & Waeco_MA650_TX</b><br><br>
	<ul>
	<li>button<br>
	Gedr&uuml;ckter Knopf an der Fernbedienung oder im FHEM Device</li>
	<li>serial_receive<br>
	Seriennummer des empfangen Ger&auml;tes</li>
	<li>user_info<br>
	Informationstext f&uuml;r den Benutzer. Es werden Tips und Handlungen ausgegeben.</li>
	<li>user_modus<br>
	Information &uuml;ber den Devicestatus (all_functions: es kann mit dem Device empfangen und gesendet werden | limited_functions: es kann nur empfangen werden)</li><br>
	</ul>
	<b>Generierte Readings JaroLift spezifisch</b><br><br>
	<ul>
	<li>_LastAction_Channel_xx<br>
	Zuletzt ausgef&uuml;hrte Aktion des Kanals</li>
	<li>last_digits<br>
	Kanal aus dem verschl&uuml;sseltem Teil der empfangenem Nachricht</li>
	<li>channel<br>
	Zu steuernder Kanal</li>
	<li>channel_control<br>
	Bei mehreren angesteuerten Kan&auml;len, entnehmbare Kan&auml;le, sonst "no".</li>
	<li>counter_receive<br>
	Z&auml;hler des Empfangsbefehles</li>
	<li>counter_send<br>
	Z&auml;hler des Sendebefehles</li>
	</ul>
</ul>

=end html_DE
=cut