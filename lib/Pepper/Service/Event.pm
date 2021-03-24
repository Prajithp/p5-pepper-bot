package Pepper::Service::Event;

use Moose;
use namespace::autoclean;

use constant URL => 'https://chat.googleapis.com/v1';

has request => (
    is       => 'ro',
    isa      => 'Pepper::Service::Request',
    required => 1,
    weak_ref => 1
);

has log => (
    is       => 'ro',
    isa      => 'Mojo::Log',
    weak_ref => 1,
    required => 1,
);

has sender => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has space_id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has type => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);  

has text => (
    is  => 'ro',
    isa => 'Str',
);

has thread_id => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_thread_id'
);

has context => (
    is  => 'ro',
    isa => 'Str|Undef',
);

sub reply {
    my ( $self, $message ) = @_;

    my $url = sprintf( "%s/spaces/%s/messages", URL, $self->space_id );
    if ( $self->has_thread_id ) {
        my $thread =
          sprintf( "spaces/%s/threads/%s", $self->space_id, $self->thread_id );
        $message->{'thread'} = { 'name' => $thread };
    }

    my $tx = $self->request->build_tx(
        method => 'POST',
        url    => $url,
        json   => $message
    );
    my $r = $self->request->dispatch($tx);

    return $r;
}

1;
