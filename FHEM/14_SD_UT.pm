##############################################
# $Id: 14_SD_UT.pm 32 2016-04-02 14:00:00 v3.2-dev $
#
# The file is part of the SIGNALduino project.
# The purpose of this module is universal support for devices.
# 2016 - 1.fhemtester | 2018 - HomeAuto_User & elektron-bbs
#
# - unitec Modul alte Variante bis 20180901 (Typ unitec-Sound) --> keine MU MSG!
# - unitec Funkfernschalterset (Typ uniTEC_48110) ??? EIM-826 Funksteckdosen --> keine MU MSG!
####################################################################################################################################
# - unitec remote door reed switch 47031 (Typ Unitec_47031) [Protocol 30] and [additionally Protocol 83] (sync -30)  (1 = on | 0 = off)
#{     FORUM: https://forum.fhem.de/index.php/topic,43346.msg353144.html#msg353144
#     8 DIP-switches for deviceCode (1-8) | 3 DIP-switches for zone (9-11) | 1 DIP-switch unknown (12) | baugleich FRIEDLAND SU4F zwecks gleichem Platinenlayout + Jumper
#     Kopplung an Unitec 47121 (Zone 1-6) | Unitec 47125 (Zone 1-2) | Friedland (Zone 1)
#     Adresse: 95 - öffnen?
#     get sduino_dummy raw MU;;P0=309;;P1=636;;P2=-690;;P3=-363;;P4=-10027;;D=012031203120402031312031203120312031204020313120312031203120312040203131203120312031203120402031312031203120312031204020313120312031203120312040203131203120312031203120402031312031203120312031204020313120312031203120312040203131203120312030;;CP=0;;O;;
#     Adresse: 00 - Gehäuse geöffnet?
#}    get sduino_dummy raw MU;;P0=684;;P1=-304;;P2=-644;;P3=369;;P4=-9931;;D=010101010101010232323104310101010101010102323231043101010101010101023232310431010101010101010232323104310101010101010102323231043101010101010101023232310431010101010101010232323104310101010101010102323231043101010101010101023232310431010100;;CP=0;;O;;
####################################################################################################################################
# - Westinghouse Deckenventilator (Typ HT12E | remote with 5 buttons without SET | Buttons_five ??? 7787100 ???) [Protocol 29] and [additionally Protocol 30] (sync -35) (1 = off | 0 = on)
#{    FORUM: https://forum.fhem.de/index.php/topic,58397.960.html | https://forum.fhem.de/index.php/topic,53282.30.html
#     Adresse e | 1110 (off|off|off|on): fan_off
#     get sduino_dummy raw MU;;P0=250;;P1=-492;;P2=166;;P3=-255;;P4=491;;P5=-8588;;D=052121212121234121212121234521212121212341212121212345212121212123412121212123452121212121234121212121234;;CP=0;;
#     Adresse e | 1110 (off|off|off|on): fan low speed
#}    get sduino_dummy raw MU;;P0=-32001;;P1=224;;P2=-255;;P3=478;;P4=-508;;P6=152;;P7=-8598;;D=01234141414641414141414123712341414141414141414141237123414141414141414141412371234141414141414141414123712341414141414141414141237123414141414141414141412371234141414141414141414123712341414141414141414141237123414141414141414141412371234141414141414141;;CP=1;;R=108;;O;;
####################################################################################################################################
# - Westinghouse Deckenventilator (Typ [M1EN compatible HT12E] example Delancey | remote RH787T with 9 buttons + SET) [Protocol 83] and [additionally Protocol 30] (sync -36) (1 = off | 0 = on)
#{    Adresse 0 | 0000 (on|on|on|on): I - fan minimum speed
#     get sduino_dummy raw MU;;P0=388;;P1=-112;;P2=267;;P3=-378;;P5=585;;P6=-693;;P7=-11234;;D=0123035353535356262623562626272353535353562626235626262723535353535626262356262627235353535356262623562626272353535353562626235626262723535353535626262356262627235353535356262623562626272353535353562626235626262723535353535626262356262627235353535356262;;CP=2;;R=43;;O;;
#     Adresse 8 | 1000 (off|on|on|on): I - fan minimum speed
#     get sduino_dummy raw MU;;P0=-11250;;P1=-200;;P2=263;;P3=-116;;P4=-374;;P5=578;;P6=-697;;D=1232456245454562626245626262024562454545626262456262620245624545456262624562626202456245454562626245626262024562454545626262456262620245624545456262624562626202456245454562626245626262024562454545626262456262620245624545456262624562626202456245454562626;;CP=2;;R=49;;O;;
#     Adresse c | 1100 (off|off|on|on): fan_off
#     get sduino_dummy raw MU;;P0=-720;;P1=235;;P2=-386;;P3=561;;P4=-11254;;D=01230141230101232301010101012301412301012323010101010123014123010123230101010101010141230101232301010101010101412301012323010101010101014123010123230101010101010;;CP=1;;R=242;;
#     Adresse c | 1100 (off|off|on|on): fan_off
#}    get sduino_dummy raw MU;;P0=-11230;;P1=258;;P2=-390;;P3=571;;P4=-699;;D=0123414123234141414141234101234141232341414141412341012341412323414141414123410123414123234141414141234101234141232341414141412341012341412323414141414123410123414123234141414141234101234141232341414141412341012341412323414141414123410123414123234141414;;CP=1;;R=246;;O;;
####################################################################################################################################
# - Remote control SA-434-1 mini 923301 [Protocol 81] and [additionally Protocol 83 + Protocol 86]
#{    one Button, 434 MHz
#     protocol like HT12E
#     10 DIP-switches for address:
#     switch                                hex     bin
#     ------------------------------------------------------------
#     1-10 on                               004     0000 0000 0100
#     1 off, 9-10 on                        804     1000 0000 0100
#     4/8 off, 9-3 5-7 9-10 on              114     0001 0001 0100
#     4/8 off, 9-3 5-7 on, 9 off, 10 on     115     0001 0001 0101
#     4/8 off, 9-3 5-7 on, 9 on, 10 off     11C     0001 0001 1100
#     4/8 off, 9-3 5-7 on, 9-10 off         11D     0001 0001 1101
#     ------------------------------------------------------------
#     pilot 12 bitlength, from that 1/3 bitlength high: -175000, 500   -35, 1
#     one:                                                -1000, 500    -2, 1
#     zero:                                                -500, 1000   -1, 2
#
#     get sduino_dummy raw MU;;P0=-1756;;P1=112;;P2=-11752;;P3=496;;P4=-495;;P5=998;;P6=-988;;P7=-17183;;D=0123454545634545456345634563734545456345454563456345637345454563454545634563456373454545634545456345634563734545456345454563456345637345454563454545634563456373454545634545456345634563734545456345454563456345637345454563454545634563456373454545634545456;;CP=3;;R=0;;
#}    get sduino_dummy raw MU;;P0=-485;;P1=188;;P2=-6784;;P3=508;;P5=1010;;P6=-974;;P7=-17172;;D=0123050505630505056305630563730505056305050563056305637305050563050505630563056373050505630505056305630563730505056305050563056305637305050563050505630563056373050505630505056305630563730505056305050563056305637305050563050505630563056373050505630505056;;CP=3;;R=0;;
####################################################################################################################################
# - QUIGG GT-7000 Funk-Steckdosendimmer | transmitter QUIGG_DMV - receiver DMV-7009AS  [Protocol 34]
#{    https://github.com/RFD-FHEM/RFFHEM/issues/195
#     nibble 0-2 -> Ident | nibble 3-4 -> Tastencode
#     get sduino_dummy raw MU;;P0=-5476;;P1=592;;P2=-665;;P3=1226;;P4=-1309;;D=01232323232323232323232323412323412323414;;CP=3;;R=1;;
#}    Send Adresse FFF funktioniert nicht 100%ig!
####################################################################################################################################
# - Novy_Pureline_6830 kitchen hood [Protocol 86]
#{    https://github.com/RFD-FHEM/RFFHEM/issues/331
#     nibble 0-1 -> Ident | nibble 2-4 -> Tastencode
#     light on/off button
#     get sduino_dummy raw MU;;P0=710;;P1=353;;P2=-403;;P4=-761;;P6=-16071;;D=20204161204120412041204120414141204120202041612041204120412041204141412041202020416120412041204120412041414120412020204161204120412041204120414141204120202041;;CP=1;;R=40;;
#     + button
#     get sduino_dummy raw MU;;P0=22808;;P1=-24232;;P2=701;;P3=-765;;P4=357;;P5=-15970;;P7=-406;;D=012345472347234723472347234723454723472347234723472347234547234723472347234723472345472347234723472347234723454723472347234723472347234;;CP=4;;R=39;;
#     - button
#     get sduino_dummy raw MU;;P0=-8032;;P1=364;;P2=-398;;P3=700;;P4=-760;;P5=-15980;;D=0123412341234123412341412351234123412341234123414123512341234123412341234141235123412341234123412341412351234123412341234123414123;;CP=1;;R=40;;
#     power button
#     get sduino_dummy raw MU;;P0=-756;;P1=718;;P2=354;;P3=-395;;P4=-16056;;D=01020202310231310202423102310231023102310202023102313102024231023102310231023102020231023131020242310231023102310231020202310231310202;;CP=2;;R=41;;
#     novy button
#}    get sduino_dummy raw MU;;P0=706;;P1=-763;;P2=370;;P3=-405;;P4=-15980;;D=0123012301230304230123012301230123012303042;;CP=2;;R=42;;
####################################################################################################################################
# - CAME Drehtor Antrieb - remote CAME_TOP_432EV [Protocol 86] and [additionally Protocol 81]
#{    https://github.com/RFD-FHEM/RFFHEM/issues/151
#     nibble 0-1 -> Ident | nibble 2 -> Tastencode
#}    get sduino_dummy raw MU;;P0=-322;;P1=136;;P2=-15241;;P3=288;;P4=-735;;P6=723;;D=0123434343064343430643434306234343430643434306434343062343434306434343064343430623434343064343430643434306234343430643434306434343062343434306434343064343430623434343064343430643434306234343430643434306434343062343434306434343064343430;;CP=3;;R=27;;
####################################################################################################################################
# - Hoermann HS1-868-BS
#{    https://github.com/RFD-FHEM/RFFHEM/issues/344 | https://github.com/RFD-FHEM/RFFHEM/issues/149
#               iiii iiii iiii iiii iiii iiii iiii bbbb
#			0000 0000 1111 0110 0010 1010 1001 1100 0000 0001 1100 (HS1-868-BS)
#}    get sduino_dummy raw MU;;P0=-578;;P1=1033;;P2=506;;P3=-1110;;P4=13632;;D=0101010232323101040101010101010101023232323102323101010231023102310231010232323101010101010101010232323101040101010101010101023232323102323101010231023102310231010232323101010101010101010232323101040101010101010101023232323102323101010231023102310231010;;CP=2;;R=77;;
####################################################################################################################################
# - Hoermann HSM4
#{    https://forum.fhem.de/index.php/topic,71877.msg642879.html (HSM4, Taste 1-4)
#               iiii iiii iiii iiii iiii iiii iiii bbbb
#     0000 0000 1110 0110 1011 1110 1001 0001 0000 0111 1100 (HSM4 Taste A)
#     0000 0000 1110 0110 1011 1110 1001 0001 0000 1011 1100 (HSM4 Taste B)
#     0000 0000 1110 0110 1011 1110 1001 0001 0000 1110 1100 (HSM4 Taste C)
#     0000 0000 1110 0110 1011 1110 1001 0001 0000 1101 1100 (HSM4 Taste D)
#}    get sduino_dummy raw MU;;P0=-3656;;P1=12248;;P2=-519;;P3=1008;;P4=506;;P5=-1033;;D=01232323232323232324545453232454532453245454545453245323245323232453232323245453245454532321232323232323232324545453232454532453245454545453245323245323232453232323245453245454532321232323232323232324545453232454532453245454545453245323245323232453232323;;CP=4;;R=48;;O;;
####################################################################################################################################
# !!! ToDo´s !!!
#     - 
#     - doppelte Logeinträge bei zutreffen von 2 Protokollen?
####################################################################################################################################

