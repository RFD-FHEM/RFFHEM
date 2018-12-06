##############################################################################
# $Id: 14_SD_BELL.pm 32 2018-12-06 14:00:00 v3.3.3-dev_06.12. $HomeAuto_User
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
# - Elro (Smartwares) Doorbell DB200 / 16 melodies - unitec Modell:98156+98YK [Protocol 41] length 32 (8)
#     get sduino_dummy raw MS;;P0=-526;;P1=1450;;P2=467;;P3=-6949;;P4=-1519;;D=231010101010242424242424102424101010102410241024101024241024241010;;CP=2;;SP=3;;O;;
####################################################################################################################################
# - KANGTAI Doorbell (Pollin 94-550405) [Protocol 42]  length 32 (8)
#     get sduino_dummy raw MS;;P0=1399;;P1=-604;;P2=397;;P3=-1602;;P4=-7090;;D=240123010101230123232301230123232301232323230123010101230123230101;;CP=2;;SP=4;;R=248;;O;;m1;;
####################################################################################################################################
# - m-e doorbell fuer FG- und Basic-Serie  [Protocol 57] length 21-24 (6)
#     get sduino_dummy raw MC;;LL=-653;;LH=665;;SL=-317;;SH=348;;D=D55B58;;C=330;;L=21;;
####################################################################################################################################
# - VTX-BELL_Funkklingel  [Protocol 79] length 12 (3)
#     get sduino_dummy raw MU;;P0=656;;P1=-656;;P2=335;;P3=-326;;P4=-5024;;D=01230121230123030303012423012301212301230303030124230123012123012303030301242301230121230123030303012423012301212301230303030124230123012123012303030301242301230121230123030303012423012301212301230303030124230123012123012303030301242301230121230123030303;;CP=2;;O;;
####################################################################################################################################
# !!! ToDo´s !!!
#     -
#     -
####################################################################################################################################

### oberer Teil ###
package main;

use strict;
use warnings;

