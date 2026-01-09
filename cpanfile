# cpanfile
requires 'Test2::Suite';
requires 'JSON';
requires 'Device::SerialPort';
requires 'File::Find';
requires 'File::Basename';
requires 'Mock::Sub';
requires 'Test::More';
requires 'Test::Device::SerialPort';
requires 'Devel::Cover';
requires 'Devel::Cover::Report::Clover';
requires 'Net::SSLeay';
requires 'Digest::CRC';
requires 'Math::Trig';
requires 'Storable'; 
requires 'Test::Without::Module';

feature 'devcontainer' => sub {
    requires 'Perl::LanguageServer';
    requires 'Perl::Critic';
};
