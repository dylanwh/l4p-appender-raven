#! /bin/env/perl

use strict;
use warnings;

use Log::Log4perl;
use Log::Log4perl::MDC;

use MyNumberGuess;

my $l4pconf = q|
log4perl.rootLogger=TRACE, Screen, Raven

layout_class=Log::Log4perl::Layout::PatternLayout
layout_pattern=%d %F{1} %L> %m %n

log4perl.appender.Screen=Log::Log4perl::Appender::Screen
log4perl.appender.Screen.layout=${layout_class}
log4perl.appender.Screen.layout.ConversionPattern=${layout_pattern}

log4perl.appender.Raven=Log::Log4perl::Appender::Raven
log4perl.appender.Raven.Threshold=ERROR
log4perl.appender.Raven.tags.application=my-demo-app
log4perl.appender.Raven.mdc_tags=sentry_tags
log4perl.appender.Raven.mdc_extra=sentry_extra
log4perl.appender.Raven.layout=${layout_class}
log4perl.appender.Raven.layout.ConversionPattern=${layout_pattern}

|;

Log::Log4perl::init(\$l4pconf);

my $LOGGER = Log::Log4perl->get_logger();



Log::Log4perl::MDC->put('sentry_tags', { phase => 'init_game' });

my $number_guess = MyNumberGuess->new();

$LOGGER->info("Starting game");

$number_guess->do_play();

Log::Log4perl::MDC->put('sentry_tags', { phase => 'shutting_down' });

$LOGGER->info("Done!");