### HASH for all modul models ###
my %models = (
	# keys(model) => values
	"unknown" =>	{	hex_lengh		=> " ",
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
	"Elro_DB200_/_unitec" =>	{	hex_lengh		=> "8",
															Protocol		=> "41",
															doubleCode	=> "yes"
														},
	"KANGTAI" =>	{	hex_lengh		=> "8",
									Protocol		=> "42",
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
	$hash->{AttrList}		= "repeats:1,2,3,4,5,6,7,8,9 IODev do_not_notify:1,0 ignore:0,1 showtime:1,0 model:".join(",", sort keys %models) . " $main::readingFnAttributes";
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


#############################
sub Define($$) {
	my ($hash, $def) = @_;
	my @a = split("[ \t][ \t]*", $def);

	# Argument											0	   	1					2		    	3						4
	return "wrong syntax: define <name> SD_BELL <Protocol> <HEX-Value> <optional IODEV>" if(int(@a) < 3 || int(@a) > 5);
	return "wrong <protocol> $a[2]" if not($a[2] =~ /^(?:14|15|32|41|42|57|79)/s);
	### checks ###
	return "wrong HEX-Value! Protocol $a[2] HEX-Value to short | long or not HEX (0-9 | a-f | A-F){3,8}" if (not $a[3] =~ /^[0-9a-fA-F]{3,8}/s);

	
	$hash->{lastMSG} =  "";
	$hash->{bitMSG} =  "";
	my $iodevice = $a[4] if($a[4]);
	my $name = $hash->{NAME};

	$modules{SD_BELL}{defptr}{$hash->{DEF}} = $hash;
	my $ioname = $modules{SD_BELL}{defptr}{ioname} if (exists $modules{SD_BELL}{defptr}{ioname} && not $iodevice);
	$iodevice = $ioname if not $iodevice;
	
	### Attributes | model set after codesyntax ###
	my $Protocol = $a[2];
	my $hash_name;
	
		### search protocol --> model ###
	foreach my $search (keys(%models)) {
		if ($models{$search}{Protocol} == $Protocol) {
			$hash_name = $search;
			last;
		}
	}
	
	$attr{$name}{model}	= $hash_name if( not defined( $attr{$name}{model} ) );	
	$attr{$name}{room}	= "SD_BELL"	if( not defined( $attr{$name}{room} ) );
	
	AssignIoPort($hash, $iodevice);
}

###################################
sub Set($$$@) {
	my ( $hash, $name, @a ) = @_;
	my $cmd = $a[0];
	my $ioname = $hash->{IODev}{NAME};
	my $model = AttrVal($name, "model", "unknown");
	my @split = split(" ", $hash->{DEF});
	my $protocol = $split[0];
	my $repeats = AttrVal($name,'repeats', '5');
	my $ret = undef;
	
	if ($hash->{bitMSG} ne "") {
		if ($cmd eq "?") {
			$ret .= "ring:noArg";
		} else {
			my $msg = "P$protocol#" . $hash->{bitMSG};
			$msg .= "#R$repeats";
			Log3 $name, 4, "$ioname: $name sendMsg=$msg";

			if ($cmd ne "?") {
				$cmd = "ring";
			}				

			Log3 $name, 3, "$ioname: $name set $cmd" if ($cmd ne "?");
			IOWrite($hash, 'sendMsg', $msg);
		}
	} else {
		return $ret;
	}

	readingsSingleUpdate($hash, "state" , $cmd, 1) if ($cmd ne "?");
	return $ret;
}

#####################################
sub Undef($$) {
	my ($hash, $name) = @_;
	delete($modules{SD_BELL}{defptr}{$hash->{DEF}})
		if(defined($hash->{DEF}) && defined($modules{SD_BELL}{defptr}{$hash->{DEF}}));
	return undef;
}


###################################
sub Parse($$) {
	my ($iohash, $msg) = @_;
	my $ioname = $iohash->{NAME};
	my ($protocol,$rawData) = split("#",$msg);
	$protocol=~ s/^[u|U|P](\d+)/$1/;		# extract protocol ID, $1 = ID
	my $hlen = length($rawData);
	my $blen = $hlen * 4;
	my $bitData = unpack("B$blen", pack("H$hlen", $rawData));
	my $hash_name;
	
	### search protocol --> model ###
	foreach my $search (keys(%models)) {
		if ($models{$search}{Protocol} == $protocol) {
			$hash_name = $search;
			last;
		}
	}
	
	Log3 $iohash, 4, "$ioname: SD_BELL_Parse protocol $protocol $hash_name doubleCode=".$models{$hash_name}{doubleCode}.", bitData $bitData";
	
	my $def;
	my $deviceCode = $rawData;
	my $devicedef;
	my $state;
	
	if (!$def) {
		$devicedef = $protocol . " " .$deviceCode;
		$def = $modules{SD_BELL}{defptr}{$devicedef};
	}
	
	$modules{SD_BELL}{defptr}{ioname} = $ioname;

	Log3 $iohash, 4, "$ioname: SD_BELL_Parse device $devicedef found" if($def);

	if(!$def) {
		Log3 $iohash, 1, "$ioname: SD_BELL_Parse UNDEFINED BELL detected, Protocol ".$protocol." code " . $deviceCode;
		return "UNDEFINED SD_BELL_$deviceCode SD_BELL $protocol $deviceCode";
	}

	my $hash = $def;
	my $name = $hash->{NAME};
	$hash->{lastMSG} = $rawData;
	$hash->{bitMSG} = $bitData;

	my $model = AttrVal($name, "model", "unknown");
	$state = "ring";
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
	my $hex_lengh = length(InternalVal($name, "lastMSG", "0"));
	
	#Log3 $name, 3, "SD_BELL_Attr cmd=$cmd attrName=$attrName attrValue=$attrValue oldmodel=$oldmodel";
	
	if ($cmd eq "set" && $attrName eq "model" && $attrValue ne $oldmodel) {		### set new attr
		return "ERROR! You want to choose the $oldmodel model to $attrValue.\nPlease check your selection.\nRAWMSG is to short!" if ($models{$attrValue}{hex_lengh} > $hex_lengh);	# variants one
		return "ERROR! You want to choose the $oldmodel model to $attrValue.\nPlease check your selection.\nRAWMSG is to long!" if ($models{$attrValue}{hex_lengh} < $hex_lengh);		# variants two
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
	<li>Heidemann HX BELL  [Protocol 14]</li>
	<li>wireless doorbell TCM 234759 Tchibo  [Protocol 15]</li>
	<li>FreeTec PE-6946  [Protocol 32]</li>
	<li>Elro (Smartwares) Doorbell DB200 / 16 melodies - unitec Modell:98156+98YK [Protocol 41]</li>
	<li>m-e doorbell fuer FG- and Basic-Serie  [Protocol 57]</li>
	<li>VTX-BELL_Funkklingel  [Protocol 79]</li>
	</ul><br><br>

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
	<li>Heidemann HX BELL  [Protocol 14]</li>
	<li>wireless doorbell TCM 234759 Tchibo  [Protocol 15]</li>
	<li>FreeTec PE-6946  [Protocol 32]</li>
	<li>Elro (Smartwares) Doorbell DB200 / 16 melodies - unitec Modell:98156+98YK [Protocol 41]</li>
	<li>m-e doorbell fuer FG- und Basic-Serie  [Protocol 57]</li>
	<li>VTX-BELL_Funkklingel  [Protocol 79]</li>
	</ul><br><br>

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
