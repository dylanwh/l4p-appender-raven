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
layout_pattern=%X{chunk} %d %F{1} %L> %m %n

log4perl.appender.Raven=Log::Log4perl::Appender::Raven
log4perl.appender.Raven.layout=${layout_class}
log4perl.appender.Raven.layout.ConversionPattern=${layout_pattern}

|;

    dies_ok{ Log::Log4perl::init(\$conf); } "Ok sentry_dsn is missing from the config";
}

    my $conf = q|
log4perl.rootLogger=ERROR, Raven

layout_class=Log::Log4perl::Layout::PatternLayout
layout_pattern=%X{chunk} %d %F{1} %L> %m %n

log4perl.appender.Raven=Log::Log4perl::Appender::Raven
log4perl.appender.Raven.sentry_dsn="http://user:key@host.com/project_id"
log4perl.appender.Raven.layout=${layout_class}
log4perl.appender.Raven.layout.ConversionPattern=${layout_pattern}

|;

lives_ok { Log::Log4perl::init(\$conf); } "Ok config is goo";

ok( my $ra =  Log::Log4perl->appender_by_name('Raven') , "Ok got appender 'Raven'");
ok( $ra->raven() , "Ok got nested raven client");

# my $LOGGER = Log::Log4perl->get_logger();

# ok( $ca->store() , "Ok got store");

# is( $ca->state() , 'OFFCHUNK');

# $LOGGER->info("Something outside any context");

# Log::Log4perl::MDC->put('chunk', '12345');

# is( $ca->state() , 'OFFCHUNK');

# $LOGGER->trace("Some trace inside the chunk");
# is( $ca->state() , 'ENTERCHUNK');

# $LOGGER->debug("Some debug inside the chunk");
# is( $ca->state() , 'INCHUNK');

# $LOGGER->info("Some info inside the chunk");
# is( $ca->state() , 'INCHUNK');

# Log::Log4perl::MDC->put('chunk', undef);

# $LOGGER->info("Outside context again");
# is( $ca->state() , 'LEAVECHUNK');

# Log::Log4perl::MDC->put('chunk', '0001');
# $LOGGER->info("Inside another chunk");
# is( $ca->state() , 'ENTERCHUNK');

# $LOGGER->info("Inside another chunk again");
# is( $ca->state() , 'INCHUNK');


# Log::Log4perl::MDC->put('chunk' , '0002' );
# $LOGGER->info("Inside a brand new chunk");
# is( $ca->state() , 'NEWCHUNK');

# $LOGGER->info("Inside a brand new chunk again");
# is( $ca->state() , 'INCHUNK');
# Log::Log4perl::MDC->put('chunk' , undef );
# $LOGGER->info("Left chunk context");
# is( $ca->state() , 'LEAVECHUNK');

# $LOGGER->info("Left chunk context again");
# is( $ca->state() , 'OFFCHUNK');

# ok(1);

done_testing();
