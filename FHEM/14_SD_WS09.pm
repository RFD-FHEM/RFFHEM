    ##############################################
    ##############################################
    # $Id: 14_SD_WS09.pm 16114 2017-09-09 22:00:00Z pejonp $
    # 
    # The purpose of this module is to support serval 
    # weather sensors like WS-0101  (Sender 868MHz ASK   Epmfänger RX868SH-DV elv)
    # Sidey79 & pejonp 2015  
    #
    package main;
    
    use strict;
    use warnings;
    #use Digest::CRC qw(crc);
    #use Math::Round qw/nearest/;
    
    sub SD_WS09_Initialize($)
    {
      my ($hash) = @_;
    
      $hash->{Match}     = "^P9#F[A-Fa-f0-9]+";    ## pos 7 ist aktuell immer 0xF
      $hash->{DefFn}     = "SD_WS09_Define";
      $hash->{UndefFn}   = "SD_WS09_Undef";
      $hash->{ParseFn}   = "SD_WS09_Parse";
      $hash->{AttrFn}	   = "SD_WS09_Attr";
      $hash->{AttrList}  = "IODev do_not_notify:1,0 ignore:0,1 showtime:1,0 "
                           ."model:CTW600,WH1080 ignore:0,1 "
                            ."windKorrektur:-3,-2,-1,0,1,2,3 "
                            ."Unit_of_Wind:m/s,km/h,ft/s,mph,bft,knot "
                            ."$readingFnAttributes ";
      $hash->{AutoCreate} =
            { "SD_WS09.*" => { ATTR => "event-min-interval:.*:300 event-on-change-reading:.* windKorrektur:.*:0 " , FILTER => "%NAME", GPLOT => "temp4hum4:Temp/Hum,",  autocreateThreshold => "2:180"} };
    
    
    }
    
    #############################
    sub SD_WS09_Define($$)
    {
      my ($hash, $def) = @_;
      my @a = split("[ \t][ \t]*", $def);
    
      return "wrong syntax: define <name> SD_WS09 <code> ".int(@a)
            if(int(@a) < 3 );
    
      $hash->{CODE} = $a[2];
      $hash->{lastMSG} =  "";
      $hash->{bitMSG} =  "";
    
      $modules{SD_WS09}{defptr}{$a[2]} = $hash;
      $hash->{STATE} = "Defined";
      
      my $model = $a[2];
      $model =~ s/_.*$//;
      $hash->{MODEL} = $model;
      
      my $name= $hash->{NAME};
      return undef;
    }
    
    #####################################
    sub SD_WS09_Undef($$)
    {
      my ($hash, $name) = @_;
      delete($modules{SD_WS09}{defptr}{$hash->{CODE}})
         if(defined($hash->{CODE}) &&
            defined($modules{SD_WS09}{defptr}{$hash->{CODE}}));
      return undef;
    }
    
    
    ###################################
    sub SD_WS09_Parse($$)
    {
      my ($iohash, $msg) = @_;
      my $name = $iohash->{NAME};
      my (undef ,$rawData) = split("#",$msg);
      my @winddir_name=("N","NNE","NE","ENE","E","ESE","SE","SSE","S","SSW","SW","WSW","W","WNW","NW","NNW");
      #my %Unit_of_Wind = ("m/s","km/h","ft/s","mph","bft","knot");
      my %uowind_unit= ("m/s",'1',"km/h",'3.6',"ft/s",'3.28',"bft",'-1',"mph",'2.24',"knot",'1.94');
      my %uowind_index = ("m/s",'0',"km/h",'1',"ft/s",'2',"mph",'3',"knot",'4',"bft",'5');
      my $hlen = length($rawData);
      my $blen = $hlen * 4;
      my $bitData = unpack("B$blen", pack("H$hlen", $rawData)); 
      my $bitData2;
      my $bitData20;
      my $rain = 0;
      my $deviceCode = 0;
      my $model = "undef";  # 0xFFA -> WS0101/WH1080 alles andere -> CTW600 
      my $modelid;
      my $windSpeed;
      my $windSpeed_kmh;
      my $windSpeed_fts;
      my $windSpeed_bft;
      my $windSpeed_mph;
      my $windSpeed_kn;
      my $windguest;
      my $windguest_kmh;
      my $windguest_fts;
      my $windguest_bft;
      my $windguest_mph;
      my$ windguest_kn;
      my $sensdata;
      my $id;
      my $bat = 0;
      my $temp = 0;
      my $hum = 1;
      my $windDirection = 1 ;
      my $windDirectionText = "N";
      my $FOuvo ;   # UV data nybble ?
      my $FOlux ; # Lux High byte (full scale = 4,000,000?) # Lux Middle byte  # Lux Low byte, Unit = 0.1 Lux (binary)
      my $rr2 ;
      my $state;
      my $msg_vor = 'P9#';
      my $minL1 = 70;
      my $minL2 = 60;
      my $whid;
      my $wh;
      my $rawData_merk;
      my $wfaktor = 1;
      my @windstat;
      
      
      
      
      my $syncpos= index($bitData,"11111110");  #7x1 1x0 preamble
    	Log3 $iohash, 4, "$name: SD_WS09_Parse0 msg=$rawData Bin=$bitData syncp=$syncpos length:".length($bitData) ;

    	if ($syncpos ==-1 || length($bitData)-$syncpos < $minL2)
    	{
    			Log3 $iohash, 4, "$name: SD_WS09_Parse EXIT: msg=$rawData syncp=$syncpos length:".length($bitData) ;
    			return undef;
    	}
      
      my $crcwh1080 = AttrVal($iohash->{NAME},'WS09_CRCAUS',0);
      Log3 $iohash, 4, "$name: SD_WS09_Parse CRC_AUS:$crcwh1080 " ;
    
      $rawData_merk = $rawData;
      #CRC-Check WH1080/WS0101 WS09_CRCAUS=2
      
       my $rc = eval
     {
      require Digest::CRC;
      Digest::CRC->import();
      1;
     };

    if($rc) # test ob  Digest::CRC geladen wurde
    {
      $rr2 = SD_WS09_CRCCHECK($rawData);
      if ($rr2 == 0 || (($rr2 == 49) && ($crcwh1080 == 2)) ) {
      # 1. OK
          $model = "WH1080";
          Log3 $iohash, 4, "$name: SD_WS09_SHIFT_0 OK rwa:$rawData" ;
      } else {
      # 1. nok
          $rawData = SD_WS09_SHIFT($rawData);
          Log3 $iohash, 4, "$name: SD_WS09_SHIFT_1 NOK  rwa:$rawData" ;
          $rr2 = SD_WS09_CRCCHECK($rawData);
          if ($rr2 == 0 || (($rr2 == 49) && ($crcwh1080 == 2)) ) {
          # 2.ok
              $msg = $msg_vor.$rawData;
              $model = "WH1080";
              Log3 $iohash, 4, "$name: SD_WS09_SHIFT_2 OK rwa:$rawData msg:$msg" ;
          } else {
              # 2. nok
              $rawData = SD_WS09_SHIFT($rawData);
              Log3 $iohash, 4, "$name: SD_WS09_SHIFT_3 NOK rwa:$rawData" ;
              $rr2 = SD_WS09_CRCCHECK($rawData);
              if ($rr2 == 0 || (($rr2 == 49) && ($crcwh1080 == 2)) ) {
                # 3. ok
                $msg = $msg_vor.$rawData;
                $model = "WH1080";
                Log3 $iohash, 4, "$name: SD_WS09_SHIFT_4 OK rwa:$rawData msg:$msg" ;
              }else{
               # 3. nok
                $rawData = $rawData_merk;
                $msg = $msg_vor.$rawData;
                Log3 $iohash, 4, "$name: SD_WS09_SHIFT_5 NOK rwa:$rawData msg:$msg" ;
             }
         }
      }
     }else {
      Log3 $iohash, 1, "$name: SD_WS09 CRC_not_load: Modul Digest::CRC fehlt: cpan install Digest::CRC or sudo apt-get install libdigest-crc-perl" ;
      return "";
   }  
    
     $hlen = length($rawData);
     $blen = $hlen * 4;
     $bitData = unpack("B$blen", pack("H$hlen", $rawData)); 
     Log3 $iohash, 4, "$name: SD_WS09_CRC_test2 rwa:$rawData msg:$msg CRC:".SD_WS09_CRCCHECK($rawData) ;
                  
         if( $model eq "WH1080") {
            $sensdata = substr($bitData,8);
            $whid = substr($sensdata,0,4);
            
            if(  $whid == "1010" ){ # A  Wettermeldungen
               	  Log3 $iohash, 4, "$name: SD_WS09_Parse msg=$sensdata length:".length($sensdata) ;
                  $model = "WH1080";
                  $id = SD_WS09_bin2dec(substr($sensdata,4,8));
                  $bat = (SD_WS09_bin2dec((substr($sensdata,64,4))) == 0) ? 'ok':'low' ; # decode battery = 0 --> ok
                  $temp = (SD_WS09_bin2dec(substr($sensdata,12,12)) - 400)/10;
        		      $hum = SD_WS09_bin2dec(substr($sensdata,24,8));
                  $windDirection = SD_WS09_bin2dec(substr($sensdata,68,4));  
                  $windDirectionText = $winddir_name[$windDirection];
                  $windSpeed =  round((SD_WS09_bin2dec(substr($sensdata,32,8))* 34)/100,01);
                  Log3 $iohash, 4, "$name: SD_WS09_Parse ".$model." id:$id, Windspeed bit: ".substr($sensdata,32,8)." Dec: " . $windSpeed ;
                  $windguest = round((SD_WS09_bin2dec(substr($sensdata,40,8)) * 34)/100,01);
                  Log3 $iohash, 4, "$name: SD_WS09_Parse ".$model." id:$id, Windguest bit: ".substr($sensdata,40,8)." Dec: " . $windguest ;
                  $rain =  SD_WS09_bin2dec(substr($sensdata,52,12)) * 0.3;
                  Log3 $iohash, 4, "$name: SD_WS09_Parse ".$model." id:$id, Rain bit: ".substr($sensdata,52,12)." Dec: " . $rain ;
                  Log3 $iohash, 4, "$name: SD_WS09_Parse ".$model." id:$id, bat:$bat, temp=$temp, hum=$hum, winddir=$windDirection:$windDirectionText wS=$windSpeed, wG=$windguest, rain=$rain";
            } elsif(  $whid == "1011" ){ # B  DCF-77 Zeitmeldungen vom Sensor
                  my $hrs1 = substr($sensdata,16,8);
                  my $hrs;
                  my $mins; 
                  my $sec; 
                  my $mday;
                  my $month;
                  my $year;
                  $id = SD_WS09_bin2dec(substr($sensdata,4,8));
                  Log3 $iohash, 4, "$name: SD_WS09_Parse Zeitmeldung0: HRS1=$hrs1 id:$id" ;
                  $hrs = sprintf "%02d" , SD_WS09_BCD2bin(substr($sensdata,18,6) ) ; # Stunde
                  $mins = sprintf "%02d" , SD_WS09_BCD2bin(substr($sensdata,24,8)); # Minute
                  $sec = sprintf "%02d" ,SD_WS09_BCD2bin(substr($sensdata,32,8)); # Sekunde
                  #day month year
                  $year = SD_WS09_BCD2bin(substr($sensdata,40,8)); # Jahr
                  $month = sprintf "%02d" ,SD_WS09_BCD2bin(substr($sensdata,51,5)); # Monat
                  $mday = sprintf "%02d" ,SD_WS09_BCD2bin(substr($sensdata,56,8)); # Tag
                  Log3 $iohash, 4, "$name: SD_WS09_Parse Zeitmeldung1: id:$id, msg=$rawData length:".length($bitData) ;
                  Log3 $iohash, 4, "$name: SD_WS09_Parse Zeitmeldung2: id:$id, HH:mm:ss - ".$hrs.":".$mins.":".$sec ;
                  Log3 $iohash, 4, "$name: SD_WS09_Parse Zeitmeldung3: id:$id, dd.mm.yy - ".$mday.".".$month.".".$year ;
                  return $name;
            } elsif(  $whid == "0111" ){   # 7  UV/Solar Meldungen vom Sensor
                  # Fine Offset (Solar Data) message BYTE offsets (within receive buffer)
                  # Examples= FF 75 B0 55 00 97 8E 0E *CRC*OK*
                  # =FF 75 B0 55 00 8F BE 92 *CRC*OK*
                  # symbol FOrunio = 0 ; Fine Offset Runin byte = FF
                  # symbol FOsaddo = 1 ; Solar Pod address word
                  # symbol FOuvo = 3 ; UV data nybble ?
                  # symbol FOluxHo = 4 ; Lux High byte (full scale = 4,000,000?)
                  # symbol FOluxMo = 5 ; Lux Middle byte
                  # symbol FOluxLo = 6 ; Lux Low byte, Unit = 0.1 Lux (binary)
                  # symbol FOcksumo= 7 ; CRC checksum (CRC-8 shifting left)
                  $id = SD_WS09_bin2dec(substr($sensdata,4,8));
                  $FOuvo = SD_WS09_bin2dec(substr($sensdata,12,4));
                  $FOlux = SD_WS09_bin2dec(substr($sensdata,24,24))/10;
                  Log3 $iohash, 4, "$name: SD_WS09_Parse7 UV-Solar1: id:$id, UV:".$FOuvo." Lux:".$FOlux ;
            } else {
                Log3 $iohash, 4, "$name: SD_WS09_Parse4 Exit: msg=$rawData length:".length($sensdata) ;
                Log3 $iohash, 4, "$name: SD_WS09_WH10 Exit:  Model=$model " ;
    	          return undef;
            }
         }else{
            # es wird eine CTW600 angenommen 
            $syncpos= index($bitData,"11111110");  #7x1 1x0 preamble
            $wh = substr($bitData,0,8);
            if ( $wh == "11111110" && length($bitData) > $minL1 )
            {
    	            Log3 $iohash, 4, "$name: SD_WS09_Parse CTW600 EXIT: msg=$bitData wh:$wh length:".length($bitData) ; 
                  $sensdata = substr($bitData,$syncpos+8);
                  Log3 $iohash, 4, "$name: SD_WS09_Parse CTW WH=$wh msg=$sensdata syncp=$syncpos length:".length($sensdata) ;
                  $model = "CTW600";
                  $whid = "0000";
                  my $nn1 = substr($sensdata,10,2);  # Keine Bedeutung
                  my $nn2 = substr($sensdata,62,4);  # Keine Bedeutung
                  $modelid = substr($sensdata,0,4);
                  Log3 $iohash, 4, "$name: SD_WS09_Parse Id: ".$modelid." NN1:$nn1 NN2:$nn2" ;
                  Log3 $iohash, 4, "$name: SD_WS09_Parse Id: ".$modelid." Bin-Sync=$sensdata syncp=$syncpos length:".length($sensdata) ;
                  $bat = SD_WS09_bin2dec((substr($sensdata,0,3))) ;
                  $id = SD_WS09_bin2dec(substr($sensdata,4,6));
                  $temp = (SD_WS09_bin2dec(substr($sensdata,12,10)) - 400)/10;
    	            $hum = SD_WS09_bin2dec(substr($sensdata,22,8));
                  $windDirection = SD_WS09_bin2dec(substr($sensdata,66,4));  
                  $windDirectionText = $winddir_name[$windDirection];
                  $windSpeed =  round(SD_WS09_bin2dec(substr($sensdata,30,16))/240,01);
                  Log3 $iohash, 4, "$name: SD_WS09_Parse ".$model." Windspeed bit: ".substr($sensdata,32,8)." Dec: " . $windSpeed ;
                  $windguest = round((SD_WS09_bin2dec(substr($sensdata,40,8)) * 34)/100,01);
                  Log3 $iohash, 4, "$name: SD_WS09_Parse ".$model." Windguest bit: ".substr($sensdata,40,8)." Dec: " . $windguest ;
                  $rain =  round(SD_WS09_bin2dec(substr($sensdata,46,16)) * 0.3,01);
                  Log3 $iohash, 4, "$name: SD_WS09_Parse ".$model." Rain bit: ".substr($sensdata,46,16)." Dec: " . $rain ;           
            }else{
                	Log3 $iohash, 4, "$name: SD_WS09_Parse CTW600 EXIT: msg=$bitData length:".length($bitData) ;
                  return undef;
            }
          }
        
       		
      Log3 $iohash, 4, "$name: SD_WS09_Parse ".$model." id:$id :$sensdata ";
      
    
      if($hum > 100 || $hum < 0) {
            	Log3 $iohash, 4, "$name: SD_WS09_Parse HUM: hum=$hum msg=$rawData " ;
    			   return undef;
         } 
      if($temp > 60 || $temp < -40) {
            	Log3 $iohash, 4, "$name: SD_WS09_Parse TEMP: Temp=$temp msg=$rawData " ;
    			   return undef;
         } 
      
          
       my $longids = AttrVal($iohash->{NAME},'longids',0);
    	if ( ($longids ne "0") && ($longids eq "1" || $longids eq "ALL" || (",$longids," =~ m/,$model,/)))
    	{
    	 $deviceCode=$model."_".$id;
     		Log3 $iohash,4, "$name: SD_WS09_Parse using longid: $longids model: $model";
    	} else {
    		$deviceCode = $model;
    	}
       
        my $def = $modules{SD_WS09}{defptr}{$iohash->{NAME} . "." . $deviceCode};
        $def = $modules{SD_WS09}{defptr}{$deviceCode} if(!$def);
    
        if(!$def) {
    		Log3 $iohash, 1, 'SD_WS09_Parse UNDEFINED sensor ' . $model . ' detected, code ' . $deviceCode;
    		return "UNDEFINED $deviceCode SD_WS09 $deviceCode";
        }
        
    my $hash = $def;
    	$name = $hash->{NAME};	    	
    	Log3 $name, 4, "SD_WS09_Parse: $name ($rawData)";  
    
    	if (!defined(AttrVal($hash->{NAME},"event-min-interval",undef)))
    	{
    		my $minsecs = AttrVal($iohash->{NAME},'minsecs',0);
    		if($hash->{lastReceive} && (time() - $hash->{lastReceive} < $minsecs)) {
    			Log3 $hash, 4, "SD_WS09_Parse $deviceCode Dropped due to short time. minsecs=$minsecs";
    		  	return undef;
    		}
    	}
    
    
    
       my $windkorr = AttrVal($hash->{NAME},'windKorrektur',0);
        if ($windkorr != 0 )      
        {
        my $oldwinddir = $windDirection; 
        $windDirection = $windDirection + $windkorr; 
        $windDirectionText = $winddir_name[$windDirection];
        Log3 $iohash, 4, "SD_WS09_Parse ".$model." Faktor:$windkorr wD:$oldwinddir  Korrektur wD:$windDirection:$windDirectionText" ;
        } 
      
       # "Unit_of_Wind:m/s,km/h,ft/s,bft,knot "
       # my %uowind_unit= ("m/s",'1',"km/h",'3.6',"ft/s",'3.28',"bft",'-1',"mph",'2.24',"knot",'1.94');
       # B  =  Wurzel aus ( 9  +  6 * V )  -  3
       # V = 17 Meter pro Sekunde ergibt:  B =  Wurzel aus( 9 + 6 * 17 )  -  3 
       # Das ergibt : 7,53   Beaufort
       
        $windstat[0]= " Ws:$windSpeed  Wg:$windguest m/s";
        #Log3 $iohash, 4, "SD_WS09_Wind m/s  : Ws:$windSpeed  Wg:$windguest : Faktor:$wfaktor" ;
        Log3 $iohash, 4, "SD_WS09_Wind $windstat[0] : Faktor:$wfaktor" ;
       
        $wfaktor = $uowind_unit{"km/h"};
        $windguest_kmh = round ($windguest * $wfaktor,01);
        $windSpeed_kmh = round ($windSpeed * $wfaktor,01);
        $windstat[1]= " Ws:$windSpeed_kmh  Wg:$windguest_kmh km/h";
        Log3 $iohash, 4, "SD_WS09_Wind $windstat[1] : Faktor:$wfaktor" ;
        
        $wfaktor = $uowind_unit{"ft/s"};
        $windguest_fts = round ($windguest * $wfaktor,01);
        $windSpeed_fts = round ($windSpeed * $wfaktor,01);
        $windstat[2]= " Ws:$windSpeed_fts  Wg:$windguest_fts ft/s";
        #Log3 $iohash, 4, "SD_WS09_Wind ft/s : Ws:$windSpeed_fts  Wg:$windguest_fts : Faktor:$wfaktor" ;
        Log3 $iohash, 4, "SD_WS09_Wind $windstat[2] : Faktor:$wfaktor" ;
        
        $wfaktor = $uowind_unit{"mph"};
        $windguest_mph = round ($windguest * $wfaktor,01);
        $windSpeed_mph = round ($windSpeed * $wfaktor,01);
        $windstat[3]= " Ws:$windSpeed_mph  Wg:$windguest_mph mph";
        #Log3 $iohash, 4, "SD_WS09_Wind mph : Ws:$windSpeed_mph  Wg:$windguest_mph : Faktor:$wfaktor" ;
        Log3 $iohash, 4, "SD_WS09_Wind $windstat[3] : Faktor:$wfaktor" ;
        
        $wfaktor = $uowind_unit{"knot"};
        $windguest_kn = round ($windguest * $wfaktor,01);
        $windSpeed_kn = round ($windSpeed * $wfaktor,01);
        $windstat[4]= " Ws:$windSpeed_kn  Wg:$windguest_kn kn" ;
        #Log3 $iohash, 4, "SD_WS09_Wind kn  : Ws:$windSpeed_kn   Wg:$windguest_kn : Faktor:$wfaktor" ;
        Log3 $iohash, 4, "SD_WS09_Wind $windstat[4] : Faktor:$wfaktor" ;
        
        $windguest_bft = round(sqrt( 9 + (6 * $windguest)) - 3,0) ;
        $windSpeed_bft = round(sqrt( 9 + (6 * $windSpeed)) - 3,0) ;
        $windstat[5]= " Ws:$windSpeed_bft  Wg:$windguest_bft bft";
        #Log3 $iohash, 4, "SD_WS09_Wind bft : Ws:$windSpeed_bft  Wg:$windguest_bft " ;
        Log3 $iohash, 4, "SD_WS09_Wind $windstat[5] " ;
         
           
      
      $hash->{lastReceive} = time();
    	$def->{lastMSG} = $rawData;
      readingsBeginUpdate($hash);
      
        if($whid ne "0111") 
         {
          my $uowind = AttrVal($hash->{NAME},'Unit_of_Wind',0) ; 
          my $windex = $uowind_index{$uowind} ;
          
          #$state = "T: $temp ". ($hum>0 ? " H: $hum ":" ")." Ws: $windSpeed "." Wg: $windguest "." Wd: $windDirectionText "." R: $rain";
          $state = "T: $temp ". ($hum>0 ? " H: $hum ":" "). $windstat[$windex]." Wd: $windDirectionText "." R: $rain";
          readingsBulkUpdate($hash, "id", $id) if ($id ne "");
          readingsBulkUpdate($hash, "state", $state);
          readingsBulkUpdate($hash, "temperature", $temp)  if ($temp ne"");
          readingsBulkUpdate($hash, "humidity", $hum)  if ($hum ne "" && $hum != 0 );
          readingsBulkUpdate($hash, "battery", $bat)   if ($bat ne "");
          #zusätzlich Daten für Wetterstation
          readingsBulkUpdate($hash, "rain", $rain );
          readingsBulkUpdate($hash, "windGust", $windguest );
          readingsBulkUpdate($hash, "windSpeed", $windSpeed );
          readingsBulkUpdate($hash, "windGust_kmh", $windguest_kmh );
          readingsBulkUpdate($hash, "windSpeed_kmh", $windSpeed_kmh );
          readingsBulkUpdate($hash, "windGust_fts", $windguest_fts );
          readingsBulkUpdate($hash, "windSpeed_fts", $windSpeed_fts );
          readingsBulkUpdate($hash, "windGust_mph", $windguest_mph );
          readingsBulkUpdate($hash, "windSpeed_mph", $windSpeed_mph );
          readingsBulkUpdate($hash, "windGust_kn", $windguest_kn );
          readingsBulkUpdate($hash, "windSpeed_kn", $windSpeed_kn );
          readingsBulkUpdate($hash, "windDirection", $windDirection );
          readingsBulkUpdate($hash, "windDirectionDegree", $windDirection * 360 / 16);     
          readingsBulkUpdate($hash, "windDirectionText", $windDirectionText );
        }
         if(($whid eq "0111") &&  ($model eq "WH1080"))
         { 
          $state = "UV: $FOuvo Lux: $FOlux ";
          readingsBulkUpdate($hash, "id", $id) if ($id ne "");
          readingsBulkUpdate($hash, "state", $state);
          #zusätzliche Daten UV + Lux
          readingsBulkUpdate($hash, "UV", $FOuvo );
          readingsBulkUpdate($hash, "Lux", $FOlux );
        }
        readingsEndUpdate($hash, 1); # Notify is done by Dispatch
    
    	return $name;
    
    }
    
    sub SD_WS09_Attr(@)
    {
      my @a = @_;
    
      # Make possible to use the same code for different logical devices when they
      # are received through different physical devices.
      return  if($a[0] ne "set" || $a[2] ne "IODev");
      my $hash = $defs{$a[1]};
      my $iohash = $defs{$a[3]};
      my $cde = $hash->{CODE};
      delete($modules{SD_WS09}{defptr}{$cde});
      $modules{SD_WS09}{defptr}{$iohash->{NAME} . "." . $cde} = $hash;
      return undef;
    }
    
    
    sub SD_WS09_bin2dec($)
    {
      my $h = shift;
      my $int = unpack("N", pack("B32",substr("0" x 32 . $h, -32))); 
      return sprintf("%d", $int); 
    }
    sub SD_WS09_binflip($)
    {
      my $h = shift;
      my $hlen = length($h);
      my $i = 0;
      my $flip = "";
      
      for ($i=$hlen-1; $i >= 0; $i--) {
        $flip = $flip.substr($h,$i,1);
      }
    
      return $flip;
    }
    
    
    sub SD_WS09_BCD2bin($) {
      my $binary = shift;
      my $int = unpack("N", pack("B32", substr("0" x 32 . $binary, -32)));
      my $BCD = sprintf("%x", $int );
      return $BCD;
    }
    
    sub SD_WS09_SHIFT($){
         my $rawData = shift;
         my $hlen = length($rawData);
         my $blen = $hlen * 4;
         my $bitData = unpack("B$blen", pack("H$hlen", $rawData));
    	   my $bitData2 = '1'.unpack("B$blen", pack("H$hlen", $rawData));
         my $bitData20 = substr($bitData2,0,length($bitData2)-1);
          $blen = length($bitData20);
          $hlen = $blen / 4;
          $rawData = uc(unpack("H$hlen", pack("B$blen", $bitData20)));
          $bitData = $bitData20;
          Log3 "SD_WS09_SHIFT", 4, "SD_WS09_SHIFT_0  raw: $rawData length:".length($bitData) ;
          Log3 "SD_WS09_SHIFT", 4, "SD_WS09_SHIFT_1  bitdata: $bitData" ;
        return $rawData;  
    }
    
    
    sub SD_WS09_CRCCHECK($) {
       my $rawData = shift;
       my $datacheck1 = pack( 'H*', substr($rawData,2,length($rawData)-2) );
       my $crcmein1 = Digest::CRC->new(width => 8, poly => 0x31);
       my $rr3 = $crcmein1->add($datacheck1)->hexdigest;
       $rr3 = sprintf("%d", hex($rr3));
       Log3 "SD_WS09_CRCCHECK", 4, "SD_WS09_CRCCHECK :  raw:$rawData CRC=$rr3 " ;
       return $rr3 ;
    }
    
    1;
    
    
