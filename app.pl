#!/usr/bin/perl

BEGIN { unshift @INC, './lib/' };

use Mojolicious::Lite -async_await;
use Pepper;
use Syntax::Keyword::Try;

app->config(hypnotoad => {listen => ['http://*:3000'], workers => 4});


plugin 'DefaultHelpers';
plugin 'Minion' => { SQLite => 'sqlite:queue.db' };
plugin 'Minion::Admin';
plugin 'Minion::Starter' => { debug => 1, spawn => 2 };


helper 'pepper' => sub {
    state $pepper = Pepper->new(log => app->log);
};

app->minion->add_task(process_message => sub {
    my ($job, $message) = @_;
    my $r = app->pepper->process($message);

    return $job;
});

any '/handler' => async sub {
    my $self = shift;

    my $body = $self->req->json;
    my $message = $body->{'message'};

    $self->minion->enqueue(
       'process_message', [$message]
    );

    $self->render(json => {});
};

app->start;
