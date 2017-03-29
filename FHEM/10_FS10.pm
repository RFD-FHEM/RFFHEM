#####################################################################
# FS10 basierend auf dem FS20 Modul (FHEM 5.3), KlausR
#####################################################################
# modified by elektron-bbs for SIGNALduino
# tested transmitter:	FS10-S8, FS10-S4, FS10-ZE
# tested receiver:		FS10-ST, WS3000-TV, PC-Wettersensor-Empfaenger

package main;

use strict;
use warnings;

my %codes = (
  "0" => "off",
  "1" => "on",
  "2" => "off",
  "3" => "on",
  "4" => "dimdown",
  "5" => "dimup",
);

my %readonly = (
  "thermo-on" => 1,
  "thermo-off" => 1,
);

use vars qw(%fs10_c2b);		# Peter would like to access it from outside

my $fs10_simple ="off on";
my %models = (
    fs10s4      => 'sender',
    fs10s8      => 'sender',
    dummySender => 'sender',

    fs10di      => 'dimmer',
    dummyDimmer => 'dimmer',

    fs10st      => 'simple',
    dummySimple => 'simple',
);

sub FS10_Initialize($) {
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
                       "loglevel:0,1,2,3,4,5,6 " .
                       "model:".join(",", sort keys %models);
}

sub FS10_Set($@) {
	# übergeben werden max. 3 Parameter:
	# 1. Name
	# 2. on, off, dimup, dimdown
	# 3. nur bei dim 0 - 100 z.B. FS10_0111 dimdown 10
	my ($hash, @a) = @_;
	my $name = $hash->{NAME};
   my $ret = undef;
   my $na = int(@a);												# Anzahl Parameter
  
	return "no set value specified" if($na < 2 || $na > 3);
   return "Readonly value $a[1]" if(defined($readonly{$a[1]}));

	if($na > 2 && $a[1] eq "dim") {
		my $dimvalue = $a[2];
		Log3 $name, 3, "$name: $a[1] value = $dimvalue";
		$a[1] = ($a[2] eq "0" ? "off" : sprintf("dim%02d%%",$a[2]) );
		splice @a, 2, 1;
		$na = int(@a);
	}

	my $c = $fs10_c2b{$a[1]};								# Keycodes
  
	if(!defined($c)) {
		# Model specific set arguments
		if(defined($attr{$name}) && defined($attr{$name}{"model"})) {
			my $mt = $models{$attr{$name}{"model"}};
			return "Unknown argument $a[1], choose one of " if($mt && $mt eq "sender");
			return "Unknown argument $a[1], choose one of $fs10_simple" if($mt && $mt eq "simple");
		}
		return "Unknown argument $a[1], choose one of " . join(" ", sort keys %fs10_c2b) . " dim:slider,0,6.25,100";
	}
	return Do_On_Till($hash, @a) if($a[1] eq "on-till");
	return "Bad time spec" if($na == 3 && $a[2] !~ m/^\d*\.?\d+$/);

	my $v = join(" ", @a);									# z.B. FS10_0111 off
	(undef, $v) = split(" ", $v, 2);						# Not interested in the name...
	Log3 $name, 5, "$name: set $v";

	my $val;

	if($na == 3) {                                	# Timed command.
		$c = sprintf("%02X", (hex($c) | 0x20)); 		# Set the extension bit
		# Calculating the time.
		LOOP: for (my $i = 0; $i <= 12; $i++) {
			for (my $j = 0; $j <= 15; $j++) {
				$val = (2**$i)*$j*0.25;
				if($val >= $a[2]) {
					if($val != $a[2]) {
						Log GetLogLevel($name,2), "$name: changing timeout to $val from $a[2]";
					}
					$c .= sprintf("%x%x", $i, $j);
					last LOOP;
				}
			}
		}
		return "Specified timeout too large, max is 15360" if(length($c) == 2);
	}
	
	# send message SIGNALduino
	my $hc = $hash->{HC};
	my $btn = $hash->{BTN};
	my	$kc = $fs10_c2b{$a[1]};						# Keycode
	while ($kc > 1) { $kc -= 2; }					# only on or off			
	for(my $i = 1; $i <= 2; $i++) {				# Nachricht 2x senden
		my $newmsg = "P61#0000000000001";		# 12 Bit Praeambel, 1 Pruefbit
		my $sum = 0;
		my $temp = "";
		if ($i == 2) {$kc +=2}						# Nachricht 2, Taste loslassen				
		$temp = $kc;									# 1. Kommando (on/off)
		$sum += $temp;
		$newmsg .= dec2nibble($temp);		
		$temp = substr($btn, 1, 1);				# 2. Ebene low
		$sum += $temp;
		$newmsg .= dec2nibble($temp);		
		$temp = substr($btn, 0, 1);				# 3. Ebene high
		$sum += $temp;
		$newmsg .= dec2nibble($temp);		
		$newmsg .= "10001";							# 4. unused
		$temp = substr($hc, 1, 1);					# 5. Hauscode
		$sum += $temp;
		$newmsg .= dec2nibble($temp);		
		if ($sum >= 11) {								# 6. Summe
			$temp = 18 - $sum;
		} else {
			$temp = 10 - $sum;
		}
		$newmsg .= dec2nibble($temp);		
		$newmsg .= "#R1";
		IOWrite($hash, 'sendMsg', $newmsg);		# send message
		Log3 $name, 3, "$name: Send message #$i $newmsg";
		if ($i == 1) {									# nach Nachricht 1
			Log3 $name, 5, "$name: wait 200 mS";
			select(undef, undef, undef, 0.2);	# 200 mSek warten
		}
	}
  
  # Set the state of a device to off if on-for-timer is called
  if($modules{FS10}{ldata}{$name}) {
    CommandDelete(undef, $name . "_timer");
    delete $modules{FS10}{ldata}{$name};
  }
  my $newState="";
  my $onTime = AttrVal($name, "follow-on-timer", undef);

  # following timers
  if($a[1] eq "on" && $na == 2 && $onTime) {
    $newState = "off";
    $val = $onTime;
  } elsif($a[1] =~ m/(on|off).*-for-timer/ && $na == 3 && AttrVal($name, "follow-on-for-timer", undef)) {
    $newState = ($1 eq "on" ? "off" : "on");
  }

  if($newState) {
    my $to = sprintf("%02d:%02d:%02d", $val/3600, ($val%3600)/60, $val%60);
    $modules{FS10}{ldata}{$name} = $to;
    Log 4, "Follow: +$to setstate $name $newState";
    CommandDefine(undef, $name."_timer at +$to "."setstate $name $newState; trigger $name $newState");
  }

  # Look for all devices with the same code, and set state, timestamp
  my $code = "$hash->{HC} $hash->{BTN}";
  my $tn = TimeNow();
  my $defptr = $modules{FS10}{defptr};
  foreach my $n (keys %{ $defptr->{$code} }) {
    my $lh = $defptr->{$code}{$n};
    $lh->{CHANGED}[0] = $v;
    $lh->{STATE} = $v;
    $lh->{READINGS}{state}{TIME} = $tn;
    $lh->{READINGS}{state}{VAL} = $v;
    my $lhname = $lh->{NAME};
    if($name ne $lhname) {
      DoTrigger($lhname, undef)
    }
  }
  return $ret;
}

