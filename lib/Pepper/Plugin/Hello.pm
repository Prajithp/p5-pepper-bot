package Pepper::Plugin::Hello;

use Pepper::Plugin;

register "print my name" => {
    pattern => qr{my name is (\w+)},
    handler => sub {
        my ( $message, $param ) = @_;
        return $message->text_reply("Hi $param->{':1'}");
    }
};

1;

