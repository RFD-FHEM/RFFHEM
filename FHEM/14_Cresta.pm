##############################################
# $Id: 14_Cresta.pm  2015-08-30 $
# The file is taken from the SIGNALduino project
# see http://www.fhemwiki.de/wiki/SIGNALduino
# and was modified by a few additions
# to support Cresta Sensors
# S. Butzek, 2015
#

package main;

use strict;
use warnings;
use POSIX;

#####################################
sub
Cresta_un_Initialize($)
{
  my ($hash) = @_;


  $hash->{Match}     = "^..[A-Fa-f0-9]{1,40}"   ## Muss noch angepasst werden an .. = Länge von x - y oder über die {1,40}
  $hash->{DefFn}     = "Cresta_un_Define";
  $hash->{UndefFn}   = "Cresta_un_Undef";
  $hash->{AttrFn}    = "Cresta_un_Attr";
  $hash->{ParseFn}   = "Cresta_un_Parse";
  $hash->{AttrList}  = "IODev do_not_notify:0,1 showtime:0,1 ignore:0,1 ".$readingFnAttributes;
}


#####################################
sub
Cresta_un_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);

  return "wrong syntax: define <name> Cresta_un <code> <minsecs> <equalmsg>".int(@a)
		if(int(@a) < 3 || int(@a) > 5);

  $hash->{CODE}    = $a[2];
  $hash->{minsecs} = ((int(@a) > 3) ? $a[3] : 30);
  $hash->{equalMSG} = ((int(@a) > 4) ? $a[4] : 0);
  $hash->{lastMSG} =  "";
  $hash->{bitMSG} =  "";

  $modules{Cresta_un}{defptr}{$a[2]} = $hash;
  $hash->{STATE} = "Defined";

  AssignIoPort($hash);
  return undef;
}

#####################################
sub
Cresta_un_Undef($$)
{
  my ($hash, $name) = @_;
  delete($modules{Cresta_un}{defptr}{$hash->{CODE}}) if($hash && $hash->{CODE});
  return undef;
}

sub Cresta_un_hex2bin {
        my $h = shift;
        my $hlen = length($h);
        my $blen = $hlen * 4;
        return unpack("B$blen", pack("H$hlen", $h));
}

#####################################
sub
Cresta_un_Parse($$)
{
	my ($hash,$msg) = @_;
	my @a = split("", $msg);
	my $name = $hash->{NAME};
	Log3 $hash, 4, "$name incomming $msg";

	my $hlen = length($rawData);
	my $blen = $hlen * 4;
	$bitData= unpack("B$blen", pack("H$hlen", $rawData)); 
	Log3 $hash, 4, "$name converted to bits: $bitData";

	#### Hier kann nun alles zum Cresta Protokoll passieren. Da es vermutlich verschiedene Geräte mit verschiedenen Sensoren gibt, sollte das hier beachtet werden. Beispiele dazu in 41_OREGON, oder 14_SIGNALduino_AS...
	my $SensorTyp;
	my $id;
	my $channel;
	my $temp;
	my $hum;
	
	Log3 $hash, 4, "$name decoded Cresta protocol   $SensorTyp, sensor id=$id, channel=$channel, temp=$temp\n" if ($debug);
	  if ($id ne "") {
		$deviceCode = $model."_".$id;
	  }
	  
	  my $def = $modules{Cresta}{defptr}{$hash->{NAME} . "." . $deviceCode};
	  $def = $modules{Cresta}{defptr}{$deviceCode} if(!$def);
	  
	  if(!$def) {
		Log3 $hash, 1, "Cresta: UNDEFINED sensor $SensorTyp detected, code $deviceCode";
		return "UNDEFINED $SensorTyp"."_"."$deviceCode Cresta $deviceCode";
	  }

	  $hash = $def;
	  my $name = $hash->{NAME};
	  return "" if(IsIgnored($name));
	  
	  Log3 $name, 4, "Cresta: $name ($msg)";  
	  
	  if($hash->{lastReceive} && (time() - $hash->{lastReceive} < $def->{minsecs} )) {
		if (($def->{lastMSG} ne $msg) && ($def->{equalMSG} > 0)) {
		  Log3 $name, 4, "Cresta: $name: $deviceCode no skipping due unequal message even if to short timedifference";
		} else {
		  Log3 $name, 4, "Cresta: $name: $deviceCode Skipping due to short timedifference";
		  return "";
		}
	  }
	  $hash->{lastReceive} = time();

	  if(!$val) {
		Log3 $name, 1, "Cresta: $name: $deviceCode Cannot decode $msg";
		return "";
	  }
	  
	  $def->{lastMSG} = $msg;

	  Log3 $name, 4, "Cresta $name: $val";

	  readingsBeginUpdate($hash);
	  readingsBulkUpdate($hash, "state", $val);
	  readingsBulkUpdate($hash, "battery", $bat)   if ($bat ne "");
	  readingsBulkUpdate($hash, "trigger", $trigger) if ($trigger ne "");
	  readingsBulkUpdate($hash, "hum", $hum) if ($hum ne "");
	  readingsBulkUpdate($hash, "temp", $temp) if ($temp ne "");

	  readingsEndUpdate($hash, 1); # Notify is done by Dispatch

	  return $name;
}



sub
Cresta_un_Attr(@)
{
  my @a = @_;

  # Make possible to use the same code for different logical devices when they
  # are received through different physical devices.
  return if($a[0] ne "set" || $a[2] ne "IODev");
  my $hash = $defs{$a[1]};
  my $iohash = $defs{$a[3]};
  my $cde = $hash->{CODE};
  delete($modules{Cresta_un}{defptr}{$cde});
  $modules{Cresta_un}{defptr}{$iohash->{NAME} . "." . $cde} = $hash;
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

<a name="Cresta_un"></a>
<h3>Cresta_un</h3>
<ul>
  The Cresta_un module is a testing and debugging module to decode some devices
  <br><br>

  <a name="Cresta_undefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; Cresta_un &lt;code&gt; [minsecs] [equalmsg]</code> <br>

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

  <a name="Cresta_unset"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="Cresta_unget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="Cresta_unattr"></a>
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

<a name="Cresta_un"></a>
<h3>Cresta_un</h3>
<ul>
  Das Cresta_un module dekodiert vom Cresta empfangene Nachrichten von Arduino basierten Sensoren.
  <br><br>

  <a name="Cresta_undefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; Cresta_un &lt;code&gt; [minsecs] [equalmsg]</code> <br>

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

  <a name="Cresta_unset"></a>
  <b>Set</b> <ul>N/A</ul><br>

  <a name="Cresta_unget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="Cresta_unattr"></a>
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
