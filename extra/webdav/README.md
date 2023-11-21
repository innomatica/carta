# WebDAV Server

You can setup a WebDAV server quickly using one of the settings here.
Note that the they did not configured to handle SSL/TLS themselves.
Thus you will need to have a reverse proxy of your own if you use them as are.
Alternatively you can customze the settings to handle SSL/TLS.

In each case, use `setup.sh` to do the configuration and use `docker compose`
to run the server.

## `apache2`

Based on Apache2 httpd docker image, its memory footprint is small and runs
fast. Thus it should work well on smaller embedded machines like Raspberry Pis.

## `nextcloud`
Based on Nextcloud community docker image. It requires better hardware.