package main;

use strict;
use warnings;
no warnings 'portable';  # Support for 64-bit ints required
#use SetExtensions;

#$| = 1;		#Puffern abschalten, Hilfreich für PEARL WARNINGS Search

### HASH for all modul models ###
my %models = (
	# keys(model) => values
	"Buttons_five" =>	{ "011111"	=> "1_fan_low_speed",
						  "111111" 	=> "2_fan_medium_speed",
						  "111101" 	=> "3_fan_high_speed",
						  "101111" 	=> "light_on_off",
						  "111110"	=> "fan_off",
						  Protocol 	=> "P29",
						  Typ			=> "remote"
						},
	"CAME_TOP_432EV" => 	{ "10"		=> "left_button",
							  "01"		=> "right_button",
							  Protocol	=> "P86",
							  Typ		=> "remote"
							},
	"HS1_868_BS" =>	{ "0"		=> "send",
					  Protocol	=> "P69",
					  Typ		=> "remote"
					},
	"HSM4" =>	{ "0111"	=> "button_1",
				  "1011" 	=> "button_2",
				  "1110" 	=> "button_3",
				  "1101" 	=> "button_4",
				  Protocol 	=> "P69",
				  Typ		=> "remote"
				},
	"Novy_Pureline_6830" => { "011101000111"	=> "light_on_off_1",	# need USERTEST!!! one variants, not three
							  "11010001"		=> "light_on_off_2",	# need USERTEST!!! one variants, not three
							  "01110111"		=> "light_on_off_3",	# need USERTEST!!! one variants, not three
							  "0101"			=> "+_button",
							  "0110"			=> "-_button",
							  "011101001111" 	=> "power_button",
							  "0100"			=> "novy_button",
							  Protocol			=> "P86",
							  Typ				=> "remote"
							},
	"QUIGG_DMV" =>  		{ "11101110"	=> "Ch1_on",
							  "11111111"	=> "Ch1_off",
							  "01101100" 	=> "Ch2_on",
							  "01111101" 	=> "Ch2_off",
							  "10101111" 	=> "Ch3_on",
							  "10111110" 	=> "Ch3_off",
							  "00101101" 	=> "Ch4_on",
							  "00111100" 	=> "Ch4_off",
							  "00001111" 	=> "Master_on",
							  "00011110" 	=> "Master_off",
							  "00010100" 	=> "Unknown_on",
							  "00000101" 	=> "Unknown_off",
							  Protocol		=> "P34",
							  Typ			=> "remote"
							},
	"RH787T" =>	{ "110111"	=> "1_fan_minimum_speed",
				  "110101" 	=> "2_fan_low_speed",
				  "101111"	=> "3_fan_medium_low_speed",
				  "100111"	=> "4_fan_medium_speed",
				  "011101"	=> "5_fan_medium_high_speed",
				  "011111"	=> "6_fan_high_speed",
				  "111011"	=> "fan_direction",
				  "111101"	=> "fan_off",
				  "111110"	=> "light_on_off",
				  "101101"	=> "set",
				  Protocol	=> "P83",
				  Typ		=> "remote"
				},
	"SA_434_1_mini" =>	{ "0"		=> "send",
						  Protocol	=> "P81",
						  Typ		=> "remote"
						},
	"Unitec_47031" =>	{ Protocol	=> "P30",
						  Typ		=> "switch"
						},
	"unknown" =>		{ Protocol	=> "any",
						  Typ		=> "not_exist"
						}
);

#############################
sub SD_UT_Initialize($) {
	my ($hash) = @_;
	$hash->{Match}		= "^P(?:29|30|34|69|81|83|86)#.*";
	$hash->{DefFn}		= "SD_UT_Define";
	$hash->{UndefFn}	= "SD_UT_Undef";
	$hash->{ParseFn}	= "SD_UT_Parse";
	$hash->{SetFn}		= "SD_UT_Set";
	$hash->{AttrFn}		= "SD_UT_Attr";
	$hash->{AttrList}	= "IODev debug:0,1 do_not_notify:1,0 ignore:0,1 showtime:1,0 model:".join(",", sort keys %models)." " .
						"$readingFnAttributes ";
	$hash->{AutoCreate}	={"SD_UT.*" => {ATTR => "model:unknown", FILTER => "%NAME", autocreateThreshold => "2:180"}};
	#$hash->{noAutocreatedFilelog} = 1;		### Bug? bei Aktivierung wird keine AutoCreate Attr berücksichtigt! ###
}

