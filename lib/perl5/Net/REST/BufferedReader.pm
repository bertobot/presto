package Net::REST::BufferedReader;

use strict;

use Class::MethodMaker [
    scalar => [ qw( fd buffer chunksize) ],
    new => [ qw( -init new ) ],
];

sub init {
    my ($self, $args) = @_;

    $self->fd($args->{fd});

    $self->chunksize($args->{chunksize} || 8192);

    $self->buffer($args->{buffer} || "");
}

sub read {
    my ($self, $args) = @_;

    my $result;

    my $lbuf = length($self->buffer);

    if ($lbuf >= $args->{'length'}) {
        $result = substr($self->buffer, 0, $args->{'length'});
    }
    else {
        my $tbuffer;

        while ($lbuf < $args->{'length'}) {

            my $rc = sysread($self->fd, $tbuffer, $args->{'length'} - $lbuf);

            last if ! $rc;

            $self->buffer($self->buffer . $tbuffer);

            $lbuf += $rc;

            last if $rc < $args->{'length'};
        }

        $result = substr($self->buffer, 0, $args->{'length'});
    }

    return $result;
}

sub readLine {

    my ($self, $args) = @_;

    my $result;
    
    if ($self->buffer =~ /^(.+?)(\r?\n)/) {
        $result = $1;
        $self->buffer(substr($self->buffer, length($result) + length($2)) );
    }
    else {
        my $buffer = $self->read({ 'length' => $self->chunksize });

        if (! length($buffer)) {
            return $self->buffer
        }

        $self->buffer($buffer);
        
        return $self->readLine;
    }

    return $result;
}

1;
