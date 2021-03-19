package Pepper::Plugin;

use Moose;
use Moose::Exporter;
use Pepper::Registry;
use Future::AsyncAwait;

Moose::Exporter->setup_import_methods(
    with_caller => ['namespace', 'register'],
    also        => ['Moose'],
);

sub namespace {
    my ( $package, $namespace) = @_;
    Pepper::Registry->register_namespace( $package, $namespace );
}


sub register {
    my ( $package, $key, $obj ) = @_;
    Pepper::Registry->register_pattern( $package, $key, $obj );
}

1;
