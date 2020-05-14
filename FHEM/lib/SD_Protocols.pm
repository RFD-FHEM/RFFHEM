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
use Carp qw(croak carp);
use Digest::CRC;
our $VERSION = '1.01';
use Storable qw(dclone);


use Data::Dumper;

############################# package lib::SD_Protocols
#=item new($)
# This functons, will initialize the given Filename containing a valid protocolHash
# First Parameter is for filename (full or relativ path) to be loaded
# Returns string with error value or undef
# =cut
#  $id

sub new {
	my $class = shift;
	croak "Illegal parameter list has odd number of values" if @_ % 2;
    my %args = @_; 
 	my $self = {};
	
	$self->{_protocolFilename} = $args{filename} //  q[];
	$self->{_protocols} = undef;
	$self->{_filetype} = $args{filetype} // 'PerlModule';
	$self->{_logCallback} = undef;
	bless $self, $class;

	if ($self->{_protocolFilename})
	{
		
		( $self->{_filetype} eq 'json' )  
			?   $self->LoadHashFromJson($self->{_protocolFilename}) 
			:   $self->LoadHash($self->{_protocolFilename}) ;
	}
	return $self;
}

############################# package lib::SD_Protocols
#=item STORABLE_freeze()
# This function is not currently explained.
# =cut

sub STORABLE_freeze {
        my $self = shift;
        return join(q[:], ($self->{_protocolFilename}, $self->{_filetype}));
}

############################# package lib::SD_Protocols
#=item STORABLE_thaw()
# This function is not currently explained.
# =cut
 
sub STORABLE_thaw {
	my ($self, $cloning, $frozen) = @_;
    ($self->{_protocolFilename}, $self->{_filetype}) = split(/:/xms, $frozen);
	$self->LoadHash();
	$self->LoadHashFromJson();
	return ;
}


############################# package lib::SD_Protocols
#=item LoadHashFromJson()
# This functons, will load protocol hash from json file into a hash.
# First Parameter is for filename (full or relativ path) to be loaded
# Returns error or undef on success
# =cut
#  $id

sub LoadHashFromJson {
	my $self = shift // carp 'Not called within an object';
	my $filename = shift // $self->{_protocolFilename};

	return if ($self->{_filetype} ne 'json');
	
	if (! -e $filename) {
		return qq[File $filename does not exsits];
	}
	
	 
	
	open(my $json_fh, '<:encoding(UTF-8)', $filename)
	      or croak("Can't open \$filename\": $!\n");
	my $json_text = do { local $/ = undef; <$json_fh> };
	close $json_fh or croak "Can't close '$filename' after reading";
	
	use JSON;
	my $json = JSON->new;
	$json = $json->relaxed(1);
	my $ver = $json->incr_parse($json_text);
	my $prot = $json->incr_parse();
	
	$self->{_protocols} = $prot // 'undef'; 
	$self->{_protocolsVersion} = $ver->{version} // 'undef'; 

	$self->setDefaults();
	$self->{_protocolFilename} = $filename;
	return ;
}

############################# package lib::SD_Protocols, test exists
#=item LoadHash()
# This functons, will load protocol hash from perlmodule file .
# First Parameter is for filename (full or relativ path) to be loaded
# Returns error or undef on success
# =cut
#  $id

sub LoadHash {
	my $self = shift // carp 'Not called within an object';
	my $filename = shift // $self->{_protocolFilename};

	return if ($self->{_filetype} ne "PerlModule");
	
	if (! -e $filename) {
		return qq[File $filename does not exists];
	}
	
	return $@ if(  ! eval { require $filename; 1 }  );
	$self->{_protocols} = \%lib::SD_ProtocolData::protocols;
	$self->{_protocolsVersion} = $lib::SD_ProtocolData::VERSION;
	
	delete($INC{$filename}); # Unload package, because we only wanted the hash

	$self->setDefaults();
	$self->{_protocolFilename} = $filename;
	return ;
}


