# $Id: SD_ProtocolData.pm 0 2025-06-09 18:35:21Z elektron-bbs $
# The file is part of the SIGNALduino project.
# All protocol definitions are contained in this file.
#
# 2016-2019  S.Butzek, Ralf9
# 2019-2025  S.Butzek, HomeAutoUser, elektron-bbs
#
# !!! useful hints !!!
# --------------------
# name             => ' '       # name of device or group of all devices
# comment          => ' '       # exact description or example of devices
# id               => ' '       # number of the protocol definition, each number only once use (accepted no .)
# knownFreqs       => ' '       # known receiver frequency 433.92 | 868.35 (some sensor families or remote send on more frequencies)
#
# Time for one, zero, start, sync, float, end and pause are calculated by clockabs * value = result in microseconds, positive value stands for high signal, negative value stands for low signal
# clockrange       => [ , ]     # only MC signals | min , max of pulse / pause times in microseconds
# clockabs         => ' '       # only MU + MS signals | value for calculation of pulse / pause times in microseconds
# clockabs         => '-1'      # only MS signals | value pulse / pause times is automatically
# one              => [ , ]     # only MU + MS signals | value pair for a one bit, must be always a positive and negative factor of clockabs (accepted . | example 1.5)
# zero             => [ , ]     # only MU + MS signals | value pair for a zero bit, must be always a positive and negative factor of clockabs (accepted . | example -1.5)
# start            => [ , ]     # only MU - value pair or more for start message
# preSync          => [ , ]     # only MU + MS - value pair or more for preamble pulse of signal
# sync             => [ , ]     # only MS - value pair or more for sync pulse of signal
# float            => [ , ]     # only MU + MS signals | Convert 0F -> 01 (F) to be compatible with CUL
# pause            => [ ]       # only MU + MS signals, delay when sending between two repeats (clockabs * pause must be < 32768)
# end              => [ ]       # only MU + MS - value or more for end pulse of signal for sending
# msgIntro         => ' '       # only MC - make combined message msgIntro.MC for sending ('SR;P0=-2560;P1=2560;P3=-640;D=10101010101010113;',)
# msgOutro         => ' '       # only MC - make combined message MC.msgOutro for sending ('SR;P0=-8500;D=0;',)
#
# length_min       => ' '       # minimum number of bits (MC, MS, MU) or nibbles (MN) of message length (MU, MS: If reconstructBit is set, then set length_min=length_min-1)
# length_max       => ' '       # maximum number of bits (MC, MS, MU) or nibbles (MN) of message length
# paddingbits      => ' '       # pad up to x bits before call module, default is 4. | --> option is active if paddingbits not defined in message definition !
# paddingbits      => '1'       # will disable padding, use this setting when using dispatchBin
# paddingbits      => '2'       # is padded to an even number, that is a maximum of 1 bit
# remove_zero      => 1         # removes leading zeros from output
# reconstructBit   => 1         # If set, then the last bit is reconstructed if the rest is missing. (If reconstructBit is set, then set length_min=length_min-1)
#
# developId        => 'm'       # logical module is under development
# developId        => 'p'       # protocol is under development or to reserve IDs, the ID in the development attribute with developId => 'p' are only used without the other entries
# developId        => 'y'       # protocol is under development, all IDs in the development attribute with developId => 'y' are used
#
# preamble         => ' '       # prepend to converted message
# preamble         => 'u..'     # message is unknown and without module, forwarding SIGNALduino_un or FHEM DOIF
# preamble         => 'U..'     # message can be unknown and without module, no forwarding SIGNALduino_un but forwarding can FHEM DOIF
# postamble        => ' '       # appends a string to the demodulated signal
#
# clientmodule     => ' '       # FHEM module for processing
# filterfunc       => ' '       # SIGNALduino_filterSign | SIGNALduino_compPattern --> SIGNALduino internal filter function, it remove the sign from the pattern, and compress message and pattern
#                               # SIGNALduino_filterMC --> SIGNALduino internal filter function, it will decode MU data via Manchester encoding
# dispatchBin      => 1         # If set to 1, data will be dispatched in binary representation to other logcial modules.
#                                 If not set (default) or set to 0, data will be dispatched in hex mode to other logical modules.
# dispatchequals   => 'true'    # Dispatch if dispatchequals is provided in protocol definition or only if $dmsg is different from last $dmsg, or if 2 seconds are between transmits
# postDemodulation => \&        # only MU - SIGNALduino internal sub for processing before dispatching to a logical module
# method           => \&        # call to process this message
#                                 system method: lib::SD_Protocols::MCRAW -> returns bits without editing and length check included
#
# frequency        => ' '       # frequency to set register cc1101 to send | example: 10AB85550A
# format           => ' '       # twostate | pwm | manchester --> modulation type of the signal, only manchester use SIGNALduino internal, other types only comment
# modulematch      => ' '       # RegEx on the exact message including preamble | if defined, it will be evaluated
# polarity         => 'invert'  # only MC signals | invert bits of the signal
#
# xFSK - Information
# datarate         => ' '       # transmission speed signal
# modulation       => ' '       # modulation type of the signal
# regexMatch       => ' '       # Regex objct which must match on the raw message qr//
# register         => ' '       # specifics cc1101 settings [$adr$value]
# rfmode           => ' '       # receive mode, default SlowRF -> ASK/OOK
# sync             => ' '       # sync parameter of signal in hex (example, 2DD4)
#
##### notice #### or #### info ############################################################################################################
# !!! Between the keys and values no tabs, please use spaces !!!
# !!! Please use first unused id for new protocols !!!
# ID´s are currently unused: 136 - 
# ID´s need to be revised (preamble u): 5|19|21|23|25|28|31|36|40|52|59|63
###########################################################################################################################################
# Please provide at least three messages for each new MU/MC/MS/MN protocol and a URL of issue in GitHub or discussion in FHEM Forum
# https://forum.fhem.de/index.php/topic,58396.975.html | https://github.com/RFD-FHEM/RFFHEM
###########################################################################################################################################

use strict;
use warnings;

