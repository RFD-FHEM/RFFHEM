use strict;
use warnings;
use File::Find;
use POSIX;
use File::Basename;
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
                my $date_time = POSIX::strftime("%Y_%d_%m_%H:%M:%S", localtime( $fi->{mtime} ));
                
                #test if firmware
                
                if (1==2 && $file =~ m/.*.pm$/)
				{
					open my $in_fh, '<', $file
						or die "Cannot open $file for reading: $!";

				
					open my $out_fh, '>', "$file.tmp"
				  		or die "Cannot open $file.tmp for writing: $!";
				   
				   	#print {$out_fh} $_ while ($_ !~ m/# Id:/ && <$in_fh>); # sysread/syswrite is probably better
					my $modifiy_line=undef;
					while(<$in_fh>)
					{
					   if ($_ =~ m/^# \$Id: .*\$$/){
					   	 $modifiy_line = $_; 
					   	 last;	
					   }
					   print $out_fh $_;
					}
					
					if ($modifiy_line) {
							
						print ("changing $modifiy_line");
	
					    my $date = POSIX::strftime("%Y-%d-%m", localtime( $fi->{mtime} ));
	                	my $time = POSIX::strftime("%H:%M:%S", localtime( $fi->{mtime} ));
					
						my @line_parts = split (" ",$modifiy_line);
						@line_parts[2] = fileparse($file,"");
						@line_parts[3] = $fi->{size};
						@line_parts[4] = $date;
						@line_parts[5] = $time;
							
						$modifiy_line = join(" ",@line_parts)."\n";				
						print (" to $modifiy_line\n");
						print {$out_fh} $modifiy_line;
						print {$out_fh} $_ while <$in_fh>; # sysread/syswrite is probably better
					
					}
					close $in_fh;
					close $out_fh;
				
					# overwrite original with modified copy
					rename "$file.tmp", $file
					  or warn "Failed to move $file.tmp to $file: $!";
				}       
	            $fi = file_info($file);
	              
                if ( $file =~ /(firmware|\.hex|\.HEX)/ ){
#                    print "$file is a firmware\n";
                    push @lines, sprintf("DEL %s\n", $fi->{path});
                }
                push @lines, sprintf("UPD %s %-7s %s\n", $date_time, $fi->{size}, $fi->{path});
            }
        }
        push @lines, "DEL FHEM/14_Cresta.pm\n";
        push @lines, "DEL FHEM/14_SIGNALduino_AS.pm\n";
        push @lines, "DEL FHEM/14_SIGNALduino_un.pm\n";
        push @lines, "DEL FHEM/14_SIGNALduino_ID7.pm\n";
        push @lines, "DEL FHEM/14_SIGNALduino_RSL.pm\n";

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
