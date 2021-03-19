package Pepper::Plugin::Help;

use Pepper::Plugin;

register "help" => {
     descrption  => "help or help <context>",
     pattern     => qr{\Ahelp\s*(?:\w+)?\Z},
     handler     => sub {
         my $match = shift;
         my $available_options = [];

         my $registry = Pepper::Registry->registry // {};
         foreach my $plugin (keys $registry->%*) {
             my $namespace = $registry->{$plugin}->{'namespace'} // 'default';
             my $patterns  = $registry->{$plugin}->{'patterns'};
             foreach my $c (keys $patterns->%*) {
                 push $available_options->@*, $patterns->{$c}->{'descrption'} // 
                      $patterns->{$c}->{'pattern'};
             }
         }
         return join "\n", $available_options->@*;
     }   
};   

1;

__END__


