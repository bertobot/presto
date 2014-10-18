package Net::REST::Request;

use strict;

use Class::MethodMaker [
	scalar	=> [ qw( uri path query params error method version headers ) ],
	new	=> [ qw( -init new ) ],
];

sub init {
	my ($self, $args) = @_;

	$self->params({});
	
	$self->headers({});

	my $channel = $args->{channel};

	my $line = <$channel>;

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

		my @p = split /\&/, $';

		foreach my $param (@p) {
			my ($k, $v) = split /=/, $param;
			$self->params->{$k} = $v;
		}
	}

	while ($line = <$channel>) {
		chomp $line;
		$line =~ s/\s+$//;

		last if $line =~ /^$/;

		my @tokens = split /:\s*/, $line;

		$self->headers->{$tokens[0]} = $tokens[1];
	}
}

1;

