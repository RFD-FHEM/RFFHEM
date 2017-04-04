##############################################
# $Id: 10_FS10.pm 331 2017-03-30 20:00:00Z v3.3-dev $
#
# FS10 basierend auf dem FS20 Modul (FHEM 5.3), elektron-bbs

package main;

use strict;
use warnings;

my %codes = (
  "0" => "off",
  "2" => "off",
  "1" => "on",
  "3" => "on",
  "4" => "dimdown",
  "5" => "dimup",
);


use vars qw(%fs10_c2b);		# Peter would like to access it from outside

my %models = (
    FS10_ST      => 'simple',
    FS10_DI      => 'dimmer',
    FS10_HD      => 'dimmer',
    FS10_SA      => 'timer',
    
);

sub
FS10_Initialize($)
{
  my ($hash) = @_;

  foreach my $k (keys %codes) {
    $fs10_c2b{$codes{$k}} = $k;
  }

  $hash->{Match}     = "^FS10[a-fA-F0-9]{8}";
  $hash->{SetFn}     = "FS10_Set";
  $hash->{DefFn}     = "FS10_Define";
  $hash->{UndefFn}   = "FS10_Undef";
  $hash->{ParseFn}   = "FS10_Parse";
  $hash->{AttrList}  = "IODev follow-on-for-timer:1,0 follow-on-timer ".
                       "do_not_notify:1,0 ".
                       "ignore:1,0 dummy:1,0 showtime:1,0 ".
                       "$readingFnAttributes " .
                       "model:".join(",", sort keys %models);
}

