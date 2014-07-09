#! /bin/env/perl

use strict;
use warnings;

use Log::Log4perl;

my $l4pconf = q|
log4perl.rootLogger=TRACE, Screen, Raven

layout_class=Log::Log4perl::Layout::PatternLayout
layout_pattern=%d %F{1} %L> %m %n

log4perl.appender.Screen=Log::Log4perl::Appender::Screen
log4perl.appender.Screen.layout=${layout_class}
log4perl.appender.Screen.layout.ConversionPattern=${layout_pattern}

log4perl.appender.Raven=Log::Log4perl::Appender::Raven
log4perl.appender.Raven.Threshold=ERROR
log4perl.appender.Raven.sentry_dsn="http://blabla:blabla@host.com/project_id"
log4perl.appender.Raven.tags.application=my-demo-app
log4perl.appender.Raven.mdc_tags=sentry_tags
log4perl.appender.Raven.mdc_extra=sentry_extra
log4perl.appender.Raven.layout=${layout_class}
log4perl.appender.Raven.layout.ConversionPattern=${layout_pattern}

|;

Log::Log4perl::init(\$l4pconf);

my $LOGGER = Log::Log4perl->get_logger();




$LOGGER->info("Starting game");
$LOGGER->debug("Picking a number");

my $to_guess = int(rand(101));

print "Guess the number [1..100]:";

while( chomp(my $num = <>) ){
    unless( $num =~ /^[0-9]+$/ ){ $LOGGER->error("Wrong number format ($num is not an integer)"); next; }

    if( $num == $to_guess ){
        print "You won!\n";
        $LOGGER->debug("User guessed the number");
        last;
    }

    unless( $num >= 1 && $num <= 100 ){
        $LOGGER->logconfess("Number $num is outside acceptable range");
    }

    if( $num > $to_guess ){
        $LOGGER->trace("Number is too high");
        print "Too high\n";
    }else{
        print "Too low\n";
    }

    print "Guess again:";
}

$LOGGER->info("Done!");
