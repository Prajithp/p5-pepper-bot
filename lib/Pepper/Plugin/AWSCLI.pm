package Pepper::Plugin::AWSCLI;

use Pepper::Plugin;
use Pepper::Util;

namespace "awscli";

register "run command" => {
     pattern     => qr{run\s+(.*)},
     descrption  => "!awscli run sts get-caller-identity --output text",
     handler     => sub {
         my $match = shift;

         my $args   = [split /\s/, $match->{':1'}];
         my $bin    = Pepper::Util::get_system_binary('aws');
         my $result = _run_aws_cli($bin, $args);
         return Pepper::Util::wrap_text($result);
     }
};

sub _run_aws_cli {
    my ($bin, $args) = @_;

    my $result = Pepper::Util::saferun(
        program => $bin,
        args    => $args
    );

    return $result;
}

1;

__END__


