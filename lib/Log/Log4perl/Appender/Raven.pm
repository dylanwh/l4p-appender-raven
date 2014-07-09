package Log::Log4perl::Appender::Raven;

use Moose;

use Sentry::Raven;

has 'sentry_dsn' => ( is => 'ro', isa => 'Str' , required => 1);
has 'sentry_timeout' => ( is => 'ro' , isa => 'Int' ,required => 1 , default => 5 );

has 'raven' => ( is => 'ro', isa => 'Sentry::Raven', lazy_build => 1);
has 'context' => ( is => 'ro' , isa => 'HashRef', default => sub{ {}; });

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

    use Data::Dumper;
    warn Dumper(\%params);

    Log::Log4perl::MDC->put(__PACKAGE__.'-reentrance', undef);
}


__PACKAGE__->meta->make_immutable();
1;

=head1 NAME

  Log::Log4perl::Appender::Raven - Append log events to your Sentry account.

=head1 CONFIGURATION

This is just another L<Log::Log4perl::Appender> the only mandatory configuration key
is *sentry_dsn* which is your sentry dsn string obtained from your sentry account.
See http://www.getsentry.com/ and https://github.com/getsentry/sentry for more details.


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
