package Pepper;

use feature qw<say>;
use Moose;
use namespace::autoclean;

use Pepper::Bot;
use Pepper::Service::Request;
use Pepper::Service::Message;
use Pepper::Registry;
use Pepper::Util;


has bot => (
    is      => 'rw',
    isa     => 'Pepper::Bot',
    default => sub { Pepper::Bot->new },
    lazy    => 1
);

has request => (
    is      => 'rw',
    isa     => 'Pepper::Service::Request',
    default => sub {
        Pepper::Service::Request->new(
            file   => $ENV{'SERVICE_ACCOUNT_FILE'},
            scopes => ['https://www.googleapis.com/auth/chat.bot']
        );
    },
    lazy => 1
);

has log => (
    is       => 'rw',
    isa      => 'Mojo::Log',
    default  => sub { Mojo::Log->new },
    weak_ref => 1,
);

sub BUILD {
    my $self = shift;

    my $registry = Pepper::Registry->new( bot => $self->bot );
    $registry->load_plugins;
}

sub process {
    my ( $self, $message ) = @_;

    my $raw_text = Pepper::Util::trim($message->{'argumentText'});
    
    my $text    = $raw_text;
    my $context = ""; 

    if ($raw_text =~ m/^!([a-zA-Z]+)\s+([a-zA-Z\s\-_+0-9]+)/) {
        $context = $1;
        $text    = $2;
    }

    $self->bot->context($context) if defined $context;

    my $space     = $message->{'space'}->{'name'};
    my $space_id  = (split(/\//, $space))[-1];
    my $thread    = $message->{'thread'}->{'name'};
    my $thread_id = (split(/\//, $thread))[-1];
    
    my $message_obj = Pepper::Service::Message->new(
        log       => $self->log,
        text      => $text, 
        raw_text  => $raw_text,
        sender    => $message->{'space'}->{'name'},
        space_id  => $space_id,
        thread_id => $thread_id,
        request   => $self->request,
    );
    $self->log->info("Processing incomming message");
    return $self->bot->process($message_obj);
}

1;
