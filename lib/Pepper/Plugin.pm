package Pepper::Plugin;

use Moose;
use namespace::autoclean;
use Moose::Exporter;
use Pepper::Registry;

Moose::Exporter->setup_import_methods(
    with_caller => ['register'],
    also        => ['Moose']
);

sub register {
    my ( $package, $key, $obj ) = @_;
    Pepper::Registry->add( $package, $key, $obj );
}

1;
