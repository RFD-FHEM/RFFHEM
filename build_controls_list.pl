use strict;
use warnings;
use File::Find;
use POSIX;

main();

our @file_list=();

{ #closure to process find file
    my @results;
    sub mywanted { 
        push @results, $File::Find::name;
    }
    sub findfiles{
        @results=();
        find \&mywanted, $_[0];
        return @results;
    }
}

sub listfiles2{
    my @dirlist = shift;
    foreach my $dir (@dirlist){
        #print ("error: $dir is not a directory\n"), next unless -d;
        my @files=findfiles($dir);
        my @lines=();
        foreach my $file (@files){
            if( (-e $file) && (! -d $file) ){ #test exist and is not a dir name
                #print "$dir contains $file\n";
                my $fi = file_info($file);
                my $date = POSIX::strftime("%Y_%d_%m_%H:%M:%S", localtime( $fi->{mtime} ));
                #test if firmware
                if ( $file =~ /(firmware|\.hex|\.HEX)/ ){
#                    print "$file is a firmware\n";
                    push @lines, sprintf("DEL %s\n", $fi->{path});
                }
                push @lines, sprintf("UPD %s %-7s %s\n", $date, $fi->{size}, $fi->{path});
            }
        }
        
        open(my $fh, '>:raw', 'controls_signalduino.txt');
        
        foreach my $l (sort @lines){
            print $l;
            print $fh $l;
        }
        close $fh;
    }
}

sub main {

    listfiles2(@ARGV);
    return;
    
    my ($dir, $sortby, $order) = @ARGV;

    my @dirs_wanted=();
    push @dirs_wanted, $dir;
    find(\&wanted, @dirs_wanted);
    foreach my $fi (@file_list){
        print $fi->{path}, ' : ', $fi->{size}, ' ', $fi->{mtime}, "\n";
    }
    return;
    
    my @contents = read_dir($dir);
    my $sb       = $sortby eq 'date' ? 'mtime' : 'path';
    my @sorted   = sort { $a->{$sb} cmp $b->{$sb}  } @contents;
    @sorted      = reverse(@sorted) if $order eq 'des';

    for my $fi (@sorted){
        print $fi->{path}, ' : ', $fi->{size}, ' ', $fi->{mtime}, "\n";
    }
}

sub file_info {
    # Takes a path to a file/dir.
    # Returns hash ref containing the path plus any stat() info you need.
    my $f = shift;
    my @s = stat($f);
    return {
        path  => $f,
        size => $s[7],
        mtime => $s[9],
    };
}
