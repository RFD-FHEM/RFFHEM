use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is bag check array like unlike U};
use Test2::Mock;

our %defs;
our %attr;

InternalTimer(time()+1, sub {
	my $target = shift;
	my $targetHash = $defs{$target};
	my $mock = Test2::Mock->new(
		track => 1,
		class => 'main'
	);	 	
	my $tracking = $mock->sub_tracking;

    plan(6);
    subtest 'check error returns' => sub {
        my @p=();
        plan(5);

        CommandAttr(undef,"-r $target hardware");
        like(SIGNALduino_Set_flash($targetHash,@p), qr/Please define your hardware! \(attr/,'Verify error without hardware');
        
        CommandAttr(undef,qq[$target hardware]);
        like(SIGNALduino_Set_flash($targetHash,@p), qr/Please define your hardware! \(attr/,'Verify error without hardware');

        CommandAttr(undef,"$target hardware nano328");
        like(SIGNALduino_Set_flash($targetHash,@p), qr/ERROR: argument failed! flash \[hexFile\|url\]/,'Verify error without parameter');

        CommandAttr(undef,"$target hardware nano328");
        like(SIGNALduino_Set_flash($targetHash,undef), qr/ERROR: argument failed! flash \[hexFile\|url\]/,'Verify error without parameter');

        CommandAttr(undef,"$target hardware nano328");
        like(SIGNALduino_Set_flash($targetHash,'flash'), qr/ERROR: argument failed! flash \[hexFile\|url\]/,'Verify error without enough parameter');
    };

    subtest 'check hardware without avrdude support' => sub {
        plan(4);
        for my $hardware (qw/ESP32 ESP8266 MAPLEMINI_F103CB MAPLEMINI_F103CBcc1101/)
        {
            CommandAttr(undef,"$target hardware $hardware");
            my $ret = SIGNALduino_Set_flash($targetHash, 'flash', './fhem/test.hex');
            is($ret, "Sorry, Flashing your $hardware via Module is currently not supported.", "check return value for $hardware");
        }
    };

    subtest 'verify SIGNALduino_PrepareFlash is called correctly' => sub {
        plan(4);
        $mock->override('SIGNALduino_PrepareFlash');
        for my $hardware (qw/nanocc1101 nano328 promini radinocc1101/)
        {
            subtest $hardware => sub {
                plan(3);
                $mock->clear_sub_tracking();
                CommandAttr(undef,"$target hardware $hardware");
                my $ret = SIGNALduino_Set_flash($targetHash, 'flash', './fhem/test.hex');
                is(scalar @{$tracking->{SIGNALduino_PrepareFlash}},1,'SIGNALduino_PrepareFlash called');
                is( $tracking->{SIGNALduino_PrepareFlash}[0]{args}[1], './fhem/test.hex', "check correct hexfilename" );
                is($ret, U(), "check return value for $hardware");
            }
        }
        $mock->restore('SIGNALduino_PrepareFlash');
    };

    subtest 'verify SIGNALduino_PrepareFlash is called for not existing version' => sub {
        plan(3);
        my $hardware = 'nanocc1101';
        $targetHash->{additionalSets}{flash} = '3.4.1,4.2.1';
        $mock->clear_sub_tracking();

        $mock->override('SIGNALduino_PrepareFlash');
        CommandAttr(undef, "$target hardware $hardware");

        my $ret = SIGNALduino_Set_flash($targetHash, 'flash', '3.4');
        is($ret, U(), "check return value for $hardware");

        is(scalar @{$tracking->{SIGNALduino_PrepareFlash}},1,'SIGNALduino_PrepareFlash called');
        is( $tracking->{SIGNALduino_PrepareFlash}[0]{args}[1], '3.4', "check provided hexfilename" );

        $mock->restore('SIGNALduino_PrepareFlash');
    };

    subtest 'verify HttpUtils_NonblockingGet is called for existing version' => sub {
        plan(3);
        my $hardware = 'nanocc1101';
        $targetHash->{additionalSets}{flash} = '3.4.1,4.2.1,3,2,3';
        $mock->clear_sub_tracking();

        $mock->override('HttpUtils_NonblockingGet');
        CommandAttr(undef, "$target hardware $hardware");

        my $ret = SIGNALduino_Set_flash($targetHash, 'flash', '4.2.1');
        is($ret, U(), "check return value for $hardware");

        is(scalar @{$tracking->{HttpUtils_NonblockingGet}},1,'HttpUtils_NonblockingGet called');
        is( $tracking->{HttpUtils_NonblockingGet}[0]{args}[0], 
            hash { 
                    field command => 'getReleaseByTag'; 
                    field url => 'https://api.github.com/repos/RFD-FHEM/SIGNALDuino/releases/tags/4.2.1';
                    etc(); 
                } , 'verify provided hashref' );

        $mock->restore('HttpUtils_NonblockingGet');
    };


    subtest 'verify HttpUtils_NonblockingGet is called to download firmware' => sub {
        plan(3);
        my $hardware = 'nanocc1101';
        my $url="https://github.com/RFD-FHEM/SIGNALDuino/releases/download/3.4.0/SIGNALDuino_nanocc11013.4.0.hex";
        $mock->override('HttpUtils_NonblockingGet');
        CommandAttr(undef, "$target hardware $hardware");
        $mock->clear_sub_tracking();

        my $ret = SIGNALduino_Set_flash($targetHash, 'flash', $url);
        is($ret, U(), "check return value for $hardware");

        is(scalar @{$tracking->{HttpUtils_NonblockingGet}},1,'HttpUtils_NonblockingGet called');
        is( $tracking->{HttpUtils_NonblockingGet}[0]{args}[0], 
            hash { 
                    field command => 'flash'; 
                    field url => $url;
                    etc(); 
                } , 'verify provided hashref' );
        $mock->restore('HttpUtils_NonblockingGet');
    };
	exit(0);
},'dummyDuino');

1;
