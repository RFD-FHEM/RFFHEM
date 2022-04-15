#!/usr/bin/env perl
use strict;
use warnings;

use File::Basename;

use Test2::V0;
use Test2::Tools::Compare qw{ is hash };

our %defs;

InternalTimer(time()+0.10, sub {
	my $target = shift;
	my $targetHash = $defs{$target};
    my %validationHash;

    my $windSpeed=0.3;
    my $windDirectionDegree=90;

    my $average = SD_WS09_WindDirAverage($targetHash, $windSpeed, $windDirectionDegree);
    is($average,90,q[check windDirAverage computed]);
    
    is($targetHash->{helper}{history},array { item 0 => E(); end(); },q[check one array value is saved after first call]);
    my $average = SD_WS09_WindDirAverage($targetHash, $windSpeed, $windDirectionDegree);
    is($targetHash->{helper}{history},array { item 0 => E(); end(); },q[check one array value is saved after second call <1 second]);

    is(FhemTestUtils_gotLog("Error"), 0, q[No errors in Logfile]);
    is(FhemTestUtils_gotLog("Warnig"), 0, q[No warnings in Logfile]);
    
},'WH1080');



InternalTimer(time()+0.20, sub {
	my $target = shift;
	my $targetHash = $defs{$target};
    my %validationHash;

    $targetHash->{helper}{history} = undef; 

    my $windSpeed=1;

    CommandAttr(undef,q[WH1080 WindDirAverageDecay 1]);
    my @mockvalue = ($windSpeed,1.57,FmtDateTime(CORE::time()-50)); ## 50 Seconds in the past, speed=1, 90° 
    push(@{$targetHash->{helper}{history}},\@mockvalue);
    
    my @mockvalue2 = ($windSpeed,1.57,FmtDateTime(CORE::time()-25)); ## 25 Seconds in the past, speed=1, 90° 
    push(@{$targetHash->{helper}{history}},\@mockvalue2);
	
    my $windDirectionDegree=180;
    my $average = SD_WS09_WindDirAverage($targetHash, $windSpeed, $windDirectionDegree);
    is($average,116,q[check windDirAverage computed]);
    is($targetHash->{helper}{history},array { item 0 => E(); item 1 => E(); item 2 => E(); end(); },q[check three array value are saved after second call >10 seconds]);

    is(FhemTestUtils_gotLog("Error"), 0, q[No errors in Logfile]);
    is(FhemTestUtils_gotLog("Warnig"), 0, q[No warnings in Logfile]);

    #use Data::Dumper;
    #print Dumper (\$targetHash->{helper}{history});

    done_testing();
    exit();
        
},'WH1080');
1;

