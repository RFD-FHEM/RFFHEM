################################################################################
#
# The file is part of the SIGNALduino project
# v3.5.x - https://github.com/RFD-FHEM/RFFHEM/tree/dev-r35-xFSK
#
# 2016-2019  S.Butzek, Ralf9
# 2019-2020  S.Butzek, HomeAutoUser, elektron-bbs
#
################################################################################
package lib::SD_Protocols;

use strict;
use warnings;
use Carp;
our $VERSION = '0.21';


############################# package lib::SD_Protocols
#=item new($)
# This functons, will initialize the given Filename containing a valid protocolHash
# First Parameter is for filename (full or relativ path) to be loaded
# Returns string with error value or undef
# =cut
#  $id

sub new {
	my $ret = LoadHash(@_);
	return $ret->{'error'} if (exists($ret->{'error'})); 
	
	## Do some initialisation needed here
	
	return;
}


############################# package lib::SD_Protocols
#=item LoadHash($)
# This functons, will load protocol hash from file into a hash.
# First Parameter is for filename (full or relativ path) to be loaded
# Returns a reference to error or the hash
# =cut
#  $id

sub LoadHash {
	if (! -e $_[0]) {
		return \%{ {"error" => "File $_[0] does not exsits"}};
	}
	delete($INC{$_[0]});
	if(  ! eval { require $_[0]; 1 }  ) {
		return \%{ {'error' => $@}};
	}
	setDefaults();
	return getProtocolList();
}


############################# package lib::SD_Protocols
#=item protocolexists()
# This functons, will return true if the given ID exists otherwise false
# =cut
#  $id
sub protocolExists {
	return exists($lib::SD_ProtocolData::protocols{$_[0]});
}


############################# package lib::SD_Protocols
#=item getProtocolList()
# This functons, will return a reference to the protocol hash
# =cut
#  $id, $propertyname,
sub getProtocolList {
	return \%lib::SD_ProtocolData::protocols;
}


############################# package lib::SD_Protocols
#=item getKeys()
# This functons, will return all keys from the protocol hash
# 
# returns "" if the var is not defined
# =cut
#  $id, $propertyname,

sub getKeys {
	return keys %lib::SD_ProtocolData::protocols;
}


############################# package lib::SD_Protocols
#=item checkProperty()
# This functons, will return a value from the Protocolist and check if the key exists and a value is defined optional you can specify a optional default value that will be returned
# 
# returns "" if the var is not defined
# =cut
#  $id, $propertyname,$default

sub checkProperty {
	return getProperty($_[0],$_[1]) if exists($lib::SD_ProtocolData::protocols{$_[0]}{$_[1]}) && defined($lib::SD_ProtocolData::protocols{$_[0]}{$_[1]});
	return $_[2]; # Will return undef if $default is not provided
}


############################# package lib::SD_Protocols
#=item getProperty()
# This functons, will return a value from the Protocolist without any checks
# 
# returns "" if the var is not defined
# =cut
#  $id, $propertyname

sub getProperty {
	return $lib::SD_ProtocolData::protocols{$_[0]}{$_[1]};
}


############################# package lib::SD_Protocols
#=item getProtocolVersion()
# This functons, will return a version value of the Protocolist
# 
# =cut

sub getProtocolVersion {
	return $lib::SD_ProtocolData::VERSION;
}


############################# package lib::SD_Protocols
#=item setDefaults()
# This functon will add common Defaults to the Protocollist
# 
# =cut

sub setDefaults {
	foreach my $id (getKeys())
	{
		my $format = getProperty($id,"format");
		
		if (defined ($format) && $format eq "manchester")
		{
			# Manchester defaults :
			$lib::SD_ProtocolData::protocols{$id}{method} = \&lib::SD_Protocols::MCRAW if (!defined(checkProperty($id,"method")));
		}
		elsif (getProperty($id,"sync"))
		{
			# Messages with sync defaults :
			
		}
		elsif (getProperty($id,"clockabs"))
		{
			# Messages without sync defaults :
			$lib::SD_ProtocolData::protocols{$id}{length_min} = 8 if (!defined(checkProperty($id,"length_min")));
		}
	}
	return;
}


