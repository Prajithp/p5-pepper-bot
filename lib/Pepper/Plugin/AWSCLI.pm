package Pepper::Plugin::AWSCLI;

use Pepper::Plugin;
use Pepper::Util;

register "run command" => {
     pattern     => qr{run\s+(.*)},
     descrption  => "!awscli run sts get-caller-identity --output text",
     context     => "awscli",
     handler     => sub {
         my ($message, $match) = @_;

         my $args   = [split /\s/, $match->{':1'}];
         my $bin    = Pepper::Util::get_system_binary('aws');
         my $result = _run_aws_cli($bin, $args);

         return $message->text_reply($result);
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


