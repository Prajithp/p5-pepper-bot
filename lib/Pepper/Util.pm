package Pepper::Util;

use strict;

sub trim { 
   my $s = shift; 
   $s =~ s/^\s+|\s+$//g;
    
   return $s;
}

sub wrap_text {
    return sprintf("```%s```", $_[0])
}   


sub get_system_binary {
    my $bin = shift;
  
    if ( index( $bin, '/' ) == 0 ) {
        return $bin;
    }
  
    my $full_path;
    for my $path (qw</bin /usr/bin /usr/local/bin>) {
        $full_path = $path . '/' . $bin;
        last if -e $full_path && -x $full_path;
    }
 
    return $full_path;
};

sub saferun {
    my %OPTS = @_;
    
    if ( $OPTS{'program'} =~ tr{><*?[]`$()|;&#$\\\r\n\t }{} && !-e $OPTS{'program'} ) {
        die "found shell chars in command";
    }   
    
    my $prog_fh;
    
    my $prog    = $OPTS{'program'};
    my $args    = $OPTS{'args'}  // [];
    
    my $pid;
    if ( $pid = open( $prog_fh, '-|' ) ) {
         # parent 
    }
    elsif ( defined $pid ) {
        open( STDERR, '>&STDOUT' ) or die "Failed to redirect STDERR to STDOUT: $!";
        exec($prog, $args->@*) or exit( $! || 127 );
    }
    else {
        die "fork() failed: $!";
    }
    waitpid( $pid, 0 );

    local $/;
    my $output = <$prog_fh>;

    return $output;
}

1;
