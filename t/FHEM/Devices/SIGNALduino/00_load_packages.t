use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Exception qw/lives/;

# Set the FHEM environment for testing modules
BEGIN {
    # Set up @INC for local modules
    #push @INC, qw(FHEM lib);

    # Mock a missing module if necessary
    push @INC, sub {
        my ($coderef, $filename) = @_;
        return if ($filename ne 'FHEM/Core/Timer/Helper.pm');
        open my $fh, '<', \<<'EOF';
package FHEM::Core::Timer::Helper;
1
EOF
        return $fh;        
    };
};

# Test loading of the new packages
subtest "Load SD packages" => sub {
    plan(3);

    # Test SD_Utils.pm
    ok (
        lives {
            require FHEM::Devices::SIGNALduino::SD_Utils;
        },
        "SD_Utils.pm loaded successfully"
    );


    # Test SD_CC1101.pm
    ok( 
        lives { 
            require FHEM::Devices::SIGNALduino::SD_CC1101;
        
        },
        "SD_CC1101.pm loaded successfully"
    );

    # Test SD_IO.pm
    my $mock_main = Test2::Mock->new(
        class => 'main',
        add => [
            SDUINO_VERSION => { val => 4.0.0 }
        ]
    );

    ok ( 
        lives {
            require FHEM::Devices::SIGNALduino::SD_IO;
        },
        "SD_IO.pm loaded successfully"
    );
};

done_testing();
