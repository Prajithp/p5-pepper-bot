package Pepper;

use feature qw<say>;
use Moose;
use namespace::autoclean;

use Pepper::Bot;
use Pepper::Service::Request;
use Pepper::Service::Message;
use Pepper::Registry;
use Pepper::Util;
use Data::Dumper;
use Syntax::Keyword::Try;


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
    my ( $self, $message) = @_;

    return unless $message;

    my $raw_text = Pepper::Util::trim($message->{'argumentText'});
    
    my $text    = $raw_text;
    my $context = ""; 

    if ($raw_text =~ m/^!([a-zA-Z]+)\s+([a-zA-Z\s\-_+0-9]+)/) {
        $context = $1;
        $text    = $2;
    }

    my $space     = $message->{'space'}->{'name'};
    my $space_id  = (split(/\//, $space))[-1];
    my $thread    = $message->{'thread'}->{'name'};
    my $thread_id = (split(/\//, $thread))[-1];

    my $log = $self->log->context(sprintf("[%s:%s]", $space_id, $thread_id));

    $log->info("Setting context to $context");
    $self->bot->context($context) if defined $context;

    try {    
        $log->info("Processing incomming message");
        my $message = Pepper::Service::Message->new(
            log       => $self->log,
            text      => $text, 
            raw_text  => $raw_text,
            sender    => $message->{'space'}->{'name'},
            space_id  => $space_id,
            thread_id => $thread_id,
            request   => $self->request,
        );

        my $r = $self->bot->process($text) or do {
            $log->info("There's no response from bot processor");
            return $message->reply({text => "There's no response from bot processor"});
        };

        $log->info("Sending response");
        if (ref $r eq 'HASH') {
            $message->reply($r);
        }
        $message->reply({text => $r});
        
    } catch {
        my $e = $@;
        $log->info("Failed to process message: " . $e);
    }
}

1;
