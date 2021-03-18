#!/usr/bin/perl

BEGIN { unshift @INC, './lib/' };

use Mojolicious::Lite;
use Pepper;

helper 'dump_request' => sub {
    my ( $self, $request ) = @_;
    app->log->debug( app->dumper($request) );
};

helper 'pepper' => sub {
    state $pepper = Pepper->new;
};

any '/handler' => sub {
    my $self = shift;
    my $body = $self->req->json;

    my $message = $body->{'message'};
    $self->pepper->process($message);

    $self->render(json => {});
};

app->start;
