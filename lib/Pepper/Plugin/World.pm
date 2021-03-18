package Pepper::Plugin::World;

use Pepper::Plugin;
use Data::Dumper;

register 'test' => {
    pattern    => qr{what is (\d+) ([+-/*]) (\d+)},
    transforms => [ [ "what's", "what is" ] ],
    context    => 'kalc',
    handler    => sub {
        my ( $context, $param ) = @_;

        my ( $n1, $op, $n2 ) =
          ( $param->{':1'}, $param->{':2'}, $param->{':3'} );
        my $r = $n1 * $n2;

        $context->reply({"text" => "$r"});
        return 1;
    }
};

1;
