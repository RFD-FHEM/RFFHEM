##############################################
# $Id: 10_FS10.pm 331 2017-12-28 17:40:00Z v3.3-dev $
#
# FS10 basierend auf dem FS20 Modul angepasst für SIGNALduino, elektron-bbs
#
# 2017-12-28  FS10_Set          	Checksumme für Wiederholung wurde falsch berechnet
#                               	Pause zwischen Wiederholung jetzt immer 200 mS
#                               	SignalRepeats jetzt auch im Abstand von 200 mS
#                               	Anzahl Wiederholungen bei Dimm-Befehlen korrigiert
#                               	Anzahl Dimup/Dimdown auf 1-10 begrenzt
#											keine Wiederholungen bei Markisensteuerung	
#             FS10_Initialize   	Anzahl Wiederholungen auf 1 bis 9 begrenzt
package main;

use strict;
use warnings;

my %codes = (
  "0" => "off_1",
  "2" => "off_2",
  "1" => "on_1",
  "3" => "on_2",
  "8" => "dimdown_1",  # 0 | 8 = 8
  "4" => "dimdown_2",
  "9" => "dimup_1",    # 1 | 8 = 9
  "5" => "dimup_2",
);


use vars qw(%fs10_c2b);		# Peter would like to access it from outside

my %models = (
    FS10_ST      => 'simple',
    FS10_DI      => 'dimmer',
    FS10_HD      => 'dimmer',
    FS10_SA      => 'timer',
    FS10_MS      => 'simple',
    FS10_S4      => 'remote',
    FS10_S8      => 'remote',
);


sub
FS10_Initialize($)
{
  my ($hash) = @_;

  foreach my $k (keys %codes) {
    $fs10_c2b{$codes{$k}} = $k;
  }

  $hash->{Match}     = '^P61#[a-fA-F0-9]{8,12}';
  $hash->{SetFn}     = "FS10_Set";
  $hash->{DefFn}     = "FS10_Define";
  $hash->{UndefFn}   = "FS10_Undef";
  $hash->{ParseFn}   = "FS10_Parse";
  $hash->{AttrList}  = "IODev follow-on-for-timer:1,0 follow-on-timer ".
                       "do_not_notify:1,0 repetition:1,2,3,4,5,6,7,8,9 ".
                       "ignore:1,0 dummy:1,0 showtime:1,0 ".
                       "$readingFnAttributes " .
                       "model:".join(",", sort keys %models);
}

