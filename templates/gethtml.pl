#!/usr/bin/perl
use warnings;
use strict;
use LWP::UserAgent;
my $ua = LWP::UserAgent->new;
$ua->timeout(10);

my $response = $ua->get("https://forecast.weather.gov/product.php?site=PQR&issuedby=PQR&product=AFD&format=txt&version=1&glossary=1");

if ($response->is_success)
{
    open(my $FH, ">/home/pi/weather/weather-www/templates/synopsis.txt");
    print $FH "noaa_synopsis = ";

    if($response->content =~ m/SYNOPSIS...(.*?)&&/gsm)
    {
	   	my $raw = $1;
	   	$raw =~ s/[\r\n]/ /g;
	   	print $FH $raw;
	   	close($FH);
    }
}

exit;

