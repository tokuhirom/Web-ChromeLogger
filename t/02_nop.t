use strict;
use warnings;
use Web::ChromeLogger::NOP;

use Test::More;

my $logger = Web::ChromeLogger::NOP->new;
subtest 'Do nothing' => sub {
    ok !$logger->encode;
    ok !$logger->error;
    ok !$logger->finalize;
    ok !$logger->group;
    ok !$logger->group_collapsed;
    ok !$logger->group_end;
    ok !$logger->info;
    ok !$logger->json_encoder;
    ok !$logger->push_log;
    ok !$logger->to_json;
    ok !$logger->unshift_log;
    ok !$logger->warn;
    ok !$logger->wrap_by_group;
};

done_testing;

