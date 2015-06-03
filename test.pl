#!/usr/bin/perl

use strict;

use lib 'lib/perl5';
use Data::Dumper;
use Net::REST;

sub helloworld {
	my ($request, $response) = @_;

    my $subject = $request->params->{name} || 'world';

    print Dumper $request;

	$response->write("hello $subject!");
}

my $app = new Net::REST({ port => 2020 });

$app->get("/hello", \&helloworld);

$app->get("/hello/:name", \&helloworld);

$app->get("/hello2/:name/:back", \&helloworld);

$app->get("/blah/*blah", sub {
    print Dumper @_;
});

$app->get('/test', sub {
	my ($req, $res) = @_;

	$res->begin();

	foreach my $p (keys %{ $req->params }) {
		$res->chunk(sprintf("%s => %s\n", $p, $req->params->{$p}) );
	}

	$res->chunk("", 1);
});

$app->get('/same', sub {
	my ($req, $res) = @_;
	
	$res->write("/same with GET method", { type => 'text/text' });
});

$app->delete('/same', sub {
	my ($req, $res) = @_;
	
	$res->write("/same with DELETE method", { type => 'text/text' });
});

$app->post('/post', sub {
    my ($req, $res) = @_;

    print Dumper "Request:";
    print Dumper $req;

    $res->write("ok\n", { type => 'text/text' } );
});

$app->get('/hellojson/:name', sub {
    my ($req, $res) = @_;
    
    $res->json({ "hello" => $req->params->{name} });
});

$app->post('/echojson', sub {
    my ($req, $res) = @_;
    
    $res->json($req->json);
});

$app->onLoopBegin(sub { print "starting loop\n"; } );

$app->onLoopEnd(sub { print "ending loop\n"; } );

$app->onNoConnection(sub { print "nobody wants to play with me\n"; } );

$app->onConnect( sub { printf "%s:%s connected.\n", $_[0]->peerhost, $_[0]->peerport; } );
		

#$app->get("/hellojson/:name", sub {
#	my ($req, $res) = @_;
#
#	my $r = { hello => $req->params->{name} };
#
#	$res->writeJson($r);
#
#	# equivalent
#	# $res->write(json_encode($r), "application/json");
#	
#});

$app->run();
