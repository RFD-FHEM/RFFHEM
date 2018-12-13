##############################################################################
# $Id: 14_SD_BELL.pm 32 2018-12-13 14:00:00 v3.3.3-dev_08.12. $HomeAuto_User
#
# The file is part of the SIGNALduino project.
# The purpose of this module is to support many wireless BELL devices.
# 2018 - HomeAuto_User & elektron-bbs
#
####################################################################################################################################
# - wireless doorbell TCM_234759 Tchibo  [Protocol 15] length 12-20 (3-5)
####################################################################################################################################
# - FreeTec PE-6946  [Protocol 32] length 24 (6)
#     get sduino_dummy raw MU;;P0=146;;P1=245;;P3=571;;P4=-708;;P5=-284;;P7=-6689;;D=14351435143514143535353535353535353535350704040435043504350435040435353535353535353535353507040404350435043504350404353535353535353535353535070404043504350435043504043535353535353535353535350704040435043504350435040435353535353535353535353507040404350435;;CP=3;;R=0;;O;;
####################################################################################################################################
# - Elro (Smartwares) Doorbell DB200 / 16 melodies - unitec Modell:98156+98YK [Protocol 41] length 32 (8) doubleCode
#     get sduino_dummy raw MS;;P0=-526;;P1=1450;;P2=467;;P3=-6949;;P4=-1519;;D=231010101010242424242424102424101010102410241024101024241024241010;;CP=2;;SP=3;;O;;
# - KANGTAI Doorbell (Pollin 94-550405) [Protocol 41]  length 32 (8)
#     get sduino_dummy raw MS;;P0=1399;;P1=-604;;P2=397;;P3=-1602;;P4=-7090;;D=240123010101230123232301230123232301232323230123010101230123230101;;CP=2;;SP=4;;R=248;;O;;m1;;
####################################################################################################################################
# - m-e doorbell fuer FG- und Basic-Serie  [Protocol 57] length 21-24 (6)
#     get sduino_dummy raw MC;;LL=-653;;LH=665;;SL=-317;;SH=348;;D=D55B58;;C=330;;L=21;;
####################################################################################################################################
# - VTX-BELL_Funkklingel  [Protocol 79] length 12 (3)
#     get sduino_dummy raw MU;;P0=656;;P1=-656;;P2=335;;P3=-326;;P4=-5024;;D=01230121230123030303012423012301212301230303030124230123012123012303030301242301230121230123030303012423012301212301230303030124230123012123012303030301242301230121230123030303012423012301212301230303030124230123012123012303030301242301230121230123030303;;CP=2;;O;;
####################################################################################################################################
# !!! ToDo´s !!!
#     - KANGTAI doubleCode must CEHCK | only one Code? - MORE USER MSG needed
#     -
####################################################################################################################################

### oberer Teil ###
package main;

use strict;
use warnings;

### HASH for all modul models ###
my %models = (
	# keys(model) => values
	"unknown" =>	{	hex_lengh		=> "99",			# length only for comparison
									Protocol		=> "00",
									doubleCode	=> "no"
								},
	"TCM_234759" =>	{	hex_lengh		=> "3,4,5",
										Protocol		=> "15",
										doubleCode	=> "no"
									},
	"FreeTec_PE-6946" =>	{	hex_lengh		=> "6",
													Protocol		=> "32",
													doubleCode	=> "no"
												},
	"Elro_DB200_/_KANGTAI_/_unitec" =>	{	hex_lengh		=> "8",
																				Protocol		=> "41",
																				doubleCode	=> "yes"
																			},
	"FG_/_Basic-Serie" =>	{	hex_lengh		=> "6",
													Protocol		=> "57",
													doubleCode	=> "no"
												},
	"Heidemann_|_Heidemann_HX_|_VTX-BELL" =>	{	hex_lengh		=> "3",
																							Protocol		=> "79",
																							doubleCode	=> "no"
																						},
);


