##############################################
# $Id: 14_SD_UT.pm 32 2016-04-02 14:00:00 v3.2-dev $
#
# The purpose of this module is to support serval
# unitec based devices
# 1.fhemtester  2016
#

package main;


use strict;
use warnings;

#use Data::Dumper;


sub SD_UT_Initialize($)
{
	my ($hash) = @_;

	$hash->{Match}	= '^u30#.*';
	$hash->{DefFn}	= "SD_UT_Define";
	$hash->{UndefFn}	= "SD_UT_Undef";
	$hash->{ParseFn}	= "SD_UT_Parse";
	$hash->{AttrFn}	= "SD_UT_Attr";
	$hash->{AttrList}	= "IODev do_not_notify:1,0 ignore:0,1 showtime:1,0 " .
				"$readingFnAttributes ";
	$hash->{AutoCreate} =
	{ "SD_UNITEC.*" => { ATTR => "event-min-interval:.*:300 event-on-change-reading:.*", FILTER => "%NAME", GPLOT => "temp4hum4:Temp/Hum,",  autocreateThreshold => "2:180"} };

}

#############################
sub SD_UT_Define($$)
{
	my ($hash, $def) = @_;
	my @a = split("[ \t][ \t]*", $def);

	return "wrong syntax: define <name> SD_UT <code> ".int(@a) if(int(@a) < 3 );

	$hash->{CODE} = $a[2];
	$hash->{lastMSG} =  "";
	$hash->{bitMSG} =  "";

	$modules{SD_UT}{defptr}{$a[2]} = $hash;
	$hash->{STATE} = "Defined";

	my $name= $hash->{NAME};
	return undef;
}

#####################################
sub SD_UT_Undef($$)
{
	my ($hash, $name) = @_;
	delete($modules{SD_UT}{defptr}{$hash->{CODE}})
		if(defined($hash->{CODE}) && defined($modules{SD_UT}{defptr}{$hash->{CODE}}));
	return undef;
}


###################################
sub SD_UT_Parse($$)
{
	my ($iohash, $msg) = @_;
	#my $rawData = substr($msg, 2);
	my $name = $iohash->{NAME};
	my ($protocol,$rawData) = split("#",$msg);
	$protocol=~ s/^u(\d+)/$1/; # extract protocol
	
	my $dummyreturnvalue= "Unknown, please report";
	my $hlen = length($rawData);
	my $blen = $hlen * 4;
	my $bitData = unpack("B$blen", pack("H$hlen", $rawData));
	my $bitData2;
	
	my $model;	
	my $SensorTyp;
	my $id;

	my $channel;

	
	Log3 $name, 3, "SD_UT_Parse: Protocol: $protocol, rawData: $rawData";
	
	$model = "UNITEC";
	$SensorTyp = "FAAC/HEIDEMANN";
	my $bin = substr($bitData,0,8);
	my $deviceCode = sprintf('%X', oct("0b$bin"));
       my $sound = substr($bitData,8,4);
       $channel = $deviceCode;

	Log3 $name, 3, "$name Heidemann/FAAC devicecode=$deviceCode, sound=$sound";
	
	if (!defined($model)) {
		return $dummyreturnvalue;
	}
	
	my $longids = AttrVal($iohash->{NAME},'longids',0);
	if (($longids ne "0") && ($longids eq "1" || $longids eq "ALL" || (",$longids," =~ m/,$model,/)))
	{
		$deviceCode = $model . '_' . $id . $channel;
		Log3 $iohash,4, "$name using longid: $longids model: $model";
	} else {
		$deviceCode = $model . "_" . $channel;
	}
	
	my $def = $modules{SD_UT}{defptr}{$iohash->{NAME} . "." . $deviceCode};
	$def = $modules{SD_UT}{defptr}{$deviceCode} if(!$def);

	if(!$def) {
		Log3 $iohash, 1, 'SD_UT: UNDEFINED sensor ' . $model . ' detected, code ' . $deviceCode;
		return "UNDEFINED $deviceCode SD_UT $deviceCode";
	}
	
	my $hash = $def;
	$name = $hash->{NAME};
	Log3 $name, 4, "SD_UT: $name ($rawData)";  

	if (!defined(AttrVal($hash->{NAME},"event-min-interval",undef)))
	{
		my $minsecs = AttrVal($iohash->{NAME},'minsecs',0);
		if($hash->{lastReceive} && (time() - $hash->{lastReceive} < $minsecs)) {
			Log3 $hash, 4, "$deviceCode Dropped due to short time. minsecs=$minsecs";
			return "";
		}
	}

	$hash->{lastReceive} = time();
	$hash->{lastMSG} = $rawData;
	if (defined($bitData2)) {
		$hash->{bitMSG} = $bitData2;
	} else {
		$hash->{bitMSG} = $bitData;
	}

	my $state = $sound; 

	readingsBeginUpdate($hash);
	readingsBulkUpdate($hash, "state", $state);
	readingsBulkUpdate($hash, "channel", $channel)  if (defined($sound));
       readingsBulkUpdate($hash, "sound", $sound)  if (defined($sound));
	
	readingsEndUpdate($hash, 1); # Notify is done by Dispatch
	
	return $name;

}

sub SD_UT_Attr(@)
{
	my @a = @_;
	
	# Make possible to use the same code for different logical devices when they
	# are received through different physical devices.
	return  if($a[0] ne "set" || $a[2] ne "IODev");
	my $hash = $defs{$a[1]};
	my $iohash = $defs{$a[3]};
	my $cde = $hash->{CODE};
	delete($modules{SD_UT}{defptr}{$cde});
	$modules{SD_UT}{defptr}{$iohash->{NAME} . "." . $cde} = $hash;
	return undef;
}


sub SD_UT_binaryToNumber
{
	my $binstr=shift;
	my $fbit=shift;
	my $lbit=$fbit;
	$lbit=shift if @_;
	
	return oct("0b".substr($binstr,$fbit,($lbit-$fbit)+1));
}

1;


