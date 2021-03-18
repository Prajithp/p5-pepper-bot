package Pepper::Service::Message;

use Moose;
use namespace::autoclean;

use constant URL => 'https://chat.googleapis.com/v1';

has text => (
    is       => 'rw',
    isa      => 'Str',
    required => 1
);

has raw_text => (
    is       => 'rw',
    isa      => 'Str',
    required => 1
);

has sender => (
    is       => 'rw',
    isa      => 'Str',
    required => 1
);

has request => (
    is       => 'ro',
    isa      => 'Pepper::Service::Request',
    required => 1
);

has space_id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has thread_id => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_thread_id'
);

sub text_reply {
    my ( $self, $message ) = @_;
    return $self->reply({
        "text" => sprintf("```%s```", $message)
    });
}

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
