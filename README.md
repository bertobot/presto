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

        # begin chunk transfer encoding
        $res->begin();

        foreach my $p (keys %{ $req->params }) {
                # send chunk
                $res->chunk(sprintf("%s => %s\n", $p, $req->params->{$p}) );
        }

        # send an empty chunk to finish the chunk encoding.
        $res->chunk;
});

# json example

use JSON;

$app->post('/json/post', sub {
        my ($req, $res) = @_;
        
        my $jsonstr = $req->body;
        
        my $jshash = decode_json($jsonstr);
        
        # do something with that data
        
        $res->write( encode_json( { 'status' => 'ok' }, { type => 'application/json' } ) );
});

$app->get('/json/get', sub {
        # lazy one liner
        $_[1]->write( encode_json({ key => 'value', anotherKey => [] }), { type => 'application/json' } );
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
- [ ] Support placeholder shortcuts like */hello/:name*
- [ ] Document the three objects (Request, Response and REST) of this project.
- [ ] Support redirect, forward in Response object.
- [ ] Built-in support for JSON ?