############################# package lib::SD_Protocols
=item binStr2hexStr()
This functon will convert binary string into its hex representation as string

Input:  binary string
 
Output:
        hex string

=cut

sub  binStr2hexStr {
    my $num   = shift;
    my $WIDTH = 4;
    my $index = length($num) - $WIDTH;
    my $hex = '';
    do {
        my $width = $WIDTH;
        if ($index < 0) {
            $width += $index;
            $index = 0;
        }
        my $cut_string = substr($num, $index, $width);
        $hex = sprintf('%X', oct("0b$cut_string")) . $hex;
        $index -= $WIDTH;
    } while ($index > (-1 * $WIDTH));
    return $hex;
}


############################# package lib::SD_Protocols
=item MCRAW()
This functon is desired to be used as a default output helper for manchester signals.
It will check for length_max and return a hex string

Input:  $name,$bitData,$id,$mcbitnum

Output:
        hex string
		or array (-1,"Error message")
		
=cut

sub MCRAW {
	my ($name,$bitData,$id,$mcbitnum) = @_;

	return (-1," message is to long") if ($mcbitnum > checkProperty($id,"length_max",0) );
	return(1,binStr2hexStr($bitData)); 
}


######################### package lib::SD_Protocols #########################
###       all functions for RAWmsg processing or module preparation       ###
#############################################################################

# to simple transfer
# SIGNALduino_HE800
# SIGNALduino_HE_EU
# SIGNALduino_postDemo_EM

############################################################
# xFSK method functions
############################################################

=item ConvPCA301()

This sub checks crc and converts data to a format which the PCA301 module can handle
croaks if called with less than one parameters

Input:  $hexData

Output:
        scalar converted message on success 
		or array (1,"Error message")

=cut


sub ConvPCA301 {
	my $hexData = shift // croak 'Error: called without $hexdata as input';
	
	return (1,'ConvPCA301, Usage: Input #1, $hexData needs to be at least 24 chars long') 
		if (length($hexData) < 24); # check double, in def length_min set

	my $checksum = substr($hexData,20,4);
	my $ctx = Digest::CRC->new(width=>16, poly=>0x8005, init=>0x0000, refin=>0, refout=>0, xorout=>0x0000);
	my $calcCrc = sprintf("%04X", $ctx->add(pack 'H*', substr($hexData,0,20))->digest);

	return (1,qq[ConvPCA301, checksumCalc:$calcCrc != checksum:$checksum]) if ($calcCrc ne $checksum);

	my $channel = hex(substr($hexData,0,2));
	my $command = hex(substr($hexData,2,2));
	my $addr1 = hex(substr($hexData,4,2));
	my $addr2 = hex(substr($hexData,6,2));
	my $addr3 = hex(substr($hexData,8,2));
	my $plugstate = substr($hexData,11,1);
	my $power1 = hex(substr($hexData,12,2));
	my $power2 = hex(substr($hexData,14,2));
	my $consumption1 = hex(substr($hexData,16,2));
	my $consumption2 = hex(substr($hexData,18,2));

	return ("OK 24 $channel $command $addr1 $addr2 $addr3 $plugstate $power1 $power2 $consumption1 $consumption2 $checksum");
}

############################################################

=item ConvKoppFreeControl()

This sub checks crc and converts data to a format which the KoppFreeControl module can handle
croaks if called with less than one parameters

Input:  $hexData

Output:
        scalar converted message on success 
		or array (1,"Error message")

=cut

