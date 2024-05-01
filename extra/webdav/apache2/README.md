# Set up

Run
```
bash setup.sh
```

This will generate

* `.env`
* `httpd.conf`
* `user.passwd`


# Launch Server

Run
```
docker compose up -d
```

# Carta Settings

Note that your media directory will be mounted at `/usr/local/apache2/webdav`
and will be served at `{your server url}/webdav`

Use following parameters

* title: (any title of your choice)
* site url: (server domain name or IP address entered above)
* username / password: (as entered above)
* directory: webdav


# Reference

* [Apache Module mod_dav](https://httpd.apache.org/docs/2.4/mod/mod_dav.html)
* [Authentication and Authorization](https://httpd.apache.org/docs/2.4/howto/auth.html)
