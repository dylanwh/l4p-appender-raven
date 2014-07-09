#! perl -T
use strict;
use warnings;

use Test::More;
use Test::Fatal qw/dies_ok lives_ok/;
use Log::Log4perl;

{
    my $conf = q|
log4perl.rootLogger=ERROR, Raven

layout_class=Log::Log4perl::Layout::PatternLayout
layout_pattern=%d %F{1} %L> %m %n

log4perl.appender.Raven=Log::Log4perl::Appender::Raven
log4perl.appender.Raven.layout=${layout_class}
log4perl.appender.Raven.layout.ConversionPattern=${layout_pattern}

|;

    dies_ok{ Log::Log4perl::init(\$conf); } "Ok sentry_dsn is missing from the config";
}

    my $conf = q|
log4perl.rootLogger=ERROR, Raven

layout_class=Log::Log4perl::Layout::PatternLayout
layout_pattern=%d %F{1} %L> %m %n

log4perl.appender.Raven=Log::Log4perl::Appender::Raven
log4perl.appender.Raven.sentry_dsn="https://blabla:blabla@app.getsentry.com/some_id"
log4perl.appender.Raven.layout=${layout_class}
log4perl.appender.Raven.layout.ConversionPattern=${layout_pattern}

|;

lives_ok { Log::Log4perl::init(\$conf); } "Ok config is goo";

ok( my $ra =  Log::Log4perl->appender_by_name('Raven') , "Ok got appender 'Raven'");
ok( $ra->raven() , "Ok got nested raven client");


package My::Shiny::Package;

my $LOGGER = Log::Log4perl->get_logger();
sub emit_error{
    my ($class) = @_;
    $LOGGER->error("Some error");
    $class->and_another_one();
}

sub and_another_one{
    $LOGGER->error('Deeper error');
}

1;

package main;

My::Shiny::Package->emit_error();

$LOGGER = Log::Log4perl->get_logger();

$LOGGER->error("Error at main level");

ok(1);
done_testing();
