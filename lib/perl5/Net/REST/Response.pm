package Net::REST::Response;

use strict;

use Class::MethodMaker [
	scalar	=> [ qw( type headers status channel codes ) ],
	new	=> [ qw( -init new ) ],
];

sub init {
	my ($self, $args) = @_;

	$self->channel($args->{channel});

	$self->type($args->{type} || "text/html");

	$self->headers($args->{headers} || {});

	$self->status($args->{status} || 200);

	$self->codes({
		200	=> 'OK',
		301	=> 'Not Modified',
		302	=> 'Moved Temporarily',
		304	=> 'Moved Permanently',
		400	=> 'Not Found',
		500	=> 'Internal Server Error',
	});

}

sub write {
	my ($self, $body, $args) = @_;

	my $channel = $self->channel;

	my $status = $args->{status} || 200;

	my $headers = $args->{headers} || $self->headers;

	$headers->{"Content-Type"} = $args->{type} || "text/html" if ! $headers->{"Content-Type"};

	$headers->{"Content-Length"} = length($body) if ! $headers->{"Content-Length"};

	printf $channel "HTTP/1.1 %s %s\r\n", $status, $self->codes->{$status};

	foreach my $h (keys %$headers) {
		printf $channel "%s: %s\r\n", $h, $headers->{$h};
	}

	print $channel "\r\n";

	print $channel "$body\r\n";
}

sub begin {
	my ($self, $args) = @_;

	my $channel = $self->channel;

	my $status = $args->{status} || 200;

	my $headers = $args->{headers};

	$headers->{"Content-Type"} = $args->{type} || "text/html" if ! $headers->{"Content-Type"};

	$headers->{"Transfer-Encoding"} = "chunked";

	printf $channel "HTTP/1.1 %s %s\r\n", $status, $self->codes->{$status};

	foreach my $h (keys %$headers) {
		printf $channel "%s: %s\r\n", $h, $headers->{$h};
	}

	print $channel "\r\n";
}

sub chunk {
	my ($self, $body) = @_;

	my $channel = $self->channel;

	printf $channel "%x\r\n%s\r\n", length($body), $body;
}

1;

