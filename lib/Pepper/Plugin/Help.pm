package Pepper::Plugin::Help;

use Pepper::Plugin;


register "help" => {
     descrption  => "help or help <context>",
     pattern     => qr{\Ahelp\s*(?:\w+)?\Z},
     handler     => sub {
         my ($message, $match) = @_;
         
         my $patterns = [];
         my $registry = Pepper::Registry->registry // {};
         foreach my $pkg (keys $registry->%*) {
             foreach my $c (keys $registry->{$pkg}->%*) {
                 push $patterns->@*, $registry->{$pkg}->{$c}->{'descrption'} // 
                      $registry->{$pkg}->{$c}->{'pattern'};
             }
         }
         return join "\n", $patterns->@*;
     }   
};   

1;

__END__


