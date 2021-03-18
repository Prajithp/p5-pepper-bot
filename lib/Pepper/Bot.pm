package Pepper::Bot;

use strict;
use warnings;
use Data::Dumper;

use base qw( Class::Accessor );

my $singleton;

__PACKAGE__->mk_ro_accessors(qw( patterns transforms ));

sub new {
    my ($class) = shift;
    return $class->SUPER::new( { context => '', @_ } );
}

sub pattern {
    @_ = get_right_object(@_);
    my ( $self, $pattern, @rest ) = @_;

    my @patterns = ref $pattern eq 'ARRAY' ? @{$pattern} : ($pattern);
    my $code     = ref $rest[0] eq 'CODE'  ? shift @rest : undef;

    my $response = shift @rest;

    for my $pattern (@patterns) {
        push @{ $self->{patterns}{ $self->{context} } },
          {
            pattern  => $pattern,
            response => $response,
            code     => $code,
          };
    }
}

sub transform {
    @_ = get_right_object(@_);
    my ( $self, $pattern, @rest ) = @_;

    my @patterns = ref $pattern eq 'ARRAY' ? @{$pattern} : ($pattern);
    my $code     = ref $rest[0] eq 'CODE'  ? shift @rest : undef;

    my $transform_to = shift @rest;

    $self->{transforms}{ $self->{context} } //= [];
    for my $pattern (@patterns) {
        push @{ $self->{transforms}{ $self->{context} } },
          {
            pattern   => $pattern,
            transform => $transform_to,
            code      => $code,
          };
    }

}

sub match {
    @_ = get_right_object(@_);
    my ( $self, $input, $pattern ) = @_;

    # regex match
    if ( ref $pattern eq 'Regexp' ) {
        if ( $input =~ $pattern ) {
            my @matches = ( $1, $2, $3, $4, $5, $6, $7, $8, $9 );
            my $i       = 0;
            my %result  = map { ':' . ++$i => $_ } grep { defined $_ } @matches;
            return \%result;
        }
        else {
            return;
        }
    }

    # text pattern (like "my name is :name")

    # first, extract the named variables
    my @named_vars = $pattern =~ m{(:\S+)}g;

    # transform named variables to '(\S+)'
    $pattern =~ s{:\S+}{'(.*)'}ge;

    # do the pattern matching
    if ( $input =~ m/\b$pattern\b/xxs ) {
        my @matches = ( $1, $2, $3, $4, $5, $6, $7, $8, $9 );
        my %result  = map { $_ => shift @matches } @named_vars;

        # override memory with new information
        $self->{memory} = { %{ $self->{memory} // {} }, %result };

        return \%result;
    }

    return;
}

sub replace_vars {
    @_ = get_right_object(@_);

    my ( $self, $pattern, $named_vars ) = @_;

    my %vars = ( %{ $self->{memory} // {} }, %{$named_vars} );

    for my $var ( keys %vars ) {
        next if $var eq '';

        # escape regex characters
        my $quoted_var = $var;
        $quoted_var =~ s{([\.\*\+])}{\\$1}g;

        $pattern =~ s{$quoted_var}{$vars{$var}}g;
    }
    return $pattern;
}

sub process_transform {
    @_ = get_right_object(@_);
    my ( $self, $str ) = @_;

    for my $tr ( @{ $self->{transforms}{ $self->{context} } } ) {
        next unless $self->match( $str, $tr->{pattern} );
        if ( ref $tr->{code} eq 'CODE' ) {
            warn "Transform code not implemented\n";
        }

        my $input = $tr->{pattern};
        my $vars  = $self->match( $str, $input );

        if ($vars) {
            my $input = $self->replace_vars( $tr->{pattern}, $vars );
            $str =~ s/$input/$tr->{transform}/g;
            $str = $self->replace_vars( $str, $vars );
        }
    }

    # No transformations found...
    return $str;
}

sub process_pattern {
    @_ = get_right_object(@_);
    my ( $self, $input, $message_obj ) = @_;

    for my $context ( 'global', $self->{context}, 'fallback' ) {
        for my $pt ( @{ $self->{patterns}{ $self->{context} } } ) {
            my $match = $self->match( $input, $pt->{pattern} );
            next if !$match;

            my $response;

            if ( $pt->{code} and ref $pt->{code} eq 'CODE' ) {
                $response = $pt->{code}( $message_obj, $match );
            }

            $response //= $pt->{response};

            if ( ref $response eq 'ARRAY' ) {

                # deal with multiple responses
                $response = $response->[ rand( scalar(@$response) ) ];
            }

            my $response_interpolated =
              $self->replace_vars( $response, $match );

            return $response_interpolated;
        }
    }

    warn Dumper $self->{patterns}{ $self->{context} };
    my @unknown_responses = (
        "Sorry, what's that?",
        "Wat?",
        "Hmm?",
        "I got nothing.",
        "No, you do it.",
        "I can't!",
        "It's too hard!",
    );

    return $unknown_responses[ int( rand( scalar @unknown_responses ) ) ];
}

sub process {
    @_ = get_right_object(@_);
    my ( $self, $message_obj ) = @_;

    my $input = $message_obj->text;

    my $tr  = $self->process_transform($input);
    my $res = $self->process_pattern($tr, $message_obj);
    return $res;
}

sub get_right_object {

    # This checks @_. If the first parameter is a reference to an
    # object, we pass that along. If not, we use the singleton
    # object.
    my $maybe_me = $_[0];

    if ( ref($maybe_me) eq __PACKAGE__ ) {
        return @_;
    }

    if ( !defined $singleton ) {
        $singleton = __PACKAGE__->new;
    }
    return ( $singleton, @_ );
}

sub context {
    @_ = get_right_object(@_);

    my ( $self, $ctx ) = @_;
    if ( defined $ctx ) {
        $self->{context} = $ctx;
    }
    return $self->{context};
}

1;

__END__

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013 Nelson Ferraz

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

