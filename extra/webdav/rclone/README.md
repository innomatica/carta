# Rclone WebDAV Server

Rclone can serve a local directory directly without setting up remote
```
rclone serve webdav --addr :{port} /{directory to serve}
```

## Set up and Launch

Open `compose.yml` and edit media directory and password file location
```
    volumes:
      - /var/mnt/webdav:/webdav:Z
      - ${PWD}/davpass:/config/rsync/davpass:Z
```

Note that the path of the WebDAV will be `{server ipv4:port}/webdav`.

To create a password file run `setup.py` or do it manually:
```
# MD5 with openssl (less secure)
printf "{username}:$(openssl passwd -1 {password})\n" >> {passwd file}

# APR1 with openssl
printf "{username}:$(openssl passwd -apr1 {password})\n" >> {passwd file}
```

Then launch server
```
docker-compose up -d
```

## Carta Settings


* title: (any title of your choice)
* server type: webdav
* username / password: (as created above)
* site url: {server url}/webdav
