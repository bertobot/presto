presto
======

Perl REST container / server

```perl
#!/usr/bin/perl

use strict;

use Net::REST;


# explcit function definition example
sub helloworld {
        my ($request, $response) = @_;

        $response->write("hello world!");
}

my $app = new Net::REST({ port => 2020 });

$app->get("/hello", \&helloworld);



# anonymous function definition example

$app->get('/test', sub {
        my ($req, $res) = @_;

        $res->begin();

        foreach my $p (keys %{ $req->params }) {
                $res->chunk(sprintf("%s => %s\n", $p, $req->params->{$p}) );
        }

        $res->chunk("", 1);
});

# run

$app->run();
```

## Features
- GET, POST, PUT, DELETE handling.
- Write standalone REST servers that can then be fronted by nginx, etc.

## Dependencies
- Class::MethodMaker
- IO::Socket::INET
- IO::Select

## TODO
- [ ] support placeholder shortcuts like */hello/:name*
