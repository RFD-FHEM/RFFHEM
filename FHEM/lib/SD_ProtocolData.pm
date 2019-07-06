################################################################################
# The file is part of the SIGNALduino project
#
# !!! useful hints !!!
# --------------------
# name        => ' '       # name of device or group of all devices
# comment     => ' '       # exact description or example of devices
# id          => ' '       # number of the protocol definition, each number only once use (accepted no .)
# knownFreqs	=> ' '       # known receiver frequency 433.92 | 868.35 (some sensor families or remote send on more frequencies)
#
# Time for one, zero, start, sync, float and pause are calculated by clockabs * value = result in microseconds, positive value stands for high signal, negative value stands for low signal
# clockrange  => [ , ]     # only MC signals | min , max of pulse / pause times in microseconds
# clockabs    => ' '       # only MU + MS signals | value for calculation of pulse / pause times in microseconds
# clockabs    => '-1'      # only MS signals | value pulse / pause times is automatically
# one         => [ , ]     # only MU + MS signals | value pair for a one bit, must be always a positive and negative factor of clockabs (accepted . | example 1.5)
# zero        => [ , ]     # only MU + MS signals | value pair for a zero bit, must be always a positive and negative factor of clockabs (accepted . | example -1.5)
# start       => [ , ]     # only MU - value pair or more for start message
# preSync     => [ , ]     # only MU + MS - value pair or more for preamble pulse of signal
# sync        => [ , ]     # only MS - value pair or more for sync pulse of signal
# float       => [ , ]     # only MU + MS signals | Convert 0F -> 01 (F) to be compatible with CUL
# pause       => [ ]       # delay when sending between two signals (clockabs * pause must be < 32768
#
# length_min  => ' '       # minimum number of bits of message length
# length_max  => ' '       # maximum number of bits of message length
# paddingbits => ' '       # pad up to x bits before call module, default is 4. | --> option is active if paddingbits not defined in message definition !
# paddingbits => '1'       # will disable padding, use this setting when using dispatchBin
# paddingbits => '2'       # is padded to an even number, that is a maximum of 1 bit
# remove_zero => 1         # removes leading zeros from output
# reconstructBit => 1      # if set, then the last bit is reconstructed if the rest is missing
#
# developId   => 'm'       # logical module is under development
# developId   => 'p'       # protocol is under development or to reserve IDs, the ID in the development attribute with developId => 'p' are only used without the other entries
# developId   => 'y'       # protocol is under development, all IDs in the development attribute with developId => 'y' are used
#
# preamble    => ' '       # prepend to converted message
# preamble    => 'u..'     # message is unknown and without module, forwarding SIGNALduino_un or FHEM DOIF
# preamble    => 'U..'     # message can be unknown and without module, no forwarding SIGNALduino_un but forwarding can FHEM DOIF
# postamble   => ' '       # appends a string to the demodulated signal
#
# clientmodule => ' '      # FHEM module for processing
# filterfunc  => ' '       # SIGNALduino_filterSign | SIGNALduino_compPattern --> SIGNALduino internal filter function, it remove the sign from the pattern, and compress message and pattern
#                          # SIGNALduino_filterMC --> SIGNALduino internal filter function, it will decode MU data via Manchester encoding
# dispatchBin => 1,        # If set to 1, data will be dispatched in binary representation to other logcial modules.
#                            If not set (default) or set to 0, data will be dispatched in hex mode to other logical modules.
# postDemodulation => \&   # only MU - SIGNALduino internal sub for processing before dispatching to a logical module
# method      => \&        # call to process this message
#                            system method: lib::SD_Protocols::MCRAW -> returns bits without editing and length check included
#
#	frequency   => ' '       # frequency to set register cc1101 to send | example: 10AB85550A
# format      => ' '       # twostate | pwm | manchester --> modulation type of the signal, only manchester use SIGNALduino internal, other types only comment
# modulematch => ' '       # RegEx on the exact message including preamble | if defined, it will be evaluated
# polarity    => 'invert'  # only MC signals | invert bits of the signal
#
##### notice #### or #### info ############################################################################################################
# !!! Between the keys and values ​​no tabs not equal to a width of 8 or please use spaces !!!
# !!! Please use first unused id for new protocols !!!
# ID´s are currently unused: 20 | 54 | 68 | 78
# ID´s need to be revised (preamble u): 5|6|19|21|22|23|24|25|26|27|28|31|36|40|42|52|56|59|63
###########################################################################################################################################
# Please provide at least three messages for each new MU/MC/MS protocol and a URL of issue in GitHub or discussion in FHEM Forum
# https://forum.fhem.de/index.php/topic,58396.975.html | https://github.com/RFD-FHEM/RFFHEM
###########################################################################################################################################