sub SD_BELL_Initialize($) {
	my ($hash) = @_;
	$hash->{Match}			= "^P(?:15|32|41|42|57|79)#.*";
	$hash->{DefFn}			= "SD_BELL::Define";
	$hash->{UndefFn}		= "SD_BELL::Undef";
	$hash->{ParseFn}		= "SD_BELL::Parse";
	$hash->{SetFn}			= "SD_BELL::Set";
	$hash->{AttrFn}			= "SD_BELL::Attr";
	$hash->{AttrList}		= "repeats:1,2,3,4,5,6,7,8,9,10,11,12,13,14,15 IODev do_not_notify:1,0 ignore:0,1 showtime:1,0 model:".join(",", sort keys %models) . " $main::readingFnAttributes";
	$hash->{AutoCreate}	=	{"SD_BELL.*" => {FILTER => "%NAME", autocreateThreshold => "3:180", GPLOT => ""}};
}

### unterer Teil ###
package SD_BELL;

use strict;
use warnings;
use POSIX;

use GPUtils qw(:all);  # wird für den Import der FHEM Funktionen aus der fhem.pl benötigt

my $missingModul = "";

## Import der FHEM Funktionen
BEGIN {
		GP_Import(qw(
		AssignIoPort
		AttrVal
		attr
		defs
		IOWrite
		InternalVal
		Log3
		modules
		readingsBeginUpdate
		readingsBulkUpdate
		readingsDelete
		readingsEndUpdate
		readingsSingleUpdate
		))
};


###################################
sub Define($$) {
	my ($hash, $def) = @_;
	my @a = split("[ \t][ \t]*", $def);
	my $hash_name;
	my $name = $hash->{NAME};
	my $protocol = $a[2];
	my $hex_lengh = length($a[3]);
	my $doubleCode = "no";

	#Log3 $name, 3, "SD_BELL_Def name=$a[0] protocol=$protocol HEX-Value=$a[3] hex_lengh=$hex_lengh";

	# Argument															0	   	1					2		    	3						4
	return "SD_BELL: wrong syntax: define <name> SD_BELL <Protocol> <HEX-Value> <optional IODEV>" if(int(@a) < 3 || int(@a) > 5);
	### checks - doubleCode yes ###
	return "SD_BELL: wrong <protocol> $a[2]" if not($a[2] =~ /^(?:15|32|41|57|79)/s);
	return "SD_BELL: wrong HEX-Value! Protocol $a[2] HEX-Value <$a[3]> not HEX (0-9 | a-f | A-F)" if (($protocol != 41) && not $a[3] =~ /^[0-9a-fA-F]*$/s);
	return "SD_BELL: wrong HEX-Value! Protocol $a[2] HEX-Value <$a[3]> not HEX (0-9 | a-f | A-F) or length wrong!" if (($protocol == 41) && not $a[3] =~ /^[0-9a-fA-F]{8}_[0-9a-fA-F]{8}$/s);

	($hash_name) = grep { $models{$_}{Protocol} eq $protocol } keys %models;		# search protocol --> model
	$doubleCode = $models{$hash_name}{doubleCode};															# read note doubleCode

	$hash->{doubleCode} =  "Code alternates between two RAWMSG" if($protocol == 41);
	$hash->{lastMSG} =  "";
	$hash->{bitMSG} =  "";
	my $iodevice = $a[4] if($a[4]);

	$modules{SD_BELL}{defptr}{$hash->{DEF}} = $hash;
	my $ioname = $modules{SD_BELL}{defptr}{ioname} if (exists $modules{SD_BELL}{defptr}{ioname} && not $iodevice);
	$iodevice = $ioname if not $iodevice;

	### Attributes | model set after codesyntax ###
	$attr{$name}{model}	= $hash_name if ( not exists($attr{$name}{model}) );				# set model, if only undef --> new def
	$attr{$name}{room}	= "SD_BELL"	if ( not exists( $attr{$name}{room} ) );				# set room, if only undef --> new def

	AssignIoPort($hash, $iodevice);
}

