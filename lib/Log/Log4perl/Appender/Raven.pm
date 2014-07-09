package Log::Log4perl::Appender::Raven;

use Moose;

use Data::Dumper;
use Sentry::Raven;
use Log::Log4perl;
use Devel::StackTrace;

has 'sentry_dsn' => ( is => 'ro', isa => 'Maybe[Str]' );
has 'sentry_timeout' => ( is => 'ro' , isa => 'Int' ,required => 1 , default => 5 );

has 'raven' => ( is => 'ro', isa => 'Sentry::Raven', lazy_build => 1);

# STATIC CONTEXT
has 'context' => ( is => 'ro' , isa => 'HashRef', default => sub{ {}; });

# STATIC TAGS. They will go in the global context.
has 'tags' => ( is => 'ro' ,isa => 'HashRef', default => sub{ {}; });

# Log4Perl MDC key to look for tags
has 'mdc_tags' => ( is => 'ro' , isa => 'Maybe[Str]' );
# Log4perl MDC key to look for extra
has 'mdc_extra' => ( is => 'ro', isa => 'Maybe[Str]' );

my %L4P2SENTRY = ('ALL' => 'info',
                  'TRACE' => 'debug',
                  'DEBUG' => 'debug',
                  'INFO' => 'info',
                  'WARN' => 'warning',
                  'ERROR' => 'error',
                  'FATAL' => 'fatal');


sub _build_raven{
    my ($self) = @_;

    my $dsn = $self->sentry_dsn || $ENV{SENTRY_DSN} || confess("No sentry_dsn config or SENTRY_DSN in ENV");


    my %raven_context = %{$self->context()};
    $raven_context{tags} = $self->tags();

    return Sentry::Raven->new( sentry_dsn => $dsn,
                               timeout => $self->sentry_timeout,
                               %raven_context
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

    my $tags = {};
    if( my $mdc_tags = $self->mdc_tags() ){
        $tags = Log::Log4perl::MDC->get($mdc_tags) || {};
    }

    my $extra = {};
    if( my $mdc_extra = $self->mdc_extra() ){
        $extra = Log::Log4perl::MDC->get($mdc_extra) || {};
    }

    # OK WE HAVE THE BASIC Sentry options.
    $self->raven->capture_message($sentry_message,
                                  logger => $sentry_logger,
                                  level => $sentry_level,
                                  culprit => $sentry_culprit,
                                  tags => $tags,
                                  extra => $extra,
                                  Sentry::Raven->stacktrace_context( $caller_frames ));

    Log::Log4perl::MDC->put(__PACKAGE__.'-reentrance', undef);
}


__PACKAGE__->meta->make_immutable();


=head1 NAME

  Log::Log4perl::Appender::Raven - Append log events to your Sentry account.

=head1 WARNING

This appender will send ALL the log events it receives to your
Sentry DSN. If you generate a log of logging, that can make your sentry account
saturate quite quickly. Using L<Log::Log4perl::Filter> in your log4perl config
is Highly Recommended.

You have been warned.

=head1 SYNOPSIS

Read the L<CONFIGURATION> section, then use Log4perl just as usual.

If you are not familiar with Log::Log4perl, please check L<Log::Log4perl>

=head1 CONFIGURATION

This is just another L<Log::Log4perl::Appender>.

=head2 Simple Configuration

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
  log4perl.appender.Raven.sentry_dsn="http://user:key@host.com/project_id"
  log4perl.appender.Raven.layout=${layout_class}
  log4perl.appender.Raven.layout.ConversionPattern=${layout_pattern}

=head2 Configuration with Static Tags

You have the option of predefining a set of tags that will be send to
your Sentry installation with every event. Remember Sentry tags have a name
and a value (they are not just 'labels').

Example:

  ...
  log4perl.appender.Raven.tags.application=myproduct
  log4perl.appender.Raven.tags.installation=live
  ...

=head2 Configure and use Dynamic Tagging

Dynamic tagging is performed using the Log4Perl MDC mechanism.
See L<Log::Log4perl::MDC> if you are not familiar with it.

Config (which MDC key to capture):

   ...
   log4perl.appender.Raven.mdc_tags=my_sentry_tags
   ...

Then anywhere in your code.

  ...
  Log::Log4perl::MDC->set('my_sentry_tags' , { subsystem => 'my_subsystem', ... });
  $log->error("Something very wrong");
  ...

Note that tags added this way will be added to the statically define ones, or override them in case
of conflict.


=head2 Configure and use Dynamic Extra

Sentry allows you to specify any data (as a Single level HashRef) that will be stored with the Event.

It's very similar to dynamic tags, except its not tags.

Config (which MDC key to capture):

  ...
  log4perl.appender.Raven.mdc_extra=my_sentry_extra
  ...

Then anywere in your code:

  ...
  Log::Log4perl::MDC->set('my_sentry_extra' , { user_id => ... , session_id => ... , ...  });
  $log->error("Something very wrong");
  ...

=head2 Configuration with a Static Context.

You can use lines like:

  log4perl.appender.Raven.context.platform=myproduct

To define static L<Sentry::Raven> context. The list of context keys supported is not very
long, and most of them are defined dynamically when you use this package anyway.

See L<Sentry::Raven> for more details.

=head1 AUTHOR

Jerome Eteve jeteve@cpan.com

=cut
