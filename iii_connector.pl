#########################################################################################
# iii_connector.pl
# A small Perl program that connects a FreeRADIUS server to the III Millennium PatronAPI.
#
# --
#
# Copyright (c) 2011, Chris Wells <chris@recklesswells.com>
# All rights reserved. 
#
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met: 
#
#  * Redistributions of source code must retain the above copyright notice, 
#    this list of conditions and the following disclaimer. 
#  * Redistributions in binary form must reproduce the above copyright 
#    notice, this list of conditions and the following disclaimer in the 
#    documentation and/or other materials provided with the distribution. 
#  * Neither the name of Genesee District Library nor the names of its 
#    contributors may be used to endorse or promote products derived from 
#    this software without specific prior written permission. 
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.

use strict;

use vars qw(%RAD_REQUEST %RAD_REPLY %RAD_CHECK);
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Request;
use DateTime;

# Timezone
# Ex: my $TIMEZONE =  "America/Detroit";
my $TIMEZONE = "";

# configuration constants used below
my $CENTURY = 2000;

# The following should be set to the base URL for your PatronAPI
# Ex: my $BASEURL = "http://library.thegdl.org:4500";
my $BASEURL = "";

# The following is used in the 'authorize' section below
my $MAX_FINE = 3.99;

# Constants used for expected FreeRADIUS responses
# immediately reject the request
use constant RLM_MODULE_REJECT	=>	0;
# module failed, don't reply
use constant RLM_MODULE_FAIL	=>	1;
# the module is OK, continuing
use constant RLM_MODULE_OK	=>	2;
# the module handled the request, so stop
use constant RLM_MODULE_HANDLED	=>	3;
# the module considers the request invalid
use constant RLM_MODULE_INVALID	=>	4;
# reject the request, the user is locked out
use constant RLM_MODULE_USERLOCK=>	5;
# user not found
use constant RLM_MODULE_NOTFOUND=>	6;
# module succeeded without doing anything
use constant RLM_MODULE_NOOP	=>	7;
# OK (pairs modified)
use constant RLM_MODULE_UPDATED	=>	8;
# How many return codes there are
use constant RLM_MODULE_NUMCODES=>	9;

# global variable (should be left blank)
my $URL = '';

# function to handle authentication
sub authenticate {
	#my $poll_result = iii_request(iii_url($ARGV[0], $ARGV[1]));
	
	# poll server for authentication
	my $poll_result = iii_request(iii_url($RAD_REQUEST{'User-Name'}, $RAD_REQUEST{'User-Password'}));
	
	# parse the poll results
	if ($poll_result =~ /RETCOD=0/) {
		&radiusd::radlog(1, "User authenticated");
		$RAD_REPLY{'Reply-Message'} = "User authenticated";
		return RLM_MODULE_OK;
	} elsif ($poll_result =~ /RETCOD=1/) {
		&radiusd::radlog(1, "Incorrect pin");
		$RAD_REPLY{'Reply-Message'} = "Incorrect pin";
		return RLM_MODULE_REJECT;
	} elsif ($poll_result =~ /RETCOD=2/) {
		&radiusd::radlog(1, "No PIN found in patron record");
		$RAD_REPLY{'Reply-Message'} = "No PIN found in patron record";
		return RLM_MODULE_REJECT;
	} else {
		&radiusd::radlog(1, "Patron record not found.");
		$RAD_REPLY{'Reply-Message'} = "Patron record not found.";
		return RLM_MODULE_REJECT;
	}
}

# function to handle authorization
# this will need to be changed to reflect an individual
# institutions policies.
sub authorize {
	# poll for information from the server, just info dump
	my $poll_result = iii_request(iii_url($RAD_REQUEST{'User-Name'}));
	
	# BUG #1 - FIXED
	# We must check to see if any data was returned and return RLM_MODULE_REJECT if
	# we received nothing.  This is most likely due to an incorrect barcode being checked
	# and this fix will hopefully correct the SEGFAULT issue we are experiencing.
	if ($poll_result =~ /ERRNUM=1/) {
		&radiusd::radlog(1, "Patron record not found.");
		$RAD_REPLY{'Reply-Message'} = "Patron record not found.";
		return RLM_MODULE_REJECT;
	}
		
	# grab the pertinant bits out of our poll_results and test them.
	$poll_result =~ /\[p96\]=\$(\d\.\d{2})/;
	my $money_due = $1;
	
	# please note that the PATRONAPI returns the year in two-digits.  This shouldn't be an issue,
	# but in a hundred years change $CENTURY above.
	$poll_result =~ /\[p43\]=(\d{2})-(\d{2})-(\d{2})/;
	my $expiration_date = DateTime->new(
		year 	=> $3+$CENTURY,
		month 	=> $1,
		day		=> $2,
		time_zone	=> $TIMEZONE,
	);
	
	my $manual_block = '';
	if ($poll_result =~ /\[p56\]=\-/) {
		$manual_block = 0;
	} else {
		$manual_block = 1;
	}

	if ($money_due > $MAX_FINE) {
		&radiusd::radlog(1, "Patron fines in excess of \$" . $MAX_FINE);
		$RAD_REPLY{'Reply-Message'} = "Patron fines in excess of \$" . $MAX_FINE;
		return RLM_MODULE_REJECT;
	}

	if ($expiration_date <= DateTime->today()) {
		&radiusd::radlog(1, "Patron account is expired");
		$RAD_REPLY{'Reply-Message'} = "Patron account is expired, please ask a librarian for assistance.";
		return RLM_MODULE_REJECT;
	}

	if ($manual_block) {
		&radiusd::radlog(1, "Manual block in effect for given patron.");
		$RAD_REPLY{'Reply-Message'} = "Authorization failed, please ask a librarian for assistance.";
		return RLM_MODULE_REJECT;
	}

	# This patron passes muster and may proceed to authentication
	&radiusd::radlog(1, "Patron Authorized");
	$RAD_REPLY{'Reply-Message'} = "Authorization succeded.";
	return RLM_MODULE_OK;
}

# function to handle accounting
# NOT YET IMPLEMENTED
sub accounting {
	return RLM_MODULE_OK;
}

sub iii_url {
	# grab function arguments
	my $barcode = @_[0];
	my $pin = @_[1];
	
	$URL = $BASEURL . "/PATRONAPI/" . $barcode . '/';
	
	if ($pin) {
		$URL = $URL . $pin . '/pintest';
	}
	else {
		$URL = $URL . 'dump';
	}

	# return the formed URL
	$URL;
}

sub iii_request {
	my $agent = LWP::UserAgent->new(env_proxy => 1, keep_alive => 1, timeout => 30);
	my $header = HTTP::Request->new(GET => $URL);
	my $request = HTTP::Request->new('GET' => $URL, $header);
	my $response = $agent->request($request);

	#check the response
	if ($response->is_error) {
		print "ERROR iii_connector: $response->error_as_string\n";
		exit;
	}
	$response->content;
}