#############################
sub SD_UT_Define($$) {
	my ($hash, $def) = @_;
	my @a = split("[ \t][ \t]*", $def);

	### checks all ###
	#Log3 $hash->{NAME}, 3, "SD_UT: Define arg0=$a[0] arg1=$a[1] arg2=$a[2]" if($a[0] && $a[1] && $a[2] && !$a[3]);
	#Log3 $hash->{NAME}, 3, "SD_UT: Define arg0=$a[0] arg1=$a[1] arg2=$a[2] arg3=$a[3]" if($a[0] && $a[1] && $a[2] && $a[3] && !$a[4]);
	#Log3 $hash->{NAME}, 3, "SD_UT: Define arg0=$a[0] arg1=$a[1] arg2=$a[2] arg3=$a[3] arg4=$a[4]" if($a[0] && $a[1] && $a[2] && $a[3] && $a[4]);
	
	# Argument					   0	 1		2		3				4
	return "wrong syntax: define <name> SD_UT <model> <HEX-Value> <optional IODEV>" if(int(@a) < 3 || int(@a) > 5);
	return "wrong <model> $a[2]\n\n(allowed modelvalues: " . join(" | ", sort keys %models).")" if $a[2] && ( !grep { $_ eq $a[2] } %models );
	### checks unknown ###
	return "wrong define: <model> $a[2] need no HEX-Value to define!" if($a[2] eq "unknown" && $a[3] && length($a[3]) >= 1);
	### checks Westinghouse_Delancey RH787T ###
	return "wrong HEX-Value! $a[2] have one HEX-Value" if ($a[2] eq "RH787T" && length($a[3]) > 1);
	return "wrong HEX-Value! ($a[3]) $a[2] HEX-Value are not (0-9 | a-f | A-F)" if ($a[2] eq "RH787T" && not $a[3] =~ /^[0-9a-fA-F]{1}/s);
	### checks Westinghouse	Buttons_five ###
	return "wrong HEX-Value! $a[2] have one HEX-Value" if ($a[2] eq "Buttons_five" && length($a[3]) > 1);
	return "wrong HEX-Value! ($a[3]) $a[2] HEX-Value are not (0-9 | a-f | A-F)" if ($a[2] eq "Buttons_five" && not $a[3] =~ /^[0-9a-fA-F]{1}/s);
	### checks SA_434_1_mini ###
	return "wrong HEX-Value! ($a[3]) $a[2] HEX-Value to short | long or not HEX (0-9 | a-f | A-F){3}" if ($a[2] eq "SA_434_1_mini" && not $a[3] =~ /^[0-9a-fA-F]{3}/s);
	### checks Unitec_47031 ###
	return "wrong HEX-Value! ($a[3]) $a[2] HEX-Value to short | long or not HEX (0-9 | a-f | A-F){2}" if ($a[2] eq "Unitec_47031" && not $a[3] =~ /^[0-9a-fA-F]{2}/s);
	### checks QUIGG_DMV ###
	return "wrong HEX-Value! ($a[3]) $a[2] HEX-Value to short | long or not HEX (0-9 | a-f | A-F){3}" if ($a[2] eq "QUIGG_DMV" && not $a[3] =~ /^[0-9a-fA-F]{3}/s);
	### checks CAME_TOP_432EV ###
	return "wrong HEX-Value! ($a[3]) $a[2] HEX-Value to short | long or not HEX (0-9 | a-f | A-F){2}" if ($a[2] eq "CAME_TOP_432EV" && not $a[3] =~ /^[0-9a-fA-F]{2}/s);
	### checks Novy_Pureline_6830 ###
	return "wrong HEX-Value! ($a[3]) $a[2] HEX-Value to short | long or not HEX (0-9 | a-f | A-F){2}" if ($a[2] eq "Novy_Pureline_6830" && not $a[3] =~ /^[0-9a-fA-F]{2}/s);
	### checks Hoermann HS1-868-BS ###
	return "wrong HEX-Value! ($a[3]) $a[2] HEX-Value to short | long or not HEX (0-9 | a-f | A-F){9}" if ($a[2] eq "HS1_868_BS" && not $a[3] =~ /^[0-9a-fA-F]{9}/s);
	### checks Hoermann HSM4 ###
	return "wrong HEX-Value! ($a[3]) $a[2] HEX-Value to short | long or not HEX (0-9 | a-f | A-F){7}" if ($a[2] eq "HSM4" && not $a[3] =~ /^[0-9a-fA-F]{7}/s);																													   
	
	$hash->{lastMSG} =  "no data";
	$hash->{bitMSG} =  "no data";
	my $iodevice = $a[4] if($a[4]);
	my $name = $hash->{NAME};

	$modules{SD_UT}{defptr}{$hash->{DEF}} = $hash;
	my $ioname = $modules{SD_UT}{defptr}{ioname} if (exists $modules{SD_UT}{defptr}{ioname} && not $iodevice);
	$iodevice = $ioname if not $iodevice;
	
	### Attributes | model set after codesyntax ###
	my $devicetyp = $a[2];
	if ($devicetyp eq "unknown") {
		$attr{$name}{model}	= "unknown"	if( not defined( $attr{$name}{model} ) );
	} else {
		$attr{$name}{model}	= $devicetyp	if( not defined( $attr{$name}{model} ) );	
	}
	$attr{$name}{room}	= "SD_UT"	if( not defined( $attr{$name}{room} ) );
	
	AssignIoPort($hash, $iodevice);
}

###################################
sub SD_UT_Set($$$@) {
	my ( $hash, $name, @a ) = @_;
	my $cmd = $a[0];
	my $ioname = $hash->{IODev}{NAME};
	my $model = AttrVal($name, "model", "unknown");
	my $debug = AttrVal($name,"debug",0);
	my $ret = undef;
	my $msg = undef;
	my $msgEnd = undef;

	my $value = "";		# value from models cmd
	my $save = "";		# bits from models cmd

	Debug " $ioname: SD_UT_Set attr_model=$model name=$name (before check)" if($debug && $cmd ne "?");
	
	############ Westinghouse_Delancey RH787T ############
	if ($model eq "RH787T" && $cmd ne "?") {

		my @definition = split(" ", $hash->{DEF});									# split adress from def
		my $adr = sprintf( "%04b", hex($definition[1])) if ($name ne "unknown");	# argument 1 - adress to binary with 4 digits

		$msg = $models{$model}{Protocol} . "#0" . $adr ."1";
		$msgEnd = "#R9";
	
	############ Westinghouse Buttons_five ############
	} elsif ($model eq "Buttons_five" && $cmd ne "?") {
		
		my @definition = split(" ", $hash->{DEF});									# split adress from def
		my $adr = sprintf( "%04b", hex($definition[1])) if ($name ne "unknown");	# argument 1 - adress to binary with 4 digits

		$msg = $models{$model}{Protocol} . "#";
		$msgEnd .= "11".$adr."#R9";

	############ SA_434_1_mini ############
	} elsif ($model eq "SA_434_1_mini" && $cmd ne "?") {
		
		my @definition = split(" ", $hash->{DEF});																		# split adress from def
		my $bitData = sprintf( "%012b", hex($definition[1])) if ($name ne "unknown");	# argument 1 - adress to binary with 4 digits
		$msg = $models{$model}{Protocol} . "#" . $bitData . "#R5";										# !!! Anzahl Wiederholungen noch klären !!!

		Debug " $ioname: SD_UT_Set attr_model=$model msg=$msg" if($debug);
	############ QUIGG_DMV ############
	} elsif ($model eq "QUIGG_DMV" && $cmd ne "?") {

		my @definition = split(" ", $hash->{DEF});									# split adress from def
		my $adr = sprintf( "%012b", hex($definition[1])) if ($name ne "unknown");	# argument 1 - adress to binary with 4 digits

		$msg = $models{$model}{Protocol} . "#P" . $adr;
		$msgEnd = "#R1";															# !!! Anzahl Wiederholungen noch klären !!!

	############ Novy_Pureline_6830 ############
	} elsif ($model eq "Novy_Pureline_6830" && $cmd ne "?") {

		my @definition = split(" ", $hash->{DEF});									# split adress from def
		my $adr = sprintf( "%08b", hex($definition[1])) if ($name ne "unknown");	# argument 1 - adress to binary with 4 digits

		$msg = $models{$model}{Protocol} . "#" . $adr;
		$msgEnd = "#R9";															# !!! Anzahl Wiederholungen noch klären !!!

	############ CAME_TOP_432EV ############
	} elsif ($model eq "CAME_TOP_432EV" && $cmd ne "?") {

		my @definition = split(" ", $hash->{DEF});									# split adress from def
		my $adr = sprintf( "%08b", hex($definition[1])) if ($name ne "unknown");	# argument 1 - adress to binary with 4 digits

		$msg = $models{$model}{Protocol} . "#" . $adr;
		$msgEnd = "#R9";															# !!! Anzahl Wiederholungen noch klären !!!

	############ Hoermann HS1-868-BS ############
	} elsif ($model eq "HS1_868_BS" && $cmd ne "?") {
		my @definition = split(" ", $hash->{DEF});																		# split adress from def
		my $bitData = "00000000";
		$bitData .= sprintf( "%036b", hex($definition[1])) if ($name ne "unknown");	# argument 1 - adress to binary with 7 digits
		$msg = $models{$model}{Protocol} . "#" . $bitData . "#R3";										# !!! Anzahl Wiederholungen noch klären !!!
		Debug " $ioname: SD_UT_Set attr_model=$model msg=$msg" if($debug);
	############ Hoermann HSM4 ############
	} elsif ($model eq "HSM4" && $cmd ne "?") {
		my @definition = split(" ", $hash->{DEF});									# split adress from def
		my $adr = sprintf( "%028b", hex($definition[1])) if ($name ne "unknown");	# argument 1 - adress to binary with 7 digits
		$msg = $models{$model}{Protocol} . "#00000000" . $adr;
		$msgEnd .= "1100#R3";
	}

	Debug " $ioname: SD_UT_Set attr_model=$model msg=$msg msgEnd=$msgEnd" if($debug && defined $msgEnd);
	
	if ($cmd eq "?") {
		### create setlist ###
		foreach my $keys (sort keys %{ $models{$model}}) {	
			if ( $keys =~ /^[0-1]{1,}/s ) {
				$ret.= $models{$model}{$keys}.":noArg ";
			}
		}
	} else {
	
		if (defined $msgEnd) {
			### if cmd, set bits ###
			foreach my $keys (sort keys %{ $models{$model}}) {
				if ( $keys =~ /^[0-1]{1,}/s ) {
					$save = $keys;
					$value = $models{$model}{$keys};
					last if ($value eq $cmd);
				}
			}

			$msg .= $save.$msgEnd;
			Debug " $ioname: SD_UT_Set attr_model=$model msg=$msg cmd=$cmd value=$value (cmd loop)" if($debug);
		}
	
		readingsSingleUpdate($hash, "LastAction", "send", 0) if ($models{$model}{Typ} eq "remote");
		readingsSingleUpdate($hash, "state" , $cmd, 1);
		
		IOWrite($hash, 'sendMsg', $msg);
		
		## for hex Check ##
		my @split = split("#", $msg);
		my $hexvalue = $split[1];
		$hexvalue =~ s/P+//g;									# if P parameter, replace P with nothing
		$hexvalue = sprintf("%X", oct( "0b$hexvalue" ) );
		###################

		Debug " $ioname: SD_UT_Set attr_model=$model sendMsg=$msg rawData=$hexvalue (after IOWrite)" if($debug);
		Log3 $name, 3, "$ioname: $name set $cmd";
	}
	return $ret;
}

