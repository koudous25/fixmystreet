use FixMyStreet::Test;
use FixMyStreet::Email;

my $secret = FixMyStreet::DB->resultset('Secret')->update({
    secret => 'abcdef123456' });

my $hash = FixMyStreet::Email::hash_from_id("report", 123);
is $hash, '8fb274c6', 'Hash generation okay';

my $token = FixMyStreet::Email::generate_verp_token("report", 123);
is $token, "report-123-8fb274c6", 'Token generation okay';

my ($type, $id) = FixMyStreet::Email::check_verp_token($token);
is $type, "report", 'Correct type from token';
is $id, 123, 'Correct ID from token';

my $verpid = FixMyStreet::Email::unique_verp_id([ "report", 123 ]);
is $verpid, 'fms-report-123-8fb274c6@example.org', 'VERP id okay';

$verpid = FixMyStreet::Email::unique_verp_id([ "report", 123 ], "example.net");
is $verpid, 'fms-report-123-8fb274c6@example.net', 'VERP id okay with custom domain';

done_testing();
