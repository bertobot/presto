package Net::REST::Request;

use strict;

use JSON;
use Net::REST::BufferedReader;
use Class::MethodMaker [
	scalar	=> [ qw( uri path query params error method version headers body ) ],
	new	=> [ qw( -init new ) ],
];

sub init {
	my ($self, $args) = @_;

	$self->params({});
	
	$self->headers({});

    $self->body('');

	my $channel = $args->{channel};

    my $br = new Net::REST::BufferedReader({ fd => $channel });

	my $line = $br->readLine;

	chomp $line;

	my @tokens = split /\s+/, $line;

	if ($tokens[-1] !~ /HTTP\//) {
		$self->error("invalid request: " . $line);
		return;
	}

	$self->method($tokens[0]);

	$self->uri($tokens[1]);

	$self->path($tokens[1]);

	$self->version($tokens[2]);

	if ($tokens[1] =~ /\?/) {
		$self->path($`);

		$self->query($');

		my @p = split /\&/, $self->decode($');

		foreach my $param (@p) {
			my ($k, $v) = split /=/, $param;
			$self->params->{$k} = $v;
		}
	}

	while ($line = $br->readLine) {
		chomp $line;
		$line =~ s/\s+$//;

		last if $line =~ /^$/;

		my @tokens = split /:\s*/, $line;

		$self->headers->{$tokens[0]} = $tokens[1];
	}

    # if the header has a content-length, read it into body
    if ($self->headers->{'Content-Length'}) {
        $self->body($br->read({ 'length' => $self->headers->{'Content-Length'} }) );
    }
}

sub decode {
	my ($self, $args) = @_;

	while ($args =~ /(%(..))/) {
		my $matched = $1;
		my $replacement = chr(hex($2) );

		$args =~ s/$matched/$replacement/g;
	}

	return $args;
}

sub json {
    my ($self, $args) = @_;
    return decode_json($self->body);
}

# vim: ts=4:sw=4:expandtab
1;

