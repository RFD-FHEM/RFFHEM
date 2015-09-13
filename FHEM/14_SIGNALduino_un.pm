##############################################
# $Id: 14_SIGNALduino_un.pm 3818 2015-08-30 $
# The file is taken from the SIGNALduino project
# see http://www.fhemwiki.de/wiki/SIGNALduino
# and was modified by a few additions
# to support debugging of unknown signal data
# The purpos is to use it as addition to the SIGNALduino
# modules in combination with RFDuino
# S. Butzek, 2015
#

package main;

use strict;
use warnings;
use POSIX;

#####################################
sub
SIGNALduino_un_Initialize($)
{
  my ($hash) = @_;


  $hash->{Match}     = "u*";
  $hash->{DefFn}     = "SIGNALduino_un_Define";
  $hash->{UndefFn}   = "SIGNALduino_un_Undef";
  $hash->{AttrFn}    = "SIGNALduino_un_Attr";
  $hash->{ParseFn}   = "SIGNALduino_un_Parse";
  $hash->{AttrList}  = "IODev do_not_notify:0,1 showtime:0,1 ignore:0,1 ".$readingFnAttributes;
}


#####################################
sub
SIGNALduino_un_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);

  return "wrong syntax: define <name> SIGNALduino_un <code> <minsecs> <equalmsg>".int(@a)
		if(int(@a) < 3 || int(@a) > 5);

  $hash->{CODE}    = $a[2];
  $hash->{minsecs} = ((int(@a) > 3) ? $a[3] : 30);
  $hash->{equalMSG} = ((int(@a) > 4) ? $a[4] : 0);
  $hash->{lastMSG} =  "";
  $hash->{bitMSG} =  "";

  $modules{SIGNALduino_un}{defptr}{$a[2]} = $hash;
  $hash->{STATE} = "Defined";

  AssignIoPort($hash);
  return undef;
}

#####################################
sub
SIGNALduino_un_Undef($$)
{
  my ($hash, $name) = @_;
  delete($modules{SIGNALduino_un}{defptr}{$hash->{CODE}}) if($hash && $hash->{CODE});
  return undef;
}

sub SIGNALduino_un_hex2bin {
        my $h = shift;
        my $hlen = length($h);
        my $blen = $hlen * 4;
        return unpack("B$blen", pack("H$hlen", $h));
}