###################################
sub
FS10_Set($@)
{
  my ($hash, $name, @a) = @_;
  my $ioname = $hash->{IODev}{NAME};
  my $ret = undef;
  my $na = int(@a);						# Anzahl in Array 

  return "no set value specified" if ($na < 1);    # if($na < 2 || $na > 3);
  return "Dummydevice $hash->{NAME}: will not set data" if(IsDummy($hash->{NAME}));

  my $model = AttrVal($name, "model", "FS10_ST");
  my $modelType = $models{$model};
  my $list .= "off:noArg on:noArg " if ($modelType ne "remote" );
  $list .= "dimup:1,2,3,4,5,6,7,8,9,10 dimdown:1,2,3,4,5,6,7,8,9,10 " if ($modelType eq "dimmer" );
  
  return SetExtensions($hash, $list, $name, @a) if( $a[0] eq "?" );
  return SetExtensions($hash, $list, $name, @a) if( !grep( $_ =~ /^\Q$a[0]\E($|:)/, split( ' ', $list ) ) );
  
  my $setstate = $a[0];
  my $temp = "";
  my $ebeneh = substr($hash->{BTN}, 0, 1);
  my $ebenel = substr($hash->{BTN}, 1, 1);
  my $housecode = $hash->{HC} - 1;
  my $kc;
  my $SignalRepeats = AttrVal($name,'repetition', '0') + 1;
  my $dimm = 0;
	my $newmsg = "P61#";
  
	if ($model eq "FS10_MS") {
		$SignalRepeats = 1;
	}
	
  if ($SignalRepeats > 10) {
		$SignalRepeats = 10;
  }
  
  if ($na > 1 && $setstate =~ m/dim/) {		# Anzahl dimup / dimdown
		$dimm += $a[1];
		if ($dimm < 1 || $dimm >10) {
			Log3 $name, 1, "$ioname: FS10 set $name $setstate $dimm - ERROR dimm value too low or high (1-10)";
			return "FS10 set $name $setstate $dimm - ERROR: dimm value too low or high (1-10)";
		} else {
			Log3 $name, 3, "$ioname: FS10 set $name $setstate $dimm";
			$newmsg .= "R1#";							# 1 Repeat
		}
  } else {
    Log3 $name, 3, "$ioname: FS10 set $name $setstate";
  }
  Log3 $name, 4, "$ioname: FS10 set $name hc=$housecode ebeneHL=$ebeneh$ebenel setstate=$setstate";

   for my $i (1..2) {
      my $sum = 0;
      if ($i == 1) {
        $kc = $fs10_c2b{$setstate."_1"};
      }
      else {
        $kc = $fs10_c2b{$setstate."_2"};
      }
      $kc = $kc & 7;
      if (defined($kc)) {
			Log3 $name, 4, "$ioname: FS10 set $name setstate$i=$setstate command=$kc";
			$newmsg .= "0000000000001";				# 12 Bit Praeambel, 1 Pruefbit
			$newmsg .= dec2nibble($kc);				# 1. setstate
			$sum += $kc;
			$newmsg .= dec2nibble($ebenel);			# 2. Ebene low
			$sum += $ebenel;
			$newmsg .= dec2nibble($ebeneh);			# 3. Ebene high
			$sum += $ebeneh;
			$newmsg .= "10001";							# 4. unused
			$newmsg .= dec2nibble($housecode);		# 5. housecode
			$sum += $housecode;
			if ($sum >= 11) {
				$temp = 18 - $sum;
			} else {
				$temp = 10 - $sum;
			}
			$newmsg .= dec2nibble($temp);				# 6. Summe
			if ($dimm == 0) {									# ein / aus
				if ($i == 1) {										# 1. Teil Nachricht
					$newmsg .= "PPPP";								# 4*32400=129600 Pause
				} else {												# 2. Teil Nachricht
					if ($SignalRepeats == 1) {
						$newmsg .= "#R1";         						# 1 Repeat
					} else {										
						$newmsg .= "PPPPPP#R" . $SignalRepeats;	# 6*32400=194400 Pause . Repeats
					}
					Log3 $name, 5, "$ioname: FS10 set sendMsg=$newmsg";
					IOWrite($hash, 'sendMsg', $newmsg);
				}
			} else {												# dimmen
				if ($i == 1) {										# 1. Nachricht
					$newmsg .= "PPPPPPPPPPPPPPPPPPPP#R1#";		# 20*32400=648000 Pause . 1 Repeat (original remote control)
					#$newmsg .= "PPPPPP#R1#";						# 6*32400=194400 Pause . 1 Repeat
				} else {												# 2. Nachricht
					if ($dimm == 1) {
						$newmsg .= "#R1";         						# 1 Repeat
					} else {										
						$newmsg .= "PPPPPP#R" . $dimm;				# 6*32400=194400 Pause . Repeats
					}
					Log3 $name, 5, "$ioname: FS10 set sendMsgCombined=$newmsg";
					IOWrite($hash, 'sendMsgCombined', $newmsg);
				}
			}
      }
   }
 
  ###########################################
  # Set the state of a device to off if on-for-timer is called
  if($modules{FS10}{ldata}{$name}) {
    CommandDelete(undef, $name . "_timer");
    delete $modules{FS10}{ldata}{$name};
  }

  ####################################
  # following timers
  if ($setstate eq "on" && AttrVal($name, "follow-on-for-timer", 0)) {
      my $dur = AttrVal($name, "follow-on-timer", 0);
      if ($dur > 0) {
         my $newState = "off";
         my $to = sprintf("%02d:%02d:%02d", $dur/3600, ($dur%3600)/60, $dur%60);
         Log3 $name, 3, "$ioname FS10_set: $name Set_Follow +$to setstate $newState";
         CommandDefine(undef, $name."_timer at +$to "."setstate $name $newState; trigger $name $newState");
         $modules{FS10}{ldata}{$name} = $to;
      }
  }

  readingsBeginUpdate($hash);
  readingsBulkUpdate($hash, "state", $setstate);
  readingsEndUpdate($hash, 1); # Notify is done by Dispatch
  
  return $ret;
}