############################# package lib::SD_Protocols, test exists
#=item protocolexists()
# This functons, will return true if the given ID exists otherwise false
# =cut
#  $id
sub protocolExists {
	my $self = shift // carp 'Not called within an object';
	my $pId= shift // carp "Illegal parameter number, protocol id was not specified";
	return exists($self->{_protocols}->{$pId});
}


############################# package lib::SD_Protocols, test exists
#=item getProtocolList()
# This functons, will return a reference to the protocol hash
# =cut
#  $id, $propertyname,
sub getProtocolList {
	my $self = shift // carp 'Not called within an object';
	return $self->{_protocols};
}


############################# package lib::SD_Protocols, test exists
#=item getKeys()
# This functons, will return all keys from the protocol hash
# 
# =cut

sub getKeys {
	my $self=shift // carp 'Not called within an object';
	my (@ret) = keys %{$self->{_protocols}};
	return @ret;
}


############################# package lib::SD_Protocols, test exists
#=item checkProperty()
# This functons, will return a value from the Protocolist and check if the key exists and a value is defined optional you can specify a optional default value that will be returned
# 
# returns undef if the var is not defined
# =cut
#  $id, $propertyname,$default

sub checkProperty {
	my $self=shift // carp 'Not called within an object';
	my $id = shift // return;
	my $valueName = shift // return;
 	my $default= shift // undef;
	
	return $self->{_protocols}->{$id}->{$valueName} if exists($self->{_protocols}->{$id}->{$valueName}) && defined($self->{_protocols}->{$id}->{$valueName});
	return $default; # Will return undef if $default is not provided
}


############################# package lib::SD_Protocols, test exists
#=item getProperty()
# This functons, will return a value from the Protocolist without any checks
# 
# returns undef if the var is not defined
# =cut
#  $id, $propertyname

sub getProperty {
	my $self = shift // carp 'Not called within an object';
	my $id = shift // return ;
	my $valueName = shift // return ;
	
	return $self->{_protocols}->{$id}->{$valueName} if ( exists $self->{_protocols}->{$id}->{$valueName} );
	return; 
}


############################# package lib::SD_Protocols, test exists
#=item getProtocolVersion()
# This functons, will return a version value of the Protocolist
# 
# =cut

sub getProtocolVersion {
	my $self = shift // carp 'Not called within an object';
	return $self->{_protocolsVersion};
}


############################# package lib::SD_Protocols, test exists
#=item setDefaults()
# This functon will add common Defaults to the Protocollist
# 
# =cut

sub setDefaults {
	my $self = shift // carp 'Not called within an object';
	
	for my $id ( $self->getKeys() )
	{
		my $format = $self->getProperty($id,'format');
			
		if ( defined $format && ($format eq 'manchester' || $format =~ 'FSK') )
		{
			# Manchester defaults :
			my $cref = $self->checkProperty($id,'method');
			( !defined $cref && $format eq 'manchester' ) 
				?    $self->{_protocols}->{$id}->{method} = \&lib::SD_Protocols::MCRAW 
				:     undef;

			if (defined $cref) {
				$cref =~ s/^\\&//xms;
				( ref $cref ne 'CODE' ) 
					? $self->{_protocols}->{$id}->{method} = eval {\&$cref}
					: undef;
			}
		}
		elsif (defined($self->getProperty($id,'sync')))
		{
			# Messages with sync defaults :			
		}
		elsif (defined($self->getProperty($id,'clockabs')))
		{
			# Messages without sync defaults :
			( !defined($self->checkProperty($id,'length_min')) ) ? 
				$self->{_protocols}->{$id}->{length_min} = 8
				: '' ;
		} else {
		
		}
	}
	return;
}


############################# package lib::SD_Protocols, test exists
=item binStr2hexStr()
This functon will convert binary string into its hex representation as string

Input:  binary string
 
Output:
        hex string

