use strict;
use warnings;
use Test::More;

use FixMyStreet::TestMech;

my $mech = FixMyStreet::TestMech->new;

$mech->get_ok('/contact');
$mech->title_like(qr/Contact Us/);
$mech->content_contains("We'd love to hear what you think about this site");

for my $test (
    {
        name      => 'A User',
        email     => 'problem_report_test@example.com',
        title     => 'Some problem or other',
        detail    => 'More detail on the problem',
        postcode  => 'EH99 1SP',
        confirmed => '2011-05-04 10:44:28.145168',
        anonymous => 0,
        meta      => 'Reported by A User at 10:44, Wednesday  4 May 2011',
    },
    {
        name      => 'A User',
        email     => 'problem_report_test@example.com',
        title     => 'A different problem',
        detail    => 'More detail on the different problem',
        postcode  => 'EH99 1SP',
        confirmed => '2011-05-03 13:24:28.145168',
        anonymous => 1,
        meta      => 'Reported anonymously at 13:24, Tuesday  3 May 2011',
    },
  )
{
    subtest 'check reporting a problem displays correctly' => sub {
        my $user = FixMyStreet::App->model('DB::User')->find_or_create(
            {
                name  => $test->{name},
                email => $test->{email}
            }
        );

        my $problem = FixMyStreet::App->model('DB::Problem')->create(
            {
                title     => $test->{title},
                detail    => $test->{detail},
                postcode  => $test->{postcode},
                confirmed => $test->{confirmed},
                name      => $test->{name},
                anonymous => $test->{anonymous},
                state     => 'confirmed',
                user      => $user,
                latitude  => 0,
                longitude => 0,
                areas     => 0,
                used_map  => 0,
            }
        );

        ok $problem, 'succesfully create a problem';

        $mech->get_ok( '/contact?id=' . $problem->id );
        $mech->content_contains('reporting the following problem');
        $mech->content_contains( $test->{title} );
        $mech->content_contains( $test->{meta} );

        $problem->delete;
    };
}

for my $test (
    {
        fields => {
            em      => ' ',
            name    => '',
            subject => '',
            message => '',
        },
        errors => [
            'Please give your name',
            'Please give your email',
            'Please give a subject',
            'Please write a message',
        ]
    },
    {
        fields => {
            em      => 'invalidemail',
            name    => '',
            subject => '',
            message => '',
        },
        errors => [
            'Please give your name',
            'Please give a valid email address',
            'Please give a subject',
            'Please write a message',
        ]
    },
    {
        fields => {
            em      => 'test@example.com',
            name    => 'A name',
            subject => '',
            message => '',
        },
        errors => [ 'Please give a subject', 'Please write a message', ]
    },
    {
        fields => {
            em      => 'test@example.com',
            name    => 'A name',
            subject => 'A subject',
            message => '',
        },
        errors => [ 'Please write a message', ]
    },
    {
        fields => {
            em      => 'test@example.com',
            name    => 'A name',
            subject => '  ',
            message => '',
        },
        errors => [ 'Please give a subject', 'Please write a message', ]
    },
    {
        fields => {
            em      => 'test@example.com',
            name    => 'A name',
            subject => 'A subject',
            message => ' ',
        },
        errors => [ 'Please write a message', ]
    },

  )
{
    subtest 'check submit page error handling' => sub {
        $mech->get_ok('/contact');
        $mech->submit_form_ok( { with_fields => $test->{fields} } );
        is_deeply $mech->form_errors,         $test->{errors};
        is_deeply $mech->visible_form_values, $test->{fields};
    };
}

for my $test (
    {
        fields => {
            em      => 'test@example.com',
            name    => 'A name',
            subject => 'A subject',
            message => 'A message',
        },
    },

  )
{
    subtest 'check email sent correctly' => sub {
        $mech->get_ok('/contact');
        $mech->submit_form_ok( { with_fields => $test->{fields} } );
        $mech->content_contains('Thanks for your feedback');
    };
}
done_testing();
