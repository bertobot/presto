package Net::REST::Response;

use strict;

use JSON;
use Class::MethodMaker [
	scalar	=> [ qw( type headers status channel ) ],
	new	=> [ qw( -init new ) ],
];

our $codes = {
    200	=> 'OK',
    301	=> 'Not Modified',
    302	=> 'Found',
    304	=> 'Moved Permanently',
    400	=> 'Bad Request',
    404	=> 'Not Found',
    500	=> 'Internal Server Error',
};

sub init {
	my ($self, $args) = @_;

	$self->channel($args->{channel});

	$self->type($args->{type} || "text/html");

	$self->headers($args->{headers} || {});

	$self->status($args->{status} || 200);
}

sub write {
	my ($self, $body, $args) = @_;

	my $channel = $self->channel;

	my $status = $args->{status} || 200;

	my $headers = $args->{headers} || $self->headers;

	$headers->{"Content-Type"} = $args->{type} || "text/html" if ! $headers->{"Content-Type"};

	$headers->{"Content-Length"} = length($body) if ! $headers->{"Content-Length"};

	printf $channel "HTTP/1.1 %s %s\r\n", $status, $codes->{$status};

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

	printf $channel "HTTP/1.1 %s %s\r\n", $status, $codes->{$status};

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

sub redirect {
	my ($self, $url) = @_;

	my $channel = $self->channel;

    my $status = 301;

	printf $channel "HTTP/1.1 %s %s\r\n", $status, $codes->{$status};

    printf $channel "Location: %s\r\n\r\n", $url;
}

sub forward {
	my ($self, $url) = @_;

	my $channel = $self->channel;

    my $status = 302;

	printf $channel "HTTP/1.1 %s %s\r\n", $status, $codes->{$status};

    printf $channel "Location: %s\r\n\r\n", $url;
}

sub json {
    my ($self, $args) = @_;
    $self->write(encode_json($args), { type => 'application/json' } );
}

sub file {
    my ($self, $filename, $args) = @_;

    if (open FILE, $filename) {
        $self->begin();
        while (1) {
            my $buffer;
            my $rc = sysread FILE, $buffer, 8192;
           
            last if ! $rc;

            $self->chunk($buffer);
        }
        $self->chunk();
    }
    else {
        $self->write("", { status => 404 });
    }
}

1;

