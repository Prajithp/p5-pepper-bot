package Pepper::Service::Message;

use Moose;
use namespace::autoclean;

use Pepper::Service::Event;
use Pepper::Util;

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

sub parse {
    my ( $self, $payload ) = @_;

    my $space    = $payload->{'space'}->{'name'};
    my $space_id = ( split( /\//, $space ) )[-1];
    my $args     = {
        request  => $self->request,
        log      => $self->log,
        event    => $payload->{'event'},
        sender   => $payload->{'user'}->{'displayName'},
        type     => $payload->{'type'},
        space_id => $space_id
    };

    if ( my $message = $payload->{'message'} ) {
        my $text   = Pepper::Util::trim( $message->{'argumentText'} );
        my $thread = $message->{'thread'}->{'name'};

        my $context;
        if ( $text =~ m/^!([a-zA-Z]+)\s+([a-zA-Z\s\-_+0-9]+)/ ) {
            $context = $1;
            $text    = $2;
        }

        $args->{'thread_id'} = ( split( /\//, $thread ) )[-1];
        $args->{'text'}      = $text;
        $args->{'context'}   = $context // "";
    }

    my $event = Pepper::Service::Event->new($args);
    return $event;
}

1;