###################################
sub Set($$$@) {
	my ( $hash, $name, @a ) = @_;
	my $cmd = $a[0];
	my $ioname = $hash->{IODev}{NAME};
	my $model = AttrVal($name, "model", "unknown");
	my @split = split(" ", $hash->{DEF});
	my @splitCode = "";																			# for doubleCode
	my $protocol = $split[0];
	my $repeats = AttrVal($name,'repeats', '5');
	my $doubleCodeCheck;
	my $ret = undef;

	if ($cmd eq "?") {
		$ret .= "ring:noArg";
	} else {
		my $rawDatasend = $split[1];													# hex value from def without protocol
		if ($rawDatasend =~ /[0-9a-fA-F]_[0-9a-fA-F]/s) {			# check doubleCode in def
			$doubleCodeCheck = 1;
			@splitCode = split("_", $rawDatasend);
			$rawDatasend = $splitCode[0];
		} else {
			$doubleCodeCheck = 0;
		}

		Log3 $name, 4, "$ioname: SD_BELL_Set_doubleCodeCheck doubleCodeCheck=$doubleCodeCheck splitCode[0]=$rawDatasend";
		
		my $hlen = length($rawDatasend);
		my $blen = $hlen * 4;
		my $bitData = unpack("B$blen", pack("H$hlen", $rawDatasend));
		
		my $msg = "P$protocol#" . $bitData;
		
		$msg .= "#R$repeats";
		Log3 $name, 3, "$ioname: $name sendMsg=$msg";

		if ($cmd ne "?") {
			$cmd = "ring";
		}				

		Log3 $name, 3, "$ioname: $name set $cmd" if ($cmd ne "?");
		IOWrite($hash, 'sendMsg', $msg);
	}

	readingsSingleUpdate($hash, "state" , $cmd, 1) if ($cmd ne "?");
	return $ret;
}

###################################
sub Undef($$) {
	my ($hash, $name) = @_;
	delete($modules{SD_BELL}{defptr}{$hash->{DEF}}) if(defined($hash->{DEF}) && defined($modules{SD_BELL}{defptr}{$hash->{DEF}}));
	delete($modules{SD_BELL}{defptr}{doubleCode}) if(defined($modules{SD_BELL}{defptr}{defptr}{doubleCode}));
	delete($modules{SD_BELL}{defptr}{doubleCode_Time}) if(defined($modules{SD_BELL}{defptr}{defptr}{doubleCode_Time}));
	return undef;
}