sub FS10_Define($$) {
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);

  my $u = "wrong syntax: define <name> FS10 housecode addr";

  return $u if(int(@a) < 4);
  return "Define $a[0]: wrong housecode format: specify a 2 digit hex value "
  		if( $a[2] !~ m/^[0-7]{2}$/i ); # U, Hauscode
  		#if( $a[2] !~ m/^[a-f0-9]{3}$/i ); # 

  return "Define $a[0]: wrong btn format: specify a 2 digit hex value "
  		if( $a[3] !~ m/^[0-7]{2}$/i ); # Ebene Low, Ebene High

  my $housecode = $a[2];
  #$housecode = four2hex($housecode,4) if (length($housecode) == 8);

  my $btncode = $a[3];
  #$btncode = four2hex($btncode,2) if (length($btncode) == 4);

  $hash->{HC} = lc($housecode);
  $hash->{BTN}  = lc($btncode);

  my $code = lc("$housecode $btncode");
  my $ncode = 1;
  my $name = $a[0];
  $hash->{CODE}{$ncode++} = $code;
  $modules{FS10}{defptr}{$code}{$name} = $hash;

  for(my $i = 4; $i < int(@a); $i += 2) {

    return "No address specified for $a[$i]" if($i == int(@a)-1);

    $a[$i] = lc($a[$i]);
    if($a[$i] eq "fg") {
      return "Bad fg address for $name, see the doc"
        if( ($a[$i+1] !~ m/^f[a-f0-9]$/) && ($a[$i+1] !~ m/^44[1-4][1-4]$/));
    } elsif($a[$i] eq "lm") {
      return "Bad lm address for $name, see the doc"
        if( ($a[$i+1] !~ m/^[a-f0-9]f$/) && ($a[$i+1] !~ m/^[1-4][1-4]44$/));
    } elsif($a[$i] eq "gm") {
      return "Bad gm address for $name, must be ff"
        if( ($a[$i+1] ne "ff") && ($a[$i+1] ne "4444"));
    } else {
      return $u;
    }

    my $grpcode = $a[$i+1];
    if (length($grpcode) == 4) {
       $grpcode = four2hex($grpcode,2);
    }

    $code = "$housecode $grpcode";
    $hash->{CODE}{$ncode++} = $code;
    $modules{FS10}{defptr}{$code}{$name}   = $hash;
  }
  AssignIoPort($hash);
}