package lib::SD_ProtocolData;
{
  use strict;
  use warnings;

  our $VERSION = '1.59';
  our %protocols = (
    "0" =>  ## various weather sensors (500 | 9100)
            # Mebus | Id:237 Ch:1 T: 1.9 Bat:low           MS;P0=-9298;P1=495;P2=-1980;P3=-4239;D=1012121312131313121313121312121212121212131212131312131212;CP=1;SP=0;R=223;O;m2;
            # GT_WT_02 | Id:163 Ch:1 T: 2.9 H: 86 Bat:ok   MS;P0=531;P1=-9027;P3=-4126;P4=-2078;D=0103040304040403030404040404040404040404030303040303040304030304030304040403;CP=0;SP=1;R=249;O;m2;
            # Prologue | Id:145 Ch:0 T: 2.6, Bat:ok        MS;P0=-4152;P1=643;P2=-2068;P3=-9066;D=1310121210121212101210101212121212121212121212121010121012121212121012101212;CP=1;SP=3;R=220;O;m2;
            # Prologue | Id:145 Ch:0 T: 2.7, Bat:ok        MS;P0=-4149;P2=-9098;P3=628;P4=-2076;D=3230343430343434303430303434343434343434343434343030343030343434343034303434;CP=3;SP=2;R=218;O;m2;
      {
        name             => 'weather (v1)',
        comment          => 'temperature / humidity or other sensors',
        id               => '0',
        knownFreqs       => '433.92',
        one              => [1,-7],
        zero             => [1,-3],
        sync             => [1,-16],
        clockabs         => -1,
        format           => 'twostate',  # not used now
        preamble         => 's',
        postamble        => '00',
        clientmodule     => 'CUL_TCM97001',
        #modulematch      => '^s[A-Fa-f0-9]+',
        length_min       => '24',
        length_max       => '40',
        paddingbits      => '8',         # pad up to 8 bits, default is 4
      },
    "0.1" =>  ## other Sensors  (380 | 9650)
              # Mebus | Id:237 Ch:1 T: 1.3 Bat:low   MS;P1=416;P2=-9618;P3=-4610;P4=-2036;D=1213141313131313141313141314141414141414141313141314131414;CP=1;SP=2;R=220;O;m0;
              # Mebus | Id:151 Ch:1 T: 1.2 Bat:low   MS;P0=-9690;P3=354;P4=-4662;P5=-2107;D=3034343434343535343534343435353535353535353434353535343535;CP=3;SP=0;R=209;O;m2;
              # https://github.com/RFD-FHEM/RFFHEM/issues/63 @localhosthack0r
              # AURIOL | Id:255 T: 0.0 Bat:ok | LIDL Wetterstation   MS;P1=367;P2=-2077;P4=-9415;P5=-4014;D=141515151515151515121512121212121212121212121212121212121212121212;CP=1;SP=4;O;
      {
        name             => 'weather (v2)',
        comment          => 'temperature / humidity or other sensors',
        id               => '0.1',
        knownFreqs       => '433.92',
        one              => [1,-12],
        zero             => [1,-6],
        sync             => [1,-26],
        clockabs         => -1,
        format           => 'twostate',  # not used now
        preamble         => 's',
        postamble        => '00',
        clientmodule     => 'CUL_TCM97001',
        #modulematch      => '^s[A-Fa-f0-9]+',
        length_min       => '24',
        length_max       => '32',
        paddingbits      => '8',
      },
    "0.2" =>  ## other Sensors | for sensors how tol is runaway (260+tol | 9650)
              # Mebus | Id:151 Ch:1 T: 0.4 Bat:low   MS;P1=-2140;P2=309;P3=-4690;P4=-9695;D=2421232323232121232123232321212121212121212123212121232121;CP=2;SP=4;R=211;m1;
              # Mebus | Id:151 Ch:1 T: 0.3 Bat:low   MS;P0=-9703;P1=304;P2=-2133;P3=-4689;D=1012131312131212131213131312121212121212121212131312131212;CP=1;SP=0;R=208;
      {
        name             => 'weather (v3)',
        comment          => 'temperature / humidity or other sensors',
        id               => '0.2',
        knownFreqs       => '433.92',
        one              => [1,-18],
        zero             => [1,-9],
        sync             => [1,-37],
        clockabs         => -1,
        format           => 'twostate',  # not used now
        preamble         => 's',
        postamble        => '00',
        clientmodule     => 'CUL_TCM97001',
        #modulematch      => '^s[A-Fa-f0-9]+',
        length_min       => '24',
        length_max       => '32',
        paddingbits      => '8',
      },
    "0.3" =>  ## Pollin PFR-130
              # CUL_TCM97001_Unknown                   MS;P0=-3890;P1=386;P2=-2191;P3=-8184;D=1312121212121012121212121012121212101012101010121012121210121210101210101012;CP=1;SP=3;R=20;O;
              # CUL_TCM97001_Unknown                   MS;P0=-2189;P1=371;P2=-3901;P3=-8158;D=1310101010101210101010101210101010121210121212101210101012101012121012121210;CP=1;SP=3;R=20;O;
              # Ventus W174 | Id:17 R: 103.25 Bat:ok   MS;P3=-2009;P4=479;P5=-9066;P6=-4047;D=45434343464343434643464643464643434643464646434346464343434343434346464643;CP=4;SP=5;R=55;O;m2;
      {
        name             => 'weather (v4)',
        comment          => 'temperature / humidity or other sensors | Pollin PFR-130, Ventus W174 ...',
        id               => '0.3',
        knownFreqs       => '433.92',
        one              => [1,-10],
        zero             => [1,-5],
        sync             => [1,-21],
        clockabs         => -1,
        preamble         => 's',
        postamble        => '00',
        clientmodule     => 'CUL_TCM97001',
        length_min       => '36',
        length_max       => '42',
        paddingbits      => '8',         # pad up to 8 bits, default is 4
      },
    "0.4" =>  ## Auriol Z31092  (450 | 9200)
              # AURIOL | Id:95 T: 6.1 Bat:low    MS;P0=443;P3=-9169;P4=-1993;P5=-3954;D=030405040505050505050404040404040404040505050504050405050504040405;CP=0;SP=3;R=14;O;m0;
              # AURIOL | Id:190 T: 2.8 Bat:low   MS;P0=-9102;P1=446;P2=-3956;P3=-2008;D=10121312121212121312131213131313131313131212121313121213121213121314;CP=1;SP=0;R=212;O;m2;
      {
        name             => 'weather (v5)',
        comment          => 'temperature / humidity or other sensors | Auriol Z31092',
        id               => '0.4',
        knownFreqs       => '433.92',
        one              => [1,-9],
        zero             => [1,-4],
        sync             => [1,-20],
        clockabs         => 450,
        preamble         => 's',
        postamble        => '00',
        clientmodule     => 'CUL_TCM97001',
        length_min       => '32',
        length_max       => '36',
        paddingbits      => '8',         # pad up to 8 bits, default is 4
      },
    "0.5" =>  ## various weather sensors (475 | 8000)
              # ABS700 | Id:79 T: 3.3 Bat:low     MS;P1=-7949;P2=492;P3=-1978;P4=-3970;D=21232423232424242423232323232324242423232323232424;CP=2;SP=1;R=245;O;
              # ABS700 | Id:69 T: 9.3 Bat:low     MS;P1=-7948;P2=471;P3=-1997;P4=-3964;D=21232423232324232423232323242323242423232323232424;CP=2;SP=1;R=246;O;m2;
      {
        name             => 'weather (v6)',
        comment          => 'temperature / humidity or other sensors | ABS700',
        id               => '0.5',
        knownFreqs       => '433.92',
        one              => [1,-8],
        zero             => [1,-4],
        sync             => [1,-16],
        clockabs         => 475,
        format           => 'twostate',     # not used now
        preamble         => 's',
        postamble        => '00',
        clientmodule     => 'CUL_TCM97001',
        #modulematch      => '^s[A-Fa-f0-9]+',
        length_min       => '24',
        length_max       => '24',
        paddingbits      => '8',            # pad up to 8 bits, default is 4
      },
    "1"  =>   ## Conrad RSL
              # on   MS;P1=1154;P2=-697;P3=559;P4=-1303;P5=-7173;D=351234341234341212341212123412343412341234341234343434343434343434;CP=3;SP=5;R=247;O;
              # on   MS;P0=561;P1=-1291;P2=-7158;P3=1174;P4=-688;D=023401013401013434013434340134010134013401013401010101010101010101;CP=0;SP=2;R=248;m1;
      {
        name             => 'Conrad RSL v1',
        comment          => 'remotes and switches',
        id               => '1',
        knownFreqs       => '',
        one              => [2,-1],
        zero             => [1,-2],
        sync             => [1,-12],
        clockabs         => '560',
        format           => 'twostate',    # not used now
        preamble         => 'P1#',
        postamble        => '',
        clientmodule     => 'SD_RSL',
        modulematch      => '^P1#[A-Fa-f0-9]{8}',
        length_min       => '20',          # 23 | userMSG 32 ?
        length_max       => '40',          # 24 | userMSG 32 ?
      },
    "2"  =>   ## Self build arduino sensor
             # ArduinoSensor_temp_2      T: 21.0  MS;P1=-463;P2=468;P3=-1043;P5=-9981;D=252121212121232321232321212121232123232123212123212321212121212121232321212123212324;CP=2;SP=5;R=16;O;m2;
             # ArduinoSensor_humidity_2  H: 61.9  MS;P0=-491;P2=523;P4=-991;P7=-9972;D=272020202024202024242420202020242020242420242024242420202020202420202424242420242426;CP=2;SP=7;m2;
             # ArduinoSensor_voltage_2   V: 3.65  MS;P0=-10406;P1=513;P2=-437;P4=-1013;D=10121212121412121214141212121214121212141414141214121212121414141212141214141214121;CP=1;SP=0;
      {
        name             => 'Arduino',
        comment          => 'self build arduino sensor (developModule. SD_AS module only in github)',
        developId        => 'm',
        id               => '2',
        knownFreqs       => '',
        one              => [1,-2],
        zero             => [1,-1],
        sync             => [1,-20],
        clockabs         => '500',
        format           => 'twostate',
        preamble         => 'P2#',
        clientmodule     => 'SD_AS',
        modulematch      => '^P2#.{8,10}',
        length_min       => '32', # without CRC
        length_max       => '40', # with CRC
      },
    "3"  =>  ## itv1 - remote with IC PT2262 example: ELRO | REWE | Intertek Modell 1946518 | WOFI Lamp // PIR JCHENG with Wireless Coding EV1527
             ## (real CP=300 | repeatpause=9300)
             # REWE Model: 0175926R -> on | v1      MS;P1=-905;P2=896;P3=-317;P4=303;P5=-9299;D=45412341414123412341414123412341234141412341414123;CP=4;SP=5;R=91;A;#;
             ## (real CP=330 | repeatpause=10100)
             # ELRO AB440R -> on | v1               MS;P1=-991;P2=953;P3=-356;P4=303;P5=-10033;D=45412341234141414141234123412341234141412341414123;CP=4;SP=5;R=93;m1;A;A;
             ## (real CP=300 | repeatpause=9400)
             # Kangtai Model Nr.: 6899 -> on | v1   MS;P0=-328;P1=263;P2=-954;P3=888;P5=-9430;D=15123012121230123012121230123012301212123012121230;CP=1;SP=5;R=35;m2;0;0;
             # door/window switch from CHN (PT2262 compatible) from amazon & ebay | itswitch_CHN model
             # open                                 MS;P1=-478;P2=1360;P3=468;P4=-1366;P5=-14045;D=35212134212134343421212134213434343434343421342134;CP=3;SP=5;R=30;O;m2;4;
             # close                                MS;P1=-474;P2=1373;P3=455;P4=-1367;P5=-14044;D=35212134212134343421212134213434343434343421212134;CP=3;SP=5;R=37;O;m2;
             ## JCHENG SECURITY Wireless PIR
             # (only autocreate -> J2 Data setting D0 open | D1 closed | D2 closed | D3 open)
             # on                                   MS;P1=-12541;P2=1227;P3=-405;P4=407;P5=-1209;D=41232323232345452323454523452323234545234545232345;CP=4;SP=1;R=35;O;m2;E;
             ## benon (Semexo OHG) | remote BH-P with 5 Channels, switch B2112 | Amazon
             ## (real CP=160) chip HS2260C-R4 | length 24
             # on                                   MS;P0=160;P4=-542;P5=515;P6=-174;P7=-5406;D=07040404560404045604560456045604560404565604045656;CP=0;SP=7;R=24;O;m2;
             # off                                  MS;P1=-538;P2=163;P3=518;P4=-175;P5=-5396;D=25212121342121213421342134213421342121343434342121;CP=2;SP=5;R=31;O;m2;4;
      {
        name             => 'chip xx2260 / xx2262',
        comment          => 'remote for benon|ELRO|Kangtai|Intertek|REWE|WOFI / PIR JCHENG',
        id               => '3',
        knownFreqs       => '433.92',
        one              => [3,-1],
        zero             => [1,-3],
        #float            => [-1,3],     # not full supported now later use
        sync             => [1,-31],
        clockabs         => -1,
        format           => 'twostate',  # not used now
        preamble         => 'i',
        clientmodule     => 'IT',
        modulematch      => '^i......',
        length_min       => '24',
        length_max       => '24',        # Don't know maximal lenth of a valid message
      },
    "3.1"  =>  ## itv1_sync40 | Intertek Modell 1946518 | ELRO
               # no decode!  MS;P0=-11440;P1=-1121;P2=-416;P5=309;P6=1017;D=150516251515162516251625162516251515151516251625151;CP=5;SP=0;R=66;
               # on | v1     MS;P1=309;P2=-1130;P3=1011;P4=-429;P5=-11466;D=15123412121234123412141214121412141212123412341234;CP=1;SP=5;R=38;  Gruppentaste, siehe Kommentar in sub SIGNALduino_bit2itv1
               # need more Device Infos / User Message
      {
        name             => 'itv1_sync40',
        comment          => 'IT remote control PAR 1000, ITS-150, AB440R',
        id               => '3',
        knownFreqs       => '433.92',
        one              => [3.5,-1],
        zero             => [1,-3.8],
        float            => [1,-1],       # fuer Gruppentaste (nur bei ITS-150,ITR-3500 und ITR-300), siehe Kommentar in sub SIGNALduino_bit2itv1
        sync             => [1,-44],
        clockabs         => -1,
        format           => 'twostate',   # not used now
        preamble         => 'i',
        clientmodule     => 'IT',
        modulematch      => '^i......',
        length_min       => '24',
        length_max       => '24',         # Don't know maximal lenth of a valid message
        postDemodulation => \&lib::SD_Protocols::Convbit2itv1,
      },
    "4"  => ## arctech2
            # need more Device Infos / User Message
      {
        name             => 'arctech2',
        id               => '4',
        knownFreqs       => '',
        #one              => [1,-5,1,-1],
        #zero             => [1,-1,1,-5],
        one              => [1,-5],
        zero             => [1,-1],
        #float            => [-1,3],     # not full supported now, for later use
        sync             => [1,-14],
        clockabs         => -1,
        format           => 'twostate',  # tristate can't be migrated from bin into hex!
        preamble         => 'i',
        postamble        => '00',
        clientmodule     => 'IT',
        modulematch      => '^i......',
        length_min       => '39',
        length_max       => '44',        # Don't know maximal lenth of a valid message
      },
    "5"  => # Unitec, Modellnummer 6899/45108
            # https://github.com/RFD-FHEM/RFFHEM/pull/389#discussion_r237232347 @sidey79 | https://github.com/RFD-FHEM/RFFHEM/pull/389#discussion_r237245943
            # no decode!   MU;P0=-31960;P1=660;P2=401;P3=-1749;P5=276;D=232353232323232323232323232353535353232323535353535353535353535010;CP=5;R=38;
            # no decode!   MU;P0=-1757;P1=124;P2=218;P3=282;P5=-31972;P6=644;P7=-9624;D=010201020303030202030303020303030202020202020203030303035670;CP=2;R=32;
            # no decode!   MU;P0=-1850;P1=172;P3=-136;P5=468;P6=236;D=010101010101310506010101010101010101010101010101010101010;CP=1;R=30;
            # A AN         MU;P0=132;P1=-4680;P2=508;P3=-1775;P4=287;P6=192;D=123434343434343634343436363434343636343434363634343036363434343;CP=4;R=2;
            # A AUS        MU;P0=-1692;P1=132;P2=194;P4=355;P5=474;P7=-31892;D=010202040505050505050404040404040404040470;CP=4;R=27;
      {
        name             => 'Unitec',
        comment          => 'remote control model 6899/45108',
        id               => '5',
        knownFreqs       => '',
        one              => [3,-1],      # ?
        zero             => [1,-3],      # ?
        clockabs         => 500,         # ?
        developId        => 'y',
        format           => 'twostate',
        preamble         => 'u5#',
        #clientmodule     => '',
        #modulematch      => '',
        length_min       => '24',        # ?
        length_max       => '24',        # ?
      },
    "6"  => ## TCM 218943, Eurochron
            # https://github.com/RFD-FHEM/RFFHEM/issues/692 @ Ralf9 2019-11-15
            # T:22.9, H:24     MS;P0=-970;P1=254;P3=-1983;P4=-8045;D=14101310131010101310101010101010101010101313101010101010101313131010131013;CP=1;SP=4;
            # T:22.7, H:23, tx MS;P0=-2054;P1=236;P2=-1032;P3=-7760;D=13121012101212121012121210121212121212121012101010121212121010101212121010;CP=1;SP=3;
      {
        name             => 'TCM 218943',
        comment          => 'Weatherstation TCM 218943, Eurochron',
        id               => '6',
        knownFreqs       => '433.92',
        one              => [1,-5],
        zero             => [1,-10],
        sync             => [1,-32],
        clockabs         => 248,
        format           => 'twostate',
        preamble         => 's',
        postamble        => '00',
        clientmodule     => 'CUL_TCM97001',
        length_min       => '36',            # sync, postamble und paddingbits werden nicht mitgezaehlt
        length_max       => '36',            # sync, postamble und paddingbits werden nicht mitgezaehlt
        paddingbits      => '8',             # pad up to 8 bits, default is 4
      },
    "7"  => ## weather sensors like EAS800z
            # Ch:1 T: 19.8 H: 11 Bat:low   MS;P1=-3882;P2=504;P3=-957;P4=-1949;D=21232424232323242423232323232323232424232323242423242424242323232324232424;CP=2;SP=1;R=249;m=2;
            # https://forum.fhem.de/index.php/topic,101682.0.html (Auriol AFW 2 A1, IAN: 297514)
            # Ch:1 T: 28.2 H: 44 Bat:ok    MS;P0=494;P1=-1949;P2=-967;P3=-3901;D=03010201010202020101020202020202010202020101020102010201020202010201010202;CP=0;SP=3;R=37;m0;
            # Ch:1 T: 24.4 H: 56 Bat:ok    MS;P1=-1940;P2=495;P3=-957;P4=-3878;D=24212321212323232121232323232323232121212123212323212321232323212121232323;CP=2;SP=4;R=20;O;m1;
      {
        name             => 'Weather',
        comment          => 'EAS800z, FreeTec NC-7344, HAMA TS34A, Auriol AFW 2 A1',
        id               => '7',
        knownFreqs       => '433.92',
        one              => [1,-4],
        zero             => [1,-2],
        sync             => [1,-8],
        clockabs         => 484,
        format           => 'twostate',
        preamble         => 'P7#',
        clientmodule     => 'SD_WS07',
        modulematch      => '^P7#.{6}[AFaf].{2}',
        length_min       => '35',
        length_max       => '40',
      },
    "7.1" => ## Mebus Modell Number HQ7312-2
             # https://github.com/RFD-FHEM/RFFHEM/issues/1024 @ rpsVerni 2021-10-06
             # Ch:3 T: 23.8 H: 11 Bat:ok    MS;P0=332;P1=-1114;P2=-2106;P3=-4055;D=03010201010202010202010201010101010202020102020201020202020101010102010202;CP=0;SP=3;R=56;m0;
             # Ch:3 T: 24.5 H: 10 Bat:ok    MS;P0=-2128;P1=320;P5=-1159;P6=-4084;D=16151015151010151010151015151515151010101015101510101010101515151510151015;CP=1;SP=6;R=66;O;m2;
             # Ch:3 T: 25.3 H: 11 Bat:ok    MS;P1=303;P4=-1153;P5=-2138;P6=-4102;D=16141514141515141515141514141414141515151515151415151515151414141415141515;CP=1;SP=6;R=50;O;m2;
      {
        name             => 'Weather',
        comment          => 'Mebus HQ7312-2',
        id               => '7.1',
        knownFreqs       => '433.92',
        one              => [1,-7],  # 300,-2100
        zero             => [1,-4],  # 300,-1200
        sync             => [1,-14], # 300,-4200
        clockabs         => 300,
        format           => 'twostate',
        preamble         => 'P7#',
        clientmodule     => 'SD_WS07',
        modulematch      => '^P7#.{6}[AFaf].{2}',
        length_min       => '36',
        length_max       => '36',
      },
    "8"  => ## TX3 (ITTX) Protocol
            # Id:97 T: 24.4   MU;P0=-1046;P1=1339;P2=524;P3=-28696;D=010201010101010202010101010202010202020102010101020101010202020102010101010202310101010201020101010101020201010101020201020202010201010102010101020202010201010101020;CP=2;R=4;
      {
        name             => 'TX3 Protocol',
        id               => '8',
        knownFreqs       => '',
        one              => [1,-2],
        zero             => [2,-2],
        #sync             => [1,-8],
        clockabs         => 470,
        format           => 'pwm',
        preamble         => 'TX',
        clientmodule     => 'CUL_TX',
        modulematch      => '^TX......',
        length_min       => '43',
        length_max       => '44',
        remove_zero      => 1,            # Removes leading zeros from output
      },
    "9"  => ## Funk Wetterstation CTW600
            ### ! some message are decode as protocol 42 and 75 !
            ## WH3080 | UV: 4 Lux: 57970 | @Ralf
            # MU;P0=-1424;P1=1417;P2=-1058;P3=453;P4=-24774;P6=288;P7=-788;D=01212121232343232323232323232123232323232121232121212123212121232123212321232121212123212121232321232321212121232323212321212121212121212323467323232323232323212323232323212123212121212321212123212321232123212121212321212123232123232121212123232321232121;CP=3;R=247;O;
            ## WH1080
            # https://forum.fhem.de/index.php/topic,39451.msg844155.html#msg844155 | https://forum.fhem.de/index.php/topic,39451.msg848667.html#msg848667 @maddinthebrain
            # MU;P0=-31072;P1=486;P2=-986;P3=1454;D=01212121212121212321232321232123232121232323212121212123232123232123212321232123232323232321232323232323212323232323232323232123212121212321232323232323232323212321212321232301212121212121212321232321232123232121232323212121212123232123232123212321232123;CP=1;R=29;O;
            ## CTW600
            # https://forum.fhem.de/index.php/topic,39451.msg917042.html#msg917042 @greewoo
            # MU;P0=-96;P1=800;P2=-985;P3=485;P4=1421;P5=-8608;D=0123232323232323242324232324242324232324242324242324232323242324242323232324242424242424242424242424242424242424242424242424242424242424242424242424242424242324242424232323235;CP=4;R=0;
      {
        name             => 'weather',
        comment          => 'Weatherstation WH1080, WH3080, WH5300SE, CTW600',
        id               => '9',
        knownFreqs       => '433.92 | 868.35',
        zero             => [3,-2],
        one              => [1,-2],
        clockabs         => 480,          # -1 = auto undef=noclock
        format           => 'pwm',        # tristate can't be migrated from bin into hex!
        preamble         => 'P9#',
        clientmodule     => 'SD_WS09',
        #modulematch      => '^u9#.....',
        length_min       => '60',
        length_max       => '120',
        reconstructBit   => '1',
      },
    "10"  =>  ## Oregon Scientific 2
              # https://forum.fhem.de/index.php/topic,60170.msg875919.html#msg875919 @David1
              # MC;LL=-973;LH=984;SL=-478;SH=493;D=EF7E2DCC00000283AF5DF7CFEFEF7E2DCC;C=487;L=134;R=33;s5;b0;
              # MC;LL=-975;LH=976;SL=-491;SH=491;D=BEF9FDFDEFC5B98000005075EBBEF9FDFDEFC5;C=488;L=152;R=34;s1;b0;O;w;
      {
        name             => 'Oregon Scientific v2|v3',
        comment          => 'temperature / humidity or other sensors',
        id               => '10',
        knownFreqs       => '',
        clockrange       => [300,520],             # min , max
        format           => 'manchester',          # tristate can't be migrated from bin into hex!
        clientmodule     => 'OREGON',
        modulematch      => '^(3[8-9A-F]|[4-6][0-9A-F]|7[0-8]).*',
        length_min       => '64',
        length_max       => '220',
        method           => \&lib::SD_Protocols::mcBit2OSV2o3,  # Call to process this message
        polarity         => 'invert',
      },
    "11"  =>  ## Arduino Sensor
      {
        name             => 'Arduino',
        comment          => 'for Arduino based sensors',
        id               => '11',
        knownFreqs       => '',
        clockrange       => [380,425],            # min , max
        format           => 'manchester',         # tristate can't be migrated from bin into hex!
        preamble         => 'P2#',
        clientmodule     => 'SD_AS',
        modulematch      => '^P2#.{7,8}',
        length_min       => '52',
        length_max       => '56',
        method           => \&lib::SD_Protocols::mcBit2AS  # Call to process this message
      },
    "12"  =>  ## Hideki
              # Id:31 Ch:1 T: 22.7 Bat:ok   MC;LL=-1040;LH=904;SL=-542;SH=426;D=A8C233B53A3E0A0783;C=485;L=72;R=213;
      {
        name             => 'Hideki',
        comment          => 'temperature / humidity or other sensors',
        id               => '12',
        knownFreqs       => '433.92',
        clockrange       => [420,510],              # min, max better for Bresser Sensors, OK for hideki/Hideki/TFA too
        format           => 'manchester',
        preamble         => 'P12#',
        clientmodule     => 'Hideki',
        modulematch      => '^P12#75.+',
        length_min       => '71',
        length_max       => '128',
        method           => \&lib::SD_Protocols::mcBit2Hideki,  # Call to process this message
        #polarity         => 'invert',
      },
    "13"  =>  ## FLAMINGO FA21
              # https://github.com/RFD-FHEM/RFFHEM/issues/21 @sidey79
              # https://github.com/RFD-FHEM/RFFHEM/issues/233
              # 32E44F | Alarm   MS;P0=-1413;P1=757;P2=-2779;P3=-16079;P4=8093;P5=-954;D=1345121210101212101210101012121012121210121210101010;CP=1;SP=3;R=33;O;
      {
        name             => 'FLAMINGO FA21',
        comment          => 'FLAMINGO FA21 smoke detector (message decode as MS)',
        id               => '13',
        knownFreqs       => '433.92',
        one              => [1,-2],
        zero             => [1,-4],
        sync             => [1,-20,10,-1],
        clockabs         => 800,
        format           => 'twostate',
        preamble         => 'P13#',
        clientmodule     => 'FLAMINGO',
        #modulematch      => 'P13#.*',
        length_min       => '24',
        length_max       => '26',
      },
    "13.1"  =>  ## FLAMINGO FA20RF
                # B67C3B | Alarm   MU;P0=-1384;P1=815;P2=-2725;P3=-20001;P4=8159;P5=-891;D=01010121212121010101210101345101210101210101212101010101012121212101010121010134510121010121010121210101010101212121210101012101013451012101012101012121010101010121212121010101210101345101210101210101212101010101012121212101010121010134510121010121010121;CP=1;O;
                # 1B61BB | Alarm   MU;P0=-17201;P1=112;P2=-1419;P3=-28056;P4=8092;P5=-942;P6=777;P7=-2755;D=12134567676762626762626762626767676762626762626267626260456767676262676262676262676767676262676262626762626045676767626267626267626267676767626267626262676262604567676762626762626762626767676762626762626267626260456767676262676262676262676767676262676262;CP=6;O;
                ## FLAMINGO FA22RF (only MU Message) @HomeAutoUser
                # CBFAD2 | Alarm   MU;P0=-5684;P1=8149;P2=-887;P3=798;P4=-1393;P5=-2746;P6=-19956;D=0123434353534353434343434343435343534343534353534353612343435353435343434343434343534353434353435353435361234343535343534343434343434353435343435343535343536123434353534353434343434343435343534343534353534353612343435353435343434343434343534353434353435;CP=3;R=0;
                # Times measured
                # Sync 8100 microSec, 900 microSec | Bit1 2700 microSec low - 800 microSec high | Bit0 1400 microSec low - 800 microSec high | Pause Repeat 20000 microSec | 1 Sync + 24Bit, Totaltime 65550 microSec without Sync
      {
        name             => 'FLAMINGO FA22RF / FA21RF / LM-101LD',
        comment          => 'FLAMINGO | Unitec smoke detector (message decode as MU)',
        id               => '13.1',
        knownFreqs       => '433.92',
        one              => [1,-1.8],
        zero             => [1,-3.5],
        start            => [10,-1],
        pause            => [-25],
        clockabs         => 800,
        format           => 'twostate',
        preamble         => 'P13.1#',
        clientmodule     => 'FLAMINGO',
        #modulematch      => '^P13\.?1?#[A-Fa-f0-9]+',
        length_min       => '24',
        length_max       => '24',
      },
    "13.2"  =>  ## LM-101LD Rauchmelder
                # https://github.com/RFD-FHEM/RFFHEM/issues/233 @Ralf9
                # B0FFAF | Alarm   MS;P1=-2708;P2=796;P3=-1387;P4=-8477;P5=8136;P6=-904;D=2456212321212323232321212121212121212123212321212121;CP=2;SP=4;
      {
        name             => 'LM-101LD',
        comment          => 'Unitec smoke detector (message decode as MS)',
        id               => '13',
        knownFreqs       => '433.92',
        zero             => [1,-1.8],
        one              => [1,-3.5],
        sync             => [1,-11,10,-1.2],
        clockabs         => 790,
        format           => 'twostate',
        preamble         => 'P13#',
        clientmodule     => 'FLAMINGO',
        length_min       => '24',
        length_max       => '24',
      },
    "14"  =>  ## LED X-MAS Chilitec model 22640
              # https://github.com/RFD-FHEM/RFFHEM/issues/421 | https://forum.fhem.de/index.php/topic,94211.msg869214.html#msg869214 @privat58
              # power_on          MS;P0=988;P1=-384;P2=346;P3=-1026;P4=-4923;D=240123012301230123012323232323232301232323;CP=2;SP=4;R=0;O;m=1;
              # brightness_plus   MS;P0=-398;P1=974;P3=338;P4=-1034;P6=-4939;D=361034103410341034103434343434343410103434;CP=3;SP=6;R=0;
      {
        name             => 'LED X-MAS',
        comment          => 'Chilitec model 22640',
        id               => '14',
        knownFreqs       => '433.92',
        one              => [3,-1],
        zero             => [1,-3],
        sync             => [1,-14],
        clockabs         => 350,
        format           => 'twostate',
        preamble         => 'P14#',
        clientmodule     => 'SD_UT',
        #modulematch      => '^P14#.*',
        length_min       => '20',
        length_max       => '20',
      },
    "15"  =>  ## TCM 234759
      {
        name             => 'TCM 234759 Bell',
        comment          => 'wireless doorbell TCM 234759 Tchibo',
        id               => '15',
        knownFreqs       => '',
        one              => [1,-1],
        zero             => [1,-2],
        sync             => [1,-45],
        clockabs         => 700,
        format           => 'twostate',
        preamble         => 'P15#',
        clientmodule     => 'SD_BELL',
        modulematch      => '^P15#.*',
        length_min       => '10',
        length_max       => '20',
      },
    "16"  =>  ## Rohrmotor24 und andere Funk Rolladen / Markisen Motoren
              # ! same definition how ID 72 !
              # https://forum.fhem.de/index.php/topic,49523.0.html
              # closed   MU;P0=-1608;P1=-785;P2=288;P3=650;P4=-419;P5=4676;D=1212121213434212134213434212121343434212121213421213434212134345021213434213434342121212121343421213421343421212134343421212121342121343421213432;CP=2;
              # closed   MU;P0=-1562;P1=-411;P2=297;P3=-773;P4=668;P5=4754;D=1232341234141234141234141414123414123232341232341412323414150234123234123232323232323234123414123414123414141412341412323234123234141232341415023412323412323232323232323412341412341412341414141234141232323412323414123234142;CP=2;
      {
        name             => 'Dooya',
        comment          => 'Rohrmotor24 and other radio shutters / awnings motors',
        id               => '16',
        knownFreqs       => '',
        one              => [2,-1],
        zero             => [1,-3],
        start            => [17,-5],
        clockabs         => 280,
        format           => 'twostate',
        preamble         => 'P16#',
        clientmodule     => 'Dooya',
        #modulematch      => '',
        length_min       => '39',
        length_max       => '40',
      },
    "17"  =>  ## arctech / intertechno
              # need more Device Infos / User Message
      {
        name             => 'arctech / Intertechno',
        id               => '17',
        knownFreqs       => '433.92',
        one              => [1,-5,1,-1],
        zero             => [1,-1,1,-5],
        #one              => [1,-5],
        #zero             => [1,-1],
        sync             => [1,-10],
        float            => [1,-1,1,-1],
        end              => [1,-40],
        clockabs         => -1,          # -1 = auto
        format           => 'twostate',  # tristate can't be migrated from bin into hex!
        preamble         => 'i',
        postamble        => '00',
        clientmodule     => 'IT',
        modulematch      => '^i......',
        length_min       => '32',
        length_max       => '34',        # Don't know maximal lenth of a valid message
        postDemodulation => \&lib::SD_Protocols::Convbit2Arctec,
      },
    "17.1"  =>  ## intertechno --> MU anstatt sonst MS (ID 17)
                # no decode!   MU;P0=344;P1=-1230;P2=-200;D=01020201020101020102020102010102010201020102010201020201020102010201020101020102020102010201020102010201010200;CP=0;R=0;
                # no decode!   MU;P0=346;P1=-1227;P2=-190;P4=-10224;P5=-2580;D=0102010102020101020201020101020102020102010102010201020102010201020201020102010201020101020102020102010102020102010201020104050201020102010102020101020201020101020102020102010102010201020102010201020201020102010201020101020102020102010102020102010201020;CP=0;R=0;
                # no decode!   MU;P0=351;P1=-1220;P2=-185;D=01 0201 0102 020101020201020101020102020102010102010201020102010201020201020102010201020101020102020102010201020102010201020100;CP=0;R=0;
                # off | v3     MU;P0=355;P1=-189;P2=-1222;P3=-10252;P4=-2604;D=01020201010201020201020101020102020102010201020102010201010201020102010201020201020101020102010201020102010201020 304 0102 01020102020101020201010201020201020101020102020102010201020102010201010201020102010201020201020101020102010201020102010201020 304 01020;CP=0;R=0;
                # https://www.sweetpi.de/blog/329/ein-ueberblick-ueber-433mhz-funksteckdosen-und-deren-protokolle
      {
        name             => 'Intertechno',
        comment          => 'PIR-1000 | ITT-1500',
        id               => '17.1',
        knownFreqs       => '433.92',
        one              => [1,-5,1,-1],
        zero             => [1,-1,1,-5],
        clockabs         => 230,         # -1 = auto
        format           => 'twostate',  # tristate can't be migrated from bin into hex!
        preamble         => 'i',
        postamble        => '00',
        clientmodule     => 'IT',
        modulematch      => '^i......',
        length_min       => '32',
        length_max       => '34',        # Don't know maximal lenth of a valid message
        postDemodulation => \&lib::SD_Protocols::Convbit2Arctec,
      },
    "18"  =>  ## Oregon Scientific v1
              # Id:3 T: 7.5 BAT:ok   MC;LL=-2721;LH=3139;SL=-1246;SH=1677;D=1A51FF47;C=1463;L=32;R=12;
      {
        name            => 'Oregon Scientific v1',
        comment         => 'temperature / humidity or other sensors',
        id              => '18',
        knownFreqs      => '433.92',
        clockrange      => [1400,1500],          # min , max
        format          => 'manchester',         # tristate can't be migrated from bin into hex!
        preamble        => '',
        clientmodule    => 'OREGON',
        modulematch     => '^[0-9A-F].*',
        length_min      => '32',
        length_max      => '32',
        polarity        => 'invert',
        method          => \&lib::SD_Protocols::mcBit2OSV1  # Call to process this message
      },
    "19"  =>  ## minify Funksteckdose
              # https://github.com/RFD-FHEM/RFFHEM/issues/114 @zag-o-mat
              # u19#E2CA7C   MU;P0=293;P1=-887;P2=-312;P6=-1900;P7=872;D=6727272010101720172720101720172010172727272720;CP=0;
              # u19#E2CA7C   MU;P0=9078;P1=-308;P2=180;P3=-835;P4=881;P5=309;P6=-1316;D=0123414141535353415341415353415341535341414141415603;CP=5;
      {
        name            => 'minify',
        comment         => 'remote control RC202',
        id              => '19',
        knownFreqs      => '',
        one             => [3,-1],
        zero            => [1,-3],
        clockabs        => 300,
        format          => 'twostate',
        preamble        => 'u19#',
        #clientmodule    => '',
        #modulematch     => '',
        length_min      => '19',
        length_max      => '23',        # not confirmed, length one more as MU Message
      },
    "20"  =>  ## Remote control with 4 buttons for diesel heating
              # https://forum.fhem.de/index.php/topic,58397.msg999475.html#msg999475 @ fhem_user0815 2019-12-04
              # RCnoName20_17E9 on     MS;P0=-740;P2=686;P3=-283;P5=229;P6=-7889;D=5650505023502323232323235023505023505050235050502323502323505050;CP=5;SP=6;R=67;O;m2;
              # RCnoName20_17E9 off    MS;P1=-754;P2=213;P4=681;P5=-283;P6=-7869;D=2621212145214545454545452145212145212121212145214521212121452121;CP=2;SP=6;R=69;O;m2;
              # RCnoName20_17E9 plus   MS;P1=-744;P2=221;P3=679;P4=-278;P5=-7860;D=2521212134213434343434342134212134212121213421212134343434212121;CP=2;SP=5;R=66;O;m2;
              # RCnoName20_17E9 minus  MS;P0=233;P1=-7903;P3=-278;P5=-738;P6=679;D=0105050563056363636363630563050563050505050505630563050505630505;CP=0;SP=1;R=71;O;m1;
              ## Remote control DC-1961-TG with 12 buttons for ceiling fan with lighting
              # https://forum.fhem.de/index.php/topic,53282.msg1240911.html#msg1240911 @ Skusi  2022-10-23
              # DC_1961_TG_1846 light_on_off   MS;P1=291;P2=-753;P3=762;P4=-249;P5=-8312;D=151212123434121212123412121234341234123412341212121234341212341234;CP=1;SP=5;R=224;O;m2;
              # DC_1961_TG_1846 fan_off        MS;P1=-760;P2=747;P3=-282;P4=253;P5=-8335;D=454141412323414141412341414123234123412341412323234123232323412323;CP=4;SP=5;R=27;O;m2;
              # DC_1961_TG_1846 fan_direction  MS;P0=-8384;P1=255;P2=-766;P3=754;P4=-263;D=101212123434121212123412121234341234123412341212341234341212341212;CP=1;SP=0;R=27;O;m2;
              ## Remote control with 9 buttons for ceiling fan with lighting (Controller MP 2.5+3UF)
              # https://forum.fhem.de/index.php?topic=138538.0 @ Butsch 2024-06-17
              # RCnoName20_09_024F fan_low   MS;P0=249;P1=-744;P3=770;P4=-228;P5=-8026;D=050101010101013401013401013434343401010101010134010101010101010134;CP=0;SP=5;R=35;O;m2;
              # RCnoName20_09_024F fan_stop  MS;P0=-7940;P1=246;P2=-757;P3=736;P4=-247;D=101212121212123412123412123434343412121212123434121212343412343412;CP=1;SP=0;R=47;O;m2;
              ## Remote control CREATE 6601L with 14 buttons for ceiling fan with lighting
              # https://forum.fhem.de/index.php?topic=53282.msg1316246#msg1316246 @ Kent 2024-07-04
              # CREATE_6601L_1B90 fan_2  MS;P0=-7944;P1=-740;P4=253;P6=732;P7=-256;D=404141416767416767674141674141414141414141674141414141674141416767;CP=4;SP=0;R=67;O;m2;
              # CREATE_6601L_1B90 fan_5  MS;P0=-264;P2=-743;P3=254;P4=733;P5=-7942;D=353232324040324040403232403232323232323232324032324032323232403240;CP=3;SP=5;R=40;O;m2;
      {
        name            => 'RCnoName20',
        comment         => 'Remote control with 4, 9, 10, 12 or 14 buttons',
        id              => '20',
        knownFreqs      => '433.92',
        one             => [3,-1],  # 720,-240
        zero            => [1,-3],  # 240,-720
        sync            => [1,-33], # 240,-7920
        clockabs        => 240,
        format          => 'twostate',
        preamble        => 'P20#',
        clientmodule    => 'SD_UT',
        modulematch     => '^P20#.{8}',
        length_min      => '31',
        length_max      => '32',
      },
    "20.1" => ## Remote control with 10 buttons for fan (messages mostly recognized as MS, sometimes MU)
              # https://forum.fhem.de/index.php/topic,53282.msg1233431.html#msg1233431 @ steffen83 2022-09-01
              # RCnoName20_10_3E00 light_on   MU;P0=-8774;P1=282;P2=-775;P3=815;P4=-253;P5=-32001;D=10121234343434341212121212121212121212123434343412121234343412343415;CP=1;
              # RCnoName20_10_3E00 light_off  MU;P0=-238;P1=831;P3=300;P4=-762;P5=-363;P6=192;P7=-8668;D=01010101010343434343434343434343434103415156464156464641564646734341010101010343434343434343434343434103410103434103434341034343734341010101010343434343434343434343434103410103434103434341034343734341010101010343434343434343434343434103410103434103434341;CP=3;O;
              # RCnoName20_10_3E00 fan_stop   MU;P0=184;P1=-380;P2=128;P3=-9090;P4=-768;P5=828;P6=-238;P7=298;D=45656565656747474747474747474747474567474560404515124040451040374745656565656747474747474747474747474567474567474565674747456747374745656565656747474747474747474747474567474567474565674747456747374745656565656747474747474747474747474567474567474565674747;CP=7;O;
      {
        name         => 'RCnoName20',
        comment      => 'Remote control with 4, 9, 10, 12 or 14 buttons',
        id           => '20.1',
        knownFreqs   => '433.92',
        one          => [3,-1],  # 720,-240
        zero         => [1,-3],  # 240,-720
        start        => [1,-33], # 240,-7920
        clockabs     => 240,
        format       => 'twostate',
        preamble     => 'P20#',
        clientmodule => 'SD_UT',
        modulematch  => '^P20#.{8}',
        length_min   => '31',
        length_max   => '32',
      },
    "21"  =>  ## Einhell Garagentor
              # https://forum.fhem.de/index.php?topic=42373.0 @Ellert | user have no RAWMSG
              # static adress: Bit 1-28 | channel remote Bit 29-32 | repeats 31 | pause 20 ms
              # Channelvalues dez
              # 1 left 1x kurz | 2 left 2x kurz | 3 left 3x kurz | 5 right 1x kurz | 6 right 2x kurz | 7 right 3x kurz ... gedrückt
      {
        name            => 'Einhell Garagedoor',
        comment         => 'remote control ISC HS 434/6',
        id              => '21',
        knownFreqs      => '433.92',
        one             => [-3,1],
        zero            => [-1,3],
        #sync            => [-50,1],
        start           => [-50,1],
        clockabs        => 400,        #ca 400us
        format          => 'twostate',
        preamble        => 'u21#',
        #clientmodule    => '',
        #modulematch     => '',
        length_min      => '32',
        length_max      => '32',
        paddingbits     => '1',        # This will disable padding
      },
    "22"  =>  ## HAMULiGHT remote control for LED transformer (for AB sets)
              # https://forum.fhem.de/index.php?topic=89301.0 @ Michi240281 10 Juli 2018| https://forum.fhem.de/index.php/topic,89643.msg822289.html#msg822289 @ Michi240281 28 Juli 2018
              # remote with one button for toggle on/off
              # u22#8F995F34   MU;P0=-196;P1=32001;P3=214;P4=1192;P5=-1200;P6=-595;P7=597;D=0103030453670707036363636367070363670703670367036363636367070363670367070303030304536707070363636363670703636707036703670363636363670703636703670703030303045367070703636363636707036367070367036703636363636707036367036707030303030453670707036363636367070;CP=3;R=15;
              # u22#8F995F34 -> P22#8F995F34 Hamulight_AB_8F99 on_off
              # https://github.com/RFD-FHEM/RFFHEM/issues/1206 @ obduser 2023-12-09
              # remote control with five buttons and touch control for dim
              # P22#36055F47 Hamulight_AB_3605 on_off   MU;P0=-16360;P1=144;P2=-191;P3=209;P4=1194;P5=-1203;P6=607;P7=-591;D=01232324562623737623737626262626262376237623762373737373762376262623737373232323245626237376237376262626262623762376237623737373737623762626237373732323232456262373762373762626262626237623762376237373737376237626262373737323232324562623737623737626262626;CP=3;R=5;O;
              # P22#36055F47 Hamulight_AB_3605 dim_1    MU;P0=-14008;P1=136;P2=-199;P3=210;P4=1200;P5=-1200;P6=596;P7=-591;D=01232324562623737623737626262626262376237623762376237623762623737373762373232323245626237376237376262626262623762376237623762376237626237373737623732323232456262373762373762626262626237623762376237623762376262373737376237323232324562623737623737626262626;CP=3;R=6;O;
              # P22#36055F47 Hamulight_AB_3605 dim_4    MU;P0=-16204;P1=120;P2=-204;P3=204;P4=1192;P5=-1208;P6=593;P7=-592;D=01232324562623737623737626262626262376237623762373762623762376262626262373232323245626237376237376262626262623762376237623737626237623762626262623732323232456262373762373762626262626237623762376237376262376237626262626237323232324562623737623737626262626;CP=3;R=5;O;
      {
        name            => 'HAMULiGHT',
        comment         => 'Remote control for LED transformer',
        id              => '22',
        knownFreqs      => '433.92',
        one             => [1,-3],
        zero            => [3,-1],
        start           => [1,-1,1,-1,6,-6],
        end             => [1,-1,1,-1],
        clockabs        => 200,
        format          => 'twostate',
        preamble        => 'P22#',
        clientmodule    => 'SD_UT',
        modulematch     => '^P22#',
        length_min      => '32',
        length_max      => '32',
      },
    "23"  =>  ## Pearl Sensor
      {
        name            => 'Pearl',
        comment         => 'unknown sensortyp',
        id              => '23',
        knownFreqs      => '',
        one             => [1,-6],
        zero            => [1,-1],
        sync            => [1,-50],
        clockabs        => 200,          #ca 200us
        format          => 'twostate',
        preamble        => 'u23#',
        #clientmodule    => '',
        #modulematch     => '',
        length_min      => '36',
        length_max      => '44',
      },
    "24"  =>  ## visivo
              # https://github.com/RFD-FHEM/RFFHEM/issues/39 @sidey79
              # Visivo_7DF825 up    MU;P0=132;P1=500;P2=-233;P3=-598;P4=-980;P5=4526;D=012120303030303120303030453120303121212121203121212121203121212121212030303030312030312031203030303030312031203031212120303030303120303030453120303121212121203121212121203121212121212030303030312030312031203030303030312031203031212120303030;CP=0;O;
              # https://forum.fhem.de/index.php/topic,42273.0.html @MikeRoxx
              # Visivo_7DF825 up    MU;P0=505;P1=140;P2=-771;P3=-225;P5=4558;D=012031212030303030312030303030312030303030303121212121203121203120312121212121203120312120303031212121212031212121252031212030303030312030303030312030303030303121212121203121203120312121212121203120312120303031212121212031212121252031212030;CP=1;O;
              # Visivo_7DF825 down  MU;P0=147;P1=-220;P2=512;P3=-774;P5=4548;D=001210303210303212121210303030321030303035321030321212121210321212121210321212121212103030303032103032103210303030303210303210303212121210303030321030303035321030321212121210321212121210321212121212103030303032103032103210303030303210303210;CP=0;O;
              # Visivo_7DF825 stop  MU;P0=-764;P1=517;P2=-216;P3=148;P5=4550;D=012303012121212123012121212123012121212121230303030301230301230123030303012303030123012303030123030303012303030305012303012121212123012121212123012121212121230303030301230301230123030303012303030123012303030123030303012303030305012303012120;CP=3;O;
      {
        name            => 'Visivo remote',
        comment         => 'Remote control for motorized screen',
        id              => '24',
        knownFreqs      => '315',
        one             => [3,-1],  #  546,-182
        zero            => [1,-4],  #  182,-728
        start           => [25,-4], # 4550,-728
        clockabs        => 182,
        reconstructBit  => '1',
        format          => 'twostate',
        preamble        => 'P24#',
        clientmodule    => 'SD_UT',
        modulematch     => '^P24#',
        length_min      => '55',
        length_max      => '56',
      },
    "25"  =>  ## LES remote for led lamp
              # https://github.com/RFD-FHEM/RFFHEM/issues/40 @sidey79
              # u25#45A06B   MS;P0=-376;P1=697;P2=-726;P3=322;P4=-13188;P5=-15982;D=3530123010101230123230123010101010101232301230123234301230101012301232301230101010101012323012301232;CP=3;SP=5;O;
      {
        name            => 'les led remote',
        id              => '25',
        knownFreqs      => '',
        one             => [-2,1],
        zero            => [-1,2],
        sync            => [-46,1],      # this is a end marker, but we use this as a start marker
        clockabs        => 350,          #ca 350us
        format          => 'twostate',
        preamble        => 'u25#',
        #clientmodule    => '',
        #modulematch     => '',
        length_min      => '24',
        length_max      => '50',         # message has only 24 bit, but we get more than one message, calculation has to be corrected
      },
    "26"  =>  ## xavax 00111939 Funksteckdosen Set
              # https://github.com/RFD-FHEM/RFFHEM/issues/717 @codeartisan-de 2019-12-14
              # xavax_DAAB2554 Ch1_on   MU;P0=412;P1=-534;P2=-1356;P3=-20601;P4=3360;P5=-3470;D=01020102010201020201010201010201020102010201020101020101010102020203010145020201020201020102010201020102020101020101020102010201020102010102010101010202020301014502020102020102010201020102010202010102010102010201020102010201010201010101020202030101450202;CP=0;R=0;O;
              # xavax_DAAB2554 Ch1_off  MU;P0=-3504;P1=416;P2=-1356;P3=-535;P4=-20816;P5=3324;D=01212131212131213121312131213121213131213131213121312131213121313131212121213131314131350121213121213121312131213121312121313121313121312131213121312131313121212121313131413135012121312121312131213121312131212131312131312131213121312131213131312121212131;CP=1;R=50;O;
              # xavax_DAAB2554 Ch2_on   MU;P0=5656;P1=-21857;P2=413;P3=-1354;P4=-536;P6=3350;P7=-3487;D=01232423232424232424232423242324232423242424232424232423232124246723232423232423242324232423242323242423242423242324232423242324242423242423242323212424672323242323242324232423242324232324242324242324232423242324232424242324242324232321242467232324232324;CP=2;R=0;O;
              # xavax_DAAB2554 Ch2_off  MU;P0=3371;P1=-3479;P2=420;P3=-31868;P4=-541;P5=272;P6=-1343;P7=-20621;D=23245426242426242624262426242624242624262624262424272424012626242626242624262426242624262624242624242624262426242624262424262426262426242427242401262624262624262426242624262426262424262424262426242624262426242426242626242624242724240126262426262426242624;CP=2;R=45;O;
      {
        name            => 'xavax',
        comment         => 'Remote control xavax 00111939',
        id              => '26',
        knownFreqs      => '433.92',
        one             => [1,-3],            # 460,-1380
        zero            => [1,-1],            # 460,-460
        start           => [1,-1,1,-1,7,-7],  # 460,-460,460,-460,3220,-3220
        # end            => [1],              # 460 - end funktioniert nicht (wird erst nach pause angehangen), ein bit ans Ende haengen geht, dann aber pause 44 statt 45
        pause           => [-44],             # -20700 mit end, 20240 mit bit 0 am Ende
        clockabs        => 460,
        format          => 'twostate',
        preamble        => 'P26#',
        clientmodule    => 'SD_UT',
        modulematch     => '^P26#.{10}',
        length_min      => '40',
        length_max      => '40',
      },
    "27"  =>  ## Temperatur-/Feuchtigkeitssensor EuroChron EFTH-800 (433 MHz) - https://github.com/RFD-FHEM/RFFHEM/issues/739
              # SD_WS_27_TH_2 - T: 15.5 H: 48 - MU;P0=-224;P1=258;P2=-487;P3=505;P4=-4884;P5=743;P6=-718;D=0121212301212303030301212123012123012123030123030121212121230121230121212121212121230301214565656561212123012121230121230303030121212301212301212303012303012121212123012123012121212121212123030121;CP=1;R=53;
              # SD_WS_27_TH_3 - T:  3.8 H: 76 - MU;P0=-241;P1=251;P2=-470;P3=500;P4=-4868;P5=743;P6=-718;D=012121212303030123012301212123012121212301212303012121212121230303012303012123030303012123014565656561212301212121230303012301230121212301212121230121230301212121212123030301230301212303030301212301;CP=1;R=23;
              # SD_WS_27_TH_3 - T:  5.3 H: 75 - MU;P0=-240;P1=253;P2=-487;P3=489;P4=-4860;P5=746;P6=-725;D=012121212303030123012301212123012121212303012301230121212121230303012301230303012303030301214565656561212301212121230303012301230121212301212121230301230123012121212123030301230123030301230303030121;CP=1;R=19;
              # Eurochron Zusatzsensor fuer EFS-3110A - https://github.com/RFD-FHEM/RFFHEM/issues/889
              # short pulse of 244 us followed by a 488 us gap is a 0 bit
              # long pulse of 488 us followed by a 244 us gap is a 1 bit
              # sync preamble of pulse, gap, 732 us each, repeated 4 times
              # sensor sends two messages at intervals of about 57-58 seconds
      {
        name            => 'EFTH-800',
        comment         => 'EuroChron weatherstation EFTH-800, EFS-3110A',
        id              => '27',
        knownFreqs      => '433.92',
        one             => [2,-1],
        zero            => [1,-2],
        start           => [3,-3,3,-3,3,-3,3,-3],
        clockabs        => '244',
        format          => 'twostate',
        preamble        => 'W27#',
        clientmodule    => 'SD_WS',
        modulematch     => '^W27#.{12}',
        length_min      => '48',  # 48 Bit + 1 Puls am Ende
        length_max      => '48',
      },
    "28"  =>  ## some remote code, send by aldi IC Ledspots
      {
        name            => 'IC Ledspot',
        id              => '28',
        knownFreqs      => '',
        one             => [1,-1],
        zero            => [1,-2],
        start           => [4,-5],
        clockabs        => 600,          #ca 600
        format          => 'twostate',
        preamble        => 'u28#',
        #clientmodule    => '',
        #modulematch     => '',
        length_min      => '8',
        length_max      => '8',
      },
    "29"  =>  ## example remote control with HT12E chip
              # fan_off   MU;P0=250;P1=-492;P2=166;P3=-255;P4=491;P5=-8588;D=052121212121234121212121234521212121212341212121212345212121212123412121212123452121212121234121212121234;CP=0;
              # https://forum.fhem.de/index.php/topic,58397.960.html
      {
        name            => 'HT12e',
        comment         => 'remote control for example Westinghouse airfan with 5 buttons',
        id              => '29',
        knownFreqs      => '',
        one             => [-2,1],
        zero            => [-1,2],
        start           => [-35,1],      # Message is not provided as MS, worakround is start
        clockabs        => 235,          # ca 220
        format          => 'twostate',   # there is a pause puls between words
        preamble        => 'P29#',
        clientmodule    => 'SD_UT',
        modulematch     => '^P29#.{3}',
        length_min      => '12',
        length_max      => '12',
      },
    "30"  =>  ## a unitec remote door reed switch
              # https://forum.fhem.de/index.php?topic=43346.0 @Dr.E.Witz
              # unknown   MU;P0=-10026;P1=-924;P2=309;P3=-688;P4=-361;P5=637;D=123245453245324532453245320232454532453245324532453202324545324532453245324532023245453245324532453245320232454532453245324532453202324545324532453245324532023245453245324532453245320232454532453245324532453202324545324532453245324532023240;CP=2;O;
              # unknown   MU;P0=307;P1=-10027;P2=-691;P3=-365;P4=635;D=0102034342034203420342034201020343420342034203420342010203434203420342034203420102034342034203420342034201020343420342034203420342010203434203420342034203420102034342034203420342034201;CP=0;
      {
        name            => 'diverse',
        comment         => 'remote control unitec | door reed switch 47031',
        id              => '30',
        knownFreqs      => '',
        one             => [-2,1],
        zero            => [-1,2],
        start           => [-30,1],     # Message is not provided as MS, worakround is start
        clockabs        => 330,         # ca 300 us
        format          => 'twostate',  # there is a pause puls between words
        preamble        => 'P30#',
        clientmodule    => 'SD_UT',
        modulematch     => '^P30#.{3}',
        length_min      => '12',
        length_max      => '12',        # message has only 10 bit but is paddet to 12
      },
    "31"  =>  ## LED Controller LTECH, LED M Serie RF RGBW - M4 & M4-5A
              # https://forum.fhem.de/index.php/topic,107868.msg1018434.html#msg1018434 | https://forum.fhem.de/index.php/topic,107868.msg1020521.html#msg1020521 @Devirex
              ## note: command length 299, now - not supported by all firmware versions
              # MU;P0=-16118;P1=315;P2=-281;P4=-1204;P5=-563;P6=618;P7=1204;D=01212121212121212121214151562151515151515151515621515621515626262156262626262626262626215626262626262626262626262626262151515151515151515151515151515151515151515151515626262626262626215151515151515156215156262626262626262626262621570121212121212121212121;CP=1;R=26;O;
              # MU;P0=-32001;P1=314;P2=-285;P3=-1224;P4=-573;P5=601;P6=1204;P7=-15304;CP=1;R=31;D=012121212121212121212131414521414141414141414145214145214145252521452525252525252525252145252525252525252525252525252521414141414141414141414141414141452141414141414145252525252525252141414141414141414525252141452525252525214145214671212121212121212121213141452;p;i;
      {
        name            => 'LTECH',
        comment         => 'remote control for LED Controller M4-5A',
        id              => '31',
        knownFreqs      => '433.92',
        one             => [1,-1.8],
        zero            => [2,-0.9],
        start           => [1,-0.9, 1,-0.9, 1,-3.8],
        preSync         => [1,-0.9, 1,-0.9, 1,-0.9, 1,-0.9, 1,-0.9, 1,-0.9, 1,-0.9, 1,-0.9],
        end             => [3.8, -51],
        clockabs        => 315,
        format          => 'twostate',
        preamble        => 'u31#',
      },
    "32"  =>  ## FreeTec PE-6946
              # ! some message are decode as protocol 40 and protocol 62 !
              # http://www.free-tec.de/Funkklingel-mit-Voic-PE-6946-919.shtml
              # OLD # https://github.com/RFD-FHEM/RFFHEM/issues/49
              # NEW # https://github.com/RFD-FHEM/RFFHEM/issues/315
              # P32#154FFF | ring   MU;P0=-6676;P1=578;P2=-278;P4=-680;P5=176;P6=-184;D=541654165412545412121212121212121212121250545454125412541254125454121212121212121212121212;CP=1;R=0;
              # P32#154FFF | ring   MU;P0=146;P1=245;P3=571;P4=-708;P5=-284;P7=-6689;D=14351435143514143535353535353535353535350704040435043504350435040435353535353535353535353507040404350435043504350404353535353535353535353535070404043504350435043504043535353535353535353535350704040435043504350435040435353535353535353535353507040404350435;CP=3;R=0;O;
              # P32#154FFF | ring   MU;P0=-6680;P1=162;P2=-298;P4=253;P5=-699;P6=555;D=45624562456245456262626262626262626262621015151562156215621562151562626262626262626262626210151515621562156215621515626262626262626262626262;CP=6;R=0;
              ## VLOXO Wireless Türklingel
              # https://github.com/RFD-FHEM/RFFHEM/issues/655 @schwatter
              # P32#7ED403 | ring   MU;P0=130;P1=-666;P2=533;P3=-273;P5=-6200;CP=0;R=15;D=01232301230123010101010101010123230501232323232323012323012301230101010101010101232305012323232323230123230123012301010101010101012323050123232323232301232301230123010101010101010123230501232323232323012323012301230101010101010101232305012323232323230123;O;
      {
        name            => 'wireless doorbell',
        comment         => 'FreeTec PE-6946 / VLOXO',
        id              => '32',
        knownFreqs      => '433.92',
        one             => [4,-2],
        zero            => [1,-5],
        start           => [1,-45],        # neuerdings MU Erknnung
        #sync            => [1,-49],       # old MS Erkennung
        clockabs        => 150,
        format          => 'twostate',
        preamble        => 'P32#',
        clientmodule    => 'SD_BELL',
        modulematch     => '^P32#.*',
        length_min      => '24',
        length_max      => '24',
      },
    "33"  =>  ## Thermo-/Hygrosensor S014, renkforce E0001PA, Conrad S522, TX-EZ6 (Weatherstation TZS First Austria)
              # https://forum.fhem.de/index.php?topic=35844.0 @BrainHunter
              # Id:62 Ch:1 T: 21.1 H: 76 Bat:ok   MS;P0=-7871;P2=-1960;P3=578;P4=-3954;D=030323232323434343434323232323234343434323234343234343234343232323432323232323232343234;CP=3;SP=0;R=0;m=0;
      {
        name            => 'weather',
        comment         => 'S014, TFA 30.3200, TCM, Conrad S522, renkforce E0001PA, TX-EZ6',
        id              => '33',
        knownFreqs      => '433.92',
        one             => [1,-8],
        zero            => [1,-4],
        sync            => [1,-16],
        clockabs        => '500',
        format          => 'twostate',  # not used now
        preamble        => 'W33#',
        postamble       => '',
        clientmodule    => 'SD_WS',
        #modulematch     => '',
        length_min      => '42',
        length_max      => '44',
      },
    "33.1"  =>  ## Thermo-/Hygrosensor TFA 30.3200
              # https://github.com/RFD-FHEM/SIGNALDuino/issues/113
              # SD_WS_33_TH_1   T: 18.8 H: 53   MS;P1=-7796;P2=745;P3=-1976;P4=-3929;D=21232323242324232324242323232323242424232323242324242323242324232324242323232323232424;CP=2;SP=1;R=30;O;m2;
              # SD_WS_33_TH_2   T: 21.9 H: 49   MS;P1=-7762;P2=747;P3=-1976;P4=-3926;D=21232324232324242323242323232424242424232423232324242323232324232324242323232324242424;CP=2;SP=1;R=32;O;m1;
              # SD_WS_33_TH_3   T: 19.7 H: 53   MS;P1=758;P2=-1964;P3=-3929;P4=-7758;D=14121213121313131213121212131212131313121213121213131212131213121213131212121212121212;CP=1;SP=4;R=48;O;m1;
      {
        name            => 'TFA 30.3200',
        comment         => 'Thermo-/Hygrosensor TFA 30.3200 (CP=750)',
        id              => '33.1',
        knownFreqs      => '433.92',
        one             => [1,-5.6],   # 736,-4121
        zero            => [1,-2.8],   # 736,-2060
        sync            => [1,-11],    # 736,-8096
        clockabs        => 736,
        format          => 'twostate',  # not used now
        preamble        => 'W33#',
        clientmodule    => 'SD_WS',
        length_min      => '42',
        length_max      => '44',
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
        name            => 'Tchibo',
        comment         => 'Tchibo weatherstation (CP=400)',
        id              => '33.2',
        knownFreqs      => '433.92',
        one             => [1,-10],     # 400,-4000
        zero            => [1,-5],      # 400,-2000
        sync            => [1,-19],     # 400,-7600
        clockabs        => 400,
        format          => 'twostate',
        preamble        => 'W33#',
        postamble       => '',
        clientmodule    => 'SD_WS',
        length_min      => '42',
        length_max      => '44',
      },
    "34"  =>  ## QUIGG GT-7000 Funk-Steckdosendimmer | transmitter DMV-7000 - receiver DMV-7009AS
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
              ## Mandolyn Funksteckdosen Set
              # https://github.com/RFD-FHEM/RFFHEM/issues/716 @codeartisan-de
              ## Pollin ISOTRONIC - 12 Tasten remote | model 58608 | SD_UT model QUIGG_DMV ???
              # remote basicadresse with 12bit -> changed if push reset behind battery cover
              # https://github.com/RFD-FHEM/RFFHEM/issues/44 @kaihs
              # Ch1_on       MU;P0=-9584;P1=592;P2=-665;P3=1223;P4=-1311;D=01234141412341412341414123232323412323234;CP=1;R=0;
              # Ch1_off      MU;P0=-12724;P1=597;P2=-667;P3=1253;P4=-1331;D=01234141412341412341414123232323232323232;CP=1;R=0;
      {
        name             => 'QUIGG | LIBRA | Mandolyn | Pollin ISOTRONIC',
        comment          => 'remote control DMV-7000, TR-502MSV, 58608',
        id               => '34',
        knownFreqs       => '433.92',
        one              => [-1,2],
        zero             => [-2,1],
        start            => [1],
        pause            => [-15],   # 9900
        clockabs         => '635',
        format           => 'twostate',
        preamble         => 'P34#',
        clientmodule     => 'SD_UT',
        reconstructBit   => '1',
        #modulematch      => '',
        length_min       => '19',
        length_max       => '20',
      },
    "35"  =>  ## Homeeasy
              # off | vHE800   MS;P0=907;P1=-376;P2=266;P3=-1001;P6=-4860;D=2601010123230123012323230101012301230101010101230123012301;CP=2;SP=6;
      {
        name             => 'HomeEasy HE800',
        id               => '35',
        knownFreqs       => '',
        one              => [1,-4],
        zero             => [3.4,-1],
        sync             => [1,-18],
        clockabs         => '280',
        format           => 'twostate',    # not used now
        preamble         => 'ih',
        postamble        => '',
        clientmodule     => 'IT',
        #modulematch      => '',
        length_min       => '28',
        length_max       => '40',
        postDemodulation => \&lib::SD_Protocols::ConvHE800,
      },
    "36"  =>  ## remote - cheap wireless dimmer
              # https://forum.fhem.de/index.php/topic,38831.msg394238.html#msg394238 @Steffenm
              # u36#CE8501   MU;P0=499;P1=-1523;P2=-522;P3=10220;P4=-10047;D=01020202020202020134010102020101010201020202020102010202020202020201340101020201010102010202020201020102020202020202013401010202010101020102020202010201020202020202020134010102020101010201020202020102010202020202020201340101020201010102010;CP=0;O;
              # u36#CE8501   MU;P0=-520;P1=500;P2=-1523;P3=10220;P4=-10043;D=01010101210121010101010101012341212101012121210121010101012101210101010101010123412121010121212101210101010121012101010101010101234121210101212121012101010101210121010101010101012341212101012121210121010101012101210101010101010123412121010;CP=1;O;
              # u36#CE8501   MU;P0=498;P1=-1524;P2=-521;P3=10212;P4=-10047;D=01010102010202020201020102020202020202013401010202010101020102020202010201020202020202020134010102020101010201020202020102010202020202020201340101020201010102010202020201020102020202020202013401010202010101020102020202010201020202020202020;CP=0;O;
      {
        name             => 'remote',
        comment          => 'cheap wireless dimmer',
        id               => '36',
        knownFreqs       => '433.92',
        one              => [1,-3],
        zero             => [1,-1],
        start            => [20,-20],
        clockabs         => '500',
        format           => 'twostate',    # not used now
        preamble         => 'u36#',
        postamble        => '',
        #clientmodule     => '',
        #modulematch      => '',
        length_min       => '24',
        length_max       => '24',
      },
    "37"  =>  ## Bresser 7009994
              # ! some message are decode as protocol 61 and protocol 84 !
              # Ch:1 T: 22.7 H: 48 Bat:ok   MU;P0=729;P1=-736;P2=483;P3=-251;P4=238;P5=-491;D=010101012323452323454523454545234523234545234523232345454545232345454545452323232345232340;CP=4;
              # Ch:3 T: 16.2 H: 51 Bat:ok   MU;P0=-790;P1=-255;P2=474;P4=226;P6=722;P7=-510;D=721060606060474747472121212147472121472147212121214747212147474721214747212147214721212147214060606060474747472121212140;CP=4;R=216;
              # short pulse of 250 us followed by a 500 us gap is a 0 bit
              # long pulse of 500 us followed by a 250 us gap is a 1 bit
              # sync preamble of pulse, gap, 750 us each, repeated 4 times
    {
        name             => 'Bresser 7009994',
        comment          => 'temperature / humidity sensor',
        id               => '37',
        knownFreqs       => '433.92',
        one              => [2,-1],
        zero             => [1,-2],
        start            => [3,-3,3,-3],
        clockabs         => '250',
        format           => 'twostate',    # not used now
        preamble         => 'W37#',
        clientmodule     => 'SD_WS',
        length_min       => '40',
        length_max       => '41',
    },
    "38"  =>  ## Rosenstein & Soehne, PEARL NC-3911, NC-3912, refrigerator thermometer - 2 channels
              # https://github.com/RFD-FHEM/RFFHEM/issues/504 - Support for NC-3911 Fridge Temp, @MoskitoHorst, 2019-02-05
              # Id:8B Ch:1 T: 6.3   MU;P0=-747;P1=-493;P2=231;P3=484;P4=-248;P6=-982;P7=718;D=1213434212134343421342121343434343434212670707070342121213421343434212134212134212121343421213434342134212134343434343421267070707034212121342134343421213421213421212134342121343434213421213434343434342126707070703421212134213434342121342121342121;CP=2;
              # Id:A8 Ch:2 T:-1.8   MU;P0=-241;P1=491;P2=249;P3=-482;P4=-962;P5=743;P6=-723;D=01023102323232310101010232323102310232323232310101010231024565656561023102310232323102310232323231010101023232310231023232323231010101023102456565656102310231023232310231023232323101010102323231023102323232323101010102310245656565610231023102323231023102;CP=2;O;
              # Id:A8 Ch:2 T: 5.4   MU;P0=-971;P1=733;P2=-731;P3=488;P4=-244;P5=248;P6=-480;P7=-368;D=01212121234563456345656563456345656563456575634563456345634345656345634343434345650121212123456345634565656345634565656345656563456345634563434565634563434343434565012121212345634563456565634563456565634565656345634563456343456563456343434343456501212121;CP=5;O;
      {
        name             => 'NC-3911',
        comment          => 'Refrigerator thermometer',
        id               => '38',
        knownFreqs       => '433.92',
        one              => [2,-1],
        zero             => [1,-2],
        start            => [3,-3,3,-3,3,-3,3,-3],
        clockabs         => 250,
        format           => 'twostate',
        preamble         => 'W38#',
        clientmodule     => 'SD_WS',
        modulematch      => '^W38#.*',
        length_min       => '36',
        length_max       => '36',
      },
    "39"  =>  ## X10 Protocol
              # https://github.com/RFD-FHEM/RFFHEM/issues/65 @wherzig
              # Closed | Bat:ok   MU;P0=10530;P1=-2908;P2=533;P3=-598;P4=-1733;P5=767;D=0123242323232423242324232324232423242323232324232323242424242324242424232423242424232501232423232324232423242323242324232423232323242323232424242423242424242324232424242325012324232323242324232423232423242324232323232423232324242424232424242423242324242;CP=2;O;
      {
        name             => 'X10 Protocol',
        id               => '39',
        knownFreqs       => '',
        one              => [1,-3],
        zero             => [1,-1],
        start            => [17,-7],
        clockabs         => 560,
        format           => 'twostate',
        preamble         => '',
        clientmodule     => 'RFXX10REC',
        #modulematch      => '^TX......',
        length_min       => '32',
        length_max       => '44',
        paddingbits      => '8',
        postDemodulation => \&lib::SD_Protocols::postDemo_lengtnPrefix,
        filterfunc       => 'SIGNALduino_compPattern',
      },
    "40"  =>  ## Romotec
              # ! some message are decode as protocol 19 and protocol 40 not decode !
              # https://github.com/RFD-FHEM/RFFHEM/issues/71 @111apieper
              # u19#6B3190   MU;P0=300;P1=-772;P2=674;P3=-397;P4=4756;P5=-1512;D=4501232301230123230101232301010123230101230103;CP=0;
              # no decode!   MU;P0=-132;P1=-388;P2=675;P4=271;P5=-762;D=012145212145452121454545212145452145214545454521454545452145454541;CP=4;
      {
        name            => 'Romotec ',
        comment         => 'Tubular motor',
        id              => '40',
        knownFreqs      => '',
        one             => [3,-2],
        zero            => [1,-3],
        start           => [1,-2],
        clockabs        => 270,
        preamble        => 'u40#',
        #clientmodule    => '',
        #modulematch     => '',
        length_min      => '12',
        #length_max      => '',    # missing
      },
    "41"  =>  ## Elro (Smartwares) Doorbell DB200 / 16 melodies
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
        name            => 'wireless doorbell',
        comment         => 'Elro (DB200) / KANGTAI (Pollin 94-550405) / unitec',
        id              => '41',
        knownFreqs      => '433.92',
        zero            => [1,-3],
        one             => [3,-1],
        sync            => [1,-14],
        clockabs        => 500,
        format          => 'twostate',
        preamble        => 'P41#',
        clientmodule    => 'SD_BELL',
        modulematch     => '^P41#.*',
        length_min      => '32',
        length_max      => '32',
      },
    "42"  =>  ## Pollin 551227
              # https://github.com/RFD-FHEM/RFFHEM/issues/390 @trosenda
              # FE1FF87 | ring   MU;P0=1446;P1=-487;P2=477;D=0101012121212121212121212101010101212121212121212121210101010121212121212121212121010101012121212121212121212101010101212121212121212121210101010121212121212121212121010101012121212121212121212101010101212121212121212121210101010121212121212121212121010;CP=2;R=93;O;
              # FE1FF87 | ring   MU;P0=-112;P1=1075;P2=-511;P3=452;P5=1418;D=01212121232323232323232323232525252523232323232323232323252525252323232323232323232325252525;CP=3;R=77;
      {
        name            => 'wireless doorbell',
        comment         => 'Pollin 551227',
        id              => '42',
        knownFreqs      => '433.92',
        one             => [1,-1],
        zero            => [3,-1],
        start           => [1,-1,1,-1,1,-1,],
        clockabs        => 500,
        format          => 'twostate',
        preamble        => 'P42#',
        clientmodule    => 'SD_BELL',
        #modulematch     => '^P42#.*',
        length_min      => '28',
        length_max      => '120',
      },
    "43"  =>  ## Somfy RTS
              # https://forum.fhem.de/index.php/topic,64141.msg642800.html#msg642800 @Elektrolurch
              # received=40, parsestate=on   MC;LL=-1405;LH=1269;SL=-723;SH=620;D=98DBD153D631BB;C=669;L=56;R=229;
      {
        name            => 'Somfy RTS',
        id              => '43',
        knownFreqs      => '433.42',
        clockrange      => [610,680],                # min , max
        format          => 'manchester',
        preamble        => 'Ys',
        clientmodule    => 'SOMFY',                  # not used now
        modulematch     => '^Ys[0-9A-F]{14}',
        length_min      => '56',
        length_max      => '57',
        method          => \&lib::SD_Protocols::mcBit2SomfyRTS,  # Call to process this message
        msgIntro        => 'SR;P0=-2560;P1=2560;P3=-640;D=10101010101010113;',
        #msgOutro        => 'SR;P0=-30415;D=0;',
        frequency       => '10AB85550A',
      },
    "44"  =>  ## Bresser Temeo Trend
              # MU;P0=32001;P1=-1939;P2=1967;P3=3896;P4=-3895;D=01213424242124212121242121242121212124212424212121212121242421212421242121242124242421242421242424242124212124242424242421212424212424212121242121212;CP=2;R=39;
      {
        name            => 'BresserTemeo',
        comment         => 'temperature / humidity sensor',
        id              => '44',
        knownFreqs      => '433.92',
        clockabs        => 500,
        zero            => [4,-4],
        one             => [4,-8],
        start           => [8,-8],
        preamble        => 'W44#',
        clientmodule    => 'SD_WS',
        modulematch     => '^W44#[A-F0-9]{18}',
        length_min      => '64',
        length_max      => '72',
      },
    "44.1"  =>  ## Bresser Temeo Trend
      {
        name            => 'BresserTemeo',
        comment         => 'temperature / humidity sensor',
        id              => '44',
        knownFreqs      => '433.92',
        clockabs        => 500,
        zero            => [4,-4],
        one             => [4,-8],
        start           => [8,-12],
        preamble        => 'W44x#',
        clientmodule    => 'SD_WS',
        modulematch     => '^W44x#[A-F0-9]{18}',
        length_min      => '64',
        length_max      => '72',
      },
    "45"  =>  ## Revolt
              #  P:126.8 E:35.88 V:232 C:0.68 Pf:0.8   MU;P0=-8320;P1=9972;P2=-376;P3=117;P4=-251;P5=232;D=012345434345434345454545434345454545454543454343434343434343434343434543434345434343434545434345434343434343454343454545454345434343454345434343434343434345454543434343434345434345454543454343434543454345434545;CP=3;R=2;
      {
        name             => 'Revolt',
        id               => '45',
        knownFreqs       => '',
        one              => [2,-2],
        zero             => [1,-2],
        start            => [83,-3],
        clockabs         => 120,
        preamble         => 'r',
        clientmodule     => 'Revolt',
        modulematch      => '^r[A-Fa-f0-9]{22}',
        length_min       => '96',
        length_max       => '120',
        postDemodulation => \&lib::SD_Protocols::postDemo_Revolt,
      },
    "46"  =>  ## Tedsen Fernbedienungen u.a. für Berner Garagentorantrieb GA401 und Geiger Antriebstechnik Rolladensteuerung
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
        length_min      => '17',       # old 14 -> too short to evaluate
        length_max      => '18',
      },
    "47"  =>  ## Maverick ET-732, ET-733; TFA 14.1504
              # https://github.com/RFD-FHEM/RFFHEM/issues/61
              # Food: 23 BBQ: 22   MC;LL=-507;LH=490;SL=-258;SH=239;D=AA9995599599A959996699A969;C=248;L=104;
              # https://github.com/RFD-FHEM/RFFHEM/issues/167
      {
        name            => 'Maverick',
        comment         => 'BBQ / food thermometer',
        id              => '47',
        knownFreqs      => '433.92',
        clockrange      => [180,260],
        format          => 'manchester',
        preamble        => 'P47#',
        clientmodule    => 'SD_WS_Maverick',
        modulematch     => '^P47#[569A]{12}.*',
        length_min      => '100',
        length_max      => '108',
        method          => \&lib::SD_Protocols::mcBit2Maverick,    # Call to process this message
        #polarity        => 'invert'
      },
    "48"  =>  ## TFA Temperature transmitter 30.3212 for Wireless thermometer JOKER 30.3055
              # https://github.com/RFD-FHEM/RFFHEM/issues/92 @anphiga
              # SD_WS_48_T  T: 24.3  W48#FF49C0F3FFD9  MU;P0=591;P1=-1488;P2=-3736;P3=1338;P4=-372;P6=-988;D=23406060606063606363606363606060636363636363606060606363606060606060606060606060636060636360106060606060606063606363606363606060636363636363606060606363606060606060606060606060636060636360106060606060606063606363606363606060636363636363606060606363606060;CP=0;O;
              # SD_WS_48_T  T: 16.3  W48#FF4D40A3FFE5  MU;P0=96;P1=-244;P2=510;P3=-1000;P4=1520;P5=-1506;D=01232323232343234343232343234323434343434343234323434343232323232323232323232323234343234325232323232323232343234343232343234323434343434343234323434343232323232323232323232323234343234325232323232323232343234343232343234323434343434343234323434343232323;CP=2;O;
      {
        name            => 'TFA JOKER',
        comment         => 'Temperature transmitter TFA 30.3212',
        id              => '48',
        knownFreqs      => '433.92',
        clockabs        => 250,
        one             => [2,-4], #   500,-1000
        zero            => [6,-4], #  1500,-1000
        start           => [-6],   # -1500
        reconstructBit  => '1',
        format          => 'twostate',
        preamble        => 'W48#',
        clientmodule    => 'SD_WS',
        modulematch     => '^W48#.*',
        length_min      => '47', # lenght without reconstructBit
        length_max      => '48',
      },
    "49"  =>  ## QUIGG GT-9000, EASY HOME RCT DS1 CR-A, uniTEC 48110 and other
              # The remote sends 8 messages in 2 different formats.
              # SIGNALduino decodes 4 messages from remote control as MS then ...
              # https://github.com/RFD-FHEM/RFFHEM/issues/667 - Oct 19, 2019
              # DMSG: 5A98B0   MS;P0=-437;P3=-1194;P4=1056;P6=297;P7=-2319;D=67634063404063406340636340406363634063404063636363;CP=6;SP=7;R=37;
              # DMSG: 887F92   MS;P1=-2313;P2=1127;P3=-405;P4=379;P5=-1154;D=41234545452345454545232323232323232345452345452345;CP=4;SP=1;R=251;
              # DMSG: E6D12E   MS;P0=1062;P1=-1176;P2=315;P3=-2283;P4=-433;D=23040404212104042104042104212121042121042104040421;CP=2;SP=3;R=26;
      {
        name            => 'GT-9000',
        comment         => 'Remote control EASY HOME RCT DS1 CR-A',
        id              => '49',
        knownFreqs      => '433.92',
        clockabs        => 383,
        one             => [3,-1],   # 1150,-385 (timings from salae logic)
        zero            => [1,-3],   # 385,-1150 (timings from salae logic)
        sync            => [1,-6],   # 385,-2295 (timings from salae logic)
        format          => 'twostate',
        preamble        => 'P49#',
        clientmodule    => 'SD_GT',
        modulematch     => '^P49.*',
        length_min      => '24',
        length_max      => '24',
      },
    "49.1"  =>  ## QUIGG GT-9000
              # ... decodes 4 messages as MU
              # https://github.com/RFD-FHEM/RFFHEM/issues/667 @Ralf9 from https://forum.fhem.de/index.php/topic,104506.msg985295.html
              # DMSG: 8B2DB0   MU;P0=-563;P1=479;P2=991;P3=-423;P4=361;P5=-1053;P6=3008;P7=-7110;D=2345454523452323454523452323452323452323454545456720151515201520201515201520201520201520201515151567201515152015202015152015202015202015202015151515672015151520152020151520152020152020152020151515156720151515201520201515201520201520201520201515151;CP=1;R=21;
              # DMSG: 887F90   MU;P0=-565;P1=489;P2=991;P3=-423;P4=359;P5=-1047;P6=3000;P7=-7118;D=2345454523454545452323232323232323454523454545456720151515201515151520202020202020201515201515151567201515152015151515202020202020202015152015151515672015151520151515152020202020202020151520151515156720151515201515151520202020202020201515201515151;CP=1;R=17;
      {
        name            => 'GT-9000',
        comment         => 'Remote control is traded under different names',
        id              => '49.1',
        knownFreqs      => '433.92',
        clockabs        => 515,
        one             => [2,-1],   # 1025,-515  (timings from salae logic)
        zero            => [1,-2],   # 515,-1030  (timings from salae logic)
        start           => [6,-14],  # 3075,-7200 (timings from salae logic)
        format          => 'twostate',
        preamble        => 'P49#',
        clientmodule    => 'SD_GT',
        modulematch     => '^P49.*',
        length_min      => '24',
        length_max      => '24',
      },
    "49.2"  =>  ## Tec Star Modell 2335191R
              # SIGNALduino decodes 4 messages from remote control as MU then ... 49.1
              # https://forum.fhem.de/index.php/topic,43292.msg352982.html#msg352982 - Nov 01, 2015
              # message was receive with older firmware
              # DMSG: CA627C   MU;P0=1092;P1=-429;P2=335;P3=-1184;P4=-2316;P5=2996;D=010123230123012323010123232301232301010101012323240101232301230123230101232323012323010101010123232401012323012301232301012323230123230101010101232355;CP=2;
              # DMSG: C9AFAC   MU;P0=328;P1=-428;P3=1090;P4=-1190;P5=-2310;D=010131040431310431043131313131043104313104040531310404310404313104310431313131310431043131040405313104043104043131043104313131313104310431310404053131040431040431310431043131313131043104313104042;CP=0;
      {
        name            => 'GT-9000',
        comment         => 'Remote control Tec Star Modell 2335191R',
        id              => '49.2',
        knownFreqs      => '433.92',
        clockabs        => 383,
        one             => [3,-1],
        zero            => [1,-3],
        start           => [1,-6],      # Message is not provided as MS
        format          => 'twostate',
        preamble        => 'P49#',
        clientmodule    => 'SD_GT',
        modulematch     => '^P49.*',
        length_min      => '24',
        length_max      => '24',
      },
    "50"  =>  ## Opus XT300
              # https://github.com/RFD-FHEM/RFFHEM/issues/99 @sidey79
              # Ch:1 T: 25 H: 5   MU;P0=248;P1=-21400;P2=545;P3=-925;P4=1368;P5=-12308;D=01232323232323232343234323432343234343434343234323432343434343432323232323232323232343432323432345232323232323232343234323432343234343434343234323432343434343432323232323232323232343432323432345232323232323232343234323432343234343434343234323432343434343;CP=2;O;
              # CH:1 T: 18 H: 5   W50#FF55053AFF93    MU;P2=-962;P4=508;P5=1339;P6=-12350;D=46424242424242424252425242524252425252525252425242525242424252425242424242424242424252524252524240;CP=4;R=0;
              # CH:3 T: 18 H: 5   W50#FF57053AFF95    MU;P2=510;P3=-947;P5=1334;P6=-12248;D=26232323232323232353235323532323235353535353235323535323232353235323232323232323232353532353235320;CP=2;R=0;
      {
        name            => 'Opus_XT300',
        comment         => 'sensor for ground humidity',
        id              => '50',
        knownFreqs      => '433.92',
        clockabs        => 500,
        zero            => [3,-2],
        one             => [1,-2],
        # start          => [-25],        # Wenn das startsignal empfangen wird, fehlt das 1 bit
        reconstructBit  => '1',
        format          => 'twostate',
        preamble        => 'W50#',
        clientmodule    => 'SD_WS',
        modulematch     => '^W50#.*',
        length_min      => '47',
        length_max      => '48',
      },
    "51"  =>  ## weather sensors
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
        name            => 'weather',
        comment         => 'Lidl Weatherstation IAN60107, IAN 114324, IAN 275901',
        id              => '51',
        knownFreqs      => '433.92',
        one             => [1,-8],
        zero            => [1,-4],
        sync            => [1,-16],
        clockabs        => '500',
        format          => 'twostate',    # not used now
        preamble        => 'W51#',
        postamble       => '',
        clientmodule    => 'SD_WS',
        modulematch     => '^W51#.*',
        length_min      => '40',
        length_max      => '45',
      },
    "52"  =>  ## Oregon Scientific PIR Protocol
              # https://forum.fhem.de/index.php/topic,63604.msg548256.html#msg548256 @Ralf_W.
              # u52#00012AE7   MC;LL=-1045;LH=1153;SL=-494;SH=606;D=FFFED518;C=549;L=30;
              ## note: unfortunately, the user is no longer in possession of a SIGNALduino
              #
              # FFFED5 = Adresse, die per DIP einstellt wird, FFF ändert sich nie
              # 1 = Kanal, per gesondertem DIP, bei mir bei beiden 1 (CH 1) oder 3 (CH 2)
              # C = wechselt, 0, 4, 8, C - dann fängt es wieder mit 0 an und wiederholt sich bei jeder Bewegung
      {
        name            => 'Oregon Scientific PIR',
        comment         => 'JMR868 / NR868',
        id              => '52',
        knownFreqs      => '433.92',
        clockrange      => [470,640],              # min , max
        format          => 'manchester',           # tristate can't be migrated from bin into hex!
        #clientmodule    => '',                    # OREGON module not for Motion Detectors
        modulematch     => '^u52#F{3}|0{3}.*',
        preamble        => 'u52#',
        length_min      => '30',
        length_max      => '30',
        method          => \&lib::SD_Protocols::mcBit2OSPIR,    # Call to process this message
        polarity        => 'invert',
      },
    "53"  =>  ## Lidl AURIOL AHFL 433 B2 IAN 314695
              # https://github.com/RFD-FHEM/RFFHEM/issues/663 @Kreidler1221 05.10.2019
              # IAN 314695 Id:07 Ch:1 T:24.2 H:59   MS;P1=611;P2=-2075;P3=-4160;P4=-9134;D=14121212121213131312121212121212121313131312121312121313131213131212131212131213121213;CP=1;SP=4;R=0;O;m2;
              # IAN 314695 Id:07 Ch:1 T:22.3 H:61   MS;P1=608;P2=-2074;P3=-4138;P4=-9138;D=14121212121213131312121212121212121313121313131313121313131312131212131212131313121212;CP=1;SP=4;R=0;O;m1;
              # IAN 314695 Id:07 Ch:2 T:18.4 H:70   MS;P0=606;P1=-2075;P2=-4136;P3=-9066;D=03010101010102020201010102010101010201020202010101020101010202010101020101020201010202;CP=0;SP=3;R=0;O;m2;
      {
        name            => 'AHFL 433 B2',
        comment         => 'Auriol weatherstation IAN 314695',
        id              => '53',
        knownFreqs      => '433.92',
        one             => [1,-7],
        zero            => [1,-3.5],
        sync            => [1,-15],
        clockabs        => 600,
        format          => 'twostate',    # not used now
        preamble        => 'W53#',
        clientmodule    => 'SD_WS',
        modulematch     => '^W53#.*',
        length_min      => '42',
        length_max      => '44',
      },
    "54"  =>  ## TFA Drop 30.3233.01 - Rain gauge
              # Rain sensor 30.3233.01 for base station 47.3005.01
              # https://github.com/merbanan/rtl_433/blob/master/src/devices/tfa_drop_30.3233.c | https://forum.fhem.de/index.php/topic,107998.0.html @sido
              # @sido
              # SD_WS_54_R_D9C43 R: 73.66   MU;P1=247;P2=-750;P3=722;P4=-489;P5=491;P6=-236;P7=-2184;D=1232141456565656145656141456565614141456141414145656141414141456561414141456561414145614561456145614141414141414145614145656145614141732321414565656561456561414565656141414561414141456561414141414565614141414565614141456145614561456141414141414141456141;CP=1;R=55;O;
              # SD_WS_54_R_D9C43 R: 74.422  MU;P0=-1672;P1=740;P2=-724;P3=260;P4=-468;P5=504;P6=-230;D=012123434565656563456563434565656343434563434343456563434343456345634343434565634565656345634563456343434343434343456563434345634345656;CP=3;R=4;
              # @punker
              # SD_WS_54_R_896E1 R: 28.702  MU;P0=-242;P1=-2076;P2=-13292;P3=242;P4=-718;P5=748;P6=-494;P7=481;CP=3;R=29;D=23454363670707036363670363670367070367070703636363670363636363670363636707036367070707036703670367036363636363636363636707036703636363154543636707070363636703636703670703670707036363636703636363636703636367070363670707070367036703670363636363636363636367;O;
              # SD_WS_54_R_896E1 R: 29.464  MU;P0=-236;P1=493;P2=235;P3=-503;P4=-2076;P5=734;P6=-728;CP=2;R=11;D=0101023101023245656232310101023232310232310231010231010102323232310232323232310102323101023102310231023102310231023232323232323232323101010231010232;e;i;
      {
        name            => 'TFA 30.3233.01',
        comment         => 'Rain sensor',
        id              => '54',
        knownFreqs      => '433.92',
        one             => [2,-1],
        zero            => [1,-2],
        start           => [3,-3],  # message provided as MU
        clockabs        => 250,
        reconstructBit  => '1',
        clientmodule    => 'SD_WS',
        format          => 'twostate',
        preamble        => 'W54#',
        length_min      => '64',
        length_max      => '68',
      },
    "54.1" => ## TFA Drop 30.3233.01 - Rain gauge
              # Rain sensor 30.3233.01 for base station 47.3005.01
              # https://github.com/merbanan/rtl_433/blob/master/src/devices/tfa_drop_30.3233.c | https://forum.fhem.de/index.php/topic,107998.0.html @punker
              # @punker
              # SD_WS_54_R_896E1 R: 28.702  MS;P0=-241;P1=486;P2=241;P3=-488;P4=-2098;P5=738;P6=-730;D=24565623231010102323231023231023101023101010232323231023232323231023232310102323101010102310231023102323232323232323232310102310232323;CP=2;SP=4;R=30;O;b=19;s=1;m0;
              # SD_WS_54_R_896E1 R: 29.464  MS;P0=-491;P1=242;P2=476;P3=-248;P4=-2096;P5=721;P6=-745;D=14565610102323231010102310102310232310232323101010102310101010102323101023231023102310231023102310231010101010101010101023232310232310;CP=1;SP=4;R=10;O;b=135;s=1;m0;
      {
        name            => 'TFA 30.3233.01',
        comment         => 'Rain sensor',
        id              => '54.1',
        knownFreqs      => '433.92',
        one             => [2,-1],
        zero            => [1,-2],
        sync            => [3,-3],  # message provided as MS
        clockabs        => 250,
        clientmodule    => 'SD_WS',
        format          => 'twostate',
        preamble        => 'W54#',
        length_min      => '64',
        length_max      => '68',
      },
    "55"  =>  ## QUIGG GT-1000
      {
        name            => 'QUIGG_GT-1000',
        comment         => 'remote control',
        id              => '55',
        knownFreqs      => '',
        clockabs        => 300,
        zero            => [1,-4],
        one             => [4,-2],
        sync            => [1,-8],
        format          => 'twostate',
        preamble        => 'i',
        clientmodule    => 'IT',
        modulematch     => '^i.*',
        length_min      => '24',
        length_max      => '24',
      },
    "56"  =>  ## Celexon Motorleinwand
              # https://forum.fhem.de/index.php/topic,52025.0.html @Horst12345
              # AC114_01B_00587B down MU;P0=5036;P1=-624;P2=591;P3=-227;P4=187;P5=-5048;D=0123412341414123234141414141414141412341232341414141232323234123234141414141414123414141414141414141234141414123234141412341232323250123412341414123234141414141414141412341232341414141232323234123234141414141414123414141414141414141234141414123234141412;CP=4;O;
              # Alphavision Slender Line Plus motor canvas, remote control AC114-01B from Shenzhen A-OK Technology Grand Development Co.
              # https://github.com/RFD-FHEM/RFFHEM/issues/906 @TheChatty
              # AC114_01B_479696 up   MU;P0=-16412;P1=5195;P2=-598;P3=585;P4=-208;P5=192;D=01234523452525234345234525252343434345252345234345234525234523434525252525252525234525252525252525252525252345234345234343434343434341234523452525234345234525252343434345252345234345234525234523434525252525252525234525252525252525252525252345234345234343;CP=5;R=105;O;
              # AC114_01B_479696 stop MU;P0=-2341;P1=5206;P2=-571;P3=591;P4=-211;P5=207;D=01234523452525234345234525252343434345252345234345234525234523434525252525252525234525252525252525252523452525234343452523452343434341234523452525234345234525252343434345252345234345234525234523434525252525252525234525252525252525252523452525234343452523;CP=5;R=107;O;
      {
        name           => 'AC114-xxB',
        comment        => 'Remote control for motorized screen from Alphavision, Celexon',
        id              => '56',
        knownFreqs      => '433.92',
        zero           => [1,-3],  #  200,-600
        one            => [3,-1],  #  600,-200
        start          => [25,-3], # 5000,-600
        pause          => [-25],   # -5000, pause between repeats of send messages (clockabs*pause must be < 32768)
        clockabs        => 200,
        reconstructBit => '1',
        format          => 'twostate',
        preamble       => 'P56#',
        clientmodule   => 'SD_UT',
        modulematch    => '^P56#',
        length_min     => '64', # 65 - reconstructBit = 64
        length_max     => '65', # normal 65 Bit, 3 Bit werden aufgefuellt
      },
    "57"  =>  ## m-e doorbell fuer FG- und Basic-Serie
              # https://forum.fhem.de/index.php/topic,64251.0.html @rippi46
              # P57#2AA4A7 | ring   MC;LL=-653;LH=665;SL=-317;SH=348;D=D55B58;C=330;L=21;
              # P57#2AA4A7 | ring   MC;LL=-654;LH=678;SL=-314;SH=351;D=D55B58;C=332;L=21;
              # P57#2AA4A7 | ring   MC;LL=-653;LH=679;SL=-310;SH=351;D=D55B58;C=332;L=21;
      {
        name            => 'm-e',
        comment         => 'radio gong transmitter for FG- and Basic-Serie',
        id              => '57',
        knownFreqs      => '',
        clockrange      => [300,360],          # min , max
        format          => 'manchester',       # tristate can't be migrated from bin into hex!
        clientmodule    => 'SD_BELL',
        modulematch     => '^P57#.*',
        preamble        => 'P57#',
        length_min      => '21',
        length_max      => '24',
        method          => \&lib::SD_Protocols::MCRAW,  # Call to process this message
        polarity        => 'invert',
      },
    "58"  =>  ## TFA 30.3208.02, 30.3228.02, 30.3229.02, Froggit/Renkforce FT007TH, FT007PF, FT007T, FT007TP, Ambient Weather F007-TH, F007-T, F007-TP
              # SD_WS_58_TH_200_2 Ch: 2 T: 18.9 H: 69 Bat: ok   MC;LL=-981;LH=964;SL=-480;SH=520;D=002BA37EBDBBA24F0015D1BF5EDDD127800AE8DFAF6EE893C;C=486;L=194;
              # Froggit FT007T - https://forum.fhem.de/index.php/topic,58397.msg1023517.html#msg1023517
              # SD_WS_58_T_135_2 Ch: 2 T: 22.2 Bat: ok   MC;LL=-1047;LH=903;SL=-545;SH=449;D=800AE5E3AE7FD44BC00572F1D73FEA25E002B9788;C=494;L=161;
              # SD_WS_58_T_135_2 Ch: 2 T: 22.3 Bat: ok   MC;LL=-1047;LH=902;SL=-546;SH=452;D=0015CBC75CF7AA8F800AE5E3AE7BD547C00572F1D0;C=487;L=165;
              # Renkforce FT007TH  - https://forum.fhem.de/index.php/topic,65680.msg963889.html#msg963889
              # SD_WS_58_TH_84_2 Ch: 2 T: 23.9 H: 58 Bat: ok   MC;LL=-1005;LH=946;SL=-505;SH=496;D=0015D55F5C0E2B47800AEAAFAE0715A3C0057557D7;C=487;L=168;R=0;
      {
        name            => 'TFA 30.3208.0',
        comment         => 'Temperature/humidity sensors (TFA 30.3208.02, 30.3228.02, 30.3229.02, Froggit/Renkforce FT007xx, Ambient Weather F007-xx)',
        id              => '58',
        knownFreqs      => '433.92',
        clockrange      => [460,520],
        format          => 'manchester',
        clientmodule    => 'SD_WS',
        modulematch     => '^W58*',
        preamble        => 'W58#',
        length_min      => '52',  # 54
        length_max      => '52',  # 136
        method          => \&lib::SD_Protocols::mcBit2TFA,
        polarity        => 'invert',
      },
    "59"  =>  ## AK-HD-4 remote | 4 Buttons
              # https://github.com/RFD-FHEM/RFFHEM/issues/133 @stevedee78
              # u59#6DCAFB   MU;P0=819;P1=-919;P2=234;P3=-320;P4=8602;P6=156;D=01230301230301230303012123012301230303030301230303412303012303012303030121230123012303030303012303034123030123030123030301212301230123030303030123030341230301230301230303012123012301230303030301230303412303012303012303030121230123012303030303012303034163;CP=0;O;
              # u59#6DCAFB   MU;P0=-334;P2=8581;P3=237;P4=-516;P5=782;P6=-883;D=23456305056305050563630563056305050505056305050263050563050563050505636305630563050505050563050502630505630505630505056363056305630505050505630505026305056305056305050563630563056305050505056305050263050563050563050505636305630563050505050563050502630505;CP=5;O;
      {
        name            => 'AK-HD-4',
        comment         => 'remote control with 4 buttons',
        id              => '59',
        knownFreqs      => '433.92',
        clockabs        => 230,
        zero            => [-4,1],
        one             => [-1,4],
        start           => [-1,37],
        format          => 'twostate',  # tristate can't be migrated from bin into hex!
        preamble        => 'u59#',
        postamble       => '',
        #clientmodule    => '',
        #modulematch     => '',
        length_min      => '24',
        length_max      => '24',
      },
    "60"  =>  ## ELV, LA CROSSE (WS2000/WS7000)
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
        name             => 'WS2000',
        comment          => 'Series WS2000/WS7000 of various sensors',
        id               => '60',
        knownFreqs       => '',
        one              => [3,-7],
        zero             => [7,-3],
        clockabs         => 122,
        reconstructBit   => '1',
        preamble         => 'K',
        postamble        => '',
        clientmodule     => 'CUL_WS',
        length_min       => '38',      # 46, letztes Bit fehlt = 45, 10 Bit Preambel = 35 Bit Daten
        length_max       => '82',
        postDemodulation => \&lib::SD_Protocols::postDemo_WS2000,
      },
    "61"  =>  ## ELV FS10
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
        name            => 'FS10',
        comment         => 'remote control',
        id              => '61',
        knownFreqs      => '433.92',
        one             => [1,-2],
        zero            => [1,-1],
        clockabs        => 400,
        pause           => [-81],      # 400*81=32400*6=194400 - pause between repeats of send messages (clockabs*pause must be < 32768)
        format          => 'twostate',
        preamble        => 'P61#',
        postamble       => '',
        clientmodule    => 'FS10',
        length_min      => '30',       # 43-1=42 (letztes Bit fehlt) 42-12=30 (12 Bit Preambel)
        length_max      => '48',       # eigentlich 46
      },
    "62"  =>  ## Clarus_Switch
              # ! some message are decode as protocol 32 !
              # Unknown code i415703, help me!   MU;P0=-5893;P4=-634;P5=498;P6=-257;P7=116;D=45656567474747474745656707456747474747456745674567456565674747474747456567074567474747474567456745674565656747474747474565670745674747474745674567456745656567474747474745656707456747474747456745674567456565674747474747456567074567474747474567456745674567;CP=7;O;
      {
        name            => 'Clarus_Switch',
        id              => '62',
        knownFreqs      => '',
        one             => [3,-1],
        zero            => [1,-3],
        start           => [1,-35],    # ca 30-40
        clockabs        => 189,
        preamble        => 'i',
        clientmodule    => 'IT',
        #modulematch     => '',
        length_min      => '24',
        length_max      => '24',
      },
    "63"  =>  ## Warema MU
              # https://forum.fhem.de/index.php/topic,38831.msg395978/topicseen.html#msg395978 @Totte10 | https://www.mikrocontroller.net/topic/264063
              # no decode!   MU;P0=-2988;P1=1762;P2=-1781;P3=-902;P4=871;P5=6762;P6=5012;D=0121342434343434352434313434243521342134343436;
              # no decode!   MU;P0=6324;P1=-1789;P2=864;P3=-910;P4=1756;D=0123234143212323232323032321234141032323232323232323;CP=2;
      {
        name            => 'Warema',
        comment         => 'radio shutter switch (is still experimental)',
        id              => '63',
        knownFreqs      => '',
        developId       => 'y',
        one             => [1],
        zero            => [0],
        clockabs        => 800,
        syncabs         => '6700',  # Special field for filterMC function
        preamble        => 'u63#',
        #clientmodule    => '',
        #modulematch     => '',
        length_min      => '24',
        #length_max      => '',     # missing
        filterfunc      => 'SIGNALduino_filterMC',
      },
    "64"  =>  ## Fine Offset Electronics WH2, WH2A Temperature/Humidity sensor
              # T: 17.4 H: 74   MU;P0=-28888;P1=461;P2=-1012;P3=1440;D=01212121212121232123232123212121232121232323232123212321212123232123232123212323232321212123232323232321212121;CP=1;R=202;
              # T: 28.3 H: 42   MU;P0=-25696;P1=479;P2=-985;P3=1461;D=01212121212121232123232123212121232121232323212323232121232121232321232123212323232323232121212321232321232323;CP=1;R=215;
              # T: 23   H: 64   MU;P0=134;P1=-113;P3=412;P4=-1062;P5=1379;D=01010101013434343434343454345454345454545454345454545454343434545434345454345454545454543454543454345454545434545454345;CP=3;
      {
        name            => 'WH2',
        comment         => 'temperature / humidity sensor',
        id              => '64',
        knownFreqs      => '433.92',
        one             => [1,-2],
        zero            => [3,-2],
        clockabs        => 490,
        clientmodule    => 'SD_WS',
        modulematch     => '^W64*',
        preamble        => 'W64#',
        clientmodule    => 'SD_WS',
        length_min      => '48',
        length_max      => '56',
      },
    "65"  =>  ## Homeeasy
              # on | vHE_EU   MS;P1=231;P2=-1336;P4=-312;P5=-8920;D=15121214141412121212141414121212121414121214121214141212141212141212121414121414141212121214141214121212141412141212;CP=1;SP=5;
      {
        name             => 'HomeEasy HE_EU',
        id               => '65',
        knownFreqs       => '',
        one              => [1,-5.5],
        zero             => [1,-1.2],
        sync             => [1,-38],
        clockabs         => 230,
        format           => 'twostate',  # not used now
        preamble         => 'ih',
        clientmodule     => 'IT',
        length_min       => '57',
        length_max       => '72',
        postDemodulation => \&lib::SD_Protocols::ConvHE_EU,
      },
    "66"  =>  ## TX2 Protocol (Remote Temp Transmitter & Remote Thermo Model 7035)
              # https://github.com/RFD-FHEM/RFFHEM/issues/160 @elektron-bbs
              # Id:66 T: 23.2   MU;P0=13312;P1=-2785;P2=4985;P3=1124;P4=-6442;P5=3181;P6=-31980;D=0121345434545454545434545454543454545434343454543434545434545454545454343434545434343434545621213454345454545454345454545434545454343434545434345454345454545454543434345454343434345456212134543454545454543454545454345454543434345454343454543454545454545;CP=3;R=73;O;
              # Id:49 T: 25.2   MU;P0=32001;P1=-2766;P2=4996;P3=1158;P4=-6416;P5=3203;P6=-31946;D=01213454345454545454543434545454345454343434543454345454345454545454543434345434543434345456212134543454545454545434345454543454543434345434543454543454545454545434343454345434343454562121345434545454545454343454545434545434343454345434545434545454545454;CP=3;R=72;O; 
      {
        name             => 'WS7035',
        comment          => 'temperature sensor',
        id               => '66',
        knownFreqs       => '',
        one              => [10,-52],
        zero             => [27,-52],
        start            => [-21,42,-21],
        clockabs         => 122,
        reconstructBit   => '1',
        format           => 'pwm',      # not used now
        preamble         => 'TX',
        clientmodule     => 'CUL_TX',
        modulematch      => '^TX......',
        length_min       => '43',
        length_max       => '44',
        postDemodulation => \&lib::SD_Protocols::postDemo_WS7035,
      },
    "67"  =>  ## TX2 Protocol (Remote Datalink & Remote Thermo Model 7053, 7054)
              # https://github.com/RFD-FHEM/RFFHEM/issues/162 @elektron-bbs
              # Id:72 T: 26.0   MU;P0=3381;P1=-672;P2=-4628;P3=1142;P4=-30768;D=010 2320232020202020232020232020202320232323202323202020202020202020 4 010 2320232020202020232020232020202320232323202323202020202020202020 0;CP=0;R=45;
              # Id:72 T: 24.3   MU;P0=1148;P1=3421;P6=-664;P7=-4631;D=161 7071707171717171707171707171717171707070717071717171707071717171 0;CP=1;R=29;
              # Message repeats 4 x with pause of ca. 30-34 mS
              #           __               ____
              #  ________|  |     ________|    |
              #      Bit 1             Bit 0
              #    4630  1220       4630   3420   mikroSek - mit Oszi gemessene Zeiten
      {
        name             => 'WS7053',
        comment          => 'temperature sensor',
        id               => '67',
        knownFreqs       => '',
        one              => [-38,10],     # -4636, 1220
        zero             => [-38,28],     # -4636, 3416
        clockabs         => 122,
        preamble         => 'TX',
        clientmodule     => 'CUL_TX',
        modulematch      => '^TX......',
        length_min       => '32',
        length_max       => '34',
        postDemodulation => \&lib::SD_Protocols::postDemo_WS7053,
      },
    "68"  =>  ## Medion OR28V RF Vista Remote Control (Made in china by X10)
              # sendet zwei verschiedene Codes pro Taste
              # Taste ok    739E0  MS;P1=-1746;P2=513;P3=-571;P4=-4612;P5=2801;D=24512321212123232121212323212121212323232323;CP=2;SP=4;R=58;#;#;
              # Taste ok    F31E0  MS;P1=-1712;P2=518;P3=-544;P4=-4586;P5=2807;D=24512121212123232121232323212121212323232323;CP=2;SP=4;R=58;m2;#;#;
              # Taste Vol+  E00B0  MS;P1=-1620;P2=580;P3=-549;P4=-4561;P5=2812;D=24512121212323232323232323232123212123232323;CP=2;SP=4;R=69;O;m2;#;#;
              # Taste Vol+  608B0  MS;P1=-1645;P2=574;P3=-535;P4=-4556;P5=2811;D=24512321212323232323212323232123212123232323;CP=2;SP=4;R=57;m2;#;#;
      {
        name            => 'OR28V',
        comment         => 'Medion OR28V RF Vista Remote Control',
        id              => '68',
        knownFreqs      => '433.92',
        one             => [1,-3],
        zero            => [1,-1],
        sync            => [1,-8,5,-3],
        clockabs        => 550,
        format          => 'twostate',
        preamble        => 'P68#',
        clientmodule    => 'SD_UT',
        modulematch     => '^P68#.{5}',
        length_min      => '20',
        length_max      => '20',
      },
    "69"  =>  ## Hoermann HSM2, HSM4, HS1-868-BS (868 MHz)
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
        name             => 'Hoermann',
        comment          => 'remote control HS1-868-BS, HSM4',
        id               => '69',
        knownFreqs       => '433.92 | 868.35',
        zero             => [2,-1],     # 1020,510
        one              => [1,-2],     # 510,1020
        start            => [25,-1],    # 12750,510
        clockabs         => 510,
        format           => 'twostate',
        clientmodule     => 'SD_UT',
        modulematch      => '^P69#.{11}',
        preamble         => 'P69#',
        length_min       => '44',
        length_max       => '44',
      },
    "70"  =>  ## FHT80TF (Funk-Tuer-Fenster-Melder FHT 80TF und FHT 80TF-2)
              # https://github.com/RFD-FHEM/RFFHEM/issues/171 @HomeAutoUser
              # closed   MU;P0=-24396;P1=417;P2=-376;P3=610;P4=-582;D=012121212121212121212121234123434121234341212343434121234123434343412343434121234341212121212341212341234341234123434;CP=1;R=35;
              # open     MU;P0=-21652;P1=429;P2=-367;P4=634;P5=-555;D=012121212121212121212121245124545121245451212454545121245124545454512454545121245451212121212124512451245451245121212;CP=1;R=38;
      {
        name             => 'FHT80TF',
        comment          => 'door/window switch',
        id               => '70',
        knownFreqs       => '868.35',
        one              => [1.5,-1.5],    # 600
        zero             => [1,-1],        # 400
        clockabs         => 400,
        format           => 'twostate',    # not used now
        clientmodule     => 'CUL_FHTTK',
        preamble         => 'T',
        length_min       => '50',
        length_max       => '58',
        postDemodulation => \&lib::SD_Protocols::postDemo_FHT80TF,
      },
    "71"  =>  ## PEARL infactory Poolthermometer (PV-8644)
              # Ch:1 T: 24.2   MU;P0=1735;P1=-1160;P2=591;P3=-876;D=0123012323010101230101232301230123010101010123012301012323232323232301232323232323232323012301012;CP=2;R=97;
      {
        name            => 'PEARL',
        comment         => 'infactory Poolthermometer (PV-8644)',
        id              => '71',
        knownFreqs      => '433.92',
        clockabs        => 580,
        zero            => [3,-2],
        one             => [1,-1.5],
        format          => 'twostate',
        preamble        => 'W71#',
        clientmodule    => 'SD_WS',
        #modulematch   => '^W71#.*'
        length_min      => '48',
        length_max      => '48',
      },
    "72"  =>  ## Siro blinds MU   @Dr.Smag
              # ! same definition how ID 16 !
              # module ERROR after delete and parse without save!!! 
              # >Siro_5B417081< returned by the Siro ParseFn is invalid, notify the module maintainer
              # https://forum.fhem.de/index.php?topic=77167.0
              # MU;P0=-760;P1=334;P2=693;P3=-399;P4=-8942;P5=4796;P6=-1540;D=01010102310232310101010102310232323101010102310101010101023102323102323102323102310101010102310232323101010102310101010101023102310231023102456102310232310232310231010101010231023232310101010231010101010102310231023102310245610231023231023231023101010101;CP=1;R=45;O;
              # MU;P0=-8848;P1=4804;P2=-1512;P3=336;P4=-757;P5=695;P6=-402;D=0123456345656345656345634343434345634565656343434345634343434343456345634563456345;CP=3;R=49;
      {
        name             => 'Siro shutter',
        comment          => 'message decode as MU',
        id               => '72',
        knownFreqs       => '',
        dispatchequals   => 'true',
        one              => [2,-1.2],     # 680, -400
        zero             => [1,-2.2],     # 340, -750
        start            => [14,-4.4],    # 4800,-1520
        clockabs         => 340,
        format           => 'twostate',
        preamble         => 'P72#',
        clientmodule     => 'Siro',
        #modulematch      => '',
        length_min       => '39',
        length_max       => '40',
        msgOutro         => 'SR;P0=-8500;D=0;',
      },
    "72.1"  =>  ## Siro blinds MS    @Dr.Smag
                # Id:5B41708 state:0   MS;P0=4803;P1=-1522;P2=333;P3=-769;P4=699;P5=-393;P6=-9190;D=2601234523454523454523452323232323452345454523232323452323232323234523232345454545;CP=2;SP=6;R=61;
      {
        name             => 'Siro shutter',
        comment          => 'message decode as MS',
        id               => '72',
        knownFreqs       => '',
        developId        => 'm',
        dispatchequals   =>  'true',
        one              => [2,-1.2],     # 680, -400
        zero             => [1,-2.2],     # 340, -750
        sync             => [14,-4.4],    # 4800,-1520
        clockabs         => 340,
        format           => 'twostate',
        preamble         => 'P72#',
        clientmodule     => 'Siro',
        #modulematch      => '',
        length_min       => '39',
        length_max       => '40',
        #msgOutro         => 'SR;P0=-8500;D=0;',
      },
    "73"  =>  ## FHT80 - Raumthermostat (868Mhz) @HomeAutoUser
              # actuator:0%   MU;P0=136;P1=-112;P2=631;P3=-392;P4=402;P5=-592;P6=-8952;D=0123434343434343434343434325434343254325252543432543434343434325434343434343434343254325252543254325434343434343434343434343252525432543464343434343434343434343432543434325432525254343254343434343432543434343434343434325432525254325432543434343434343434;CP=4;R=250;
      {
        name             => 'FHT80',
        comment          => 'roomthermostat (only receive)',
        id               => '73',
        knownFreqs       => '868.35',
        one              => [1.5,-1.5],  # 600
        zero             => [1,-1],      # 400
        pause            => [-25],
        clockabs         => 400,
        format           => 'twostate',  # not used now
        clientmodule     => 'FHT',
        preamble         => '810c04xx0909a001',
        length_min       => '59',
        length_max       => '67',
        postDemodulation => \&lib::SD_Protocols::postDemo_FHT80,
      },
    "74"  =>  ## FS20 - Remote Control (868Mhz) @HomeAutoUser
              # dim100%   MU;P0=-10420;P1=-92;P2=398;P3=-417;P5=596;P6=-592;D=1232323232323232323232323562323235656232323232356232356232623232323232323232323232323235623232323562356565623565623562023232323232323232323232356232323565623232323235623235623232323232323232323232323232323562323232356235656562356562356202323232323232323;CP=2;R=72;
      {
        name             => 'FS20',
        comment          => 'remote control (decode as MU)',
        id               => '74',
        knownFreqs       => '868.35',
        one              => [1.5,-1.5],  # 600
        zero             => [1,-1],      # 400
        pause            => [-25],
        clockabs         => 400,
        #reconstructBit   => '1',
        format           => 'twostate',  # not used now
        clientmodule     => 'FS20',
        preamble         => '810b04f70101a001',
        length_min       => '50',
        length_max       => '67',
        postDemodulation => \&lib::SD_Protocols::postDemo_FS20,
      },
    "74.1"  =>  ## FS20 - Remote Control (868Mhz) @HomeAutoUser
                # dim100%   MS;P1=-356;P2=448;P3=653;P4=-551;P5=-10412;D=2521212121212121212121212134212121343421212121213421213421212121212121212121212121212121342121212134213434342134342134;CP=2;SP=5;R=72;O;!;4;
      {
        name             => 'FS20',
        comment          => 'remote control (decode as MS)',
        id               => '74.1',
        knownFreqs       => '868.35',
        one              => [1.5,-1.5],  # 600
        zero             => [1,-1],      # 400
        sync             => [-25],
        clockabs         => 400,
        #reconstructBit   => '1',
        format           => 'twostate',  # not used now
        clientmodule     => 'FS20',
        preamble         => '810b04f70101a001',
        paddingbits      => '1',         # disable padding
        length_min       => '50',
        length_max       => '67',
        postDemodulation => \&lib::SD_Protocols::postDemo_FS20,
      },
    "75"  =>  ## Conrad RSL (Erweiterung v2) @litronics https://github.com/RFD-FHEM/SIGNALDuino/issues/69
              # ! same definition how ID 5, but other length !
              # !! protocol needed revision - start or sync failed !! https://github.com/RFD-FHEM/SIGNALDuino/issues/69#issuecomment-440349328
              # on    MU;P0=-1365;P1=477;P2=1145;P3=-734;P4=-6332;D=01023202310102323102423102323102323101023232323101010232323231023102323102310102323102423102323102323101023232323101010232323231023102323102310102323102;CP=1;R=12;
      {
        name            => 'Conrad RSL v2',
        comment         => 'remotes and switches',
        id              => '75',
        knownFreqs      => '',
        one             => [3,-1],
        zero            => [1,-3],
        clockabs        => 500,
        format          => 'twostate',
        developId       => 'y',
        clientmodule    => 'SD_RSL',
        preamble        => 'P1#',
        modulematch     => '^P1#[A-Fa-f0-9]{8}',
        length_min      => '32',
        length_max      => '40',
      },
    "76"  =>  ## Kabellose LED-Weihnachtskerzen XM21-0
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
        name            => 'LED XM21',
        comment         => 'remote with 2-buttons for LED X-MAS light string',
        id              => '76',
        knownFreqs      => '433.92',
        one             => [1.2,-2],                       # 120,-200
        #zero            => [],                            # existiert nicht
        start           => [4.5,-2,4.5,-2,4.5,-2,4.5,-2],  # 450,-200 Starsequenz
        clockabs        => 100,
        format          => 'twostate',                     # not used now
        clientmodule    => 'SD_UT',
        preamble        => 'P76#',
        length_min      => 58,
        length_max      => 64,
      },
    "77"  =>  ## NANO_DS1820_4Fach
              # https://github.com/juergs/NANO_DS1820_4Fach
              # Id:105 T: 22.8   MU;P0=-1483;P1=239;P2=970;P3=-21544;D=01020202010132020202010201020202020201010201020201020201010102020102010202020201010102020102020201013202020201020102020202020101020102020102020101010202010201020202020101010202010202020101;CP=1;
              # Id:106 T: 0.0    MU;P0=-168;P1=420;P2=-416;P3=968;P4=-1491;P5=242;P6=-21536;D=01234343434543454343434343454543454345434543454345434343434343434343454345434343434345454363434343454345434343434345454345434543454345434543434343434343434345434543434343434545436343434345434543434343434545434543454345434543454343434343434343434543454343;CP=3;O;
              # Id:106 T: 0.0    MU;P0=-1483;P1=969;P2=236;P3=-21542;D=01010102020131010101020102010101010102020102010201020102010201010101010101010102010201010101010202013101010102010201010101010202010201020102010201020101010101010101010201020101010101020201;CP=1;
              # Id:107 T: 0.0    MU;P0=-32001;P1=112;P2=-8408;P3=968;P4=-1490;P5=239;P6=-21542;D=01234343434543454343434343454543454345454343454345434343434343434343454345434343434345454563434343454345434343434345454345434545434345434543434343434343434345434543434343434545456343434345434543434343434545434543454543434543454343434343434343434543454343;CP=3;O;
              # Id:107 T: 0.0    MU;P0=-1483;P1=968;P2=240;P3=-21542;D=01010102020231010101020102010101010102020102010202010102010201010101010101010102010201010101010202023101010102010201010101010202010201020201010201020101010101010101010201020101010101020202;CP=1;
              # Id:108 T: 0.0    MU;P0=-32001;P1=969;P2=-1483;P3=237;P4=-21542;D=01212121232123212121212123232123232121232123212321212121212121212123212321212121232123214121212123212321212121212323212323212123212321232121212121212121212321232121212123212321412121212321232121212121232321232321212321232123212121212121212121232123212121;CP=1;O;
              # Id:108 T: 0.0    MU;P0=-1485;P1=967;P2=236;P3=-21536;D=010201020131010101020102010101010102020102020101020102010201010101010101010102010201010101020102013101010102010201010101010202010202010102010201020101010101010101010201020101010102010201;CP=1;
      {
        name            => 'NANO_DS1820_4Fach',
        comment         => 'self build sensor',
        id              => '77',
        knownFreqs      => '',
        developId       => 'y',
        zero            => [4,-6],
        one             => [1,-6],
        clockabs        => 250,
        format          => 'pwm',
        preamble        => 'TX',
        clientmodule    => 'CUL_TX',
        modulematch     => '^TX......',
        length_min      => '43',
        length_max      => '44',
        remove_zero     => 1,          # Removes leading zeros from output
      },
    "78"  =>  ## Remote control SEAV BeSmart S4 for BEST Cirrus Draw (07F57800) Deckenluefter
                # https://github.com/RFD-FHEM/RFFHEM/issues/909 @TheChatty
                # BeSmart_S4_534 light_toggle MU;P0=-19987;P1=205;P2=-530;P3=501;P4=-253;P6=-4094;D=01234123412123434123412123412123412121216123412341212343412341212341212341212121612341234121234341234121234121234121212161234123412123434123412123412123412121216123412341212343412341212341212341212121;CP=1;R=70;
                # BeSmart_S4_534 5min_boost   MU;P0=-23944;P1=220;P2=-529;P3=483;P4=-252;P5=-3828;D=01234123412123434123412123412121212121235123412341212343412341212341212121212123512341234121234341234121234121212121212351234123412123434123412123412121212121235123412341212343412341212341212121212123;CP=1;R=74;
                # BeSmart_S4_534 level_up     MU;P0=-8617;P1=204;P2=-544;P3=490;P4=-246;P6=-4106;D=01234123412123434123412123412121234121216123412341212343412341212341212123412121612341234121234341234121234121212341212161234123412123434123412123412121234121216123412341212343412341212341212123412121;CP=1;R=70;
                # BeSmart_S4_534 level_down   MU;P0=-14542;P1=221;P2=-522;P3=492;P4=-240;P5=-4114;D=01234123412123434123412123412121212341215123412341212343412341212341212121234121512341234121234341234121234121212123412151234123412123434123412123412121212341215123412341212343412341212341212121234121;CP=1;R=62;
      {
        name            => 'BeSmart_Sx',
        comment         => 'Remote control SEAV BeSmart S4',
        id              => '78',
        knownFreqs      => '433.92',
        zero            => [1,-2], # 250,-500
        one             => [2,-1], # 500,-250
        start           => [-14],  # -3500 + low time from last bit
        clockabs        => 250,
        reconstructBit  => '1',
        format          => 'twostate',
        preamble        => 'P78#',
        clientmodule    => 'SD_UT',
        modulematch     => '^P78#',
        length_min      => '19', # length - reconstructBit = length_min
        length_max      => '20',
      },
    "79"  =>  ## Heidemann | Heidemann HX | VTX-BELL
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
        name            => 'wireless doorbell',
        comment         => 'Heidemann | Heidemann HX | VTX-BELL',
        id              => '79',
        knownFreqs      => '',
        zero            => [-2,1],
        one             => [-1,2],
        start           => [-15,1],
        clockabs        => 330,
        format          => 'twostate',
        preamble        => 'P79#',
        clientmodule    => 'SD_BELL',
        modulematch     => '^P79#.*',
        length_min      => '12',
        length_max      => '12',
      },
    "80"  =>  ## EM1000WZ (Energy-Monitor) Funkprotokoll (868Mhz)  @HomeAutoUser | Derwelcherichbin
              # https://github.com/RFD-FHEM/RFFHEM/issues/253
              # CNT:91 CUM:14.560 5MIN:0.240 TOP:0.170   MU;P1=-417;P2=385;P3=-815;P4=-12058;D=42121212121212121212121212121212121232321212121212121232321212121212121232323212323212321232121212321212123232121212321212121232323212121212121232121212121212121232323212121212123232321232121212121232123232323212321;CP=2;R=87;
      {
        name             => 'EM1000WZ',
        comment          => 'EM (Energy-Monitor)',
        id               => '80',
        knownFreqs       => '868.35',
        one              => [1,-2],     # 800
        zero             => [1,-1],     # 400
        clockabs         => 400,
        format           => 'twostate', # not used now
        clientmodule     => 'CUL_EM',
        preamble         => 'E',
        length_min       => '104',
        length_max       => '114',
        postDemodulation => \&lib::SD_Protocols::postDemo_EM,
      },
    "81"  =>  ## Remote control SA-434-1 based on HT12E @elektron-bbs
              # P86#115 | receive   MU;P0=-485;P1=188;P2=-6784;P3=508;P5=1010;P6=-974;P7=-17172;D=0123050505630505056305630563730505056305050563056305637305050563050505630563056373050505630505056305630563730505056305050563056305637305050563050505630563056373050505630505056305630563730505056305050563056305637305050563050505630563056373050505630505056;CP=3;R=0;
              # P86#115 | receive   MU;P0=-1756;P1=112;P2=-11752;P3=496;P4=-495;P5=998;P6=-988;P7=-17183;D=0123454545634545456345634563734545456345454563456345637345454563454545634563456373454545634545456345634563734545456345454563456345637345454563454545634563456373454545634545456345634563734545456345454563456345637345454563454545634563456373454545634545456;CP=3;R=0;
              #      __        ____
              # ____|  |    __|    |
              #  Bit 1       Bit 0
              # short 500 microSec / long 1000 microSec / bittime 1500 mikroSek / pilot 12 * bittime, from that 1/3 bitlength high
      {
        name            => 'SA-434-1',
        comment         => 'remote control SA-434-1 mini 923301 based on HT12E',
        id              => '81',
        knownFreqs      => '433.92',
        one             => [-2,1],       # i.O.
        zero            => [-1,2],       # i.O.
        start           => [-35,1],      # Message is not provided as MS, worakround is start
        clockabs        => 500,
        format          => 'twostate',
        preamble        => 'P81#',
        modulematch     => '^P81#.{3}',
        clientmodule    => 'SD_UT',
        length_min      => '12',
        length_max      => '12',
      },
    "82"  =>  ## Fernotron shutters and light switches
              # https://github.com/RFD-FHEM/RFFHEM/issues/257 @zwiebert
              # down | MU;P0=-200;P1=21748;P2=-25008;P3=410;P4=-388;P5=-3189;P6=811;P7=-785;CP=3;D=012343434343434343564646464376464646437356464646437646464376435643737373764376464373564373737376437643764356437373737373737643735643737373737373737643564376464376464646464356437646437646464373735376437646464646464643537643764646464643737353737646464646437643735373764646464643737643;e;
              # stop | MU;P0=-32001;P1=441;P2=-355;P3=-3153;P4=842;P5=-757;CP=1;D=0121212121212121342424242154242424215134242424215424242154213421515151542154242151342151515154215421542134215151515151515421513421515151515151515421342154242421542424242134215424242154242151513151542424242424242421315154242424242421515131542424215424215421513154242421542421515421;e;
              # the messages received are usual missing 12 bits at the end for some reason. So the checksum byte is missing.
              # Fernotron protocol is unidirectional. Here we can only receive messages from controllers send to receivers.
      {
        name            => 'Fernotron',
        comment         => 'shutters and light switches',
        id              => '82',
        knownFreqs      => '',
        developId       => 'm',
        dispatchBin     => '1',
        paddingbits     => '1',       # disable padding
        one             => [1,-2],    # on=400us, off=800us
        zero            => [2,-1],    # on=800us, off=400us
        float           => [1,-8],    # on=400us, off=3200us. the preamble and each 10bit word has one [1,-8] in front
        pause           => [1,-1],    # preamble (5x)
        clockabs        => 400,       # 400us
        format          => 'twostate',
        preamble        => 'P82#',    # prepend our protocol number to converted message
        clientmodule    => 'Fernotron',
        length_min      => '100',     # actual 120 bit (12 x 10bit words to decode 6 bytes data), but last 20 are for checksum
        length_max      => '3360',    # 3360 bit (336 x 10bit words to decode 168 bytes data) for full timer message
      },
    "83"  =>  ## Remote control RH787T based on MOSDESIGN SEMICONDUCTOR CORP (CMOS ASIC encoder) M1EN compatible HT12E
              # Westinghouse Deckenventilator Delancey, 6 speed buttons, @zwiebelxxl
              # https://github.com/RFD-FHEM/RFFHEM/issues/250
              # 1_fan_minimum_speed      MU;P0=388;P1=-112;P2=267;P3=-378;P5=585;P6=-693;P7=-11234;D=0123035353535356262623562626272353535353562626235626262723535353535626262356262627235353535356262623562626272353535353562626235626262723535353535626262356262627235353535356262623562626272353535353562626235626262723535353535626262356262627235353535356262;CP=2;R=43;O;
              # 2_fan_low_speed          MU;P0=-176;P1=262;P2=-11240;P3=112;P5=-367;P6=591;P7=-695;D=0123215656565656717171567156712156565656567171715671567121565656565671717156715671215656565656717171567156712156565656567171715671567121565656565671717156715671215656565656717171567156712156565656567171715671567121565656565671717171717171215656565656717;CP=1;R=19;O;
              # 3_fan_medium_low_speed   MU;P0=564;P1=-392;P2=-713;P3=245;P4=-11247;D=0101010101023231023232323431010101010232310232323234310101010102323102323232343101010101023231023232323431010101010232310232323234310101010102323102323232343101010101023231023232323431010101010232310232323234310101010102323102323232343101010101023231023;CP=3;R=40;O;
              # SEAV BeEasy TX blind controller (HT12E), remote control with 2 buttons [Protocol 83]
              # https://github.com/RFD-FHEM/RFFHEM/issues/1276 @ xschmidt2 2024-10-10
              # BeEasy_TX_4D4 down       MU;P0=-25312;P1=286;P2=-354;P3=626;P4=-677;P5=-11292;D=01234123234141234123412341512341232341412341234123415123412323414123412341234151234123234141234123412341512341232341412341234123415123412323414123412341234151234123234141234123412341512341232341412341234123415123412323414123412341234151234123234141234123;CP=1;R=37;O;
              # BeEasy_TX_4D4 up         MU;P0=-24160;P1=277;P2=-363;P3=602;P4=-690;P6=-11311;D=01234123234141234123414123612341232341412341234141236123412323414123412341412361234123234141234123414123612341232341412341234141236123412323414123412341412361234123234141234123414123612341232341412341234141236123412323414123412341412361234123234141234123;CP=1;R=38;O;
      {
        name            => 'RH787T',
        comment         => 'remote control for example Westinghouse Delancey 7800140',
        id              => '83',
        knownFreqs      => '433.92',
        one             => [-2,1],
        zero            => [-1,2],
        start           => [-35,1],      # calculated 12126,31579 µS
        clockabs        => 335,          # calculated ca 336,8421053 µS short - 673,6842105µS long
        format          => 'twostate',   # there is a pause puls between words
        preamble        => 'P83#',
        clientmodule    => 'SD_UT',
        modulematch     => '^P83#.{3}',
        length_min      => '12',
        length_max      => '12',
      },
    "84"  =>  ## Funk Wetterstation Auriol IAN 283582 Version 06/2017 (Lidl), Modell-Nr.: HG02832D, 09/2018 @roobbb
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
        name            => 'IAN 283582 / TV-4848',
        comment         => 'Weatherstation Auriol IAN 283582 / Sempre 92596/65395 / TECVANCE',
        id              => '84',
        knownFreqs      => '433.92',
        one             => [3,-1],
        zero            => [1,-3],
        start           => [4,-4,4,-4,4,-4],
        clockabs        => 215,
        format          => 'twostate',
        preamble        => 'W84#',
        postamble       => '',
        clientmodule    => 'SD_WS',
        length_min      => '39',            # das letzte Bit fehlt meistens
        length_max      => '41',
      },
    "85"  =>  ## Funk Wetterstation TFA 35.1140.01 mit Temperatur-/Feuchte- und Windsensor TFA 30.3222.02 09/2018 @Iron-R
              # https://github.com/RFD-FHEM/RFFHEM/issues/266
              # Ch:1 T: 8.7 H: 85 Bat:ok   MU;P0=-509;P1=474;P2=-260;P3=228;P4=718;P5=-745;D=01212303030303012301230123012301230301212121230454545453030303012123030301230303012301212123030301212303030303030303012303012303012303012301212303030303012301230123012301230301212121212454545453030303012123030301230303012301212123030301212303030303030303;CP=3;R=46;O;
              # Ch:1 T: 7.6 H: 89 Bat:ok   MU;P0=7944;P1=-724;P2=742;P3=241;P4=-495;P5=483;P6=-248;D=01212121343434345656343434563434345634565656343434565634343434343434345634345634345634343434343434343434345634565634345656345634343456563421212121343434345656343434563434345634565656343434565634343434343434345634345634345634343434343434343434345634565634;CP=3;R=47;O;
              # TFA Wetterstation Weather PRO, Windmesser TFA 30.3251.10 2022-04-10 @ deeb
              # https://forum.fhem.de/index.php/topic,107998.msg1217772.html#msg1217772
              # Ch:1 wS: 5.9 wD: 58 Bat:ok   MU;P0=-28464;P1=493;P2=-238;P3=244;P4=-492;P5=728;P6=-732;D=01212123434343412121212343434343434123434343434343412121234121234343434343412121234123412343412123434343456565656343434341234121212121212121212123434343412121212343434343434123434343434343412121234121234343434343412121234123412343412123434343456565656343;CP=3;R=20;O;
      {
        name            => 'TFA 30.3222.02',
        comment         => 'Combisensor TFA 30.3222.02, Windsensor TFA 30.3251.10',
        id              => '85',
        knownFreqs      => '',
        one             => [2,-1],
        zero            => [1,-2],
        start           => [3,-3,3,-3,3,-3],
        clockabs        => 250,
        format          => 'twostate',
        preamble        => 'W85#',
        postamble       => '',
        clientmodule    => 'SD_WS',
        length_min      => '64',
        length_max      => '68',
      },
    "86"  =>  ### for remote controls:  Novy 840029, CAME TOP 432EV, BOSCH & Neff Transmitter SF01 01319004
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
              ### remote control Novy 840039 for Novy Cloud 230 kitchen hood:
              #  https://github.com/RFD-FHEM/RFFHEM/issues/792 | https://forum.fhem.de/index.php/topic,107867.0.html @Devirex
              # note: !! Clockpulse is 375, value from ID 86 350 it does not work !!
              # Novy 840039 | power_button          MU;P0=-749;P1=378;P2=-456;P3=684;P4=-16081;D=01230101012301232301014123012301230123012301010123012323010141230123012301230123010101230123230101412;CP=1;R=66; 
              #  Novy 840039 | cooking_light on      MU;P0=-750;P1=375;P2=-418;P3=682;P4=-16059;P5=290;P6=-5060;D=0123010123010123010123412305230123012301230101230101230101234123012301230123012301012301012301012341230123012301230123010123010123010123416505230123010123010123010123412;
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
        name            => 'BOSCH | CAME | Novy | Neff | Refsta Topdraft',
        comment         => 'remote control CAME TOP 432EV, Novy 840029 & 840039, BOSCH / Neff or Refsta Topdraft SF01 01319004',
        id              => '86',
        knownFreqs      => '433.92',
        one             => [-2,1],
        zero            => [-1,2],
        start           => [-44,1],
        clockabs        => 350,
        format          => 'twostate',
        preamble        => 'P86#',
        clientmodule    => 'SD_UT',
        #modulematch   => '^P86#.*',
        length_min      => '12',
        length_max      => '18',
      },
    "87"  =>  ## JAROLIFT Funkwandsender TDRC 16W / TDRCT 04W
              # https://github.com/RFD-FHEM/RFFHEM/issues/380 @bismosa
              # P87#E8119A34200065F100 | button=up   MS;P1=1524;P2=-413;P3=388;P4=-3970;P5=-815;P6=778;P7=-16024;D=34353535623562626262626235626262353562623535623562626235356235626262623562626262626262626262626262623535626235623535353535626262356262626262626267123232323232323232323232;CP=3;SP=4;R=226;O;m2;
              # P87#CD287247200065F100 | button=up   MS;P0=-15967;P1=1530;P2=-450;P3=368;P4=-3977;P5=-835;P6=754;D=34353562623535623562623562356262626235353562623562623562626235353562623562626262626262626262626262623535626235623535353535626262356262626262626260123232323232323232323232;CP=3;SP=4;R=229;O;
              # KeeLoq is a registered trademark of Microchip Technology Inc.
      {
        name            => 'JAROLIFT',
        comment         => 'remote control JAROLIFT TDRC_16W / TDRCT_04W',
        id              => '87',
        knownFreqs      => '433.92',
        one             => [1,-2],
        zero            => [2,-1],
        preSync         => [3.8,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1],
        sync            => [1,-10],       # this is a end marker, but we use this as a start marker
        pause           => [-40],
        clockabs        => 400,           # ca 400us
        reconstructBit  => '1',
        format          => 'twostate',
        preamble        => 'P87#',
        clientmodule    => 'SD_Keeloq',
        #modulematch     => '',
        length_min      => '72',
        length_max      => '85',
      },
    "88"  =>  ## Roto Dachfensterrolladen | Aurel Fernbedienung "TX-nM-HCS" (HCS301 chip) | three buttons -> up, stop, down
              # https://forum.fhem.de/index.php/topic,91244.0.html @bruen985
              # P88#AC3895D790EAFEF2C | button=0100   MS;P1=361;P2=-435;P4=-4018;P5=-829;P6=759;P7=-16210;D=141562156215156262626215151562626215626215621562151515621562151515156262156262626215151562156215621515151515151562151515156262156215171212121212121212121212;CP=1;SP=4;R=66;O;m0;
              # P88#9451E57890EAFEF24 | button=0100   MS;P0=-16052;P1=363;P2=-437;P3=-4001;P4=-829;P5=755;D=131452521452145252521452145252521414141452521452145214141414525252145252145252525214141452145214521414141414141452141414145252145252101212121212121212121212;CP=1;SP=3;R=51;O;m1;
              ## remote control Waeco MA650_TX (HCS300 chip) | two buttons
              # P88#4A823F65482822040 | button=blue MS;P0=344;P3=-429;P4=-3926;P5=719;P6=-823;P7=-15343;D=045306535306530653065353535353065353530606060606065306065353065306530653530653535353530653065353535353065353530653535353535306535353570303030303030303030303;CP=0;SP=4;R=38;O;m2;0;0;
              ## remote control RADEMACHER RP-S1-HS-RF11 (HCS301 chip) fuer Garagentorantrieb RolloPort S1 with two buttons
              # https://github.com/RFD-FHEM/RFFHEM/issues/612 @ D3ltorohd 20.07.2019
              # Firmware: Signalduino V 3.3.2.1-rc8 SIGNALduino cc1101 - compiled at Jan 10 2019 20:13:56
              # P88#7EFDFFDDF9C284E4C | button=0010 MS;P1=735;P2=-375;P3=377;P4=-752;P6=-3748;D=3612343434343434123434343434341234343434343434343434341234343412343434343434121234343412121212341234121212123412123434341212341212343;CP=3;SP=6;R=42;e;m1;
              # P88#C2C85435F9C284E18 | button=1000 MS;P1=385;P2=-375;P3=-3756;P4=-745;P5=766;P6=-15000;D=131414525252521452141452521452525252145214521452525252141452145214141414141452521414145252525214521452525252145252141414525252521414561212121212121212121212;CP=1;SP=3;R=54;O;s=36;m0;
              ## remote control SCS Sentinel - PR3-4207-002 (HCS300 chip) | four buttons
              # https://github.com/RFD-FHEM/RFFHEM/issues/616
              # P88#0A8423F39D6020044 | button=one   MS;P0=844;P1=-4230;P2=420;P4=-860;P6=-17704;P7=-439;D=210707070724072407240707070724070707072407070724242424242407072424240707242424072407242407070707070707240707070707070707070724070707262727272727272727272727;CP=2;SP=1;R=18;O;s=36;m0;
              # P88#00C7922B9D6020024 | button=two   MS;P1=417;P3=847;P4=-442;P5=-858;P7=-4258;D=1734343434343434341515343434151515153434153434153434341534153415151534341515153415341515343434343434341534343434343434343434341534341;CP=1;SP=7;R=25;e;m1;
              # P88#F82542039D6020014 | button=three MS;P0=-855;P1=852;P2=-433;P3=432;P5=-17236;P6=-4250;D=363030303030121212121230121230123012301212121230121212121212123030301212303030123012303012121212121212301212121212121212121212123012353232323232323232323232;CP=3;SP=6;R=29;O;s=36;m0;
              # P88#DB06531F9D6020084 | button=four  MS;P0=-17496;P1=435;P2=-438;P4=-4269;P5=-845;P6=850;D=141515621515621515626262626215156262156215626215156262621515151515156262151515621562151562626262626262156262626262626262621562626262101212121212121212121212;CP=1;SP=4;R=34;O;m1;
              ## remote enjoy motors HS-8, HS-1 / RIO HS-8 | three buttons
              # Modulation = GFSK | Frequenz = 868.302 MHz | Bandwidth = 58.036 kHz | Deviation = 25.391 kHz | Datarate = 24.796 kHz
              # https://forum.fhem.de/index.php/topic,107239.0.html | https://github.com/fhem/SD_Keeloq/issues/19
              # P88#31EB8B8A008B48058 | button=up    MS;P1=399;P2=-421;P3=-4034;P4=800;P5=-815;P6=-15516;D=1342421515424242151515154215421515154242421542151515424242154215424242424242424242154242421542151542154242154242424242424242154215161212121212121212121212;CP=1;SP=3;R=86;O;m2;
              # P88#54F58AA3008B48038 | button=down  MS;P1=415;P2=-400;P3=-4034;P4=810;P5=-803;P6=-15468;D=1342154215421542421515151542154215154242421542154215421542424215154242424242424242154242421542151542154242154242424242424242421515161212121212121212121212;CP=1;SP=3;R=84;O;m2;
              # P88#CBDA84D2008B48018 | button=stop  MS;P1=417;P2=-400;P3=-4032;P4=-789;P5=811;P6=-15540;D=1314145252145214141414521414521452145252525214525214145214525214525252525252525252145252521452141452145252145252525252525252525214161212121212121212121212;CP=1;SP=3;R=86;O;m2;
              ## remote Normstahl Garage DOORS - 1k AM HS 433MHz | AKHS 433-61 | one button @HomeAutoUser
              # P88#A4630395D55800014 | buttone one  MS;P1=314;P2=-433;P3=-3801;P4=-799;P5=680;P6=-15288;D=131452145252145252521414525252141452525252525214141452521452145214141452145214521452145214145252525252525252525252525252525252521452161212121212121212121212;CP=1;SP=3;R=56;O;m2;
              # P88#8B6988E6D55800014 | buttone one  MS;P0=684;P1=-436;P2=316;P3=-799;P4=-15280;P5=-3796;D=252301010123012323012323012301012323010101230101012323230101232301232301230123012301230123230101010101010101010101010101010101012301242121212121212121212121;CP=2;SP=5;R=18;O;m1;
              # P88#CAADF1BFD55800010 | buttone one  MS;P1=-437;P2=311;P3=-3786;P4=-806;P5=676;P6=-14940;D=232424515124512451245124512424512424242424515151242451242424242424242451245124512451245124245151515151515151515151515151515151512451562121212121212121212121;CP=2;SP=3;R=55;O;m2;
              # P88#CAD0BB54D55800010 | buttone one  MS;P0=686;P1=-425;P2=317;P3=-3796;P4=-802;P5=-14916;P6=240;D=232424010124012401242401240101010124012424240124240124012401240101242401240124012401240124240101010101010101010101010101010101012401052161616161616161212121;CP=2;SP=3;R=59;O;m2;
              ## KeeLoq is a registered trademark of Microchip Technology Inc.
      {
        name            => 'HCS300/HCS301',
        comment         => 'remote controls Aurel TX-nM-HCS, enjoy motors HS, Normstahl ,Rademacher RP-S1-HS-RF11, SCS Sentinel PR3-4207-002, Waeco MA650_TX',
        id              => '88',
        knownFreqs      => '433.92 | 868.35',
        one             => [1,-2],        # PWM bit pulse width typ. 1.2 mS
        zero            => [2,-1],        # PWM bit pulse width typ. 1.2 mS
        preSync         => [1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1, 1,-1,],  # 11 pulses preambel, 1 sync, 66 data, pause ... repeat
        sync            => [1,-10],       # Header duration typ. 4 mS
        pause           => [-39],         # Guard Time typ. 15.6 mS
        clockabs        => 400,           # Basic pulse element typ. 0.4 mS (Timings from table CODE WORD TRANSMISSION TIMING REQUIREMENTS in PDF)
        reconstructBit  => '1',
        format          => 'twostate',
        preamble        => 'P88#',
        clientmodule    => 'SD_Keeloq',
        length_min      => '65',
        length_max      => '78',
      },
    "89"  =>  ## Funk Wetterstation TFA 35.1140.01 mit Temperatur-/Feuchtesensor TFA 30.3221.02 12/2018 @Iron-R
              # ! some message are decode as protocol 37 and 61 !
              # https://github.com/RFD-FHEM/RFFHEM/issues/266
              # Ch:3 T: 5.5 H: 58 Bat:low   MU;P0=-900;P1=390;P2=-499;P3=-288;P4=193;P7=772;D=1213424213131342134242424213134242137070707013424213134242131342134242421342424213421342131342421313134213424242421313424213707070701342421313424213134213424242134242421342134213134242131313421342424242131342421;CP=4;R=43;
              # Ch:3 T: 5.4 H: 58 Bat:low   MU;P0=-491;P1=382;P2=-270;P3=179;P4=112;P5=778;P6=-878;D=01212304012123012303030123030301230123012303030121212301230301230121212121256565656123030121230301212301230303012303030123012301230303012121230123030123012121212125656565612303012123030121230123030301230303012301230123030301212123012303012301212121212565;CP=3;R=43;O;
              # Ch:3 T: 5 H: 60 Bat:low     MU;P0=-299;P1=384;P2=169;P3=-513;P5=761;P6=-915;D=01023232310101010101023565656561023231010232310102310232323102323231023231010232323101010102323231010101010102356565656102323101023231010231023232310232323102323101023232310101010232323101010101010235656565610232310102323101023102323231023232310232310102;CP=2;R=43;O;
              # Ch:2 T: 6.5 H: 62 Bat:ok    MU;P0=-32001;P1=412;P2=-289;P3=173;P4=-529;P5=777;P6=-899;D=01234345656541212341234123434121212121234123412343412343456565656121212123434343434343412343412343434121234123412343412121212123412341234341234345656565612121212343434343434341234341234343412123412341234341212121212341234123434123434565656561212121234343;CP=3;R=22;O;
              # Ch:2 T: 6.3 H: 62 Bat:ok    MU;P0=22960;P1=-893;P2=775;P3=409;P4=-296;P5=182;P6=-513;D=01212121343434345656565656565634565634565656343456563434565634343434345656565656565656342121212134343434565656565656563456563456565634345656343456563434343434565656565656565634212121213434343456565656565656345656345656563434565634345656343434343456565656;CP=5;R=22;O;
              # Ch:2 T: 6.1 H: 66 Bat:ok    MU;P0=172;P1=-533;P2=401;P3=-296;P5=773;P6=-895;D=01230101230101012323010101230123010101010101230101230101012323010101230123010301230101010101012301012301010123230101012301230101010123010101010101012301565656562323232301010101010101230101230101012323010101230123010101012301010101010101230156565656232323;CP=0;R=23;O;
      {
        name            => 'TFA 30.3221.02',
        comment         => 'temperature / humidity sensor for weatherstation TFA 35.1140.01',
        id              => '89',
        knownFreqs      => '433.92',
        one             => [2,-1],
        zero            => [1,-2],
        start           => [3,-3,3,-3,3,-3],
        clockabs        => 250,
        format          => 'twostate',
        preamble        => 'W89#',
        postamble       => '',
        clientmodule    => 'SD_WS',
        length_min      => '40',
        length_max      => '40',
      },
    "90"  =>  ## mumbi AFS300-s / manax MX-RCS250 (CP 258-298)
              # https://forum.fhem.de/index.php/topic,94327.15.html @my-engel @peterboeckmann
              # A  AN    MS;P0=-9964;P1=273;P4=-866;P5=792;P6=-343;D=10145614141414565656561414561456561414141456565656561456141414145614;CP=1;SP=0;R=35;O;m2;
              # A  AUS   MS;P0=300;P1=-330;P2=-10160;P3=804;P7=-840;D=02073107070707313131310707310731310707070731313107310731070707070707;CP=0;SP=2;R=23;O;m1;
              # B  AN    MS;P1=260;P2=-873;P3=788;P4=-351;P6=-10157;D=16123412121212343434341212341234341212121234341234341234121212341212;CP=1;SP=6;R=21;O;m2;
              # B  AUS   MS;P1=268;P3=793;P4=-337;P6=-871;P7=-10159;D=17163416161616343434341616341634341616161634341616341634161616343416;CP=1;SP=7;R=24;O;m2;
      {
        name            => 'mumbi | MANAX',
        comment         => 'remote control mumbi RC-10, MANAX MX-RCS250',
        id              => '90',
        knownFreqs      => '433.92',
        one             => [3,-1],
        zero            => [1,-3],
        sync            => [1,-36],
        clockabs        => 280,
        format          => 'twostate',
        preamble        => 'P90#',
        length_min      => '33',
        length_max      => '36',
        clientmodule    => 'SD_UT',
        modulematch     => '^P90#.*',
      },
    "91"  =>  ## Atlantic Security / Focus Security China Devices
              # https://forum.fhem.de/index.php/topic,58397.msg876862.html#msg876862 @Harst @jochen_f
              # normal    MU;P0=800;P1=-813;P2=394;P3=-410;P4=-3992;D=0123030303030303012121230301212304230301212301230301212123012301212303012301230303030303030121212303012123042303012123012303012121230123012123030123012303030303030301212123030121230;CP=2;R=46;
              # normal    MU;P0=406;P1=-402;P2=802;P3=-805;P4=-3994;D=012123012301212121212121230303012123030124012123030123012123030301230123030121230123012121212121212303030121230301240121230301230121230303012301230301212301230121212121212123030301212303012;CP=0;R=52;
              # warning   MU;P0=14292;P1=-10684;P2=398;P3=-803;P4=-406;P5=806;P6=-4001;D=01232324532453232454532453245454532324545323232453245324562454532324532454532323245324532324545324532454545323245453232324532453245624545323245324545323232453245323245453245324545453232454532323245324532456245453232453245453232324532453232454532453245454;CP=2;R=50;O;
      {
        name            => 'Atlantic security',
        comment         => 'example sensor MD-210R | MD-2018R | MD-2003R (MU decode)',
        id              => '91',
        knownFreqs      => '433.92 | 868.35',
        one             => [-2,1],
        zero            => [-1,2],
        start           => [-10,1],
        clockabs        => 400,
        format          => 'twostate',
        preamble        => 'P91#',
        length_min      => '35', # 36 - reconstructBit = 35
        length_max      => '36',
        clientmodule    => 'SD_UT',
        #modulematch     => '^P91#.*',
        reconstructBit  => '1',
      },
    "91.1" => ## Atlantic Security / Focus Security China Devices
              # https://forum.fhem.de/index.php/topic,58397.msg878008.html#msg878008 @Harst @jochen_f
              # warning   MS;P0=-399;P1=407;P2=820;P3=-816;P4=-4017;D=14131020231020202313131023131313131023102023131313131310202313131020202313;CP=1;SP=4;O;m0;
              # warning   MS;P1=392;P2=-824;P3=-416;P4=804;P5=-4034;D=15121343421343434212121342121212121342134342121212121213434212121343434212;CP=1;SP=5;e;m2;
      {
        name            => 'Atlantic security',
        comment         => 'example sensor MD-210R | MD-2018R | MD-2003R (MS decode)',
        id              => '91.1',
        knownFreqs      => '433.92 | 868.35',
        one             => [-2,1],
        zero            => [-1,2],
        sync            => [-10,1],
        clockabs        => 400,
        reconstructBit  => '1',
        format          => 'twostate',
        preamble        => 'P91#',
        length_min      => '32',
        length_max      => '36',
        clientmodule    => 'SD_UT',
        #modulematch     => '^P91.1#.*',
      },
    "92"  =>  ## KRINNER Lumix - LED X-MAS
              # https://github.com/RFD-FHEM/RFFHEM/issues/452 | https://forum.fhem.de/index.php/topic,94873.msg876477.html?PHPSESSID=khp4ja64pcqa5gsf6gb63l1es5#msg876477 @gestein
              # on    MU;P0=24188;P1=-16308;P2=993;P3=-402;P4=416;P5=-967;P6=-10162;D=0123234545454523234523234545454545454545232623452345454545454523234523234545454523234523234545454545454545232623452345454545454523234523234545454523234523234545454545454545232623452345454545454523234523234545454523234523234545454545454545232;CP=4;R=25;
              # off   MU;P0=11076;P1=-20524;P2=281;P3=-980;P4=982;P5=-411;P6=408;P7=-10156;D=0123232345456345456363636363636363634745634563636363636345456345456363636345456345456363636363636363634745634563636363636345456345456363636345456345456363636363636363634745634563636363636345456345456363636345456345456363636363636363634;CP=6;R=38;
      {
        name            => 'KRINNER Lumix',
        comment         => 'remote control LED X-MAS',
        id              => '92',
        knownFreqs      => '433.92',
        zero            => [1,-2],
        one             => [2,-1],
        start           => [2,-24],
        clockabs        => 420,
        format          => 'twostate',
        preamble        => 'P92#',
        length_min      => '32',
        length_max      => '32',
        clientmodule    => 'SD_UT',
        #modulematch     => '^P92#.*',
      },
    "93"  =>  ## ESTO Lighting GmbH | remote control KL-RF01 with 9 buttons (CP 375-395)
              # https://github.com/RFD-FHEM/RFFHEM/issues/449 @daniel89fhem 
              # light_color_cold_white   MS;P1=376;P4=-1200;P5=1170;P6=-409;P7=-12224;D=17141414561456561456565656145656141414145614141414565656145656565614;CP=1;SP=7;R=231;e;m0; 
              # dimup                    MS;P1=393;P2=-1174;P4=1180;P5=-401;P6=-12222;D=16121212451245451245454545124545124545451212121212121212454545454512;CP=1;SP=6;R=243;e;m0;
              # dimdown                  MS;P0=397;P1=-385;P2=-1178;P3=1191;P4=-12230;D=04020202310231310231313131023131023131020202020202020231313131313102;CP=0;SP=4;R=250;e;m0;
      {
        name            => 'ESTO Lighting GmbH',
        comment         => 'remote control KL-RF01',
        id              => '93',
        knownFreqs      => '433.92',
        one             => [3,-1],
        zero            => [1,-3],
        sync            => [1,-32],
        clockabs        => 385,
        format          => 'twostate',
        preamble        => 'P93#',
        length_min      => '32',           # 2. MSG: 32 Bit, bleibt so
        length_max      => '36',           # 1. MSG: 33 Bit, wird verlängert auf 36 Bit
        clientmodule    => 'SD_UT',
        #modulematch     => '^P93#.*',
      },
    "94"  =>  # Atech wireless weather station (vermutlicher Name: WS-308)
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
    "95"  =>  # Techmar / Garden Lights Fernbedienung, 6148011 Remote control + 12V Outdoor receiver
              # https://github.com/RFD-FHEM/RFFHEM/issues/558 @BlackcatSandy
              # Group_1_on    MU;P0=-972;P1=526;P2=-335;P3=-666;D=01213131312131313121212121312121313131313121312131313121313131312121212121312121313131313121313121212101213131312131313121212121312121313131313121312131313121313131312121212121312121313131313121313121212101213131312131313121212121312121313131313121312131;CP=1;R=44;O;
              # Group_5_on    MU;P0=-651;P1=530;P2=-345;P3=-969;D=01212121312101010121010101212121210121210101010101210121010101210101010121212121012121210101010121010101212101312101010121010101212121210121210101010101210121010101210101010121212121012121210101010121010101212121312101010121010101212121210121210101010101;CP=1;R=24;O;
              # Group_8_off   MU;P0=538;P1=-329;P2=-653;P3=-964;D=01020301020202010202020101010102010102020202020102010202020102020202010101010101010201020202020202010202010301020202010202020101010102010102020202020102010202020102020202010101010101010201020202020202010201010301020202010202020101010102010102020202020102;CP=0;R=19;O;
      {
        name            => 'Techmar',
        comment         => 'Garden Lights remote control',
        id              => '95',
        knownFreqs      => '433.92',
        one             => [5,-6],  # 550,-660
        zero            => [5,-3],  # 550,-330
        start           => [5,-9],  # 550,-990
        clockabs        => 110,
        format          => 'twostate',
        preamble        => 'P95#',
        clientmodule    => 'SD_UT',
        length_min      => '50',
        length_max      => '50',
      },
    "96"  =>  # Funk-Gong | Taster Grothe Mistral SE 03.1 / 01.1, Innenteil Grothe Mistral 200M(E)
              # https://forum.fhem.de/index.php/topic,64251.msg940593.html?PHPSESSID=nufcvvjobdd8r7rgr0cq3qkrv0#msg940593 @coolheizer
              # SD_BELL_104762 Alarm        MC;LL=-430;LH=418;SL=-216;SH=226;D=23C823B1401F8;C=214;L=49;R=53;
              # SD_BELL_104762 ring         MC;LL=-439;LH=419;SL=-221;SH=212;D=238823B1001F8;C=215;L=49;R=69;
              # SD_BELL_104762 ring low bat MC;LL=-433;LH=424;SL=-214;SH=210;D=238823B100248;C=213;L=49;R=65;
              # SD_BELL_0253B3 Alarm        MC;LL=-407;LH=451;SL=-195;SH=239;D=23C129D9E78;C=215;L=41;R=241;
              # SD_BELL_0253B3 ring         MC;LL=-412;LH=458;SL=-187;SH=240;D=238129D9A78;C=216;L=41;R=241;
              # SD_BELL_024DB5 Alarm        MC;LL=-415;LH=454;SL=-200;SH=226;D=23C126DAE58;C=215;L=41;R=246;
              # SD_BELL_024DB5 ring         MC;LL=-409;LH=448;SL=-172;SH=262;D=238126DAA58;C=215;L=41;R=238;
      {
        name            => 'Grothe Mistral SE',
        comment         => 'Wireless doorbell Grothe Mistral SE 01.1 or 03.1',
        id              => '96',
        knownFreqs      => '868.35',
        clockrange      => [170,260],
        format          => 'manchester',
        clientmodule    => 'SD_BELL',
        modulematch     => '^P96#',
        preamble        => 'P96#',
        length_min      => '40',
        length_max      => '49',
        method          => \&lib::SD_Protocols::mcBit2Grothe,
      },
    "97"  =>  # Momento, remote control for wireless digital picture frame - elektron-bbs 2020-03-21
              # Short press repeatedly message 3 times, long press repeatedly until release.
              # When sending, the original message is not reproduced, but the recipient also reacts to the messages generated in this way.
              # Momento_0000064 play/pause MU;P0=-294;P1=237;P2=5829;P3=-3887;P4=1001;P5=-523;P6=504;P7=-995;D=01010101010101010101010234545454545454545454545454545454545454545456767454567454545456745456745456745454523454545454545454545454545454545454545454545676745456745454545674545674545674545452345454545454545454545454545454545454545454567674545674545454567454;CP=4;R=45;O; 
              # Momento_0000064 power      MU;P0=-998;P1=-273;P2=256;P3=5830;P4=-3906;P5=991;P6=-527;P7=508;D=12121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121345656565656565656565656565656565656565656567070565670565656565670567056565670707034565656565656565656565656565656565656565656707056567;CP=2;R=40;O;
              # Momento_0000064 up         MU;P0=-1005;P1=-272;P2=258;P3=5856;P4=-3902;P5=1001;P6=-520;P7=508;D=0121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121213456565656565656565656565656565656565656565670705656705656567056565670565670567056345656565656565656565656565656565656565656567070565;CP=2;R=63;O;
      {
        name            => 'Momento',
        comment         => 'Remote control for wireless digital picture frame',
        id              => '97',
        knownFreqs      => '433.92',
        one             => [2,-4],    # 500, -1000
        zero            => [4,-2],    # 1000, -500
        start           => [23,-15],  # 5750, -3750
        clockabs        => 250,
        format          => 'twostate',
        preamble        => 'P97#',
        clientmodule    => 'SD_UT',
        length_min      => '40',
        length_max      => '40',
      },
    "98"  =>  # Funk-Tuer-Gong: Modell GEA-028DB, Ningbo Rui Xiang Electrical Co.,Ltd., Vertrieb durch Walter Werkzeuge Salzburg GmbH, Art. Nr. K612021A
              # https://forum.fhem.de/index.php/topic,109952.0.html 2020-04-12
              # SD_BELL_6A2C   MU;P0=1488;P1=-585;P2=520;P3=-1509;P4=1949;P5=-5468;CP=2;R=38;D=01232301230123010101230123230101454501232301230123010101230123230101454501232301230123010101230123230101454501232301230123010101230123230101454501232301230123010101230123230101454501232301230123010101230123230101454501232301230123010101230123230101454501;O;
              # SD_BELL_6A2C   MU;P0=-296;P1=-1542;P2=1428;P3=-665;P4=483;P5=1927;P6=-5495;P7=92;CP=4;R=31;D=1234141232356562341412341234123232341234141232356562341412341234123232341234141232356562341412341234123232341234141232356562341412341234123232341234141232356562341412341234123232341234141232356562341412341234123232341234141232370;e;i;
      {
        name            => 'GEA-028DB',
        comment         => 'Wireless doorbell',
        knownFreqs      => '433.92',
        id              => '98',
        one             => [1,-3],
        zero            => [3,-1],
        start           => [4,-11,4,-11],
        clockabs        => 500,
        format          => 'twostate',
        clientmodule    => 'SD_BELL',
        modulematch     => '^P98#',
        preamble        => 'P98#',
        length_min      => '16',
        length_max      => '16',
      },
    "99"  =>  # NAVARIS touch light switch Model No.: 44344.04
              # https://github.com/RFD-FHEM/RFFHEM/issues/828
              # Navaris_211073   MU;P0=-302;P1=180;P2=294;P3=-208;P4=419;P5=-423;D=01023101010101023232310102323451010231010101023101010231010101010232323101023234510102310101010231010102310101010102323231010232345101023101010102310101023101010101023232310102323451010231010101023101010231010101010232323101023234510102310101010231010102;CP=1;R=36;O;
              # Navaris_13F8E3   MU;P0=406;P1=-294;P2=176;P3=286;P4=-191;P6=-415;D=01212134212134343434343434212121343434212121343406212121342121343434343434342121213434342121213434062121213421213434343434343421212134343421212134340621212134212134343434343434212121343434212121343406212121342121343434343434342121213434342121213434062121;CP=2;R=67;O;
      {
        name            => 'Navaris 44344.04',
        comment         => 'Wireless touch light switch',
        knownFreqs      => '433.92',
        id              => '99',
        one             => [3,-2],
        zero            => [2,-3],
        start           => [4,-4],
        clockabs        => 100,
        format          => 'twostate',
        clientmodule    => 'SD_UT',
        modulematch     => '^P99#',
        preamble        => 'P99#',
        length_min      => '24',
        length_max      => '24',
      },
    "100" =>  # Lacrosse, Mode 1 - IT+
              # https://forum.fhem.de/index.php/topic,106594.msg1034378.html#msg1034378 @Ralf9
              # ID=100, addr=42 temp=23.6 hum=44 bat=0 batInserted=128   MN;D=9AA6362CC8AAAA000012F8F4;R=4;
      {
        name            => 'Lacrosse mode 1',
        comment         => 'example: TX25-IT,TX27-IT,TX29-IT,TX29DTH-IT,TX37,30.3143.IT,30.3144.IT',
        id              => '100',
        knownFreqs      => '868.3',
        datarate        => '17257.69',
        sync            => '2DD4',
        modulation      => '2-FSK',
        regexMatch      => qr/^9/,
        register        => ['0001','022E','0341','042D','05D4','0605','0780','0800','0D21','0E65','0F6A','1089','115C','1202','1322','14F8','1556','1916','1B43','1C68'],
        rfmode          => 'Lacrosse_mode1',
        clientmodule    => 'LaCrosse',
        length_min      => '10',
        method          => \&lib::SD_Protocols::ConvLaCrosse,
      },
    "101" =>  # ELV PCA 301
              # https://wiki.fhem.de/wiki/PCA301_Funkschaltsteckdose_mit_Energieverbrauchsmessung
              # MN;D=0405019E8700AAAAAAAA0F13AA16ACC0540AAA49C814473A2774D208AC0B0167;N=3;R=6;
              # MN;D=010503B7A101AAAAAAAA7492AA9885E53246E91113F897A4F80D30C8DE602BDF;N=3;
      {
        name            => 'PCA 301',
        comment         => 'Energy socket',
        id              => '101',
        knownFreqs      => '868.950',
        datarate        => '6620.41',
        sync            => '2DD4',
        modulation      => '2-FSK',
        register        => ['0001','0246','0307','042D','05D4','06FF','0700','0802','0D21','0E6B','0FD0','1088','110B','1206','1322','14F8','1553','1700','1818','1916','1B43','1C68','1D91','23ED','2517','2611'],
        rfmode          => 'PCA301',
        clientmodule    => 'PCA301',
        dispatchequals  => 'true',
        length_min      => '24',
        method          => \&lib::SD_Protocols::ConvPCA301,
      },
    "102" =>  # KoppFreeControl
              # https://forum.fhem.de/index.php/topic,106594.msg1008936.html?PHPSESSID=er8d3f2ar1alq3rcijmu4efffo#msg1008936 @Ralf9
              # https://wiki.fhem.de/wiki/Kopp_Allgemein
              # MN;D=07FA5E1721CC0F02FE000000000000;
      {
        name            => 'KoppFreeControl',
        comment         => 'example: remotes, switches',
        id              => '102',
        knownFreqs      => '868.3',
        datarate        => '4785.5',
        sync            => 'AA54',
        modulation      => 'GFSK',
        regexMatch      => qr/^0/,   # ToDo, check! fuer eine regexp Pruefung am Anfang vor dem method Aufruf
        register        => ['0001','012E','0246','0304','04AA','0554','060F','07E0','0800','0900','0A00','0B06','0C00','0D21','0E65','0F6A','1097','1183','1216','1363','14B9','1547','1607','170C','1829','1936','1A6C','1B07','1C40','1D91','1E87','1F6B','20F8','2156','2211','23EF','240A','253D','261F','2741'],
        rfmode          => 'KOPP_FC',
        clientmodule    => 'KOPP_FC',
        method          => \&lib::SD_Protocols::ConvKoppFreeControl,
      },
    "103" =>  # Lacrosse Mode 2 - IT+
              # https://forum.fhem.de/index.php/topic,106278.msg1048506.html#msg1048506 @Ralf9
              # ID=103, addr=40 temp=19.2 hum=47 bat=0 batInserted=0   MN;D=9A05922F8180046818480800;N=2;
              # https://forum.fhem.de/index.php/topic,106594.msg1034378.html#msg1034378 @Ralf9
              # ID=103, addr=52 temp=21.5 hum=47 bat=0 batInserted=0   MN;D=9D06152F5484791062004090;N=2;
      {
        name            => 'Lacrosse mode 2',
        comment         => 'example: TX35-IT,TX35DTH-IT,30.3155WD,30.3156WD,EMT7110',
        id              => '103',
        knownFreqs      => '868.3',
        datarate        => '9596',
        sync            => '2DD4',
        modulation      => '2-FSK',
        regexMatch      => qr/^9/,
        register        => ['0001','022E','0341','042D','05D4','0605','0780','0800','0D21','0E65','0F6A','10C8','1183','1202','1322','14F8','1542','1916','1B43','1C68'],
        rfmode          => 'Lacrosse_mode2',
        clientmodule    => 'LaCrosse',
        length_min      => '10',
        method          => \&lib::SD_Protocols::ConvLaCrosse,
      },
    "104" =>  # Remote control TR60C-1 with touch screen from Satellite Electronic (Zhongshan) Ltd., Importer Westinghouse Lighting for ceiling fan Bendan
              # https://forum.fhem.de/index.php?topic=53282.msg1045428#msg1045428 phoenix-anasazi 2020-04-21
              # TR60C1_0 light_off_fan_off  MU;P0=18280;P1=-737;P2=419;P3=-331;P4=799;P5=-9574;P6=-7080;D=012121234343434341212121212121252121212123434343434121212121212125212121212343434343412121212121212521212121234343434341212121212121252121212123434343434121212121212126;CP=2;R=2;
              # TR60C1_9 light_off_fan_4    MU;P0=14896;P1=-751;P2=394;P3=-370;P4=768;P5=-9572;P6=-21472;D=0121234123434343412121212121212523412123412343434341212121212121252341212341234343434121212121212125234121234123434343412121212121212523412123412343434341212121212121252341212341234343434121212121212126;CP=2;R=4;
              # TR60C1_B light_on_fan_2     MU;P0=-96;P1=152;P2=-753;P3=389;P4=-374;P5=769;P6=-9566;P7=-19920;D=012345454523232345454545634523454523234545452323234545454563452345452323454545232323454545456345234545232345454523232345454545634523454523234545452323234545454563452345452323454545232323454545457;CP=3;R=1;
              # https://github.com/RFD-FHEM/RFFHEM/issues/842
      {
        name            => 'TR60C-1',
        comment         => 'Remote control for example Westinghouse Bendan 77841B',
        id              => '104',
        knownFreqs      => '433.92',
        one             => [-1,2],  #  -380,760
        zero            => [-2,1],  #  -760,380
        start           => [-25,1], # -9500,380
        clockabs        => 380,
        format          => 'twostate',
        clientmodule    => 'SD_UT',
        modulematch     => '^P104#',
        preamble        => 'P104#',
        length_min      => '16',
        length_max      => '16',
      },
    "105" =>  # Remote control BF-301 from Shenzhen BOFU Mechanic & Electronic Co., Ltd.
              # Protocol description found on https://github.com/akirjavainen/markisol/blob/master/Markisol.ino
              # original remotes repeat 8 (multi) or 10 (single) times by default
              # https://github.com/RFD-FHEM/RFFHEM/issues/861 stsirakidis 2020-06-27
              # BF_301_FAD0 down   MU;P0=-697;P1=5629;P2=291;P3=3952;P4=-2459;P5=1644;P6=-298;P7=689;D=34567676767676207620767620762020202076202020762020207620202020207676762076202020767614567676767676207620767620762020202076202020762020207620202020207676762076202020767614567676767676207620767620762020202076202020762020207620202020207676762076202020767614;CP=2;R=41;O;
              # BF_301_FAD0 stop   MU;P0=5630;P1=3968;P2=-2458;P3=1642;P4=-285;P5=690;P6=282;P7=-704;D=12345454545454675467545467546767676754676767546754675467676767675454546754676767675402345454545454675467545467546767676754676767546754675467676767675454546754676767675402345454545454675467545467546767676754676767546754675467676767675454546754676767675402;CP=6;R=47;O;
              # BF_301_FAD0 up     MU;P0=-500;P1=5553;P2=-2462;P3=1644;P4=-299;P5=679;P6=298;P7=-687;D=01234545454545467546754546754676767675467676767675454546767676767545454675467546767671234545454545467546754546754676767675467676767675454546767676767545454675467546767671234545454545467546754546754676767675467676767675454546767676767545454675467546767671;CP=6;R=48;O;
      {
        name            => 'BF-301',
        comment         => 'Remote control',
        id              => '105',
        knownFreqs      => '433.92',
        one             => [2,-1],       # 660,-330
        zero            => [1,-2],       # 330,-660
        start           => [17,-7,5,-1], # 5610,-2310,1650,-330
        clockabs        => 330,
        format          => 'twostate',
        clientmodule    => 'SD_UT',
        modulematch     => '^P105#',
        preamble        => 'P105#',
        length_min      => '40',
        length_max      => '40',
      },
    "106" =>  ## BBQ temperature sensor GT-TMBBQ-01s (Sender), GT-TMBBQ-01e (Empfaenger)
              # https://forum.fhem.de/index.php/topic,114437.0.html KoelnSolar 2020-09-23
              # https://github.com/RFD-FHEM/RFFHEM/issues/892 Ralf9 2020-09-24
              # SD_WS_106_T  T: 22.6  MS;P0=525;P1=-2051;P3=-8905;P4=-4062;D=0301010401010404010101040401010401040401040404;CP=0;SP=3;R=35;e;b=2;m0;
              # SD_WS_106_T  T: 88.1  MS;P1=-8514;P2=488;P3=-4075;P4=-2068;D=2123242423232423242423242324232323232423242324;CP=2;SP=1;R=31;e;b=70;s=4;m0;
              # SD_WS_106_T  T: 97.8  MS;P1=-9144;P2=469;P3=-4101;P4=-2099;D=2123242423232423242423242323232423242423242424;CP=2;SP=1;R=58;O;b=70;s=4;m0;
              # Sensor sends every 5 seconds 1 message.
      {
        name            => 'GT-TMBBQ-01',
        comment         => 'BBQ temperature sensor',
        id              => '106',
        one             => [1,-8],  # 500,-4000
        zero            => [1,-4],  # 500,-2000
        sync            => [1,-18], # 500,-9000
        clockabs        => 500,
        format          => 'twostate',
        preamble        => 'W106#',
        clientmodule    => 'SD_WS',
        modulematch     => '^W106#',
        length_min      => '22',
        length_max      => '22',
      },
    "107" =>  ## Fine Offset WH51, ECOWITT WH51, MISOL/1, Froggit DP100 Soil Moisture Sensor use with FSK 433.92 MHz
              # https://forum.fhem.de/index.php/topic,109056.0.html
              # SD_WS_107_H_00C6BF H: 31  MN;D=5100C6BF107F1FF8BBFFFFFFEE22;R=14;
              # SD_WS_107_H_00C6BF H: 34  MN;D=5100C6BF107F22F8C3FFFFFF0443;R=14;
              # SD_WS_107_H_00C6BF H: 35  MN;D=5100C6BF107F23F8C7FFFFFF5DA1;R=14;
      {
        name            => 'WH51 433.92 MHz',
        comment         => 'Fine Offset WH51, ECOWITT WH51, MISOL/1, Froggit DP100 Soil moisture sensor',
        id              => '107',
        knownFreqs      => '433.92',
        datarate        => '17257.69',
        sync            => '2DD4',
        modulation      => '2-FSK',
        regexMatch      => qr/^51/, # Family code 0x51 (ECOWITT/FineOffset WH51)
        preamble        => 'W107#',
        register        => ['0001','022E','0343','042D','05D4','060E','0780','0800','0D10','0EB0','0F71','10A9','115C','1202','1322','14F8','1543','1916','1B43','1C68'],
        rfmode          => 'Fine_Offset_WH51_434',
        clientmodule    => 'SD_WS',
        length_min      => '28',
        length_max      => '38', # WH68 - length_min => '32', length_max => '38',
      },
    "107.1" =>  # Fine Offset WH51, ECOWITT WH51, MISOL/1, Froggit DP100 Soil Moisture Sensor use with FSK 868.35 MHz
      {
        name            => 'WH51 868.35 MHz',
        comment         => 'Fine Offset WH51, ECOWITT WH51, MISOL/1, Froggit DP100 Soil moisture sensor',
        id              => '107.1',
        knownFreqs      => '868.35',
        datarate        => '17257.69',
        sync            => '2DD4',
        modulation      => '2-FSK',
        regexMatch      => qr/^51/, # Family code 0x51 (ECOWITT/FineOffset WH51)
        preamble        => 'W107#',
        register        => ['0001','022E','0343','042D','05D4','060E','0780','0800','0D21','0E65','0FE8','10A9','115C','1202','1322','14F8','1543','1916','1B43','1C68'],
        rfmode          => 'Fine_Offset_WH51_868',
        clientmodule    => 'SD_WS',
        length_min      => '28',
        length_max      => '38', # WH68 - length_min => '32', length_max => '38',
      },
    "108" =>  ## BRESSER 5-in-1 Weather Center, Bresser Professional Rain Gauge, Fody E42, Fody E43 - elektron-bbs 2021-05-02
              # https://github.com/RFD-FHEM/RFFHEM/issues/607
              # https://forum.fhem.de/index.php/topic,106594.msg1151467.html#msg1151467
              # T: 11 H: 43 W: 1.7 R: 7.6     MN;D=E6837FD73FE8EFEFFEBC89FFFF197C8028C017101001437600000001;R=230;
              # elektron-bbs
              # T: 20.7 H: 28 W: 0.8 R: 354.4  MN;D=E7527FF78FF7EFF8FDD7BBCAFF18AD80087008100702284435000002;R=213;
              # T: -2.8 H: 78 W: 0 R: 354.4    MN;D=E8527FFF2FFFEFD7FF87BBCAF717AD8000D000102800784435080000;R=214;
              # T: 8 H: 88 W: 1.3 R: 364.8     MN;D=E6527FEB0FECEF7FFF77B7C9FF19AD8014F013108000884836000003;R=211;
      {
        name            => 'Bresser 5in1',
        comment         => 'BRESSER 5-in-1 weather center, rain gauge, Fody E42, Fody E43',
        id              => '108',
        knownFreqs      => '868.300',
        datarate        => '8.232',
        sync            => '2DD4',
        modulation      => '2-FSK',
        rfmode          => 'Bresser_5in1',
        regexMatch      => qr/^[a-fA-F0-9]/,
        register        => ['0001','022E','0346','042D','05D4','061A','07C0','0800','0D21','0E65','0F6A','1088','114C','1202','1322','14F8','1551','1916','1B43','1C68'],
        preamble        => 'W108#',
        clientmodule    => 'SD_WS',
        length_min      => '52',
        method          => \&lib::SD_Protocols::ConvBresser_5in1,
      },
    "109" =>  ## Rojaflex HSR-15, HSTR-15,
              # only tested remote control HSR-15 in mode bidirectional
              # https://github.com/RFD-FHEM/RFFHEM/issues/955 - Hofyyy 2021-04-18
              # SD_Rojaflex_3122FD2_9 down   MN;D=083122FD298A018A8E;R=0;
              # SD_Rojaflex_3122FD2_9 stop   MN;D=083122FD290A010A8E;R=244;
              # SD_Rojaflex_3122FD2_9 up     MN;D=083122FD291A011AAE;R=249;
      {
        name            => 'Rojaflex',
        comment         => 'Rojaflex shutter',
        id              => '109',
        knownFreqs      => '433.92',
        datarate        => '9.9926',
        sync            => 'D391D391',
        modulation      => 'GFSK',
        rfmode          => 'Rojaflex',
        regexMatch      => qr/^08/,
        register        => ['0007','022E','0302','04D3','0591','060C','0788','0805','0D10','0EB0','0F71','10C8','1193','1213','1322','14F8','1535','170F','1916','1B43','1C40','2156','2211'],
        preamble        => 'P109#',
        clientmodule    => 'SD_Rojaflex',
        length_min      => '18',
        length_max      => '18',
      },
    "110" =>  # ADE WS1907 Wetterstation mit Funk-Regenmesser 
              # https://github.com/RFD-FHEM/RFFHEM/issues/965 docolli 2021-05-14
              # T: 16.3 R: 26.6   MU;P0=970;P1=-112;P2=516;P3=-984;P4=2577;P5=-2692;P6=7350;D=01234343450503450503434343434505034343434343434343434343434343434505050503450345034343434343450345050345034505034503456503434505050343434343450503450503434343434505034343434343434343434343434343434505050503450345034343434343450345050345034505034503456503;CP=0;R=12;O;
              # T: 12.6 R: 80.8   MU;P0=7344;P1=384;P2=-31380;P3=272;P4=-972;P5=2581;P6=-2689;P7=990;D=12345454545676745676745454545456745454545456767676745454545454545676767456745456767674545454545674567674545456745454545606745456767674545454545676745676745454545456745454545456767676745454545454545676767456745456767674545454545674567674545456745454545606;CP=7;R=19;O;
              # T: 11.8 R: 82.1   MU;P0=-5332;P1=6864;P2=-2678;P3=994;P4=-977;P5=2693;D=01234545232323454545454523234523234545454545234545454523452345232345454545454523232345452323454545454545454523452323454545452323454521234545232323454545454523234523234545454545234545454523452345232345454545454523232345452323454545454545454523452323454545;CP=3;R=248;O;
              # The sensor sends about every 45 seconds.
      {
        name            => 'ADE_WS_1907',
        comment         => 'Weather station with rain gauge',
        id              => '110',
        knownFreqs      => '433.92',
        one             => [-3,1], # 2700,-900
        zero            => [-1,3], # -900,2700
        start           => [8],    # 7200
        clockabs        => 900,
        format          => 'twostate',
        clientmodule    => 'SD_WS',
        modulematch     => '^W110#',
        preamble        => 'W110#',
        reconstructBit   => '1',
        length_min      => '65',
        length_max      => '66',
      },
    "111" =>  # Water Tank Level Monitor TS-FT002
              # https://github.com/RFD-FHEM/RFFHEM/issues/977 docolli 2021-06-05
              # T: 16.8 D: 111   MU;P0=-21110;P1=484;P2=-971;P3=-488;D=01213121212121213121312121312121213131312131313131212131313131312121212131313121313131213131313121213131312131313131313131313131212131312131312101213121212121213121312121312121213131312131313131212131313131312121212131313121313131213131313121213131312131;CP=1;R=26;O;
              # T: 19 D: 47      MU;P0=-31628;P1=469;P2=-980;P3=-499;P4=-22684;D=01213121212121213121312121312121213131312131313131213131313131312121212131313121312121213131313131312131312131313131313131313131312121312131312141213121212121213121312121312121213131312131313131213131313131312121212131313121312121213131313131312131312131;CP=1;R=38;O;
              # T: 20 D: 47      MU;P0=-5980;P1=464;P2=-988;P3=-511;P4=-22660;D=01213121212121213121312121312121213131312131313131213131313131312121212131313121313131213131313121312131312131313131313131313131213131312131312141213121212121213121312121312121213131312131313131213131313131312121212131313121313131213131313121312131312131;CP=1;R=38;O;
              # The sensor sends normally every 180 seconds.
      {
        name            => 'TS-FT002',
        comment         => 'Water tank level monitor with temperature',
        id              => '111',
        knownFreqs      => '433.92',
        one             => [1,-2], # 480,-960
        zero            => [1,-1], # 480,-480
        start           => [1,-2, 1,-1, 1,-2, 1,-2, 1,-2, 1,-2, 1,-2], # Sync 101.1111
        clockabs        => 480,
        format          => 'twostate',
        clientmodule    => 'SD_WS',
        modulematch     => '^W111#',
        preamble        => 'W111#5F', # add sync 0101.1111
        length_min      => '64',
        length_max      => '64',
      },
    "112" =>  ## AVANTEK DB-LE
              # Wireless doorbell & LED night light
              # Sample: 20 Microseconds | 3 Repeats with ca. 1,57ms Pause
              # A7129 -> FSK/GFSK Sub 1GHz Transceiver
              #
              #       PPPPPSSSSDDDDDDDDDD
              #       |    |   |--------> Data
              #       |    ||||---------> Sync
              #       |||||-------------> Preambel
              #
              # URH:  aaaaa843484608a4224
              # FHEM: MN;D=08C114844FDA5CA2;R=48;
              #       MN;D=08C11484435D873B;R=47;
              # !!! receiver hardware is required to complete in SD_BELL module !!!
      {
        name            => 'Avantek',
        comment         => 'Wireless doorbell & LED night light',
        id              => '112',
        knownFreqs      => '433.3',
        datarate        => '50.087',
        sync            => '0869',
        modulation      => '2-FSK',
        rfmode          => 'Avantek',
        register        => ['0001','0246','0301','0408','0569','06FF','0780','0802','0D10','0EAA','0F56','108A','11F8','1202','1322','14F8','1551','1916','1B43','1C40','20FB','2156','2211'],
        preamble        => 'P112#',
        clientmodule    => 'SD_BELL',
        length_min      => '16',
        length_max      => '16',
      },
    "113" =>  ## Wireless Grill Thermometer, Model name: GFGT 433 B1, WDJ7036, FCC ID: 2AJ9O-GFGT433B1, 
              # https://github.com/RFD-FHEM/RFFHEM/issues/992 @ muede-de 2021-07-13
              # The sensor sends more than 12 messages every 2 seconds.
              # T:  24 T2:  29   MS;P1=-761;P2=249;P4=-3005;P5=718;P6=-270;D=24212156215656565621212121212121215621562121562156562156215656562156562156212121562121212121565621;CP=2;SP=4;R=34;O;m2;
              # T: 203 T2: 300   MS;P1=-262;P2=237;P3=-760;P6=-2972;P7=721;D=26232371237171717123232323237171237171712371232323712323712371712371712371232323712371232371717123;CP=2;SP=6;R=1;O;m2;
              # T: 201 T2: 257   MS;P2=-754;P3=247;P5=-2996;P6=718;P7=-272;D=35323267326767676732323232326767326767673232326767326732326732323267673267323232673232323232326732;CP=3;SP=5;R=3;O;m2;
      {
        name            => 'GFGT_433_B1',
        comment         => 'Wireless Grill Thermometer',
        id              => '113',
        knownFreqs      => '433.92',
        one             => [3,-1],  # 750,-250
        zero            => [1,-3],  # 250,-750
        sync            => [1,-12], # 250,-3000
        clockabs        => 250,
        format          => 'twostate',
        preamble        => 'W113#',
        clientmodule    => 'SD_WS',
        modulematch     => '^W113#',
        reconstructBit   => '1',
        length_min      => '47',
        length_max      => '48',
      },
    "114" =>  ## TR401 (Well-Light)
                # https://forum.fhem.de/index.php/topic,121103.0.html @Jake @Ralf9
                # TR401_0_2 off  MU;P0=311;P1=585;P2=-779;P3=1255;P4=-1445;P5=-23617;P7=-5646;CP=1;R=230;D=12323234141414141514123414123232341414141415141234141232323414141414151412341412323234141414141514123414123232341414141415141234141232323414141414151412341412323234141414141517141232323414141414150;p;
                # TR401_0_2 off  MU;P0=-14293;P1=611;P2=-1424;P3=-753;P4=1277;P5=-23626;P6=-9108;P7=214;CP=1;R=240;D=1213421213434342121212121512134212134343421212121216701213421213434342121212121512134212134343421212121215121342121343434212121212151213421213434342121212121512134212134343421212121215121342121343434212121212151213421213434342121212121512134212134343421212121215121342121343434212121212151;p;
                # TR401_0_2 on   MU;P0=-1426;P1=599;P2=-23225;P3=-748;P4=1281;P5=372;P6=111;P7=268;CP=1;R=235;D=0121343401013434340101010101252621343401013434340101010101252705012134340101343434010101010125;p;
                # TR401_0_2 on   MU;P0=-14148;P1=-23738;P2=607;P3=-737;P4=1298;P5=-1419;P6=340;P7=134;CP=2;R=236;D=12343452523434345252525252161712343452523434345252525252160;p;
      {
        name            => 'TR401',
        comment         => 'Remote control for example for Well-Light',
        id              => '114',
        one             => [-7,3],     #  -1400,600
        zero            => [-4,6],     #  -800,1200
        start           => [-118,3],   # -23600,600
        clockabs        => 200,
        format          => 'twostate',
        preamble        => 'P114#',
        modulematch     => '^P114#[13569BDE][13579BDF]F$',
        clientmodule    => 'SD_UT',
        length_min      => '12',
        length_max      => '12',
      },
    "115" =>  ## BRESSER 6-in-1 Weather Center, Bresser new 5-in-1 sensors 7002550
              # https://github.com/RFD-FHEM/RFFHEM/issues/607#issuecomment-888542022 @ Alex-S1981 2021-07-28
              # The sensor alternately sends two different messages every 12 seconds.
              # T: 15.2 H: 93 W: 0.8   MN;D=3BF120B00C1618FF77FF0458152293FFF06B0000;R=242;
              # W: 0.6 R: 5.6          MN;D=1E6C20B00C1618FF99FF0458FFFFA9FF015B0000;R=241;
      {
        name            => 'Bresser 6in1',
        comment         => 'BRESSER 6-in-1 weather center',
        id              => '115',
        knownFreqs      => '868.300',
        datarate        => '8.232',
        sync            => '2DD4',
        modulation      => '2-FSK',
        rfmode          => 'Bresser_6in1',
        regexMatch      => qr/^[a-fA-F0-9]/,
        register        => ['0001','022E','0344','042D','05D4','0612','07C0','0800','0D21','0E65','0F6A','1088','114C','1202','1322','14F8','1551','1916','1B43','1C68'],
        preamble        => 'W115#',
        clientmodule    => 'SD_WS',
        length_min      => '36',
        method          => \&lib::SD_Protocols::ConvBresser_6in1,
      },
    "116" =>  ## Thunder and lightning sensor Fine Offset WH57, aka Froggit DP60, aka Ambient Weather WH31L use with FSK 433.92 MHz
              # https://forum.fhem.de/index.php/topic,122527.0.html
              # I: lightning   D:  6  MN;D=5780C65505060F6C78;R=39;
              # I: lightning   D: 20  MN;D=5780C655051401C4D0;R=37;
              # I: disturbance D: 63  MN;D=5740C655053F0A7272;R=39;
      {
        name            => 'WH57',
        comment         => 'Fine Offset WH57, Ambient Weather WH31L, Froggit DP60 Thunder and Lightning sensor',
        id              => '116',
        knownFreqs      => '433.92',
        datarate        => '17.257',
        sync            => '2DD4',
        modulation      => '2-FSK',
        regexMatch      => qr/^57/, # Family code 0x57 (FineOffset WH57)
        preamble        => 'W116#',
        register        => ['0001','022E','0343','042D','05D4','0609','0780','0800','0D10','0EB0','0F71','10A9','115C','1202','1322','14F8','1543','1916','1B43','1C68'],
        rfmode          => 'Fine_Offset_WH57_434',
        clientmodule    => 'SD_WS',
        length_min      => '18',
        length_max      => '38', # WH68 - length_min => '32', length_max => '38',
      },
    "116.1" =>  ## Thunder and lightning sensor Fine Offset WH57, aka Froggit DP60, aka Ambient Weather WH31L use with FSK 868.35 MHz
      {
        name            => 'WH57',
        comment         => 'Fine Offset WH57, Ambient Weather WH31L, Froggit DP60 Thunder and Lightning sensor',
        id              => '116.1',
        knownFreqs      => '868.35',
        datarate        => '17.257',
        sync            => '2DD4',
        modulation      => '2-FSK',
        regexMatch      => qr/^57/, # Family code 0x57 (FineOffset WH57)
        preamble        => 'W116#',
        register        => ['0001','022E','0343','042D','05D4','0609','0780','0800','0D21','0E65','0FE8','10A9','115C','1202','1322','14F8','1543','1916','1B43','1C68'],
        rfmode          => 'Fine_Offset_WH57_868',
        clientmodule    => 'SD_WS',
        length_min      => '18',
        length_max      => '38', # WH68 - length_min => '32', length_max => '38',
      },
    "117" =>  ## BRESSER 7-in-1 Weather Center (outdoor sensor)
              # https://forum.fhem.de/index.php/topic,78809.msg1196941.html#msg1196941 @ JensS 2021-12-30
              # T: 12.7 H: 87 W: 0 R: 8.4 B: 6.676   MN;D=FC28A6F58DCA18AAAAAAAAAA2EAAB8DA2DAACCDCAAAAAAAAAA000000;R=29;
              # T: 13.1 H: 88 W: 0 R: 0   B: 0.36    MN;D=4DC4A6F5B38A10AAAAAAAAAAAAAAB9BA22AAA9CAAAAAAAAAAA000000;R=15;
              # T: 10.1 H: 94 W: 0 R: 0   B: 1.156   MN;D=0CF0A6F5B98A10AAAAAAAAAAAAAABABC3EAABBFCAAAAAAAAAA000000;R=28;
              ## BRESSER PM2.5/10 air quality meter @ elektron-bbs 2023-11-30
              # PM2.5: 629  PM10: 636   MN;D=ACF66068BDCA89BD2AF22AC83AC9CA33333333333393CAAAAA00;R=9;
              # PM2.5:   8  PM10:   9   MN;D=E3626068BDCA89BD2AAADAAA2AAA3AAEEAAF9AAFEA93CAAAAA00;R=10;
      {
        name            => 'Bresser 7in1',
        comment         => 'BRESSER 7-in-1 weather center',
        id              => '117',
        knownFreqs      => '868.300',
        datarate        => '8.232',
        sync            => '2DD4',
        modulation      => '2-FSK',
        rfmode          => 'Bresser_7in1',
        regexMatch      => qr/^[a-fA-F0-9]/,
        register        => ['0001','022E','0345','042D','05D4','0617','07C0','0800','0D21','0E65','0F6A','1088','114C','1202','1322','14F8','1551','1916','1B43','1C68'],
        preamble        => 'W117#',
        clientmodule    => 'SD_WS',
        length_min      => '46',
        method          => \&lib::SD_Protocols::ConvBresser_7in1,
      },
    "118" => ## Remote controls for Meikee LED lights e.g. RGB LED Wallwasher Light and Solar Flood Light
             # https://forum.fhem.de/index.php/topic,126110.0.html @ Sepp 2022-02-09
             # Meikee_24_20D3 on     MU;P0=506;P1=-1015;P2=1008;P3=-523;P4=-12696;D=01012301040101230101010101232301230101232301010101010123010;CP=0;R=49;
             # Meikee_24_20D3 off    MU;P0=-516;P1=518;P2=-1015;P3=1000;P4=-12712;D=01230121230301212121212121230141212301212121212303012301212303012121212121212301;CP=1;R=35;
             # Meikee_24_20D3 learn  MU;P0=-509;P1=513;P2=-999;P3=1027;P4=-12704;D=01230121230301212121212121212141212301212121212303012301212303012121212121212121;CP=1;R=77;
      {
        name            => 'Meikee',
        comment         => 'Remote controls for Meikee LED lights',
        id              => '118',
        one             => [2,-1], # 1016,-508
        zero            => [1,-2], # 508,-1016
        start           => [-25],  # -12700, message provided as MU
        end             => [1],    # 508
        clockabs        => 508,
        format          => 'twostate',
        clientmodule    => 'SD_UT',
        modulematch     => '^P118#',
        preamble        => 'P118#',
        length_min      => '24',
        length_max      => '25',
      },
    "118.1" => ## Remote controls for Meikee LED lights e.g. RGB LED Wallwasher Light and Solar Flood Light
      {
        name            => 'Meikee',
        comment         => 'Remote controls for Meikee LED lights',
        id              => '118.1',
        one             => [2,-1], # 1016,-508
        zero            => [1,-2], # 508,-1016
        sync            => [-25],  # -12700, message provided as MS
        end             => [1],    # 508
        clockabs        => 508,
        format          => 'twostate',
        clientmodule    => 'SD_UT',
        modulematch     => '^P118#',
        preamble        => 'P118#',
        length_min      => '24',
        length_max      => '25',
      },
    "119" =>  ## Funkbus
              #
      {
        name            => 'Funkbus',
        comment         => 'only Typ 43',
        id              => '119',
        clockrange      => [490,520],       # min , max
        format          => 'manchester',
        clientmodule    => 'IFB',
        #modulematch     => '',
        preamble        => 'J',
        length_min      => '47',
        length_max      => '52',
        method          => \&lib::SD_Protocols::mcBit2Funkbus,
      },
    "120" =>  ## Weather station TFA 35.1077.54.S2 with 30.3151 (T/H-transmitter), 30.3152 (rain gauge), 30.3153 (anemometer)
              # https://forum.fhem.de/index.php/topic,119335.msg1221926.html#msg1221926 2022-05-17 @ Ronny2510
              # SD_WS_120 T: 19.1 H: 84 W: 0.7 R: 473.1  MU;P0=-6544;P1=486;P2=-987;P3=1451;D=01212121212121232123212321232121232323232321232321232321212121232123212321232323232323232321232323232323212323232323232321212323232123212323212121232123212123;CP=1;R=51;
              # SD_WS_120 T: 18.7 H: 60 W: 2.0 R: 491.1  MU;P0=-4848;P1=984;P2=-981;P3=1452;P4=-17544;P5=480;P6=-31000;P7=320;D=01234525252525252523252325232523252523232323232523232523232523252523232525252523232323232323252523232323232523232323232323232525232325252323252325252323232523232565272525252525232523252325232525232323232325232325232325232525232325252525232323232323232525;CP=5;R=51;O;
              # SD_WS_120 T: 22   H: 43 W: 0.3 R: 530.4  MU;P0=-15856;P1=480;P2=-981;P3=1460;D=01212121212121232123212321232121232323232321232321212321212323232321232123212123232323232323212323232323232123232323232321212321212123212323232321212121232121;CP=1;R=47; 
      {
        name            => 'TFA 35.1077.54.S2',
        comment         => 'Weatherstation with sensors 30.3151, 30.3152, 30.3153',
        id              => '120',
        knownFreqs      => '868.35',
        one             => [1,-2], #  480,-960
        zero            => [3,-2], # 1440,-960
        clockabs        => 480,
        reconstructBit  => '1',
        format          => 'twostate',
        preamble        => 'W120#',
        clientmodule    => 'SD_WS',
        modulematch     => '^W120#',
        length_min      => '78',
        length_max      => '80',
      },
    "121" => ## Remote control Busch-Transcontrol HF - Handsender 6861
             # 1 OFF   MU;P0=28479;P1=-692;P2=260;P3=574;P4=-371;D=0121212121212134343434213434342121213434343434342;CP=2;R=41;
             # 1 ON    MU;P0=4372;P1=-689;P2=254;P3=575;P4=-368;D=0121213434212134343434213434342121213434343434342;CP=2;R=59;
             # 2 OFF   MU;P0=7136;P1=-688;P2=259;P3=585;P4=-363;D=0121212121212134343434213434342121213434343434343;CP=2;R=59;
      {
        name            => 'Busch-Transcontrol',
        comment         => 'Remote control 6861',
        id              => '121',
        one             => [2.2,-1.4], #   572,-364
        zero            => [1,-2.6],   #   260,-676
        start           => [-2.6],     #  -675
        pause           => [120,-2.6], # 31200,-676
        clockabs        => 260,
        reconstructBit  => '1',
        format          => 'twostate',
        clientmodule    => 'SD_UT',
        modulematch     => '^P121#',
        preamble        => 'P121#',
        length_min      => '23',
        length_max      => '24',
      },
    "122" =>  ## TM40, Wireless Grill-, Meat-, Roasting-Thermometer with 4 Temperature Sensors
              # https://forum.fhem.de/index.php?topic=127938.msg1224516#msg1224516 2022-06-09 @ Prof. Dr. Peter Henning
              # SD_WS_122_T  T: 36 T2: 32 T3: 31 T4: 31  MU;P0=3412;P1=-1029;P2=1043;P3=4706;P4=-2986;P5=549;P6=-1510;P7=-562;D=01212121212121213456575756575756575756565757575656575757575757575657575656575656575757575757575756575756565756565757575757575757565756575757575757575757575757575657565657565757575757575757575757575757575757575756575656565757575621212121212121213456575756;CP=5;R=2;O;
              # SD_WS_122_T  T: 83 T2: 22 T3: 22 T4: 22  MU;P0=11276;P1=-1039;P2=1034;P3=4704;P4=-2990;P5=543;P6=-1537;P7=-559;D=01212121212121213456575756575756575756565757575656575757575757575756565756565657575757575757575757565657565656575757575757575757575656575656565757575757575757565657575656565656575757575757575757575757575757575756565756565656575621212121212121213456575756;CP=5;R=12;O;
      {
        name            => 'TM40',
        comment         => 'Roasting Thermometer with 4 Temperature Sensors',
        id              => '122',
        knownFreqs      => '433.92',
        one             => [1,-3],           # 520,-1560
        zero            => [1,-1],           # 520,-520
        start           => [2,-1,2,-1,9,-6], # 1040,-520,1040,-520,4680,-3120
        clockabs        => 520,
        format          => 'twostate',
        preamble        => 'W122#',
        clientmodule    => 'SD_WS',
        modulematch     => '^W122#',
        length_min      => '104',
        length_max      => '108',
      },
    "123" =>  ## Inkbird IBS-P01R Pool Thermometer, Inkbird ITH-20R (not tested)
              # https://forum.fhem.de/index.php/topic,128945.0.html 2022-08-28 @ xeenon
              # SD_WS_123_T_0655  T: 25           MN;D=D3910F800301005A0655FA001405140535F6;R=10;
              # SD_WS_123_T_7E43  T: 25.4 H: 60   MN;D=D3910F00010301207E43FE0014055802772A;R=232;
      {
        name            => 'IBS-P01R',
        comment         => 'Inkbird IBS-P01R pool phermometer, ITH-20R',
        id              => '123',
        knownFreqs      => '433.92',
        datarate        => '10.000',
        sync            => '2DD4',
        modulation      => '2-FSK',
        regexMatch      => qr/^D391/,
        preamble        => 'W123#',
        register        => ['0001','022E','0344','042D','05D4','0612','07C0','0800','0D10','0EB0','0F71','10C8','1193','1202','1322','14F8','1534','1916','1B43','1C48'],
        rfmode          => 'Inkbird_IBS-P01R',
        clientmodule    => 'SD_WS',
        length_min      => '36',
      },

    # "124" reserved for => ## Remote control CasaFan FB-FNK Powerboat with 5 buttons for fan

    "125" =>  ## Humidity and Temperaturesensor Ecowitt WH31/WH31E, froggit DP50 / WH31A, DNT000005
              # Nordamerika: 915MHz; Europa: 868MHz, andere Regionen: 433MHz
              # https://github.com/RFD-FHEM/RFFHEM/pull/1161 @ sidey79 2023-04-01
              # SD_WS_125_TH_1 T: 21.0 H: 55  Battery: ok channel:1   MN;D=300282623704516C000200;R=56;
              # SD_WS_125_TH_1 T: 16.7 H: 60  Battery: ok channel:2   MN;D=300292373CDA116C000200;R=229;
              # SD_WS_125_TH_3 T: 5.4 H: 52   Battery: ok channel:3   MN;D=30E0A1C634FEA96C000200;R=197;
              # SD_WS_125_DCF: 97: 2025-01-09 10:49:29                MN;D=52971025010910492909B3;R=33;A=2;
      {
        name            => 'WH31',
        comment         => 'Fine Offset | Ambient Weather WH31E Thermo-Hygrometer Sensor',
        id              => '125',
        knownFreqs      => '868.35',
        datarate        => '17.257',
        sync            => '2DD4',
        modulation      => '2-FSK',
        regexMatch      => qr/^(30|37|52)/,
        preamble        => 'W125#',
        register        => ['0001','022E','0342','042D','05D4','060b','0780','0800','0D21','0E65','0FE8','10A9','115C','1202','1322','14F8','1543','1916','1B43','1C68'],
        rfmode          => 'Fine_Offset_WH31_868',
        clientmodule    => 'SD_WS',
        length_min      => '22',
        length_max      => '38', # WH68 - length_min => '32', length_max => '38',
      },
    "126" =>  ## Rainfall Sensor Ecowitt WH40
              # https://github.com/RFD-FHEM/RFFHEM/pull/1164 @ sidey79 2023-04-03
              # SD_WS_126 R: 0 MN;D=40011CDF8F0000976220A6802801;R=61;   14 byte  ID 11CDF
              # SD_WS_126 R: 0 MN;D=40013E3C900000105BA02A;R=61;         11 byte  ID 13E3c
              # SD_WS_126 R: 9 MN;D=40013E3C90005AB55AA0A0800408;R=61;   14 Byte  ID 13E3c
      { 
        name            => 'WH40',
        comment         => 'Fine Offset | Ambient Weather WH40 rain gauge',
        id              => '125',
        knownFreqs      => '868.35',
        datarate        => '17.257',
        sync            => '2DD4',
        modulation      => '2-FSK',
        regexMatch      => qr/^40/, 
        preamble        => 'W126#',
        register        => ['0001','022E','0343','042D','05D4','060e','0780','0800','0D21','0E65','0FE8','10A9','115C','1202','1322','14F8','1543','1916','1B43','1C68'],
        rfmode          => 'Fine_Offset_WH40_868',
        clientmodule    => 'SD_WS',
        length_min      => '22',
        length_max      => '38', # WH68 - length_min => '32', length_max => '38',
      },
    "127" =>  ## Remote control with 14 buttons for ceiling fan
               # https://forum.fhem.de/index.php?topic=134121.0 @ Kai-Alfonso 2023-06-29
               # RCnoName127_3603A fan_off  MU;P0=5271;P1=-379;P2=1096;P3=368;P4=-1108;P5=-5997;D=01213434213434212121212121213434342134212121343421343434212521213434213434212121212121213434342134212121343421343434212521213434213434212121212121213434342134212121343421343434212521213434213434212121212121213434342134212121343421343434212;CP=3;R=63;
               # Message is output by SIGNALduino as MU if the last bit is a 0.
      {
        name             => 'RCnoName127',
        comment          => 'Remote control with 14 buttons for ceiling fan',
        id               => '127',
        knownFreqs       => '433.92',
        one              => [1,-3],  #   370,-1110
        zero             => [3,-1],  #  1110, -370
        start            => [-15],   # -5550 (MU)
        reconstructBit   => '1',
        clockabs         => '370',
        format           => 'twostate',
        preamble         => 'P127#',
        clientmodule     => 'SD_UT',
        modulematch      => '^P127#',
        length_min       => '29',
        length_max       => '30',
      },
    "127.1" =>  ## Remote control with 14 buttons for ceiling fan
                 # https://forum.fhem.de/index.php?topic=134121.0 @ Kai-Alfonso 2023-06-29
                 # RCnoName127_3603A fan_1         MS;P1=-385;P2=1098;P3=372;P4=-1108;P5=-6710;D=352121343421343421212121212121343434213421212121213421343434;CP=3;SP=5;R=79;m2;
                 # RCnoName127_3603A light_on_off  MS;P1=-372;P2=1098;P3=376;P4=-1096;P5=-6712;D=352121343421343421212121212121343434213421342134212134213421;CP=3;SP=5;R=73;m2;
                 # Message is output by SIGNALduino as MS if the last bit is a 1.
      {
        name             => 'RCnoName127',
        comment          => 'Remote control with 14 buttons for ceiling fan',
        id               => '127.1',
        knownFreqs       => '433.92',
        one              => [1,-3],  #  370,-1110
        zero             => [3,-1],  # 1110, -370
        sync             => [1,-18], #  370,-6660 (MS)
        clockabs         => '370',
        format           => 'twostate',
        preamble         => 'P127#',
        clientmodule     => 'SD_UT',
        modulematch      => '^P127#',
        length_min       => '29',
        length_max       => '30',
      },
    "128" =>  ## Remote control with 12 buttons for ceiling fan
               # https://forum.fhem.de/index.php?msg=1281573 @ romakrau 2023-07-14
               # RCnoName128_8A7F fan_slower   MU;P0=-420;P1=1207;P2=-1199;P3=424;P4=-10154;D=010101230123010123232323232323232323230123010143230101012301230101232323232323232323232301230101432301010123012301012323232323232323232323012301014323010101230123010123232323232323232323230123010143230101012301230101232323232323232323232301230101;CP=3;R=18;
               # Message is output by SIGNALduino as MU if the last bit is a 0.
      {
        name             => 'RCnoName128',
        comment          => 'Remote control with 12 buttons for ceiling fan',
        id               => '128',
        knownFreqs       => '433.92',
        one              => [-3,1],  #  -1218,406
        zero             => [-1,3],  #   -406,1218
        start            => [-25,1], # -10150,406 (MU)
        clockabs         => '406',
        format           => 'twostate',
        preamble         => 'P128#',
        clientmodule     => 'SD_UT',
        modulematch      => '^P128#',
        length_min       => '23',
        length_max       => '24',
      },
    "128.1" =>  ## Remote control with 12 buttons for ceiling fan
                 # https://forum.fhem.de/index.php?msg=1281573 @ romakrau 2023-07-14
                 # RCnoName128_8A7F fan_on_off      MS;P2=-424;P3=432;P4=1201;P5=-1197;P6=-10133;D=36353242424532453242453535353535353535353532453535;CP=3;SP=6;R=36;m1;
                 # RCnoName128_8A7F fan_direction   MS;P0=-10144;P4=434;P5=-415;P6=1215;P7=-1181;D=40474565656745674565674747474747474747474745656567;CP=4;SP=0;R=37;m2;
                 # Message is output by SIGNALduino as MS if the last bit is a 1.
      {
        name             => 'RCnoName128',
        comment          => 'Remote control with 12 buttons for ceiling fan',
        id               => '128.1',
        knownFreqs       => '433.92',
        one              => [-3,1],  #  -1218,406
        zero             => [-1,3],  #   -406,1218
        sync             => [-25,1], # -10150,406 (MS)
        reconstructBit   => '1',
        clockabs         => '406',
        format           => 'twostate',
        preamble         => 'P128#',
        clientmodule     => 'SD_UT',
        modulematch      => '^P128#',
        length_min       => '23',
        length_max       => '24',
      },
    "129"  =>  ## Sainlogic FT-0835
               # https://forum.fhem.de/index.php?topic=134381.0 @  Tueftler1983 2023-07-23
               # SD_WS_129_0E  T: 27.6 H: 36 W: 0.2 R: 0   MC;LL=-987;LH=970;SL=-506;SH=473;D=002B3F1FFDFCE4FFFF7B3FDB000404F9;C=489;L=128;R=60;
               # SD_WS_129_0E  T: 17.7 H: 70 W: 0.4 R: 0   MC;LL=-963;LH=986;SL=-491;SH=491;D=002B3F1BFBF8EDFFFF7BF0B900040413;C=488;L=128;R=92;
               # https://forum.fhem.de/index.php?msg=1283414 @ Nighthawk 2023-08-05
               # SD_WS_129_BD  T: 18.4 H: 90 W: 1.3 R: 1536.6 B: 115105   MC;LL=-1036;LH=918;SL=-533;SH=435;D=002B3427F2EE58C3F97BE4A53E5EB79B;C=486;L=128;R=212;
               # SD_WS_129_BD  T: 17.6 H: 82 W: 1.5 R: 1537.2 B: 591      MC;LL=-983;LH=962;SL=-487;SH=488;D=002B3427F0EB0BC3F3FBF3ADFDB0FA87;C=486;L=128;R=219;
      {
        name            => 'FT-0835',
        comment         => 'Sainlogic weather stations',
        id              => '129',
        knownFreqs      => '433.92',
        clockrange      => [450,550],
        format          => 'manchester',
        clientmodule    => 'SD_WS',
        modulematch     => '^W129#FF.*',
        preamble        => 'W129#',
        length_min      => '128',
        length_max      => '128',
        polarity        => 'invert',
        method          => \&lib::SD_Protocols::mcBit2Sainlogic, # Call to process this message
      },
    "130" =>  ## Remote control CREATE 6601TL for ceiling fan with light
                 # https://forum.fhem.de/index.php?msg=1288203 @ erdnar 2023-09-29
                 # CREATE_6601TL_F53A light_on_off     MS;P1=425;P2=-1142;P3=1187;P4=-395;P5=-12314;D=15121212123412341234341212123412341212121212121234;CP=1;SP=5;R=232;O;m2;
                 # CREATE_6601TL_F53A light_cold_warm  MS;P1=432;P2=-1143;P3=1183;P4=-393;P5=-12300;D=15121212123412341234341212123412341212121212123434;CP=1;SP=5;R=231;O;m2;
                 # CREATE_6601TL_F53A fan_faster       MS;P0=-11884;P1=392;P2=-1179;P3=1180;P4=-391;D=10121212123412341234341212123412341212121212341234;CP=1;SP=0;R=231;O;m2;
      {
        name             => 'CREATE_6601TL',
        comment          => 'Remote control for ceiling fan with light',
        id               => '130',
        knownFreqs       => '433.92',
        one              => [1,-3],  #
        zero             => [3,-1],  #
        sync             => [1,-30], #
        clockabs         => '400',
        format           => 'twostate',
        preamble         => 'P130#',
        clientmodule     => 'SD_UT',
        modulematch      => '^P130#',
        length_min       => '24',
        length_max       => '24',
      },
    "131" =>  ## BRESSER lightning detector @ elektron-bbs 2023-12-26
              # SD_WS_131 count:   0, distance:  0, batteryState: ok, batteryChanged: 0   MN;D=DA5A2866AAA290AAAAAA;R=23;A=-2;
              # SD_WS_131 count:   1, distance: 17, batteryState: ok, batteryChanged: 0   MN;D=5B192866AAB290BDAAAA;R=32;A=-3;
              # SD_WS_131 count: 148, distance:  8, batteryState: ok, batteryChanged: 1   MN;D=AA362866BE2298A2AAAA;R=24;A=-2;
      {
        name            => 'Bresser lightning',
        comment         => 'Bresser lightning detector',
        id              => '131',
        knownFreqs      => '868.300',
        datarate        => '8.232',
        sync            => '2DD4',
        modulation      => '2-FSK',
        rfmode          => 'Bresser_lightning',
        regexMatch      => qr/^[a-fA-F0-9]/,
        register        => ['0001','022E','0342','042D','05D4','060A','07C0','0800','0D21','0E65','0F6A','1088','114C','1202','1322','14F8','1551','1916','1B43','1C68'],
        preamble        => 'W131#',
        clientmodule    => 'SD_WS',
        length_min      => '20',
        method          => \&lib::SD_Protocols::ConvBresser_lightning,
      },
    "132"  =>  ## Remote control Halemeier HA-HX2 for Actor HA-RX-M2-1
               # https://github.com/RFD-FHEM/RFFHEM/issues/1207 @ HomeAuto_User 2023-12-11
               # https://forum.fhem.de/index.php?topic=38452.0 (probably identical)
               # remote 1 - off | P132#85EFAC
               # MU;P0=304;P1=-351;P2=633;P3=-692;P4=-12757;D=01230303030301230123030121240301212121230123030303012303030303012124030121212123012303030301230303030301230123030121240301212121230123030303012303030303012301230301212403012121212301230303030123030303030123012303012124030121212123012303030301230303030301;CP=0;R=241;O;
               # MU;P0=-12609;P1=305;P2=-696;P3=-344;P4=653;D=01213434343421342121212134212121212134213421213434012134343434213421212121342121212121342134212134340121343434342134212121213421212121213421342121343401213434343421342121212134212121212134213421213434012134343434213421212121342121212121342134212134340121;CP=1;R=239;O;
               # remote 1 - on  | P132#85EFAA
               # MU;P0=-696;P1=312;P2=-371;P3=637;P4=-12847;D=01012301230123012341012323232301230101010123010101010123012301230123410123232323012301010101230101010101230123012301234101232323230123010101012301010101012301230123012341012323232301230101010123010101010123012301230123410123232323012301010101230101010101;CP=1;R=236;O;
               # MU;P0=-701;P1=304;P2=-366;P3=642;P4=-12781;D=01012301230123012341012323232301230101010123010101010123012301230123410123232323012301010101230101010101230123012301234101232323230123010101012301010101012301230123012341012323232301230101010123010101010123012301230123410123232323012301010101230101010101;CP=1;R=238;O;
               # remote 2 - on  | P132#01EFAA
               # MU;P0=-340;P1=639;P2=-686;P3=304;P4=-12480;D=01230123014301010101010101232323232301230123012301430101010101010123232323012323232323012301230123014301010101010101232323230123232323230123012301230143010101010101012323232301232323232301230123012301430101010101010123232323012323232323012301230123014301;CP=3;R=226;O;
               # MU;P0=-120;P1=642;P2=-343;P3=-684;P4=319;P5=-12492;D=01212121343434342134343434342134213421342154212121212121213434343421343434343421342134213421542121212121212134343434213434343434213421342134215421212121212121343434342134343434342134213421342154212121212121213434343421343434343421342134213421542121212121;CP=4;R=227;O;
               # remote 2 - off  | P132#01EFAC
               # MU;P0=622;P1=-367;P2=-690;P3=323;P4=-12531;D=01010101010101023232323102323232323102310232310101010102323232310232323232310231023231010431010101010101023232323102323232323102310232310104310101010101010232323231023232323231023102323101043101010101010102323232310232323232310231023231010431010101010101;CP=3;R=235;O;
               # MU;P0=307;P1=-685;P2=-350;P3=658;P4=-12510;D=01010102310101010102310231010232340232323232323231010101023101010101023102323232323232323101010102310101010102310231010232340232323232323231010101023101010101023102310102323402323232323232310101010231010101010231023101023234023232323232323101010102310101;CP=0;R=232;O;
      {
        name            => 'HA-HX2',
        comment         => 'Remote control for Halemeier LED actor HA-RX-M2-1',
        id              => '132',
        knownFreqs      => '433.92',
        one             => [-2,1],
        zero            => [-1,2],
        start           => [-39,1],
        clockabs        => 330,
        format          => 'twostate',
        preamble        => 'P132#',
        clientmodule    => 'SD_UT',
        modulematch     => '^P132#.*',
        length_min      => '24',
        length_max      => '24',
      },
    "133" =>  # WMBus_S
              # https://wiki.fhem.de/wiki/WMBUS
      {
        name            => 'WMBus_S',
        comment         => 'WMBus mode S',
        id              => '133',
        knownFreqs      => '868.300',
        datarate        => '32.720',
        preamble        => 'b',
        modulation      => '2-FSK',
        sync            => '7696',
        rfmode          => 'WMBus_S',
        register        => ['0006','0200','0340','0476','0596','06FF','0704','0802','0B08','0D21','0E65','0F6A','106A','114A','1206','1322','14F8','1547','192E','1A6D','1B04','1C09','1DB2'],
        length_min      => '56',      # to filter messages | must check
        clientmodule    => 'WMBUS',
      },
    "134" =>  # WMBus_T
              # https://wiki.fhem.de/wiki/WMBUS
              # messages with normal identifier
              # RAWMSG: MN;D=3E44FA1213871122011633057A1C002025417CD28E06770269857D8001EF3B8BBE56BA7E06855CBA0334149F51682F2E6E2960E6900F800C0001090086B41E003A6F140131414D7D88810A;R=10;A=16;
              # DMSG:       b3E44FA1213871122011633057A1C002025417CD28E06770269857D8001EF3B8BBE56BA7E06855CBA0334149F51682F2E6E2960E6900F800C0001090086B41E003A6F140131414D7D88810A
              # messages with Y identifier for frame type B
              # RAWMSG: MN;D=Y304497264202231800087A3E0020A5EE5B2074920E46E4B4A26B99C92C8DD3A55F44FAF6AE0256B354F9C48C717BFAD43400FB;R=251;A=0;
              # DMSG:       bY304497264202231800087A3E0020A5EE5B2074920E46E4B4A26B99C92C8DD3A55F44FAF6AE0256B354F9C48C717BFAD43400FB
      {
        name            => 'WMBus_T',
        comment         => 'WMBus mode C and T',
        id              => '134',
        knownFreqs      => '868.950',
        datarate        => '100.000',
        preamble        => 'b',
        modulation      => '2-FSK',
        sync            => '543D',
        rfmode          => 'WMBus_T',
        register        => ['0006','0200','0340','0454','053D','06FF','0704','0802','0B08','0D21','0E6B','0FD0','105C','1104','1206','1322','14F8','1544','192E','1ABF','1BC7','1C09','1DB2'],
        length_min      => '56',      # to filter messages | must check
        clientmodule    => 'WMBUS',
      },
    "135" =>  ## Temperatursensor TFA Dostmann 30.3255.02
              # https://forum.fhem.de/index.php?topic=141436.0 @ Johann.S 2025-04-18
              # Ch: 2  T: 21.4  batteryState: ok  sendmode: manual   MU;P0=-5132;P1=963;P2=-992;P3=467;P4=-273;P5=230;P6=-499;D=01212121234565656343456343434563456563456343434565634563434565634343456565612121212345656563434563434345634565634563434345656345634345656343434565656121212123456565634345634343456345656345634343456563456343456563434345656561212121234565656343456343434563;CP=5;R=51;O;
              # Ch: 2  T: 21.4  batteryState: ok  sendmode: auto     MU;P0=-10720;P1=965;P2=-994;P3=470;P4=-265;P5=237;P6=-501;D=01212121234565656343456343456563456563456343434565634563456345634343456565612121212345656563434563434565634565634563434345656345634563456343434565656121212123456565634345634345656345656345634343456563456345634563434345656561212121234565656343456343456563;CP=5;R=60;O;
      {
        name            => 'TFA 30.3255.02',
        comment         => 'Temperature sensor TFA 30.3255.02',
        id              => '135',
        knownFreqs      => '433.92',
        one             => [2,-1],           # 488,-244
        zero            => [1,-2],           # 244,-488
        start           => [4,-4,4,-4,4,-4], # 976,-976,976,-976,976,-976,976,-976
        clockabs        => 244,
        format          => 'twostate',
        preamble        => 'W135#',
        clientmodule    => 'SD_WS',
        length_min      => '32',
        length_max      => '33',
      },
    ########################################################################
    #### ###  register informations from other hardware protocols  #### ####

    # "993" =>  # HomeMatic
              # # settings from CUL
      # {
        # name            => 'HomeMatic',
        # comment         => '',
        # id              => '993',
        # developId       => 'm',
        # knownFreqs      => '868.3',
        # datarate        => '',
        # sync            => 'E9CA',
        # modulation      => '2-FSK',
        # rfmode          => 'HomeMatic',
        # register        => ['0007','012E','022E','030D','04E9','05CA','06FF','070C','0845','0900','0A00','0B06','0C00','0D21','0E65','0F6A','10C8','1193','1203','1322','14F8','1534','1607','1733','1818','1916','1A6C','1B43','1C40','1D91','1E87','1F6B','20F8','2156','2210','23AC','240A','253D','2611','2741'],
      # },
    # "994" =>  # LaCrosse_mode_4
              # # https://wiki.fhem.de/wiki/JeeLink
              # # https://forum.fhem.de/index.php/topic,106594.0.html?PHPSESSID=g0k1ruul2e3hmddm0uojaeurfl
      # {
        # name            => 'LaCrosse_mode_4',
        # comment         => 'example: TX22 (WS 1600)',
        # id              => '994',
        # developId       => 'm',
        # knownFreqs      => '868.3',
        # datarate        => '8.842',
        # sync            => '2DD4',
        # modulation      => '2-FSK',
        # rfmode          => 'LaCrosse_mode_4',
        # register        => ['0001','012E','0246','0302','042D','05D4','06FF','0700','0802','0900','0A00','0B06','0C00','0D21','0E65','0F6A','1088','1165','1206','1322','14F8','1556','1607','1700','1818','1916','1A6C','1B43','1C68','1D91','1E87','1F6B','20F8','2156','2211','23EC','242A','2517','2611','2741'],
      # },
    # "995" =>  # MAX
              # # settings from CUL
      # {
        # name            => 'MAX',
        # comment         => '',
        # id              => '995',
        # developId       => 'm',
        # knownFreqs      => '',
        # datarate        => '',
        # sync            => 'C626',
        # modulation      => '2-FSK',
        # rfmode          => 'MAX',
        # register        => ['0007','012E','0246','0307','04C6','0526','06FF','070C','0845','0900','0A00','0B06','0C00','0D21','0E65','0F6A','10C8','1193','1203','1322','14F8','1534','1607','173F','1828','1916','1A6C','1B43','1C40','1D91','1E87','1F6B','20F8','2156','2210','23AC','240A','253D','2611','2741'],
      # },
    # "996" =>  # RIO-Funkprotokoll
              # # https://forum.fhem.de/index.php/topic,107239.msg1011812.html#msg1011812
              # # send RIO in GFSK
              # # https://wiki.fhem.de/wiki/Unbekannte_Funkprotokolle
      # {
        # name            => 'RIO Protocol, send GFSK',
        # comment         => 'example: HS-8',
        # id              => '996',
        # developId       => 'm',
        # knownFreqs      => '868.3',
        # datarate        => '24.796',
        # modulation      => 'GFSK',
        # rfmode          => 'RIO',
        # register        => ['000D','012E','022D','0347','04D3','0591','063D','0704','0832','0900','0A00','0B06','0C00','0D21','0E65','0F6F','1086','1190','1218','1323','14B9','1540','1607','1700','1818','1914','1A6C','1B07','1C00','1D91','1E87','1F6B','20F8','21B6','2211','23EF','240D','253E','261F','2741'],
      # },

    ########################################################################
    #### ### old information from incomplete implemented protocols #### ####

          # ""  =>  ## Livolo
          # https://github.com/RFD-FHEM/RFFHEM/issues/29
          # MU;P0=-195;P1=151;P2=475;P3=-333;D=0101010101 02 01010101010101310101310101010101310101 02 01010101010101010101010101010101010101 02 01010101010101010101010101010101010101 02 010101010101013101013101;CP=1;
          #
          # protocol sends 24 to 47 pulses per message.
          # First pulse is the header and is 595 μs long. All subsequent pulses are either 170 μs (short pulse) or 340 μs (long pulse) long.
          # Two subsequent short pulses correspond to bit 0, one long pulse corresponds to bit 1. There is no footer. The message is repeated for about 1 second.
          #
          # Start bit: |             |___|    bit 0: |   |___|    bit 1: |       |___|
      # {
        # name          => 'Livolo',
        # comment       => 'remote control / dimmmer / switch ...',
        # id            => '',
        # knownFreqs    => '',
        # one           => [3],
        # zero          => [1],
        # start         => [5],
        # clockabs      => 110,         #can be 90-140
        # format        => 'twostate',
        # preamble      => 'uXX#',
        # #clientmodule  => '',
        # #modulematch   => '',
        # length_min    => '16',
        # #length_max   => '',          # missing
        # filterfunc    => 'SIGNALduino_filterSign',
      # },

    ########################################################################
  );
}