#############################
sub
FS10_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);

  my $u = "wrong syntax: define <name> FS10 housecode_button";

  return $u if(int(@a) < 3);
  
  my ($housecode, $btncode) = split("_", $a[2], 2);
  
  return "Define $a[0]: wrong syntax: housecode_button"
     if (!defined($housecode) || !defined($btncode));
  
  return "Define $a[0]: wrong housecode format: specify a 1 digit value [1-8]"
     if ($housecode !~ m/^[1-8]$/i );
  
  return "Define $a[0]: wrong button format: specify a 2 digit value [0-7]"
     if ($btncode !~ m/^[0-7]{2}$/i ); # Ebene Low, Ebene High

  $hash->{HC} = $housecode;
  $hash->{BTN} = $btncode;
  $hash->{CODE} = $a[2];
  $modules{FS10}{defptr}{$a[2]} = $hash;

  AssignIoPort($hash);
}

#############################
sub
FS10_Undef($$)
{
  my ($hash, $name) = @_;
  delete($modules{FS10}{defptr}{$hash->{CODE}})
     if(defined($hash->{CODE}) &&
        defined($modules{FS10}{defptr}{$hash->{CODE}}));
  return undef;
}

sub
FS10_Parse($$)
{
  my ($iohash, $msg) = @_;
  my $ioname = $iohash->{NAME};
  my ($protocol,$rawData) = split("#",$msg);
  my $err;
  my $gesErr;
  my $cde;
  my $ebenel;
  my $ebeneh;
  my $u;
  my $dev;
  my $sum;
  my $rsum;
  
  my $hlen = length($rawData);
  my $blen = $hlen * 4;
  $protocol=~ s/^[P](\d+)/$1/; # extract protocol
  my $bitData = unpack("B$blen", pack("H$hlen", $rawData));

  Log3 $ioname, 4, "$ioname FS10_Parse: Protocol: $protocol, rawData: $rawData";
  Log3 $ioname, 4, "$ioname FS10_Parse: rawBitData: $bitData ($blen)";
  
  my $datastart = 0;
  $datastart = index($bitData, "001");						# datastart 10 = 12 bit preamble
  return "" if ($datastart < 0 || $datastart > 10);	# -1 if not found || max. 12 bit preamble
  
  $bitData = substr($bitData, $datastart+2);
  $blen = length($bitData);
  
  Log3 $ioname, 4, "$ioname FS10_Parse: datastart: $datastart, blen: $blen, bitData=$bitData";
  return "" if ($blen < 30 || $blen > 38);
  
  ($err, $cde) = nibble2dec(substr($bitData, 0, 5));    # Command Code
  $gesErr = $err;
  $sum = $cde;
  
  ($err, $ebenel) = nibble2dec(substr($bitData, 5, 5)); # EbeneL
  $gesErr += $err;
  $sum += $ebenel;
  
  ($err, $ebeneh) = nibble2dec(substr($bitData,10,5));  # EbeneH
  $gesErr += $err;
  $sum += $ebeneh;
  
  ($err, $u) = nibble2dec(substr($bitData,15,5));       # unbenutzt, muss 0 sein
  if ($u != 0) {
    $err = 1;
  }
  $gesErr += $err;
  $sum += $u;
  
  ($err, $dev) = nibble2dec(substr($bitData,20,5));     # housecode
  $gesErr += $err;
  $sum += $dev;
  
  ($err, $rsum) = nibble2dec(substr($bitData,25,5));    # Summe
  $gesErr += $err;

  if ($sum > 11) {
    $sum = 18 - $sum;
  }
  else {
    $sum = 10 - $sum;
  }
  $sum = $sum & 7;
  if ($sum != $rsum) {
    Log3 $ioname, 3, "$ioname FS10_Parse: error sum=$sum rsum=$rsum bitData=$bitData";
    return "";
  }
  if ($gesErr > 0) {
    Log3 $ioname, 3, "$ioname FS10_Parse: $gesErr errors bitData=$bitData";
    return "";
  }
  
  $dev++;
  my $v = $codes{$cde};
  $v = "unknown_$cde" if(!defined($v));
  my $btn = $ebeneh . $ebenel;
  my $deviceCode = $dev . "_" . $btn;
  
  Log3 $ioname, 4, "$ioname FS10_Parse: cde=$cde $v ebeneHL=$btn u=$u hc=$dev rsum=$rsum";
  
  $v =~ s/_[1,2]$//;      # _1 oder _2 am Ende abschneiden
  
  my $def = $modules{FS10}{defptr}{$iohash->{NAME} . "." . $deviceCode};
  $def = $modules{FS10}{defptr}{$deviceCode} if(!$def);

  if(!$def) {
    Log3 $ioname, 3, "$ioname FS10_Parse: Unknown device $dev, " . "Button $btn Code $cde ($v), please define it";
    return "UNDEFINED FS10_$deviceCode FS10 $deviceCode";
  }
  
  my $hash = $def;
  my $name = $hash->{NAME};
  return "" if(IsIgnored($name));
  Log3 $name, 4, "$ioname FS10_Parse: $name $v";
  
  if ($v eq "on" && AttrVal($name, "follow-on-for-timer", 0)) {
      my $dur = AttrVal($name, "follow-on-timer", 0);
      if ($dur > 0) {
         my $newState = "off";
         my $to = sprintf("%02d:%02d:%02d", $dur/3600, ($dur%3600)/60, $dur%60);
         Log3 $name, 4, "$ioname FS10_Parse: $name Set_Follow +$to setstate $newState";
         CommandDefine(undef, $name."_timer at +$to "."setstate $name $newState; trigger $name $newState");
         $modules{FS10}{ldata}{$name} = $to;
      }
  }
 
  readingsBeginUpdate($hash);
  readingsBulkUpdate($hash, "state", $v);
  readingsEndUpdate($hash, 1); # Notify is done by Dispatch
  
  return $name;
}


