package Pepper::Registry;

use Moose;
use namespace::autoclean;
use MooseX::ClassAttribute;
use Module::Pluggable;
use Data::Dumper;


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

sub register_namespace {
   my ( $class, $pkg, $key ) = @_;

   my $registry = $class->registry;
   $registry->{$pkg} //= {};
   $registry->{$pkg}->{'namespace'} = $key; 
}

sub register_pattern {
    my ( $class, $pkg, $key, $param ) = @_;

    my $registry = $class->registry;
    $registry->{$pkg} //= {};
    $registry->{$pkg}->{'patterns'}->{$key} = $param;
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
        my $plugin_obj = $self->registry->{$plugin};
        
        my $patterns   = $plugin_obj->{'patterns'};
        my $context    = $plugin_obj->{'namespace'} // "";
        
        foreach my $key (keys $patterns->%*) {
            my $params     = $patterns->{$key};

            my $pattern    = $params->{'pattern'} // $key;
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
