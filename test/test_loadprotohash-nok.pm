package SD_Protocols;
{ 
	my %signalduino_protocols = (
    "9999"    => 
        {
            name			=> 'Unittest MS Protocol',		
			comment			=> 'ony for running automated tests'
			id				=> '9999',
        },
		
 
	);
	sub getProtocolList	{	return \%signalduino_protocols;	}
}