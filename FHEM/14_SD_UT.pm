##############################################
# $Id: 14_SD_UT.pm 32 2016-04-02 14:00:00 v3.2-dev $
#
# The purpose of this module is to support serval ht12e protocol based devices
# 2016 - 1.fhemtester | 2018 - HomeAuto_User & elektron-bbs
#
# - unitec Modul alte Variante bis 20180901 (Typ unitec-Sound) --> keine MU MSG!
# - unitec Funkfernschalterset (Typ uniTEC_48110) ??? EIM-826 Funksteckdosen --> keine MU MSG!
####################################################################################################################################
# - unitec remote door reed switch 47031 (Typ Unitec_47031) [Protocol 30] (sync -30)
#     FORUM: https://forum.fhem.de/index.php/topic,43346.msg353144.html#msg353144
#     Adresse: 6A - öffnen?
#     get sduino_dummy raw MU;;P0=309;;P1=636;;P2=-690;;P3=-363;;P4=-10027;;D=012031203120402031312031203120312031204020313120312031203120312040203131203120312031203120402031312031203120312031204020313120312031203120312040203131203120312031203120402031312031203120312031204020313120312031203120312040203131203120312030;;CP=0;;O;;
#     Adresse: FF - Gehäuse geöffnet?
#     get sduino_dummy raw MU;;P0=684;;P1=-304;;P2=-644;;P3=369;;P4=-9931;;D=010101010101010232323104310101010101010102323231043101010101010101023232310431010101010101010232323104310101010101010102323231043101010101010101023232310431010101010101010232323104310101010101010102323231043101010101010101023232310431010100;;CP=0;;O;;
####################################################################################################################################
# - Westinghouse Delancey Deckenventilator (Typ Westinghouse_Delancey) [Protocol 83] (sync -35)
#     Adresse F: I - fan minimum speed
#     get sduino_dummy raw MU;;P0=388;;P1=-112;;P2=267;;P3=-378;;P5=585;;P6=-693;;P7=-11234;;D=0123035353535356262623562626272353535353562626235626262723535353535626262356262627235353535356262623562626272353535353562626235626262723535353535626262356262627235353535356262623562626272353535353562626235626262723535353535626262356262627235353535356262;;CP=2;;R=43;;O;;
#     Adresse 7: I - fan minimum speed
#     get sduino_dummy raw MU;;P0=-11250;;P1=-200;;P2=263;;P3=-116;;P4=-374;;P5=578;;P6=-697;;D=1232456245454562626245626262024562454545626262456262620245624545456262624562626202456245454562626245626262024562454545626262456262620245624545456262624562626202456245454562626245626262024562454545626262456262620245624545456262624562626202456245454562626;;CP=2;;R=49;;O;;
#	  Adresse 9: fan_off
#	  get sduino_dummy raw MU;;P0=-720;;P1=235;;P2=-386;;P3=561;;P4=-11254;;D=01230141230101232301010101012301412301012323010101010123014123010123230101010101010141230101232301010101010101412301012323010101010101014123010123230101010101010;;CP=1;;R=242;;
####################################################################################################################################
# - Remote control SA-434-1 mini 923301  [Protocol 81]
#     one Button, 434 MHz
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
#		get sduino_dummy raw MU;;P0=-1756;;P1=112;;P2=-11752;;P3=496;;P4=-495;;P5=998;;P6=-988;;P7=-17183;;D=0123454545634545456345634563734545456345454563456345637345454563454545634563456373454545634545456345634563734545456345454563456345637345454563454545634563456373454545634545456345634563734545456345454563456345637345454563454545634563456373454545634545456;;CP=3;;R=0;;
#		get sduino_dummy raw MU;;P0=-485;;P1=188;;P2=-6784;;P3=508;;P5=1010;;P6=-974;;P7=-17172;;D=0123050505630505056305630563730505056305050563056305637305050563050505630563056373050505630505056305630563730505056305050563056305637305050563050505630563056373050505630505056305630563730505056305050563056305637305050563050505630563056373050505630505056;;CP=3;;R=0;;
####################################################################################################################################
# - VTX-BELL_Funkklingel  [Protocol 79]
#     get sduino_dummy raw MU;;P0=656;;P1=-656;;P2=335;;P3=-326;;P4=-5024;;D=01230121230123030303012423012301212301230303030124230123012123012303030301242301230121230123030303012423012301212301230303030124230123012123012303030301242301230121230123030303012423012301212301230303030124230123012123012303030301242301230121230123030303;;CP=2;;O;;
####################################################################################################################################
# !!! ToDo´s !!!
#     - send MSG von $protocol nutzen ?
#     - 
####################################################################################################################################

