package Integrations::Echo;

use strict;
use warnings;
use Moo;
use Tie::IxHash;

has attr => ( is => 'ro', default => 'http://www.twistedfish.com/xmlns/echo/api/v1' );
has action => ( is => 'lazy', default => sub { $_[0]->attr . "/Service/" } );
has username => ( is => 'ro' );
has password => ( is => 'ro' );
has url => ( is => 'ro' );

has endpoint => (
    is => 'lazy',
    default => sub {
        my $self = shift;
        SOAP::Lite->soapversion(1.2);
        my $soap = SOAP::Lite->on_action( sub { $self->action . $_[1]; } )->proxy($self->url);
        $soap->serializer->register_ns("http://schemas.microsoft.com/2003/10/Serialization/Arrays", 'msArray'),
        return $soap;
    },
);

has security => (
    is => 'lazy',
    default => sub {
        my $self = shift;
        SOAP::Header->name("Security")->attr({
            'mustUnderstand' => 'true',
            'xmlns' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd'
        })->value(
            \SOAP::Header->name(
                "UsernameToken" => \SOAP::Header->value(
                    SOAP::Header->name('Username', $self->username),
                    SOAP::Header->name('Password', $self->password),
                )
            )
        );
    },
);

sub action_hdr {
    my ($self, $method) = @_;
    SOAP::Header->name("Action")->attr({
        'xmlns' => 'http://www.w3.org/2005/08/addressing',
    })->value(
        $self->action . $method
    );
}

sub call {
    my ($self, $method, @params) = @_;

    require SOAP::Lite;
    @params = make_soap_structure(@params);
    my $res = $self->endpoint->call(
        SOAP::Data->name($method)->attr({ xmlns => $self->attr }),
        $self->security,
        $self->action_hdr($method),
        @params
    );
    $res = $res->result;
    return $res;
}

#print $echo->GetTasks( 27345708, 7433);

sub GetTasks {
    my $self = shift;
    my $ref1 = shift;
    my $ref2 = shift;
    tie(my %obj, 'Tie::IxHash',
        Key => 'Handle',
        Type => "Task",
        Value => [
            { 'msArray:anyType' => $ref1 },
            { 'msArray:anyType' => $ref2 },
        ],
    );
    $self->call('GetTasks',
        taskRefs => {
            ObjectRef => \%obj,
        },
        options => {
            IncludePoints => 'false',
        },
    );
}

sub GetPointAddress {
    my $self = shift;
    my $uprn = shift;
    tie(my %obj, 'Tie::IxHash',
        Key => 'Uprn',
        Type => 'PointAddress',
        Value => [
            { 'msArray:anyType' => $uprn },
        ],
    );
    $self->call('GetPointAddress', ref => \%obj);
}

sub FindPoints {
    my $self = shift;
    my $pc = shift;
    tie(my %obj, 'Tie::IxHash',
        PointType => 'PointAddress',
        Postcode => $pc,
    );
    $self->call('FindPoints', query => \%obj);
}

sub GetServiceUnitsForObject {
    my $self = shift;
    my $uprn = shift;
    tie(my %obj, 'Tie::IxHash',
        Key => 'Uprn',
        Type => 'PointAddress',
        Value => [
            { 'msArray:anyType' => $uprn },
        ],
    );
    $self->call('GetServiceUnitsForObject',
        objectRef => \%obj,
        query => {
            IncludeTaskInstances => 'true',
        }
    );
}

sub make_soap_structure {
    my @out;
    for (my $i=0; $i<@_; $i+=2) {
        my $name = $_[$i] =~ /:/ ? $_[$i] : $_[$i];
        my $v = $_[$i+1];
        my $val = $v;
        my $d = SOAP::Data->name($name);
        if (ref $v eq 'HASH') {
            $val = \SOAP::Data->value(make_soap_structure(%$v));
        } elsif (ref $v eq 'ARRAY') {
            my @map = map { make_soap_structure(%$_) } @$v;
            $val = \SOAP::Data->value(SOAP::Data->name('dummy' => @map));
        } else {
            $d->type('string');
        }
        push @out, $d->value($val);
    }
    return @out;
}

1;