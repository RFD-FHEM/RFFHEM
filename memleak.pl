#!/usr/bin/env perl
# Track every object including where they're created
#use Devel::Gladiator qw(walk_arena arena_ref_counts arena_table);
#use Devel::Leak::Object qw{ GLOBAL_bless };
#$Devel::Leak::Object::TRACKSOURCELINES = 1;
#use Devel::Cycle;

use strict;
use warnings;
use lib::SD_Protocols;
use List::Util qw(max min);




 
 

our %defs;

sub Debug
{
    print $_[0]."\n";
}

sub AttrVal {
    return 0;
}

sub
round($$)
{
  my($v,$n) = @_;
  return sprintf("%.${n}f",$v);
}

############################# package main
#=item SIGNALduino_PatternExists()
# This functons, needs reference to $hash, @array of values to search and %patternList where to find the matches.
#
# Will return -1 if pattern is not found or a string, containing the indexes which are in tolerance and have the smallest gap to what we searched
# =cut

# 01232323242423       while ($message =~ /$pstr/g) { $count++ }



sub SIGNALduino_PatternExists {
  my ($hash,$search,$patternList,$data) = @_;
  #my %patternList=$arg3;
  #Debug 'plist: '.Dumper($patternList) if($debug);
  #Debug 'searchlist: '.Dumper($search) if($debug);

  my $valid=1;
  my @pstr;
  my $debug = AttrVal($hash->{NAME},'debug',0);
  my $i=0;
  my $maxcol=0;

  my %plist=();
      my $maxIndexes=1;
      my @indexer;
      my @sumlist;

  foreach my $searchpattern (@{$search})    # z.B. [1, -4]
  {
      next if (exists $plist{$searchpattern});
    #my $patt_id;
    # Calculate tolernace for search
    #my $tol=abs(abs($searchpattern)>=2 ?$searchpattern*0.3:$searchpattern*1.5);
    my $tol=abs(abs($searchpattern)>3 ? abs($searchpattern)>16 ? $searchpattern*0.18 : $searchpattern*0.3 : 1);  #tol is minimum 1 or higer, depending on our searched pulselengh

    Debug "tol: looking for ($searchpattern +- $tol)" if($debug);

    my %pattern_gap ; #= {};
    # Find and store the gap of every pattern, which is in tolerance
    %pattern_gap = map { $_ => abs($patternList->{$_}-$searchpattern) } grep { abs($patternList->{$_}-$searchpattern) <= $tol} (keys %$patternList);
    if (scalar keys %pattern_gap > 0)
    {
      Debug "index => gap in tol (+- $tol) of pulse ($searchpattern) : ".Dumper(\%pattern_gap) if($debug);
      # Extract fist pattern, which is nearst to our searched value
      my @closestidx = (sort {$pattern_gap{$a} <=> $pattern_gap{$b}} keys %pattern_gap);

      my $idxstr='';
      my $r=0;
      
        $plist{$searchpattern} = [@closestidx];
        push @indexer, $searchpattern; 
        push @sumlist, [@closestidx];  
        $maxIndexes = scalar @closestidx * $maxIndexes ;      

      while (my ($item) = splice(@closestidx, 0, 1))
      {
        $pstr[$i][$r]=$item;
        $r++;
        Debug "closest pattern has index: $item" if($debug);
      }
      $valid=1;
    } else {
      # search is not found, return -1
      return -1;
      last;
    }
    $i++;
  }

use List::Util qw(reduce);

sub cartesian_product {
  reduce {
    [ map {
      my $item = $_;
      map [ @$_, $item ], @$a
    } @$b ]
  } [[]], @_
}


#print Dumper( @indexer );
#print "\n\n";

my @res = cartesian_product @sumlist;

use Data::Dumper;
my $pattern_regex;

OUTERLOOP:
for my $i (0..$#{$res[0]})
{

  ## Check if we have same patternindex for different values and skip this invalid ones
  my %count;  
  for (@{$res[0][$i]}) 
  { 
    $count{$_}++; 
    next OUTERLOOP if ($count{$_} > 1)
  };

  my @patternVariant= @{$search} ;
  for my $x (0..$#indexer)
  {
    #print "$indexer[$x]   -->>    ". $res[0][$i][$x]."\n";
    for (@patternVariant) { $_ = ($_ eq $indexer[$x]) ? $res[0][$i][$x] : $_; };
  }
  $pattern_regex = (defined $pattern_regex) ? qq[$pattern_regex|].join "",@patternVariant : join "",@patternVariant;
  #print $pattern_regex;
  #print join "",@patternVariant;
  #print "\n";
}
($$data =~ m/($pattern_regex)/) ? print $1." found\n" && return $1: return -1;

  use Data::Dumper;
  my $maxPatterns=0;
  my @regexes = ('');
  $maxPatterns = $maxIndexes;
  for my $x (0..$maxPatterns-1)  
  {
    @regexes = map {
      my $res = $_; 
      map $res.$_, map @{$plist{$_}}, (keys %plist)
  } @regexes;

  # my $p = min($x, $#elem);
  # $regexes[$x] = [@{$search}];
  print Dumper (\@regexes);

    @regexes[$x] = map { 
      my $refVal = $_;
      print Dumper  $refVal;
      map $_ eq $refVal ? 'HT' : $_,  @{$plist{$refVal}};
    } @{$regexes[$x]};
  print Dumper (\@regexes);

    #$regexes[$x] = (defined $regexes[$x]) ? $regexes[$x].$elem[$p] : $elem[$p];

  }
  
  

  # ist '[2][14][2][14][2][14]'

  # soll (212121|242424)
  
  $pattern_regex = join ("|", @regexes);

  (${$data} =~ qr/($pattern_regex)/) ? print $1."\n" : undef;


  $pattern_regex="";
  for my $i ( 0 .. $#pstr ) 
  {
    my $regexPart = join ("", @{$pstr[$i]});
    $pattern_regex.= "[".$regexPart."]";
  }

  (${$data} =~ qr/($pattern_regex)/) ? print $1."\n" : undef;
  
  my @results = ('');

  use Data::Dumper;

  Debug "elements in pstr array: ".scalar @pstr ;
  

  

    # print Dumper(\@pstr);
 
  for my $subarray (@pstr)
  {
    @results = map {my $res = $_; map $res.$_, @$subarray } @results;
    #print Dumper(\@results);
    my $numentrys = $#results;
    Debug "elements in results array: ". scalar @results ;
    if ($numentrys < 31) { next };

    for (my $p = $#results; $p > -1; $p--) {
      if (index( ${$data}, $results[$p]) == -1)
      {
        splice @results, $p, 1;
      }
    }
    #print Dumper(\@results);
  }
  
 
  foreach my $search (@results)
  {
    Debug "looking for substr $search" if($debug);
    return $search if (index( ${$data}, $search) >= 0);
  }

  return -1;

  #return ($valid ? @results : -1);  # return @pstr if $valid or -1
}

sub SIGNALduino_splitMsg {
  my $txt = shift;
  my $delim = shift;
  my @msg_parts = split(/$delim/,$txt);

  return @msg_parts;
}

############################# package main
sub SIGNALduino_Split_Message {
  my $rmsg = shift;
  my $name = shift;
  my %patternList;
  my $clockidx;
  my $syncidx;
  my $rawData;
  my $clockabs;
  my $mcbitnum;
  my $rssi;

  my @msg_parts = SIGNALduino_splitMsg($rmsg,';');      ## Split message parts by ';'
  my %ret;
  my $debug = AttrVal($name,'debug',0);

  foreach (@msg_parts)
  {
    #Debug "$name: checking msg part:( $_ )" if ($debug);

    #if ($_ =~ m/^MS/ or $_ =~ m/^MC/ or $_ =~ m/^Mc/ or $_ =~ m/^MU/)  #### Synced Message start
    if ($_ =~ m/^M./)
    {
      $ret{messagetype} = $_;
    }
    elsif ($_ =~ m/^P\d=-?\d{2,}/ or $_ =~ m/^[SL][LH]=-?\d{2,}/) #### Extract Pattern List from array
    {
       $_ =~ s/^P+//;
       $_ =~ s/^P\d//;
       my @pattern = split(/=/,$_);

      
       $patternList{$pattern[0]} = $pattern[1];
       Debug "$name: extracted  pattern @pattern \n" if ($debug);
    }
    elsif($_ =~ m/D=\d+/ or $_ =~ m/^D=[A-F0-9]+/)                #### Message from array
    {
      $_ =~ s/D=//;
      $rawData = $_ ;
      Debug "$name: extracted  data $rawData\n" if ($debug);
      $ret{rawData} = $rawData;
    }
    elsif($_ =~ m/^SP=([0-9])$/)                                     #### Sync Pulse Index
    {
      Debug "$name: extracted  syncidx $1\n" if ($debug);
      #return undef if (!defined($patternList{$syncidx}));
      $ret{syncidx} = $1;
    }
    elsif($_ =~ m/^CP=([0-9])$/)                                     #### Clock Pulse Index
    {
      Debug "$name: extracted  clockidx $1\n" if ($debug);;
      $ret{clockidx} = $1;
    }
    elsif($_ =~ m/^L=\d/)                                         #### MC bit length
    {
      (undef, $mcbitnum) = split(/=/,$_);
      Debug "$name: extracted  number of $mcbitnum bits\n" if ($debug);;
      $ret{mcbitnum} = $mcbitnum;
    }
    elsif($_ =~ m/^C=\d+/)                                        #### Message from array
    {
      $_ =~ s/C=//;
      $clockabs = $_ ;
      Debug "$name: extracted absolute clock $clockabs \n" if ($debug);
      $ret{clockabs} = $clockabs;
    }
    elsif($_ =~ m/^R=\d+/)                                        #### RSSI
    {
      $_ =~ s/R=//;
      $rssi = $_ ;
      Debug "$name: extracted RSSI $rssi \n" if ($debug);
      $ret{rssi} = $rssi;
    }  else {
      Debug "$name: unknown Message part $_" if ($debug);;
    }
    #print "$_\n";
  }
  $ret{pattern} = {%patternList};
  
  return %ret;
}

sub leak {
    my ($foo, $bar);
    $foo = \$bar;
    $bar = \$foo;

}



my $protocols= new lib::SD_Protocols( filename => './FHEM/lib/SD_ProtocolData.pm' );
my $hash;
$hash->{protocolObject} = $protocols;
$hash->{NAME} = "dummy";

my %patternListRaw;
#my $rawData = "MU;P0=-2076;P1=479;P2=-963;P3=-492;P4=-22652;D=01213121213121212131313121313131312121313131313121212121313131212131313131313131313121313121313131313131313131312131212121313121412131212121212131213121213121212131313121313131312121313131313121212121313131212131313131313131313121313121313131313131313131;CP=1;R=26;O;";
#my $rawData = "MU;P0=740;P1=-2076;P2=381;P3=-4022;P4=-604;P5=152;P6=-1280;P7=-8692;D=012123232321245621212121232123232427212323212123232326;CP=2;R=228;";

my $rawData= "MU;P0=7944;P1=-724;P2=742;P3=241;P4=-495;P5=483;P6=-248;D=01212121343434345656343434563434345634565656343434565634343434343434345634345634345634343434343434343434345634565634345656345634343456563421212121343434345656343434563434345634565656343434565634343434343434345634345634345634343434343434343434345634565634;CP=3;R=47;";

my $message_start;
for (my $id=85; $id <=111;$id++)
{
    if ( !defined $hash->{protocolObject}->getProperty($id,'clockabs')  ) { next };
    if ( !defined $hash->{protocolObject}->getProperty($id,'start')  ) { next };
    
    #my %dump1 = map { ("$_" => $_) } @{walk_arena()};
    my %msg_parts = SIGNALduino_Split_Message($rawData, $hash->{NAME});
    #my %dump2 = map { $dump1{$_} ? () : ("$_" => $_) } @{walk_arena()};
    #use Devel::Peek; Dump \%dump2;

    my $clockabs= $hash->{protocolObject}->getProperty($id,'clockabs');

    $patternListRaw{$_} = $msg_parts{pattern}{$_} for keys %{$msg_parts{pattern}};
    my %patternList = map { $_ => round($patternListRaw{$_}/$clockabs,1) } keys %patternListRaw;

    $rawData=$msg_parts{rawData};
    my $startStr=SIGNALduino_PatternExists($hash,$hash->{protocolObject}->getProperty($id,'start'),\%patternList,\$rawData );


    print qq[$startStr\n];

      $message_start = index($rawData, $startStr);
      if ( $message_start == -1)
      {
          next;
      } else {
          $rawData = substr($rawData, $message_start);
      }
    
    #%patternList=undef;
    #$rawData=undef;

  }
    # 
    # use Devel::Peek; Dump \%dump2;
  #$protocols = undef;

