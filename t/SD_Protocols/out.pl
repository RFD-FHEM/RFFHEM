use Data::Dumper;

#my %protocols;
require "test_loadprotohash-ok.pm";
$Data::Dumper::Purity = 1;
$Data::Dumper::Deparse = 1;

my $d = Data::Dumper->new([\%lib::SD_ProtocolData::protocols], [qw(*protocols)]);
$d->Seen({ '*lib::SD_Protocols::Not_Existing_Sub' => \&lib::SD_Protocols::Not_Existing_Sub });

#print  Data::Dumper->Dump([protocols], [%protocols]);

#print $d->Dump;




use B;
sub codename {
    my $coderef = shift;
    return unless ref $coderef eq 'CODE';
    my $cv = B::svref_2object($coderef);
    return $cv->GV->NAME;
}


use JSON::Create 'create_json';
my $jc = JSON::Create->new ();
# Let's validate the output of the subroutine below.
#$jc->validate (1);
$jc->escape_slash (1);
$jc->replace_bad_utf8 (1);

# Try this one weird old trick to convert your Perl type.
$jc->type_handler (
    sub {
        my ($thing) = @_;
        my $value;
        my $type = ref ($thing);
        if ($type eq 'CODE') {
	        $value= '"\\\&'.codename($thing).'"';
        }
        else {
            $value = "$thing";
        }
        return create_json ({ type => $type, value => $value, });
        
    }
);
print $jc->run (\%lib::SD_ProtocolData::protocols)."\n";
