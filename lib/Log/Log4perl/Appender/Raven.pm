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

__PACKAGE__->meta->make_immutable();
1;
