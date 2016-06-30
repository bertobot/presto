package Net::REST;

use strict;

use Net::REST::Request;
use Net::REST::Response;
use IO::Socket::INET;
use IO::Select;

use Class::MethodMaker [
	scalar	=> [ qw( host port urimap uriregex timeout onLoopBegin onLoopEnd onConnect onNoConnection ) ],
	new	=> [ qw( -init new ) ],
];

sub init {
	my ($self, $args) = @_;

	$self->host($args->{host} || 'localhost');

	$self->port($args->{port} || 2020);

	$self->timeout($args->{timeout} || 5);

	$self->urimap({});

	$self->uriregex({});

	$self->onLoopBegin($args->{onLoopBegin});

	$self->onLoopEnd($args->{onLoopEnd});

	$self->onConnect($args->{onConnect});

	$self->onNoConnection($args->{onNoConnection});
}

sub _uriprep {
	my ($self, $method, $uri, $func) = @_;

    if ($uri =~ /[:\*]/) {
        my @paramlist = ();

        my $duri = $uri;

        if ($duri =~ /(\*(.+?))$/) {
            my $param = $2;

            my $match = "\\*$param";

            $duri =~ s/$match/(.+?)/g;

            push @paramlist, $param;
        }

        while ($duri =~ /(:(\w+))/) {
            my $match = $1;

            push @paramlist, $2;

            $duri =~ s/$match/(\\w+)/;
        }

        $self->uriregex->{$method}->{$duri}{func} = $func;

        $self->uriregex->{$method}->{$duri}{params} = \@paramlist;
    }

    else {
        $self->urimap->{$method}->{$uri} = $func;
    }
}

sub get {
	my ($self, $uri, $func) = @_;

    $self->_uriprep('GET', $uri, $func);
}

sub post {
	my ($self, $uri, $func) = @_;

    $self->_uriprep('POST', $uri, $func);
}

sub put {
	my ($self, $uri, $func) = @_;

    $self->_uriprep('PUT', $uri, $func);
}

sub delete {
	my ($self, $uri, $func) = @_;

    $self->_uriprep('DELETE', $uri, $func);
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
                
                    $select->remove($r);

                    $r->close;

                    # TODO: support onError callback?

                    next;
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

	my $f = $self->urimap->{$request->method}->{$request->path};

	if (defined $f) {
		&$f($request, $response);
	}

	else {
        my $done = 0;

        foreach my $re (keys %{ $self->uriregex->{$request->method} }) {
            my @matches = ($request->path =~ /$re/);

            if (@matches) {
                my $f = $self->uriregex->{$request->method}->{$re}{func};

                my $list = $self->uriregex->{$request->method}->{$re}{params};

                
                for (my $i = 0; $i < @$list; $i++) {
                    $request->params->{$list->[$i]} = $matches[$i];
                }

                if (defined $f) {
                    &$f($request, $response);

                    $done = 1;

                    last;
                }
            }
        }

		$response->write("", { status => 404 }) if ! $done;
	}
}

1;

