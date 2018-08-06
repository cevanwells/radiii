#!/bin/sh
set -e

RADDB=/etc/raddb

# tack on a new RADIUS client in clients.conf
echo "
client iii_radius_client {
	ipaddr		= $RADIII_CLIENT_IP
	secret		= $RADIII_CLIENT_SECRET
}" > $RADDB/clients.conf

exec "$@"
