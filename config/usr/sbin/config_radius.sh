#!/bin/sh
set -x
set -e
#
# Docker build calls this script to configure FreeRADIUS during build.

RADDB=/etc/raddb

# disable unecessary modules
BAD_MODS="always cache_eap chap dhcp dynamic_clients exec expiration logintime mschap ntlm_auth pap passwd radutmp realm soh sradutmp unix unpack attr_filter digest expr linelog detail detail.log files echo date replicate"
for mod in ${BAD_MODS}; do
	rm $RADDB/mods-available/$mod;
done

# enable the rlm_perl module
ln -s $RADDB/mods-available/perl $RADDB/mods-enabled/perl

# configure rlm_perl to use our iii_radius.pl file
sed -i "s|example.pl|radiii.pl|g" $RADDB/mods-available/perl

# disable the inner-tunnel and default sites
rm $RADDB/sites-enabled/inner-tunnel
rm $RADDB/sites-enabled/default

# enable iii_radius site
ln -s $RADDB/sites-available/radiii $RADDB/sites-enabled/radiii

# remove request proxying
sed -i '/proxy_requests  = yes/s/^/#/g' $RADDB/radiusd.conf
sed -i '/$INCLUDE proxy.conf/s/^/#/g' $RADDB/radiusd.conf

# tack on a new RADIUS client in clients.conf. We need to figure out how to
# abstract this out into an ENV variable for config.
echo "
client iii_radius_client {
	ipaddr		= 172.18.0.0/24
	secret		= testing123
}" >> $RADDB/clients.conf