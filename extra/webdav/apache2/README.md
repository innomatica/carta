# Apache WebDAV Server


## Set up and Launch

Run
```
bash setup.sh
```

This will generate following files:

* `.env`
* `httpd.conf`
* `user.passwd`

Then launch server
```
docker-compose up -d
```

## Carta Settings

Note that your media directory will be mounted at `/usr/local/apache2/webdav`
and will be served at `{your server url}/webdav`

Use following parameters

* title: (any title of your choice)
* server type: webdav
* username / password: (as created above)
* site url: {server url}/webdav

## Note

`mod_dav` may not work with certain versions of `apach2` especially recent ones.
Try other versions in such occasion.

## Reference

* [Apache Module mod_dav](https://httpd.apache.org/docs/2.4/mod/mod_dav.html)
* [Authentication and Authorization](https://httpd.apache.org/docs/2.4/howto/auth.html)