#####################################
sub SD_UT_Undef($$) {
	my ($hash, $name) = @_;
	delete($modules{SD_UT}{defptr}{$hash->{DEF}})
		if(defined($hash->{DEF}) && defined($modules{SD_UT}{defptr}{$hash->{DEF}}));
	return undef;
}


###################################
sub SD_UT_Parse($$) {
	my ($iohash, $msg) = @_;
	my $ioname = $iohash->{NAME};
	my ($protocol,$rawData) = split("#",$msg);
	$protocol=~ s/^[u|U|P](\d+)/$1/; # extract protocol
	my $hlen = length($rawData);
	my $blen = $hlen * 4;
	my $bitData = unpack("B$blen", pack("H$hlen", $rawData));
	my $model = "unknown";
	my $SensorTyp;
	Log3 $iohash, 4, "$ioname: SD_UT protocol $protocol, bitData $bitData";
	
	my $bin;
	my $def;
	my $deviceCode;
	my $zone;			# bits for zone
	my $zoneRead;		# text for user of zone
	my $usersystem;		# text for user of system
	my $devicedef;
	my $state;
	
	my $deletecache = $modules{SD_UT}{defptr}{deletecache};
	Log3 $iohash, 5, "$ioname: SD_UT device in delete cache = $deletecache" if($deletecache && $deletecache ne "-");
	
	if ($deletecache && $deletecache ne "-") {
		fhem("delete $deletecache");				# delete new device
		fhem("delete FileLog_$deletecache");		# delete Filelog
		Log3 $iohash, 3, "$ioname: SD_UT device $deletecache delete" if($deletecache);
		$modules{SD_UT}{defptr}{deletecache} = "-";
		return "";
	}
	
	### Westinghouse Buttons_five [P29] ###
	$deviceCode = substr($rawData,2,1);
	$devicedef = "Buttons_five " . $deviceCode if(!$def && ($protocol == 29 || $protocol == 30));
	$def = $modules{SD_UT}{defptr}{$devicedef} if(!$def && ($protocol == 29 || $protocol == 30));
	### Unitec_47031 [P30] ###
	$deviceCode = substr($rawData,0,2);
	$devicedef = "Unitec_47031 " . $deviceCode if(!$def && ($protocol == 30 || $protocol == 83));
	$def = $modules{SD_UT}{defptr}{$devicedef} if(!$def && ($protocol == 30 || $protocol == 83));
	### QUIGG_DMV [P34] ###
	$deviceCode = substr($rawData,0,3);
	$devicedef = "QUIGG_DMV " . $deviceCode  if(!$def && $protocol == 34);
	$def = $modules{SD_UT}{defptr}{$devicedef}  if(!$def && $protocol == 34);
	### Remote control SA_434_1_mini 923301 [P81] ###
	$deviceCode = $rawData;
	$devicedef = "SA_434_1_mini " . $deviceCode if (!$def && ($protocol == 81 || $protocol == 83 || $protocol == 86));
	$def = $modules{SD_UT}{defptr}{$devicedef} if (!$def && ($protocol == 81 || $protocol == 83 || $protocol == 86));
	### Westinghouse_Delancey RH787T [P83] ###
	$deviceCode = substr($bitData,1,4);
	$deviceCode = sprintf("%X", oct( "0b$deviceCode" ) );
	$devicedef = "RH787T " . $deviceCode if(!$def && ($protocol == 83 || $protocol == 30));
	$def = $modules{SD_UT}{defptr}{$devicedef} if (!$def && ($protocol == 83 || $protocol == 30));
	### Novy_Pureline_6830 [P86] ###
	$deviceCode = substr($rawData,0,2);
	$devicedef = "Novy_Pureline_6830 " . $deviceCode  if(!$def && ($protocol == 86 || $protocol == 81));
	$def = $modules{SD_UT}{defptr}{$devicedef}  if(!$def && ($protocol == 86 || $protocol == 81));
	### CAME_TOP_432EV [P86] ###
	$deviceCode = substr($rawData,0,2);
	$devicedef = "CAME_TOP_432EV " . $deviceCode  if(!$def && ($protocol == 86 || $protocol == 81));
	$def = $modules{SD_UT}{defptr}{$devicedef}  if(!$def && ($protocol == 86 || $protocol == 81));
	### Remote control Hoermann HS1-868-BS [P69] ###
	$deviceCode = substr($rawData,2,9) if ($hlen >= 11);
	$devicedef = "HS1_868_BS " . $deviceCode if (!$def && $protocol == 69);
	$def = $modules{SD_UT}{defptr}{$devicedef} if (!$def && $protocol == 69);
	### Remote control Hoermann HSM4 [P69] ###
	$deviceCode = substr($rawData,2,7) if ($hlen >= 11);
	$devicedef = "HSM4 " . $deviceCode if (!$def && $protocol == 69);
	$def = $modules{SD_UT}{defptr}{$devicedef} if (!$def && $protocol == 69);
	### unknown ###
	$devicedef = "unknown" if(!$def);
	$def = $modules{SD_UT}{defptr}{$devicedef} if(!$def);
	$modules{SD_UT}{defptr}{ioname} = $ioname;

	Log3 $iohash, 4, "$ioname: SD_UT device $devicedef found (delete cache = $deletecache)" if($def && $deletecache && $deletecache ne "-");
	
	if(!$def) {
		Log3 $iohash, 1, "$ioname: SD_UT_Parse UNDEFINED sensor " . $model . " detected, code " . $deviceCode;
		return "UNDEFINED $model SD_UT $model";
	}
	
	my $hash = $def;
	my $name = $hash->{NAME};
	my $debug = AttrVal($name,"debug",0);
	$hash->{lastMSG} = $rawData;
	$hash->{bitMSG} = $bitData;
	$deviceCode = undef;				# reset for Westinghouse_Delancey
	
	$model = AttrVal($name, "model", "unknown");
	Debug " $ioname: SD_UT_Parse devicedef=$devicedef attr_model=$model protocol=$protocol state= (before check)" if($debug);
	
	############ Westinghouse_Delancey RH787T ############ Protocol 83 or 30 ############
  if ($model eq "RH787T" && ($protocol == 83 || $protocol == 30)) {
		$state = substr($bitData,6,6);
		$deviceCode = substr($bitData,1,4);

		## Check fixed bits
		my $unknown1 = substr($bitData,0,1);	# every 0
		my $unknown2 = substr($bitData,5,1);	# every 1
		if ($unknown1 ne "0" | $unknown2 ne "1") {
			Log3 $name, 3, "$ioname: $model fixed bits wrong! always bit0=0 ($unknown1) and bit5=1 ($unknown2)";
			return "";
		}

		## deviceCode conversion for User in ON or OFF ##
		my $deviceCodeUser = $deviceCode;
		$deviceCodeUser =~ s/1/off|/g;
		$deviceCodeUser =~ s/0/on|/g;
		$deviceCodeUser = substr($deviceCodeUser, 0 , length($deviceCodeUser)-1);
		$deviceCode = $deviceCode." ($deviceCodeUser)";

	############ Westinghouse Buttons_five ############ Protocol 29 or 30 ############
	} elsif ($model eq "Buttons_five" && ($protocol == 29 || $protocol == 30)) {
		$state = substr($bitData,0,6);
		$deviceCode = substr($bitData,8,4);

		## Check fixed bits
		my $unknown1 = substr($bitData,6,1);	# every 1
		my $unknown2 = substr($bitData,7,1);	# every 1
		if ($unknown1 ne "1" | $unknown2 ne "1") {
			Log3 $name, 3, "$ioname: $model fixed bits wrong! always bit6=1 ($unknown1) and bit7=1 ($unknown2)";
			return "";
		}

		## deviceCode conversion for User in ON or OFF ##
		my $deviceCodeUser = $deviceCode;
		$deviceCodeUser =~ s/1/off|/g;
		$deviceCodeUser =~ s/0/on|/g;
		$deviceCodeUser = substr($deviceCodeUser, 0 , length($deviceCodeUser)-1);
		$deviceCode = $deviceCode." ($deviceCodeUser)";

	############ Unitec_47031 ############ Protocol 30 or 83 ############
	} elsif ($model eq "Unitec_47031" && ($protocol == 30 || $protocol == 83)) {
		$state = substr($bitData,11,1);		# muss noch 100% verifiziert werden !!!

		## deviceCode conversion for User in ON or OFF ##
		$deviceCode = substr($bitData,0,8);		
		my $deviceCodeUser = $deviceCode;
		$deviceCodeUser =~ s/1/on|/g;
		$deviceCodeUser =~ s/0/off|/g;
		$deviceCodeUser = substr($deviceCodeUser, 0 , length($deviceCodeUser)-1);
		$deviceCode = $deviceCode." ($deviceCodeUser)";
		
		## zone conversion for User in ON or OFF ##
		$zone = substr($bitData,8,3);
		my $zoneUser = $zone;
		$zoneUser =~ s/1/on|/g;
		$zoneUser =~ s/0/off|/g;
		$zoneUser = substr($zoneUser, 0 , length($zoneUser)-1);
		
		$zoneRead = $zone." ($zoneUser) - Zone ";
		
		# Anmeldung an Profi-Alarmanzentrale 47121
		if (oct("0b".$zone) < 6 ) {
			$zoneRead.= (oct("0b".$zone)+1);
			$usersystem = "Unitec 47121";
		# other variants
		} else {
			$zoneRead.= (oct("0b".$zone)-5);
			# Anmeldung an Basis-Alarmanzentrale 47125 | Sirenen-System (z.B. ein System ohne separate Funk-Zentrale)
			$usersystem = "Unitec 47125 or Friedland" if (oct("0b".$zone) == 6);
			# Anmeldung an Basis-Alarmanzentrale 47125
			$usersystem = "Unitec 47125" if (oct("0b".$zone) == 7);
		}
		
		Debug " $ioname: SD_UT_Parse devicedef=$devicedef attr_model=$model protocol=$protocol deviceCode=$deviceCode state=$state Zone=$zone" if($debug);
	############ SA_434_1_mini ############ Protocol 81 ############
	} elsif ($model eq "SA_434_1_mini" && ($protocol == 81 || $protocol == 83 || $protocol == 86)) {
		$state = "receive";
		
		Debug " $ioname: SD_UT_Parse devicedef=$devicedef attr_model=$model protocol=$protocol state=$state" if($debug);
	############ QUIGG_DMV ############ Protocol 34 ############
	} elsif ($model eq "QUIGG_DMV" && $protocol == 34) {
		$state = substr($bitData,12,8);
		$deviceCode = substr($bitData,0,12);

	############ Novy_Pureline_6830 ############ Protocol 86 ############
	} elsif ($model eq "Novy_Pureline_6830" && ($protocol == 86 || $protocol == 81)) {
		$state = substr($bitData,8);
		$deviceCode = substr($bitData,0,8);

	############ CAME_TOP_432EV ############ Protocol 86 ############
	} elsif ($model eq "CAME_TOP_432EV" && ($protocol == 86 || $protocol == 81)) {
		$state = substr($bitData,8);
		$deviceCode = substr($bitData,0,8);

	############ Hoermann HS1-868-BS ############ Protocol 69 ############
	} elsif ($model eq "HS1_868_BS" && $protocol == 69) {
		$state = "receive";
		$deviceCode = substr($bitData,8,28);
	
	############ Hoermann HSM4 ############ Protocol 69 ############
	} elsif ($model eq "HSM4" && $protocol == 69) {
		$state = substr($bitData,36,4);
		$deviceCode = substr($bitData,8,28);
	
		############ unknown ############
	} else {
		readingsSingleUpdate($hash, "state", "???", 0);
		readingsSingleUpdate($hash, "unknownMSG", $bitData."  (protocol: ".$protocol.")", 1);
		Log3 $name, 3, "$ioname: SD_UT Please define your model of Device $name in Attributes!" if (AttrVal($name, "model", "unknown") eq "unknown");
		Debug " $ioname: SD_UT_Parse devicedef=$devicedef attr_model=$model protocol=$protocol rawData=$rawData, bitData=$bitData" if($debug);
	}

	Debug " $ioname: SD_UT_Parse devicedef=$devicedef attr_model=$model protocol=$protocol devicecode=$deviceCode state=$state" if($debug && ($model ne "unknown" || $model ne "Unitec_47031" || $model ne "SA_434_1_mini"));
	Debug " $ioname: SD_UT_Parse devicedef=$devicedef attr_model=$model typ=".$models{$model}{Typ}." (after check)" if($debug);
	
	if ($models{$model}{Typ} eq "remote" && ($model ne "SA_434_1_mini" || $model ne "HS1_868_BS")) {
		### identify state bits to value from hash ###
		foreach my $keys (sort keys %{ $models{$model}}) {	
			if ($keys eq $state) {
				$state = $models{$model}{$keys};
				Debug " $ioname: SD_UT_Parse devicedef=$devicedef attr_model=$model typ=".$models{$model}{Typ}." key=".$models{$model}{$keys}." (state loop)" if($debug);
				last;
			}
		}
	}
	
	readingsBeginUpdate($hash);
	readingsBulkUpdate($hash, "deviceCode", $deviceCode, 0)  if (defined($deviceCode) && $models{$model}{Typ} eq "remote" && ($model ne "SA_434_1_mini" || $model ne "HS1_868_BS"));
	readingsBulkUpdate($hash, "System-Housecode", $deviceCode, 0)  if (defined($deviceCode) && $model eq "Unitec_47031");
	readingsBulkUpdate($hash, "Zone", $zoneRead, 0) if ($model eq "Unitec_47031");
	readingsBulkUpdate($hash, "Usersystem", $usersystem, 0)  if ($model eq "Unitec_47031");
	readingsBulkUpdate($hash, "LastAction", "receive", 0)  if (defined($state) && $models{$model}{Typ} eq "remote" && ($model ne "SA_434_1_mini" || $model ne "HS1_868_BS"));
	readingsBulkUpdate($hash, "state", $state)  if (defined($state) && $state ne "unknown");
	readingsEndUpdate($hash, 1); 		# Notify is done by Dispatch

	return $name;
}

