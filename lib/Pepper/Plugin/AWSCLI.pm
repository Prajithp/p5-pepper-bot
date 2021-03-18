package Pepper::Plugin::AWSCLI;

use Pepper::Plugin;
use Pepper::Util;

register "run command" => {
     pattern  => qr{run\s+(.*)},
     context  => "aws",
     handler  => sub {
         my ($message, $match) = @_;

         my $cmd  = [split /\s/, $match->{':1'}];
         my $prog = shift $cmd->@*;

         my $bin = Pepper::Util::get_system_binary($prog);
         print $bin . "\n";         
         my $result = Pepper::Util::saferun(
             program => Pepper::Util::get_system_binary($prog), 
             args    => $cmd
         );

         return $message->text_reply($result);
     }
};

1;