#####################################
sub
SIGNALduino_un_Parse($$)
{
	my ($hash,$msg) = @_;
	my @a = split("", $msg);
	my $name = $hash->{NAME};
	Log3 $hash, 4, "$name incomming $msg";
	my $rawData=substr($msg,2);
	my $hlen = length($rawData);
	my $blen = $hlen * 4;
	my $bitData= unpack("B$blen", pack("H$hlen", $rawData)); 
	Log3 $hash, 4, "$name converted to bits: $bitData";

        my $laenge = length($bitData);
          if ($laenge < 29) { 
            	Log3 $hash, 4, "Länge $laenge  stimmt nicht: $bitData" ;
              return;
        }

	if ($a[1] == "7")  ## Unknown Proto 7 
	{
		my $id = oct ("0b".substr($bitData,0,9));
		my $channel = oct ("0b".substr($bitData,10,2))+1;
		my $temp = oct ("0b".substr($bitData,12,11))/10;
		Log3 $hash, 4, "$name decoded protocolid: 7  sensor id=$id, channel=$channel, temp=$temp\n" ;
		
		## Try TX70DTH Decding
		my $SensorTyp = "TX70DTH";
		$channel = bin2dec(substr($bitData,9,3));
		my $bin = substr($bitData,0,8);
		my $id = sprintf('%X', oct("0b$bin"));
		my $bat = int(substr($bitData,8,1)) eq "1" ? "ok" : "critical";
		my $trend = "";
		my $sendMode = "";
		my $temp = bin2dec(substr($bitData,16,8));
		if (substr($bitData,14,1) eq "1") {
		  $temp = $temp - 1024;
		}
		$temp = $temp / 10;
		my $hum = bin2dec(substr($bitData,29,7));
		my $val = "T: $temp H: $hum B: $bat";
		Log3 $hash, 4, "$name decoded protocolid: 7  sensor id=$id, channel=$channel, temp=$temp\n" ;

		
		return;

	} elsif ($a[1] == "9")  ## Eurochron 
	{   

		  # EuroChron / Tchibo
		  #                /--------------------------- Channel, changes after every battery change      
		  #               /        / ------------------ Battery state 0 == Ok      
		  #              /        / /------------------ unknown      
		  #             /        / /  / --------------- forced send      
		  #            /        / /  /  / ------------- unknown      
		  #           /        / /  /  /     / -------- Humidity      
		  #          /        / /  /  /     /       / - neg Temp: if 1 then temp = temp - 2048
		  #         /        / /  /  /     /       /  / Temp
		  #         01100010 1 00 1  00000 0100011 0  00011011101
		  # Bit     0        8 9  11 12    17      24 25        36
		my $SensorTyp = "EuroChron";
		my $channel = "";
		my $bin = substr($bitData,0,8);
		my $id = sprintf('%X', oct("0b$bin"));
		my $bat = int(substr($bitData,8,1)) eq "0" ? "ok" : "critical";
		my $trend = "";
		my $sendMode = int(substr($bitData,11,1)) eq "0" ? "automatic" : "manual";
		my $temp = bin2dec(substr($bitData,25,11));
		if (substr($bitData,24,1) eq "1") {
		  $temp = $temp - 2048
		}
		$temp = $temp / 10.0;
		my $hum = bin2dec(substr($bitData,17,7));
		my $val = "T: $temp H: $hum B: $bat";
		Log3 $hash, 4, "$name decoded protocolid: 9  $SensorTyp, sensor id=$id, channel=$channel, temp=$temp\n" ;

		return;
	} elsif ($a[1] == "9")  ## Unknown Proto 9 
	{   #http://nupo-artworks.de/media/report.pdf
		my $syncpos= index($bitData,"1111111110");
		my $sensdata = substr($bitData,$syncpos+10);

		my $id = substr($sensdata,4,6);
		my $bat = substr($sensdata,0,3);
		my $temp = substr($sensdata,12,10);
		my $hum = substr($sensdata,22,8);
		my $wind = substr($sensdata,30,16);
		my $rain = substr($sensdata,46,16);
		my $winddir = substr($sensdata,66,4);
		
		Log3 $hash, 4, "$name found ctw600 syncpos at $syncpos message is: $sensdata - sensor id:$id, bat:$bat, temp=$temp, hum=$hum, wind=$wind, rain=$rain, winddir=$winddir";

		return;
	} elsif ($a[1] == "1" and $a[2] == "3")  ## RF20 Protocol 
	{  
		my $deviceCode = $a[3].$a[5].$a[6].$a[7].$a[8].$a[9];
		my  $Freq = $a[10].$a[11].$a[12].$a[13].$a[14];

		Log3 $hash, 4, "$name found TCM dorrbell protocol. devicecode=$deviceCode, freq=$Freq ";
		return;
	}
	elsif ($a[1] == "1" and $a[2] == "4")  ## Heidman HX 
	{  
		my $deviceCode = $a[4].$a[5].$a[6].$a[7].$a[8];

		my $bin = substr($bitData,0,4);
		my $deviceCode = sprintf('%X', oct("0b$bin"));
 	    my $sound = substr($bitData,7,5);

		Log3 $hash, 4, "$name found Heidman HX doorbell. devicecode=$deviceCode, sound=$sound";

		return;
	}
	elsif ($a[1] == "1" and $a[2] == "5")  ## TCM 
	{  
		my $deviceCode = $a[4].$a[5].$a[6].$a[7].$a[8];


		Log3 $hash, 4, "$name found TCM doorbell. devicecode=$deviceCode";

		return;
	}

  return $name;
}



sub
SIGNALduino_un_Attr(@)
{
  my @a = @_;

  # Make possible to use the same code for different logical devices when they
  # are received through different physical devices.
  return if($a[0] ne "set" || $a[2] ne "IODev");
  my $hash = $defs{$a[1]};
  my $iohash = $defs{$a[3]};
  my $cde = $hash->{CODE};
  delete($modules{SIGNALduino_un}{defptr}{$cde});
  $modules{SIGNALduino_un}{defptr}{$iohash->{NAME} . "." . $cde} = $hash;
  return undef;
}

