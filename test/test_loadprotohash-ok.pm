package SD_Protocols;
{ 
	my %signalduino_protocols = (
		"9999"	=> 
			{
				name			=> 'Unittest Protocol with developId=m',
				comment			=> 'ony for running automated tests',
				id				=> '9999',
				developId		=> 'm',
				modulematch		=> '^X[A-Fa-f0-9]+',
	        },
		"9998"	=>
			{
				name			=> 'Unittest Protocol  with developId=m',
				comment			=> 'ony  for running automated tests',
				id				=> '9998',
				developId		=> 'm',
	        },
		"9997"	=>
			{
				name			=> 'Unittest Protocol  with developId=y',
				comment			=> 'ony for running automated tests',
				id				=> '9997',
				developId		=> 'y',
	        },
		"9996"	=>
			{
				name			=> 'Unittest Protocol  with developId=p',
				comment			=> 'ony for running automated tests',
				id				=> '9996',
				developId		=> 'p',
	        },
	);
	sub getProtocolList	{			
		return \%signalduino_protocols;	
	}
}