#######################
sub nibble2dec {
	my $nibble = shift;
	my $parity = 1;
	my $err;
	my $dec = oct("0b" . substr($nibble, 2));

	for(my $i = 0; $i < 4; $i++) {
	      $parity += substr($nibble, $i+1, 1);
	}
	$err = $parity % 2;
	if (substr($nibble, 0, 1) eq "0") {    # das erste Bit muss 1 sein
	   $err = 1;   
	}
	return ($err, $dec);
}

sub dec2nibble {
	my $num = shift;
	my $parity = 1;								# Paritaet ungerade
	my $result = "";

	for(my $i = 0; $i < 3; $i++) {
		my $reminder = $num % 2;				# Modulo division to get reminder
		$result = $reminder . $result;		# Concatenation of two numbers
		$parity += $reminder;
		$num /= 2;									# New Value of decimal number to do next set of above operations
	}
	$result = ($parity % 2) . $result . "1";	# paritybit . bin( num) . checkbit
	return $result;
}

1;

=pod
=item summary devices communicating using the ELV FS10 protocol
=item summary_DE Anbindung von FS10 Ger&auml;ten

=begin html

<a name="FS10"></a>
<h3>FS10</h3>
The FS10 module decrypts and sends FS10 messages sent by the SIGNALduino. The following types are supported at the moment: simple, dimmer, timer, remote<br>
<br>
<a name="FS10define"></a>
<b>Define</b>
<ul>
	<p><code>define &lt;name&gt; FS10 &lt;hauscode&gt;_&lt;button&gt;</code>
	<br>
	<br>
	<code>&lt;name&gt;</code> is any name assigned to the device.
	For a better overview it is recommended to use a name in the form &quot;FS10_6_12&quot;, where &quot;6&quot; is the used house code and &quot;12&quot; is the address of the button.
	<br /><br />
	<code>&lt;hauscode&gt;</code> corresponds to the house code of the remote control or the device to be controlled. The house code is 1-8.
	<br /><br />
	<code>&lt;button&gt;</code> represents the keyboard level or address of the devices used. Address &quot;11&quot; corresponds to the two buttons at the top row of remote control FS10-S8.<br />  
</ul>   
<a name="FS10set"></a>
<b>Set</b>
<ul>
  <code>set &lt;name&gt; &lt;value&gt; [&lt;anz&gt;]</code>
  <br /><br />
  <code>&lt;value&gt;</code> can be one of the following values:<br>
  <pre>
  dimdown
  dimup
  off
  on
  </pre>
  
  For dimup and dimdown, you can optionally use &lt;anz&gt; for the number of repetitions.
	<br /><br />
  The <a href="#setExtensions">set extensions</a> are supported.
