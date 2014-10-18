#!/usr/bin/perl

use strict;

use lib 'lib/perl5';
use Net::REST;

sub helloworld {
	my ($request, $response) = @_;

	$response->write("hello world!");
}

my $app = new Net::REST({ port => 2020 });

$app->get("/hello", \&helloworld);

$app->get('/test', sub {
	my ($req, $res) = @_;

	$res->begin();

	foreach my $p (keys %{ $req->params }) {
		$res->chunk(sprintf("%s => %s\n", $p, $req->params->{$p}) );
	}

	$res->chunk("", 1);
});
		

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
