package Log::Log4perl::Appender::Raven;

use Moose;

use Sentry::Raven;
use Log::Log4perl;
use Devel::StackTrace;

has 'sentry_dsn' => ( is => 'ro', isa => 'Maybe[Str]' );
has 'sentry_timeout' => ( is => 'ro' , isa => 'Int' ,required => 1 , default => 5 );

has 'raven' => ( is => 'ro', isa => 'Sentry::Raven', lazy_build => 1);
has 'context' => ( is => 'ro' , isa => 'HashRef', default => sub{ {}; });

my %L4P2SENTRY = ('ALL' => 'info', 
                  'TRACE' => 'debug',
                  'DEBUG' => 'debug',
                  'INFO' => 'info',
                  'WARN' => 'warning',
                  'ERROR' => 'error',
                  'FATAL' => 'fatal');


sub _build_raven{
    my ($self) = @_;
    return Sentry::Raven->new( sentry_dsn => $self->sentry_dsn,
                               timeout => $self->sentry_timeout,
                               %{$self->context()}
                             );
}

sub log{
    my ($self, %params) = @_;

    ## Any logging within this method will be discarded.
    if( Log::Log4perl::MDC->get(__PACKAGE__.'-reentrance') ){
        return;
    }
    Log::Log4perl::MDC->put(__PACKAGE__.'-reentrance', 1);

    # use Data::Dumper;
    # warn Dumper(\%params);

    # Look there to see what sentry expects:
    # http://sentry.readthedocs.org/en/latest/developer/client/index.html#building-the-json-packet

    my $sentry_message = length($params{message}) > 1000 ? substr($params{message}, 0 , 1000) : $params{message};
    my $sentry_logger  = $params{log4p_category};
    my $sentry_level = $L4P2SENTRY{$params{log4p_level}} || 'info';

    # We are 5 levels down after the standard Log4perl caller_depth
    my $caller_offset = Log::Log4perl::caller_depth_offset( $Log::Log4perl::caller_depth + 5 );

    my $caller_frames = Devel::StackTrace->new();
    {
        ## Remove the frames from the Log4Perl layer.
        my @frames = $caller_frames->frames();
        splice(@frames, 0, $caller_offset);
        $caller_frames->frames(@frames);
    }

    my $sentry_culprit;
    {
        my ($package, $filename, $line,
            $subroutine, $hasargs,
            $wantarray, $evaltext, $is_require,
            $hints, $bitmask) = caller($caller_offset - 1);
        $sentry_culprit = $subroutine || $filename || 'main';
    }

    # OK WE HAVE THE BASIC Sentry options.
    $self->raven->capture_message($sentry_message,
                                  logger => $sentry_logger,
                                  level => $sentry_level,
                                  culprit => $sentry_culprit,
                                  Sentry::Raven->stacktrace_context( $caller_frames ));

    Log::Log4perl::MDC->put(__PACKAGE__.'-reentrance', undef);
}


__PACKAGE__->meta->make_immutable();


=head1 NAME

  Log::Log4perl::Appender::Raven - Append log events to your Sentry account.

=head1 CONFIGURATION

This is just another L<Log::Log4perl::Appender>.

The only mandatory configuration key
is *sentry_dsn* which is your sentry dsn string obtained from your sentry account.
See http://www.getsentry.com/ and https://github.com/getsentry/sentry for more details.

Alternatively to setting this configuration key, you can set an environment variable SENTRY_DSN
with the same setting. - Not recommended -

Example:

  log4perl.rootLogger=ERROR, Raven

  layout_class=Log::Log4perl::Layout::PatternLayout
  layout_pattern=%X{chunk} %d %F{1} %L> %m %n

  log4perl.appender.Raven=Log::Log4perl::Appender::Raven
  # THIS IS MANDATORY:
  log4perl.appender.Raven.sentry_dsn="http://user:key@host.com/project_id"
  log4perl.appender.Raven.layout=${layout_class}
  log4perl.appender.Raven.layout.ConversionPattern=${layout_pattern}


=cut