###################################
sub SD_UT_Attr(@) {
	my ($cmd, $name, $attrName, $attrValue) = @_;
	my $hash = $defs{$name};
	my $typ = $hash->{TYPE};
	my $devicemodel;
	my $deviceCode;
	my $devicename;
	my $ioDev = InternalVal($name, "LASTInputDev", undef);
	my $state;
	my $oldmodel = AttrVal($name, "model", "unknown");
	my $bitData;
	
	############ chance device models ############
	if ($cmd eq "set" && $attrName eq "model" && $attrValue ne $oldmodel) {
	
		if (InternalVal($name, "bitMSG", "no data") ne "no data") {
			my $devicemodel;
			if ($attrName eq "model" && $attrValue eq "unknown") {
				readingsSingleUpdate($hash, "state", " Please define your model with attributes! ", 0);
			}

			foreach my $keys (sort keys %models) {	
				Log3 $name, 3, "SD_UT_Attr $keys";
				if($keys eq $attrValue) {
					$attr{$name}{model}	= $attrValue;				# set new model
					$bitData = InternalVal($name, "bitMSG", "-");
					$devicemodel = $keys;
					$state = "Defined";
					last;
				}
			}

			############ Westinghouse_Delancey RH787T ############
			if ($attrName eq "model" && $attrValue eq "RH787T") {
				$deviceCode = substr($bitData,1,4);
				$deviceCode = sprintf("%X", oct( "0b$deviceCode" ) );
				$devicename = $devicemodel."_".$deviceCode;
			############ Westinghouse Buttons_five ############
			} elsif ($attrName eq "model" && $attrValue eq "Buttons_five") {
				$deviceCode = substr($bitData,8,4);
				$deviceCode = sprintf("%X", oct( "0b$deviceCode" ) );
				$devicename = $devicemodel."_".$deviceCode;
			############ SA_434_1_mini	############
			} elsif ($attrName eq "model" && $attrValue eq "SA_434_1_mini") {
				$deviceCode = sprintf("%03X", oct( "0b$bitData" ) );
				$devicename = $devicemodel."_".$deviceCode;
			############ Unitec_47031	############
			} elsif ($attrName eq "model" && $attrValue eq "Unitec_47031") {
				$deviceCode = substr($bitData,0,8);		# unklar derzeit! 10Dil auf Bild
				$deviceCode = sprintf("%02X", oct( "0b$deviceCode" ) );
				$devicename = $devicemodel."_".$deviceCode;
			############ QUIGG_DMV ############
			} elsif ($attrName eq "model" && $attrValue eq "QUIGG_DMV") {
				$deviceCode = substr($bitData,0,12);
				$deviceCode = sprintf("%X", oct( "0b$deviceCode" ) );
				$devicename = $devicemodel."_".$deviceCode;
			############ Novy_Pureline_6830 ############
			} elsif ($attrName eq "model" && $attrValue eq "Novy_Pureline_6830") {
				$deviceCode = substr($bitData,0,8);
				$deviceCode = sprintf("%X", oct( "0b$deviceCode" ) );
				$devicename = $devicemodel."_".$deviceCode;
			############ CAME_TOP_432EV ############
			} elsif ($attrName eq "model" && $attrValue eq "CAME_TOP_432EV") {
				$deviceCode = substr($bitData,0,8);
				$deviceCode = sprintf("%X", oct( "0b$deviceCode" ) );
				$devicename = $devicemodel."_".$deviceCode;
			############ Hoermann HS1-868-BS	############
			} elsif ($attrName eq "model" && $attrValue eq "HS1_868_BS") {
				$deviceCode = sprintf("%09X", oct( "0b$bitData" ) );
				$devicename = $devicemodel."_".$deviceCode;
			############ Hoermann HSM4	############
			} elsif ($attrName eq "model" && $attrValue eq "HSM4") {
				$deviceCode = substr(sprintf("%X", oct( "0b$bitData" ) ) , 0 , 7);
				$devicename = $devicemodel."_".$deviceCode;
			############ unknown ############
			} else {
				$devicename = $devicemodel;
				Log3 $name, 3, "SD_UT_Attr UNDEFINED sensor $attrValue";
			}

			Log3 $name, 3, "SD_UT_Attr UNDEFINED sensor " . $attrValue . " detected, code " . $deviceCode if ($devicemodel ne "unknown");

			$modules{SD_UT}{defptr}{deletecache} = $name if ($hash->{DEF} eq "unknown");
			Log3 $name, 5, "SD_UT: Attr cmd=$cmd devicename=$name attrName=$attrName attrValue=$attrValue oldmodel=$oldmodel";

			readingsSingleUpdate($hash, "state", $state, 0);
			
			my $search = "FileLog_$devicename";
			
			fhem("define $devicename SD_UT $devicemodel $deviceCode") if ($devicename);			# create new device
			fhem("attr $devicename model $attrValue") if ($devicename);							# set model
			fhem("attr $devicename room SD_UT") if ($devicename);								# set room
			
			if (!defined($defs{$search})) {
				fhem("define FileLog_$devicename FileLog ./log/$devicename-%Y-%m.log $devicename") if ($devicename);		# Filelog
			}			
			
			fhem("attr FileLog_$devicename room SD_UT") if ($devicename);						# set room

		} else {
			$attr{$name}{model}	= "unknown";
			readingsSingleUpdate($hash, "state", "Please press button again!", 0);
			return "Please press button again or receive more messages!\nOnly with another message can the model be defined.\nWe need bitMSG from message.";
		}
	}
	
	#Log3 $name, 3, "SD_UT: cmd=$cmd attrName=$attrName attrValue=$attrValue oldmodel=$oldmodel";
	
	if ($cmd eq "del" && $attrName eq "model") {			### delete readings
		delete $hash->{READINGS}{"Button"} if($hash->{READINGS});
		delete $hash->{READINGS}{"deviceCode"} if($hash->{READINGS});
		delete $hash->{READINGS}{"LastAction"} if($hash->{READINGS});
		delete $hash->{READINGS}{"state"} if($hash->{READINGS});
		delete $hash->{READINGS}{"unknownMSG"} if($hash->{READINGS});
	}
	
	return undef;
}

