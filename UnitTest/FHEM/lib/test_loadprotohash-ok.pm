package lib::SD_ProtocolData;
{
	use strict;
	use warnings;
	use diagnostics;
	
	our %protocols = (
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
		"9995"	=>
			{
				name			=> 'Unittest MS Protocol',
				comment			=> 'ony for running automated tests',
				id				=> '9995',
				one				=> [-2,1],
				zero			=> [-1,2],
				sync			=> [-10,1],
				clockabs		=> 400,
				format			=> 'twostate',	#
				preamble		=> '#',			# prepend to converted message
				length_min		=> '32',
				length_max		=> '36',
				test_data		=> 	{ 
										test_MS_2 => [
											{
												desc	=>	"ms signal without reconstruct at end of signal", 
												input	=>	"MS;P1=-403;P2=813;P3=-812;P4=396;P5=-4005;D=45412123434123412123434341234123434121234123412121212121234343434121234343;CP=4;SP=5;",
												output	=>	[1,1,9995,"#34EB281E6"],
											},
											{
												desc	=>	"ms signal without reconstruct at middle of signal", 
												input	=>	"MS;P1=-403;P2=813;P3=-812;P4=396;P5=-4005;P6=5000;D=454121234341234121234343412341234341212341234121212121212343434341212343436;CP=4;SP=5;",
												output	=>	[1,1,9995,"#34EB281E6"],
											},
											{
												desc	=>	"ms signal without reconstruct and 31 bits (to short)", 
												input	=>	"MS;P1=-403;P2=813;P3=-812;P4=396;P5=-4005;P6=5000;D=45412123434123412123434341234123434121234123412121212121234343434141;CP=4;SP=5;",
												output	=>	[0],
											},
											{
												desc	=>	"ms signal without reconstruct and 37 bits (to long)", 
												input	=>	"MS;P1=-403;P2=813;P3=-812;P4=396;P5=-4005;P6=5000;D=45412123434123412123434341234123434121234123412121212121234343434121234343434;CP=4;SP=5;",
												output	=>	[0],
											},

										],
									},
			},
		"9994"	=>
			{
				name			=> 'Unittest MS Protocol',
				comment			=> 'ony for running automated tests',
				id				=> '9994',
				one				=> [-2,1],
				zero			=> [-1,2],
				sync			=> [-10,1],
				clockabs		=> 400,
				format			=> 'twostate',	#
				preamble		=> '#',			# prepend to converted message
				length_min		=> '32',
				length_max		=> '36',
				reconstructBit	=> 1,
				test_data		=> 	{ 
										test_MS_2 => [
											{
												desc	=>	"ms signal with reconstruct at end of signal", 
												input	=>	"MS;P1=-403;P2=813;P3=-812;P4=396;P5=-4005;D=45412123434123412123434341234123434121234123412121212121234343434121234343;CP=4;SP=5;",
												output	=>	[1,1,9994,"#34EB281E7"],
										
											},
											{
												desc	=>	"ms signal with reconstruct at middle of signal", 
												input	=>	"MS;P1=-403;P2=813;P3=-812;P4=396;P5=-4005;P6=5000;D=454121234341234121234343412341234341212341234121212121212343434341212343436;CP=4;SP=5;",
												output	=>	[1,1,9994,"#34EB281E7"],
											},
											{
												desc	=>	"ms signal with reconstruct 32  bits (long enough)", 
												input	=>	"MS;P1=-403;P2=813;P3=-812;P4=396;P5=-4005;P6=5000;D=45412123434123412123434341234123434121234123412121212121234343434141;CP=4;SP=5;",
												output	=>	[1,1,9994,"#34EB281E"],
											},
											{
												desc	=>	"ms signal with reconstruct 31  bits (to short)", 
												input	=>	"MS;P1=-403;P2=813;P3=-812;P4=396;P5=-4005;P6=5000;D=454121234341234121234343412341234341212341234121212121212343434341;CP=4;SP=5;",
												output	=>	[0],
											},
											{
												desc	=>	"ms signal with reconstruct and 37 bits (to long)", 
												input	=>	"MS;P1=-403;P2=813;P3=-812;P4=396;P5=-4005;P6=5000;D=4541212343412341212343434123412343412123412341212121212123434343412123434343;CP=4;SP=5;",
												output	=>	[0],
											},

										]
									},
			},
		"9993"	=>			
			{
				name			=> 'Unittest MS Protocol with float',
				comment			=> 'ony for running automated tests',
				id				=> '9993',
				one				=> [3.5,-1],
				zero			=> [1,-3.8],
				float			=> [1,-1],			# fuer Gruppentaste (nur bei ITS-150,ITR-3500 und ITR-300), siehe Kommentar in sub SIGNALduino_bit2itv1
				sync			=> [1,-44],
				clockabs		=> -1,				# -1=auto
				format			=> 'twostate',
				preamble		=> '#',				# prepend to converted message
				length_min		=> '24',
				length_max		=> '24',			# Don't know maximal lenth of a valid message
				postDemodulation	=> \&main::SIGNALduino_bit2itv1,
				test_data		=> 	{ 
							test_MS_2 => [
								{
									desc	=>	"ms signal with float at end of signal", 
									input	=>	" MS;P1=309;P2=-1130;P3=1011;P4=-429;P5=-11466;D=15123412121234123412141214121412141212123412341214;CP=1;SP=5;R=38;",
									output	=>	[1,1,9993,"#455515"],
							
								},
							]
						},
			
			},
		"9992"	=>			
			{
				name			=> 'Unittest MU Protocol ',
				comment			=> 'ony for running automated tests',
				id				=> '9992',
				clockabs		=> 400,
				one				=> [2,-1.2],
				zero			=> [1,-3],
				start			=> [6,-15],
				format			=> 'twostate',
				preamble		=> '#',						# prepend to converted message
				length_min		=> '22',
				length_max		=> '28',
				test_data		=> 	{ 
							test_mu_1 => [
								{
									desc	=>	"mu signal starting at first char in rmsg", 
									input	=>	"MU;P0=-563;P1=479;P2=991;P3=-423;P4=361;P5=-1053;P6=3008;P7=-7110;D=6720151515201520201515201520201520201520201515151567201515152015202015152015202015202015202015151515672015151520152020151520152020152020152020151515156720151515201520201515201520201520201520201515151;CP=1;R=21;",
									output	=>	[4,4,9992,"#8B2DB0"],
								},
								{
									desc	=>	"mu signal starting not at first char in rmsg ", 
									input	=>	"MU;P0=-563;P1=479;P2=991;P3=-423;P4=361;P5=-1053;P6=3008;P7=-7110;D=2345454523452323454523452323452323452323454545456720151515201520201515201520201520201520201515151567201515152015202015152015202015202015202015151515672015151520152020151520152020152020152020151515156720151515201520201515201520201520201520201515151;CP=1;R=21;",
									output	=>	[4,4,9992,"#8B2DB0"],
								},
							]
						},
			
			},
		"9991"	=>			
			{
				name				=> 'Unittest MU Protocol',
				comment				=> 'ony for running automated tests',
				id					=> '9991',
				zero				=> [3,-2],
				one					=> [1,-2],
				clockabs			=> 480,					
				reconstructBit		=> '1',
				format				=> 'pwm',				
				preamble			=> '#',					# prepend to converted message
				length_min			=> '60',
				length_max			=> '120',
				test_data			=> 	{ 
							test_mu_1 => [
								{ 
									desc	=>	"mu reconstruct lastbit is 1 ", 
									input	=>	"MU;P0=-987;P1=144;P2=522;P3=1495;CP=2;R=244;D=0102020202020202020203020303030202020203030303030203020202020203020302030302030302030303030303030303030303030303020303030302020303030202030202020303030303020202030302020303020202;",
									output	=>	[1,1,9991,"#FFA3C17D4900010C6E0E67"],
								},
								{
									desc	=>	"mu reconstruct lastbit is 0 ", 
									input	=>	"MU;P0=-987;P1=144;P2=522;P3=1495;CP=2;R=244;D=0102020202020202020203020303030202020203030303030203020202020203020302030302030302030303030303030303030303030303020303030302020303030202030202020303030303020202030302020303020203;",
									output	=>	[1,1,9991,"#FFA3C17D4900010C6E0E66"],
								},
							
							]
						},
			
		},
		"9990"=>			
			{
				name				=> 'Unittest MC Protocol',
				comment				=> 'ony for running automated tests',
				id					=> '9990',
				clockrange			=> [300,360],						
				format				=> 'manchester',				
				length_min			=> '2',
				length_max			=> '8',
		},
		"9989"=>			
			{
				name				=> 'Unittest MC Protocol',
				comment				=> 'ony for running automated tests',
				id					=> '9989',
				clockrange			=> [300,360],						
				format				=> 'manchester',				
				length_min			=> '1',
				length_max			=> '24',
				method				=> \&lib::SD_Protocols::Not_Existing_Sub,	
				polarity			=> 'invert',
		},
		"9988"	=>	
			{
				name			=> 'Unittest MN Protocol',
				comment			=> 'ony for running automated tests',
				id              => '100',
				knownFreqs      => '868.3',
				datarate        => '17257.69',
				sync            => '2DD4',
				modulation      => '2-FSK',
				regexMatch      => qr/^35/,   
				clientmodule    => 'LaCrosse',
				method			=> \&lib::SD_Protocols::Not_Existing_Sub,	
			},
		"9987"	=>	
			{
				name			=> 'Unittest MN Protocol',
				comment			=> 'ony for running automated tests',
				id              => '100',
				knownFreqs      => '868.3',
				datarate        => '17257.69',
				sync            => '2DD4',
				modulation      => '2-FSK',
				regexMatch      => qr/^36/,   
				clientmodule    => 'LaCrosse',
			},
		
	);
	no warnings 'redefine';
	sub getProtocolList	{	
		return \%protocols;	
	}
 
 }