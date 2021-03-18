package Pepper::Service::Request;

use Moose;
use Mojo::UserAgent;
use Mojo::JWT::Google;
use namespace::autoclean;

has file => (
    is       => 'rw',
    isa      => 'Str',
    required => 1
);

has scopes => (
    is       => 'rw',
    isa      => 'ArrayRef',
    required => 1
);

has ua => (
    is      => 'ro',
    isa     => 'Mojo::UserAgent',
    lazy    => 1,
    default => sub { Mojo::UserAgent->new; }
);

has expiration => (
    is      => 'rw',
    isa     => 'Int',
    default => sub { 0 },
    lazy    => 1
);

has _token => (
    is  => 'rw',
    isa => 'HashRef',
);

sub authorize {
    my $self = shift;

    return $self->_token if $self->expiration - 240 >= time;

    my $jwt = Mojo::JWT::Google->new(
        from_json => $self->file,
        scopes    => $self->scopes
    );

    my $tx = $self->ua->post( 'https://oauth2.googleapis.com/token',
        form => $jwt->as_form_data );
    die scalar $tx->error if $tx->error;

    my $token_res = $tx->res->json;
    my $expire    = delete $token_res->{'expires_in'};

    $self->expiration( time + $expire );
    $self->_token($token_res);

    return $token_res;
}

sub access_token {
    my $token = $_[0]->authorize;
    return $token->{'access_token'};
}

sub build_tx {
    my ( $self, %args ) = @_;

    my $method = $args{'method'};
    my $url    = $args{'url'};
    my $ua     = $self->ua;

    my @content = ref $args{'json'} eq 'HASH' ? ( json => $args{'json'} ) : ();
    my $header  = { 'Authorization' => 'Bearer ' . $self->access_token };
    my $tx      = $ua->build_tx( $method, $url, $header, @content );

    return $tx;
}

sub dispatch {
    my ( $self, $tx ) = @_;

    my $r = $self->ua->start($tx);
    if ( my $e = $r->error ) {
        die $e->{'message'} || 'Unknown error';
    }

    return $r->res->json;
}

1;