package lib::SD_ProtocolData;
{ 
	use strict;
	use warnings;
	
	our $VERSION = '1.06';
	our %protocols = (
		"0"	=>	## various weather sensors (500 | 9100)
						# ABS700 | Id:79 T: 3.3 Bat:low                MS;P1=-7949;P2=492;P3=-1978;P4=-3970;D=21232423232424242423232323232324242423232323232424;CP=2;SP=1;R=245;O;
						# Mebus | Id:237 Ch:1 T: 1.9 Bat:low           MS;P0=-9298;P1=495;P2=-1980;P3=-4239;D=1012121312131313121313121312121212121212131212131312131212;CP=1;SP=0;R=223;O;m2;
						# GT_WT_02 | Id:163 Ch:1 T: 2.9 H: 86 Bat:ok   MS;P0=531;P1=-9027;P3=-4126;P4=-2078;D=0103040304040403030404040404040404040404030303040303040304030304030304040403;CP=0;SP=1;R=249;O;m2;
						# Prologue | Id:145 Ch:0 T: 2.6, Bat:ok        MS;P0=-4152;P1=643;P2=-2068;P3=-9066;D=1310121210121212101210101212121212121212121212121010121012121212121012101212;CP=1;SP=3;R=220;O;m2;
						# Prologue | Id:145 Ch:0 T: 2.7, Bat:ok        MS;P0=-4149;P2=-9098;P3=628;P4=-2076;D=3230343430343434303430303434343434343434343434343030343030343434343034303434;CP=3;SP=2;R=218;O;m2;
			{
				name						=> 'weather (v1)',
				comment					=> 'temperature / humidity or other sensors',
				id							=> '0',
				knownFreqs      => '433.92',
				one							=> [1,-7],
				zero						=> [1,-3],
				sync						=> [1,-16],
				clockabs				=> -1,
				format					=> 'twostate',	# not used now
				preamble				=> 's',					# prepend to converted message
				postamble				=> '00',				# Append to converted message
				clientmodule		=> 'CUL_TCM97001',
				#modulematch		=> '^s[A-Fa-f0-9]+',
				length_min			=> '24',
				length_max			=> '40',
				paddingbits			=> '8',					# pad up to 8 bits, default is 4
			},
		"0.1"	=>	## other Sensors  (380 | 9650)
							# Mebus | Id:237 Ch:1 T: 1.3 Bat:low   MS;P1=416;P2=-9618;P3=-4610;P4=-2036;D=1213141313131313141313141314141414141414141313141314131414;CP=1;SP=2;R=220;O;m0;
							# Mebus | Id:151 Ch:1 T: 1.2 Bat:low   MS;P0=-9690;P3=354;P4=-4662;P5=-2107;D=3034343434343535343534343435353535353535353434353535343535;CP=3;SP=0;R=209;O;m2;
							# https://github.com/RFD-FHEM/RFFHEM/issues/63 @localhosthack0r
							# AURIOL | Id:255 T: 0.0 Bat:ok | LIDL Wetterstation   MS;P1=367;P2=-2077;P4=-9415;P5=-4014;D=141515151515151515121512121212121212121212121212121212121212121212;CP=1;SP=4;O;
			{
				name						=> 'weather (v2)',
				comment					=> 'temperature / humidity or other sensors',
				id							=> '0.1',
				knownFreqs      => '433.92',
				one							=> [1,-12],
				zero						=> [1,-6],
				sync						=> [1,-26],
				clockabs				=> -1,
				format					=> 'twostate',		# not used now
				preamble				=> 's',						# prepend to converted message
				postamble				=> '00',					# Append to converted message
				clientmodule		=> 'CUL_TCM97001',
				#modulematch		=> '^s[A-Fa-f0-9]+',
				length_min			=> '24',
				length_max			=> '32',
				paddingbits			=> '8',
			},
		"0.2"	=>	## other Sensors | for sensors how tol is runaway (260+tol | 9650)
							# Mebus | Id:151 Ch:1 T: 0.4 Bat:low   MS;P1=-2140;P2=309;P3=-4690;P4=-9695;D=2421232323232121232123232321212121212121212123212121232121;CP=2;SP=4;R=211;m1;
							# Mebus | Id:151 Ch:1 T: 0.3 Bat:low   MS;P0=-9703;P1=304;P2=-2133;P3=-4689;D=1012131312131212131213131312121212121212121212131312131212;CP=1;SP=0;R=208;
			{
				name						=> 'weather (v3)',
				comment					=> 'temperature / humidity or other sensors',
				id							=> '0.2',
				knownFreqs      => '433.92',
				one							=> [1,-18],
				zero						=> [1,-9],
				sync						=> [1,-37],
				clockabs				=> -1,
				format					=> 'twostate',		# not used now
				preamble				=> 's',						# prepend to converted message
				postamble				=> '00',					# Append to converted message
				clientmodule		=> 'CUL_TCM97001',
				#modulematch		=> '^s[A-Fa-f0-9]+',
				length_min			=> '24',
				length_max			=> '32',
				paddingbits			=> '8',
			},
		"0.3"	=>	## Pollin PFR-130
							# CUL_TCM97001_Unknown                   MS;P0=-3890;P1=386;P2=-2191;P3=-8184;D=1312121212121012121212121012121212101012101010121012121210121210101210101012;CP=1;SP=3;R=20;O;
							# CUL_TCM97001_Unknown                   MS;P0=-2189;P1=371;P2=-3901;P3=-8158;D=1310101010101210101010101210101010121210121212101210101012101012121012121210;CP=1;SP=3;R=20;O;
							# Ventus W174 | Id:17 R: 103.25 Bat:ok   MS;P3=-2009;P4=479;P5=-9066;P6=-4047;D=45434343464343434643464643464643434643464646434346464343434343434346464643;CP=4;SP=5;R=55;O;m2;
			{
				name					=> 'weather (v4)',
				comment				=> 'temperature / humidity or other sensors | Pollin PFR-130, Ventus W174 ...',
				id						=> '0.3',
				knownFreqs		=> '433.92',
				one						=> [1,-10],
				zero					=> [1,-5],
				sync					=> [1,-21],
				clockabs			=> -1,
				preamble			=> 's',				# prepend to converted message
				postamble			=> '00',			# Append to converted message
				clientmodule	=> 'CUL_TCM97001',
				length_min		=> '36',
				length_max		=> '42',
				paddingbits		=> '8',				 # pad up to 8 bits, default is 4
			},
		"0.4"	=>	## Auriol Z31092  (450 | 9200)
							# AURIOL | Id:95 T: 6.1 Bat:low    MS;P0=443;P3=-9169;P4=-1993;P5=-3954;D=030405040505050505050404040404040404040505050504050405050504040405;CP=0;SP=3;R=14;O;m0;
							# AURIOL | Id:190 T: 2.8 Bat:low   MS;P0=-9102;P1=446;P2=-3956;P3=-2008;D=10121312121212121312131213131313131313131212121313121213121213121314;CP=1;SP=0;R=212;O;m2;
			{
				name					=> 'weather (v5)',
				comment				=> 'temperature / humidity or other sensors | Auriol Z31092',
				id						=> '0.4',
				knownFreqs		=> '433.92',
				one						=> [1,-9],
				zero					=> [1,-4],
				sync					=> [1,-20],
				clockabs			=> 450,
				preamble			=> 's',				# prepend to converted message
				postamble			=> '00',			# Append to converted message
				clientmodule	=> 'CUL_TCM97001',
				length_min		=> '32',
				length_max		=> '36',
				paddingbits		=> '8',				 # pad up to 8 bits, default is 4
			},
			"1"	=>	## Conrad RSL
							# on   MS;P1=1154;P2=-697;P3=559;P4=-1303;P5=-7173;D=351234341234341212341212123412343412341234341234343434343434343434;CP=3;SP=5;R=247;O;
							# on   MS;P0=561;P1=-1291;P2=-7158;P3=1174;P4=-688;D=023401013401013434013434340134010134013401013401010101010101010101;CP=0;SP=2;R=248;m1;
			{
				name					=> 'Conrad RSL v1',
				comment				=> 'remotes and switches',
				id						=> '1',
				knownFreqs		=> '',
				one						=> [2,-1],
				zero					=> [1,-2],
				sync					=> [1,-12],
				clockabs			=> '560',
				format				=> 'twostate',		# not used now
				preamble			=> 'P1#',					# prepend to converted message
				postamble			=> '',						# Append to converted message
				clientmodule	=> 'SD_RSL',
				modulematch		=> '^P1#[A-Fa-f0-9]{8}',
				length_min		=> '20',					# 23 | userMSG 32 ?
				length_max		=> '40',					# 24 | userMSG 32 ?
			},
		"2"	=>	## Self build arduino sensor
			{
				name						=> 'Arduino',
				comment					=> 'self build arduino sensor (developModule. SD_AS module only in github)',
				developId				=> 'm',
				id							=> '2',
				knownFreqs      => '',
				one							=> [1,-2],
				zero						=> [1,-1],
				sync						=> [1,-20],
				clockabs				=> '500',
				format					=> 'twostate',
				preamble				=> 'P2#',				# prepend to converted message
				clientmodule		=> 'SD_AS',
				modulematch			=> '^P2#.{7,8}',
				length_min			=> '32',
				length_max			=> '34',				# Don't know maximal lenth of a valid message
				paddingbits			=> '8',					# pad up to 8 bits, default is 4
			},
		"3"	=>	## itv1 - remote with IC PT2262 example: ELRO | REWE | Intertek Modell 1946518 | WOFI Lamp
						## (real CP=300 | repeatpause=9300)
						# REWE Model: 0175926R -> on | v1      MS;P1=-905;P2=896;P3=-317;P4=303;P5=-9299;D=45412341414123412341414123412341234141412341414123;CP=4;SP=5;R=91;A;#;
						## (real CP=330 | repeatpause=10100)
						# ELRO AB440R -> on | v1               MS;P1=-991;P2=953;P3=-356;P4=303;P5=-10033;D=45412341234141414141234123412341234141412341414123;CP=4;SP=5;R=93;m1;A;A;
						## (real CP=300 | repeatpause=9400)
						# Kangtai Model Nr.: 6899 -> on | v1   MS;P0=-328;P1=263;P2=-954;P3=888;P5=-9430;D=15123012121230123012121230123012301212123012121230;CP=1;SP=5;R=35;m2;0;0;
						# door/window switch from CHN (PT2262 compatible) from amazon & ebay | itswitch_CHN model
						# open                                 MS;P1=-478;P2=1360;P3=468;P4=-1366;P5=-14045;D=35212134212134343421212134213434343434343421342134;CP=3;SP=5;R=30;O;m2;4;
						# close                                MS;P1=-474;P2=1373;P3=455;P4=-1367;P5=-14044;D=35212134212134343421212134213434343434343421212134;CP=3;SP=5;R=37;O;m2;
			{
				name						=> 'chip xx2262',
				comment					=> 'remote for ELRO|Kangtai|Intertek|REWE|WOFI',
				id							=> '3',
				knownFreqs      => '433.92',
				one							=> [3,-1],
				zero						=> [1,-3],
				#float					=> [-1,3],			# not full supported now later use
				sync						=> [1,-31],
				clockabs				=> -1,					# -1=auto
				format					=> 'twostate',	# not used now
				preamble				=> 'i',
				clientmodule		=> 'IT',
				modulematch			=> '^i......',
				length_min			=> '24',
				length_max			=> '24',				# Don't know maximal lenth of a valid message
			},
		"3.1"	=>	## itv1_sync40 | Intertek Modell 1946518 | ELRO
							# no decode!  MS;P0=-11440;P1=-1121;P2=-416;P5=309;P6=1017;D=150516251515162516251625162516251515151516251625151;CP=5;SP=0;R=66;
							# on | v1     MS;P1=309;P2=-1130;P3=1011;P4=-429;P5=-11466;D=15123412121234123412141214121412141212123412341234;CP=1;SP=5;R=38;  Gruppentaste, siehe Kommentar in sub SIGNALduino_bit2itv1
							# need more Device Infos / User Message
			{
				name							=> 'itv1_sync40',
				comment						=> 'IT remote control PAR 1000, ITS-150, AB440R',
				id								=> '3',
				knownFreqs				=> '',
				one								=> [3.5,-1],
				zero							=> [1,-3.8],
				float							=> [1,-1],			# fuer Gruppentaste (nur bei ITS-150,ITR-3500 und ITR-300), siehe Kommentar in sub SIGNALduino_bit2itv1
				sync							=> [1,-44],
				clockabs					=> -1,					# -1=auto
				format						=> 'twostate',	# not used now
				preamble					=> 'i',
				clientmodule			=> 'IT',
				modulematch				=> '^i......',
				length_min				=> '24',
				length_max				=> '24',				# Don't know maximal lenth of a valid message
				postDemodulation	=> \&main::SIGNALduino_bit2itv1,
			},
		"4"	=>	## arctech2
						# need more Device Infos / User Message
			{
				name						=> 'arctech2',
				id							=> '4',
				knownFreqs      => '',
				#one						=> [1,-5,1,-1],
				#zero						=> [1,-1,1,-5],
				one							=> [1,-5],
				zero						=> [1,-1],
				#float					=> [-1,3],			# not full supported now, for later use
				sync						=> [1,-14],
				clockabs				=> -1,					# -1 = auto
				format					=> 'twostate',	# tristate can't be migrated from bin into hex!
				preamble				=> 'i',					# Append to converted message
				postamble				=> '00',				# Append to converted message
				clientmodule		=> 'IT',
				modulematch			=> '^i......',
				length_min			=> '39',
				length_max			=> '44',		# Don't know maximal lenth of a valid message
			},
		"5"	=>	# Unitec, Modellnummer 6899/45108
						# https://github.com/RFD-FHEM/RFFHEM/pull/389#discussion_r237232347 @sidey79 | https://github.com/RFD-FHEM/RFFHEM/pull/389#discussion_r237245943
						# no decode!   MU;P0=-31960;P1=660;P2=401;P3=-1749;P5=276;D=232353232323232323232323232353535353232323535353535353535353535010;CP=5;R=38;
						# no decode!   MU;P0=-1757;P1=124;P2=218;P3=282;P5=-31972;P6=644;P7=-9624;D=010201020303030202030303020303030202020202020203030303035670;CP=2;R=32;
						# no decode!   MU;P0=-1850;P1=172;P3=-136;P5=468;P6=236;D=010101010101310506010101010101010101010101010101010101010;CP=1;R=30;
						# A AN         MU;P0=132;P1=-4680;P2=508;P3=-1775;P4=287;P6=192;D=123434343434343634343436363434343636343434363634343036363434343;CP=4;R=2;
						# A AUS        MU;P0=-1692;P1=132;P2=194;P4=355;P5=474;P7=-31892;D=010202040505050505050404040404040404040470;CP=4;R=27;
			{
				name						=> 'Unitec',
				comment					=> 'remote control model 6899/45108',
				id							=> '5',
				knownFreqs      => '',
				one							=> [3,-1],			# ?
				zero						=> [1,-3],			# ?
				clockabs				=> 500,					# ?
				developId				=> 'y',
				format					=> 'twostate',
				preamble				=> 'u5#',
				#clientmodule		=> '',
				#modulematch		=> '',
				length_min			=> '24',				# ?
				length_max			=> '24',				# ?
			},
		"6"	=>	## Eurochron Protocol
						# u6#B1002A022   MS;P1=-7982;P2=262;P3=-1949;P4=-948;D=21232423232424242324242424242424242424232424232323242424242424232424242324;CP=2;SP=1;R=249;O;m2;
						# u6#B1002A022   MS;P0=254;P1=-7990;P2=-1935;P3=-950;D=01020302020303030203030303030303030303020302030203030303030303020303030203;CP=0;SP=1;R=248;O;m2;
			{
				name					=> 'weather',
				comment				=> 'unknown sensor is under development',
				id						=> '6',
				knownFreqs		=> '',
				one						=> [1,-10],
				zero					=> [1,-5],
				sync					=> [1,-36],				# This special device has no sync
				clockabs			=> 220,						# -1 = auto
				format				=> 'twostate',		# tristate can't be migrated from bin into hex!
				preamble			=> 'u6#',					# Append to converted message
				#clientmodule	=> '',
				#modulematch	=> '^u......',
				length_min		=> '24',
				#length_max		=> '36',					# missing
			},
		"7"	=>	## weather sensors like EAS800z
						# Ch:1 T: 19.8 H: 11 Bat:low   MS;P1=-3882;P2=504;P3=-957;P4=-1949;D=21232424232323242423232323232323232424232323242423242424242323232324232424;CP=2;SP=1;R=249;m=2;
						# https://forum.fhem.de/index.php/topic,101682.0.html (Auriol AFW 2 A1, IAN: 297514)
						# Ch:1 T: 28.2 H: 44 Bat:ok    MS;P0=494;P1=-1949;P2=-967;P3=-3901;D=03010201010202020101020202020202010202020101020102010201020202010201010202;CP=0;SP=3;R=37;m0;
						# Ch:1 T: 24.4 H: 56 Bat:ok    MS;P1=-1940;P2=495;P3=-957;P4=-3878;D=24212321212323232121232323232323232121212123212323212321232323212121232323;CP=2;SP=4;R=20;O;m1;
			{
				name						=> 'Weather',
				comment					=> 'EAS800z, FreeTec NC-7344, HAMA TS34A, Auriol AFW 2 A1',
				id							=> '7',
				knownFreqs      => '433.92',
				one							=> [1,-4],
				zero						=> [1,-2],
				sync						=> [1,-8],
				clockabs				=> 484,
				format					=> 'twostate',
				preamble				=> 'P7#',				# prepend to converted message
				clientmodule		=> 'SD_WS07',
				modulematch			=> '^P7#.{6}[AFaf].{2}',
				length_min			=> '35',
				length_max			=> '40',
			},
		"8"	=>	## TX3 (ITTX) Protocol
						# Id:97 T: 24.4   MU;P0=-1046;P1=1339;P2=524;P3=-28696;D=010201010101010202010101010202010202020102010101020101010202020102010101010202310101010201020101010101020201010101020201020202010201010102010101020202010201010101020;CP=2;R=4;
			{
				name						=> 'TX3 Protocol',
				id							=> '8',
				knownFreqs      => '',
				one							=> [1,-2],
				zero						=> [2,-2],
				#sync						=> [1,-8],			#
				clockabs				=> 470,
				format					=> 'pwm',				#
				preamble				=> 'TX',				# prepend to converted message
				clientmodule		=> 'CUL_TX',
				modulematch			=> '^TX......',
				length_min			=> '43',
				length_max			=> '44',
				remove_zero			=> 1,						# Removes leading zeros from output
			},
		"9"	=>	## Funk Wetterstation CTW600
			{
				name					=> 'CTW 600',
				comment					=> 'FunkWS WH1080/WH3080/CTW600',
				id					=> '9',
				knownFreqs				=> '433.92 | 868.35',
				zero					=> [3,-2],
				one					=> [1,-2],
				clockabs				=> 480,					# -1 = auto undef=noclock
				#reconstructBit				=> '1',
				format					=> 'pwm',				# tristate can't be migrated from bin into hex!
				preamble				=> 'P9#',				# prepend to converted message
				clientmodule			=> 'SD_WS09',
				#modulematch			=> '^u9#.....',
				length_min			=> '60',
				length_max			=> '120',
			},
		"10"	=>	## Oregon Scientific 2
			{
				name						=> 'Oregon Scientific v2|v3',
				comment					=> 'temperature / humidity or other sensors',
				id							=> '10',
				knownFreqs      => '',
				clockrange			=> [300,520],						# min , max
				format					=> 'manchester',				# tristate can't be migrated from bin into hex!
				clientmodule		=> 'OREGON',
				modulematch			=> '^(3[8-9A-F]|[4-6][0-9A-F]|7[0-8]).*',
				length_min			=> '64',
				length_max			=> '220',
				method					=> \&main::SIGNALduino_OSV2,	# Call to process this message
				polarity				=> 'invert',
			},
		"11"	=>	## Arduino Sensor
			{
				name						=> 'Arduino',
				comment					=> 'for Arduino based sensors',
				id							=> '11',
				knownFreqs      => '',
				clockrange			=> [380,425],						# min , max
				format					=> 'manchester',				# tristate can't be migrated from bin into hex!
				preamble				=> 'P2#',								# prepend to converted message
				clientmodule		=> 'SD_AS',
				modulematch			=> '^P2#.{7,8}',
				length_min			=> '52',
				length_max			=> '56',
				method					=> \&main::SIGNALduino_AS			# Call to process this message
			},
		"12"	=>	## Hideki
							# Id:31 Ch:1 T: 22.7 Bat:ok   MC;LL=-1040;LH=904;SL=-542;SH=426;D=A8C233B53A3E0A0783;C=485;L=72;R=213;
			{
				name						=> 'Hideki',
				comment					=> 'temperature / humidity or other sensors',
				id							=> '12',
				knownFreqs      => '433.92',
				clockrange			=> [420,510],							# min, max better for Bresser Sensors, OK for hideki/Hideki/TFA too
				format					=> 'manchester',
				preamble				=> 'P12#',								# prepend to converted message
				clientmodule		=> 'Hideki',
				modulematch			=> '^P12#75.+',
				length_min			=> '71',
				length_max			=> '128',
				method					=> \&main::SIGNALduino_Hideki,	# Call to process this message
				#polarity				=> 'invert',
			},
		"13"	=>	## FLAMINGO FA21
							# https://github.com/RFD-FHEM/RFFHEM/issues/21 @sidey79
							# https://github.com/RFD-FHEM/RFFHEM/issues/233
							# 32E44F | Alarm   MS;P0=-1413;P1=757;P2=-2779;P3=-16079;P4=8093;P5=-954;D=1345121210101212101210101012121012121210121210101010;CP=1;SP=3;R=33;O;
			{
				name						=> 'FLAMINGO FA21',
				comment					=> 'FLAMINGO FA21 smoke detector (message decode as MS)',
				id							=> '13',
				knownFreqs      => '433.92',
				one							=> [1,-2],
				zero						=> [1,-4],
				sync						=> [1,-20,10,-1],
				clockabs				=> 800,
				format					=> 'twostate',
				preamble				=> 'P13#',				# prepend to converted message
				clientmodule		=> 'FLAMINGO',
				#modulematch		=> 'P13#.*',
				length_min			=> '24',
				length_max			=> '26',
			},
		"13.1"	=>	## FLAMINGO FA20RF
								# B67C3B | Alarm   MU;P0=-1384;P1=815;P2=-2725;P3=-20001;P4=8159;P5=-891;D=01010121212121010101210101345101210101210101212101010101012121212101010121010134510121010121010121210101010101212121210101012101013451012101012101012121010101010121212121010101210101345101210101210101212101010101012121212101010121010134510121010121010121;CP=1;O;
								# 1B61BB | Alarm   MU;P0=-17201;P1=112;P2=-1419;P3=-28056;P4=8092;P5=-942;P6=777;P7=-2755;D=12134567676762626762626762626767676762626762626267626260456767676262676262676262676767676262676262626762626045676767626267626267626267676767626267626262676262604567676762626762626762626767676762626762626267626260456767676262676262676262676767676262676262;CP=6;O;
								## FLAMINGO FA22RF (only MU Message) @HomeAutoUser
								# CBFAD2 | Alarm   MU;P0=-5684;P1=8149;P2=-887;P3=798;P4=-1393;P5=-2746;P6=-19956;D=0123434353534353434343434343435343534343534353534353612343435353435343434343434343534353434353435353435361234343535343534343434343434353435343435343535343536123434353534353434343434343435343534343534353534353612343435353435343434343434343534353434353435;CP=3;R=0;
								# Times measured
								# Sync 8100 microSec, 900 microSec | Bit1 2700 microSec low - 800 microSec high | Bit0 1400 microSec low - 800 microSec high | Pause Repeat 20000 microSec | 1 Sync + 24Bit, Totaltime 65550 microSec without Sync
			{
				name						=> 'FLAMINGO FA22RF / FA21RF / LM-101LD',
				comment					=> 'FLAMINGO | Unitec smoke detector (message decode as MU)',
				id							=> '13.1',
				knownFreqs      => '433.92',
				one							=> [1,-1.8],
				zero						=> [1,-3.5],
				start						=> [10,-1],
				pause						=> [-25],
				clockabs				=> 800,
				format					=> 'twostate',
				preamble				=> 'P13.1#',				# prepend to converted message
				clientmodule		=> 'FLAMINGO',
				#modulematch		=> '^P13\.?1?#[A-Fa-f0-9]+',
				length_min			=> '24',
				length_max			=> '24',
			},
		"13.2"	=>	## LM-101LD Rauchm
								# https://github.com/RFD-FHEM/RFFHEM/issues/233 @Ralf9
								# B0FFAF | Alarm   MS;P1=-2708;P2=796;P3=-1387;P4=-8477;P5=8136;P6=-904;D=2456212321212323232321212121212121212123212321212121;CP=2;SP=4;
			{
				name						=> 'LM-101LD',
				comment					=> 'Unitec smoke detector (message decode as MS)',
				id							=> '13',
				knownFreqs      => '433.92',
				zero						=> [1,-1.8],
				one							=> [1,-3.5],
				sync						=> [1,-11,10,-1.2],
				clockabs				=> 790,
				format					=> 'twostate',
				preamble				=> 'P13#',			# prepend to converted message
				clientmodule		=> 'FLAMINGO',
				#modulematch		=> '',
				length_min			=> '24',
				length_max			=> '24',
			},
		"14"	=>	## LED X-MAS Chilitec model 22640
							# https://github.com/RFD-FHEM/RFFHEM/issues/421 | https://forum.fhem.de/index.php/topic,94211.msg869214.html#msg869214 @privat58
							# power_on          MS;P0=988;P1=-384;P2=346;P3=-1026;P4=-4923;D=240123012301230123012323232323232301232323;CP=2;SP=4;R=0;O;m=1;
							# brightness_plus   MS;P0=-398;P1=974;P3=338;P4=-1034;P6=-4939;D=361034103410341034103434343434343410103434;CP=3;SP=6;R=0;
			{
				name						=> 'LED X-MAS',
				comment					=> 'Chilitec model 22640',
				id							=> '14',
				knownFreqs      => '433.92',
				one							=> [3,-1],
				zero						=> [1,-3],
				sync						=> [1,-14],
				clockabs				=> 350,
				format					=> 'twostate',
				preamble				=> 'P14#',				# prepend to converted message
				clientmodule		=> 'SD_UT',
				#modulematch			=> '^P14#.*',
				length_min			=> '20',
				length_max			=> '20',
			},
		"15"	=>	## TCM 234759
			{
				name						=> 'TCM 234759 Bell',
				comment					=> 'wireless doorbell TCM 234759 Tchibo',
				id							=> '15',
				knownFreqs      => '',
				one							=> [1,-1],
				zero						=> [1,-2],
				sync						=> [1,-45],
				clockabs				=> 700,
				format					=> 'twostate',
				preamble				=> 'P15#',				# prepend to converted message
				clientmodule		=> 'SD_BELL',
				modulematch			=> '^P15#.*',
				length_min			=> '10',
				length_max			=> '20',
			},
		"16"	=>	## Rohrmotor24 und andere Funk Rolladen / Markisen Motoren
							# ! same definition how ID 72 !
							# https://forum.fhem.de/index.php/topic,49523.0.html
							# closed   MU;P0=-1608;P1=-785;P2=288;P3=650;P4=-419;P5=4676;D=1212121213434212134213434212121343434212121213421213434212134345021213434213434342121212121343421213421343421212134343421212121342121343421213432;CP=2;
							# closed   MU;P0=-1562;P1=-411;P2=297;P3=-773;P4=668;P5=4754;D=1232341234141234141234141414123414123232341232341412323414150234123234123232323232323234123414123414123414141412341412323234123234141232341415023412323412323232323232323412341412341412341414141234141232323412323414123234142;CP=2;
			{
				name						=> 'Dooya',
				comment					=> 'Rohrmotor24 and other radio shutters / awnings motors',
				id							=> '16',
				knownFreqs      => '',
				one							=> [2,-1],
				zero						=> [1,-3],
				start						=> [17,-5],
				clockabs				=> 280,
				format					=> 'twostate',
				preamble				=> 'P16#',				# prepend to converted message
				clientmodule		=> 'Dooya',
				#modulematch		=> '',
				length_min			=> '39',
				length_max			=> '40',
			},
		"17"	=>	## arctech / intertechno
							# need more Device Infos / User Message
			{
				name							=> 'arctech / Intertechno',
				id								=> '17',
				knownFreqs        => '',
				one								=> [1,-5,1,-1],
				zero							=> [1,-1,1,-5],
				#one							=> [1,-5],
				#zero							=> [1,-1],
				sync							=> [1,-10],
				float							=> [1,-1,1,-1],
				end								=> [1,-40],
				clockabs					=> -1,					# -1 = auto
				format						=> 'twostate',	# tristate can't be migrated from bin into hex!
				preamble					=> 'i',					# Append to converted message
				postamble					=> '00',				# Append to converted message
				clientmodule			=> 'IT',
				modulematch				=> '^i......',
				length_min				=> '32',
				length_max				=> '34',				# Don't know maximal lenth of a valid message
				postDemodulation	=> \&main::SIGNALduino_bit2Arctec,
			},
		"17.1"	=>	## intertechno --> MU anstatt sonst MS (ID 17)
								# no decode!   MU;P0=344;P1=-1230;P2=-200;D=01020201020101020102020102010102010201020102010201020201020102010201020101020102020102010201020102010201010200;CP=0;R=0;
								# no decode!   MU;P0=346;P1=-1227;P2=-190;P4=-10224;P5=-2580;D=0102010102020101020201020101020102020102010102010201020102010201020201020102010201020101020102020102010102020102010201020104050201020102010102020101020201020101020102020102010102010201020102010201020201020102010201020101020102020102010102020102010201020;CP=0;R=0;
								# no decode!   MU;P0=351;P1=-1220;P2=-185;D=01 0201 0102 020101020201020101020102020102010102010201020102010201020201020102010201020101020102020102010201020102010201020100;CP=0;R=0;
								# off | v3     MU;P0=355;P1=-189;P2=-1222;P3=-10252;P4=-2604;D=01020201010201020201020101020102020102010201020102010201010201020102010201020201020101020102010201020102010201020 304 0102 01020102020101020201010201020201020101020102020102010201020102010201010201020102010201020201020101020102010201020102010201020 304 01020;CP=0;R=0;
								# https://www.sweetpi.de/blog/329/ein-ueberblick-ueber-433mhz-funksteckdosen-und-deren-protokolle
			{
				name							=> 'Intertechno',
				comment						=> 'PIR-1000 | ITT-1500',
				id								=> '17.1',
				knownFreqs				=> '433.92',
				one								=> [1,-5,1,-1],
				zero							=> [1,-1,1,-5],
				clockabs					=> 230,					# -1 = auto
				format						=> 'twostate',	# tristate can't be migrated from bin into hex!
				preamble					=> 'i',					# Append to converted message
				postamble					=> '00',				# Append to converted message
				clientmodule			=> 'IT',
				modulematch				=> '^i......',
				length_min				=> '32',
				length_max				=> '34',				# Don't know maximal lenth of a valid message
				postDemodulation	=> \&main::SIGNALduino_bit2Arctec,
			},
		"18"	=>	## Oregon Scientific v1
							# Id:3 T: 7.5 BAT:ok   MC;LL=-2721;LH=3139;SL=-1246;SH=1677;D=1A51FF47;C=1463;L=32;R=12;
			{
				name						=> 'Oregon Scientific v1',
				comment					=> 'temperature / humidity or other sensors',
				id							=> '18',
				knownFreqs      => '',
				clockrange			=> [1400,1500],					# min , max
				format					=> 'manchester',				# tristate can't be migrated from bin into hex!
				preamble				=> '',
				clientmodule		=> 'OREGON',
				modulematch			=> '^[0-9A-F].*',
				length_min			=> '32',
				length_max			=> '32',
				polarity				=> 'invert',						# invert bits
				method					=> \&main::SIGNALduino_OSV1		# Call to process this message
			},
		"19"	=>	## minify Funksteckdose
							# https://github.com/RFD-FHEM/RFFHEM/issues/114 @zag-o-mat
							# u19#E2CA7C   MU;P0=293;P1=-887;P2=-312;P6=-1900;P7=872;D=6727272010101720172720101720172010172727272720;CP=0;
							# u19#E2CA7C   MU;P0=9078;P1=-308;P2=180;P3=-835;P4=881;P5=309;P6=-1316;D=0123414141535353415341415353415341535341414141415603;CP=5;
			{
				name					=> 'minify',
				comment				=> 'remote control RC202',
				id						=> '19',
				knownFreqs		=> '',
				one						=> [3,-1],
				zero					=> [1,-3],
				clockabs			=> 300,
				format				=> 'twostate',
				preamble			=> 'u19#',				# prepend to converted message
				#clientmodule	=> '',
				#modulematch	=> '',
				length_min		=> '19',
				length_max		=> '23',					# not confirmed, length one more as MU Message
			},
		# "20"	=>	## Livolo
							# # https://github.com/RFD-FHEM/RFFHEM/issues/29
							# # MU;P0=-195;P1=151;P2=475;P3=-333;D=0101010101 02 01010101010101310101310101010101310101 02 01010101010101010101010101010101010101 02 01010101010101010101010101010101010101 02 010101010101013101013101;CP=1;
							# #
							# # protocol sends 24 to 47 pulses per message.
							# # First pulse is the header and is 595 μs long. All subsequent pulses are either 170 μs (short pulse) or 340 μs (long pulse) long.
							# # Two subsequent short pulses correspond to bit 0, one long pulse corresponds to bit 1. There is no footer. The message is repeated for about 1 second.
							# #             _____________                 ___                 _______
							# # Start bit: |             |___|    bit 0: |   |___|    bit 1: |       |___|
			# {
				# name					=> 'Livolo',
				# comment				=> 'remote control / dimmmer / switch ...',
				# id						=> '20',
				# knownFreqs		=> '',
				# one						=> [3],
				# zero					=> [1],
				# start					=> [5],
				# clockabs			=> 110,						#can be 90-140
				# format				=> 'twostate',
				# preamble			=> 'u20#',				# prepend to converted message
				# #clientmodule	=> '',
				# #modulematch	=> '',
				# length_min		=> '16',
				# #length_max		=> '',						# missing
				# filterfunc		=> 'SIGNALduino_filterSign',
			# },
		"21"	=>	## Einhell Garagentor
							# https://forum.fhem.de/index.php?topic=42373.0 @Ellert | user have no RAWMSG
							# static adress: Bit 1-28 | channel remote Bit 29-32 | repeats 31 | pause 20 ms
							# Channelvalues dez
							# 1 left 1x kurz | 2 left 2x kurz | 3 left 3x kurz | 5 right 1x kurz | 6 right 2x kurz | 7 right 3x kurz ... gedrückt
			{
				name						=> 'Einhell Garagedoor',
				comment					=> 'remote control ISC HS 434/6',
				id							=> '21',
				knownFreqs      => '',
				one							=> [-3,1],
				zero						=> [-1,3],
				#sync						=> [-50,1],
				start						=> [-50,1],
				clockabs				=> 400,					#ca 400us
				format					=> 'twostate',
				preamble				=> 'u21#',			# prepend to converted message
				#clientmodule		=> '',
				#modulematch		=> '',
				length_min			=> '32',
				length_max			=> '32',
				paddingbits			=> '1',					# This will disable padding
			},
		"22"	=>	## HAMULiGHT LED Trafo
							# https://forum.fhem.de/index.php?topic=89301.0
							# u22#8F995F34   MU;P0=-589;P1=209;P2=-336;P3=32001;P4=-204;P5=1194;P6=-1200;P7=602;D=0123414145610747474101010101074741010747410741074101010101074741010741074741414141456107474741010101010747410107474107410741010101010747410107410747414141414561074747410101010107474101074741074107410101010107474101074107474141414145610747474101010101074;CP=1;R=25;
							# u22#8F995F34   MU;P0=204;P1=-596;P2=598;P3=-206;P4=1199;P5=-1197;D=0123230123012301010101012323010123012323030303034501232323010101010123230101232301230123010101010123230101230123230303030345012323230101010101232301012323012301230101010101232301012301232303030303450123232301010101012323010123230123012301010101012323010;CP=0;R=25;
			{
				name						=> 'HAMULiGHT',
				comment					=> 'remote control for LED Transformator',
				id							=> '22',
				knownFreqs      => '433.92',
				one							=> [1,-3],
				zero						=> [3,-1],
				start						=> [6,-6],
				clockabs				=> 200,					# ca 200us
				format					=> 'twostate',
				preamble				=> 'u22#',			# prepend to converted message
				#clientmodule		=> '',
				#modulematch		=> '',
				length_min			=> '32',
				length_max			=> '32',
			},
		"23"	=>	## Pearl Sensor
			{
				name					=> 'Pearl',
				comment				=> 'unknown sensortyp',
				id						=> '23',
				knownFreqs		=> '',
				one						=> [1,-6],
				zero					=> [1,-1],
				sync					=> [1,-50],
				clockabs			=> 200,						#ca 200us
				format				=> 'twostate',
				preamble			=> 'u23#',				# prepend to converted message
				#clientmodule	=> '',
				#modulematch	=> '',
				length_min		=> '36',
				length_max		=> '44',
			},
		"24"	=>	## visivon
							# https://github.com/RFD-FHEM/RFFHEM/issues/39 @sidey79
							# u24#9F7DF825029C10   MU;P0=132;P1=500;P2=-233;P3=-598;P4=-980;P5=4526;D=012120303030303120303030453120303121212121203121212121203121212121212030303030312030312031203030303030312031203031212120303030303120303030453120303121212121203121212121203121212121212030303030312030312031203030303030312031203031212120303030;CP=0;O;
			{
				name					=> 'visivon remote',
				id						=> '24',
				knownFreqs		=> '',
				one						=> [3,-2],
				zero					=> [1,-5],
				#one					=> [3,-2],
				#zero					=> [1,-1],
				start					=> [30,-5],
				clockabs			=> 150,						#ca 150us
				format				=> 'twostate',
				preamble			=> 'u24#',				# prepend to converted message
				#clientmodule	=> '',
				#modulematch	=> '',
				length_min		=> '54',
				length_max		=> '58',
			},
		"25"	=>	## LES remote for led lamp
							# https://github.com/RFD-FHEM/RFFHEM/issues/40 @sidey79
							# u25#45A06B   MS;P0=-376;P1=697;P2=-726;P3=322;P4=-13188;P5=-15982;D=3530123010101230123230123010101010101232301230123234301230101012301232301230101010101012323012301232;CP=3;SP=5;O;
			{
				name					=> 'les led remote',
				id						=> '25',
				knownFreqs		=> '',
				one						=> [-2,1],
				zero					=> [-1,2],
				sync					=> [-46,1],				# this is a end marker, but we use this as a start marker
				clockabs			=> 350,						#ca 350us
				format				=> 'twostate',
				preamble			=> 'u25#',				# prepend to converted message
				#clientmodule	=> '',
				#modulematch	=> '',
				length_min		=> '24',
				length_max		=> '50',					# message has only 24 bit, but we get more than one message, calculation has to be corrected
			},
		"26"	=>	## some remote code, send by flamingo style remote controls
							# https://forum.fhem.de/index.php/topic,43292.msg352982.html#msg352982
							# u26#322BE3   MU;P0=1086;P1=-433;P2=327;P3=-1194;P4=-2318;P5=2988;D=01012323010123010101230123012323232323010101232324010123230101230101012301230123232323230101012323240101232301012301010123012301232323232301010123232401012323010123010101230123012323232323010101232353;CP=2;
			{
				name					=> 'remote',
				id						=> '26',
				knownFreqs		=> '',
				one						=> [1,-3],
				zero					=> [3,-1],
				# sync				=> [1,-6],				# Message is not provided as MS, due to small fact
				start					=> [1,-6],				# Message is not provided as MS, due to small fact
				clockabs			=> 380,						#ca 380
				format				=> 'twostate',
				preamble			=> 'u26#',				# prepend to converted message
				#clientmodule	=> '',
				#modulematch	=> '',
				length_min		=> '24',
				length_max		=> '24',					# message has only 24 bit, but we get more than one message, calculation has to be corrected
			},
		"27"	=>	## some remote code, send by flamingo style remote controls
							# https://forum.fhem.de/index.php/topic,43292.msg352982.html#msg352982
							# u27#322BE3   MU;P0=963;P1=-559;P2=393;P3=-1134;P4=2990;P5=-7172;D=01012323010123010101230123012323232323010101232345010123230101230101012301230123232323230101012323450101232301012301010123012301232323232301010123234501012323010123010101230123012323232323010101232323;CP=2;
			{
				name						=> 'remote',
				id							=> '27',
				knownFreqs      => '',
				one							=> [1,-2],
				zero						=> [2,-1],
				start						=> [6,-15],				# Message is not provided as MS, worakround is start
				clockabs				=> 480,						#ca 480
				format					=> 'twostate',
				preamble				=> 'u27#',				# prepend to converted message
				#clientmodule		=> '',
				#modulematch		=> '',
				length_min			=> '24',
				length_max			=> '24',
			},
		"28"	=>	## some remote code, send by aldi IC Ledspots
			{
				name						=> 'IC Ledspot',
				id							=> '28',
				knownFreqs      => '',
				one							=> [1,-1],
				zero						=> [1,-2],
				start						=> [4,-5],
				clockabs				=> 600,						#ca 600
				format					=> 'twostate',
				preamble				=> 'u28#',				# prepend to converted message
				#clientmodule		=> '',
				#modulematch		=> '',
				length_min			=> '8',
				length_max			=> '8',
			},
		"29"	=>	## example remote control with HT12E chip
							# fan_off   MU;P0=250;P1=-492;P2=166;P3=-255;P4=491;P5=-8588;D=052121212121234121212121234521212121212341212121212345212121212123412121212123452121212121234121212121234;CP=0;
							# https://forum.fhem.de/index.php/topic,58397.960.html
			{
				name						=> 'HT12e',
				comment					=> 'remote control for example Westinghouse airfan with 5 buttons',
				id							=> '29',
				knownFreqs      => '',
				one							=> [-2,1],
				zero						=> [-1,2],
				start						=> [-35,1],				# Message is not provided as MS, worakround is start
				clockabs				=> 235,						# ca 220
				format					=> 'twostate',		# there is a pause puls between words
				preamble				=> 'P29#',				# prepend to converted message
				clientmodule		=> 'SD_UT',
				modulematch			=> '^P29#.{3}',
				length_min			=> '12',
				length_max			=> '12',
			},
		"30"	=>	## a unitec remote door reed switch
							# https://forum.fhem.de/index.php?topic=43346.0 @Dr.E.Witz
							# unknown   MU;P0=-10026;P1=-924;P2=309;P3=-688;P4=-361;P5=637;D=123245453245324532453245320232454532453245324532453202324545324532453245324532023245453245324532453245320232454532453245324532453202324545324532453245324532023245453245324532453245320232454532453245324532453202324545324532453245324532023240;CP=2;O;
							# unknown   MU;P0=307;P1=-10027;P2=-691;P3=-365;P4=635;D=0102034342034203420342034201020343420342034203420342010203434203420342034203420102034342034203420342034201020343420342034203420342010203434203420342034203420102034342034203420342034201;CP=0;
			{
				name					=> 'diverse',
				comment				=> 'remote control unitec | door reed switch 47031',
				id						=> '30',
				knownFreqs		=> '',
				one						=> [-2,1],
				zero					=> [-1,2],
				start					=> [-30,1],				# Message is not provided as MS, worakround is start
				clockabs			=> 330,						# ca 300 us
				format				=> 'twostate',		# there is a pause puls between words
				preamble			=> 'P30#',				# prepend to converted message
				clientmodule	=> 'SD_UT',
				modulematch		=> '^P30#.{3}',
				length_min		=> '12',
				length_max		=> '12',				# message has only 10 bit but is paddet to 12
			},
		"31"	=>	## Pollin ISOTRONIC - 12 Tasten remote
							# remote basicadresse with 12bit -> changed if push reset behind battery cover
							# https://github.com/RFD-FHEM/RFFHEM/issues/44 @kaihs
							# u31#891EE   MU;P0=-9584;P1=592;P2=-665;P3=1223;P4=-1311;D=01234141412341412341414123232323412323234;CP=1;R=0;
							# u31#891FE   MU;P0=-12724;P1=597;P2=-667;P3=1253;P4=-1331;D=01234141412341412341414123232323232323232;CP=1;R=0;
			{
				name					=> 'Pollin ISOTRONIC',
				comment				=> 'remote control model 58608 with 12 buttons',
				id						=> '31',
				knownFreqs		=> '',
				one						=> [-1,2],
				zero					=> [-2,1],
				start					=> [-18,1],
				clockabs			=> 600,
				format				=> 'twostate',
				preamble			=> 'u31#',				# prepend to converted message
				#clientmodule	=> '',
				#modulematch	=> '',
				length_min		=> '19',
				length_max		=> '20',
			},
		"32"	=>	## FreeTec PE-6946
							# ! some message are decode as protocol 40 and protocol 62 !
							# http://www.free-tec.de/Funkklingel-mit-Voic-PE-6946-919.shtml
							# OLD # https://github.com/RFD-FHEM/RFFHEM/issues/49
							# NEW # https://github.com/RFD-FHEM/RFFHEM/issues/315
							# P32#154FFF | ring   MU;P0=-6676;P1=578;P2=-278;P4=-680;P5=176;P6=-184;D=541654165412545412121212121212121212121250545454125412541254125454121212121212121212121212;CP=1;R=0;
							# P32#154FFF | ring   MU;P0=146;P1=245;P3=571;P4=-708;P5=-284;P7=-6689;D=14351435143514143535353535353535353535350704040435043504350435040435353535353535353535353507040404350435043504350404353535353535353535353535070404043504350435043504043535353535353535353535350704040435043504350435040435353535353535353535353507040404350435;CP=3;R=0;O;
							# P32#154FFF | ring   MU;P0=-6680;P1=162;P2=-298;P4=253;P5=-699;P6=555;D=45624562456245456262626262626262626262621015151562156215621562151562626262626262626262626210151515621562156215621515626262626262626262626262;CP=6;R=0;
			{
				name						=> 'FreeTec PE-6946',
				comment					=> 'wireless doorbell',
				id							=> '32',
				knownFreqs      => '',
				one							=> [4,-2],
				zero						=> [1,-5],
				start						=> [1,-45],				# neuerdings MU Erknnung
				#sync						=> [1,-49],				# old MS Erkennung
				clockabs				=> 150,
				format					=> 'twostate',
				preamble				=> 'P32#',				# prepend to converted message
				clientmodule		=> 'SD_BELL',
				modulematch			=> '^P32#.*',
				length_min			=> '24',
				length_max			=> '24',
			},
		"33"	=>	## Thermo-/Hygrosensor S014, renkforce E0001PA, Conrad S522, TX-EZ6 (Weatherstation TZS First Austria)
							# https://forum.fhem.de/index.php?topic=35844.0 @BrainHunter
							# Id:62 Ch:1 T: 21.1 H: 76 Bat:ok   MS;P0=-7871;P2=-1960;P3=578;P4=-3954;D=030323232323434343434323232323234343434323234343234343234343232323432323232323232343234;CP=3;SP=0;R=0;m=0;
			{
				name					=> 'weather',
				comment				=> 'S014, TFA 30.3200, TCM, Conrad S522, renkforce E0001PA, TX-EZ6',
				id						=> '33',
				knownFreqs		=> '433.92',
				one						=> [1,-8],
				zero					=> [1,-4],
				sync					=> [1,-16],
				clockabs			=> '500',
				format				=> 'twostate',	# not used now
				preamble			=> 'W33#',			# prepend to converted message
				postamble			=> '',					# Append to converted message
				clientmodule	=> 'SD_WS',
				#modulematch	=> '',
				length_min		=> '42',
				length_max		=> '44',
			},
		"33.1"	=>	## Thermo-/Hygrosensor TFA 30.3200
							# https://github.com/RFD-FHEM/SIGNALDuino/issues/113
							# SD_WS_33_TH_1   T: 18.8 H: 53   MS;P1=-7796;P2=745;P3=-1976;P4=-3929;D=21232323242324232324242323232323242424232323242324242323242324232324242323232323232424;CP=2;SP=1;R=30;O;m2;
							# SD_WS_33_TH_2   T: 21.9 H: 49   MS;P1=-7762;P2=747;P3=-1976;P4=-3926;D=21232324232324242323242323232424242424232423232324242323232324232324242323232324242424;CP=2;SP=1;R=32;O;m1;
							# SD_WS_33_TH_3   T: 19.7 H: 53   MS;P1=758;P2=-1964;P3=-3929;P4=-7758;D=14121213121313131213121212131212131313121213121213131212131213121213131212121212121212;CP=1;SP=4;R=48;O;m1;
			{
				name          => 'TFA 30.3200',
				comment       => 'Thermo-/Hygrosensor TFA 30.3200 (CP=750)',
				id            => '33.1',
				knownFreqs    => '433.92',
				one           => [1,-5.6],	# 736,-4121
				zero          => [1,-2.8],	# 736,-2060
				sync          => [1,-11],		# 736,-8096
				clockabs      => 736,
				format        => 'twostate',	# not used now
				preamble      => 'W33#',
				clientmodule  => 'SD_WS',
				length_min    => '42',
				length_max    => '44',
			},
		"33.2" => ## Tchibo Wetterstation
							# https://forum.fhem.de/index.php/topic,58397.msg880339.html#msg880339 @Doublefant
							# passt bei 33 und 33.2:
							# SD_WS_33_TH_1   T: 5.1 H: 41   MS;P1=399;P2=-7743;P3=-2038;P4=-3992;D=12131314141414141313131413131314141414131313141314131414131314131314131313131314131314;CP=1;SP=2;R=230;O;m2;
							# SD_WS_33_TH_1   T: 5.1 H: 41   MS;P1=399;P2=-7733;P3=-2043;P4=-3991;D=12131314141414141313131413131314141414131313141314131414131314131314131313131314131314;CP=1;SP=2;R=230;O;
							# passt nur bei 33.2:
							# SD_WS_33_TH_1   T: 5.1 H: 41   MS;P1=393;P2=-7752;P3=-2047;P4=-3993;D=12131314141414141313131413131314141414131313141314131414131314131314131313131314131314;CP=1;SP=2;R=230;O;m1;
							# SD_WS_33_TH_1   T: 5.1 H: 41   MS;P1=396;P2=-7759;P3=-2045;P4=-4000;D=12131314141414141313131413131314141414131313141314131414131314131314131313131314131314;CP=1;SP=2;R=230;O;m0;
			{
				name          => 'Tchibo',
				comment       => 'Tchibo weatherstation (CP=400)',
				id            => '33.2',
				knownFreqs    => '433.92',
				one           => [1,-10],     # 400,-4000
				zero          => [1,-5],      # 400,-2000
				sync          => [1,-19],     # 400,-7600
				clockabs      => 400,
				format        => 'twostate',
				preamble      => 'W33#',
				postamble     => '',
				clientmodule  => 'SD_WS',
				length_min    => '42',
				length_max    => '44',
			},
		"34"	=>	## QUIGG GT-7000 Funk-Steckdosendimmer | transmitter DMV-7000 - receiver DMV-7009AS
							# https://github.com/RFD-FHEM/RFFHEM/issues/195 | https://forum.fhem.de/index.php/topic,38831.msg361341.html#msg361341 @StefanW
							# Ch1_on       MU;P0=-5284;P1=583;P2=-681;P3=1216;P4=-1319;D=012341412323232341412341412323234123232341;CP=1;R=16;
							# Ch1_off      MU;P0=-9812;P1=589;P2=-671;P3=1261;P4=-1320;D=012341412323232341412341412323232323232323;CP=3;R=19;
							# Ch2_on       MU;P0=-9832;P1=577;P2=-670;P3=1219;P4=-1331;D=012341412323232341412341414123234123234141;CP=1;R=16;
							# Ch2_off      MU;P0=-8816;P1=594;P2=-662;P3=1263;P4=-1330;D=012341412323232341412341414123232323234123;CP=1;R=16;
							# Ch3_on       MU;P0=-677;P1=581;P2=1250;P3=-1319;D=010231310202020231310231310231023102020202;CP=1;R=18;
							# Ch3_off      MU;P0=-29120;P1=603;P2=-666;P3=1235;P4=-1307;D=012341412323232341412341412341232323232341;CP=1;R=16;
							## LIBRA GmbH (LIDL) TR-502MSV
							# no decode!   MU;P0=-12064;P1=71;P2=-669;P3=1351;P4=-1319;D=012323414141234123232323232323232323232323;
							# Ch1_off      MU;P0=697;P1=-1352;P2=-679;P3=1343;D=01010101010231023232323232323232323232323;CP=0;R=27;
			{
				name					=> 'QUIGG | LIBRA',
				comment				=> 'remote control DMV-7000, TR-502MSV',
				id						=> '34',
				knownFreqs		=> '433.92',
				one						=> [-1,2],
				zero					=> [-2,1],
				start					=> [1],
				pause					=> [-15],   # 9900
				clockabs			=> '660',
				format				=> 'twostate',
				preamble			=> 'P34#',
				clientmodule	=> 'SD_UT',
				#modulematch	=> '',
				length_min		=> '20',
				length_max		=> '20',
			},
		"35"	=>	## Homeeasy
							# off | vHE800   MS;P0=907;P1=-376;P2=266;P3=-1001;P6=-4860;D=2601010123230123012323230101012301230101010101230123012301;CP=2;SP=6;
			{
				name							=> 'HomeEasy HE800',
				id								=> '35',
				knownFreqs				=> '',
				one								=> [1,-4],
				zero							=> [3.4,-1],
				sync							=> [1,-18],
				clockabs					=> '280',
				format						=> 'twostate',		# not used now
				preamble					=> 'ih',					# prepend to converted message
				postamble					=> '',						# Append to converted message
				clientmodule			=> 'IT',
				#modulematch			=> '',
				length_min				=> '28',
				length_max				=> '40',
				postDemodulation	=> \&main::SIGNALduino_HE800,
			},
		"36"	=>	## remote - cheap wireless dimmer
							# https://forum.fhem.de/index.php/topic,38831.msg394238.html#msg394238 @Steffenm
							# u36#CE8501   MU;P0=499;P1=-1523;P2=-522;P3=10220;P4=-10047;D=01020202020202020134010102020101010201020202020102010202020202020201340101020201010102010202020201020102020202020202013401010202010101020102020202010201020202020202020134010102020101010201020202020102010202020202020201340101020201010102010;CP=0;O;
							# u36#CE8501   MU;P0=-520;P1=500;P2=-1523;P3=10220;P4=-10043;D=01010101210121010101010101012341212101012121210121010101012101210101010101010123412121010121212101210101010121012101010101010101234121210101212121012101010101210121010101010101012341212101012121210121010101012101210101010101010123412121010;CP=1;O;
							# u36#CE8501   MU;P0=498;P1=-1524;P2=-521;P3=10212;P4=-10047;D=01010102010202020201020102020202020202013401010202010101020102020202010201020202020202020134010102020101010201020202020102010202020202020201340101020201010102010202020201020102020202020202013401010202010101020102020202010201020202020202020;CP=0;O;
			{
				name						=> 'remote',
				comment					=> 'cheap wireless dimmer',
				id							=> '36',
				knownFreqs      => '433.92',
				one							=> [1,-3],
				zero						=> [1,-1],
				start						=> [20,-20],
				clockabs				=> '500',
				format					=> 'twostate',		# not used now
				preamble				=> 'u36#',				# prepend to converted message
				postamble				=> '',						# Append to converted message
				#clientmodule		=> '',
				#modulematch		=> '',
				length_min			=> '24',
				length_max			=> '24',
			},
		"37"	=>	## Bresser 7009994
							# ! some message are decode as protocol 61 and protocol 84 !
							# Ch:1 T: 22.7 H: 48 Bat:ok   MU;P0=729;P1=-736;P2=483;P3=-251;P4=238;P5=-491;D=010101012323452323454523454545234523234545234523232345454545232345454545452323232345232340;CP=4;
							# Ch:3 T: 16.2 H: 51 Bat:ok   MU;P0=-790;P1=-255;P2=474;P4=226;P6=722;P7=-510;D=721060606060474747472121212147472121472147212121214747212147474721214747212147214721212147214060606060474747472121212140;CP=4;R=216;
							# short pulse of 250 us followed by a 500 us gap is a 0 bit
							# long pulse of 500 us followed by a 250 us gap is a 1 bit
							# sync preamble of pulse, gap, 750 us each, repeated 4 times
		{
				name						=> 'Bresser 7009994',
				comment					=> 'temperature / humidity sensor',
				id							=> '37',
				knownFreqs      => '',
				one							=> [2,-1],
				zero						=> [1,-2],
				start						=> [3,-3,3,-3],
				clockabs				=> '250',
				format					=> 'twostate',		# not used now
				preamble				=> 'W37#',				# prepend to converted message
				clientmodule		=> 'SD_WS',
				length_min			=> '40',
				length_max			=> '41',
		},
		"38"	=>	## Rosenstein & Soehne, PEARL NC-3911, NC-3912, refrigerator thermometer - 2 channels
							# https://github.com/RFD-FHEM/RFFHEM/issues/504 - Support for NC-3911 Fridge Temp, @MoskitoHorst, 2019-02-05
							# Id:8B Ch:1 T: 6.3   MU;P0=-747;P1=-493;P2=231;P3=484;P4=-248;P6=-982;P7=718;D=1213434212134343421342121343434343434212670707070342121213421343434212134212134212121343421213434342134212134343434343421267070707034212121342134343421213421213421212134342121343434213421213434343434342126707070703421212134213434342121342121342121;CP=2;
							# Id:A8 Ch:2 T:-1.8   MU;P0=-241;P1=491;P2=249;P3=-482;P4=-962;P5=743;P6=-723;D=01023102323232310101010232323102310232323232310101010231024565656561023102310232323102310232323231010101023232310231023232323231010101023102456565656102310231023232310231023232323101010102323231023102323232323101010102310245656565610231023102323231023102;CP=2;O;
							# Id:A8 Ch:2 T: 5.4   MU;P0=-971;P1=733;P2=-731;P3=488;P4=-244;P5=248;P6=-480;P7=-368;D=01212121234563456345656563456345656563456575634563456345634345656345634343434345650121212123456345634565656345634565656345656563456345634563434565634563434343434565012121212345634563456565634563456565634565656345634563456343456563456343434343456501212121;CP=5;O;
			{
				name         => 'NC-3911',
				comment      => 'Refrigerator thermometer',
				id           => '38',
				knownFreqs   => '433.92',
				one          => [2,-1],
				zero         => [1,-2],
				start        => [3,-3,3,-3,3,-3,3,-3],
				clockabs     => 250,
				format       => 'twostate',
				preamble     => 'W38#',
				clientmodule => 'SD_WS',
				modulematch  => '^W38#.*',
				length_min   => '36',
				length_max   => '36',
			},
		"39"	=>	## X10 Protocol
							# https://github.com/RFD-FHEM/RFFHEM/issues/65 @wherzig
							# Closed | Bat:ok   MU;P0=10530;P1=-2908;P2=533;P3=-598;P4=-1733;P5=767;D=0123242323232423242324232324232423242323232324232323242424242324242424232423242424232501232423232324232423242323242324232423232323242323232424242423242424242324232424242325012324232323242324232423232423242324232323232423232324242424232424242423242324242;CP=2;O;
			{
				name							=> 'X10 Protocol',
				id								=> '39',
				knownFreqs				=> '',
				one								=> [1,-3],
				zero							=> [1,-1],
				start							=> [17,-7],
				clockabs					=> 560,
				format						=> 'twostate',
				preamble					=> '', # prepend to converted message
				clientmodule			=> 'RFXX10REC',
				#modulematch		=> '^TX......',
				length_min				=> '32',
				length_max				=> '44',
				paddingbits				=> '8',
				postDemodulation	=> \&main::SIGNALduino_lengtnPrefix,
				filterfunc				=> 'SIGNALduino_compPattern',
			},
		"40"	=>	## Romotec
							# ! some message are decode as protocol 19 and protocol 40 not decode !
							# https://github.com/RFD-FHEM/RFFHEM/issues/71 @111apieper
							# u19#6B3190   MU;P0=300;P1=-772;P2=674;P3=-397;P4=4756;P5=-1512;D=4501232301230123230101232301010123230101230103;CP=0;
							# no decode!   MU;P0=-132;P1=-388;P2=675;P4=271;P5=-762;D=012145212145452121454545212145452145214545454521454545452145454541;CP=4;
			{
				name						=> 'Romotec ',
				comment					=> 'Tubular motor',
				id							=> '40',
				knownFreqs      => '',
				one							=> [3,-2],
				zero						=> [1,-3],
				start						=> [1,-2],
				clockabs				=> 270,
				preamble				=> 'u40#',	# prepend to converted message
				#clientmodule		=> '',
				#modulematch		=> '',
				length_min			=> '12',
				#length_max			=> '',			# missing
			},
		"41"	=>	## Elro (Smartwares) Doorbell DB200 / 16 melodies
							# https://github.com/RFD-FHEM/RFFHEM/issues/70 @beatz0001
							# P41#F813D593 | doubleCode_part1   MS;P0=-526;P1=1450;P2=467;P3=-6949;P4=-1519;D=231010101010242424242424102424101010102410241024101024241024241010;CP=2;SP=3;O;
							# P41#219D85D3 | doubleCode_part2   MS;P0=468;P1=-1516;P2=1450;P3=-533;P4=-7291;D=040101230101010123230101232323012323010101012301232323012301012323;CP=0;SP=4;O;
							# unitec Modell:98156+98YK / 36 melodies
							# repeats 15, change two codes every 15 repeats --> one button push, 2 codes
							# P41#08E8D593 | doubleCode_part1   MS;P0=1474;P1=-521;P2=495;P3=-1508;P4=-6996;D=242323232301232323010101230123232301012301230123010123230123230101;CP=2;SP=4;R=51;m=0;
							# P41#754485D3 | doubleCode_part2   MS;P1=-7005;P2=482;P3=-1511;P4=1487;P5=-510;D=212345454523452345234523232345232345232323234523454545234523234545;CP=2;SP=1;R=47;m=2;
							## KANGTAI Doorbell (Pollin 94-550405)
							# https://github.com/RFD-FHEM/RFFHEM/issues/365 @trosenda
							# The bell button alternately sends two different codes
							# P41#BA2885D3 | doubleCode_part1   MS;P0=1390;P1=-600;P2=409;P3=-1600;P4=-7083;D=240123010101230123232301230123232301232323230123010101230123230101;CP=2;SP=4;R=248;O;m0;
							# P41#1791D593 | doubleCode_part2   MS;P1=403;P2=-7102;P3=-1608;P4=1378;P5=-620;D=121313134513454545451313451313134545451345134513454513134513134545;CP=1;SP=2;R=5;O;m0;
			{
				name					=> 'wireless doorbell',
				comment				=> 'Elro (DB200) / KANGTAI (Pollin 94-550405) / unitec',
				id						=> '41',
				knownFreqs		=> '433.92',
				zero					=> [1,-3],
				one						=> [3,-1],
				sync					=> [1,-14],
				clockabs			=> 500,
				format				=> 'twostate',
				preamble			=> 'P41#', # prepend to converted message
				clientmodule	=> 'SD_BELL',
				modulematch		=> '^P41#.*',
				length_min		=> '32',
				length_max		=> '32',
			},
		"42"	=>	## Pollin 551227
							# https://github.com/RFD-FHEM/RFFHEM/issues/390 @trosenda
							# FE1FF87 | ring   MU;P0=1446;P1=-487;P2=477;D=0101012121212121212121212101010101212121212121212121210101010121212121212121212121010101012121212121212121212101010101212121212121212121210101010121212121212121212121010101012121212121212121212101010101212121212121212121210101010121212121212121212121010;CP=2;R=93;O;
							# FE1FF87 | ring   MU;P0=-112;P1=1075;P2=-511;P3=452;P5=1418;D=01212121232323232323232323232525252523232323232323232323252525252323232323232323232325252525;CP=3;R=77;
			{
				name					=> 'wireless doorbell',
				comment				=> 'Pollin 551227',
				id						=> '42',
				knownFreqs		=> '433.92',
				one						=> [1,-1],
				zero					=> [3,-1],
				start					=> [1,-1,1,-1,1,-1,],
				clockabs			=> 500,
				format				=> 'twostate',
				preamble			=> 'P42#',
				clientmodule	=> 'SD_BELL',
				#modulematch		=> '^P42#.*',
				length_min		=> '28',
				length_max		=> '120',
			},
		"43"	=>	## Somfy RTS
							# received=40, parsestate=on   MC;LL=-1405;LH=1269;SL=-723;SH=620;D=98DBD153D631BB;C=669;L=56;R=229;
			{
				name					=> 'Somfy RTS',
				id						=> '43',
				knownFreqs		=> '',
				clockrange		=> [610,680],								# min , max
				format				=> 'manchester',
				preamble			=> 'Ys',
				clientmodule	=> 'SOMFY',									# not used now
				modulematch		=> '^Ys[0-9A-F]{14}',
				length_min		=> '56',
				length_max		=> '57',
				method				=> \&main::SIGNALduino_SomfyRTS,	# Call to process this message
				msgIntro			=> 'SR;P0=-2560;P1=2560;P3=-640;D=10101010101010113;',
				#msgOutro			=> 'SR;P0=-30415;D=0;',
				frequency			=> '10AB85550A',
			},
		"44"	=>	## Bresser Temeo Trend
			{
				name					=> 'BresserTemeo',
				comment				=> 'temperature / humidity sensor',
				id						=> '44',
				knownFreqs		=> '',
				clockabs			=> 500,
				zero					=> [4,-4],
				one						=> [4,-8],
				start					=> [8,-8],
				preamble			=> 'W44#',
				clientmodule	=> 'SD_WS',
				modulematch		=> '^W44#[A-F0-9]{18}',
				length_min		=> '64',
				length_max		=> '72',
			},
		"44.1"	=>	## Bresser Temeo Trend
			{
				name					=> 'BresserTemeo',
				comment				=> 'temperature / humidity sensor',
				id						=> '44',
				knownFreqs		=> '',
				clockabs			=> 500,
				zero					=> [4,-4],
				one						=> [4,-8],
				start					=> [8,-12],
				preamble			=> 'W44x#',
				clientmodule	=> 'SD_WS',
				modulematch		=> '^W44x#[A-F0-9]{18}',
				length_min		=> '64',
				length_max		=> '72',
			},
		"45"	=>	## Revolt
							#	P:126.8 E:35.88 V:232 C:0.68 Pf:0.8   MU;P0=-8320;P1=9972;P2=-376;P3=117;P4=-251;P5=232;D=012345434345434345454545434345454545454543454343434343434343434343434543434345434343434545434345434343434343454343454545454345434343454345434343434343434345454543434343434345434345454543454343434543454345434545;CP=3;R=2;
			{
				name							=> 'Revolt',
				id								=> '45',
				knownFreqs				=> '',
				one								=> [2,-2],
				zero							=> [1,-2],
				start							=> [83,-3],
				clockabs					=> 120,
				preamble					=> 'r', # prepend to converted message
				clientmodule			=> 'Revolt',
				modulematch				=> '^r[A-Fa-f0-9]{22}',
				length_min				=> '84',
				length_max				=> '120',
				postDemodulation	=> sub {	my ($name, @bit_msg) = @_;	my @new_bitmsg = splice @bit_msg, 0,88;	return 1,@new_bitmsg; },
			},
		"46"	=>	## Tedsen Fernbedienungen u.a. für Berner Garagentorantrieb GA401 und Geiger Antriebstechnik Rolladensteuerung
							# https://github.com/RFD-FHEM/RFFHEM/issues/91
							# remote TEDSEN SKX1MD 433.92 MHz - 1 button | settings via 9 switch on battery compartment
							# compatible with doors: BERNER SKX1MD, ELKA SKX1MD, TEDSEN SKX1LC, TEDSEN SKX1 - 1 Button
							# Tedsen_SKX1xx | Button_1   MU;P0=-15829;P1=-3580;P2=1962;P3=-330;P4=245;P5=-2051;D=1234523232345234523232323234523234540 0 2345 2323 2345 2345 2323 2323 2345 2323 454 023452323234523452323232323452323454023452323234523452323232323452323454023452323234523452323232323452323454023452323234523452323;CP=2;
							# Tedsen_SKX1xx | Button_1   MU;P0=-1943;P1=1966;P2=-327;P3=247;P5=-15810;D=012301212123012301212121212301212303           5 1230 1212 1230 1230 1212 1212 1230 1212 303 5 1230 1212 1230 1230 1212 1212 1230 1212 303 51230121212301230121212121230121230351230121212301230121212121230121230351230;CP=1;
							## GEIGER GF0001, 2 Button, DIP-Schalter: + 0 + - + + - 0 0
							# https://forum.fhem.de/index.php/topic,39153.0.html
							# Tedsen_SKX2xx | Button_1   MU;P0=-15694;P1=2009;P2=-261;P3=324;P4=-2016;D=01212123412123434121212123434123434301212123412123434121212123434123434301212123412123434121212123434123434301212123412123434121212123434123434301212123412123434121212123434123434301;CP=3;R=30;
							# Tedsen_SKX2xx | Button_2   MU;P0=-32001;P1=2072;P2=-260;P3=326;P4=-2015;P5=-15769;D=01212123412123434121212123434123412351212123412123434121212123434123412351212123412123434121212123434123412351212123412123434121212123434123412351212123412123434121212123434123412351212123412123434121212123434123412351212123412123434121212123434123412351;CP=3;R=37;O;
							# ?
							# P46#CC0A0   MU;P0=313;P1=1212;P2=-309;P4=-2024;P5=-16091;P6=2014;D=01204040562620404626204040404040462046204040562620404626204040404040462046204040562620404626204040404040462046204040562620404626204040404040462046204040;CP=0;R=236;
							# P46#ECF20   MU;P0=-15770;P1=2075;P2=-264;P3=326;P4=-2016;P5=948;D=012121234121234341212121234341234343012125;CP=3;R=208;
			{
				name            => 'SKXxxx, GF0x0x',
				comment         => 'remote controls Tedsen SKXxxx, GEIGER GF0x0x',
				id              => '46',
				knownFreqs      => '433.92',
				one             => [7,-1],
				zero            => [1,-7],
				start           => [-55],
				clockabs        => 290,
				reconstructBit  => '1',
				format          => 'tristate', # not used now
				preamble        => 'P46#',
				clientmodule    => 'SD_UT',
				modulematch     => '^P46#.*',
				length_min      => '14',       # ???
				length_max      => '18',
			},
		"47"	=>	## Maverick
							# Food: 23 BBQ: 22   MC;LL=-507;LH=490;SL=-258;SH=239;D=AA9995599599A959996699A969;C=248;L=104;
			{
				name						=> 'Maverick',
				comment					=> 'BBQ / food thermometer',
				id							=> '47',
				knownFreqs      => '',
				clockrange			=> [180,260],
				format					=> 'manchester',
				preamble				=> 'P47#',						# prepend to converted message
				clientmodule		=> 'SD_WS_Maverick',
				modulematch			=> '^P47#[569A]{12}.*',
				length_min			=> '100',
				length_max			=> '108',
				method					=> \&main::SIGNALduino_Maverick,		# Call to process this message
				#polarity				=> 'invert'
			},
		"48"	=>	## Joker Dostmann TFA 30.3055.01
							# ! some message are decode as protocol 42 and protocol 50 !
							# https://github.com/RFD-FHEM/RFFHEM/issues/92 @anphiga
							# U48#016C7E18004C   MU;P0=591;P1=-1488;P2=-3736;P3=1338;P4=-372;P6=-988;D=23406060606063606363606363606060636363636363606060606363606060606060606060606060636060636360106060606060606063606363606363606060636363636363606060606363606060606060606060606060636060636360106060606060606063606363606363606060636363636363606060606363606060;CP=0;O;
							# U48#01657EB80034   MU;P0=96;P1=-244;P2=510;P3=-1000;P4=1520;P5=-1506;D=01232323232343234343232343234323434343434343234323434343232323232323232323232323234343234325232323232323232343234343232343234323434343434343234323434343232323232323232323232323234343234325232323232323232343234343232343234323434343434343234323434343232323;CP=2;O;
			{
				name						=> 'TFA Dostmann',
				comment					=> 'Funk-Thermometer Joker TFA 30.3055.01',
				id							=> '48',
				knownFreqs      => '',
				clockabs				=> 250, 						# In real it is 500 but this leads to unprceise demodulation
				one							=> [-4,6],
				zero						=> [-4,2],
				start						=> [-6,2],
				format					=> 'twostate',
				preamble				=> 'U48#',						# prepend to converted message
				#clientmodule		=> '',
				modulematch			=> '^U48#.*',
				length_min			=> '47',
				length_max			=> '48',
			},
		"49"	=>	## QUIGG / ALDI GT-9000
							# ! some message are decode as protocol 27 !
							# https://github.com/RFD-FHEM/RFFHEM/issues/93 @TiEr92
							# U49#8B2DB0   MU;P0=-563;P1=479;P2=991;P3=-423;P4=361;P5=-1053;P6=3008;P7=-7110;D=2345454523452323454523452323452323452323454545456720151515201520201515201520201520201520201515151567201515152015202015152015202015202015202015151515672015151520152020151520152020152020152020151515156720151515201520201515201520201520201520201515151;CP=1;R=21;
			{
				name						=> 'QUIGG_GT-9000',
				comment					=> 'remote control',
				id							=> '49',
				knownFreqs      => '',
				clockabs				=> 400,
				one							=> [2,-1.2],
				zero						=> [1,-3],
				start						=> [6,-15],
				format					=> 'twostate',
				preamble				=> 'U49#',						# prepend to converted message
				#clientmodule		=> '',
				modulematch			=> '^U49#.*',
				length_min			=> '22',
				length_max			=> '28',
			},
		"50"	=>	## Opus XT300
							# https://github.com/RFD-FHEM/RFFHEM/issues/99 @sidey79
							# Ch:1 T: 25 H: 5   MU;P0=248;P1=-21400;P2=545;P3=-925;P4=1368;P5=-12308;D=01232323232323232343234323432343234343434343234323432343434343432323232323232323232343432323432345232323232323232343234323432343234343434343234323432343434343432323232323232323232343432323432345232323232323232343234323432343234343434343234323432343434343;CP=2;O;
							# CH:1 T: 18 H: 5   W50#FF55053AFF93    MU;P2=-962;P4=508;P5=1339;P6=-12350;D=46424242424242424252425242524252425252525252425242525242424252425242424242424242424252524252524240;CP=4;R=0;
							# CH:3 T: 18 H: 5   W50#FF57053AFF95    MU;P2=510;P3=-947;P5=1334;P6=-12248;D=26232323232323232353235323532323235353535353235323535323232353235323232323232323232353532353235320;CP=2;R=0;

			{
				name					=> 'Opus_XT300',
				comment					=> 'sensor for ground humidity',
				id						=> '50',
				knownFreqs				=> '433.92',
				clockabs				=> 500,
				zero					=> [3,-2],
				one						=> [1,-2],
				# start				  	=> [-25],				# Wenn das startsignal empfangen wird, fehlt das 1 bit
				reconstructBit			=> '1',
				format					=> 'twostate',
				preamble				=> 'W50#',				# prepend to converted message
				clientmodule			=> 'SD_WS',
				modulematch				=> '^W50#.*',
				length_min				=> '47',
				length_max				=> '48',
			},
		"51"	=>	## weather sensors
							# https://github.com/RFD-FHEM/RFFHEM/issues/118 @Stertzi
							# IAN 275901 Id:08 Ch:3 T:6.3 H:95    MS;P0=-4074;P1=608;P2=-1825;P3=-15980;P4=1040;P5=-975;P6=-7862;D=16121212121012121212101212101212101210121012121010121010121012121012101210121210101345454545;CP=1;SP=6;
							# IAN 275901 Id:08 Ch:3 T:8.5 H:95    MS;P0=611;P1=-4073;P2=-1825;P3=-15980;P4=1041;P5=-974;P6=-7860;D=06020202020102020202020201010202010201020102010201010102010102020102010201020201010345454545;CP=0;SP=6;
							# https://github.com/RFD-FHEM/RFFHEM/issues/122 @6040
							# IAN 114324 Id:11 Ch:1 T:17.3 H:40   MS;P0=-1848;P1=577;P2=-4066;P3=-15997;P4=1013;P5=-1001;P6=-7875;D=16101010121010101210101210101012101012101212121212121012121012101010101010101010121345454545;CP=1;SP=6;O;
							# IAN 114324 Id:71 Ch:1 T:17.3 H:41   MS;P0=-16000;P1=1002;P2=-1010;P3=572;P4=-7884;P5=-1817;P6=-4102;D=34353636363535353635363535353535353536353636363636363536363536353535353536353535363012121212;CP=3;SP=4;O;
							# https://github.com/RFD-FHEM/RFFHEM/issues/161
							# IAN 60107 Id:F0 Ch:1 T:-2.9 H:76    MS;P2=594;P3=-7386;P4=-4081;P5=-1873;D=2324242424252525252525242425252525252425252425252524242424252424242524242525252524;CP=2;SP=3;R=242;
							# IAN 60107 Id:F0 Ch:1 T:0.9 H:81     MS;P2=604;P3=-7258;P4=-4179;P5=-1852;D=2324242424252525252525242525252524252425252424252425242524242525252525252425252524;CP=2;SP=3;R=242;
							# IAN 60107 Id:F0 Ch:1 T:13.6 H:51    MS;P2=634;P3=-8402;P4=-4079;P5=-1832;D=2324242424252525252425252425252524252425242425242424252524252425242525252425252524;CP=2;SP=3;R=244;
			{
				name						=> 'weather',
				comment					=> 'Lidl Weatherstation IAN60107, IAN 114324, IAN 275901',
				id							=> '51',
				knownFreqs      => '433.92',
				one							=> [1,-8],
				zero						=> [1,-4],
				sync						=> [1,-16],
				clockabs				=> '500',
				format					=> 'twostate',		# not used now
				preamble				=> 'W51#',				# prepend to converted message
				postamble				=> '',						# Append to converted message
				clientmodule		=> 'SD_WS',
				modulematch			=> '^W51#.*',
				length_min			=> '40',
				length_max			=> '45',
			},
		"52"	=>	## Oregon Scientific PIR Protocol
							# https://forum.fhem.de/index.php/topic,63604.msg548256.html#msg548256 @Ralf_W.
							# u52#00012AE7   MC;LL=-1045;LH=1153;SL=-494;SH=606;D=FFFED518;C=549;L=30;
							#
							# FFFED5 = Adresse, die per DIP einstellt wird, FFF ändert sich nie
							# 1 = Kanal, per gesondertem DIP, bei mir bei beiden 1 (CH 1) oder 3 (CH 2)
							# C = wechselt, 0, 4, 8, C - dann fängt es wieder mit 0 an und wiederholt sich bei jeder Bewegung
			{
				name						=> 'Oregon Scientific PIR',
				id							=> '52',
				knownFreqs      => '',
				clockrange			=> [470,640],							# min , max
				format					=> 'manchester',					# tristate can't be migrated from bin into hex!
				clientmodule		=> 'OREGON',
				modulematch			=> '^u52#F{3}|0{3}.*',
				preamble				=> 'u52#',
				length_min			=> '30',
				length_max			=> '30',
				method					=> \&main::SIGNALduino_OSPIR,		# Call to process this message
				polarity				=> 'invert',
			},
		"55"	=>	## QUIGG GT-1000
			{
				name						=> 'QUIGG_GT-1000',
				comment					=> 'remote control',
				id							=> '55',
				knownFreqs      => '',
				clockabs				=> 300,
				zero						=> [1,-4],
				one							=> [4,-2],
				sync						=> [1,-8],
				format					=> 'twostate',
				preamble				=> 'i',						# prepend to converted message
				clientmodule		=> 'IT',
				modulematch			=> '^i.*',
				length_min			=> '24',
				length_max			=> '24',
			},
		"56"	=>	## Celexon
			{
				name						=> 'Celexon',
				id							=> '56',
				knownFreqs      => '',
				clockabs				=> 200,
				zero						=> [1,-3],
				one							=> [3,-1],
				start						=> [25,-3],
				format					=> 'twostate',
				preamble				=> 'u56#',						# prepend to converted message
				#clientmodule		=> '',
				modulematch			=> '',
				length_min			=> '56',
				length_max			=> '68',
			},
		"57"	=>	## m-e doorbell fuer FG- und Basic-Serie
							# https://forum.fhem.de/index.php/topic,64251.0.html @rippi46
							# P57#2AA4A7 | ring   MC;LL=-653;LH=665;SL=-317;SH=348;D=D55B58;C=330;L=21;
							# P57#2AA4A7 | ring   MC;LL=-654;LH=678;SL=-314;SH=351;D=D55B58;C=332;L=21;
							# P57#2AA4A7 | ring   MC;LL=-653;LH=679;SL=-310;SH=351;D=D55B58;C=332;L=21;
			{
				name						=> 'm-e',
				comment					=> 'radio gong transmitter for FG- and Basic-Serie',
				id							=> '57',
				knownFreqs      => '',
				clockrange			=> [300,360],						# min , max
				format					=> 'manchester',				# tristate can't be migrated from bin into hex!
				clientmodule		=> 'SD_BELL',
				modulematch			=> '^P57#.*',
				preamble				=> 'P57#',
				length_min			=> '21',
				length_max			=> '24',
				method					=> \&lib::SD_Protocols::MCRAW,	# Call to process this message
				polarity				=> 'invert',
			},
		"58"	=>	## TFA 30.3208.0
							# Ch:2 T: 18.9 H: 69 Bat:ok   MC;LL=-981;LH=964;SL=-480;SH=520;D=002BA37EBDBBA24F0015D1BF5EDDD127800AE8DFAF6EE893C;C=486;L=194;
			{
				name				=> 'TFA 30.3208.0',
				comment				=> 'temperature / humidity sensor',
				id				=> '58',
				knownFreqs			=> '433.92',
				clockrange			=> [460,520],			# min , max
				format				=> 'manchester',	# tristate can't be migrated from bin into hex!
				clientmodule			=> 'SD_WS',
				modulematch			=> '^W58*',
				preamble			=> 'W58#',
				length_min			=> '52',	# 54
				length_max			=> '52',	# 136
				method				=> \&main::SIGNALduino_MCTFA, # Call to process this message
				polarity			=> 'invert',
			},
		"59"	=>	## AK-HD-4 remote | 4 Buttons
							# https://github.com/RFD-FHEM/RFFHEM/issues/133 @stevedee78
							# u59#6DCAFB   MU;P0=819;P1=-919;P2=234;P3=-320;P4=8602;P6=156;D=01230301230301230303012123012301230303030301230303412303012303012303030121230123012303030303012303034123030123030123030301212301230123030303030123030341230301230301230303012123012301230303030301230303412303012303012303030121230123012303030303012303034163;CP=0;O;
							# u59#6DCAFB   MU;P0=-334;P2=8581;P3=237;P4=-516;P5=782;P6=-883;D=23456305056305050563630563056305050505056305050263050563050563050505636305630563050505050563050502630505630505630505056363056305630505050505630505026305056305056305050563630563056305050505056305050263050563050563050505636305630563050505050563050502630505;CP=5;O;
			{
				name						=> 'AK-HD-4',
				comment					=> 'remote control with 4 buttons',
				id							=> '59',
				knownFreqs      => '',
				clockabs				=> 230,
				zero						=> [-4,1],
				one							=> [-1,4],
				start						=> [-1,37],
				format					=> 'twostate',	# tristate can't be migrated from bin into hex!
				preamble				=> 'u59#',			# Append to converted message
				postamble				=> '',					# Append to converted message
				#clientmodule		=> '',
				#modulematch			=> '',
				length_min			=> '24',
				length_max			=> '24',
			},
		"60"	=>	## ELV, LA CROSSE (WS2000/WS7000)
							# Id:11 T: 21.3   MU;P0=32001;P1=-381;P2=835;P3=354;P4=-857;D=01212121212121212121343421212134342121213434342121343421212134213421213421212121342121212134212121213421212121343421343430;CP=2;R=53;
							# tested sensors:   WS-7000-20, AS2000, ASH2000, S2000, S2000I, S2001A, S2001IA,
							#                   ASH2200, S300IA, S2001I, S2000ID, S2001ID, S2500H
							# not tested:       AS3, S2000W, S2000R, WS7000-15, WS7000-16, WS2500-19, S300TH, S555TH
							# das letzte Bit (1) und mehrere Bit (0) Preambel fehlen meistens
							#  ___        _
							# |   |_     | |___
							#  Bit 0      Bit 1
							# kurz 366 mikroSek / lang 854 mikroSek / gesamt 1220 mikroSek - Sollzeiten
			{
				name								=> 'WS2000',
				comment							=> 'Series WS2000/WS7000 of various sensors',
				id									=> '60',
				knownFreqs					=> '',
				one									=> [3,-7],
				zero								=> [7,-3],
				clockabs						=> 122,
				preamble						=> 'K',				# prepend to converted message
				postamble						=> '',				# Append to converted message
				clientmodule				=> 'CUL_WS',
				length_min					=> '38',			# 46, letztes Bit fehlt = 45, 10 Bit Preambel = 35 Bit Daten
				length_max					=> '82',
				postDemodulation		=> \&main::SIGNALduino_postDemo_WS2000,
			},
		"61"	=>	## ELV FS10
							# tested transmitter:   FS10-S8, FS10-S4, FS10-ZE
							# tested receiver:      FS10-ST, FS10-MS, WS3000-TV, PC-Wettersensor-Empfaenger
							# sends 2 messages with 43 or 48 bits in distance of 100 mS (on/off) , last bit 1 is missing
							# sends x messages with 43 or 48 bits in distance of 200 mS (dimm) , repeats second message
							# 2_13 | on   MU;P0=1776;P1=-410;P2=383;P3=-820;D=01212121212121212121212123212121232323212323232121212323232121212321212123232123212120;CP=2;R=74;
							#  __         __
							# |  |__     |  |____
							#  Bit 0      Bit 1
							# kurz 400 mikroSek / lang 800 mikroSek / gesamt 800 mikroSek = 0, gesamt 1200 mikroSek = 1 - Sollzeiten
			{
				name					=> 'FS10',
				comment				=> 'remote control',
				id						=> '61',
				knownFreqs		=> '433.92',
				one						=> [1,-2],
				zero					=> [1,-1],
				clockabs			=> 400,
				pause					=> [-81],				# 400*81=32400*6=194400 - pause between repeats of send messages (clockabs*pause must be < 32768)
				format				=> 'twostate',
				preamble			=> 'P61#',			# prepend to converted message
				postamble			=> '',					# Append to converted message
				clientmodule	=> 'FS10',
				#modulematch	=> '',
				length_min		=> '38',				# eigentlich 41 oder 46 (Pruefsumme nicht bei allen)
				length_max		=> '48',				# eigentlich 46
			},
		"62"	=>	## Clarus_Switch
							# ! some message are decode as protocol 32 !
							# Unknown code i415703, help me!   MU;P0=-5893;P4=-634;P5=498;P6=-257;P7=116;D=45656567474747474745656707456747474747456745674567456565674747474747456567074567474747474567456745674565656747474747474565670745674747474745674567456745656567474747474745656707456747474747456745674567456565674747474747456567074567474747474567456745674567;CP=7;O;
			{
				name					=> 'Clarus_Switch',
				id						=> '62',
				knownFreqs		=> '',
				one						=> [3,-1],
				zero					=> [1,-3],
				start					=> [1,-35],		# ca 30-40
				clockabs			=> 189,
				preamble			=> 'i',				# prepend to converted message
				clientmodule	=> 'IT',
				#modulematch	=> '',
				length_min		=> '24',
				length_max		=> '24',
			},
		"63"	=>	## Warema MU
							# https://forum.fhem.de/index.php/topic,38831.msg395978/topicseen.html#msg395978 @Totte10 | https://www.mikrocontroller.net/topic/264063
							# no decode!   MU;P0=-2988;P1=1762;P2=-1781;P3=-902;P4=871;P5=6762;P6=5012;D=0121342434343434352434313434243521342134343436;
							# no decode!   MU;P0=6324;P1=-1789;P2=864;P3=-910;P4=1756;D=0123234143212323232323032321234141032323232323232323;CP=2;
			{
				name					=> 'Warema',
				comment				=> 'radio shutter switch (is still experimental)',
				id						=> '63',
				knownFreqs		=> '',
				developId			=> 'y',
				one						=> [1],
				zero					=> [0],
				clockabs			=> 800,
				syncabs				=> '6700',	# Special field for filterMC function
				preamble			=> 'u63#',		# prepend to converted message
				#clientmodule	=> '',
				#modulematch	=> '',
				length_min		=> '24',
				#length_max		=> '',			# missing
				filterfunc		=> 'SIGNALduino_filterMC',
			},
		"64"	=>	## WH2
							# no decode!   MU;P0=-32001;P1=457;P2=-1064;P3=1438;D=0123232323212121232123232321212121212121212323212121232321;CP=1;R=63;
							# no decode!   MU;P0=-32001;P1=473;P2=-1058;P3=1454;D=0123232323212121232123232121212121212121212121232321212321;CP=1;R=51;
							# no value!    MU;P0=134;P1=-113;P3=412;P4=-1062;P5=1379;D=01010101013434343434343454345454345454545454345454545454343434545434345454345454545454543454543454345454545434545454345;CP=3;
			{
				name					=> 'WH2',
				comment				=> 'temperature / humidity sensor',
				id						=> '64',
				knownFreqs		=> '',
				one						=> [1,-2],
				zero					=> [3,-2],
				clockabs			=> 490,
				clientmodule	=> 'SD_WS',
				modulematch		=> '^W64*',
				preamble			=> 'W64#',				# prepend to converted message
				postamble			=> '',						# Append to converted message
				#clientmodule	=> '',
				length_min		=> '48',
				length_max		=> '54',
			},
		"65"	=>	## Homeeasy
							# on | vHE_EU   MS;P1=231;P2=-1336;P4=-312;P5=-8920;D=15121214141412121212141414121212121414121214121214141212141212141212121414121414141212121214141214121212141412141212;CP=1;SP=5;
			{
				name							=> 'HomeEasy HE_EU',
				id								=> '65',
				knownFreqs				=> '',
				one								=> [1,-5.5],
				zero							=> [1,-1.2],
				sync							=> [1,-38],
				clockabs					=> 230,
				format						=> 'twostate',	# not used now
				preamble					=> 'ih',
				clientmodule			=> 'IT',
				length_min				=> '57',
				length_max				=> '72',
				postDemodulation	=> \&main::SIGNALduino_HE_EU,
			},
		"66"	=>	## TX2 Protocol (Remote Temp Transmitter & Remote Thermo Model 7035)
							# https://github.com/RFD-FHEM/RFFHEM/issues/160 @elektron-bbs
							# Id:66 T: 23.2   MU;P0=13312;P1=-2785;P2=4985;P3=1124;P4=-6442;P5=3181;P6=-31980;D=0121345434545454545434545454543454545434343454543434545434545454545454343434545434343434545621213454345454545454345454545434545454343434545434345454345454545454543434345454343434345456212134543454545454543454545454345454543434345454343454543454545454545;CP=3;R=73;O;
							# Id:49 T: 25.2   MU;P0=32001;P1=-2766;P2=4996;P3=1158;P4=-6416;P5=3203;P6=-31946;D=01213454345454545454543434545454345454343434543454345454345454545454543434345434543434345456212134543454545454545434345454543454543434345434543454543454545454545434343454345434343454562121345434545454545454343454545434545434343454345434545434545454545454;CP=3;R=72;O; 
			{
				name							=> 'WS7035',
				comment						=> 'temperature sensor',
				id								=> '66',
				knownFreqs				=> '',
				one								=> [10,-52],
				zero							=> [27,-52],
				start							=> [-21,42,-21],
				clockabs					=> 122,
				reconstructBit		=> '1',
				format						=> 'pwm',				# not used now
				preamble					=> 'TX',
				clientmodule			=> 'CUL_TX',
				modulematch				=> '^TX......',
				length_min				=> '43',
				length_max				=> '44',
				postDemodulation	=> \&main::SIGNALduino_postDemo_WS7035,
			},
		"67"	=>	## TX2 Protocol (Remote Datalink & Remote Thermo Model 7053, 7054)
							# https://github.com/RFD-FHEM/RFFHEM/issues/162 @elektron-bbs
							# Id:72 T: 26.0   MU;P0=3381;P1=-672;P2=-4628;P3=1142;P4=-30768;D=010 2320232020202020232020232020202320232323202323202020202020202020 4 010 2320232020202020232020232020202320232323202323202020202020202020 0;CP=0;R=45;
							# Id:72 T: 24.3   MU;P0=1148;P1=3421;P6=-664;P7=-4631;D=161 7071707171717171707171707171717171707070717071717171707071717171 0;CP=1;R=29;
							# Message repeats 4 x with pause of ca. 30-34 mS
							#           __               ____
							#  ________|  |     ________|    |
							#      Bit 1             Bit 0
							#    4630  1220       4630   3420   mikroSek - mit Oszi gemessene Zeiten
			{
				name							=> 'WS7053',
				comment						=> 'temperature sensor',
				id								=> '67',
				knownFreqs				=> '',
				one								=> [-38,10],     # -4636, 1220
				zero							=> [-38,28],     # -4636, 3416
				clockabs					=> 122,
				preamble					=> 'TX',         # prepend to converted message
				clientmodule			=> 'CUL_TX',
				modulematch				=> '^TX......',
				length_min				=> '32',
				length_max				=> '34',
				postDemodulation	=> \&main::SIGNALduino_postDemo_WS7053,
			},

			# "68"	=>	can use

		"69"	=>	## Hoermann HSM2, HSM4, HS1-868-BS (868 MHz)
							# https://github.com/RFD-FHEM/RFFHEM/issues/149
							# HSM4 | button_1   MU;P0=-508;P1=1029;P2=503;P3=-1023;P4=12388;D=01010232323232310104010101010101010102323231010232310231023232323231023101023101010231010101010232323232310104010101010101010102323231010232310231023232323231023101023101010231010101010232323232310104010101010101010102323231010232310231023232323231023101;CP=2;R=37;O;
							# Remote control HS1-868-BS (one button):
							# https://github.com/RFD-FHEM/RFFHEM/issues/344
							# HS1_868_BS | receive   MU;P0=-578;P1=1033;P2=506;P3=-1110;P4=13632;D=0101010232323101040101010101010101023232323102323101010231023102310231010232323101010101010101010232323101040101010101010101023232323102323101010231023102310231010232323101010101010101010232323101040101010101010101023232323102323101010231023102310231010;CP=2;R=77;
							# HS1_868_BS | receive   MU;P0=-547;P1=1067;P2=553;P3=-1066;P4=13449;D=0101010101010232323101040101010101010101023232323102323101010231023102310231010232323101010101010101010232323101040101010101010101023232323102323101010231023102310231010232323101010101010101010232323101040101010101010101023232323102323101010231023102310;CP=2;R=71;
							# https://forum.fhem.de/index.php/topic,71877.msg642879.html (HSM4, Taste 1-4)
							# HSM4 | button_1   MU;P0=-332;P1=92;P2=-1028;P3=12269;P4=-510;P5=1014;P6=517;D=01234545454545454545462626254546262546254626262626254625454625454546254545454546262626262545434545454545454545462626254546262546254626262626254625454625454546254545454546262626262545434545454545454545462626254546262546254626262626254625454625454546254545;CP=6;R=37;O;
							# HSM4 | button_2   MU;P0=509;P1=-10128;P2=1340;P3=-517;P4=1019;P5=-1019;P6=12372;D=01234343434343434343050505434305054305430505050505430543430543434305434343430543050505054343634343434343434343050505434305054305430505050505430543430543434305434343430543050505054343634343434343434343050505434305054305430505050505430543430543434305434343;CP=0;R=52;O;
							# HSM4 | button_3   MU;P0=12376;P1=360;P2=-10284;P3=1016;P4=-507;P6=521;P7=-1012;D=01234343434343434343467676734346767346734676767676734673434673434346734343434676767346767343404343434343434343467676734346767346734676767676734673434673434346734343434676767346767343404343434343434343467676734346767346734676767676734673434673434346734343;CP=6;R=55;O;
							# HSM4 | button_4   MU;P0=-3656;P1=12248;P2=-519;P3=1008;P4=506;P5=-1033;D=01232323232323232324545453232454532453245454545453245323245323232453232323245453245454532321232323232323232324545453232454532453245454545453245323245323232453232323245453245454532321232323232323232324545453232454532453245454545453245323245323232453232323;CP=4;R=48;O;
			{
				name							=> 'Hoermann',
				comment						=> 'remote control HS1-868-BS, HSM4',
				id								=> '69',
				knownFreqs				=> '433.92 | 868.35',
				zero							=> [2,-1],     # 1020,510
				one								=> [1,-2],     # 510,1020
				start							=> [25,-1],    # 12750,510
				clockabs					=> 510,
				format						=> 'twostate',
				clientmodule			=> 'SD_UT',
				modulematch				=> '^P69#.{11}',
				preamble					=> 'P69#',
				length_min				=> '44',
				length_max				=> '44',
			},
		"70"	=>	## FHT80TF (Funk-Tuer-Fenster-Melder FHT 80TF und FHT 80TF-2)
							# https://github.com/RFD-FHEM/RFFHEM/issues/171 @HomeAutoUser
							# closed   MU;P0=-24396;P1=417;P2=-376;P3=610;P4=-582;D=012121212121212121212121234123434121234341212343434121234123434343412343434121234341212121212341212341234341234123434;CP=1;R=35;
							# open     MU;P0=-21652;P1=429;P2=-367;P4=634;P5=-555;D=012121212121212121212121245124545121245451212454545121245124545454512454545121245451212121212124512451245451245121212;CP=1;R=38;
			{
				name							=> 'FHT80TF',
				comment						=> 'door/window switch',
				id								=> '70',
				knownFreqs				=> '868.35',
				one								=> [1.5,-1.5],		# 600
				zero							=> [1,-1],				# 400
				clockabs					=> 400,
				format						=> 'twostate',		# not used now
				clientmodule			=> 'CUL_FHTTK',
				preamble					=> 'T',
				length_min				=> '50',
				length_max				=> '58',
				postDemodulation	=> \&main::SIGNALduino_postDemo_FHT80TF,
			},
		"71"	=>	## PEARL infactory Poolthermometer (PV-8644)
							# Ch:1 T: 24.2   MU;P0=1735;P1=-1160;P2=591;P3=-876;D=0123012323010101230101232301230123010101010123012301012323232323232301232323232323232323012301012;CP=2;R=97;
			{
				name					=> 'PEARL',
				comment				=> 'infactory Poolthermometer (PV-8644)',
				id						=> '71',
				knownFreqs		=> '433.92',
				clockabs			=> 580,
				zero					=> [3,-2],
				one						=> [1,-1.5],
				format				=> 'twostate',
				preamble			=> 'W71#',			# prepend to converted message
				clientmodule	=> 'SD_WS',
				#modulematch	=> '^W71#.*'
				length_min		=> '48',
				length_max		=> '48',
			},
		"72"	=>	## Siro blinds MU	 @Dr.Smag
							# ! same definition how ID 16 !
							# module ERROR after delete and parse without save!!! 
							# >Siro_5B417081< returned by the Siro ParseFn is invalid, notify the module maintainer
							# https://forum.fhem.de/index.php?topic=77167.0
							# MU;P0=-760;P1=334;P2=693;P3=-399;P4=-8942;P5=4796;P6=-1540;D=01010102310232310101010102310232323101010102310101010101023102323102323102323102310101010102310232323101010102310101010101023102310231023102456102310232310232310231010101010231023232310101010231010101010102310231023102310245610231023231023231023101010101;CP=1;R=45;O;
							# MU;P0=-8848;P1=4804;P2=-1512;P3=336;P4=-757;P5=695;P6=-402;D=0123456345656345656345634343434345634565656343434345634343434343456345634563456345;CP=3;R=49;
			{
				name						=> 'Siro shutter',
				comment					=> 'message decode as MU',
				id							=> '72',
				knownFreqs      => '',
				dispatchequals	=>  'true',
				one							=> [2,-1.2],		# 680, -400
				zero						=> [1,-2.2],		# 340, -750
				start						=> [14,-4.4],		# 4800,-1520
				clockabs				=> 340,
				format					=> 'twostate',
				preamble				=> 'P72#',			# prepend to converted message
				clientmodule		=> 'Siro',
				#modulematch		=> '',
				length_min			=> '39',
				length_max			=> '40',
				msgOutro				=> 'SR;P0=-8500;D=0;',
			},
		"72.1"	=>	## Siro blinds MS		@Dr.Smag
								# Id:5B41708 state:0   MS;P0=4803;P1=-1522;P2=333;P3=-769;P4=699;P5=-393;P6=-9190;D=2601234523454523454523452323232323452345454523232323452323232323234523232345454545;CP=2;SP=6;R=61;
			{
				name						=> 'Siro shutter',
				comment					=> 'message decode as MS',
				id							=> '72',
				knownFreqs      => '',
				developId				=> 'm',
				dispatchequals	=>  'true',
				one							=> [2,-1.2],		# 680, -400
				zero						=> [1,-2.2],		# 340, -750
				sync						=> [14,-4.4],		# 4800,-1520
				clockabs				=> 340,
				format					=> 'twostate',
				preamble				=> 'P72#',			# prepend to converted message
				clientmodule		=> 'Siro',
				#modulematch		=> '',
				length_min			=> '39',
				length_max			=> '40',
				#msgOutro				=> 'SR;P0=-8500;D=0;',
			},
		"73"	=>	## FHT80 - Raumthermostat (868Mhz) @HomeAutoUser
							# actuator:0%   MU;P0=136;P1=-112;P2=631;P3=-392;P4=402;P5=-592;P6=-8952;D=0123434343434343434343434325434343254325252543432543434343434325434343434343434343254325252543254325434343434343434343434343252525432543464343434343434343434343432543434325432525254343254343434343432543434343434343434325432525254325432543434343434343434;CP=4;R=250;
			{
				name							=> 'FHT80',
				comment						=> 'roomthermostat (only receive)',
				id								=> '73',
				knownFreqs				=> '868.35',
				one								=> [1.5,-1.5],	# 600
				zero							=> [1,-1],			# 400
				pause							=> [-25],
				clockabs					=> 400,
				format						=> 'twostate',	# not used now
				clientmodule			=> 'FHT',
				preamble					=> '810c04xx0909a001',
				length_min				=> '59',
				length_max				=> '67',
				postDemodulation	=> \&main::SIGNALduino_postDemo_FHT80,
			},
		"74"	=>	## FS20 - Remote Control (868Mhz) @HomeAutoUser
							# dim100%   MU;P0=-10420;P1=-92;P2=398;P3=-417;P5=596;P6=-592;D=1232323232323232323232323562323235656232323232356232356232623232323232323232323232323235623232323562356565623565623562023232323232323232323232356232323565623232323235623235623232323232323232323232323232323562323232356235656562356562356202323232323232323;CP=2;R=72;
			{
				name				=> 'FS20',
				comment				=> 'remote control (decode as MU)',
				id				=> '74',
				knownFreqs			=> '868.35',
				one				=> [1.5,-1.5],	# 600
				zero				=> [1,-1],	# 400
				pause				=> [-25],
				clockabs			=> 400,
				#reconstructBit			=> '1',
				format				=> 'twostate',	# not used now
				clientmodule			=> 'FS20',
				preamble			=> '810b04f70101a001',
				length_min			=> '50',
				length_max			=> '67',
				postDemodulation	=> \&main::SIGNALduino_postDemo_FS20,
			},
		"74.1"	=>	## FS20 - Remote Control (868Mhz) @HomeAutoUser
								# dim100%   MS;P1=-356;P2=448;P3=653;P4=-551;P5=-10412;D=2521212121212121212121212134212121343421212121213421213421212121212121212121212121212121342121212134213434342134342134;CP=2;SP=5;R=72;O;!;4;
			{
				name             => 'FS20',
				comment          => 'remote control (decode as MS)',
				id               => '74.1',
				knownFreqs       => '868.35',
				one              => [1.5,-1.5],	# 600
				zero             => [1,-1],	# 400
				sync             => [-25],
				clockabs         => 400,
				#reconstructBit   => '1',
				format           => 'twostate',	# not used now
				clientmodule     => 'FS20',
				preamble         => '810b04f70101a001',
				paddingbits      => '1',      # disable padding
				length_min       => '50',
				length_max       => '67',
				postDemodulation => \&main::SIGNALduino_postDemo_FS20,
			},
		"75"	=>	## Conrad RSL (Erweiterung v2) @litronics https://github.com/RFD-FHEM/SIGNALDuino/issues/69
							# ! same definition how ID 5, but other length !
							# !! protocol needed revision - start or sync failed !! https://github.com/RFD-FHEM/SIGNALDuino/issues/69#issuecomment-440349328
							# on    MU;P0=-1365;P1=477;P2=1145;P3=-734;P4=-6332;D=01023202310102323102423102323102323101023232323101010232323231023102323102310102323102423102323102323101023232323101010232323231023102323102310102323102;CP=1;R=12;
			{
				name					=> 'Conrad RSL v2',
				comment				=> 'remotes and switches',
				id						=> '75',
				knownFreqs		=> '',
				one						=> [3,-1],
				zero					=> [1,-3],
				clockabs			=> 500,
				format				=> 'twostate',
				developId			=> 'y',
				clientmodule	=> 'SD_RSL',
				preamble			=> 'P1#',
				modulematch		=> '^P1#[A-Fa-f0-9]{8}',
				length_min		=> '32',
				length_max 		=> '40',
			},
		"76"	=>	## Kabellose LED-Weihnachtskerzen XM21-0
							# ! min length not work - must CHECK !
							# https://github.com/RFD-FHEM/RFFHEM/pull/437#issuecomment-448019192 @sidey79
							# on -> P76#FFFFFFFFFFFFFFFF
							# LED_XM21_0 | on    MU;P0=-205;P1=113;P3=406;D=010101010101010101010101010101010101010101010101010101010101030303030101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010103030303010101010101010101010100;CP=1;R=69;
							# LED_XM21_0 | on    MU;P0=-198;P1=115;P4=424;D=0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010404040401010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101040404040;CP=1;R=60;O;
							# LED_XM21_0 | on    MU;P0=114;P1=-197;P2=419;D=0121212121010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101012121212101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010;CP=0;R=54;O;
							# off -> P76#FFFFFFFFFFFFFFC
							# LED_XM21_0 | off   MU;P0=-189;P1=115;P4=422;D=0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101040404040101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010104040404010101010;CP=1;R=73;O;
							# LED_XM21_0 | off   MU;P0=-203;P1=412;P2=114;D=01010101020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020101010102020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200;CP=2;R=74;
							# LED_XM21_0 | off   MU;P0=-210;P1=106;P3=413;D=0101010101010101010303030301010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101030303030100;CP=1;R=80;

			{
				name					=> 'LED XM21',
				comment				=> 'remote with 2-buttons for LED X-MAS light string',
				id						=> '76',
				knownFreqs		=> '433.92',
				one						=> [1.2,-2],			# 120,-200
				#zero					=> [],						# existiert nicht
				start					=> [4.5,-2,4.5,-2,4.5,-2,4.5,-2],			# 450,-200 Starsequenz
				clockabs			=> 100,
				format				=> 'twostate',		# not used now
				clientmodule	=> 'SD_UT',
				preamble			=> 'P76#',
				length_min		=> 58,
				length_max		=> 64,
			},
		"77"	=>	## NANO_DS1820_4Fach
							# https://github.com/juergs/NANO_DS1820_4Fach
							# Id:105 T: 22.8   MU;P0=-1483;P1=239;P2=970;P3=-21544;D=01020202010132020202010201020202020201010201020201020201010102020102010202020201010102020102020201013202020201020102020202020101020102020102020101010202010201020202020101010202010202020101;CP=1;
							# Id:106 T: 0.0    MU;P0=-168;P1=420;P2=-416;P3=968;P4=-1491;P5=242;P6=-21536;D=01234343434543454343434343454543454345434543454345434343434343434343454345434343434345454363434343454345434343434345454345434543454345434543434343434343434345434543434343434545436343434345434543434343434545434543454345434543454343434343434343434543454343;CP=3;O;
							# Id:106 T: 0.0    MU;P0=-1483;P1=969;P2=236;P3=-21542;D=01010102020131010101020102010101010102020102010201020102010201010101010101010102010201010101010202013101010102010201010101010202010201020102010201020101010101010101010201020101010101020201;CP=1;
							# Id:107 T: 0.0    MU;P0=-32001;P1=112;P2=-8408;P3=968;P4=-1490;P5=239;P6=-21542;D=01234343434543454343434343454543454345454343454345434343434343434343454345434343434345454563434343454345434343434345454345434545434345434543434343434343434345434543434343434545456343434345434543434343434545434543454543434543454343434343434343434543454343;CP=3;O;
							# Id:107 T: 0.0    MU;P0=-1483;P1=968;P2=240;P3=-21542;D=01010102020231010101020102010101010102020102010202010102010201010101010101010102010201010101010202023101010102010201010101010202010201020201010201020101010101010101010201020101010101020202;CP=1;
							# Id:108 T: 0.0    MU;P0=-32001;P1=969;P2=-1483;P3=237;P4=-21542;D=01212121232123212121212123232123232121232123212321212121212121212123212321212121232123214121212123212321212121212323212323212123212321232121212121212121212321232121212123212321412121212321232121212121232321232321212321232123212121212121212121232123212121;CP=1;O;
							# Id:108 T: 0.0    MU;P0=-1485;P1=967;P2=236;P3=-21536;D=010201020131010101020102010101010102020102020101020102010201010101010101010102010201010101020102013101010102010201010101010202010202010102010201020101010101010101010201020101010102010201;CP=1;
			{
				name					=> 'NANO_DS1820_4Fach',
				comment				=> 'self build sensor',
				id						=> '77',
				knownFreqs		=> '',
				developId			=> 'y',
				zero					=> [4,-6],
				one						=> [1,-6],
				clockabs			=> 250,
				format				=> 'pwm',				#
				preamble			=> 'TX',				# prepend to converted message
				clientmodule	=> 'CUL_TX',
				modulematch		=> '^TX......',
				length_min		=> '43',
				length_max		=> '44',
				remove_zero		=> 1,						# Removes leading zeros from output
			},
		# "78"	=>	## GEIGER blind motors
							# # https://forum.fhem.de/index.php/topic,39153.0.html @fasch
							# # MU;P0=313;P1=1212;P2=-309;P4=-2024;P5=-16091;P6=2014;D=01204040562620404626204040404040462046204040562620404626204040404040462046204040562620404626204040404040462046204040562620404626204040404040462046204040;CP=0;R=236;
							# # MU;P0=-15770;P1=2075;P2=-264;P3=326;P4=-2016;P5=948;D=012121234121234341212121234341234343012125;CP=3;R=208;
			# {
				# name					=> 'GEIGER blind motors',
				# comment				=> 'example remote control GF0001',
				# id						=> '78',
				# knownFreqs		=> '',
				# developId			=> 'y',
				# zero					=> [1,-6.6],
				# one						=> [6.6,-1],
				# start					=> [-53],
				# clockabs     	=> 300,
				# format				=> 'twostate',
				# preamble			=> 'u78#',			# prepend to converted message
				# clientmodule	=> 'SIGNALduino_un',
				# #modulematch	=> '^TX......',
				# length_min		=> '14',
				# length_max		=> '18',
				# paddingbits		=> '2'				 # pad 1 bit, default is 4
			# },
		"79"	=>	## Heidemann | Heidemann HX | VTX-BELL
							# https://github.com/RFD-FHEM/SIGNALDuino/issues/84
							# P79#A5E | ring   MU;P0=656;P1=-656;P2=335;P3=-326;P4=-5024;D=0123012123012303030301 24 230123012123012303030301 24 230123012123012303030301 24 2301230121230123030303012423012301212301230303030124230123012123012303030301242301230121230123030303012423012301212301230303030124230123012123012303030301242301230121230123030303;CP=2;O;
							# https://forum.fhem.de/index.php/topic,64251.0.html
							# P79#4FC | ring   MU;P0=540;P1=-421;P2=-703;P3=268;P4=-4948;D=4 323102323101010101010232 34 323102323101010101010232 34 323102323101010101010232 34 3231023231010101010102323432310232310101010101023234323102323101010101010232343231023231010101010102323432310232310101010101023234323102323101010101010232343231023231010101010;CP=3;O;
							# https://github.com/RFD-FHEM/RFFHEM/issues/252
							# P79#A0E | ring   MU;P0=-24096;P1=314;P2=-303;P3=615;P4=-603;P5=220;P6=-4672;D=0123456123412341414141412323234 16 123412341414141412323234 16 12341234141414141232323416123412341414141412323234161234123414141414123232341612341234141414141232323416123412341414141412323234161234123414141414123232341612341234141414141232323416123412341414;CP=1;R=26;O;
							# P79#A0E | ring   MU;P0=-10692;P1=602;P2=-608;P3=311;P4=-305;P5=-4666;D=01234123232323234141412 35 341234123232323234141412 35 341234123232323234141412 35 34123412323232323414141235341234123232323234141412353412341232323232341414123534123412323232323414141235341234123232323234141412353412341232323232341414123534123412323232323414;CP=3;R=47;O;
							# P79#A0E | ring   MU;P0=-7152;P1=872;P2=-593;P3=323;P4=-296;P5=622;P6=-4650;D=01234523232323234545452 36 345234523232323234545452 36 345234523232323234545452 36 34523452323232323454545236345234523232323234545452363452345232323232345454523634523452323232323454545236345234523232323234545452363452345232323232345454523634523452323232323454;CP=3;R=26;O;
							# https://forum.fhem.de/index.php/topic,58397.msg879878.html#msg879878 @rcmcronny
							# P79#3FC | ring   MU;P0=-421;P1=344;P2=-699;P4=659;P6=-5203;P7=259;D=1612121040404040404040421216121210404040404040404212161212104040404040404042121612121040404040404040421216121210404040404040404272761212104040404040404042121612121040404040404040421216121210404040404040404212167272104040404040404042721612127040404040404;CP=4;R=0;O;
			{
				name					=> 'wireless doorbell',
				comment				=> 'Heidemann | Heidemann HX | VTX-BELL',
				id						=> '79',
				knownFreqs		=> '',
				zero					=> [-2,1],
				one						=> [-1,2],
				start					=> [-15,1],
				clockabs			=> 330,
				format				=> 'twostate',	#
				preamble			=> 'P79#',			# prepend to converted message
				clientmodule	=> 'SD_BELL',
				modulematch		=> '^P79#.*',
				length_min		=> '12',
				length_max		=> '12',
			},
		"80"	=>	## EM1000WZ (Energy-Monitor) Funkprotokoll (868Mhz)  @HomeAutoUser | Derwelcherichbin
							# https://github.com/RFD-FHEM/RFFHEM/issues/253
							# CNT:91 CUM:14.560 5MIN:0.240 TOP:0.170   MU;P1=-417;P2=385;P3=-815;P4=-12058;D=42121212121212121212121212121212121232321212121212121232321212121212121232323212323212321232121212321212123232121212321212121232323212121212121232121212121212121232323212121212123232321232121212121232123232323212321;CP=2;R=87;
			{
				name							=> 'EM1000WZ',
				comment						=> 'EM (Energy-Monitor)',
				id								=> '80',
				knownFreqs				=> '868.35',
				one								=> [1,-2],	# 800
				zero							=> [1,-1],	# 400
				clockabs					=> 400,
				format						=> 'twostate', # not used now
				clientmodule			=> 'CUL_EM',
				preamble					=> 'E',
				length_min				=> '104',
				length_max				=> '114',
				postDemodulation	=> \&main::SIGNALduino_postDemo_EM,
			},
		"81"	=>	## Remote control SA-434-1 based on HT12E @elektron-bbs
							# P86#115 | receive   MU;P0=-485;P1=188;P2=-6784;P3=508;P5=1010;P6=-974;P7=-17172;D=0123050505630505056305630563730505056305050563056305637305050563050505630563056373050505630505056305630563730505056305050563056305637305050563050505630563056373050505630505056305630563730505056305050563056305637305050563050505630563056373050505630505056;CP=3;R=0;
							# P86#115 | receive   MU;P0=-1756;P1=112;P2=-11752;P3=496;P4=-495;P5=998;P6=-988;P7=-17183;D=0123454545634545456345634563734545456345454563456345637345454563454545634563456373454545634545456345634563734545456345454563456345637345454563454545634563456373454545634545456345634563734545456345454563456345637345454563454545634563456373454545634545456;CP=3;R=0;
							#      __        ____
							# ____|  |    __|    |
							#  Bit 1       Bit 0
							# short 500 microSec / long 1000 microSec / bittime 1500 mikroSek / pilot 12 * bittime, from that 1/3 bitlength high
			{
				name					=> 'SA-434-1',
				comment				=> 'remote control SA-434-1 mini 923301 based on HT12E',
				id						=> '81',
				knownFreqs		=> '433.92',
				one						=> [-2,1],			# i.O.
				zero					=> [-1,2],			# i.O.
				start					=> [-35,1],			# Message is not provided as MS, worakround is start
				clockabs			=> 500,
				format				=> 'twostate',
				preamble			=> 'P81#',			# prepend to converted message
				modulematch		=> '^P81#.{3}',
				clientmodule	=> 'SD_UT',
				length_min		=> '12',
				length_max		=> '12',
			},
		"82"	=>	## Fernotron shutters and light switches
							# https://github.com/RFD-FHEM/RFFHEM/issues/257
							# MU;P0=-32001;P1=435;P2=-379;P4=-3201;P5=831;P6=-778;D=01212121212121214525252525252521652161452525252525252161652141652521652521652521614165252165252165216521416521616165216525216141652161616521652165214165252161616521652161416525216161652161652141616525252165252521614161652525216525216521452165252525252525;CP=1;O;
							# the messages received are usual missing 12 bits at the end for some reason. So the checksum byte is missing.
							# Fernotron protocol is unidirectional. Here we can only receive messages from controllers send to receivers.
			{
				name					=> 'Fernotron',
				comment					=> 'shutters and light switches',
				id						=> '82',				# protocol number
				knownFreqs				=> '',
				developId				=> 'm',
				dispatchBin				=> '1',
				paddingbits				=> '1',     		# disable padding
				one						=> [1,-2],			# on=400us, off=800us
				zero					=> [2,-1],			# on=800us, off=400us
				float					=> [1,-8],			# on=400us, off=3200us. the preamble and each 10bit word has one [1,-8] in front
				pause					=> [1,-1],			# preamble (5x)
				clockabs				=> 400,				# 400us
				format					=> 'twostate',
				preamble				=> 'P82#',			# prepend our protocol number to converted message
				clientmodule			=> 'Fernotron',
				length_min				=> '100',			# actual 120 bit (12 x 10bit words to decode 6 bytes data), but last 20 are for checksum
				length_max				=> '3360',			# 3360 bit (336 x 10bit words to decode 168 bytes data) for full timer message
			},
		"83"	=>	## Remote control RH787T based on MOSDESIGN SEMICONDUCTOR CORP (CMOS ASIC encoder) M1EN compatible HT12E
							# for example Westinghouse Deckenventilator Delancey, 6 speed buttons, @zwiebelxxl
							# https://github.com/RFD-FHEM/RFFHEM/issues/250
							# 1_fan_minimum_speed      MU;P0=388;P1=-112;P2=267;P3=-378;P5=585;P6=-693;P7=-11234;D=0123035353535356262623562626272353535353562626235626262723535353535626262356262627235353535356262623562626272353535353562626235626262723535353535626262356262627235353535356262623562626272353535353562626235626262723535353535626262356262627235353535356262;CP=2;R=43;O;
							# 2_fan_low_speed          MU;P0=-176;P1=262;P2=-11240;P3=112;P5=-367;P6=591;P7=-695;D=0123215656565656717171567156712156565656567171715671567121565656565671717156715671215656565656717171567156712156565656567171715671567121565656565671717156715671215656565656717171567156712156565656567171715671567121565656565671717171717171215656565656717;CP=1;R=19;O;
							# 3_fan_medium_low_speed   MU;P0=564;P1=-392;P2=-713;P3=245;P4=-11247;D=0101010101023231023232323431010101010232310232323234310101010102323102323232343101010101023231023232323431010101010232310232323234310101010102323102323232343101010101023231023232323431010101010232310232323234310101010102323102323232343101010101023231023;CP=3;R=40;O;
			{
				name					=> 'RH787T',
				comment				=> 'remote control for example Westinghouse Delancey 7800140',
				id						=> '83',
				knownFreqs		=> '433.92',
				one						=> [-2,1],
				zero					=> [-1,2],
				start					=> [-35,1],				# calculated 12126,31579 µS
				clockabs			=> 335,						# calculated ca 336,8421053 µS short - 673,6842105µS long
				format				=> 'twostate',		# there is a pause puls between words
				preamble			=> 'P83#',				# prepend to converted message
				clientmodule	=> 'SD_UT',
				modulematch		=> '^P83#.{3}',
				length_min		=> '12',
				length_max		=> '12',
			},
		"84"	=>	## Funk Wetterstation Auriol IAN 283582 Version 06/2017 (Lidl), Modell-Nr.: HG02832D, 09/2018 @roobbb
							# ! some message are decode as protocol 40 !
							# https://github.com/RFD-FHEM/RFFHEM/issues/263
							# Ch:1 T: 25.3 H: 53 Bat:ok   MU;P0=-28796;P1=376;P2=-875;P3=834;P4=220;P5=-632;P6=592;P7=-268;D=0123232324545454545456767454567674567456745674545454545456767676767674567674567676767456;CP=4;R=22;
							# Ch:2 T: 13.1 H: 78 Bat:ok   MU;P0=-28784;P1=340;P2=-903;P3=814;P4=223;P5=-632;P6=604;P7=-248;D=0123232324545454545456767456745456767674545674567454545456745454545456767454545456745676;CP=4;R=22;
							# Ch:1 T: 6.9 H: 66 Bat:ok    MU;P0=-21520;P1=235;P2=-855;P3=846;P4=620;P5=-236;P7=-614;D=012323232454545454545451717451717171745171717171717171717174517171745174517174517174545;CP=1;R=217;
							## Sempre 92596/65395, Hofer/Aldi, WS97210-1, WS97230-1, WS97210-2, WS97230-2
							# https://github.com/RFD-FHEM/RFFHEM/issues/223
							# Ch:3 T: 21.3 H: 77 Bat:ok   MU;P0=-30004;P1=815;P2=-910;P3=599;P4=-263;P5=234;P6=-621;D=0121212345634565634345656345656343456345656345656565656343456345634563456343434565656;CP=5;R=5;
							## TECVANCE TV-4848 (Amazon) @HomeAutoUser
							# Ch:1 T: 26.4 H: 49 (L39)    MU;P0=-218;P1=254;P2=-605;P4=616;P5=907;P6=-799;P7=-1536;D=012121212401212124012401212121240125656565612401240404040121212404012121240121212121212124012121212401212124012401212121247;CP=1;
							# Ch:1 T: 26.6 H: 49 (L41)    MU;P0=239;P1=-617;P2=612;P3=-245;P4=862;P5=-842;D=01230145454545012301232323230101012323010101230123010101010123010101012301230123232301012301230145454545012301232323230101012323010101230123010101010123010101012301230123232301012301230145454545012301232323230101012323010101230123010101010123010101012301;CP=0;R=89;O;
			{
				name					=> 'IAN 283582 / TV-4848',
				comment				=> 'Weatherstation Auriol IAN 283582 / Sempre 92596/65395 / TECVANCE',
				id						=> '84',
				knownFreqs		=> '433.92',
				one						=> [3,-1],
				zero					=> [1,-3],
				start					=> [4,-4,4,-4,4,-4],
				clockabs			=> 215,
				format				=> 'twostate',
				preamble			=> 'W84#',						# prepend to converted message
				postamble			=> '',								# append to converted message
				clientmodule	=> 'SD_WS',
				length_min		=> '39',							# das letzte Bit fehlt meistens
				length_max		=> '41',
			},
		"85"	=>	## Funk Wetterstation TFA 35.1140.01 mit Temperatur-/Feuchte- und Windsensor TFA 30.3222.02 09/2018 @Iron-R
							# https://github.com/RFD-FHEM/RFFHEM/issues/266
							# Ch:1 T: 8.7 H: 85 Bat:ok   MU;P0=-509;P1=474;P2=-260;P3=228;P4=718;P5=-745;D=01212303030303012301230123012301230301212121230454545453030303012123030301230303012301212123030301212303030303030303012303012303012303012301212303030303012301230123012301230301212121212454545453030303012123030301230303012301212123030301212303030303030303;CP=3;R=46;O;
							# Ch:1 T: 7.6 H: 89 Bat:ok   MU;P0=7944;P1=-724;P2=742;P3=241;P4=-495;P5=483;P6=-248;D=01212121343434345656343434563434345634565656343434565634343434343434345634345634345634343434343434343434345634565634345656345634343456563421212121343434345656343434563434345634565656343434565634343434343434345634345634345634343434343434343434345634565634;CP=3;R=47;O;
			{
				name					=> 'TFA 30.3222.02',
				comment				=> 'Combisensor for Weatherstation TFA 35.1140.01',
				id						=> '85',
				knownFreqs		=> '',
				one						=> [2,-1],
				zero					=> [1,-2],
				start					=> [3,-3,3,-3,3,-3],
				clockabs			=> 250,
				format				=> 'twostate',
				preamble			=> 'W85#',					# prepend to converted message
				postamble			=> '',							# append to converted message
				clientmodule	=> 'SD_WS',
				length_min		=> '64',
				length_max		=> '68',
			},
		"86"	=>	### for remote controls:  Novy 840029, CAME TOP 432EV, BOSCH & Neff Transmitter SF01 01319004
							### CAME TOP 432EV 433,92 MHz für z.B. Drehtor Antrieb:
							# https://forum.fhem.de/index.php/topic,63370.msg849400.html#msg849400
							# https://github.com/RFD-FHEM/RFFHEM/issues/151 @andreasloe
							# CAME TOP 432EV | right_button      MU;P0=711;P1=-15288;P4=132;P5=-712;P6=316;P7=-313;D=4565656705656567056567056 16 565656705656567056567056 16 56565670565656705656705616565656705656567056567056165656567056565670565670561656565670565656705656705616565656705656567056567056165656567056565670565670561656565670565656705656705616565656705656567056;CP=6;R=52;
							# CAME TOP 432EV | left_button       MU;P0=-322;P1=136;P2=-15241;P3=288;P4=-735;P6=723;D=012343434306434343064343430623434343064343430643434306 2343434306434343064343430 623434343064343430643434306234343430643434306434343062343434306434343064343430623434343064343430643434306234343430643434306434343062343434306434343064343430;CP=3;R=27;
							# CAME TOP 432EV | right_button      MU;P0=-15281;P1=293;P2=-745;P3=-319;P4=703;P5=212;P6=152;P7=-428;D=0 1212121342121213421213421 01 212121342121213421213421 01 21212134212121342121342101212121342121213421213421012121213421212134212134210121243134212121342121342101252526742121213425213421012121213421212134212134210121212134212;CP=1;R=23;
							# rechteTaste: 0x112 (000100010010), linkeTaste: 0x111 (000100010001), the least significant bits distinguish the keys
							### remote control Novy 840029 for Novy Pureline 6830 kitchen hood:
							# https://github.com/RFD-FHEM/RFFHEM/issues/331 @Garfonso
							# Novy 840029 | light on/off button   MU;P0=710;P1=353;P2=-403;P4=-761;P6=-16071;D=20204161204120412041204120414141204120202041612041204120412041204141412041202020416120412041204120412041414120412020204161204120412041204120414141204120202041;CP=1;R=40;
							# Novy 840029 | plus button           MU;P0=22808;P1=-24232;P2=701;P3=-765;P4=357;P5=-15970;P7=-406;D=012345472347234723472347234723454723472347234723472347234547234723472347234723472345472347234723472347234723454723472347234723472347234;CP=4;R=39;
							# Novy 840029 | minus button          MU;P0=-8032;P1=364;P2=-398;P3=700;P4=-760;P5=-15980;D=0123412341234123412341412351234123412341234123414123512341234123412341234141235123412341234123412341412351234123412341234123414123;CP=1;R=40;
							# Novy 840029 | power button          MU;P0=-756;P1=718;P2=354;P3=-395;P4=-16056;D=01020202310231310202 42 310231023102310231020202310231310202 42 31023102310231023102020231023131020242310231023102310231020202310231310202;CP=2;R=41;
							# Novy 840029 | novy button           MU;P0=706;P1=-763;P2=370;P3=-405;P4=-15980;D=0123012301230304230123012301230123012303042;CP=2;R=42;
							### Neff Transmitter SF01 01319004 (SF01_01319004) 433,92 MHz
							# https://github.com/RFD-FHEM/RFFHEM/issues/376 @fhemjcm
							# SF01_01319004 | light_on_off        MU;P0=-707;P1=332;P2=-376;P3=670;P5=-15243;D=01012301232323230123012301232301010123510123012323232301230123012323010101235101230123232323012301230123230101012351012301232323230123012301232301010123510123012323232301230123012323010101235101230123232323012301230123230101012351012301232323230123012301;CP=1;R=3;O;
							# SF01_01319004 | plus                MU;P0=-32001;P1=348;P2=-704;P3=-374;P4=664;P5=-15255;D=01213421343434342134213421343421213434512134213434343421342134213434212134345121342134343434213421342134342121343451213421343434342134213421343421213434512134213434343421342134213434212134345121342134343434213421342134342121343451213421343434342134213421;CP=1;R=15;O;
							# SF01_01319004 | minus               MU;P0=-32001;P1=326;P2=-721;P3=-385;P4=656;P5=-15267;D=01213421343434342134213421343421342134512134213434343421342134213434213421345121342134343434213421342134342134213451213421343434342134213421343421342134512134213434343421342134213434213421345121342134343434213421342134342134213451213421343434342134213421;CP=1;R=10;O;
							# SF01_01319004 | interval            MU;P0=-372;P1=330;P2=684;P3=-699;P4=-14178;D=010231020202023102310231020231310231413102310202020231023102310202313102314;CP=1;R=253;
							# SF01_01319004 | delay               MU;P0=-710;P1=329;P2=-388;P3=661;P4=-14766;D=01232301410123012323232301230123012323012323014;CP=1;R=1;
							### BOSCH Transmitter SF01 01319004 (SF01_01319004_Typ2) 433,92 MHz
							# SF01_01319004_Typ2 | light_on_off   MU;P0=706;P1=-160;P2=140;P3=-335;P4=-664;P5=385;P6=-15226;P7=248;D=01210103045303045453030304545453030454530653030453030454530303045454530304747306530304530304545303030454545303045453065303045303045453030304545453030454530653030453030454530303045454530304545306530304530304545303030454545303045453065303045303045453030304;CP=5;O;
							# SF01_01319004_Typ2 | plus           MU;P0=-15222;P1=379;P2=-329;P3=712;P6=-661;D=30123236123236161232323616161232361232301232361232361612323236161612323612323012323612323616123232361616123236123230123236123236161232323616161232361232301232361232361612323236161612323612323012323612323616123232361616123236123230123236123236161232323616;CP=1;O;
							# SF01_01319004_Typ2 | delay          MU;P0=705;P1=-140;P2=-336;P3=-667;P4=377;P5=-15230;P6=248;D=01020342020343420202034343420202020345420203420203434202020343434202020203654202034202034342020203434342020202034542020342020343420202034343420202020345420203420203434202020343434202020203454202034202034342020203434342020202034542020342020343420202034343;CP=4;O;
							# SF01_01319004_Typ2 | minus          MU;P0=704;P1=-338;P2=-670;P3=378;P4=-15227;P5=244;D=01023231010102323231010102310431010231010232310101023232310101025104310102310102323101010232323101010231043101023101023231010102323231010102310431010231010232310101023232310101023104310102310102323101010232323101010231043101023101023231010102323231010102;CP=3;O;
							# SF01_01319004_Typ2 | interval       MU;P0=-334;P1=709;P2=-152;P3=-663;P4=379;P5=-15226;P6=250;D=01210134010134340101013434340101340134540101340101343401010134343401013601365401013401013434010101343434010134013454010134010134340101013434340101340134540101340101343401010134343401013401345401013401013434010101343434010134013454010134010134340101013434;CP=4;O;
			{
				name					=> 'BOSCH | CAME | Novy | Neff | Refsta Topdraft',
				comment				=> 'remote control CAME TOP 432EV, Novy 840029, BOSCH / Neff or Refsta Topdraft SF01 01319004',
				id						=> '86',
				knownFreqs		=> '433.92',
				one						=> [-2,1],
				zero					=> [-1,2],
				start					=> [-44,1],
				clockabs			=> 350,
				format				=> 'twostate',
				preamble			=> 'P86#',				# prepend to converted message
				clientmodule	=> 'SD_UT',
				#modulematch	=> '^P86#.*',
				length_min		=> '12',
				length_max		=> '18',
			},
		"87"	=>	## JAROLIFT Funkwandsender TDRC 16W / TDRCT 04W
							# https://github.com/RFD-FHEM/RFFHEM/issues/380 @bismosa
							# P87#E8119A34200065F100 | button=up   MS;P1=1524;P2=-413;P3=388;P4=-3970;P5=-815;P6=778;P7=-16024;D=34353535623562626262626235626262353562623535623562626235356235626262623562626262626262626262626262623535626235623535353535626262356262626262626267123232323232323232323232;CP=3;SP=4;R=226;O;m2;
							# P87#CD287247200065F100 | button=up   MS;P0=-15967;P1=1530;P2=-450;P3=368;P4=-3977;P5=-835;P6=754;D=34353562623535623562623562356262626235353562623562623562626235353562623562626262626262626262626262623535626235623535353535626262356262626262626260123232323232323232323232;CP=3;SP=4;R=229;O;
							# KeeLoq is a registered trademark of Microchip Technology Inc.
			{
				name					=> 'JAROLIFT',
				comment				=> 'remote control JAROLIFT TDRC_16W / TDRCT_04W',
				id						=> '87',
				knownFreqs		=> '433.92',
				one						=> [1,-2],
				zero					=> [2,-1],
				preSync				=> [3.8,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1],
				sync					=> [1,-10],				# this is a end marker, but we use this as a start marker
				pause					=> [-40],
				clockabs			=> 400,						# ca 400us
				reconstructBit			=> '1',
				format				=> 'twostate',
				preamble			=> 'P87#',				# prepend to converted message
				clientmodule	=> 'SD_Keeloq',
				#modulematch	=> '',
				length_min		=> '72',					# 72
				length_max		=> '85',					# 85
			},
		"88"	=>	## Roto Dachfensterrolladen | Aurel Fernbedienung "TX-nM-HCS" (HCS301 Chip) | three buttons -> up, stop, down
							# https://forum.fhem.de/index.php/topic,91244.0.html @bruen985
							# P88#AC3895D790EAFEF2C | button=0100   MS;P1=361;P2=-435;P4=-4018;P5=-829;P6=759;P7=-16210;D=141562156215156262626215151562626215626215621562151515621562151515156262156262626215151562156215621515151515151562151515156262156215171212121212121212121212;CP=1;SP=4;R=66;O;m0;
							# P88#9451E57890EAFEF24 | button=0100   MS;P0=-16052;P1=363;P2=-437;P3=-4001;P4=-829;P5=755;D=131452521452145252521452145252521414141452521452145214141414525252145252145252525214141452145214521414141414141452141414145252145252101212121212121212121212;CP=1;SP=3;R=51;O;m1;
							# Waeco_MA650_TX | too buttons
							# KeeLoq is a registered trademark of Microchip Technology Inc.
			{
				name					=> 'Roto shutter | other',
				comment				=> 'remote control Aurel TX-nM-HCS | Waeco_MA650_TX',
				id						=> '88',
				knownFreqs		=> '433.92',
				one						=> [1,-2],        # PWM bit pulse width typ. 1.2 mS
				zero					=> [2,-1],				# PWM bit pulse width typ. 1.2 mS
				preSync				=> [1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1,],	# 11 pulses preambel, 1 sync, 66 data, pause ... repeat
				sync					=> [1,-10],				# Header duration typ. 4 mS
				pause         => [-39],         # Guard Time typ. 15.6 mS
				clockabs			=> 400,						# Basic pulse element typ. 0.4 mS (TABLE 8-4)
				reconstructBit	=> '1',
				format				=> 'twostate',
				preamble			=> 'P88#',				# prepend to converted message
				clientmodule			=> 'SD_Keeloq',
				#modulematch	=> '',
				length_min		=> '65',
				length_max		=> '78',
			},
		"89" => ## Funk Wetterstation TFA 35.1140.01 mit Temperatur-/Feuchtesensor TFA 30.3221.02 12/2018 @Iron-R
						# ! some message are decode as protocol 37 and 61 !
						# https://github.com/RFD-FHEM/RFFHEM/issues/266
						# Ch:3 T: 5.5 H: 58 Bat:low   MU;P0=-900;P1=390;P2=-499;P3=-288;P4=193;P7=772;D=1213424213131342134242424213134242137070707013424213134242131342134242421342424213421342131342421313134213424242421313424213707070701342421313424213134213424242134242421342134213134242131313421342424242131342421;CP=4;R=43;
						# Ch:3 T: 5.4 H: 58 Bat:low   MU;P0=-491;P1=382;P2=-270;P3=179;P4=112;P5=778;P6=-878;D=01212304012123012303030123030301230123012303030121212301230301230121212121256565656123030121230301212301230303012303030123012301230303012121230123030123012121212125656565612303012123030121230123030301230303012301230123030301212123012303012301212121212565;CP=3;R=43;O;
						# Ch:3 T: 5 H: 60 Bat:low     MU;P0=-299;P1=384;P2=169;P3=-513;P5=761;P6=-915;D=01023232310101010101023565656561023231010232310102310232323102323231023231010232323101010102323231010101010102356565656102323101023231010231023232310232323102323101023232310101010232323101010101010235656565610232310102323101023102323231023232310232310102;CP=2;R=43;O;
						# Ch:2 T: 6.5 H: 62 Bat:ok    MU;P0=-32001;P1=412;P2=-289;P3=173;P4=-529;P5=777;P6=-899;D=01234345656541212341234123434121212121234123412343412343456565656121212123434343434343412343412343434121234123412343412121212123412341234341234345656565612121212343434343434341234341234343412123412341234341212121212341234123434123434565656561212121234343;CP=3;R=22;O;
						# Ch:2 T: 6.3 H: 62 Bat:ok    MU;P0=22960;P1=-893;P2=775;P3=409;P4=-296;P5=182;P6=-513;D=01212121343434345656565656565634565634565656343456563434565634343434345656565656565656342121212134343434565656565656563456563456565634345656343456563434343434565656565656565634212121213434343456565656565656345656345656563434565634345656343434343456565656;CP=5;R=22;O;
						# Ch:2 T: 6.1 H: 66 Bat:ok    MU;P0=172;P1=-533;P2=401;P3=-296;P5=773;P6=-895;D=01230101230101012323010101230123010101010101230101230101012323010101230123010301230101010101012301012301010123230101012301230101010123010101010101012301565656562323232301010101010101230101230101012323010101230123010101012301010101010101230156565656232323;CP=0;R=23;O;
			{
				name         => 'TFA 30.3221.02',
				comment      => 'temperature / humidity sensor for weatherstation TFA 35.1140.01',
				id           => '89',
				knownFreqs	 => '433.92',
				one          => [2,-1],
				zero         => [1,-2],
				start        => [3,-3,3,-3,3,-3],
				clockabs     => 250,
				format       => 'twostate',
				preamble     => 'W89#',
				postamble    => '',
				clientmodule => 'SD_WS',
				length_min   => '40',
				length_max   => '40',
			},
		"90"	=>	## mumbi AFS300-s / manax MX-RCS250 (CP 258-298)
							# https://forum.fhem.de/index.php/topic,94327.15.html @my-engel @peterboeckmann
							# A	AN    MS;P0=-9964;P1=273;P4=-866;P5=792;P6=-343;D=10145614141414565656561414561456561414141456565656561456141414145614;CP=1;SP=0;R=35;O;m2;
							# A	AUS   MS;P0=300;P1=-330;P2=-10160;P3=804;P7=-840;D=02073107070707313131310707310731310707070731313107310731070707070707;CP=0;SP=2;R=23;O;m1;
							# B	AN    MS;P1=260;P2=-873;P3=788;P4=-351;P6=-10157;D=16123412121212343434341212341234341212121234341234341234121212341212;CP=1;SP=6;R=21;O;m2;
							# B	AUS   MS;P1=268;P3=793;P4=-337;P6=-871;P7=-10159;D=17163416161616343434341616341634341616161634341616341634161616343416;CP=1;SP=7;R=24;O;m2;
			{
				name         => 'mumbi | MANAX',
				comment      => 'remote control mumbi RC-10, MANAX MX-RCS250 (only receive)',
				id           => '90',
				knownFreqs   => '433.92',
				one          => [3,-1],
				zero         => [1,-3],
				sync         => [1,-36],
				clockabs     => 280,						# -1=auto	
				format       => 'twostate',
				preamble     => 'P90#',
				length_min   => '33',
				length_max   => '36',
				clientmodule => 'SD_UT',
				modulematch	=> '^P90#.*',
			},
		"91"	=>	## Atlantic Security / Focus Security China Devices
							# https://forum.fhem.de/index.php/topic,58397.msg876862.html#msg876862 @Harst @jochen_f
							# normal    MU;P0=800;P1=-813;P2=394;P3=-410;P4=-3992;D=0123030303030303012121230301212304230301212301230301212123012301212303012301230303030303030121212303012123042303012123012303012121230123012123030123012303030303030301212123030121230;CP=2;R=46;
							# normal    MU;P0=406;P1=-402;P2=802;P3=-805;P4=-3994;D=012123012301212121212121230303012123030124012123030123012123030301230123030121230123012121212121212303030121230301240121230301230121230303012301230301212301230121212121212123030301212303012;CP=0;R=52;
							# warning   MU;P0=14292;P1=-10684;P2=398;P3=-803;P4=-406;P5=806;P6=-4001;D=01232324532453232454532453245454532324545323232453245324562454532324532454532323245324532324545324532454545323245453232324532453245624545323245324545323232453245323245453245324545453232454532323245324532456245453232453245453232324532453232454532453245454;CP=2;R=50;O;
			{
				name					=> 'Atlantic security',
				comment				=> 'example sensor MD-210R | MD-2018R | MD-2003R (MU decode)',
				id						=> '91',
				knownFreqs		=> '433.92 | 868.35',
				one           => [-2,1],
				zero          => [-1,2],
				start					=> [-10,1],
				clockabs			=> 400,
				format				=> 'twostate',	#
				preamble			=> 'P91#',			# prepend to converted message
				length_min		=> '36',
				length_max		=> '36',
				clientmodule	=> 'SD_UT',
				#modulematch	=> '^P91#.*',
				reconstructBit		=> '1',
			},
		"91.1"	=>	## Atlantic Security / Focus Security China Devices
							# https://forum.fhem.de/index.php/topic,58397.msg878008.html#msg878008 @Harst @jochen_f
							# warning   MS;P0=-399;P1=407;P2=820;P3=-816;P4=-4017;D=14131020231020202313131023131313131023102023131313131310202313131020202313;CP=1;SP=4;O;m0;
							# warning   MS;P1=392;P2=-824;P3=-416;P4=804;P5=-4034;D=15121343421343434212121342121212121342134342121212121213434212121343434212;CP=1;SP=5;e;m2;
			{
				name						=> 'Atlantic security',
				comment					=> 'example sensor MD-210R | MD-2018R | MD-2003R (MS decode)',
				id							=> '91.1',
				knownFreqs			=> '433.92 | 868.35',
				one							=> [-2,1],
				zero						=> [-1,2],
				sync						=> [-10,1],
				clockabs				=> 400,
				reconstructBit	=> '1',
				format					=> 'twostate',	#
				preamble				=> 'P91#',		# prepend to converted message
				length_min			=> '32',
				length_max			=> '36',
				clientmodule		=> 'SD_UT',
				#modulematch		=> '^P91.1#.*',
			},
		"92"	=>	## KRINNER Lumix - LED X-MAS
							# https://github.com/RFD-FHEM/RFFHEM/issues/452 | https://forum.fhem.de/index.php/topic,94873.msg876477.html?PHPSESSID=khp4ja64pcqa5gsf6gb63l1es5#msg876477 @gestein
							# on    MU;P0=24188;P1=-16308;P2=993;P3=-402;P4=416;P5=-967;P6=-10162;D=0123234545454523234523234545454545454545232623452345454545454523234523234545454523234523234545454545454545232623452345454545454523234523234545454523234523234545454545454545232623452345454545454523234523234545454523234523234545454545454545232;CP=4;R=25;
							# off   MU;P0=11076;P1=-20524;P2=281;P3=-980;P4=982;P5=-411;P6=408;P7=-10156;D=0123232345456345456363636363636363634745634563636363636345456345456363636345456345456363636363636363634745634563636363636345456345456363636345456345456363636363636363634745634563636363636345456345456363636345456345456363636363636363634;CP=6;R=38;
			{
				name					=> 'KRINNER Lumix',
				comment				=> 'remote control LED X-MAS',
				id						=> '92',
				knownFreqs		=> '433.92',
				zero					=> [1,-2],
				one						=> [2,-1],
				start					=> [2,-24],
				clockabs			=> 420,
				format				=> 'twostate',	#
				preamble			=> 'P92#',			# prepend to converted message
				length_min		=> '32',
				length_max		=> '32',
				clientmodule	=> 'SD_UT',
				#modulematch	=> '^P92#.*',
			},
		"93"	=>	## ESTO Lighting GmbH | remote control KL-RF01 with 9 buttons (CP 375-395)
							# https://github.com/RFD-FHEM/RFFHEM/issues/449 @daniel89fhem 
							# light_color_cold_white   MS;P1=376;P4=-1200;P5=1170;P6=-409;P7=-12224;D=17141414561456561456565656145656141414145614141414565656145656565614;CP=1;SP=7;R=231;e;m0; 
							# dimup                    MS;P1=393;P2=-1174;P4=1180;P5=-401;P6=-12222;D=16121212451245451245454545124545124545451212121212121212454545454512;CP=1;SP=6;R=243;e;m0;
							# dimdown                  MS;P0=397;P1=-385;P2=-1178;P3=1191;P4=-12230;D=04020202310231310231313131023131023131020202020202020231313131313102;CP=0;SP=4;R=250;e;m0;
			{
				name         => 'ESTO Lighting GmbH',
				comment      => 'remote control KL-RF01',
				id           => '93',
				knownFreqs   => '433.92',
				one          => [3,-1],
				zero         => [1,-3],
				sync         => [1,-32],
				clockabs     => 385,						# -1=auto	
				format       => 'twostate',
				preamble     => 'P93#',
				length_min   => '32',           # 2. MSG:	32 Bit, bleibt so
				length_max   => '36',           # 1. MSG: 33 Bit, wird verlängert auf 36 Bit
				clientmodule	=> 'SD_UT',
				#modulematch	=> '^P93#.*',
			},
		"94"	=>	# Atech wireless weather station (vermutlicher Name: WS-308)
							# https://github.com/RFD-FHEM/RFFHEM/issues/547 @Kreidler1221 2019-03-15
							# Sensor sends Bit 0 as "0", Bit 1 as "110"
							# Id:0C T:-14.6 MU;P0=-32001;P1=1525;P2=-303;P3=-7612;P4=-2008;D=01212121212121213141414141212141212141414141412121414141414121214141212141414141212141212141412121412121414121214121;CP=1;
							# Id:0C T:-0.4  MU;P0=-32001;P1=1533;P2=-297;P3=-7612;P4=-2005;D=0121212121212121314141414121214121214141414141212141414141414141414141412121414141212141412121414121;CP=1;
							# Id:0C T:0.2   MU;P0=-32001;P1=1532;P2=-299;P3=-7608;P4=-2005;D=0121212121212121314141414121214121214141414141414141414141414141414141212141412121412121412121414121;CP=1;
							# Id:0C T:10.2  MU;P0=-31292;P1=1529;P2=-300;P3=-7610;P4=-2009;D=012121212121212131414141412121412121414141414141414141412121414141414141412121414121214121214121214121214121012121212121212131414141412121412121414141414141414141412121414141414141412121414121214121214121214121214121;CP=1;
							# Id:0C T:27    MU;P0=-31290;P1=1533;P2=-297;P3=-7608;P4=-2006;D=012121212121212131414141412121412121414141414141414141212141414121214121214121214141414141212141414121214121012121212121212131414141412121412121414141414141414141212141414121214121214121214141414141212141414121214121;CP=1;
			{
				name            => 'Atech',
				comment         => 'Temperature sensor',
				id              => '94',
				knownFreqs      => '433.92',
				one             => [5.3,-1],     # 1537, 290
				zero            => [5.3,-6.9],   # 1537, 2001
				start           => [5.3,-26.1],  # 1537, 7569
				clockabs        => 290,
				reconstructBit  => '1',
				format          => 'twostate',
				preamble        => 'W94#',
				clientmodule    => 'SD_WS',
				length_min      => '24',         # minimal 24*0=24 Bit, kuerzeste bekannte aus Userlog: 36
				length_max      => '96',         # maximal 24*110=96 Bit, laengste bekannte aus Userlog:  60
			},
		"95"	=>	# Techmar / Garden Lights Fernbedienung, 6148011 Remote control + 12V Outdoor receiver
							# https://github.com/RFD-FHEM/RFFHEM/issues/558 @BlackcatSandy
							# Group_1_on    MU;P0=-972;P1=526;P2=-335;P3=-666;D=01213131312131313121212121312121313131313121312131313121313131312121212121312121313131313121313121212101213131312131313121212121312121313131313121312131313121313131312121212121312121313131313121313121212101213131312131313121212121312121313131313121312131;CP=1;R=44;O;
							# Group_5_on    MU;P0=-651;P1=530;P2=-345;P3=-969;D=01212121312101010121010101212121210121210101010101210121010101210101010121212121012121210101010121010101212101312101010121010101212121210121210101010101210121010101210101010121212121012121210101010121010101212121312101010121010101212121210121210101010101;CP=1;R=24;O;
							# Group_8_off   MU;P0=538;P1=-329;P2=-653;P3=-964;D=01020301020202010202020101010102010102020202020102010202020102020202010101010101010201020202020202010202010301020202010202020101010102010102020202020102010202020102020202010101010101010201020202020202010201010301020202010202020101010102010102020202020102;CP=0;R=19;O;
			{
				name            => 'Techmar',
				comment         => 'Garden Lights remote control',
				id              => '95',
				knownFreqs      => '433.92',
				one             => [5,-6],	# 550,-660
				zero            => [5,-3],	# 550,-330
				start           => [5,-9],	# 550,-990
				clockabs        => 110,
				format          => 'twostate',
				preamble        => 'P95#',
				clientmodule    => 'SD_UT',
				length_min      => '50',
				length_max      => '50',
			},
		"96"	=>	# Funk-Gong | Taster Grothe Mistral SE 03.1 , Innenteil Grothe Mistral 200M(E)
							# https://forum.fhem.de/index.php/topic,64251.msg940593.html?PHPSESSID=nufcvvjobdd8r7rgr0cq3qkrv0#msg940593 @coolheizer
							# Button_1    MC;LL=-424;LH=438;SL=-215;SH=212;D=238823B1001F8;C=214;L=49;R=68;
							# Button_2    MC;LL=-412;LH=458;SL=-187;SH=240;D=238129D9A78;C=216;L=41;R=241;
			{
				name            => 'Grothe Mistral',
				comment         => 'wireless gong',
				id              => '96',
				knownFreqs      => '866.35',
				clockrange			=> [210,220],							# min , max
				format					=> 'manchester',					# tristate can't be migrated from bin into hex!
				#clientmodule		 => '',
				#modulematch		 => '^u96#',
				preamble				=> 'u96#',
				length_min			=> '41',
				length_max			=> '49',
				method					=> \&lib::SD_Protocols::MCRAW,		# Call to process this message
			},
	);
	sub getProtocolList	{	
		return \%protocols;	
	}

}