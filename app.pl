#!/usr/bin/perl

BEGIN { unshift @INC, './lib/' };

use Mojolicious::Lite;
use Pepper;

helper 'dump_request' => sub {
    my ( $self, $request ) = @_;
    app->log->debug( app->dumper($request) );
};

helper 'pepper' => sub {
    state $pepper = Pepper->new(log => $_[0]->app->log);
};

any '/handler' => sub {
    my $self = shift;
    my $body = $self->req->json;

    my $message = $body->{'message'};
    my $result  = $self->pepper->process($message);
    
    my $response = {};
    if (defined $result && !ref $result) {
        $response->{'text'} = $result;
    }
    $self->render(json => $response);
};

app->start;
