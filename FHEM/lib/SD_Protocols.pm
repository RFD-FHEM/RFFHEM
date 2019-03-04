################################################################################
# The file is part of the SIGNALduino project
#
 
package lib::SD_Protocols;

our $VERSION = '0.10';
use strict;
use warnings;


#=item new($)   #This functons, will initialize the given Filename containing a valid protocolHash
#=item LoadHash($) #This functons, will load protocol hash from file into a hash
#=item exists() # This functons, will return true if the given id exists otherwise false
#=item getKeys() # This functons, will return all keys from the protocol hash
#=item checkProperty() #This functons, will return a value from the Protocolist and check if the key exists and a value is defined optional you can specify a optional default value that will be returned
#=item getProperty() #This functons, will return a value from the Protocolist without any checks

# - - - - - - - - - - - -
#=item new($)
# This functons, will initialize the given Filename containing a valid protocolHash
# First Parameter is for filename (full or relativ path) to be loaded
# Returns string with error value or undef
# =cut
#  $id

sub new
{
	my $ret = LoadHash(@_);
	return $ret->{'error'} if (exists($ret->{'error'})); 
	
	## Do some initialisation needed here
	
	return undef;
}

# - - - - - - - - - - - -
#=item LoadHash($)
# This functons, will load protocol hash from file into a hash.
# First Parameter is for filename (full or relativ path) to be loaded
# Returns a reference to error or the hash
# =cut
#  $id


	
sub LoadHash
{	
	if (! -e $_[0]) {
		return \%{ {"error" => "File $_[0] does not exsits"}};
	}
	delete($INC{$_[0]});
	if(  ! eval { require "$_[0]"; 1 }  ) {
		return 	\%{ {"error" => $@}};
	}
	return getProtocolList();
}


# - - - - - - - - - - - -
#=item exists()
# This functons, will return true if the given ID exists otherwise false
# =cut
#  $id
sub exists($)
{
	return exists($lib::SD_ProtocolData::protocols{$_[0]});
}

# - - - - - - - - - - - -
#=item getProtocolList()
# This functons, will return a reference to the protocol hash
# =cut
#  $id, $propertyname,
sub getProtocolList()	{	
	return \%lib::SD_ProtocolData::protocols;	}

# - - - - - - - - - - - -
#=item getKeys()
# This functons, will return all keys from the protocol hash
# 
# returns "" if the var is not defined
# =cut
#  $id, $propertyname,

sub getKeys() {
	return keys %lib::SD_ProtocolData::protocols; }

# - - - - - - - - - - - -
#=item checkProperty()
# This functons, will return a value from the Protocolist and check if the key exists and a value is defined optional you can specify a optional default value that will be returned
# 
# returns "" if the var is not defined
# =cut
#  $id, $propertyname,$default

sub checkProperty($$;$)
{
	return getProperty($_[0],$_[1]) if exists($lib::SD_ProtocolData::protocols{$_[0]}{$_[1]}) && defined($lib::SD_ProtocolData::protocols{$_[0]}{$_[1]});
	return $_[2]; # Will return undef if $default is not provided
}

# - - - - - - - - - - - -
#=item getProperty()
# This functons, will return a value from the Protocolist without any checks
# 
# returns "" if the var is not defined
# =cut
#  $id, $propertyname

sub getProperty($$)
{
	return $lib::SD_ProtocolData::protocols{$_[0]}{$_[1]};
}


1;