=cut

sub  binStr2hexStr {
    my $num   = shift // return;
	return if ($num !~ /^[01]*$/xms);
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


############################# package lib::SD_Protocols, test exists
=item MCRAW()
This functon is desired to be used as a default output helper for manchester signals.
It will check for length_max and return a hex string

Input:  $name,$bitData,$id,$mcbitnum

Output:
        hex string
		or array (-1,"Error message")
		
=cut

sub MCRAW {
	my ($self,$name,$bitData,$id,$mcbitnum) = @_;
	$self // carp 'Not called within an object' ;
	

	return (-1," message is to long") if ($mcbitnum > $self->checkProperty($id,"length_max",0) );
	return(1,binStr2hexStr($bitData)); 
}

############################# package lib::SD_Protocols, test exists

=item registerLogCallback()

=cut

sub registerLogCallback
{
	my $self = shift // carp 'Not called within an object';
	my $callback = shift // carp 'coderef must be provided';
	
	(ref $callback eq 'CODE') ? $self->{_logCallback} = $callback
		: carp 'coderef must be provided for callback';

	return ;
}

############################# package lib::SD_Protocols

=item _logging()
	$self->_logging('something happend','3')

=cut

sub _logging {
	my $self = shift // carp 'Not called within an object';
	my $message = shift // carp 'message must be provided';
	my $level = shift // 3;
	
	
	if (defined $self->{_logCallback})
	{
		$self->{_logCallback}->($message,$level);
	}
	return ;
}

######################### package lib::SD_Protocols #########################
###       all functions for RAWmsg processing or module preparation       ###
#############################################################################

############################################################
# ASK/OOK method functions
############################################################

=item dec2binppari()

This sub calculated. It converts a decimal number with a width of 8 bits into binary format,
calculates the parity, appends the parity bit and returns this 9 bit.

Input:  $num

Output:
        calculated number binary with parity

=cut

sub dec2binppari {      # dec to bin . parity
	my $num = shift // carp 'must be called with an number';
	my $parity = 0;
	my $nbin = sprintf("%08b",$num);
	for my $c (split //, $nbin) {
		$parity ^= $c;
	}
	return  qq[$nbin$parity];  # bin(num) . paritybit
}

############################################################

=item Convbit2Arctec()

This sub convert 0 -> 01, 1 -> 10 to be compatible with IT Module.

Input:  @bit_msg

Output:
        converted message

=cut

sub Convbit2Arctec {
	my ($self,undef,@bitmsg) = @_;
	$self // carp 'Not called within an object';
	@bitmsg // carp 'no bitmsg provided';
	my $convmsg = join("",@bitmsg);
	my @replace = qw(01 10); 

	# Convert 0 -> 01   1 -> 10 to be compatible with IT Module
	$convmsg =~ s/(0|1)/$replace[$1]/gx;
	return (1,split(//,$convmsg));
}

############################################################

=item Convbit2itv1()

This sub convert 0F -> 01 (F) to be compatible with CUL.

Input:  $msg

Output:
        converted message

=cut

sub Convbit2itv1 {
	my ($self,undef,@bitmsg) = @_;
	$self // carp 'Not called within an object';
	@bitmsg // carp 'no bitmsg provided';
	my $msg = join("",@bitmsg);
	
	$msg =~ s/0F/01/gsm;  # Convert 0F -> 01 (F) to be compatible with CUL
	return (1,split(//,$msg)) if (index($msg,'F') == -1);
	return (0,0);
}

############################################################

=item ConvHE800()

This sub checks the length of the bits.
If the length is less than 40, it adds a 0.

Input:  $name, @bit_msg

Output:
        scalar converted message on success 

=cut

sub ConvHE800 {
	my ($self,$name, @bit_msg) = @_;
	$self // carp 'Not called within an object';
	
	my $protolength = scalar @bit_msg;

	if ($protolength < 40) {
		for (my $i=0; $i<(40-$protolength); $i++) {
			push(@bit_msg, 0);
		}
	}
	return (1,@bit_msg);
}

############################################################

=item ConvHE_EU()

This sub checks the length of the bits.
If the length is less than 72, it adds a 0.

Input:  $name, @bit_msg

Output:
        scalar converted message on success 

=cut

sub ConvHE_EU {
	my ($self,$name, @bit_msg) = @_;
	my $protolength = scalar @bit_msg;

	if ($protolength < 72) {
		for (my $i=0; $i<(72-$protolength); $i++) {
			push(@bit_msg, 0);
		}
	}
	return (1,@bit_msg);
}

############################################################

=item ConvITV1_tristateToBit()

This sub Convert 0 -> 00, 1 -> 11, F => 01 to be compatible with IT Module.

Input:  $msg

Output:
        converted message

=cut

sub ConvITV1_tristateToBit {
	my ($msg) = @_;

	$msg =~ s/0/00/gsm;
	$msg =~ s/1/11/gsm;
	$msg =~ s/F/01/gsm;
	$msg =~ s/D/10/gsm;

	return (1,$msg);
}

############################################################

=item postDemo_EM()

This sub prepares the send message.

Input:  $id,$sum,$msg

Output:
        prepares message

=cut

sub postDemo_EM {
	my $self = shift // carp "Not called within an object";
	
	my ($name, @bit_msg) = @_;
	my $msg = join("",@bit_msg);
	my $msg_start = index($msg, "0000000001");      # find start
	my $count;
	$msg = substr($msg,$msg_start + 10);            # delete preamble + 1 bit
	my $new_msg = "";
	my $crcbyte;
	my $msgcrc = 0;

	if ($msg_start > 0 && length $msg == 89) {
		for ($count = 0; $count < length ($msg) ; $count +=9) {
			$crcbyte = substr($msg,$count,8);
			if ($count < (length($msg) - 10)) {
				$new_msg.= join "", reverse @bit_msg[$msg_start + 10 + $count.. $msg_start + 17 + $count];
				$msgcrc = $msgcrc ^ oct( "0b$crcbyte" );
			}
		}
		if ($msgcrc == oct( "0b$crcbyte" )) {
			return (1,split("",$new_msg));
		} else {
			#$hash->{logMethod}->($name, 3, "$name: EM, protocol - CRC ERROR");
			# new output with Callback
			return 0, undef;
		}
	}
	
	#$hash->{logMethod}->($name, 3, "$name: EM, protocol - Start not found or length msg (".length $msg.") not correct");
	# new output with Callback
	return 0, undef;
}

############################################################

=item PreparingSend_FS20_FHT()

This sub prepares the send message.

Input:  $id,$sum,$msg

Output:
        prepares message

=cut

sub PreparingSend_FS20_FHT {
	my $self = shift // carp 'Not called within an object';
	my $id   = shift // carp 'no idprovided';
	my $sum  = shift // carp 'no sum provided';
	my $msg  = shift // carp 'no msg provided';
	
	return if ( $id > 74 || $id < 73); 
	
	my $temp = 0;
	my $newmsg = q[P].$id.q[#0000000000001];    # 12 Bit Praeambel, 1 bit

	for (my $i=0; $i<length($msg); $i+=2) {
		$temp = hex(substr($msg, $i, 2));
		$sum += $temp;
		$newmsg .= dec2binppari($temp);
	}

	$newmsg .= dec2binppari($sum & 0xFF);       # Checksum
	my $repeats = $id - 71;                     # FS20(74)=3, FHT(73)=2
	return $newmsg.q[0P#R].$repeats;            # EOT, Pause, 3 Repeats
}


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
	my $self = shift // carp 'Not called within an object';
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
	my $self = shift // carp 'Not called within an object';
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
	my $self = shift // carp 'Not called within an object';
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

	if ($humObat == 125) {  # Channel 2
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