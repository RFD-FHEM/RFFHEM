use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Mock;

# Mocking dependencies before loading the module
my $mock_logger = mock 'FHEM::Devices::SIGNALduino::SD_Logger' => (
    add => [
        Log => sub { return 1; }
    ]
);

# Pre-declare the package so require doesn't fail if file missing or just to satisfy perl
$INC{'FHEM/Devices/SD/Logger.pm'} = 1;
$INC{'FHEM/Devices/SD/Clients.pm'} = 1;

my $mock_clients = mock 'FHEM::Devices::SIGNALduino::SD_Clients' => (
    add => [
        getClientsasStr => sub { return ':IT:OREGON:'; }
    ]
);

# Load the module
require FHEM::Devices::SIGNALduino::SD_Matchlist;

subtest 'getMatchListasRef' => sub {
    plan(4);
    my $matchlist = FHEM::Devices::SIGNALduino::SD_Matchlist::getMatchListasRef();
    
    is(ref($matchlist), 'HASH', 'Returns a hash reference');
    ok(exists $matchlist->{'1:IT'}, 'Contains IT entry');
    ok(exists $matchlist->{'4:OREGON'}, 'Contains OREGON entry');
    is($matchlist->{'1:IT'}, '^i......', 'IT pattern matches');
};

subtest 'UpdateMatchList' => sub {
    plan(6);

    my $hash = { NAME => 'TestDevice' };
    
    # Test with valid hashref
    my $user_list = { '99:Test' => '^test' };
    FHEM::Devices::SIGNALduino::SD_Matchlist::UpdateMatchList($hash, $user_list);
    
    ok(exists $hash->{MatchList}->{'99:Test'}, 'User entry added');
    is($hash->{MatchList}->{'99:Test'}, '^test', 'User pattern matches');
    ok(exists $hash->{MatchList}->{'1:IT'}, 'Default entries still present');

    # Test with invalid input
    $hash = { NAME => 'TestDevice' };
    my $log_called = 0;
    $mock_logger->override(
        Log => sub { 
            my ($h, $level, $msg) = @_;
            $log_called = 1 if $msg =~ /not a HASH/;
        }
    );
    
    FHEM::Devices::SIGNALduino::SD_Matchlist::UpdateMatchList($hash, 'invalid');
    
    is(ref($hash->{MatchList}), 'HASH', 'MatchList set to defaults on invalid input');
    ok(exists $hash->{MatchList}->{'1:IT'}, 'Default entries present');
    ok($log_called, 'Warning logged for invalid input');
    
    # Restore mock
    $mock_logger->override(Log => sub { return 1; });
};

subtest 'UpdateFromClients' => sub {
    plan(5);
    my $hash = { NAME => 'TestDevice' };
    
    # Mock Clients to return specific list
    $mock_clients->override(
        getClientsasStr => sub { return ':IT:OREGON:UnknownClient:'; }
    );
    
    FHEM::Devices::SIGNALduino::SD_Matchlist::UpdateFromClients($hash);
    
    my $ml = $hash->{MatchList};
    ok(exists $ml->{'1:IT'}, 'IT client included');
    ok(exists $ml->{'4:OREGON'}, 'OREGON client included');
    ok(!exists $ml->{'2:CUL_TCM97001'}, 'CUL_TCM97001 client excluded');
    
    # Test with additional Clients in hash
    $hash->{Clients} = 'CUL_TCM97001';
    FHEM::Devices::SIGNALduino::SD_Matchlist::UpdateFromClients($hash);
    
    $ml = $hash->{MatchList};
    ok(exists $ml->{'2:CUL_TCM97001'}, 'Additional client from hash included');
    
    # Test with non-hash input
    my $res = FHEM::Devices::SIGNALduino::SD_Matchlist::UpdateFromClients('not a hash');
    is($res, undef, 'Returns undef/empty for non-hash input');
};

done_testing;