###################################
sub SD_UT_binaryToNumber {
	my $binstr=shift;
	my $fbit=shift;
	my $lbit=$fbit;
	$lbit=shift if @_;
	return oct("0b".substr($binstr,$fbit,($lbit-$fbit)+1));
}

1;

=pod
=item summary    ...
=item summary_DE ...
=begin html

<a name="SD_UT"></a>
<h3>SD_UT</h3>
<ul>The module SD_UT is a universal module of SIGNALduino for devices or sensors.<br>
	After the first creation of the device <code><b>SD_UT_Unknown</b></code>, the user must define the device himself via the <code>model</code> attribute.<br>
	If the device is not supported yet, bit data can be collected with the SD_UT_Unknown device.<br><br>
	<i><u><b>Note:</b></u></i> As soon as the attribute model of a defined device is changed or deleted, the module re-creates a device of the selected type, and when a new message is run, the current device is deleted. 
	Devices of <u>the same or different type with the same deviceCode will result in errors</u>. PLEASE use different <code>deviceCode</code>.<br><br>
	 <u>The following devices are supported:</u><br>
	 <ul> - CAME swing gate drive&nbsp;&nbsp;&nbsp;<small>(module model: CAME_TOP_432EV | protocol 86)</small></ul>
	 <ul> - Hoermann HS1-868-BS&nbsp;&nbsp;&nbsp;<small>(module model: HS1_868_BS | protocol 69)</small></ul>
	 <ul> - Hoermann HSM4&nbsp;&nbsp;&nbsp;<small>(module model: HSM4 | protocol 69)</small></ul>
	 <ul> - Novy Pureline 6830 kitchen hood&nbsp;&nbsp;&nbsp;<small>(module model: Novy_Pureline_6830 | protocol 86)</small></ul>
	 <ul> - QUIGG DMV-7000&nbsp;&nbsp;&nbsp;<small>(module model: QUIGG_DMV | protocol 34)</small></ul>
	 <ul> - Remote control SA-434-1 mini 923301&nbsp;&nbsp;&nbsp;<small>(module model: SA_434_1_mini | protocol 81)</small></ul>
	 <ul> - unitec remote door reed switch 47031 (Unitec 47121 | Unitec 47125 | Friedland)&nbsp;&nbsp;&nbsp;<small>(module model: Unitec_47031 | protocol 30)</small></ul>
	 <ul> - Westinghouse Delancey ceiling fan (remote, 5 buttons without SET)&nbsp;&nbsp;&nbsp;<small>(module model: Buttons_five | protocol 29)</small></ul>
	 <ul> - Westinghouse Delancey ceiling fan (remote, 9 buttons with SET)&nbsp;&nbsp;&nbsp;<small>(module model: RH787T | protocol 83)</small></ul>
	 <br><br>
	<b>Define</b><br>
	<ul><code>define &lt;NAME&gt; SD_UT &lt;model&gt; &lt;Hex-address&gt;</code><br><br>
	<u>examples:</u>
		<ul>
		define &lt;NAME&gt; SD_UT RH787T A<br>
		define &lt;NAME&gt; SD_UT SA_434_1_mini ffd<br>
		define &lt;NAME&gt; SD_UT unknown<br>
		</ul>	</ul><br><br>
	<b>Set</b><br>
	<ul>Different transmission commands are available.</ul><br>
	<ul><u>Remote control SA-434-1 mini 923301&nbsp;&nbsp;|&nbsp;&nbsp;Hoermann HS1-868-BS</u></ul>
	<ul>
		<li>send<br>
		button <small>(Always send the same, even if the user sends another set command via console.)</small></li>
	</ul><br>

	<ul><u>Hoermann HSM4 (remote with 4 buttons)</u></ul>
	<ul><a name="button_1"></a>
		<li>button_1<br>
		Button one on the remote</li>
	</ul>
	<ul><a name="button_2"></a>
		<li>button_2<br>
		Button two on the remote</li>
	</ul>
	<ul><a name="button_3"></a>
		<li>button_3<br>
		Button three on the remote</li>
	</ul>
	<ul><a name="button_4"></a>
		<li>button_4<br>
		Button four on the remote</li>
	</ul><br>

	<ul><u>Westinghouse Deckenventilator (remote with 5 buttons and without SET)</u></ul>
	<ul><a name="1_fan_low_speed"></a>
		<li>1_fan_low_speed<br>
		Button LOW on the remote</li>
	</ul>
	<ul><a name="2_fan_medium_speed"></a>
		<li>2_fan_medium_speed<br>
		Button MED on the remote</li>
	</ul>
	<ul><a name="3_fan_high_speed"></a>
		<li>3_fan_high_speed<br>
		Button HI on the remote</li>
	</ul>
	<ul><a name="light_on_off"></a>
		<li>light_on_off<br>
		switch light on or off</li>
	</ul>
	<ul><a name="fan_off"></a>
		<li>fan_off<br>
		turns off the fan</li>
	</ul><br><a name=" "></a>
	
	<ul><u>Westinghouse Delancey ceiling fan (remote RH787T with 9 buttons and SET)</u></ul>
	<ul><a name="1_fan_minimum_speed"></a>
		<li>1_fan_minimum_speed<br>
		Button I on the remote</li>
	</ul>
	<ul><a name="2_fan_low_speed"></a>
		<li>2_fan_low_speed<br>
		Button II on the remote</li>
	</ul>
	<ul><a name="3_fan_medium_low_speed"></a>
		<li>3_fan_medium_low_speed<br>
		Button III on the remote</li>
	</ul>
	<ul><a name="4_fan_medium_speed"></a>
		<li>4_fan_medium_speed<br>
		Button IV on the remote</li>
	</ul>
	<ul><a name="5_fan_medium_high_speed"></a>
		<li>5_fan_medium_high_speed<br>
		Button V on the remote</li>
	</ul>
	<ul><a name="6_fan_high_speed"></a>
		<li>6_fan_high_speed<br>
		Button VI on the remote</li>
	</ul>
	<ul><a name="fan_off"></a>
		<li>fan_off<br>
		turns off the fan</li>
	</ul>
	<ul><a name="fan_direction"></a>
		<li>fan_direction<br>
		Defining the direction of rotation</li>
	</ul>
	<ul><a name="light_on_off"></a>
		<li>light_on_off<br>
		switch light on or off</li>
	</ul>
	<ul><a name="set"></a>
		<li>set<br>
		Button SET in the remote</li><a name=" "></a>
	</ul>
	<br><br>
	
	<b>Get</b><br>
	<ul>N/A</ul><br><br>
	
	<b>Attribute</b><br>
	<ul><li><a name="debug">debug</a><br>
		Bring the module into a very detailed debug output in the logfile. This allows functions to be checked.</li><a name=" "></a></ul><br>
	<ul><li><a href="#do_not_notify">do_not_notify</a></li></ul><br>
	<ul><li><a href="#ignore">ignore</a></li></ul><br>
	<ul><li><a href="#IODev">IODev</a></li></ul><br>
	<ul><a name="model"></a>
		<li>model<br>
		The attribute indicates the model type of your device.<br>
		(unknown, Buttons_five, CAME_TOP_432EV, HS1-868-BS, HSM4, QUIGG_DMV, Novy_Pureline_6830, RH787T, SA_434_1_mini, Unitec_47031)</li>
	</ul><br><br>
	
	<b><i>Generated readings of the models</i></b><br>
	<ul><u>Buttons_five | CAME_TOP_432EV | HSM4 | Novy_Pureline_6830 | QUIGG_DMV | RH787T</u><br>
	<li>deviceCode<br>
	Device code of the system</li>
	<li>LastAction<br>
	Last executed action of the device. <code>receive</code> for command received | <code>send</code> for command send</li>
	<li>state<br>
	Last executed keystroke of the remote control</li></ul><br>

	<ul><u>HS1-868-BS&nbsp;&nbsp;|&nbsp;&nbsp;SA_434_1_mini</u><br>
	<li>LastAction<br>
	Last executed action of FHEM. <code>send</code> for command send.</li>
	<li>state<br>
	Last executed action of the device. <code>receive</code> for command received | <code>send</code> for command send</li></ul><br>
	
	<ul><u>Unitec_47031</u><br>
	<li>System-Housecode<br>
	System or house code of the device</li>
	<li>state<br>
	Condition of contact (prepared, unconfirmed)</li>
	<li>Zone<br>
	Zone of the device</li>
	<li>Usersystem<br>
	Group of the system</li>
	</ul><br>
	
