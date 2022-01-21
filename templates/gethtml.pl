#!/usr/bin/perl
use warnings;
use strict;
use LWP::UserAgent;
my $ua = LWP::UserAgent->new;
$ua->timeout(10);

my $response = $ua->get("http://www.wunderground.com/DisplayDisc.asp?DiscussionCode=GSP&StateCode=NC&SafeCityName=Candler");

if ($response->is_success)
{
    open(my $FH, ">/root/weather/synopsis.txt");
    print $FH "noaa_synopsis = ";

    if($response->content =~ m/Synopsis...(.*?)&&/gsm)
    {
	   	my $raw = $1;
	   	$raw =~ s/[\r\n]//g;
	   	print $FH $raw;
	   	close($FH);
    }
}   

exit;