</ul>
<a name="FS10get"></a>
<b>Get</b>
<ul>
	N/A
</ul>
<a name="FS10attr"></a>
<b>Attribute</b>
<ul>
        <li><a href="#IODev">IODev</a></li>
	<li><a href="#do_not_notify">do_not_notify</a></li>
	<li><a href="#eventMap">eventMap</a></li>
	<li>follow-on-for-timer (enable/disable follow-on-timer)</li>
	<li>follow-on-timer (Number of seconds after the timer of the FS10_SA the state automatically goes back to off.)</li>
	<li><a href="#ignore">ignore</a></li>
	<li>model</li>
    <pre>
    FS10_ST  simple
    FS10_DI  dimmer
    FS10_HD  dimmer
    FS10_SA  timer
    FS10_MS  simple
    FS10_S4  remote
    FS10_S8  remote
    </pre>
	<li><a href="#readingFnAttributes">readingFnAttributes</a></li>
</ul>
=end html

=begin html_DE

<a name="FS10"></a>
<h3>FS10</h3>
Das FS10-Modul entschl&uuml;sselt und sendet Nachrichten vom Typ FS10, die vom
SIGNALduino verarbeitet werden. Unterst&uuml;tzt werden z.Z. folgende Typen: simple, dimmer, timer, remote<br>
<br>
<a name="FS10define"></a>
<b>Define</b>
<ul>
	<p><code>define &lt;name&gt; FS10 &lt;hauscode&gt;_&lt;button&gt;</code>
	<br>
	<br>
	<code>&lt;name&gt;</code> ist ein beliebiger Name, der dem Ger&auml;t zugewiesen wird.
	 Zur besseren &Uuml;bersicht wird empfohlen einen Namen in der Form &quot; FS10_6_12&quot; zu verwenden,
	  wobei &quot;6&quot; der verwendete Hauscode und &quot;12&quot; die Adresse darstellt.
	<br /><br />
	<code>&lt;hauscode&gt;</code> entspricht dem Hauscode der verwendeten Fernbedienung bzw. des Ger&auml;tes, das gesteuert werden soll. Als Hauscode wird 1-8 verwendet.
	<br /><br />
	<code>&lt;button&gt;</code> stellt die Tastaturebene bzw. Adresse der verwendeten Ger&auml;te dar. Adresse &quot;11&quot; entspricht auf der Fernbedienung FS10-S8 z.B. den beiden Tasten der obersten Reihe.<br />  
</ul>   
<a name="FS10set"></a>
<b>Set</b>
<ul>
  <code>set &lt;name&gt; &lt;value&gt; [&lt;anz&gt;]</code>
  <br /><br />
  <code>&lt;value&gt;</code> kann einer der folgenden Werte sein:<br>
  <pre>
  dimdown
  dimup
  off
  on
  </pre>
  
  Bei dimup und dimdown kann optional mit &lt;anz&gt; die Anzahl der Wiederholungen im Bereich von 1 bis 10 angegeben werden.
  <br /><br />
  Die <a href="#setExtensions">set extensions</a> werden unterst&uuml;tzt.
</ul>
<a name="FS10get"></a>
<b>Get</b>
<ul>
	N/A
</ul>
<a name="FS10attr"></a>
<b>Attribute</b>
<ul>
        <li><a href="#IODev">IODev</a></li>
	<li><a href="#do_not_notify">do_not_notify</a></li>
	<li><a href="#eventMap">eventMap</a></li>
	<li>follow-on-for-timer (enable/disable follow-on-timer)</li>
	<li>follow-on-timer (Anzahl Sekunden nachdem beim Timer des FS10_SA der state automatisch wieder auf off geht)</li>
	<li><a href="#ignore">ignore</a></li>
	<li>model</li>
    <pre>
    FS10_ST  simple
    FS10_DI  dimmer
    FS10_HD  dimmer
    FS10_SA  timer
    FS10_MS  simple
    FS10_S4  remote
    FS10_S8  remote
    </pre>
	<li>repetition (Anzahl Wiederholungen der Sendebefehle)</li>
	<li><a href="#readingFnAttributes">readingFnAttributes</a></li>
</ul>
=end html_DE
=cut
