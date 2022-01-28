#!/usr/bin/perl
##################################################
#  rtweather.pl 
#  Joe Jaworski 12-SEP-2013 v0.2    jj@joejaworski.com
#  This script gets the real time weather data and parses the template
#  file to produce the final html file that browsers can read. It can
#  be run as a cron job every minute or so.
#
#  Adapted from my original 2004 rtwheather.sh BASH script.
#
#################################################
require 5.003;
use warnings;
use strict;

my $weather_www = $ENV{'HOME'} . "/weather/weather-www";
my $weather_templates = "$weather_www/templates";

################  start of user variables #####################
my $vpweather	= $ENV{'HOME'} . "/weather/vproweather";			# path to vproweather
my $vpreplace	= $ENV{'HOME'} . "/weather/vproreplace";			# path to vproreplace
my $serport     = "/dev/ttyUSB0";
my $rtdata	= "$weather_templates/rtdata";				# vproweather raw real time data
my $wxdata	= "$weather_templates/wxdata";				# vproweather raw extended data
my $synopsis	= "$weather_templates/synopsis.txt";			# noaa synopsis scrape file
my $rttmplfile 	= "$weather_templates/index.tmpl";			# vproreplace template file
my $rtOutParse 	= "$weather_templates/rt1.tmpl";			# output realtime html file parse 
my $rtOutParse2	= "$weather_templates/rt2.tmpl";			# output realtime html file parse 
my $rtOutWeb	= "/var/www/weather/index.html";			# output realtime html file web

my $tmplfile1	= "$weather_templates/temp.tmpl";			# template file-1
my $outfile1	= "/var/www/weather/temp.html";				# html output file-1 
my $tmplfile2	= "$weather_templates/wind.tmpl";			# template file-2
my $outfile2	= "/var/www/weather/wind.html";				# html output file-2 
my $tmplfile3	= "$weather_templates/rain.tmpl";			# template file-3
my $outfile3	= "/var/www/weather/rain.html";				# html output file-3 
my @remserial	= ("/root/remserial-1.4/remserial", "-d", "-r", "192.168.0.8", "-p", "5001", "-l", "/dev/remserial1", "/dev/ptmx", "&");

################  end of user variables #####################

our $errOut;
my $FH;

unless (@ARGV == 1 && ($ARGV[0] eq "-r" || $ARGV[0] eq "-x"))
{
	&showOptions();						# must have a single command line option
	exit;
}

#&checkRS();								# check and restart remserial

if(&checkVPInst())						# check for vproweather running
{
	#failed- already running
	open($FH, '>', $rtOutWeb);
	print $FH $errOut;
	close($FH);
	exit;
}

if($ARGV[0] eq "-r")
{
	# Realtime data request
	if(&getRTdata())					# get real time data
	{
		open($FH, '>', $rtOutWeb);
		print $FH $errOut;
		close($FH);
		exit;
	}
			 
	# replace template data from rtdata
	if( &Replace($rttmplfile, $rtdata, $rtOutParse))
	{
		exit;
	}
	# run through wxdata
	if( &Replace($rtOutParse, $wxdata, $rtOutParse2))
	{
		exit;
	}
	# run through synopsis file
	if( &Replace($rtOutParse2, $synopsis, $rtOutWeb))
	{
		exit;
	}
	
}
else
{
	#Process extended data request (arg -x)
	if(&getRTdata())					# get real time data
	{
		open($FH, '>', $rtOutWeb);
		print $FH $errOut;
		close($FH);
		exit;
	}
			 
	if(&getWXdata())					# get extended data
	{
		open($FH, '>', $rtOutWeb);
		print $FH $errOut;
		close($FH);
		exit;
	}
	
	# replace fileset #1
	if( &Replace($tmplfile1, $wxdata, $outfile1))
	{
		exit;
	}
	# replace fileset #2
	if( &Replace($tmplfile2, $wxdata, $outfile2))
	{
		exit;
	}
	# replace fileset #3
	&Replace($tmplfile3, $wxdata, $outfile3);
}
exit;
	
		


#---------------------------------------------------------------------#
sub Replace
{
	# Run vproreplace on the passed parms
	# 0 = path to template file
	# 1 = path to raw data file (rtdata or wxdata)
	# 2 = path to output file 
	
	my $err = qx($vpreplace -t $_[0] -d $_[1] > $_[2]);
	if($err)
	{
		$errOut = "<html><body><h2>vprorelace error:<br>";
    	$errOut = $errOut . $err . "<br></h2></body></html>";

		return 1;
	}
	return 0;
}	


	

#---------------------------------------------------------------------#
sub getRTdata
{
	# gets the rtdata file via vproweather. Returns non-zero if failed.
	
	my $err = qx($vpweather -xt $serport > $rtdata);
	if($err)
	{
		$errOut = "<html><body><h2>RT Data Access Failure:<br>";
    	$errOut = $errOut . $err . "<br></h2></body></html>";
    	
		return 1;
	}
	return 0;
}


	
#---------------------------------------------------------------------#
sub getWXdata
{
	# gets the xtdata file via vproweather. Returns non-zero if failed.
	
	my $err = qx($vpweather -g -l $serport > $wxdata);
	if($err)
	{
		$errOut = "<html><body><h2>WX Data Access Failure:<br>";
    	$errOut = $errOut . $err . "<br></h2></body></html>";

		return 1;
	}
	return 0;
}

	
	
#---------------------------------------------------------------------#
sub showOptions
{
	# Display command line options
	
    print("\nweathproc v1.0 (c)2009 Joe Jaworski.\n");
    print("\nUsage: weathproc -r -x\n\n");
    print("Options:\n");
    print(" -r, process realtime data.\n");
    print(" -x, process extended data.\n");
}




#---------------------------------------------------------------------#
sub checkRS
{
	# if remserial is running, then return. else, start it up. You
	# can remove this function if you're not using remserial. What
	# this does is allow the task to be restarted after an AC power
	# failure- which sometimes causes a broken pipe and in turn, kills
	# the remserial process. So we restart it again if its not already
	# running.
	my $pid = qx(ps -C remserial -o pid=);
	
#	exec("/root/remserial-1.4/remserial", "-d", "-r", "192.168.0.8", "-p", "5001", "-s",
#		"-l", "/dev/remserial1", "/dev/ptmx", "&") unless $pid;
	exec("@remserial") unless $pid;
}		
	


#---------------------------------------------------------------------#
sub checkVPInst
{
	# if vproweather is already running, then we need to wait for it
	# to finish before starting another instance. We give up after
	# 20 seconds and return non-zero.

	my $pid = qx(ps -C vproweather -o pid=);
	if ($pid)
	{
		# vproweather is running
		my $cnt = 20;							# give it 20 secs to stop					
		while($cnt--)
		{
			sleep(1);
			$pid = qx(ps -C vproweather -o pid=);	# check again
			unless ($pid)
			{
				return;								# okay, it stopped
			}
		}
		# vproweather is still running after 20 sec wait
		$errOut = "<html><body><h2>Error: vproweather multiple instances." .
			"<br><br></h2></body></html>";
		return 1;
	}
	return 0;
}	
		
