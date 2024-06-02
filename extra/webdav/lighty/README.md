# Lighttpd WebDAV Server

## Set Up

```bash
# create data directories
mkdir -p ./data/htdocs ./data/webdav ./data/config

# copy html docs (optional)
cp -a <your_html_docs> ./data/htdocs/

# copy webdav data
cp -a <your_webdav_data> ./data/webdav/

# create a password file with admin account
htpasswd -bc2 ./data/config/lighthttpd.user <admin> <admin_passwd>

# add user to the password file
htpasswd -b2 ./data/config/lighttpd.user <user> <user_passwd>
```

Note: `htpasswd` is a part of `apache2-utils` package. Alternatively, you can use openssl.
```
# using openssl
printf "{admin}:$(openssl passwd -5 {admin_passwd})\n" > ./data/config/lighttpd.user
printf "{user}:$(openssl passwd -5 {user_passwd})\n" >> ./data/config/lighttpd.user
```


## Build and Run

```bash
docker-compose build
docker-compose up -d
```

## Test

```bash
# WEB: access anonymously => get 401 unauthorized response
curl -X GET localhost:8080/dav

# WEB: access with credential => get 200 response
curl -X GET -u <user>:<user_passwd> localhost:8080/dav

# WebDAV: access anonymously => get 401 aunauthorized response
curl -X PROPFIND localhost:8080/dav -H "Depth: 1"
```


## Carta Settings

* title: (any title of your choice)
* server type: webdav
* username / password: (as created above)
* site url: {server url}/dav
