# Note

This server uses internal SQLite as a database. It should be enough to serve
your data via WebDAV for media consumption. If what you are thinking is a full
featured NextCloud instance, please consider a separate SQL database.

Setting up is a two step process:

* Initialize Nextcloud instance
* Copy media directory under the user's file folder

# Set Up

Run
```
bash setup.sh
```
and enter the step (1) parameters.

Bring up the Nextcloud server
```
docker compose up -d
```
and finish the intialization

Come back to the setup script and proceed to the step (2).

# Carta Settings

Use following parameters

* title: (any title of your choice)
* site url: (server domain name)
* username / password: (as entered above)
* directory: remote.php/dav/files/(username)/Media