</ul>
=end html
=begin html_DE

<a name="SD_UT"></a>
<h3>SD_UT</h3>
<ul>Das Modul SD_UT ist ein Universalmodul vom SIGNALduino f&uuml;r Ger&auml;te oder Sensoren.<br>
	Nach dem ersten anlegen des Ger&auml;tes <code><b>SD_UT_Unknown</b></code> muss der User das Ger&auml;t selber definieren via dem Attribut <code>model</code>.<br>
	Bei noch nicht unterst&uuml;tzen Ger&auml;ten k&ouml;nnen mit dem <code><b>SD_UT_Unknown</b></code> Ger&auml;t Bitdaten gesammelt werden.<br><br>
	<i><u><b>Hinweis:</b></u></i> Sobald das Attribut model eines definieren Ger&auml;tes verstellt oder gelöscht wird, so legt das Modul ein Ger&auml;t des gew&auml;hlten Typs neu an und mit Durchlauf einer neuen Nachricht wird das aktuelle Ger&auml;t gel&ouml;scht. 
	Das betreiben von Ger&auml;ten des <u>gleichen oder unterschiedliches Typs mit gleichem <code>deviceCode</code> f&uuml;hrt zu Fehlern</u>. BITTE achte stets auf einen unterschiedlichen <code>deviceCode</code>.<br><br>
	 <u>Es werden bisher folgende Ger&auml;te unterst&uuml;tzt:</u><br>
	 <ul> - CAME Drehtor Antrieb&nbsp;&nbsp;&nbsp;<small>(Modulmodel: CAME_TOP_432EV | Protokoll 86)</small></ul>
	 <ul> - Hoermann HS1-868-BS&nbsp;&nbsp;&nbsp;<small>(Modulmodel: HS1_868_BS | Protokoll 69)</small></ul>
	 <ul> - Hoermann HSM4&nbsp;&nbsp;&nbsp;<small>(Modulmodel: HSM4 | Protokoll 69)</small></ul>
	 <ul> - Novy Pureline 6830 Dunstabzugshaube&nbsp;&nbsp;&nbsp;<small>(Modulmodel: Novy_Pureline_6830 | Protokoll 86)</small></ul>
	 <ul> - QUIGG DMV-7000&nbsp;&nbsp;&nbsp;<small>(Modulmodel: QUIGG_DMV | Protokoll 34)</small></ul>
	 <ul> - Remote control SA-434-1 mini 923301&nbsp;&nbsp;&nbsp;<small>(Modulmodel: SA_434_1_mini | Protokoll 81)</small></ul>
	 <ul> - unitec remote door reed switch 47031 (Unitec 47121 | Unitec 47125 | Friedland)&nbsp;&nbsp;&nbsp;<small>(Modulmodel: Unitec_47031 | Protokoll 30)</small></ul>
	 <ul> - Westinghouse Deckenventilator (Fernbedienung, 5 Tasten ohne SET)&nbsp;&nbsp;&nbsp;<small>(Modulmodel: Buttons_five | Protokoll 29)</small></ul>
	 <ul> - Westinghouse Delancey Deckenventilator (Fernbedienung, 9 Tasten mit SET)&nbsp;&nbsp;&nbsp;<small>(Modulmodel: RH787T | Protokoll 83)</small></ul>
	 <br><br>
	
	<b>Define</b><br>
	<ul><code>define &lt;NAME&gt; SD_UT &lt;model&gt; &lt;Hex-Adresse&gt;</code><br><br>
	<u>Beispiele:</u>
		<ul>
		define &lt;NAME&gt; SD_UT RH787T A<br>
		define &lt;NAME&gt; SD_UT SA_434_1_mini ffd<br>
		define &lt;NAME&gt; SD_UT unknown<br>
		</ul></ul><br><br>
	
	<b>Set</b><br>
	<ul>Je nach Ger&auml;t sind unterschiedliche Sendebefehle verf&uuml;gbar.</ul><br>
	<ul><u>Remote control SA-434-1 mini 923301&nbsp;&nbsp;|&nbsp;&nbsp;Hoermann HS1-868-BS</u></ul>
	<ul>
		<li>send<br>
		Knopfdruck <small>(Sendet immer das selbe, auch wenn der Benutzer einen anderen Set-Befehl via Konsole sendet.)</small></li>
	</ul><br>

	<ul><u>Hoermann HSM4 (Fernbedienung mit 4 Tasten)</u></ul>
	<ul><a name="button_1"></a>
		<li>button_1<br>
		Taste 1 auf der Fernbedienung</li>
	</ul>
	<ul><a name="button_2"></a>
		<li>button_2<br>
		Taste 2 auf der Fernbedienung</li>
	</ul>
	<ul><a name="button_3"></a>
		<li>button_3<br>
		Taste 3 auf der Fernbedienung</li>
	</ul>
	<ul><a name="button_4"></a>
		<li>button_4<br>
		Taste 4 auf der Fernbedienung</li>
	</ul><br>

	<ul><u>Westinghouse Deckenventilator (Fernbedienung mit 5 Tasten)</u></ul>
	<ul><a name="1_fan_low_speed"></a>
		<li>1_fan_low_speed<br>
		Taste LOW auf der Fernbedienung</li>
	</ul>
	<ul><a name="2_fan_medium_speed"></a>
		<li>2_fan_medium_speed<br>
		Taste MED auf der Fernbedienung</li>
	</ul>
	<ul><a name="3_fan_high_speed"></a>
		<li>3_fan_high_speed<br>
		Taste HI auf der Fernbedienung</li>
	</ul>
	<ul><a name="light_on_off"></a>
		<li>light_on_off<br>
		Licht ein-/ausschalten</li>
	</ul>
	<ul><a name="fan_off"></a>
		<li>fan_off<br>
		Ventilator ausschalten</li>
	</ul><br>
	
	<ul><a name=" "></a><u>Westinghouse Delancey Deckenventilator (Fernbedienung RH787T mit 9 Tasten + SET)</u></ul>
	<ul><a name="1_fan_minimum_speed"></a>
		<li>1_fan_minimum_speed<br>
		Taste I auf der Fernbedienung</li>
	</ul>
	<ul><a name="2_fan_low_speed"></a>
		<li>2_fan_low_speed<br>
		Taste II auf der Fernbedienung</li>
	</ul>
	
	<ul><a name="3_fan_medium_low_speed"></a>
		<li>3_fan_medium_low_speed<br>
		Taste III auf der Fernbedienung</li>
	</ul>
	<ul><a name="4_fan_medium_speed"></a>
		<li>4_fan_medium_speed<br>
		Taste IV auf der Fernbedienung</li>
	</ul>
	<ul><a name="5_fan_medium_high_speed"></a>
		<li>5_fan_medium_high_speed<br>
		Taste V auf der Fernbedienung</li>
	</ul>
	<ul><a name="6_fan_high_speed"></a>
		<li>6_fan_high_speed<br>
		Taste VI auf der Fernbedienung</li>
	</ul>
	<ul><a name="fan_off"></a>
		<li>fan_off<br>
		Ventilator ausschalten</li></ul>
	<ul><a name="fan_direction"></a>
		<li>fan_direction<br>
		Drehrichtung festlegen</li>
	</ul>
	<ul><a name="light_on_off"></a>
		<li>light_on_off<br>
		Licht ein-/ausschalten</li>
	</ul>
	<ul><a name="set"></a>
		<li>set<br>
		Taste SET in der Fernbedienung</li><a name=" "></a>
	</ul>
	<br><br>
	
	<b>Get</b><br>
	<ul>N/A</ul><br><br>
	
	<b>Attribute</b><br>
	<ul><li><a name="debug">debug</a><br>
		Dies bringt das Modul in eine sehr ausf&uuml;hrliche Debug-Ausgabe im Logfile. Somit lassen sich Funktionen &uuml;berpr&uuml;fen.</li><a name=" "></a></ul><br>
	<ul><li><a href="#do_not_notify">do_not_notify</a></li></ul><br>
	<ul><li><a href="#ignore">ignore</a></li></ul><br>
	<ul><li><a href="#IODev">IODev</a></li></ul><br>
	<ul><li><a name="model">model</a><br>
		Das Attribut bezeichnet den Modelltyp Ihres Ger&auml;tes.<br>
		(unknown, Buttons_five, CAME_TOP_432EV, HS1-868-BS, HSM4, QUIGG_DMV, RH787T, Novy_Pureline_6830, SA_434_1_mini, Unitec_47031)</li><a name=" "></a>
	</ul><br><br>
	
	<b><i>Generierte Readings der Modelle</i></b><br>
	<ul><u>Buttons_five | CAME_TOP_432EV | HSM4 | Novy_Pureline_6830 | QUIGG_DMV | RH787T</u><br>
	<li>deviceCode<br>
	Ger&auml;teCode des Systemes</li>
	<li>LastAction<br>
	Zuletzt ausgef&uuml;hrte Aktion des Ger&auml;tes. <code>receive</code> f&uuml;r Kommando empfangen | <code>send</code> f&uuml;r Kommando gesendet</li>
	<li>state<br>
	Zuletzt ausgef&uuml;hrter Tastendruck der Fernbedienung</li></ul><br>
	
	<ul><u>HS1-868-BS&nbsp;&nbsp;|&nbsp;&nbsp;SA_434_1_mini</u><br>
	<li>LastAction<br>
	Zuletzt ausgef&uuml;hrte Aktion aus FHEM. <code>send</code> f&uuml;r Kommando gesendet.</li>
	<li>state<br>
	Zuletzt ausgef&uuml;hrte Aktion des Ger&auml;tes. <code>receive</code> f&uuml;r Kommando empfangen.</li></ul><br>
	
	<ul><u>Unitec_47031</u><br>
	<li>System-Housecode<br>
	Eingestellter System bzw. Hauscode des Ger&auml;tes</li>
	<li>state<br>
	Zustand des Kontaktes (vorbereitet, unbest&auml;tigt)</li>
	<li>Zone<br>
	Eingestellte Zone des Ger&auml;tes</li>
	<li>Usersystem<br>
	Bezeichnung Systemes</li>
	</ul><br>
	
</ul>
=end html_DE
=cut