sub ConvKoppFreeControl {
	my $hexData = shift // croak 'Error: called without $hexdata as input';

	return (1,'ConvKoppFreeControl, Usage: Input #1, $hexData needs to be at least 4 chars long')
		if (length($hexData) < 4); # check double, in def length_min set

	my $anz = hex(substr($hexData,0,2)) + 1;
	my $blkck = 0xAA;

	for (my $i = 0; $i < $anz; $i++) {
		my $d = hex(substr($hexData,$i*2,2));
		$blkck ^= $d;
	}
	return (1,'ConvKoppFreeControl, hexData is to short')
		if (length($hexData) < $anz*2); # check double, in def length_min set

	my $checksum = hex(substr($hexData,$anz*2,2));

	return (1,qq[ConvKoppFreeControl, checksumCalc:$blkck != checksum:$checksum]) if ($blkck != $checksum);
	return ("kr" . substr($hexData,0,$anz*2));
}


############################################################

=item ConvLaCrosse()

This sub checks crc and converts data to a format which the LaCrosse module can handle
croaks if called with less than one parameter

Input:  $hexData

Output:
        scalar converted message on success 
		or array (1,"Error message")

Message Format:
	
	 .- [0] -. .- [1] -. .- [2] -. .- [3] -. .- [4] -.
	 |       | |       | |       | |       | |       |
	 SSSS.DDDD DDN_.TTTT TTTT.TTTT WHHH.HHHH CCCC.CCCC
	 |  | |     ||  |  | |  | |  | ||      | |       |
	 |  | |     ||  |  | |  | |  | ||      | `--------- CRC
	 |  | |     ||  |  | |  | |  | |`-------- Humidity
	 |  | |     ||  |  | |  | |  | |
	 |  | |     ||  |  | |  | |  | `---- weak battery
	 |  | |     ||  |  | |  | |  |
	 |  | |     ||  |  | |  | `----- Temperature T * 0.1
	 |  | |     ||  |  | |  |
	 |  | |     ||  |  | `---------- Temperature T * 1
	 |  | |     ||  |  |
	 |  | |     ||  `--------------- Temperature T * 10
	 |  | |     | `--- new battery
	 |  | `---------- ID
	 `---- START

=cut


sub ConvLaCrosse {
	my $hexData = shift // croak 'Error: called without $hexdata as input';

	return (1,'ConvLaCrosse, Usage: Input #1, $hexData needs to be at least 8 chars long') 
		if (length($hexData) < 8); # check number of length for this sub to not throw an error

	my $ctx = Digest::CRC->new(width=>8, poly=>0x31);
	my $calcCrc = $ctx->add(pack 'H*', substr($hexData,0,8))->digest;
	my $checksum = sprintf("%d", hex(substr($hexData,8,2)));
	return (1,qq[ConvLaCrosse, checksumCalc:$calcCrc != checksum:$checksum]) if ($calcCrc != $checksum);

	my $addr = ((hex(substr($hexData,0,2)) & 0x0F) << 2) | ((hex(substr($hexData,2,2)) & 0xC0) >> 6);
	my $temperature = ( ( ((hex(substr($hexData,2,2)) & 0x0F) * 100) + (((hex(substr($hexData,4,2)) & 0xF0) >> 4) * 10) + (hex(substr($hexData,4,2)) & 0x0F) ) / 10) - 40;
	return (1,qq[ConvLaCrosse, temp:$temperature (out of Range)]) if ($temperature >= 60 || $temperature <= -40);   # Shoud be checked in logical module

	my $humidity = hex(substr($hexData,6,2));
	my $batInserted = (hex(substr($hexData,2,2)) & 0x20) << 2;
	my $SensorType = 1;
	
	my $humObat = $humidity & 0x7F;

	if ($humObat == 125) {	# Channel 2
		$SensorType = 2;
	}
	elsif ($humObat > 99) { # Shoud be checked in logical module
		return (-1,qq[ConvLaCrosse: hum:$humObat (out of Range)])
	}

	# build string for 36_LaCrosse.pm
	$temperature = (($temperature* 10 + 1000) & 0xFFFF);
	my $t1= ($temperature >> 8) & 0xFF;
	my $t2= $temperature & 0xFF;
	my $sensTypeBat = $SensorType | $batInserted;
	return( qq[OK 9 $addr $sensTypeBat $t1 $t2 $humidity] )  ;
}

1;