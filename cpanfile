requires 'Test2::Suite';
requires 'JSON';
requires 'Device::SerialPort';
requires 'File::Find';
requires 'File::Basename';
requires 'Mock::Sub';
requires 'Test::More';
requires 'Test::Device::SerialPort';
requires 'Devel::Cover';
requires 'Devel::Cover::Report::Coveralls';
requires 'Net::SSLeay';
requires 'Digest::CRC';
requires 'Math::Trig';
requires 'Storable'; # This is needed for unittesting because core ships an old version which doesn't allow cloning of regexp