###################################
sub
FS10_Set($@)
{
  my ($hash, $name, @a) = @_;
  #my $name = $a[0];						# z.B. FS10_0111
  # Log GetLogLevel($name,2), "FS10_Set: name $name";		# FS10_0111
  # Log GetLogLevel($name,2), "FS10: hash $hash";		# HASH(0xab56a2c)
  # Log GetLogLevel($name,2), "FS10: a    @a";			# FS10_0111 dimdown 10
  my $ret = undef;
  my $na = int(@a);						# Anzahl in Array 
  Log3 $name, 3, "FS10: na   $na";		# 2 oder 3

  return "no set value specified" if ($na < 1);    # if($na < 2 || $na > 3);
  return "Dummydevice $hash->{NAME}: will not set data" if(IsDummy($hash->{NAME}));

  my $list .= "off:noArg on:noArg ";
  my $model = AttrVal($name, "model", "FS10_ST");
  my $modelType = $models{$model};
  
  Log3 $name, 3, "FS10_Set: $name, a0=$a[0]";
  
  $list .= "dimup:noArg dimdown:noArg " if ($modelType eq "dimmer" );
  
  return SetExtensions($hash, $list, $name, @a) if( $a[0] eq "?" );
  return SetExtensions($hash, $list, $name, @a) if( !grep( $_ =~ /^\Q$a[0]\E($|:)/, split( ' ', $list ) ) );
  
 # if($na > 2 && $a[1] eq "dim") {
 #    my $dimvalue = $a[2];
 #    #Log GetLogLevel($name,2), "FS10: dimvalue    $dimvalue";
 #    $a[1] = ($a[2] eq "0" ? "off" : sprintf("dim%02d%%",$a[2]) );
 #    splice @a, 2, 1;
 #    $na = int(@a);
 # }
 
  #my $v = join(" ", @a);	# FS10_0111 off
  #(undef, $v) = split(" ", $v, 2);	# Not interested in the name...

  my $setstate = $a[0];
  my $val;

  my $sum = 0;
  my $temp = "";
  my $ebenel = substr($hash->{BTN}, 0, 1);
  my $ebeneh = substr($hash->{BTN}, 1, 1);
  my $housecode = $hash->{XMIT} - 1;
  
  Log3 $name, 3, "$name: set housecode=$housecode ebeneLH=$ebenel $ebeneh setstate=$setstate";

  # Nachricht 1, Taste druecken
  my $newmsg = "P61#0000000000001";		# 12 Bit Praeambel, 1 Pruefbit
  if ($setstate eq "on") {
	$newmsg .= "00011";			# 1. Kommando on, Wiederholbit 1 nicht gesetzt
	$sum = 1;
  } else {
	$newmsg .= "10001";			# 1. Kommando off, Wiederholbit 1 nicht gesetzt
  }

  $temp = $ebenel;				# 2. Ebene low
  $newmsg .= dec2nibble($temp);		
  $sum += $temp;

  $temp = $ebeneh;				# 3. Ebene high
  $newmsg .= dec2nibble($temp);		
  $sum += $temp;

  $newmsg .= "10001";				# 4. unused

  $temp = $housecode;				# 5. Hauscode
  $newmsg .= dec2nibble($temp);		
  $sum += $temp;

  if ($sum >= 11) {				# 6. Summe
	$temp = 18 - $sum;
  } else {
	$temp = 10 - $sum;
  }
  $newmsg .= dec2nibble($temp);

  $newmsg .= "#R1";

  IOWrite($hash, 'sendMsg', $newmsg);
  #select(undef, undef, undef, 0.2); 
  Log3 $name, 3, "$name: Send message #1 $newmsg";
  #Log3 $name, 3, "$name: wait 200 mS";
  
  # Nachricht 2, Taste loslassen
  $sum = 0;
  $newmsg = "P61#0000000000001";		# 12 Bit Praeambel, 1 Pruefbit
  if ($setstate eq "on") {
	$newmsg .= "10111";			# 1. Kommando on, Wiederholbit 1 gesetzt
	$sum = 3;
  } else {
	$newmsg .= "00101";			# 1. Kommando off, Wiederholbit 1 gesetzt
	$sum = 2;
  }

  $temp = $ebenel;				# 2. Ebene low
  $newmsg .= dec2nibble($temp);
  $sum += $temp;

  $temp = $ebeneh;				# 3. Ebene high
  $newmsg .= dec2nibble($temp);		
  $sum += $temp;

  $newmsg .= "10001";				# 4. unused

  $temp = $housecode;				# 5. Hauscode
  $newmsg .= dec2nibble($temp);		
  $sum += $temp;

  if ($sum >= 11) {				# 6. Summe
	$temp = 18 - $sum;
  } else {
	$temp = 10 - $sum;
  }
  $newmsg .= dec2nibble($temp);		

  $newmsg .= "#R1";
  Log3 $name, 3, "$name: Send message #2 $newmsg";
  IOWrite($hash, 'sendMsg', $newmsg);
  
  ###########################################
  # Set the state of a device to off if on-for-timer is called
  if($modules{FS10}{ldata}{$name}) {
    CommandDelete(undef, $name . "_timer");
    delete $modules{FS10}{ldata}{$name};
  }

  my $newState="";
  my $onTime = AttrVal($name, "follow-on-timer", undef);

  ####################################
  # following timers
  if($setstate eq "on" && $onTime) {
    $newState = "off";
    $val = $onTime;
    my $to = sprintf("%02d:%02d:%02d", $val/3600, ($val%3600)/60, $val%60);
    $modules{FS10}{ldata}{$name} = $to;
    Log 4, "Follow: +$to setstate $name $newState";
    CommandDefine(undef, $name."_timer at +$to ".
    "setstate $name $newState; trigger $name $newState");
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

  my $u = "wrong syntax: define <name> FS10 housecode_addr";

  return $u if(int(@a) < 3);
  
  my $housecode = substr($a[2], 0, 1);
  my $btncode = substr($a[2], 2, 2);
  
  #return "Define $a[0]: wrong housecode format: specify a 1 digit value [0-7]"
  #		if( $a[2] !~ m/^[0-7]$/i ); # U, Hauscode
  #		#if( $a[2] !~ m/^[a-f0-9]{3}$/i ); # 

  #return "Define $a[0]: wrong btn format: specify a 2 digit hex value " .
  #       "or a 4 digit quad value"
  #		if( $a[3] !~ m/^[a-f0-9]{2}$/i ); # Ebene Low, Ebene High

  $hash->{XMIT} = $housecode;
  $hash->{BTN}  = $btncode;

  #my $name = $a[0];
  $hash->{CODE} = $a[2];
  #$hash->{lastMSG} =  "";
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
  my $name = $iohash->{NAME};
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
  my $cde;
  
  my $hlen = length($rawData);
  my $blen = $hlen * 4;
  $protocol=~ s/^[P](\d+)/$1/; # extract protocol
  my $bitData = unpack("B$blen", pack("H$hlen", $rawData));

  Log3 $name, 4, "FS10_Parse: Protocol: $protocol, rawData: $rawData";
  Log3 $name, 3, "FS10_Parse: rawBitData: $bitData ($blen)";
  
  my $datastart = 0;
  $datastart = index($bitData, "0000001");
  return "" if ($datastart < 0 || $datastart > 10);
  
  $bitData = substr($bitData, $datastart+6);
  my $blen = length($bitData);
  
  Log3 $name, 4, "FS10_Parse: datastart: $datastart, blen: $blen bitData=$bitData ($blen)";
  return "" if ($blen < 30);
  
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
    Log3 $name, 3, "FS10_Parse: error ### sum=$sum rsum=$rsum bitData=$bitData";
    return "";
  }
  if ($gesErr > 0) {
    Log3 $name, 3, "FS10_Parse: $gesErr errors ### bitData=$bitData";
    return "";
  }
  
  $dev++;
  my $v = $codes{$cde};
  $v = "unknown_$cde" if(!defined($v));
  my $btn = $ebenel . $ebeneh;
  my $deviceCode = $dev . "_" . $btn;
  
  Log3 $name, 3, "FS10_Parse: cde=$cde $v ebeneLH=$btn u=$u hc=$dev rsum=$rsum";
  
  my $def = $modules{FS10}{defptr}{$iohash->{NAME} . "." . $deviceCode};
  $def = $modules{FS10}{defptr}{$deviceCode} if(!$def);

  if(!$def) {
    Log3 $name, 3, "FS10_Parse: Unknown device $dev, " . "Button $btn Code $cde ($v), please define it";
    return "UNDEFINED FS10_$deviceCode FS10 $deviceCode";
  }
  
  my $hash = $def;
  $name = $hash->{NAME};
  return "" if(IsIgnored($name));
  Log3 $name, 3, "FS10_Parse: $name $v";
  
  my $dur = 0;
  #$v .= " $dur" if($dur);
  
   my $newState = "";
   if ($v eq "on" && (my $d = AttrVal($name, "follow-on-timer", undef))) {
      $dur = $d;
      $newState = "off";
      my $to = sprintf("%02d:%02d:%02d", $dur/3600, ($dur%3600)/60, $dur%60);
      Log3 $name, 3, "Set_Follow: +$to setstate $newState";
      CommandDefine(undef, $name."_timer at +$to "."setstate $name $newState; trigger $name $newState");
      $modules{FS10}{ldata}{$name} = $to;
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
=item summary    devices communicating via the ELV FS10 protocol
=item summary_DE Anbindung von FS10 Ger&auml;ten
=begin html_DE
<a name="FS10"></a>
<h3>FS10</h3>
Das FS10-Modul entschl&uuml;sselt und sendet Nachrichten vom Typ FS10, die vom
SIGNALduino oder CUL verarbeitet werden. Unterst&uuml;tzt werden z.Z. folgende Ger&auml;te:
 FS10-S8, FS10-S4, FS10-ZE, FS10-ST die Wetterstation WS3000-TV.<br>
<br>
<a name="FS10define"></a>
<b>Define</b>
<ul>
	<p><code>define &lt;name&gt; FS10_&lt;hauscode&gt;_&lt;button&gt;</code>
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
	<code>set &lt;name&gt; &lt;value&gt;;</code>
	<br /><br />
	<code>&lt;value&gt;</code> kann einer der folgenden Werte sein:
	<ul>
		on<br />
		off
	</ul>
</ul>
<a name="FS10get"></a>
<b>Get</b>
<ul>
	N/A
</ul>
<a name="FS10attr"></a>
<b>Attribute</b>
<ul>
	<li><a href="#do_not_notify">do_not_notify</a></li>
	<li><a href="#eventMap">eventMap</a></li>
	<li><a href="#ignore">ignore</a></li>
	<li><a href="#model">model</a> (fs10di, fs10s4, fs10s8, fs10st)</li>
	<li><a href="#readingFnAttributes">readingFnAttributes</a></li>
</ul>
=end html_DE
=cut
