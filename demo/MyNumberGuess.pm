package MyNumberGuess;

use Moose;

use Log::Log4perl;
my $LOGGER = Log::Log4perl->get_logger();

sub do_play{
    $LOGGER->debug("Picking a number");

    my $to_guess = int(rand(101));


    Log::Log4perl::MDC->put('sentry_tags', { phase => 'in_game' });

    print "Guess the number [1..100]:";

    while ( chomp(my $num = <>) ) {
        unless ( $num =~ /^[0-9]+$/ ) {
            $LOGGER->error("Wrong number format ($num is not an integer)"); next;
        }

        unless( $num >= 1 && $num <= 100 ){
            $LOGGER->logconfess("Number $num is outside acceptable range");
        }

        if ( $num == $to_guess ) {
            print "You won!\n";
            $LOGGER->debug("User guessed the number");
            last;
        }

        if ( $num > $to_guess ) {
            $LOGGER->trace("Number is too high");
            print "Too high\n";
        } else {
            print "Too low\n";
        }
        print "Guess again:";
    }
}

__PACKAGE__->meta->make_immutable();
