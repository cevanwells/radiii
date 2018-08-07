#!/bin/sh
set -e

RADDB=/etc/raddb

# tack on new RADIUS clients in clients.conf
n=`printenv | grep -i 'RADIII_CLIENT_IP' | wc -l`

for i in `seq 1 $n`
do
        ip_name="RADIII_CLIENT_IP${i}"
        secret_name="RADIII_CLIENT_SECRET${i}"
        echo "
        client iii_radius_client-$i {
                ipaddr          = $(eval echo \$$ip_name)
                secret          = $(eval echo \$$secret_name)
        }" > $RADDB/clients.conf
done

exec "$@"
