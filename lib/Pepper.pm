package Pepper;

use Moose;
use namespace::autoclean;

use feature "switch";

use Pepper::Bot;
use Pepper::Service::Request;
use Pepper::Service::Message;
use Pepper::Registry;

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

has message => (
    is      => 'rw',
    isa     => 'Pepper::Service::Message',
    lazy    => 1,
    builder => '_build_message',
);

sub BUILD {
    my $registry = Pepper::Registry->new( bot => $_[0]->bot );
    $registry->load_plugins;
}

sub _build_message {
    return Pepper::Service::Message->new(
        request => $_[0]->request,
        log     => $_[0]->log
    );
}

sub process {
    my ( $self, $message) = @_;

    my $event = $self->message->parse($message);

    $self->log->info("Processing message event");

    given ($event->type) {
        when ('MESSAGE') {
            my $r =  $self->_on_message($event);
            $self->log->info("Sending message response");
            $event->reply($r);
        }
        when ('ADDED_TO_SPACE') {
            $self->log->info("Bot added to space");
        }
        when ('REMOVED_FROM_SPACE') {
            $self->log->info("Bot removed from space");
        }
        default { 
	    $self->log->info("Unknown event received from bot");
        }  
    }

}

sub _on_message {
    my ($self, $event) = @_;

    my $text = $event->text;

    $self->bot->context($event->context) if defined $event->context;
    my $r = $self->bot->process($text);

    unless (defined $r) {
       $r = "There's no response from bot processor";
    }
    if (ref $r eq 'HASH') {
        return $r;
    }

    return { text => $r };
}

1;
