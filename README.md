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

## Hooks Example:
```perl
use Net::REST;

...

my $stats = {
        loops   => 0,
        clients => 0,
        idle    => 0,
};

$app->onConnect(sub {
        my $clientsocket = shift;
        
        # print the client connection info on-connect:
        printf "%s:%s has connected.\n", $clientsocket->peerhost, $clientsocket->peerport;
        
        $stats->{clients}++;
});

# could be handled in onLoopEnd, also.  Your choice.
$app-onLoopBegin(sub { $stats->{loops}++ } );

$app->onNoConnection(sub { 
        $stats->{idle}++;
        
        # maybe perform some kind of 'household' task...
        # like publish stats
});

...

$app->run;

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
- [X] Document the three objects (Request, Response and REST) of this project.
- [ ] Support redirect, forward in Response object.
- [ ] Built-in support for JSON ?

## Methods
### Net::REST

* get() - HTTP GET method handler.
* post() - HTTP POST method handler.
* put() - HTTP PUT method handler.
* delete() - HTTP DELETE method handler.

* onLoopBegin() - hook on loop start.
* onLoopEnd() - hook on loop end.
* onConnect() - hook on connection established.  Provides the callback with the IO::Socket::INET object.
* onNoConnection() - hook on no-connections received.

* run() - runs the loop event.  

### Net::REST::Request
* uri - the raw uri of the request
* path - the interpreted path of the request.
* query - the query portion of the request.
* params - any passed parameters on the request line.
* error - message of the error encountered.
* method - request method.
* version - HTTP request version.
* headers - HTTP headers of the request.

### Net::REST::Response
* type - the content-type shortcut of the response.
* headers - HTTP headers to respond with.
* status - HTTP status code to respond with.

* write($body, $args) - respond with $body as the payload.  $args is a hash reference to include with the response, like the *type* shortcut or to provide headers.

* begin($args) - begin a response with **Encoding-Type: chunked**.  $args is a hash reference to include with the response, like the *type* shortcut or to provide headers.

* chunk($body) - send the next payload chunk.  Send and empty chunk() call to end the chunked-type encoding.