###################################
sub Parse($$) {
	my ($iohash, $msg) = @_;
	my $ioname = $iohash->{NAME};
	my ($protocol,$rawData) = split("#",$msg);
	$protocol=~ s/^[u|U|P](\d+)/$1/;																									# extract protocol ID, $1 = ID
	my $hlen = length($rawData);
	my $blen = $hlen * 4;
	my $bitData = unpack("B$blen", pack("H$hlen", $rawData));
	my $doubleCode_known = "0";																												# marker, RAWMSG known in defpr
	my ($hash_name) = grep { $models{$_}{Protocol} eq $protocol } keys %models;				# search protocol --> model
	my $deviceCode = $rawData;
	my $devicedef;

	Log3 $iohash, 4, "$ioname: SD_BELL_Parse protocol $protocol $hash_name doubleCode=".$models{$hash_name}{doubleCode}." rawData=$rawData";	

	## loop to view SD_BELL defined defptr ##
	if ($protocol == 41) {
		foreach my $d(sort keys %{$modules{SD_BELL}{defptr}}) {
			Log3 $iohash, 4, "$ioname: SD_BELL_Parse Check defptr - $d is defined!" if ($d =~ /$protocol/s);
			if ($d =~ /$rawData/s) {
				my @doubleCode = split(" ",$d);								# split two RAWMSG from protocol in def 41 BA7983D3_3286D393
				$doubleCode_known = $doubleCode[1];						# RAWMSG are in split RAWMSG
				Log3 $iohash, 4, "$ioname: SD_BELL_Parse Check defptr - $rawData is already registered!"			 
			}
		}

		$modules{SD_BELL}{defptr}{doubleCode_Time} = 0 if (!exists $modules{SD_BELL}{defptr}{doubleCode_Time});
		Log3 $iohash, 4, "$ioname: SD_BELL_Parse Check doubleCode - doubleCode_Time_old=".$modules{SD_BELL}{defptr}{doubleCode_Time}." Time_now=".time()." Diff=".(time()-$modules{SD_BELL}{defptr}{doubleCode_Time});

		if ((time() - $modules{SD_BELL}{defptr}{doubleCode_Time} > 15) && $doubleCode_known eq "0") {			# max timediff 15 seconds
			Log3 $iohash, 4, "$ioname: SD_BELL_Parse Check doubleCode - pointer <doubleCode> not exists!" if (not exists $modules{SD_BELL}{defptr}{doubleCode});
			Log3 $iohash, 4, "$ioname: SD_BELL_Parse Check doubleCode - pointer <doubleCode> ".$modules{SD_BELL}{defptr}{doubleCode}." deleted! RAWMSG too old!" if (exists $modules{SD_BELL}{defptr}{doubleCode});
			delete ($modules{SD_BELL}{defptr}{doubleCode}) if (exists $modules{SD_BELL}{defptr}{doubleCode});
			$modules{SD_BELL}{defptr}{doubleCode_Time} = time();															# set time for new RAWMSG
			return "";
		}

		### doubleCode yes and RAWMSG are unknown in def ###
		if ($models{$hash_name}{doubleCode} eq "yes" && $doubleCode_known eq "0") {					# !defs
			Log3 $iohash, 3, "$ioname: SD_BELL_Parse Check doubleCode - doubleCode known $doubleCode_known in defptr. autocreate are not complete finish!";

			if (exists $modules{SD_BELL}{defptr}{doubleCode}) {
				Log3 $iohash, 4, "$ioname: SD_BELL_Parse Check doubleCode - pointer <doubleCode> data already exists!";
			} else {
				$modules{SD_BELL}{defptr}{doubleCode} = $rawData."_doubleCode";									# first RAWMSG | reset marker, RAWMSG other
				$modules{SD_BELL}{defptr}{doubleCode_Time} = time();														# set time from new RAWMSG
				Log3 $iohash, 3, "$ioname: SD_BELL_Parse Check doubleCode - ".$modules{SD_BELL}{defptr}{doubleCode}." new defined!";
				return "";
			}

			if ($modules{SD_BELL}{defptr}{doubleCode} =~ /_doubleCode/s ) {										# check of 2 RAWMSG
				my @doubleCode = split("_",$modules{SD_BELL}{defptr}{doubleCode});

				# Codes - common ground unknown !! #
				####################################
				# 45D77A2C	BA7983D3
				# E86E2A6C	3286D393
				#
				# 754485D3  08E8D593
				# 08E8D593  754485D3
				# 3286D393  BA7983D3
				# BA7983D3  3286D393

				# my $check_4 = 0;
				# $check_4 = 1 if (abs(hex(substr($doubleCode[0],4,1)) - hex(substr($rawData,4,1))) == 5);
				# my $check_5 = 0;
				# $check_5 = 1 if (substr($doubleCode[0],5,1) eq substr($rawData,5,1));
				# my $check_6 = 0;
				# $check_6 = 1 if (abs(hex(substr($doubleCode[0],6,1)) - hex(substr($rawData,6,1))) == 4);
				# my $check_7 = 0;
				# $check_7 = 1 if (substr($doubleCode[0],7,1) eq substr($rawData,7,1));

				# if ($check_4 != 1 || $check_5 != 1 || $check_6 != 1 || $check_7 != 1) {
					# Log3 $iohash, 3, "$ioname: SD_BELL_Parse Check doubleCode - RAWMSG check failed ($check_4 $check_5 $check_6 $check_7)";
					# return "";
				# }

				### messages are verified ###
				if ($modules{SD_BELL}{defptr}{doubleCode} =~ /$rawData/s) {											# check, part known
					Log3 $iohash, 4, "$ioname: SD_BELL_Parse Check doubleCode - $rawData is already known!";
				} else {																																				# new part
					$modules{SD_BELL}{defptr}{doubleCode} = $doubleCode[0]."_".$rawData;
					Log3 $iohash, 4, "$ioname: SD_BELL_Parse Check doubleCode - $rawData part two for defptr find!";
				}
				Log3 $iohash, 4, "$ioname: SD_BELL_Parse Check doubleCode - ".$modules{SD_BELL}{defptr}{doubleCode}." complete for defptr";
				$deviceCode = $modules{SD_BELL}{defptr}{doubleCode};
				$devicedef = $protocol . " " .$deviceCode;
			} else {
				if ($modules{SD_BELL}{defptr}{doubleCode} =~ /$rawData/s) {											# check RAWMSG known
					Log3 $iohash, 4, "$ioname: SD_BELL_Parse Check doubleCode - $rawData already registered! The system search the second code.";
					$deviceCode = $modules{SD_BELL}{defptr}{doubleCode};
					$devicedef = $protocol . " " .$deviceCode;
				} else {
					Log3 $iohash, 3, "$ioname: SD_BELL_Parse Check doubleCode - RAWMSG $rawData failed! Other MSG are registered!";		# Error detections, another bit
					return "";
				}
			}
			### doubleCode yes and RAWMSG are known in def ###
		} elsif ($models{$hash_name}{doubleCode} eq "yes" && $doubleCode_known ne "0") {
			$devicedef = $protocol . " " .$doubleCode_known;																									# variant two, RAWMSG in a different order
			Log3 $iohash, 4, "$ioname: SD_BELL_Parse Check doubleCode - $devicedef ready to define!";					# Error detections, another bit
		}
	### doubleCode no without P41 ###
	} else {
		$devicedef = $protocol . " " .$deviceCode;
		Log3 $iohash, 4, "$ioname: SD_BELL_Parse Check - $rawData alone";
	}

	my $def = $modules{SD_BELL}{defptr}{$devicedef};
	$modules{SD_BELL}{defptr}{ioname} = $ioname;

	if(!$def) {
		Log3 $iohash, 1, "$ioname: SD_BELL_Parse UNDEFINED BELL detected, Protocol ".$protocol." code " . $deviceCode;
		return "UNDEFINED SD_BELL_$deviceCode SD_BELL $protocol $deviceCode";
	}

	my $hash = $def;
	my $name = $hash->{NAME};
	$hash->{lastMSG} = $rawData;
	$hash->{bitMSG} = $bitData;

	my $model = AttrVal($name, "model", "unknown");
	my $state = "ring";
	Log3 $name, 4, "$ioname: SD_BELL_Parse $name model=$model state=$state ($rawData)";

	readingsBeginUpdate($hash);
	readingsBulkUpdate($hash, "state", $state);
	readingsEndUpdate($hash, 1); 		# Notify is done by Dispatch

	return $name;
}

