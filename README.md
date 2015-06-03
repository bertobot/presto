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


# named parameters

$app->get('/phonebook/add/:name/:number', sub {
    my ($req, $res) = @_;

    my $message = sprintf "added %s => %s", $req->params->{name}, $req->params->{number};

    $res->write($message);

});


# blob parameter

# /blog/2014/10/31, date will be '2014/10/31'

$app->get('/blog/*date', sub {

    my ($req, $res) = @_;

    my $date = $req->params->{date};

    $res->write("date: $date");
});


# json example

$app->post('/json/post', sub {
        my ($req, $res) = @_;
        
        # request->json will attempt to json-decode request body

        my $json_hash = $req->json;

        # do something with that data
        
        # response->json is a wrapper of response->write where it 
        # json-encodes the payload, with a content-type of application/json

        $res->json({ 'status' => 'ok' });
});

$app->get('/json/get', sub {
        # lazy one liner
        $_[1]->json({ key => 'value', anotherKey => [] });
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
- JSON

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
* body - the content body, usually associated with POST, PUT and DELETE.
* json - if the body is a json object, it returns a hash representation (decoded json).


### Net::REST::Response
* type - the content-type shortcut of the response.
* headers - HTTP headers to respond with.
* status - HTTP status code to respond with.

* write($body, $args) - respond with $body as the payload.  $args is a hash reference to include with the response, like the *type* shortcut or to provide headers.

* begin($args) - begin a response with **Encoding-Type: chunked**.  $args is a hash reference to include with the response, like the *type* shortcut or to provide headers.

* chunk($body) - send the next payload chunk.  Send and empty chunk() call to end the chunked-type encoding.
* redirect($url) - redirect to the url provided, via HTTP 301.
* forward($url) - redirect to the url provided, via HTTP 302.
* json($hash) - encodes hash in json and writes it back to the client.
