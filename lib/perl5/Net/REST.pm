package Net::REST;

use strict;

use Net::REST::Request;
use Net::REST::Response;
use IO::Socket::INET;
use IO::Select;

use Class::MethodMaker [
	scalar	=> [ qw( host port urimap timeout onLoopBegin onLoopEnd onConnect onNoConnection ) ],
	new	=> [ qw( -init new ) ],
];

sub init {
	my ($self, $args) = @_;

	$self->host($args->{host} || 'localhost');

	$self->port($args->{port} || 2020);

	$self->timeout($args->{timeout} || 5);

	$self->urimap({});

	$self->onLoopBegin($args->{onLoopBegin});

	$self->onLoopEnd($args->{onLoopEnd});

	$self->onConnect($args->{onConnect});

	$self->onNoConnection($args->{onNoConnection});
}

sub get {
	my ($self, $uri, $func) = @_;

	$self->urimap->{$uri} = $func;
}

sub post {
	my ($self, $uri, $func) = @_;

	$self->urimap->{$uri} = $func;
}

sub put {
	my ($self, $uri, $func) = @_;

	$self->urimap->{$uri} = $func;
}

sub delete {
	my ($self, $uri, $func) = @_;

	$self->urimap->{$uri} = $func;
}

sub run {
	my ($self, $args) = @_;

	my $server = new IO::Socket::INET(
		LocalHost	=> $self->host,
		LocalPort	=> $self->port,
		Listen	=> 1,
		Reuse	=> 1,
		Proto	=> 'tcp',
	) || die "couldn't listen on port $args->{port}: $!\n";

	my $select = new IO::Select($server);

	while (1) {

		if (defined $self->onLoopBegin) {
			&{ $self->onLoopBegin };
		}

		my @ready = $select->can_read( $self->timeout );

		if (! @ready && defined $self->onNoConnection) {
			&{ $self->onNoConnection };
		}

		foreach my $r (@ready) {
			if ($r == $server) {
				# TODO: log
				my $client = $r->accept;

				$select->add($client);

				if (defined $self->onConnect) {
					&{ $self->onConnect }($client);
				}
			}
			else{

				my $request = new Net::REST::Request({ channel => $r });

				if ($request->error) {
					# TODO: log
				}

				$self->process($request, $r);

				$select->remove($r);

				$r->close;
			}
		}

		if (defined $self->onLoopEnd) {
			&{ $self->onLoopEnd };
		}

		# loops forever until killed.
	}
}

sub process {
	my ($self, $request, $channel) = @_;

	my $response = new Net::REST::Response({ channel => $channel });

	my $f = $self->urimap->{$request->path};

	if (defined $f) {
		&$f($request, $response);
	}
	else {
		$response->write("", { status => 404 });
	}
}

1;

