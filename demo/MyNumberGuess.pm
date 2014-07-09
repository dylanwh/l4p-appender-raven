package MyNumberGuess;

use Moose;

use Log::Log4perl;
my $LOGGER = Log::Log4perl->get_logger();

sub do_play{
    my ($self) = @_;

    $LOGGER->debug("Picking a number");

    my $to_guess = int(rand(11));


    Log::Log4perl::MDC->put('sentry_tags', { phase => 'in_game' });

    print "Guess the number [1..10]:";

    while ( chomp(my $num = <>) ) {

        unless( $self->check_number($num) ){ next; }

        $self->check_range($num);

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

sub check_range{
    my ($self, $num) = @_;
    unless( $num >= 1 && $num <= 10 ){
        $LOGGER->logconfess("Number $num is outside acceptable range");
    }
}

sub check_number{
    my ($self, $num) = @_;
    unless ( $num =~ /^[0-9]+$/ ) {
        $LOGGER->error("Wrong number format ($num is not an integer)");
        return 0;
    }
    return 1;
}


__PACKAGE__->meta->make_immutable();
