package Pepper::Registry;

use Moose;
use namespace::autoclean;
use MooseX::ClassAttribute;
use Module::Pluggable;

has bot => (
    is       => 'ro',
    isa      => 'Pepper::Bot',
    required => 1,
    weak_ref => 1
);

class_has 'registry' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { +{} }
);

sub add {
    my ( $class, $pkg, $key, $param ) = @_;

    my $registry = $class->registry;
    $registry->{$pkg}->{$key} = $param;
}

sub load_plugins {
    my $self = shift;

    Module::Pluggable->import(
        search_path => ['Pepper::Plugin'],
        instantiate => 'new',
        require     => 1,
        inner       => 0
    );

    my @plugins = $self->plugins;
    foreach my $plugin_ref (@plugins) {
        my $plugin = ref $plugin_ref;
        foreach my $reg ( keys $self->registry->{$plugin}->%* ) {
            my $params = $self->registry->{$plugin}->{$reg};

            my $pattern    = $params->{'pattern'} // $reg;
            my $context    = $params->{'context'} // "";
            my $handler    = $params->{'handler'};
            my $transforms = $params->{'transforms'} // [];

            $self->bot->context($context);
            $self->bot->pattern( $pattern, $handler );
            for my $transform ( $transforms->@* ) {
                if ( ref $transform eq 'ARRAY' ) {
                    my ( $match, $target ) = $transform->@*;
                   $self->bot->transform( $match, $target );
                }
            }
        }
    }
}

1;