###################################
sub Attr(@) {
	my ($cmd, $name, $attrName, $attrValue) = @_;
	my $hash = $defs{$name};
	my $typ = $hash->{TYPE};
	my $ioDev = InternalVal($name, "LASTInputDev", undef);
	my $state;
	my $oldmodel = AttrVal($name, "model", "unknown");

	my @hex_lengh_def = split(" ", $defs{$name}->{DEF});
	my $hex_lengh = length($hex_lengh_def[1]);
	my $check_ok = 0;
	#Log3 $name, 3, "SD_BELL_Attr cmd=$cmd attrName=$attrName attrValue=$attrValue oldmodel=$oldmodel";

	if ($cmd eq "set" && $attrName eq "model" && $attrValue ne $oldmodel) {		### set new attr

		$check_ok = 1 if ($models{$attrValue}{hex_lengh} =~ /($hex_lengh)/);
		return "SD_BELL: ERROR! You want to choose the $oldmodel model to $attrValue.\nPlease check your selection. Your HEX-Value in DEF with a length of " .$hex_lengh. " are not allowed on this model!" if ($check_ok != 1 && $hex_lengh != 0);
		Log3 $name, 3, "SD_BELL_Attr $cmd $attrName to $attrValue from $oldmodel";
	}

	if ($cmd eq "del" && $attrName eq "model") {		### delete readings
		readingsDelete($hash, "LastAction") if(defined(ReadingsVal($hash->{NAME},"LastAction",undef)));
		readingsDelete($hash, "state") if(defined(ReadingsVal($hash->{NAME},"state",undef)));
	}

	return undef;
}

1;

=pod
=item summary    module for wireless bells
=item summary_DE Modul f&uuml;r Funk-Klingeln
=begin html