sub
hex2bin($)
{
  my $h = shift;
  my $hlen = length($h);
  my $blen = $hlen * 4;
  return unpack("B$blen", pack("H$hlen", $h));
}

sub
bin2dec($)
{
  my $h = shift;
  my $int = unpack("N", pack("B32",substr("0" x 32 . $h, -32))); 
  return sprintf("%d", $int); 
}
sub
binflip($)
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

1;

=pod
=begin html

<a name="SIGNALduino_un"></a>
<h3>SIGNALduino_un</h3>
<ul>
  The SIGNALduino_un module is a testing and debugging module to decode some devices
  <br><br>

  <a name="SIGNALduino_undefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; SIGNALduino_un &lt;code&gt; [minsecs] [equalmsg]</code> <br>

    <br>
    &lt;code&gt; is the housecode of the autogenerated address of the Env device and 
	is build by the channelnumber (1 to 3) and an autogenerated address build when including
	the battery (adress will change every time changing the battery).<br>
    minsecs are the minimum seconds between two log entries or notifications
    from this device. <br>E.g. if set to 300, logs of the same type will occure
    with a minimum rate of one per 5 minutes even if the device sends a message
    every minute. (Reduces the log file size and reduces the time to display
    the plots)<br>
	equalmsg set to 1 generates, if even if minsecs is set, a log entrie or notification
	when the msg content has changed.
  </ul>
  <br>

  <a name="SIGNALduino_unset"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="SIGNALduino_unget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="SIGNALduino_unattr"></a>
  <b>Attributes</b>
  <ul>
    <li><a href="#IODev">IODev (!)</a></li>
    <li><a href="#do_not_notify">do_not_notify</a></li>
    <li><a href="#eventMap">eventMap</a></li>
    <li><a href="#ignore">ignore</a></li>
    <li><a href="#model">model</a> (LogiLink Env)</li>
    <li><a href="#showtime">showtime</a></li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
  </ul>
  <br>
</ul>

=end html

=begin html_DE

<a name="SIGNALduino_un"></a>
<h3>SIGNALduino_un</h3>
<ul>
  Das SIGNALduino_un module dekodiert vom SIGNALduino empfangene Nachrichten von Arduino basierten Sensoren.
  <br><br>

  <a name="SIGNALduino_undefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; SIGNALduino_un &lt;code&gt; [minsecs] [equalmsg]</code> <br>

    <br>
    &lt;code&gt; ist der automatisch angelegte Hauscode des Env und besteht aus der
	Kanalnummer (1..3) und einer Zufallsadresse, die durch das Gerät beim einlegen der
	Batterie generiert wird (Die Adresse ändert sich bei jedem Batteriewechsel).<br>
    minsecs definert die Sekunden die mindesten vergangen sein müssen bis ein neuer
	Logeintrag oder eine neue Nachricht generiert werden.
    <br>
	Z.B. wenn 300, werden Einträge nur alle 5 Minuten erzeugt, auch wenn das Device
    alle paar Sekunden eine Nachricht generiert. (Reduziert die Log-Dateigröße und die Zeit
	die zur Anzeige von Plots benötigt wird.)<br>
	equalmsg gesetzt auf 1 legt fest, dass Einträge auch dann erzeugt werden wenn die durch
	minsecs vorgegebene Zeit noch nicht verstrichen ist, sich aber der Nachrichteninhalt geändert
	hat.
  </ul>
  <br>

  <a name="SIGNALduino_unset"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="SIGNALduino_unget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="SIGNALduino_unattr"></a>
  <b>Attributes</b>
  <ul>
    <li><a href="#IODev">IODev (!)</a></li>
    <li><a href="#do_not_notify">do_not_notify</a></li>
    <li><a href="#eventMap">eventMap</a></li>
    <li><a href="#ignore">ignore</a></li>
    <li><a href="#model">model</a> (LogiLink Env)</li>
    <li><a href="#showtime">showtime</a></li>
    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
  </ul>
  <br>
</ul>

=end html_DE
=cut