=pod
=item summary    Supports weather sensors (WH1080/3080/CTW-600) protocl 9 from SIGNALduino
=item summary_DE Unterst&uumltzt Wettersensoren (WH1080/3080/CTW-600) mit Protokol 9 vom SIGNALduino
=begin html

<a name="SD_WS09"></a>
<h3>Wether Sensors protocol #9</h3>
<ul>
  The SD_WS09 module interprets temperature sensor messages received by a Device like CUL, CUN, SIGNALduino etc.<br>
  Requires Perl-Modul Digest::CRC. <br>
   <br> 
  cpan install Digest::CRC    or   sudo apt-get install libdigest-crc-perl <br>
   <br>
  <br>
  <b>Known models:</b>
  <ul>
    <li>WS-0101              --> Model: WH1080</li>
    <li>TFA 30.3189 / WH1080 --> Model: WH1080</li>
    <li>1073 (WS1080)        --> Model: WH1080</li>
     <li>WH3080               --> Model: WH1080</li>
    <li>CTW600               --> Model: CTW600 (??) </li> 
  </ul>
  <br>
  New received device are add in fhem with autocreate.
  <br><br>

  <a name="SD_WS09_Define"></a>
  <b>Define</b> 
  <ul>The received devices created automatically.<br>
  The ID of the defice is the model or, if the longid attribute is specified, it is a combination of model and some random generated bits at powering the sensor.<br>
  If you want to use more sensors, you can use the longid option to differentiate them.
  </ul>
  <br>
  <a name="SD_WS09 Events"></a>
  <b>Generated readings:</b>
  <br>Some devices may not support all readings, so they will not be presented<br>
  <ul>
   <li>State (T: H: Ws: Wg: Wd: R: )  temperature, humidity, windSpeed, windGuest, windDirection, Rain</li>
     <li>Temperature (&deg;C)</li>
     <li>Humidity: (The humidity (1-100 if available)</li>
     <li>Battery: (low or ok)</li>
     <li>ID: (The ID-Number (number if)</li>
     <li>windSpeed/windGuest (Unit_of_Wind)) and windDirection (N-O-S-W)</li>
     <li>Rain (mm)</li>
     <b>WH3080:</b>
     <li>UV Index</li>
     <li>Lux</li>
  </ul>
  <br>
  <b>Attributes</b>
  <ul>
    <li><a href="#do_not_notify">do_not_notify</a></li>
    <li><a href="#ignore">ignore</a></li>
    <li><a href="#showtime">showtime</a></li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
    <li>Model: WH1080,CTW600
    </li>
    <li>windKorrektur: -3,-2,-1,0,1,2,3   
    </li>
    <li>Unit_of_Wind<br>
    Unit of windSpeed and windGuest. State-Format: Value + Unit.
       <br>m/s,km/h,ft/s,mph,bft,knot 
    </li><br>
    <li>WS09_CRCAUS (set in Signalduino-Modul 00_SIGNALduino.pm)
       <br>0: CRC-Check WH1080 CRC-Summe = 0  on, default   
       <br>2: CRC-Summe = 49 (x031) WH1080, set OK
    </li>
   </ul> <br>
  <a name="SD_WS09_Set"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="SD_WS09_Parse"></a>
  <b>Parse</b> <ul>N/A</ul><br>

</ul>

=end html
=begin html_DE

<a name="SD_WS09"></a>
<h3>SD_WS09</h3>
<ul>
  Das SD_WS09 Module verarbeitet von einem IO Gerät (CUL, CUN, SIGNALDuino, etc.) empfangene Nachrichten von Temperatur-Sensoren.<br>
  <br>
  Perl-Modul Digest::CRC erforderlich. <br>
   <br>
    cpan install Digest::CRC oder auch             <br>
    sudo apt-get install libdigest-crc-perl         <br>
   <br>
  <br>
  <b>Unterstütze Modelle:</b>
  <ul>
    <li>WS-0101              --> Model: WH1080</li>
    <li>TFA 30.3189 / WH1080 --> Model: WH1080</li>
    <li>1073 (WS1080)        --> Model: WH1080</li>
    <li>WH3080               --> Model: WH1080</li>
    <li>CTW600               --> Model: CTW600</li>    
  </ul>
  <br>
  Neu empfangene Sensoren werden in FHEM per autocreate angelegt.
  <br><br>

  <a name="SD_WS09_Define"></a>
  <b>Define</b> 
  <ul>Die empfangenen Sensoren werden automatisch angelegt.<br>
  Die ID der angelegten Sensoren wird nach jedem Batteriewechsel ge&aumlndert, welche der Sensor beim Einschalten zuf&aumlllig vergibt.<br>
  CRC Checksumme wird zur Zeit noch nicht überpr&uumlft, deshalb werden Sensoren bei denen die Luftfeuchte < 0 oder > 100 ist, nicht angelegt.<br>
  </ul>
  <br>
  <a name="SD_WS09 Events"></a>
  <b>Generierte Readings:</b>
  <ul>
     <li>State (T: H: Ws: Wg: Wd: R: )  temperature, humidity, windSpeed, windGuest, Einheit, windDirection, Rain</li>
     <li>Temperature (&deg;C)</li>
     <li>Humidity: (The humidity (1-100 if available)</li>
     <li>Battery: (low or ok)</li>
     <li>ID: (The ID-Number (number if)</li>
     <li>windSpeed/windgust (Einheit siehe Unit_of_Wind)  and windDirection (N-O-S-W)</li>
     <li>Rain (mm)</li>
     <b>WH3080:</b>
     <li>UV Index</li>
     <li>Lux</li>
  </ul>
  <br>
  <b>Attribute</b>
  <ul>
    <li><a href="#do_not_notify">do_not_notify</a></li>
    <li><a href="#ignore">ignore</a></li>
    <li><a href="#showtime">showtime</a></li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
    <li>Model<br>
        WH1080, CTW600
    </li><br>
    <li>windKorrektur<br>
    Korrigiert die Nord-Ausrichtung des Windrichtungsmessers, wenn dieser nicht richtig nach Norden ausgerichtet ist. 
      -3,-2,-1,0,1,2,3    
    </li><br>
    <li>Unit_of_Wind<br>
    Hiermit wird der Einheit eingestellt und im State die entsprechenden Werte + Einheit angezeigt.
       <br>m/s,km/h,ft/s,mph,bft,knot 
    </li><br>
    
    <li>WS09_CRCAUS<br>
    Wird im Signalduino-Modul (00_SIGNALduino.pm) gesetzt 
       <br>0: CRC-Prüfung bei WH1080 CRC-Summe = 0  
       <br>2: CRC-Summe = 49 (x031) bei WH1080 wird als OK verarbeitet
    </li><br>
    
   </ul>

  <a name="SD_WS09_Set"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="SD_WS09_Parse"></a>
  <b>Parse</b> <ul>N/A</ul><br>

</ul>

=end html_DE
=cut

