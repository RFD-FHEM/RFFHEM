######################################################################
# $Id: 88_SIGNALduino_TOOL.pm 13115 2019-02-11 21:17:50Z HomeAuto_User $
#
# The file is part of the SIGNALduino project
# see http://www.fhemwiki.de/wiki/SIGNALduino to support debugging of unknown signal data
# The purpos is to use it as addition to the SIGNALduino
# 2018 | 2019 - HomeAuto_User & elektron-bbs
#
######################################################################
# Note´s
# - added commandref doublePulse command take a while
# - Send_RAWMSG last message Button!! nicht 
######################################################################

package main;

use strict;
use warnings;

use Data::Dumper qw (Dumper);

#$| = 1;		#Puffern abschalten, Hilfreich für PEARL WARNINGS Search

my %List;																								# message hash
my $Filename_Dispatch = "SIGNALduino_TOOL_Dispatch_";		# name file to read input for dispatch


################################
sub SIGNALduino_TOOL_Initialize($) {
	my ($hash) = @_;

	$hash->{DefFn}			=	"SIGNALduino_TOOL_Define";
	$hash->{SetFn}			=	"SIGNALduino_TOOL_Set";
	$hash->{ShutdownFn}	= "SIGNALduino_TOOL_Shutdown";
	$hash->{AttrFn}			=	"SIGNALduino_TOOL_Attr";
	$hash->{GetFn}			=	"SIGNALduino_TOOL_Get";
	$hash->{AttrList}		=	"disable Dummyname Filename_input Filename_export MessageNumber Path StartString:MU;,MC;,MS; DispatchMax comment"
												." RAWMSG_M1 RAWMSG_M2 RAWMSG_M3 Sendername Senderrepeats $readingFnAttributes";
}

################################
sub SIGNALduino_TOOL_Define($$) {
	my ($hash, $def) = @_;
	my @arg = split("[ \t][ \t]*", $def);
	my $name = $arg[0];						## Der Definitionsname, mit dem das Gerät angelegt wurde.
	my $typ = $hash->{TYPE};			## Der Modulname, mit welchem die Definition angelegt wurde.
	my $file = AttrVal($name,"Filename_input","");

	return "Usage: define <name> $name"  if(@arg != 2);

	if ( $init_done == 1 ) {
		### Check SIGNALduino min one definded ###
		my $Device_count = 0;
		foreach my $d (sort keys %defs) {
			if(defined($defs{$d}) && $defs{$d}{TYPE} eq "SIGNALduino") {
				$Device_count++;
			}
		}
		return "ERROR: You can use this TOOL only with a definded SIGNALduino!" if ($Device_count == 0);

		### Attributes ###
		$attr{$name}{room}		= "SIGNALduino_un" if ( not exists($attr{$name}{room}) );				# set room, if only undef --> new def
		$attr{$name}{cmdIcon}	= "START:remotecontrol/black_btn_PS3Start Dispatch_RAWMSG_last:remotecontrol/black_btn_BACKDroid" if ( not exists($attr{$name}{cmdIcon}) );		# set Icon
	}

	### default value´s ###
	$hash->{STATE} = "Defined";
	readingsSingleUpdate($hash, "state" , "Defined" , 0);

	return undef;
}

################################
sub SIGNALduino_TOOL_Shutdown($$) {
	my ($hash) = @_;
	my $name = $hash->{NAME};

	Log3 $name, 5, "$name: SIGNALduino_TOOL_Shutdown are running!";
	for my $readingname (qw/cmd_raw cmd_sendMSG last_MSG last_DMSG line_read message_dispatched message_to_module/) {		# delete reading cmd_raw & cmd_sendMSG
		readingsDelete($hash,$readingname);
	}
	return undef;
}

