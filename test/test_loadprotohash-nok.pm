package lib::SD_PrococolData;
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

