package FHEM::Devices::SIGNALduino::SD_Protocols::Data;
{ 
	our %protocols = (
    "9999"    => 
        {
            name			=> 'Unittest MS Protocol',		
			comment			=> 'ony for running automated tests'
			id				=> '9999',
        },
		
 
	);
	sub getProtocolList	{	return \%protocols;	}
};