sub FS10_Undef($$) {
  my ($hash, $name) = @_;

  foreach my $c (keys %{ $hash->{CODE} } ) {
    $c = $hash->{CODE}{$c};

    # As after a rename the $name my be different from the $defptr{$c}{$n}
    # we look for the hash.
    foreach my $dname (keys %{ $modules{FS10}{defptr}{$c} }) {
      delete($modules{FS10}{defptr}{$c}{$dname})
        if($modules{FS10}{defptr}{$c}{$dname} == $hash);
    }
  }
  return undef;
}

sub FS10_Parse($$) {
	# Msg format CUL: 
	# FS10CAAHHH??
	# raw format (preprocessed in CUL module):
	# p 3  400  320  400  720 12  3 5 xx CAAHHH??
	# xx = RSSI, C = command code, AA = address/button code, HHH = home/device code

   # Msg format sduino: 
   # FS10111016
	# ---|||||||_ Summe
	#    ||||||_ Hauscode
	#    |||||_ unused (0)
	#    ||||_ Ebene high
	#    |||_ Ebene low
	#    ||_ Kommand
	#    |_ Name

	my ($iohash, $msg) = @_;
	my $name = $iohash->{NAME};
	Log3 $name, 4, "FS10: received msg from $name: $msg";
	$msg = substr($msg, 4, (length($msg) - 4));			# FS10 entfernen
	my $hlen = length($msg);
	my $blen = $hlen * 4;
	my $bit_msg = unpack("B$blen", pack("H$hlen", $msg));
	Log3 $name, 5, "FS10: bitmsg: $bit_msg";
# 2017.03.25 13:22:15 3: FS10_Parse: sduino msg: FS1000118C711F0
# 2017.03.25 13:22:15 3: FS10_Parse: sduino msg: 00118C711F0
# 2017.03.25 13:22:15 3: FS10_Parse: sduino bitmsg: 000000000001000110001100011100010001111100000000000000000000
# 00000000000 1 0010 1 1011 1 0001 1 1000 1 0001 1 1011 000
# 00000000000 1 1000 1 1011 1 0001 1 1000 1 0001 1 1101 000

	my $debug = AttrVal($name,"debug",0);
	my $protolength = length($bit_msg);
	my $datastart = 0;
	my @data = ();
	my $datanr = 0;
	my $dataindex = 0;
	my $index = 0;
	my $parity = 1;		# Paritaet ungerade
	my $error = 0;
	my $sum = 0;
	my $temp = 0;

	while (substr($bit_msg,$datastart,1) == 0) { $datastart++; }	# Start bei erstem Bit mit Wert 1 suchen
	my $datalength = $protolength - $datastart;
	my $datalength1 = $datalength - ($datalength % 5);  				# modulo 5
	Debug "FS10: protolength: $protolength, datastart: $datastart, datalength $datalength" if ($debug);
	Log3 $name, 5, "FS10: protolength: $protolength, datastart: $datastart, datalength $datalength, datalength1 $datalength1";
	if ($datalength1 < 30 || $datalength1 > 35) {						# check lenght of message
		Log3 $name, 1, "FS10: ERROR lenght of message $datalength1";
		return "";
	} elsif ($datastart > 12) {												# max 12 Bit preamble
		Log3 $name, 1, "FS10: ERROR preamble > 12 ($datastart)";
		return "";
	} else {
		do {
			$error += !(substr($bit_msg,$index + $datastart,1));		# jedes 5. Bit muss 1 sein
			$dataindex = $index + $datastart + 1;				 
			$data[$datanr] = oct("0b".substr($bit_msg, $dataindex, 4));
			if ($index < 30) {
				$temp = $data[$datanr];		
				$parity = 1; 														# Paritaet ungerade
				while ($temp != 0) {
					if ($temp & 1) { $parity = 1 - $parity; }				# Paritaet ungerade
					$temp >>= 1;													# shift right
				}
				$sum += $data[$datanr] & 0x07;
			}
			$data[$datanr] = $data[$datanr] & 0x07;
			Log3 $name, 5, "FS10: received nibble $datanr = $data[$datanr]";
			$index += 5;
			$datanr += 1;
		} until ($index >= $datalength1);
	}
	if ($error != 0) {
		Log3 $name, 1, "FS10: ERROR examination bit";
		return "";
	} elsif ($parity != 0) {
		Log3 $name, 1, "FS10: ERROR parity bit";
		return "";
	} elsif (($data[3] & 0x07) != 0) {										# Nibble muss 0 sein
		Log3 $name, 1, "FS10: ERROR nibble 3 not zero";
		return "";
	} elsif ($sum != 10 && $sum != 18) {
		Log3 $name, 1, "FS10: ERROR sum";
		return "";
	} else {
	
		my $dev = $data[3].$data[4];	# U, Hauscode
		my $btn = $data[2].$data[1];	# Ebene high, Ebene low
		my $cde = $data[0];				# Command

		my $dur = 0;
		my $cx = hex($cde);

		my $v = $codes{$cde};
		$v = "unknown_$cde" if(!defined($v));
		$v .= " $dur" if($dur);

		my $def = $modules{FS10}{defptr}{"$dev $btn"};
		
		if ($def) {
			my @list;
			foreach my $n (keys %{ $def }) {
				my $lh = $def->{$n};
				$n = $lh->{NAME};        			# It may be renamed
				return "" if(IsIgnored($n));		# Little strange.
				$lh->{CHANGED}[0] = $v;
				$lh->{STATE} = $v;
				$lh->{READINGS}{state}{TIME} = TimeNow();
				$lh->{READINGS}{state}{VAL} = $v;
				Log3 $name, 4, "FS10: received command $n $v";		# FS10_0111 on
				if($modules{FS10}{ldata}{$n}) {
					CommandDelete(undef, $n . "_timer");
					delete $modules{FS10}{ldata}{$n};
				}
				my $newState = "";
				if ($v =~ m/(on|off).*-for-timer/ && $dur && AttrVal($n, "follow-on-for-timer", undef)) {
					$newState = ($1 eq "on" ? "off" : "on");
				} elsif ($v eq "on" && (my $d = AttrVal($n, "follow-on-timer", undef))) {
					$dur = $d;
					$newState = "off";
				}
				if ($newState) {
					my $to = sprintf("%02d:%02d:%02d", $dur/3600, ($dur%3600)/60, $dur%60);
					Log3 $name, 4, "Follow: +$to setstate $n $newState";
					CommandDefine(undef, $n."_timer at +$to "."setstate $n $newState; trigger $n $newState");
					$modules{FS10}{ldata}{$n} = $to;
				}
				push(@list, $n);
			}
		return @list;
		} else {
			# Special FHZ initialization parameter. In Multi-FHZ-Mode we receive
			# it by the second FHZ
			return "" if($dev eq "0001" && $btn eq "00" && $cde eq "00");
			Log3 $name, 1, "FS10: Unknown device $dev, " . "Button $btn Code $cde ($v), please define it";
			return "UNDEFINED FS10_$dev$btn FS10 $dev $btn";
		}
	}
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

=item device 
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
	<p><code>define &lt;name&gt; FS10 &lt;hauscode&gt; &lt;button&gt;</code>
	<br>
	<br>
	<code>&lt;name&gt;</code> ist ein beliebiger Name, der dem Ger&auml;t zugewiesen wird.
	 Zur besseren &Uuml;bersicht wird empfohlen einen Namen in der Form &quot; FS10_0612&quot; zu verwenden,
	  wobei &quot;06&quot; der verwendete Hauscode und &quot;12&quot; die Adresse darstellt.
	<br /><br />
	<code>&lt;hauscode&gt;</code> entspricht dem Hauscode der verwendeten Fernbedienung bzw. des Ger&auml;tes, das gesteuert werden soll. Entgegen den Original wird hier der Hauscode 00-07 verwendet. Ein hier z.B. eingestellter Hauscode von &quot;01&quot; entspricht dem Original-Hauscode &quot;2&quot;.
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