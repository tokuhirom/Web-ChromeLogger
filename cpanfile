requires 'perl', '5.008001';
requires 'JSON::XS';
requires 'MIME::Base64';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