################################
sub SIGNALduino_TOOL_Set($$$@) {
	my ( $hash, $name, @a ) = @_;

	return "no set value specified" if(int(@a) < 1);
	my $RAWMSG_last = ReadingsVal($name, "last_MSG", "none");		# check RAWMSG exists
	my $DMSG_last = ReadingsVal($name, "last_DMSG", "none");		# check RAWMSG exists

	my $cmd = $a[0];
	my $cmd2 = $a[1];
	my $count1 = 0;		# Initialisieren - zeilen
	my $count2 = 0;		# Initialisieren - startpos found
	my $count3 = 0;		# Initialisieren - dispatch ok
	my $return = "";

	my $string1pos = AttrVal($name,"StartString","");						# String to find Pos
	my $DispatchMax = AttrVal($name,"DispatchMax","1");					# max value to dispatch from attribut
	my $cmd_raw;																								# cmd_raw to view for user
	my $cmd_sendMSG;																						# cmd_sendMSG to view for user
	my $file = AttrVal($name,"Filename_input","");							# Filename
	my $path = AttrVal($name,"Path","./");											# Path | # Path if not define
	my $Sendername = AttrVal($name,"Sendername","none");				# Sendername to direct send command
	my $Sender_repeats = AttrVal($name,"Senderrepeats",1);			# Senderepeats
	my $Dummyname = AttrVal($name,"Dummyname","none");					# Dummyname
	my $DummyDMSG = InternalVal($Dummyname, "DMSG", "failed");	# P30#7FE
	my $DummyMSGCNT = InternalVal($Dummyname, "MSGCNT", 0);			# DummynameMSGCNT
	my $DummyMSGCNT_old = $DummyMSGCNT;													# DummynameMSGCNT before
	my $DummyMSGCNTvalue = 0;																		# value DummynameMSGCNT before - DummynameMSGCNT
	my $DummyTime = 0;																					# to set DummyTime after dispatch
	my $webCmd = AttrVal($name,"webCmd","");										# webCmd value from attr
	my $DispatchModule = AttrVal($name,"DispatchModule","-");		# DispatchModule List
	my $userattr = AttrVal($name,"userattr","-");								# userattr value
	my $NameDispatchSet = "Dispatch_";													# name of setlist value´s to dispatch
	my $NameSendSet = "Send_";																	# name of setlist value´s to send
	my $messageNumber = AttrVal($name,"MessageNumber",0);				# MessageNumber
	
	my $setList = "";
	$setList = $NameDispatchSet."DMSG ".$NameDispatchSet."RAWMSG";
	$setList .= " ".$NameDispatchSet."RAWMSG_last:noArg "  if ($RAWMSG_last ne "none");
	$setList .= " START:noArg" if (AttrVal($name,"Filename_input","") ne "");
	$setList .= " RAWMSG_M1:noArg" if (AttrVal($name,"RAWMSG_M1","") ne "");
	$setList .= " RAWMSG_M2:noArg" if (AttrVal($name,"RAWMSG_M2","") ne "");
	$setList .= " RAWMSG_M3:noArg" if (AttrVal($name,"RAWMSG_M3","") ne "");
	$setList .= " ".$NameSendSet."RAWMSG" if ($Sendername ne "none");

	Log3 $name, 4, "$name: Set | cmd=$cmd file=$file RAWMSG_last=$RAWMSG_last DMSG_last=$DMSG_last webCmd=$webCmd" if ($cmd ne "?");

	$attr{$name}{webCmd} =~ s/:$NameDispatchSet?RAWMSG_last//g  if (($RAWMSG_last eq "none" && $DMSG_last eq "none") && ($webCmd =~ /:$NameDispatchSet?RAWMSG_last/));

	#### list userattr reload new ####
	if ($cmd eq "?") {
		my @modeltyp;
		my $DispatchFile;

		readingsSingleUpdate($hash, "state" , "ERROR: $path not found! Please check Attributes Path." , 0) if not (-d $path);
		readingsSingleUpdate($hash, "state" , "ready" , 0) if (-d $path && ReadingsVal($name, "state", "none") =~ /^ERROR.*Path.$/);

		opendir(DIR,$path) || return "ERROR: directory $path can not open!";
		while( my $directory_value = readdir DIR ){
		if ($directory_value =~ /^$Filename_Dispatch.*txt/) {
				$DispatchFile = $directory_value;
				$DispatchFile =~ s/$Filename_Dispatch//;
				$DispatchFile =~ s/.txt//;
				push(@modeltyp,$DispatchFile);
			}
		}
		close DIR;
		
		my @modeltyp_sorted = sort { lc($a) cmp lc($b) } @modeltyp;
		my $userattr_list = "DispatchModule:-,".join(",", @modeltyp_sorted);
		$attr{$name}{userattr} = $userattr_list;																				# set model, live always
		$attr{$name}{DispatchModule} = "-" if ($userattr =~ /^DispatchModule:-,$/);			# set DispatchModule to standard

		if ($DispatchModule ne "-") {
			my $count = 0;
			my $returnList = "";
			
			### read file in hash
			open (FileCheck,"<$path$Filename_Dispatch$DispatchModule.txt") || return "ERROR: No file ($Filename_Dispatch$DispatchModule.txt) exists!";
			while (<FileCheck>){
				if ($_ !~ /^#.*/ && $_ ne "\r\n" && $_ ne "\r" && $_ ne "\n") {
					$count++;
					my @arg = split(",", $_);										# a0=Modell | a1=Zustand | a2=RAWMSG
					$arg[1] = "noArg" if ($arg[1] eq "");
					$arg[1] =~ s/[^A-Za-z0-9\-;=_|#?]//g;;			# nur zulässige Zeichen erlauben sonst leicht ERROR
					$List{$arg[0]}{$arg[1]} = $arg[2];
				}
			}
			close FileCheck;
			return "ERROR: your File is not support!" if ($count == 0);

			### build new list for setlist
			foreach my $keys (sort keys %List) {	
				$returnList.= $NameDispatchSet.$DispatchModule."_".$keys . ":" . join(",", sort keys(%{$List{$keys}})) . " ";
			}
			$setList .= " $returnList";
		}
	}


	if ($cmd ne "?") {
			### delete readings ###
		if ($cmd eq $NameDispatchSet."DMSG" || $cmd eq "START" || $cmd =~ /$NameDispatchSet?$DispatchModule.*/ || $cmd eq $NameSendSet."RAWMSG") {
			for my $readingname (qw/cmd_raw cmd_sendMSG last_MSG message_to_module message_dispatched last_DMSG line_read/) {
				readingsDelete($hash,$readingname);
			}
		}

		return "ERROR: no Dummydevice with Attributes (Dummyname) defined!" if ($Dummyname eq "none");

		### Liste von RAWMSG´s dispatchen ###
		if ($cmd eq "START") {
			return "ERROR: no StartString is defined in Attributes!" if ($string1pos eq "");

			(my $error, my @content) = FileRead($path.$file);		# check file open
			$count1 = "-1" if (defined $error);									# file can´t open

			if (not defined $error) {
				if ($string1pos ne "") {
					for ($count1 = 0;$count1<@content;$count1++){		# loop to read file in array
						Log3 $name, 3, "$name: #####################################################################" if ($count1 == 0);
						Log3 $name, 3, "$name: ##### -->>> DISPATCH_TOOL is running (max dispatch=$DispatchMax) !!! <<<-- #####" if ($count1 == 0 && $messageNumber == 0);
						Log3 $name, 3, "$name: ##### -->>> DISPATCH_TOOL is running (MessageNumber) !!! <<<-- #####" if ($count1 == 0 && $messageNumber != 0);

						my $string = $content[$count1];
						$string =~ s/[^A-Za-z0-9\-;=]//g;;			# nur zulässige Zeichen erlauben

						my $pos = index($string,$string1pos);		# check string welcher gesucht wird
						my $pos2 = index($string,"D=");					# check string D= exists
						my $pos3 = index($string,"D=;");				# string D=; for check ERROR Input
						my $lastpos = substr($string,-1);				# for check END of line;

						if ((index($string,("MU;")) >= 0 ) or (index($string,("MS;")) >= 0 ) or (index($string,("MC;")) >= 0 )) {
							$count2++;
							Log3 $name, 4, "$name: readed Line ($count2) | $content[$count1]"." |END|";																		# Ausgabe
							Log3 $name, 5, "$name: Zeile ".($count1+1)." Poscheck string1pos=$pos D=$pos2 D=;=$pos3 lastpos=$lastpos";		# Ausgabe
						}

						if ($pos >= 0 && $pos2 > 1 && $pos3 == -1 && $lastpos eq ";") {				# check if search in array value
							$string = substr($string,$pos,length($string)-$pos);
							$string =~ s/;+/;;/g;		# ersetze ; durch ;;

							### dispatch all ###
							if ($count3 <= $DispatchMax && $messageNumber == 0) {
								Log3 $name, 4, "$name: ($count2) get $Dummyname raw $string";			# Ausgabe
								Log3 $name, 5, "$name: letztes Zeichen '$lastpos' (".ord($lastpos).") in Zeile ".($count1+1)." ist ungueltig " if ($lastpos ne ";");

								fhem("get $Dummyname raw $string");
								$DummyMSGCNT = InternalVal($Dummyname, "MSGCNT", 0);
								$DummyMSGCNTvalue++ if ($DummyMSGCNT - $DummyMSGCNT_old == 1);

								$count3++;
								if ($count3 == $DispatchMax) { last; }		# stop loop
							} elsif ($count2 == $messageNumber) {
								Log3 $name, 4, "$name: ($count2) get $Dummyname raw $string";			# Ausgabe
								Log3 $name, 5, "$name: letztes Zeichen '$lastpos' (".ord($lastpos).") in Zeile ".($count1+1)." ist ungueltig " if ($lastpos ne ";");

								fhem("get $Dummyname raw $string");
								$count3 = 1;
								last;																			# stop loop
							}
						}
					}

					Log3 $name, 3, "$name: ### -->>> no message to Dispatch found !!! <<<-- ###" if ($count3 == 0);
					Log3 $name, 3, "$name: ##### -->>> DISPATCH_TOOL is STOPPED !!! <<<-- #####";
					Log3 $name, 3, "$name: ####################################################";

					$return = "dispatched" if ($count3 > 0);
					$return = "no dispatched -> MessageNumber not found!" if ($count3 == 0);
				} else {
					$return = "no StartString";
				}
			} else {
				$return = $error;
				Log3 $name, 3, "$name: FileRead=$error";		# Ausgabe
			}
		}

		### neue RAWMSG benutzen ###
		if ($cmd eq $NameDispatchSet."RAWMSG") {
			return "ERROR: no RAWMSG" if !defined $a[1];										# no RAWMSG
			my $error = SIGNALduino_TOOL_RAWMSG_Check($name,$a[1],$cmd);		# check RAWMSG
			return "$error" if $error ne "";																# if check RAWMSG failed

			$a[1] =~ s/[^A-Za-z0-9\-;=]//g;;		# nur zulässige Zeichen erlauben
			$a[1] =~ s/;+/;;/g;									# ersetze ; durch ;;
			my $msg = $a[1];
			Log3 $name, 4, "$name: get $Dummyname raw $msg" if (defined $a[1]);

			fhem("get $Dummyname raw $msg");
			$RAWMSG_last = $a[1];
			$DummyTime = InternalVal($Dummyname, "TIME", 0);								# time if protocol dispatched - 1544377856
			$return = "RAWMSG dispatched";
			$count3 = 1;
		}

		### neue DMSG benutzen ###
		if ($cmd eq $NameDispatchSet."DMSG") {
			return "ERROR: argument failed!" if (not $a[1]);
			return "ERROR: wrong argument! (no space at Start & End)" if (not $a[1] =~ /^\S.*\S$/s);
			return "ERROR: wrong DMSG message format!" if ($a[1] =~ /(^(MU|MS|MC)|.*;)/s);

			Dispatch($defs{$Dummyname}, $a[1], undef);

			$RAWMSG_last = "none";
			$DummyMSGCNTvalue = undef;
			$DMSG_last = $a[1];
			$return = "DMSG dispatched";
			$count3 = 1;
		}

		### letzte RAWMSG_last benutzen ###
		if ($cmd eq $NameDispatchSet."RAWMSG_last") {
			###	letzte DMSG_last benutzen, da webCmd auf RAWMSG_last gesetzt
			if ($DMSG_last ne "none" && $RAWMSG_last eq "none") {
				Dispatch($defs{$Dummyname}, $DMSG_last, undef);

				readingsBeginUpdate($hash);
				readingsBulkUpdate($hash, "state" , " DMSG dispatched");
				readingsBulkUpdate($hash, "last_DMSG" , $DMSG_last) if (defined $DMSG_last);
				readingsBulkUpdate($hash, "message_dispatched" , 1);
				readingsEndUpdate($hash, 1);
				return "";
			}

			return "ERROR: no last_MSG." if ($RAWMSG_last eq "none");			# no RAWMSG_last
			$RAWMSG_last =~ s/;/;;/g;																			# ersetze ; durch ;;

			fhem("get $Dummyname raw ".$RAWMSG_last);

			$return = "$cmd dispatched";
			$count3 = 1;
		}

		### RAWMSG_M1|M2|M3 Speicherplatz benutzen ###
		if ($cmd eq "RAWMSG_M1" || $cmd eq "RAWMSG_M2" || $cmd eq "RAWMSG_M3") {
			my $RAWMSG_Memory = AttrVal($name,"$cmd","");
			$RAWMSG_Memory =~ s/;/;;/g;																			# ersetze ; durch ;;

			fhem("get $Dummyname raw ".$RAWMSG_Memory);

			$return = "$cmd dispatched";
			$count3 = 1;
		}

		### RAWMSG from DispatchModule Attributes ###
		if ($cmd ne "-" && $cmd =~ /$NameDispatchSet$DispatchModule.*/ ) {
			my $setcommand;
			my $RAWMSG;

			foreach my $keys (sort keys %List) {	
				if ($cmd =~ /^$NameDispatchSet$DispatchModule\_$keys$/) {
					$setcommand = $DispatchModule."_".$keys;
					$RAWMSG = $List{$keys}{$cmd2} if (defined $cmd2);
					$RAWMSG = $List{$keys}{noArg} if (not defined $cmd2);
					last;
				}
			}
			
			my $error = SIGNALduino_TOOL_RAWMSG_Check($name,$RAWMSG,$cmd);	# check RAWMSG
			return "$error" if $error ne "";																# if check RAWMSG failed

			$RAWMSG =~ s/[^A-Za-z0-9\-;=]//g;;															# nur zulässige Zeichen erlauben
			$RAWMSG =~ s/;/;;/g;																						# ersetze ; durch ;;
			Log3 $name, 4, "$name: get $Dummyname raw $RAWMSG";
			fhem("get $Dummyname raw ".$RAWMSG);
			$DummyTime = InternalVal($Dummyname, "TIME", 0);								# time if protocol dispatched - 1544377856
			$return = "$a[0] dispatched" if (not defined $cmd2);
			$return = "$a[0] -> $a[1] dispatched" if (defined $cmd2);
			$count3 = 1;
			$RAWMSG_last = $RAWMSG;
		}

		### Readings cmd_raw cmd_sendMSG ###		
		if ($cmd eq $NameDispatchSet."RAWMSG" || $cmd =~ /$NameDispatchSet$DispatchModule.*/) {
			my $rawData = $DummyDMSG;
			$rawData =~ s/P|u[0-9]+#//g;						# ersetze P30# durch nichts
			$DummyDMSG =~ s/#/#0x/g;								# ersetze # durch #0x
			my $hlen = length($rawData);
			my $blen = $hlen * 4;
			my $bitData = unpack("B$blen", pack("H$hlen", $rawData));

			Log3 $name, 4, "$name: Dummyname_Time=$DummyTime time=".time()." diff=".(time()-$DummyTime)." DMSG=$DummyDMSG rawData=$rawData";

			if (time() - $DummyTime < 2)	{
				$cmd_raw = "D=$bitData";
				$cmd_sendMSG = "set $Dummyname sendMSG $DummyDMSG#R5 (check Data !!!)";
			} else {
				$cmd_raw = "no rawMSG! Protocol not decoded!";
				$cmd_sendMSG = "no sendMSG! Protocol not decoded!";
			}
		}

		### Readings cmd_raw cmd_sendMSG ###
		if ($cmd eq $NameSendSet."RAWMSG") {
			return "ERROR: argument failed!" if (not $a[1]);
			return "ERROR: wrong message! syntax is wrong!" if (not $a[1] =~ /^(MU|MS|MC);.*D=/);

			my $RAWMSG = $a[1];
			chomp ($RAWMSG);																				# Zeilenende entfernen
			$RAWMSG =~ s/[^A-Za-z0-9\-;=]//g;;											# nur zulässige Zeichen erlauben sonst leicht ERROR
			$RAWMSG = $1 if ($RAWMSG =~ /^(.*;D=\d+?;).*/);					# cut ab ;CP=

			my $prefix;
			if (substr($RAWMSG,0,2) eq "MU") {
				$prefix = "SR;R=$Sender_repeats";
			} elsif (substr($RAWMSG,0,2) eq "MS") {
				$prefix = "SM;R=$Sender_repeats";
			} elsif (substr($RAWMSG,0,2) eq "MC") {
				$prefix = "SC;R=$Sender_repeats";
			}
			
			$RAWMSG = $prefix.substr($RAWMSG,2,length($RAWMSG)-2);
			$RAWMSG =~ s/;/;;/g;;
			
			Log3 $name, 4, "$name: set $Sendername raw $RAWMSG";
			fhem("set $Sendername raw ".$RAWMSG);
			
			$RAWMSG_last = $a[1];
			$count3 = undef;
			$DummyMSGCNTvalue = undef;
			$return = "send RAWMSG";
			#return "The function are in development!";
		}
		
		### counter message_to_module ###
		$DummyMSGCNT = InternalVal($Dummyname, "MSGCNT", 0);
		if ($cmd ne "START") {
			 $DummyMSGCNTvalue++ if ($DummyMSGCNT - $DummyMSGCNT_old >= 1);
		}

		$RAWMSG_last =~ s/;;/;/g;																						# ersetze ; durch ;;

		readingsDelete($hash,"line_read") if ($cmd ne "START");

		readingsBeginUpdate($hash);
		readingsBulkUpdate($hash, "state" , $return);
		readingsBulkUpdate($hash, "cmd_raw" , $cmd_raw) if (defined $cmd_raw);
		readingsBulkUpdate($hash, "cmd_sendMSG" , $cmd_sendMSG) if (defined $cmd_sendMSG);
		readingsBulkUpdate($hash, "last_MSG" , $RAWMSG_last) if ($RAWMSG_last ne "none");
		readingsBulkUpdate($hash, "last_DMSG" , $DMSG_last) if ($DMSG_last ne "none");
		readingsBulkUpdate($hash, "line_read" , $count1+1) if ($cmd eq "START");
		readingsBulkUpdate($hash, "message_dispatched" , $count3) if (defined $count3);
		readingsBulkUpdate($hash, "message_to_module" , $DummyMSGCNTvalue, 0) if (defined $DummyMSGCNTvalue);
		readingsEndUpdate($hash, 1);

		Log3 $name, 4, "$name: Set | cmd=$cmd RAWMSG_last=$RAWMSG_last DMSG_last=$DMSG_last webCmd=$webCmd" if ($cmd ne "?");

		if (($RAWMSG_last ne "none" || $DMSG_last ne "none") && (not $webCmd =~ /:$NameDispatchSet?RAWMSG_last/) && $cmd ne "?") {
				$webCmd .= ":$NameDispatchSet"."RAWMSG_last";
				$attr{$name}{webCmd} = $webCmd;
		}

		#Log3 $name, 3, "$name: Set | cmd=$cmd RAWMSG_last=$RAWMSG_last DMSG_last=$DMSG_last webCmd=$webCmd" if ($cmd ne "?");
		return;
	}

	return $setList;
}

################################
sub SIGNALduino_TOOL_Get($$$@) {
	my ( $hash, $name, $cmd, @a ) = @_;
	my $Filename_input = AttrVal($name,"Filename_input","");
	my $Filename_export = AttrVal($name,"Filename_export","");
	my $path = AttrVal($name,"Path","./");
	my $onlyDataName = "-ONLY_DATA-";
	my $list = "TimingsList:noArg invert_bitMsg invert_hexMsg change_bitMsg_to_hexMsg change_hexMsg_to_bitMsg ";
	$list .= "FilterFile:multiple,bitMsg:,bitMsg_invert:,dmsg:,hexMsg:,hexMsg_invert:,MC;,MS;,MU;,RAWMSG:,READredu:,READ:,UserInfo:,$onlyDataName ".
					"All_ClockPulse:noArg All_SyncPulse:noArg InputFile_one_ClockPulse InputFile_one_SyncPulse InputFile_doublePulse:noArg InputFile_length_Datapart:noArg" if ($Filename_input ne "");
	my $linecount = 0;
	my $founded = 0;
	my $search = "";
	my $value;
	my @Zeilen = ();

	if ($cmd ne "?") {
		for my $readingname (qw/cmd_raw cmd_sendMSG last_MSG last_DMSG message_to_module message_dispatched/) {
			readingsDelete($hash,$readingname);
		}
	}

	if ($cmd eq "TimingsList") {
		my %ProtocolListSIGNALduino = SIGNALduino_LoadProtocolHash("$attr{global}{modpath}/FHEM/lib/signalduino_protocols.hash");
		if (exists($ProtocolListSIGNALduino{error})  ) {
			Log3 "SIGNALduino", 1, "Error loading Protocol Hash. Module is in inoperable mode error message:($ProtocolListSIGNALduino{error})";
			delete($ProtocolListSIGNALduino{error});
			return undef;
		}

		my $file = "timings.txt";
		my @value;																																					# for values from hash_list
		my @value_name = ("one","zero","start","pause","end","sync","clockrange","float");	# for max numbre of one [0] | zero [1] | start [2] | sync [3]
		my @value_max = ();																																	# for max numbre of one [0] | zero [1] | start [2] | sync [3]
		my $valuecount = 0;																																	# Werte für array

		open(TIMINGS_LOG, ">$path$file");

		### for find max ... in array alles one - zero - sync ....
		foreach my $timings_protocol(sort {$a <=> $b} keys %ProtocolListSIGNALduino) {
			### max Werte von value_name array ###						
			for my $i (0..scalar(@value_name)-1) {
				$value_max[$i] = 0 if (not exists $value_max[$i]);
				$value_max[$i] = scalar(@{$ProtocolListSIGNALduino{$timings_protocol}{$value_name[$i]}})  if (exists $ProtocolListSIGNALduino{$timings_protocol}{$value_name[$i]} && scalar(@{$ProtocolListSIGNALduino{$timings_protocol}{$value_name[$i]}}) > $value_max[$i]);
			}
		}

		### einzelne Werte ###
		foreach my $timings_protocol(sort {$a <=> $b} keys %ProtocolListSIGNALduino) {
			for my $i (0..scalar(@value_name)-1) {

				### Kopfzeilen Beschriftung ###
				if ($timings_protocol == 0 && $i == 0) {
					print TIMINGS_LOG "id;" ;
					print TIMINGS_LOG "typ;" ;
					print TIMINGS_LOG "clockabs;" ;
					for my $i (0..scalar(@value_name)-1) {
						for my $i2 (1..$value_max[$i]) {
							print TIMINGS_LOG $value_name[$i].";";			
						}
					}
					print TIMINGS_LOG "clientmodule;";
					print TIMINGS_LOG "preamble;";
					print TIMINGS_LOG "name;";
					print TIMINGS_LOG "comment"."\n" ;
				}
				### ENDE ###

				foreach my $e(@{$ProtocolListSIGNALduino{$timings_protocol}{$value_name[$i]}}) {
					$value[$valuecount] = $e;
					$valuecount++;
				}

				if ($i == 0) {
					print TIMINGS_LOG $timings_protocol.";"; 																			# ID Nummer
					### Message - Typ
					if (exists $ProtocolListSIGNALduino{$timings_protocol}{format} && $ProtocolListSIGNALduino{$timings_protocol}{format} eq "manchester") {
						print TIMINGS_LOG "MC".";";
					} elsif (exists $ProtocolListSIGNALduino{$timings_protocol}{sync}) {
						print TIMINGS_LOG "MS".";";
					} else {
						print TIMINGS_LOG "MU".";";
					}
					###
					if (exists $ProtocolListSIGNALduino{$timings_protocol}{clockabs}) {
						print TIMINGS_LOG $ProtocolListSIGNALduino{$timings_protocol}{clockabs}.";";	# clockabs
					} else {
						print TIMINGS_LOG ";";
					}
				}

				if (scalar(@value) > 0) {
					foreach my $f (@value) {		# Werte
						print TIMINGS_LOG $f;
						print TIMINGS_LOG ";";
					}
				}

				for ( my $anzahl = $valuecount; $anzahl < $value_max[$i]; $anzahl++ ) {
					print TIMINGS_LOG ";";
				}

				$valuecount = 0;			# reset
				@value = ();					# reset
			}

			if (exists $ProtocolListSIGNALduino{$timings_protocol}{clientmodule}) {
				print TIMINGS_LOG $ProtocolListSIGNALduino{$timings_protocol}{clientmodule}.";";
			} else {
				print TIMINGS_LOG ";";
			}

			if (exists $ProtocolListSIGNALduino{$timings_protocol}{preamble}) {
				print TIMINGS_LOG $ProtocolListSIGNALduino{$timings_protocol}{preamble}.";";
			} else {
				print TIMINGS_LOG ";";
			}

			print TIMINGS_LOG $ProtocolListSIGNALduino{$timings_protocol}{name}.";" if exists($ProtocolListSIGNALduino{$timings_protocol}{name});

			if (exists $ProtocolListSIGNALduino{$timings_protocol}{comment}) {
				print TIMINGS_LOG $ProtocolListSIGNALduino{$timings_protocol}{comment}."\n";
			} else {
				print TIMINGS_LOG "\n";
			}
		}
		close TIMINGS_LOG;

		readingsSingleUpdate($hash, "state" , "TimingsList created", 0);
		return "New TimingsList ($file) are created!\nFile is in $path directory from FHEM.";
	}

	if ($cmd eq "FilterFile") {
		my $manually = 0;
		my $only_Data = 0;
		my $Data_parts = 1;
		my $save = "";
		my $pos;
		return "ERROR: Your arguments in Filename_input is not definded!" if (not defined $a[0]);

		Log3 $name, 4, "SIGNALduino_TOOL_Get: cmd $cmd - a0=$a[0]";
		Log3 $name, 4, "SIGNALduino_TOOL_Get: cmd $cmd - a0=$a[0] a0=$a[1]" if (defined $a[1]);
		Log3 $name, 4, "SIGNALduino_TOOL_Get: cmd $cmd - a0=$a[0] a1=$a[1] a2=$a[2]" if (defined $a[1] && defined $a[2]);
		
		### Auswahl checkboxen - ohne Textfeld Eingabe ###
		my $check = 0;
		$search = $a[0];
		
		if (defined $a[1]) {
			$search.= " ".$a[1];
			$a[0] = $search;
		}
		
		if (defined $a[1] && $a[1] =~ /.*$onlyDataName.*/) {
			return "This option is supported with only one argument!";
		}
		
		my @arg = split(",", $a[0]);
		
		### check - mehr als 1 Auswahlbox selektiert ###
		if (scalar(@arg) != 1) {
			$search =~ tr/,/|/;
		}
		
		### check - Option only_Data in Auswahl selektiert ###
		if (grep /$onlyDataName/, @arg) {
			$only_Data = 1;
			$Data_parts = scalar(@arg) - 1;
			$search =~ s/\|$onlyDataName//g;
		}

		Log3 $name, 4, "SIGNALduino_TOOL_Get: cmd $cmd - searcharg=$search  splitting arg from a0=".scalar(@arg)."  manually=$manually  only_Data=$only_Data";

		return "ERROR: Your Attributes Filename_input is not definded!" if ($Filename_input eq "");

		open (InputFile,"<$path$Filename_input") || return "ERROR: No file ($Filename_input) found in $path directory from FHEM!";
		while (<InputFile>){
			if ($_ =~ /$search/s){
				chomp ($_);														# Zeilenende entfernen
				if ($only_Data == 1) {
					if ($Data_parts == 1) {
						$pos = index($_,"$search");
						$save = substr($_,$pos+length($search)+1,(length($_)-$pos)) if not ($search =~ /MC;|MS;|MU;/);
						$save = substr($_,$pos,(length($_)-$pos)) if ($search =~ /MC;|MS;|MU;/);
						Log3 $name, 5, "SIGNALduino_TOOL_Get: cmd $cmd - startpos=$pos line save=$save";
						push(@Zeilen,$save);							# Zeile in array
					} else {
						foreach my $i (0 ... $Data_parts-1) {
							$pos = index($_,$arg[$i]);
							$save = substr($_,$pos+length($arg[$i])+1,(length($_)-$pos));
							Log3 $name, 5, "SIGNALduino_TOOL_Get: cmd $cmd - startpos=$pos line save=$save";
							if ($pos >= 0) {
								push(@Zeilen,$save);					# Zeile in array
							}
						}
					}
				} else {
					$save = $_;
					push(@Zeilen,$save);								# Zeile in array
				}
				$founded++;
			}
			$linecount++;
		}
		close InputFile;

		for my $readingname (qw/cmd_raw cmd_sendMSG last_MSG message_dispatched message_to_module/) {		# delete reading cmd_raw & cmd_sendMSG
			readingsDelete($hash,$readingname);
		}

		readingsSingleUpdate($hash, "line_read" , $linecount, 0);
		readingsSingleUpdate($hash, "state" , "data filtered", 0);

		return "ERROR: Your filter (".$search.") found nothing!\nNo file saved!" if ($founded == 0);
		return "ERROR: Your Attributes Filename_export is not definded!" if ($Filename_export eq "");

		open(OutFile, ">$path$Filename_export");
		for (@Zeilen) {
			print OutFile $_."\n";
		}
		close OutFile;

		return "$cmd are ready!";
	}

	if ($cmd eq "All_ClockPulse" || $cmd eq "All_SyncPulse") {
		my $ClockPulse = 0;			# array Zeilen
		my $SyncPulse = 0;			# array Zeilen
		$search = "CP=" if ($cmd eq "All_ClockPulse");
		$search = "SP=" if ($cmd eq "All_SyncPulse");
		my $min = 0;
		my $max = 0;
		my $CP;
		my $SP;
		my $pos2;
		my $valuepercentmin;
		my $valuepercentmax;

		return "ERROR: Your Attributes Filename_input is not definded!" if ($Filename_input eq "");

		open (InputFile,"<$path$Filename_input") || return "ERROR: No file ($Filename_input) found in $path directory from FHEM!";
		while (<InputFile>){
			if ($_ =~ /$search/s){
				chomp ($_);												# Zeilenende entfernen
				my $pos = index($_,"$search");
				my $text = substr($_,$pos,10);
				$text = substr($text, 0 ,index ($text,";"));

				if ($cmd eq "All_ClockPulse") {
					$text =~ s/CP=//g;
					$CP = $text;
					$pos2 = index($_,"P$CP=");
				} elsif ($cmd eq "All_SyncPulse") {
					$text =~ s/SP=//g;
					$SP = $text;
					$pos2 = index($_,"P$SP=");
				}

				my $text2 = substr($_,$pos2,12);
				$text2 = substr($text2, 0 ,index ($text2,";"));

				if ($cmd eq "All_ClockPulse") {
					$text2 = substr($text2,length($text2)-3);
					$ClockPulse += $text2;
				}	elsif ($cmd eq "All_SyncPulse") {
					$text2 =~ s/P$SP=//g;
					$SyncPulse += $text2;
				}

				if ($min == 0) {
					$min = $text2;
					$max = $text2;
				}

				if ($text2 < $min) { $min = $text2; }
				if ($text2 > $max) { $max = $text2; }

				$founded++;
			}
			$linecount++;
		}
		close InputFile;

		readingsSingleUpdate($hash, "line_read" , $linecount, 0);
		readingsSingleUpdate($hash, "state" , substr($cmd,4)." calculated", 0);

		return "ERROR: no ".substr($cmd,4)." found!" if ($founded == 0);
		$value = $ClockPulse/$founded if ($cmd eq "All_ClockPulse");
		$value = $SyncPulse/$founded if ($cmd eq "All_SyncPulse");

		for my $readingname (qw/cmd_raw cmd_sendMSG last_MSG message_dispatched message_to_module/) {		# delete reading cmd_raw & cmd_sendMSG
			readingsDelete($hash,$readingname);
		}

		$value = sprintf "%.0f", $value;	## round value
		$valuepercentmin = sprintf "%.0f", abs((($min*100)/$value)-100);
		$valuepercentmax = sprintf "%.0f", abs((($max*100)/$value)-100);

		return substr($cmd,4)." &Oslash; are ".$value." at $founded readed values!\nmin: $min (- $valuepercentmin%) | max: $max (+ $valuepercentmax%)";
	}

	if ($cmd eq "InputFile_one_ClockPulse" || $cmd eq "InputFile_one_SyncPulse") {
		return "ERROR: Your Attributes Filename_input is not definded!" if ($Filename_input eq "");
		return "ERROR: ".substr($cmd,14)." is not definded" if (not $a[0]);
		return "ERROR: wrong value of $cmd! only [0-9]!" if (not $a[0] =~ /^(-\d+|\d+$)/ && $a[0] > 1);

		my $ClockPulse = 0;			# array Zeilen
		my $SyncPulse = 0;			# array Zeilen
		$search = "CP=" if ($cmd eq "InputFile_one_ClockPulse");
		$search = "SP=" if ($cmd eq "InputFile_one_SyncPulse");
		my $CP;
		my $SP;
		my $pos2;
		my $tol = 0.15;

		open (InputFile,"<$path$Filename_input") || return "ERROR: No file ($Filename_input) found in $path directory from FHEM!";
		while (<InputFile>){
			if ($_ =~ /$search/s){
				chomp ($_);												# Zeilenende entfernen
				my $pos = index($_,"$search");
				my $text = substr($_,$pos,10);
				$text = substr($text, 0 ,index ($text,";"));

				if ($cmd eq "InputFile_one_ClockPulse") {
					$text =~ s/CP=//g;
					$CP = $text;
					$pos2 = index($_,"P$CP=");
				} elsif ($cmd eq "InputFile_one_SyncPulse") {
					$text =~ s/SP=//g;
					$SP = $text;
					$pos2 = index($_,"P$SP=");
				}

				my $text2 = substr($_,$pos2,12);
				$text2 = substr($text2, 0 ,index ($text2,";"));

				if ($cmd eq "InputFile_one_ClockPulse") {
					$text2 = substr($text2,length($text2)-3);
					$ClockPulse += $text2;
				}	elsif ($cmd eq "InputFile_one_SyncPulse") {
					$text2 =~ s/P$SP=//g;
					$SyncPulse += $text2;
				}

				my $tol_min = abs($a[0]*(1-$tol));
				my $tol_max = abs($a[0]*(1+$tol));

				if (abs($text2) > $tol_min && abs($text2) < $tol_max) {
					push(@Zeilen,$_);							# Zeile in array
					$founded++;
				}
			}
			$linecount++;
		}
		close InputFile;

		readingsSingleUpdate($hash, "line_read" , $linecount, 0);
		readingsSingleUpdate($hash, "state" , substr($cmd,14)." NOT in tol found!", 0) if ($founded == 0);
		readingsSingleUpdate($hash, "state" , substr($cmd,14)." in tol found ($founded)", 0) if ($founded != 0);

		return "ERROR: Your Attributes Filename_export is not definded!" if ($Filename_export eq "");
		open(OutFile, ">$path$Filename_export");
		for (@Zeilen) {
			print OutFile $_."\n";
		}
		close OutFile;

		return "ERROR: no $cmd with value $a[0] in tol!" if ($founded == 0);
		return substr($cmd,14)." in tol found!";
	}
	
	if ($cmd eq "invert_bitMsg" || $cmd eq "invert_hexMsg") {
		return "ERROR: Your input failed!" if (not defined $a[0]);
		return "ERROR: wrong value $a[0]! only [0-1]!" if ($cmd eq "invert_bitMsg" && not $a[0] =~ /^[0-1]+$/);
		return "ERROR: wrong value $a[0]! only [a-fA-f0-9]!" if ($cmd eq "invert_hexMsg" && not $a[0] =~ /^[a-fA-f0-9]+$/);

		if ($cmd eq "invert_bitMsg") {
			$value = $a[0];
			$value =~ tr/01/10/;															# ersetze ; durch ;;
		} elsif ($cmd eq "invert_hexMsg") {
			my $hlen = length($a[0]);
			my $blen = $hlen * 4;
			my $bitData = unpack("B$blen", pack("H$hlen", $a[0]));
			$bitData =~ tr/01/10/;
			$value = sprintf("%X", oct("0b$bitData"));		
		}

		return "Your $cmd is ready.\n\n  Input: $a[0]\n Output: $value";
	}
	
	if ($cmd eq "change_hexMsg_to_bitMsg" || $cmd eq "change_bitMsg_to_hexMsg") {
		return "ERROR: Your input failed!" if (not defined $a[0]);
		return "ERROR: wrong value $a[0]! only [0-1]!" if ($cmd eq "change_bitMsg_to_hexMsg" && not $a[0] =~ /^[0-1]+$/);
		return "ERROR: wrong value $a[0]! only [a-fA-f0-9]!" if ($cmd eq "change_hexMsg_to_bitMsg" && not $a[0] =~ /^[a-fA-f0-9]+$/);

		if ($cmd eq "change_bitMsg_to_hexMsg") {
			$value = sprintf("%x", oct( "0b$a[0]" ) );
			$value = sprintf("%X", oct( "0b$a[0]" ) );
			return "Your $cmd is ready.\n\nInput: $a[0]\n  Hex: $value";
		} elsif ($cmd eq "change_hexMsg_to_bitMsg") {
			$value = sprintf( "%b", hex( $a[0] ) );
			return "Your $cmd is ready.\n\nInput: $a[0]\n  Bin: $value";
		}
	}

	if ($cmd eq "InputFile_doublePulse") {
		return "ERROR: Your Attributes Filename_input is not definded!" if ($Filename_input eq "");

		my $counterror = 0;
		my $MUerror = 0;
		my $MSerror = 0;
		
		open (InputFile,"<$path$Filename_input") || return "ERROR: No file ($Filename_input) found in $path directory from FHEM!";
		while (<InputFile>){
			if ($_ =~ /READredu:\sM(U|S);/s){
				chomp ($_);										# Zeilenende entfernen
				my $checkData = $_;

				#$_ =~ s/^.*;D=//g;						# cut bis D=		# OLD
				#$_ =~ s/;CP=.*//g;						# cut ab ;CP=		# OLD
				$_ = $1 if ($_ =~ /.*;D=(\d+?);.*/);			# cut bis D= & ab ;CP= 	# NEW

				my @array_Data = split("",$_);
				my $pushbefore = "";
				foreach (@array_Data) {
					if ($pushbefore eq $_) {
						$counterror++;
						push(@Zeilen,"ERROR with same Pulses - $counterror");
						push(@Zeilen,$checkData);
						if ($checkData =~ /MU;/s) { $MUerror++; }
						if ($checkData =~ /MS;/s) { $MSerror++; }						
					}
					$pushbefore = $_;
				}
				$founded++;
			}
			$linecount++;
		}
		close InputFile;

		return "ERROR: Your Attributes Filename_export is not definded!" if ($Filename_export eq "");
		open(OutFile, ">$path$Filename_export");
		for (@Zeilen) {
			print OutFile $_."\n";
		}
		close OutFile;
		return "no doublePulse found!" if $founded == 0;
		my $percenterrorMU = sprintf ("%.2f", ($MUerror*100)/$founded);
		my $percenterrorMS = sprintf ("%.2f", ($MSerror*100)/$founded);

		return "$cmd are finished.\n\n- read $linecount lines\n- found $founded messages (MS|MU)\n- found MU with ERROR = $MUerror ($percenterrorMU"."%)\n- found MS with ERROR = $MSerror ($percenterrorMS"."%)";
	}
	
	if ($cmd eq "InputFile_length_Datapart") {
		return "ERROR: Your Attributes Filename_input is not definded!" if ($Filename_input eq "");
		my @dataarray;
		my $dataarray_min;
		my $dataarray_max;

		open (InputFile,"<$path$Filename_input") || return "ERROR: No file ($Filename_input) found in $path directory from FHEM!";
		while (<InputFile>){
			if ($_ =~ /M(U|S);/s){
				$_ = $1 if ($_ =~ /.*;D=(\d+?);.*/);			# cut bis D= & ab ;CP= 	# NEW
				my $length_data = length($_);
				push (@dataarray,$length_data),
				($dataarray_min,$dataarray_max) = (sort {$a <=> $b} @dataarray)[0,-1];
				$linecount++;
			}
		}
		close InputFile;

		return "length of Datapart from RAWMSG in $linecount lines.\n\nmin:$dataarray_min max:$dataarray_max";
	}

	return "Unknown argument $cmd, choose one of $list";

}

################################
sub SIGNALduino_TOOL_Attr() {
	my ($cmd, $name, $attrName, $attrValue) = @_;
	my $hash = $defs{$name};
	my $typ = $hash->{TYPE};
	my $webCmd = AttrVal($name,"webCmd","");										# webCmd value from attr
	my $cmdIcon = AttrVal($name,"cmdIcon","");									# webCmd value from attr
	my $path = AttrVal($name,"Path","./");											# Path | # Path if not define
	my $Filename_input = AttrVal($name,"Filename_input","");
	my $DispatchModule = AttrVal($name,"DispatchModule","-");		# DispatchModule List
	my @Zeilen = ();

	if ($cmd eq "set" && $init_done == 1 ) {

		### memory for three message
		if ($attrName eq "RAWMSG_M1" || $attrName eq "RAWMSG_M2" || $attrName eq "RAWMSG_M3" && $attrValue ne "") {
			my $error = SIGNALduino_TOOL_RAWMSG_Check($name, $attrValue, $cmd);		# check RAWMSG
			return "$error" if $error ne "";																			# if check RAWMSG failed

			### set new webCmd & cmdIcon ###
			my $attrNameNr	= substr($attrName,-1);
			$webCmd .= ":$attrName";
			$cmdIcon .= " $attrName:remotecontrol/black_btn_$attrNameNr";
			$attr{$name}{webCmd} = $webCmd;
			$attr{$name}{cmdIcon} = $cmdIcon;
		}

		### name of dummy to work with this tool
		if ($attrName eq "Dummyname") {
			### Check, eingegebener Dummyname als Device definiert?
			my @dummy = ();
			foreach my $d (sort keys %defs) {
				if(defined($defs{$d}) && $defs{$d}{TYPE} eq "SIGNALduino" && $defs{$d}{DeviceName} eq "none") {
					push(@dummy,$d);
				}
			}
			return "ERROR: Your $attrName is wrong!\n\nDevices to use: \n- ".join("\n- ",@dummy) if (not grep /^$attrValue$/, @dummy);
		}

		### name of initialized sender to work with this tool
		if ($attrName eq "Sendername") {
			### Check, eingegebener Sender als Device definiert?
			my @sender = ();
			foreach my $d (sort keys %defs) {
				if(defined($defs{$d}) && $defs{$d}{TYPE} eq "SIGNALduino" && $defs{$d}{DeviceName} ne "none" && $defs{$d}{DevState} eq "initialized") {
					push(@sender,$d);
				}
			}
			return "ERROR: Your $attrName is wrong!\n\nDevices to use: \n- ".join("\n- ",@sender) if (not grep /^$attrValue$/, @sender);
		}

		### max value for dispatch
		if ($attrName eq "DispatchMax") {
			return "Your $attrName value must only numbers!" if (not $attrValue =~ /^[0-9]/s);
			return "Your $attrName value is to great! (max 10000)" if ($attrValue > 10000);
			return "Your $attrName value is to short!" if ($attrValue < 1);
		}

		### input file for data
		if ($attrName eq "Filename_input") {
			return "Your Attributes $attrName must defined!" if ($attrValue eq "1");

			### all files in path
			opendir(DIR,$path) || return "ERROR: attr $attrName follow with Error in opening dir $path!";
			my @errorlist = ();
			while( my $directory_value = readdir DIR ){
					if ($directory_value =~ /.txt$/) {
						push(@errorlist,$directory_value);
					}
			}
			close DIR;
			my @errorlist_sorted = sort { lc($a) cmp lc($b) } @errorlist;
			
			### check file from attrib
			open (FileCheck,"<$path$attrValue") || return "ERROR: No file ($attrValue) exists for attrib Filename_input!\n\nFiles in path:\n- ".join("\n- ",@errorlist_sorted);
			close FileCheck;
		
			$attr{$name}{webCmd}	= "START" if ( not exists($attr{$name}{webCmd}) || $webCmd !~ /START/ );							# set model, if only undef --> new def
		}

		### dispatch from file with line check
		if ($attrName eq "DispatchModule" && $attrValue ne "-") {
			my $DispatchModuleOld = $DispatchModule;
			my $DispatchModuleNew = $attrValue;
			%List = () if ($DispatchModuleOld ne $attrValue);

			my $count;

			open (FileCheck,"<$path$Filename_Dispatch$attrValue.txt") || return "ERROR: No file $Filename_Dispatch$attrValue.txt exists!";
			while (<FileCheck>){
				$count++;
				if ($_ !~ /^#.*/ && $_ ne "\r\n" && $_ ne "\r" && $_ ne "\n") {
					chomp ($_);												# Zeilenende entfernen
					$_ =~ s/[^A-Za-z0-9\-;,=]//g;;		# nur zulässige Zeichen erlauben

					return "ERROR: the line $count in file $path$Filename_Dispatch$attrValue.txt have a wrong syntax! [<model>,<state>,<RAWMSG>]" if (not $_ =~ /^.*,.*,.*;.*/);
					return "ERROR: the line $count in file $path$Filename_Dispatch$attrValue.txt have a wrong RAWMSG! syntax RAWMSG is wrong. no ; at end of line!" if (not $_ =~ /.*;$/);					# end of RAWMSG ;
					return "ERROR: the line $count in file $path$Filename_Dispatch$attrValue.txt have a wrong RAWMSG! no MU;|MC;|MS;"		if not $_ =~ /(?:MU;|MC;|MS;).*/;														# MU;|MC;|MS;
					return "ERROR: the line $count in file $path$Filename_Dispatch$attrValue.txt have a wrong RAWMSG! D= are not [0-9]"		if ($_ =~ /(?:MU;|MS;).*/ && not $_ =~ /D=[0-9]*;/);			# MU|MS D= with [0-9]
					return "ERROR: the line $count in file $path$Filename_Dispatch$attrValue.txt have a wrong RAWMSG! D= are not [0-9][A-F]" 	if ($_ =~ /(?:MC).*/ && not $_ =~ /D=[0-9A-F]*;/);		# MC D= with [0-9A-F]
				}
			}
			close FileCheck;

			return "Your Attributes $attrName must defined!" if ($attrValue eq "1");
		}
		
		### repeats for sender
		if ($attrName eq "Senderrepeats" && $attrValue gt "25") {
			return "ERROR: Your attrib $attrName with value $attrValue are wrong!\nPlease put a value smaler 25 repeats.";
		}

		Log3 $name, 3, "$name: set Attributes $attrName to $attrValue";
	}

	
	if ($cmd eq "del") {
		### delete attribut memory for three message
		if ($attrName eq "RAWMSG_M1" || $attrName eq "RAWMSG_M2" || $attrName eq "RAWMSG_M3") {
			$webCmd =~ s/:$attrName//g;						# ersetze :RAWMSG_M1 durch nichts
			$attr{$name}{webCmd} = $webCmd;
			if ($cmdIcon ne "") {
				my $attrNameNr	= substr($attrName,-1);
				my $regexvalue = $attrName.":remotecontrol/black_btn_".$attrNameNr;
				$cmdIcon =~ s/$regexvalue//g;
				if ($cmdIcon ne "") {
					$attr{$name}{cmdIcon} = $cmdIcon;
				} else {
					delete $attr{$name}{cmdIcon};
				}
			}
		}
		
		### delete file for input
		if ($attrName eq "Filename_input") {
			$webCmd =~ s/(?:START:|START)//g;			# ersetze :RAWMSG_M1 durch nichts
			if ($webCmd eq "") {
				delete $attr{$name}{webCmd};
			} else {
				$attr{$name}{webCmd} = $webCmd;
			}
		}

		Log3 $name, 3, "$name: $cmd Attributes $attrName";
	}

}

################################
sub SIGNALduino_TOOL_RAWMSG_Check($$$) {
	my ( $name, $message, $cmd ) = @_;
	$message =~ s/[^A-Za-z0-9\-;=]//g;;		# nur zulässige Zeichen erlauben
	Log3 $name, 4, "$name: RAWMSG_Check is running for $cmd with $message";

	return "ERROR: no attribute value defined" 	if ($message =~ /^1/ && $cmd eq "set");																			# attr without value
	return "ERROR: wrong RAWMSG - no MU;|MC;|MS; at start" 	if not $message =~ /^(?:MU;|MC;|MS;).*/;												# Start with MU;|MC;|MS;
	return "ERROR: wrong RAWMSG - D= are not [0-9]" 		if ($message =~ /^(?:MU;|MS;).*/ && not $message =~ /D=[0-9]*;/);		# MU|MS D= with [0-9]
	return "ERROR: wrong RAWMSG - D= are not [0-9][A-F]" 	if ($message =~ /^(?:MC).*/ && not $message =~ /D=[0-9A-F]*;/);		# MC D= with [0-9A-F]
	return "ERROR: wrong RAWMSG - End of Line missing ;" 	if not $message =~ /;\Z/;																					# End Line with ;
  return "";		# check END
}


# Eval-Rückgabewert für erfolgreiches
# Laden des Moduls
1;


# Beginn der Commandref

=pod
=item [helper|device|command]
=item summary Tool from SIGNALduino
=item summary_DE Tool vom SIGNALduino

=begin html

<a name="SIGNALduino_TOOL"></a>
<h3>SIGNALduino_TOOL</h3>
<ul>
	The module is for the support of developers of the SIGNALduino project. It includes various functions for calculation / filtering / dispatchen / conversion and much more.<br><br><br>

	<b>Define</b><br>
	<ul><code>define &lt;NAME&gt; SIGNALduino_TOOL</code><br><br>
	example: define sduino_TOOL SIGNALduino_TOOL
	</ul><br><br>

	<a name="SIGNALduino_TOOL_Set"></a>
	<b>Set</b>
	<ul><li><a name="Dispatch_DMSG"></a><code>Dispatch_DMSG</code> - a finished DMSG from modul to dispatch (without SIGNALduino processing!)</li><a name=""></a></ul>
	<ul><li><a name="Dispatch_RAWMSG"></a><code>Dispatch_RAWMSG</code> - one RAW message to dispatch</li><a name=""></a></ul>
	<ul><li><a name="Dispatch_RAWMSG_last"></a><code>Dispatch_RAWMSG_last</code> - dispatch the last RAW message</li><a name=""></a></ul>
	<ul><li><a name="modulname"></a><code>&lt;modulname&gt;</code> - dispatch a message of the selected module from the DispatchModule attribute</li><a name=""></a></ul>
	<ul><li><a name="START"></a><code>START</code> - starts the loop for automatic dispatch</li><a name=""></a></ul>
	<ul><li><a name="Send_RAWMSG"></a><code>Send_RAWMSG</code> - send one MU | MS | MC RAWMSG with the defined Sendename (attributes Sendename needed!)</li><a name=""></a></ul>
	<a name=""></a>
	<br>

	<a name="SIGNALduino_TOOL_Get"></a>
	<b>Get</b>
	<ul><li><a name="All_ClockPulse"></a><code>All_ClockPulse</code> - calculates the average of the ClockPulse from Input_File</li><a name=""></a></ul>
	<ul><li><a name="All_SyncPulse"></a><code>All_SyncPulse</code> - calculates the average of the SyncPulse from Input_File</li><a name=""></a></ul>
	<ul><li><a name="FilterFile"></a><code>FilterFile</code> - creates a file with the filtered values</li><a name=""></a></ul>
	<ul><li><a name="InputFile_doublePulse"></a><code>InputFile_doublePulse</code> - searches for duplicate pulses in the data part of the individual messages in the input_file and filters them into the export_file</li><a name=""></a></ul>
	<ul><li><a name="InputFile_length_Datapart"></a><code>InputFile_length_Datapart</code> - determines the min and max lenght of the readed RAWMSG.</li><a name=""></a></ul>
	<ul><li><a name="InputFile_one_ClockPulse"></a><code>InputFile_one_ClockPulse</code> - Find the specified ClockPulse with 15% tolerance from the Input_File and filter the RAWMSG in the Export_File</li><a name=""></a></ul>
	<ul><li><a name="InputFile_one_SyncPulse"></a><code>InputFile_one_SyncPulse</code> - Find the specified SyncPulse with 15% tolerance from the Input_File and filter the RAWMSG in the Export_File</li><a name=""></a></ul>
	<ul><li><a name="TimingsList"></a><code>TimingsList</code> - created one file in csv format from the file &lt;signalduino_protocols.hash&gt; to use for import</li><a name=""></a></ul>
	<ul><li><a name="change_bitMsg_to_hexMsg"></a><code>change_bitMsg_to_hexMsg</code> - converts the binary input to HEX</li><a name=""></a></ul>
	<ul><li><a name="change_hexMsg_to_bitMsg"></a><code>change_hexMsg_to_bitMsg</code> - converts the hexadecimal input into binary</li><a name=""></a></ul>
	<ul><li><a name="invert_bitMsg"></a><code>invert_bitMsg</code> - invert your bitMsg</li><a name=""></a></ul>
	<ul><li><a name="invert_hexMsg"></a><code>invert_hexMsg</code> - invert your RAWMSG</li><a name=""></a></ul>
	<br><br>

	<b>Attributes</b>
	<ul>
		<li><a name="DispatchMax">DispatchMax</a><br>
			Maximum number of messages that can be dispatch. if the attribute not set, the value automatically 1.</li>
		<li><a name="DispatchModule">DispatchModule</a><br>
			A selection of modules that have been automatically detected. It looking for files in the pattern <code>SIGNALduino_TOOL_Dispatch_xxx.txt</code> in which the RAWMSGs with model designation and state are stored.
			The classification must be made according to the pattern <code>name (model) , state , RAWMSG;</code>. A designation is mandatory NECESSARY! NO set commands entered automatically.
			If a module is selected, the detected RAWMSG will be listed with the names in the set list.</li>
		<li><a name="Dummyname">Dummyname</a><br>
			Name of the dummy device which is to trigger the dispatch command.</li>
		<li><a name="Filename_export">Filename_export</a><br>
			File name of the file in which the new data is stored.</li>
		<li><a name="Filename_input">Filename_input</a><br>
			File name of the file containing the input entries.</li>
		<li><a name="MessageNumber">MessageNumber</a><br>
		Number of message how dispatched only. (force-option)</li>
		<li><a name="Path">Path</a><br>
			Path of the tool in which the file (s) are stored or read. (standard is <code>./</code> which corresponds to the directory FHEM)</li>
		<li><a name="RAWMSG_M1">RAWMSG_M1</a><br>
			Memory 1 for a raw message</li>
		<li><a name="RAWMSG_M2">RAWMSG_M2</a><br>
			Memory 2 for a raw message</li>
		<li><a name="RAWMSG_M3">RAWMSG_M3</a><br>
			Memory 3 for a raw message</li>
		<li><a name="Sendername">Sendername</a><br>
			Name of the initialized device, which is used for direct transmission.</li>
		<li><a name="Senderrepeats">Senderrepeats</a><br>
			Numbre of repeats to send.</li>
		<li><a name="StartString">StartString</a><br>
			The attribute is necessary for the <code> set START</code> option. It search the start of the dispatch command.<br>
			There are 3 options: <code>MC;</code> | <code>MS;</code> | <code>MU;</code></li>
		<li><a name="userattr">userattr</a><br>
			Is an automatic attribute that reflects detected Dispatch files. It is self-created and necessary for processing. Each modified value is automatically overwritten by the TOOL!</li>
	</ul>
	<br>
=end html


=begin html_DE

<a name="SIGNALduino_TOOL"></a>
<h3>SIGNALduino_TOOL</h3>
<ul>
	Das Modul ist zur Hilfestellung für Entwickler des SIGNALduino Projektes. Es beinhaltet verschiedene Funktionen zur Berechnung / Filterung / Dispatchen / Wandlung und vieles mehr.<br><br><br>

	<b>Define</b><br>
	<ul><code>define &lt;NAME&gt; SIGNALduino_TOOL</code><br><br>
	Beispiel: define sduino_TOOL SIGNALduino_TOOL
	</ul><br><br>

	<a name="SIGNALduino_TOOL_Set"></a>
	<b>Set</b>
	<ul><li><a name="Dispatch_DMSG"></a><code>Dispatch_DMSG</code> - eine fertige DMSG vom Modul welche dispatch werden soll (ohne SIGNALduino Verarbeitung!)</li><a name=""></a></ul>
	<ul><li><a name="Dispatch_RAWMSG"></a><code>Dispatch_RAWMSG</code> - eine Roh-Nachricht welche einzeln dispatch werden soll</li><a name=""></a></ul>
	<ul><li><a name="Dispatch_RAWMSG_last"></a><code>Dispatch_RAWMSG_last</code> - Dispatch die zu letzt dispatchte Roh-Nachricht</li><a name=""></a></ul>
	<ul><li><a name="modulname"></a><code>&lt;modulname&gt;</code> - Dispatch eine Nachricht des ausgewählten Moduls aus dem Attribut DispatchModule.</li><a name=""></a></ul>
	<ul><li><a name="START"></a><code>START</code> - startet die Schleife zum automatischen dispatchen</li><a name=""></a></ul>
	<ul><li><a name="Send_RAWMSG"></a><code>Send_RAWMSG</code> - sendet eine MU | MS | MC Nachricht direkt über den angegebenen Sender (Attribut Sendename ist notwendig!)</li><a name=""></a></ul>
	<br>

	<a name="SIGNALduino_TOOL_Get"></a>
	<b>Get</b>
	<ul><li><a name="All_ClockPulse"></a><code>All_ClockPulse</code> - berechnet den Durchschnitt des ClockPulse aus der Input_Datei.</li><a name=""></a></ul>
	<ul><li><a name="All_SyncPulse"></a><code>All_SyncPulse</code> - berechnet den Durchschnitt des SyncPulse aus der Input_Datei.</li><a name=""></a></ul>
	<ul><li><a name="FilterFile"></a><code>FilterFile</code> - erstellt eine Datei mit den gefilterten Werten.<br>
	&emsp;&rarr; eine Vorauswahl von Suchbegriffen via Checkbox ist m&ouml;glich<br>
	&emsp;&rarr; die Checkbox Auswahl <i>-ONLY_DATA-</i> filtert nur die Suchdaten einzel aus jeder Zeile anstatt die komplette Zeile mit den gesuchten Daten<br>
	&emsp;&rarr; eingegebene Texte im Textfeld welche mit <i>Komma ,</i> getrennt werden, werden ODER verkn&uuml;pft und ein Text mit Leerzeichen wird als ganzes Argument gesucht</li><a name=""></a></ul>
	<ul><li><a name="InputFile_doublePulse"></a><code>InputFile_doublePulse</code> - sucht nach doppelten Pulsen im Datenteil der einzelnen Nachrichten innerhalb der Input_Datei und filtert diese in die Export_Datei.</li><a name=""></a></ul>
	<ul><li><a name="InputFile_length_Datapart"></a><code>InputFile_length_Datapart</code> - ermittelt die min und max L&auml;nge vom Datenteil der eingelesenen RAWMSG´s.</li><a name=""></a></ul>
	<ul><li><a name="InputFile_one_ClockPulse"></a><code>InputFile_one_ClockPulse</code> - sucht den angegebenen ClockPulse mit 15% Tolleranz aus der Input_Datei und filtert die RAWMSG in die Export_Datei.</li><a name=""></a></ul>
	<ul><li><a name="InputFile_one_SyncPulse"></a><code>InputFile_one_SyncPulse</code> - sucht den angegebenen SyncPulse mit 15% Tolleranz aus der Input_Datei und filtert die RAWMSG in die Export_Datei.</li><a name=""></a></ul>
	<ul><li><a name="TimingsList"></a><code>TimingsList</code> - erstellt eine Liste der Protokolldatei &lt;signalduino_protocols.hash&gt; im CSV-Format welche zum Import genutzt werden kann</li><a name=""></a></ul>
	<ul><li><a name="change_bitMsg_to_hexMsg"></a><code>change_bitMsg_to_hexMsg</code> - wandelt die binäre Eingabe in HEX.</li><a name=""></a></ul>
	<ul><li><a name="change_hexMsg_to_bitMsg"></a><code>change_hexMsg_to_bitMsg</code> - wandelt die hexadezimale Eingabe in bin&auml;r.</li><a name=""></a></ul>
	<ul><li><a name="invert_bitMsg"></a><code>invert_bitMsg</code> - invertiert die eingegebene binäre Nachricht.</li><a name=""></a></ul>
	<ul><li><a name="invert_hexMsg"></a><code>invert_hexMsg</code> - invertiert die eingegebene hexadezimale Nachricht.</li><a name=""></a></ul>
	<br><br>

	<b>Attributes</b>
	<ul>
		<li><a name="DispatchMax">DispatchMax</a><br>
			Maximale Anzahl an Nachrichten welche dispatcht werden d&uuml;rfen. Ist das Attribut nicht gesetzt, so nimmt der Wert automatisch 1 an.</li>
		<li><a name="DispatchModule">DispatchModule</a><br>
			Eine Auswahl an Modulen, welche automatisch erkannt wurden. Gesucht wird jeweils nach Dateien im Muster <code>SIGNALduino_TOOL_Dispatch_xxx.txt</code> worin die RAWMSG´s mit Modelbezeichnung und Zustand gespeichert sind. 
			Die Einteilung muss jeweils nach dem Muster <code>Bezeichnung (Model) , Zustand , RAWMSG;</code> erfolgen. Eine Bezeichnung ist zwingend NOTWENDIG! Mit dem Wert <code> - </code>werden KEINE Set Befehle automatisch eingetragen. 
			Bei Auswahl eines Modules, werden die gefundenen RAWMSG mit Bezeichnungen in die Set Liste eingetragen.</li>
		<li><a name="Dummyname">Dummyname</a><br>
			Name des Dummy-Ger&auml;tes welcher den Dispatch-Befehl ausl&ouml;sen soll.</li>
		<li><a name="Filename_export">Filename_export</a><br>
			Dateiname der Datei, worin die neuen Daten gespeichert werden.</li>
		<li><a name="Filename_input">Filename_input</a><br>
			Dateiname der Datei, welche die Input-Eingaben enth&auml;lt.</li>
		<li><a name="MessageNumber">MessageNumber</a><br>
			Nummer der g&uuml;ltigen Nachricht welche EINZELN dispatcht werden soll. (force-Option)</li>
			<a name="MessageNumberEnd"></a>
		<li><a name="Path">Path</a><br>
			Pfadangabe des Tools worin die Datei(en) gespeichert werden oder gelesen werden. (Standard ist <code>./</code> was dem Verzeichnis FHEM entspricht)</li>
		<li><a name="RAWMSG_M1">RAWMSG_M1</a><br>
			Speicherplatz 1 für eine Roh-Nachricht</li>
		<li><a name="RAWMSG_M2">RAWMSG_M2</a><br>
			Speicherplatz 2 für eine Roh-Nachricht</li>
		<li><a name="RAWMSG_M3">RAWMSG_M3</a><br>
			Speicherplatz 3 für eine Roh-Nachricht</li>
		<li><a name="Sendername">Sendername</a><br>
			Name des initialisierten Device, welches zum direkten senden genutzt wird.</li>
		<li><a name="Senderrepeats">Senderrepeats</a><br>
			Anzahl der Sendewiederholungen.</li>
		<li><a name="StartString">StartString</a><br>
			Das Attribut ist notwendig für die <code> set START</code> Option. Es gibt das Suchkriterium an welches automatisch den Start f&uuml;r den Dispatch-Befehl bestimmt.<br>
			Es gibt 3 M&ouml;glichkeiten: <code>MC;</code> | <code>MS;</code> | <code>MU;</code></li>
		<li><a name="userattr">userattr</a><br>
			Ist ein automatisches Attribut welches die erkannten Dispatch Dateien wiedergibt. Es wird selbst erstellt und ist notwendig für die Verarbeitung. Jeder modifizierte Wert wird durch das TOOL automatisch im Durchlauf &uuml;berschrieben!</li>
	</ul>
	<br>
</ul>
=end html_DE

=cut