package main;

use strict;
use warnings;
#use SetExtensions;
#use Data::Dumper;

sub SD_UT_Initialize($) {
	my ($hash) = @_;
	$hash->{Match}		= "^[P|u](30|79|81|83)#.*";
	$hash->{DefFn}		= "SD_UT_Define";
	$hash->{UndefFn}	= "SD_UT_Undef";
	$hash->{ParseFn}	= "SD_UT_Parse";
	$hash->{SetFn}		= "SD_UT_Set";
	$hash->{AttrFn}	= "SD_UT_Attr";
	$hash->{AttrList}	= "IODev do_not_notify:1,0 ignore:0,1 showtime:1,0 model:unknown,SA_434_1_mini,Unitec_47031,Unitec_other,VTX_BELL,Westinghouse_Delancey " .
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
	return "wrong <model>: SA_434_1_mini | Unitec_47031 | Unitec_other | VTX_BELL | Westinghouse_Delancey | unknown" if not($a[2] eq  "SA_434_1_mini" || $a[2] eq  "Unitec_47031" || $a[2] eq "Unitec_other" || $a[2] eq "VTX_BELL" || $a[2] eq "Westinghouse_Delancey" || $a[2] eq "unknown");
	### checks unknown ###
	return "wrong define: $a[2] need no HEX-Value to define!" if($a[2] eq "unknown" && $a[3] && length($a[3]) >= 1);
	### checks Westinghouse_Delancey ###
	return "wrong HEX-Value! $a[2] have one HEX-Value" if ($a[2] eq "Westinghouse_Delancey" && length($a[3]) > 1);
	return "wrong HEX-Value! $a[2] HEX-Value are not (0-9 | a-f | A-F)" if ($a[2] eq "Westinghouse_Delancey" && not $a[3] =~ /^[0-9a-fA-F]/s);
	### checks SA_434_1_mini ###
	return "wrong HEX-Value! $a[2] HEX-Value to short | long or not HEX (0-9 | a-f | A-F){3}" if ($a[2] eq "SA_434_1_mini" && not $a[3] =~ /^[0-9a-fA-F]{3}/s);
	### checks VTX_BELL ###
	return "wrong HEX-Value! $a[2] HEX-Value to short | long or not HEX (0-9 | a-f | A-F){3}" if ($a[2] eq "VTX_BELL" && not $a[3] =~ /^[0-9a-fA-F]{3}/s);
	### checks Unitec_47031 ###
	return "wrong HEX-Value! $a[2] HEX-Value to short | long or not HEX (0-9 | a-f | A-F){2}" if ($a[2] eq "Unitec_47031" && not $a[3] =~ /^[0-9a-fA-F]{2}/s);
	### checks Unitec_other ###
	return "wrong HEX-Value! $a[2] HEX-Value to short | long or not HEX (0-9 | a-f | A-F){3}" if ($a[2] eq "Unitec_other" && not $a[3] =~ /^[0-9a-fA-F]{3}/s);

	
	$hash->{lastMSG} =  "";
	$hash->{bitMSG} =  "";
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
	my $ret = undef;
	
	############ Westinghouse_Delancey ############
	if ($model eq "Westinghouse_Delancey") {

		my @definition = split(" ", $hash->{DEF});									# split adress from def
		my $adr = sprintf( "%04b", hex($definition[1])) if ($name ne "unknown");	# argument 1 - adress to binary with 4 digits

		if ($cmd eq "?") {
			$ret .= "1_fan_minimum_speed:noArg 2_fan_low_speed:noArg 3_fan_medium_low_speed:noArg 4_fan_medium_speed:noArg 5_fan_medium_high_speed:noArg 6_fan_high_speed:noArg fan_direction:noArg fan_off:noArg light_on/off:noArg set:noArg";
		} else {
			my $msg = "P83#1". $adr ."0";
			if ($cmd eq "1_fan_minimum_speed") {
				$msg .= "001000";		# I - fan minimum speed
			} elsif ($cmd eq "2_fan_low_speed") {
				$msg .= "001010";		# II - fan low speed
			} elsif ($cmd eq "3_fan_medium_low_speed") {
				$msg .= "010000";		# III - fan medium low speed
			} elsif ($cmd eq "4_fan_medium_speed") {
				$msg .= "011000";		# IV - fan medium speed
			} elsif ($cmd eq "5_fan_medium_high_speed") {
				$msg .= "100010";		# V - fan medium high speed
			} elsif ($cmd eq "6_fan_high_speed") {
				$msg .= "100000";		# VI - fan high speed
			} elsif ($cmd eq "fan_off") {
				$msg .= "000010";		# Turn the fan off
			} elsif ($cmd eq "fan_direction") {
				$msg .= "000100";		# fan direction
			} elsif ($cmd eq "light_on/off") {
				$msg .= "000001";		# light on/off
			} elsif ($cmd eq "set") {
				$msg .= "010010";		# set
			} else {
				return "Wrong command, please select one from list.";
			}
			
			# Gitub - User: "Die besten Ergebnisse waren mit "#R7"."
			# https://github.com/RFD-FHEM/RFFHEM/issues/250#issuecomment-419622486
			$msg .= "#R7";

			## for hex Check ##
			my @split = split("#", $msg);
			my $hexvalue = $split[1];
			$hexvalue = sprintf("%X", oct( "0b$hexvalue" ) );
			###################
			
			Log3 $name, 3, "$ioname: $name sendMsg=$msg ($hexvalue)";
			Log3 $name, 3, "$ioname: $name set $cmd" if ($cmd ne "?");
			IOWrite($hash, 'sendMsg', $msg);
		}
	############ SA_434_1_mini ############
	} elsif 	($model eq "SA_434_1_mini") {
			if ($cmd eq "?") {
				$ret .= "send:noArg";
			} else {
				my $msg = "P81#" . $hash->{bitMSG};
				$msg .= "#R5";		# Anzahl Wiederholungen noch klären!
				Log3 $name, 5, "$ioname: $name sendMsg=$msg";
				
				if ($cmd ne "?") {
					$cmd = "send";
				}
				
				Log3 $name, 3, "$ioname: $name set $cmd" if ($cmd ne "?");
				IOWrite($hash, 'sendMsg', $msg);
			}
	############ VTX_BELL ############
	} elsif 	($model eq "VTX_BELL") {
			if ($cmd eq "?") {
				$ret .= "send:noArg";
			} else {
				my $msg = "P79#" . $hash->{bitMSG};
				$msg .= "#R5";		# Anzahl Wiederholungen noch klären!
				Log3 $name, 5, "$ioname: $name sendMsg=$msg";
				
				if ($cmd ne "?") {
					$cmd = "send";
				}				

				Log3 $name, 3, "$ioname: $name set $cmd" if ($cmd ne "?");
				IOWrite($hash, 'sendMsg', $msg);
			}
	}

	readingsSingleUpdate($hash, "LastAction", "send", 0) if ($cmd ne "?" && $model eq "Westinghouse_Delancey");
	readingsSingleUpdate($hash, "state" , $cmd, 1) if ($cmd ne "?");
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
	Log3 $iohash, 3, "$ioname: SD_UT protocol $protocol, bitData $bitData";
	if (!defined($model)) {
		Log3 $iohash, 4, "$ioname: SD_UT unknown model, please report ($rawData)";  
		return "";
	}
	my $bin;
	my $def;
	my $deviceCode;
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
	
	### Remote control SA_434_1_mini 923301 ###
	$deviceCode = sprintf("%x", oct( "0b$bitData" ) );
	$devicedef = "SA_434_1_mini " . $deviceCode if (!$def && $protocol == 81);
	$def = $modules{SD_UT}{defptr}{$devicedef} if (!$def && $protocol == 81);
	### Unitec_47031 ###
	$deviceCode = substr($bitData,0,8);
	$deviceCode = sprintf("%x", oct( "0b$deviceCode" ) );
	$devicedef = "Unitec_47031 " . $deviceCode if(!$def && $protocol == 30);
	$def = $modules{SD_UT}{defptr}{$devicedef} if(!$def && $protocol == 30);
	### Westinghouse_Delancey ###
	$deviceCode = substr($bitData,1,4);
	$deviceCode = sprintf("%x", oct( "0b$deviceCode" ) );
	$devicedef = "Westinghouse_Delancey " . $deviceCode if(!$def && $protocol == 83);
	$def = $modules{SD_UT}{defptr}{$devicedef} if (!$def && $protocol == 83);
	### VTX_BELL ###
	$deviceCode = sprintf("%x", oct( "0b$bitData" ) );
	$devicedef = "VTX_BELL " . $deviceCode if(!$def && $protocol == 79);
	$def = $modules{SD_UT}{defptr}{$devicedef} if (!$def && $protocol == 79);
	### Unitec_other ###
	$deviceCode = sprintf("%x", oct( "0b$bitData" ) );
	$devicedef = "Unitec_other " . $deviceCode  if(!$def && $protocol == 30);
	$def = $modules{SD_UT}{defptr}{$devicedef}  if(!$def && $protocol == 30);
	### unknown ###
	$devicedef = "unknown" if(!$def);
	$def = $modules{SD_UT}{defptr}{$devicedef} if(!$def);
	$modules{SD_UT}{defptr}{ioname} = $ioname;

	Log3 $iohash, 4, "$ioname: SD_UT device $devicedef found (delete cache = $deletecache)" if($def && $deletecache && $deletecache ne "-");
	
	if(!$def) {
		Log3 $iohash, 1, "$ioname: SD_UT UNDEFINED sensor " . $model . " detected, code " . $deviceCode;
		return "UNDEFINED $model SD_UT $model";
	}
	
	my $hash = $def;
	my $name = $hash->{NAME};
	$hash->{lastMSG} = $rawData;
	$hash->{bitMSG} = $bitData;
	$deviceCode = undef;				# reset for Westinghouse_Delancey
	
	my $protocolnumber = ReadingsVal($name, "sduino_protocol", "unknown");
	readingsSingleUpdate($hash, "sduino_protocol" , $protocol, 0) if ($protocol);		# save protocol nr

	
	############ unitec orginal ############ Protocol 30 ############
	if (AttrVal($name, "model", "unknown") eq "Unitec_other" && $protocol == 30) {
		$model = AttrVal($name, "model", "unknown");
		$bin = substr($bitData,0,8);
		$state = substr($bitData,8,4);
		$SensorTyp = "FAAC/HEIDEMANN";	
		$deviceCode = sprintf('%X', oct("0b$bin"));
		Log3 $name, 3, "$ioname: $model $SensorTyp devicecode=$deviceCode state=$state ($rawData)";
		if (!defined(AttrVal($hash->{NAME},"event-min-interval",undef)))
		{
			my $minsecs = AttrVal($iohash->{NAME},'minsecs',0);
			if($hash->{lastReceive} && (time() - $hash->{lastReceive} < $minsecs)) {
				Log3 $hash, 4, "$ioname: $deviceCode Dropped due to short time. minsecs=$minsecs";
				return "";
			}
		}
		$hash->{lastReceive} = time();
		$hash->{lastMSG} = $rawData;
		$hash->{bitMSG} = $bitData;
	############ Westinghouse_Delancey ############ Protocol 30 ############
	} elsif (AttrVal($name, "model", "unknown") eq "Westinghouse_Delancey" && $protocol == 83) {
		$model = AttrVal($name, "model", "unknown");
		$state = substr($bitData,6,6);
		$deviceCode = substr($bitData,1,4);
		
		## deviceCode conversion for User in ON or OFF ##
		my $deviceCodeUser = $deviceCode;
		$deviceCodeUser =~ s/0/off|/g && $deviceCodeUser =~ s/1/on|/g;
		$deviceCodeUser = substr($deviceCodeUser, 0 , length($deviceCodeUser)-1);
		$deviceCode = $deviceCode." ($deviceCodeUser)";
		
		#my $unknown1 = substr($bitData,0,1);
		#my $unknown2 = substr($bitData,5,1);
		$bin = substr($bitData,0,8);
		Log3 $name, 3, "$ioname: $model devicecode=$deviceCode state=$state ($rawData)";
		if ($state eq "001000") {
			$state = "I - fan minimum speed";
		} elsif ($state eq "001010") {
			$state = "II - fan low speed";
		} elsif ($state eq "010000") {
			$state = "III - fan medium low speed";
		} elsif ($state eq "011000") {
			$state = "IV - fan medium speed";
		} elsif ($state eq "100010") {
			$state = "V - fan medium high speed";
		} elsif ($state eq "100000") {
			$state = "VI - fan high speed";
		} elsif ($state eq "000010") {
			$state = "Turn the fan off";
		} elsif ($state eq "000001") {
			$state = "light on/off";
		} elsif ($state eq "000100") {
			$state = "fan direction";
		} elsif ($state eq "010010") {
		$state = "set";
		} else {
			$state = "unknown";
		}
		
		#$state.= " | ".TimeNow();
		
	############ Unitec_47031 ############ Protocol 30 ############
	} elsif (AttrVal($name, "model", "unknown") eq "Unitec_47031" && $protocol == 30) {
		$model = AttrVal($name, "model", "unknown");
		$state = "new MSG | ".TimeNow();
		$bin = substr($bitData,0,8);
		#$state = substr($bitData,8,4);
		$deviceCode = sprintf('%X', oct("0b$bin"));
		Log3 $name, 3, "$ioname: $model devicecode=$deviceCode state=$state ($rawData)";
	############ SA_434_1_mini ############ Protocol xx ############
	} elsif (AttrVal($name, "model", "unknown") eq "SA_434_1_mini" && $protocol == 81) {
		$model = AttrVal($name, "model", "unknown");
		$state = "receive";
		Log3 $name, 3, "$ioname: $model $name state=$state ($rawData)";
	############ VTX_BELL ############ Protocol 79 ############
	} elsif (AttrVal($name, "model", "unknown") eq "VTX_BELL" && $protocol == 79) {
		$model = AttrVal($name, "model", "unknown");
		$state = "receive";
		Log3 $name, 3, "$ioname: $model $name state=$state ($rawData)";
	############ unknown ############
	} else {
		readingsSingleUpdate($hash, "state", "???", 0);
		readingsSingleUpdate($hash, "unknownMSG", $bitData, 1);
		Log3 $name, 3, "$ioname: SD_UT Please define your model of Device $name in Attributes!";
		Log3 $name, 4, "$ioname: SD_UT_Parse Protocol: $protocol, rawData=$rawData, bitData=$bitData, model=$model";
	}

	readingsBeginUpdate($hash);
	readingsBulkUpdate($hash, "deviceCode", $deviceCode, 0)  if (defined($deviceCode));
	readingsBulkUpdate($hash, "LastAction", "receive", 0)  if (defined($state) && $model eq "Westinghouse_Delancey");
	readingsBulkUpdate($hash, "state", $state)  if (defined($state));
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
	
	############ chance device models ############
	if ($cmd eq "set" && $attrName eq "model" && $attrValue ne $oldmodel) {
	
		if (InternalVal($name, "bitMSG", "-") ne "") {
			my $devicemodel;
			if ($attrName eq "model" && $attrValue eq "unknown") {
				readingsSingleUpdate($hash, "state", " Please define your model with attributes! ", 0);
			}
			
			############ Westinghouse_Delancey	############			
			if ($attrName eq "model" && $attrValue eq "Westinghouse_Delancey") {
				$attr{$name}{model}	= $attrValue;				# set new model
				my $bitData = InternalVal($name, "bitMSG", "-");
				$deviceCode = substr($bitData,1,4);
				$deviceCode = sprintf("%x", oct( "0b$deviceCode" ) );
				$devicemodel = "Westinghouse_Delancey";
				$devicename = $devicemodel."_".$deviceCode;
				Log3 $name, 3, "SD_UT: UNDEFINED sensor ".$attrValue . " detected, code ". $deviceCode;
				$state = "Defined";
			############ SA_434_1_mini	############
			} elsif ($attrName eq "model" && $attrValue eq "SA_434_1_mini") {
				$attr{$name}{model}	= $attrValue;				# set new model
				my $bitData = InternalVal($name, "bitMSG", "0");
				$deviceCode = sprintf("%x", oct( "0b$bitData" ) );
				$devicemodel = "SA_434_1_mini";
				$devicename = $devicemodel."_".$deviceCode;
				Log3 $name, 3, "SD_UT: UNDEFINED sensor " . $attrValue . " detected, code " . $deviceCode;
				$state = "Defined";
			############ Unitec_47031	############
			} elsif ($attrName eq "model" && $attrValue eq "Unitec_47031") {
				$attr{$name}{model}	= $attrValue;				# set new model
				my $bitData = InternalVal($name, "bitMSG", "0");
				$deviceCode = substr($bitData,0,8);
				$deviceCode = sprintf("%x", oct( "0b$deviceCode" ) );
				$devicemodel = "Unitec_47031";
				$devicename = $devicemodel."_".$deviceCode;
				Log3 $name, 3, "SD_UT: UNDEFINED sensor " . $attrValue . " detected, code " . $deviceCode;
				$state = "Defined";
			############ VTX_BELL	############
			} elsif ($attrName eq "model" && $attrValue eq "VTX_BELL") {
				$attr{$name}{model}	= $attrValue;				# set new model
				my $bitData = InternalVal($name, "bitMSG", "0");
				$deviceCode = sprintf("%x", oct( "0b$bitData" ) );
				$devicemodel = "VTX_BELL";
				$devicename = $devicemodel."_".$deviceCode;
				Log3 $name, 3, "SD_UT: UNDEFINED sensor " . $attrValue . " detected, code " . $deviceCode;
				$state = "Defined";
			############ Unitec_other ############
			} elsif ($attrName eq "model" && $attrValue eq "Unitec_other") {
				$attr{$name}{model}	= $attrValue;				# set new model
				my $bitData = InternalVal($name, "bitMSG", "0");
				$deviceCode = sprintf("%x", oct( "0b$bitData" ) );
				$devicemodel = "Unitec_other";
				$devicename = $devicemodel."_".$deviceCode;
				Log3 $name, 3, "SD_UT: UNDEFINED sensor $attrValue";
				$state = "Defined";
			############ unknown ############
			} else {
				$attr{$name}{model}	= $attrValue;				# set new model
				$devicemodel = "unknown";
				$devicename = $devicemodel;
				Log3 $name, 3, "SD_UT: UNDEFINED sensor $attrValue";
				$state = "Defined";
			}

			$modules{SD_UT}{defptr}{deletecache} = $name;
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
			readingsSingleUpdate($hash, "state", "Please press button again!", 0);
		}
	}
	
	#Log3 $name, 3, "SD_UT: cmd=$cmd attrName=$attrName attrValue=$attrValue oldmodel=$oldmodel";
	
	if ($cmd eq "del" && $attrName eq "model") {			### delete readings
		delete $hash->{READINGS}{"Button"} if($hash->{READINGS});
		delete $hash->{READINGS}{"deviceCode"} if($hash->{READINGS});
		delete $hash->{READINGS}{"LastAction"} if($hash->{READINGS});
		delete $hash->{READINGS}{"sduino_protocol"} if($hash->{READINGS});
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
<ul>The module SD_UT is a universal module of SIGNALduino for devices or sensors with a 12bit message.<br>
	After the first creation of the device <code><b>SD_UT_Unknown</b></code>, the user must define the device himself via the <code>model</code> attribute.<br>
	If the device is not supported yet, bit data can be collected with the SD_UT_Unknown device.<br><br>
	<i><u>Note:</u></i> As soon as the attribute model of a defined device is changed or deleted, the module re-creates a device of the selected type, and when a new message is run, the current device is deleted.<br><br>
	 <u>The following devices are supported:</u><br>
	 <ul> - Remote control SA-434-1 mini 923301&nbsp;&nbsp;&nbsp;<small>(module model: SA_434_1_mini | protocol 81)</small></ul>
	 <ul> - unitec Sound (Ursprungsmodul)&nbsp;&nbsp;&nbsp;<small>(module model: Unitec_other | protocol 30)</small></ul>
	 <ul> - unitec remote door reed switch 47031 (prepared)&nbsp;&nbsp;&nbsp;<small>(module model: Unitec_47031 | protocol 30)</small></ul>
	 <ul> - VTX-BELL_Funkklingel&nbsp;&nbsp;&nbsp;<small>(module model: VTX-BELL | protocol 79)</small></ul>
	 <ul> - Westinghouse Delancey Deckenventilator&nbsp;&nbsp;&nbsp;<small>(module model: Westinghouse_Delancey | protocol 83)</small></ul>
	 <br><br>
	<b>Define</b><br>
	<ul><code>define &lt;NAME&gt; SD_UT &lt;model&gt; &lt;Hex-address&gt;</code><br><br>
	<u>examples:</u>
		<ul>
		define &lt;NAME&gt; SD_UT Unitec_other 6FF<br>
		define &lt;NAME&gt; SD_UT SA_434_1_mini ffd<br>
		define &lt;NAME&gt; SD_UT unknown<br>
		define &lt;NAME&gt; SD_UT Westinghouse_Delancey AB5<br>
		</ul>	</ul><br><br>
	<b>Set</b><br>
	<ul>Different transmission commands are available.</ul><br>
	<ul><u>Remote control SA-434-1 mini 923301</u></ul>
	<ul><li>send&nbsp;&nbsp;<small>(Always send the same, even if the user sends another set command via console.)</small></li></ul><br>
	<ul><u>VTX-BELL_radio bell</u></ul>
	<ul><li>send&nbsp;&nbsp;<small>(Always send the same, even if the user sends another set command via console.)</small></li></ul><br>
	<ul><u>Westinghouse Delancey ceiling fan</u></ul>
	<ul><li>1_fan_minimum_speed --> Button I on the remote</li></ul>
	<ul><li>2_fan_low_speed --> Button II on the remote</li></ul>
	<ul><li>3_fan_medium_low_speed --> Button III on the remote</li></ul>
	<ul><li>4_fan_medium_speed --> Button IV on the remote</li></ul>
	<ul><li>5_fan_medium_high_speed --> Button V on the remote</li></ul>
	<ul><li>6_fan_high_speed --> Button VI on the remote</li></ul>
	<ul><li>fan_off</li></ul>
	<ul><li>fan_direction</li></ul>
	<ul><li>light_on/off</li></ul>
	<ul><li>set --> Button SET in the remote</li></ul>
	<br><br>
	<b>Get</b><br>
	<ul>N/A</ul><br><br>
	<b>Attribute</b><br>
	<ul><li><a href="#do_not_notify">do_not_notify</a></li></ul><br>
	<ul><li><a href="#ignore">ignore</a></li></ul><br>
	<ul><li><a href="#IODev">IODev</a></li></ul><br>
	<ul><li><a href="#model">model</a> (unknown,SA_434_1_mini,Unitec_47031,Unitec_other,VTX-BELL,Westinghouse_Delancey)</li></ul><br>
</ul>
=end html
=begin html_DE

<a name="SD_UT"></a>
<h3>SD_UT</h3>
<ul>Das Modul SD_UT ist ein Universalmodul vom SIGNALduino f&uuml;r Ger&auml;te oder Sensoren mit einer 12bit Nachricht.<br>
	Nach dem ersten anlegen des Ger&auml;tes <code><b>SD_UT_Unknown</b></code> muss der User das Ger&auml;t selber definieren via dem Attribut <code>model</code>.<br>
	Bei noch nicht unterst&uuml;tzen Ger&auml;ten k&ouml;nnen mit dem <code><b>SD_UT_Unknown</b></code> Ger&auml;t Bitdaten gesammelt werden.<br><br>
	<i><u>Hinweis:</u></i> Sobald das Attribut model eines definieren Ger&auml;tes verstellt oder gelöscht wird, so legt das Modul ein Ger&auml;t des gew&auml;hlten Typs neu an und mit Durchlauf einer neuen Nachricht wird das aktuelle Ger&auml;t gel&ouml;scht.<br><br>
	 <u>Es werden bisher folgende Ger&auml;te unterst&uuml;tzt:</u><br>
	 <ul> - Remote control SA-434-1 mini 923301&nbsp;&nbsp;&nbsp;<small>(Modulmodel: SA_434_1_mini | Protokoll 81)</small></ul>
	 <ul> - unitec Sound (Ursprungsmodul)&nbsp;&nbsp;&nbsp;<small>(Modulmodel: Unitec_other | Protokoll 30)</small></ul>
	 <ul> - unitec remote door reed switch 47031 (vorbereitet)&nbsp;&nbsp;&nbsp;<small>(Modulmodel: Unitec_47031 | Protokoll 30)</small></ul>
	 <ul> - VTX-BELL_Funkklingel&nbsp;&nbsp;&nbsp;<small>(Modulmodel: VTX-BELL | Protokoll 79)</small></ul>
	 <ul> - Westinghouse Delancey Deckenventilator&nbsp;&nbsp;&nbsp;<small>(Modulmodel: Westinghouse_Delancey | Protokoll 83)</small></ul>
	 <br><br>
	<b>Define</b><br>
	<ul><code>define &lt;NAME&gt; SD_UT &lt;model&gt; &lt;Hex-Adresse&gt;</code><br><br>
	<u>Beispiele:</u>
		<ul>
		define &lt;NAME&gt; SD_UT Unitec_other 6FF<br>
		define &lt;NAME&gt; SD_UT SA_434_1_mini ffd<br>
		define &lt;NAME&gt; SD_UT unknown<br>
		define &lt;NAME&gt; SD_UT Westinghouse_Delancey AB5<br>
		</ul></ul><br><br>
	<b>Set</b><br>
	<ul>Je nach Ger&auml;t sind unterschiedliche Sendebefehle verf&uuml;gbar.</ul><br>
	<ul><u>Remote control SA-434-1 mini 923301</u></ul>
	<ul><li>send&nbsp;&nbsp;<small>(Sendet immer das selbe, auch wenn der Benutzer einen anderen Set-Befehl via Konsole sendet.)</small></li></ul><br>
	<ul><u>VTX-BELL_Funkklingel</u></ul>
	<ul><li>send&nbsp;&nbsp;<small>(Sendet immer das selbe, auch wenn der Benutzer einen anderen Set-Befehl via Konsole sendet.)</small></li></ul><br>
	<ul><u>Westinghouse Delancey Deckenventilator</u></ul>
	<ul><li>1_fan_minimum_speed --> Taste I auf der Fernbedienung</li></ul>
	<ul><li>2_fan_low_speed --> Taste II auf der Fernbedienung</li></ul>
	<ul><li>3_fan_medium_low_speed --> Taste III auf der Fernbedienung</li></ul>
	<ul><li>4_fan_medium_speed --> Taste IV auf der Fernbedienung</li></ul>
	<ul><li>5_fan_medium_high_speed --> Taste V auf der Fernbedienung</li></ul>
	<ul><li>6_fan_high_speed --> Taste VI auf der Fernbedienung</li></ul>
	<ul><li>fan_off</li></ul>
	<ul><li>fan_direction</li></ul>
	<ul><li>light_on/off</li></ul>
	<ul><li>set --> Taste SET in der Fernbedienung</li></ul>
	<br><br>
	<b>Get</b><br>
	<ul>N/A</ul><br><br>
	<b>Attribute</b><br>
	<ul><li><a href="#do_not_notify">do_not_notify</a></li></ul><br>
	<ul><li><a href="#ignore">ignore</a></li></ul><br>
	<ul><li><a href="#IODev">IODev</a></li></ul><br>
	<ul><li><a href="#model">model</a> (unknown,SA_434_1_mini,Unitec_47031,Unitec_other,VTX-BELL,Westinghouse_Delancey)</li></ul><br>
</ul>
=end html_DE
=cut
