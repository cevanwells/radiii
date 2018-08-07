FROM alpine:3.7
MAINTAINER Chris Wells <chris@wells.io>

ENV RADIUS_VER=3.0.15-r3 

# install necessary packages
RUN apk add --no-cache --update \
	freeradius=${RADIUS_VER} \
	freeradius-perl=${RADIUS_VER} \
	openssl \
	perl \
	perl-datetime \
	perl-libwww

# copy any configs and scripts into their proper locations
COPY config /
COPY docker-entrypoint.sh /usr/local/bin/

# configure RADIUS installation
RUN /usr/sbin/config_radius.sh \
    && chmod +x /usr/local/bin/docker-entrypoint.sh \
	&& find /etc/raddb -exec chgrp -h radius {} +

EXPOSE 1812/udp

USER radius
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/sbin/radiusd", "-f", "-l", "stdout"]