<a name="SD_BELL"></a>
<h3>SD_BELL</h3>
<ul>The module SD_BELL is a universal module of the SIGNALduino for different bells.<br><br>
	<u>Currently, the following models are supported:</u>
	<ul>
	<li>wireless doorbell TCM 234759 Tchibo  [Protocol 15]</li>
	<li>FreeTec PE-6946  [Protocol 32]</li>
	<li>Elro (Smartwares) Doorbell DB200 / 16 melodies - unitec Modell:98156+98YK [Protocol 41]</li>
	<li>m-e doorbell fuer FG- and Basic-Serie  [Protocol 57]</li>
	<li>Heidemann | Heidemann HX | VTX-BELL_Funkklingel  [Protocol 79]</li>
	<br>
	<u><i>Special feature Protocol 41, 2 different codes will be sent one after the other!</u></i>
	</ul><br>
	<br>

	<b>Define</b><br>
	<ul><code>define &lt;NAME&gt; SD_BELL &lt;protocol&gt; &lt;hex-adresse&gt;</code><br><br>
	<u>Examples:</u>
		<ul>
		define &lt;NAME&gt; SD_BELL 32 68C1DA<br>
		define &lt;NAME&gt; SD_BELL 41 754485D3_08E8D593<br>
		define &lt;NAME&gt; SD_BELL 79 A3C<br>
		</ul></ul><br>

	<b>Set</b><br>
	<ul>ring</ul><br>
	
	<b>Get</b><br>
	<ul>N/A</ul><br>
	
	<b>Attribute</b><br>
	<ul><li><a href="#do_not_notify">do_not_notify</a></li></ul>
	<ul><li><a href="#ignore">ignore</a></li></ul>
	<ul><li><a href="#IODev">IODev</a></li></ul>
	<ul><a name="model"></a>
		<li>model<br>
		The attribute indicates the model type of your device.<br></li></ul>
	<ul><li><a name="repeats"></a>repeats<br>
		This attribute can be used to adjust how many repetitions are sent. Default is 5.</li></ul><br>
		<br>
</ul>
=end html
=begin html_DE

<a name="SD_BELL"></a>
<h3>SD_BELL</h3>
<ul>Das Modul SD_BELL ist ein Universalmodul vom SIGNALduino f&uuml;r verschiedene Klingeln.<br><br>
	<u>Derzeit werden folgende Modelle unters&uuml;tzt:</u>
	<ul>
	<li>wireless doorbell TCM 234759 Tchibo  [Protokoll 15]</li>
	<li>FreeTec PE-6946  [Protokoll 32]</li>
	<li>Elro (Smartwares) Doorbell DB200 / 16 Melodien - unitec Modell:98156+98YK [Protokoll 41]</li>
	<li>m-e doorbell fuer FG- und Basic-Serie  [Protokoll 57]</li>
	<li>Heidemann | Heidemann HX | VTX-BELL_Funkklingel  [Protokoll 79]</li>
	<br>
	<u><i>Besonderheit Protokoll 41, es sendet 2 verschiedene Codes nacheinader!</u></i>
	</ul><br>
	<br>

	<b>Define</b><br>
	<ul><code>define &lt;NAME&gt; SD_BELL &lt;Protokoll&gt; &lt;Hex-Adresse&gt;</code><br><br>
	<u>Beispiele:</u>
		<ul>
		define &lt;NAME&gt; SD_BELL 32 68C1DA<br>
		define &lt;NAME&gt; SD_BELL 41 754485D3_08E8D593<br>
		define &lt;NAME&gt; SD_BELL 79 A3C<br>
		</ul></ul><br>

	<b>Set</b><br>
	<ul>ring</ul><br>
	
	<b>Get</b><br>
	<ul>N/A</ul><br>
	
	<b>Attribute</b><br>
	<ul><li><a href="#do_not_notify">do_not_notify</a></li></ul>
	<ul><li><a href="#ignore">ignore</a></li></ul>
	<ul><li><a href="#IODev">IODev</a></li></ul>
	<ul><a name="model"></a>
		<li>model<br>
		Das Attribut bezeichnet den Modelltyp Ihres Ger&auml;tes.<br></li></ul>
		<ul><li><a name="repeats"></a>repeats<br>
		Mit diesem Attribut kann angepasst werden, wie viele Wiederholungen sendet werden. Standard ist 5.</li></ul><br>
	<br>
</ul>
=end html_DE
=cut
