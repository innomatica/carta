FROM alpine:3.19

ARG LIGHTTPD_VERSION=1.4.76-r0

RUN set -x \
    && apk add --no-cache \
    lighttpd${LIGHTTPD_VERSION:+=}${LIGHTTPD_VERSION} \
    lighttpd-mod_auth${LIGHTTPD_VERSION:+=}${LIGHTTPD_VERSION} \
    lighttpd-mod_webdav${LIGHTTPD_VERSION:+=}${LIGHTTPD_VERSION} \
	sqlite${SQLITE_VERSION:+=}${SQLITE_VERSION} \
    && rm -rvf /etc/lighttpd/* /etc/logrotate.d/lighttpd /var/log/lighttpd/* \
	&& mkdir -vp /var/lib/lighttpd/db \
	#&& sqlite3 /var/lib/lighttpd/db/dav.sqlite3 "VACUUM;" \
	&& chown -vR lighttpd:lighttpd /var/lib/lighttpd/db

COPY config/ /etc/lighttpd/

EXPOSE 80/tcp

ENTRYPOINT ["/usr/sbin/lighttpd"]
CMD ["-D", "-f", "/etc/lighttpd/lighttpd.conf"]
