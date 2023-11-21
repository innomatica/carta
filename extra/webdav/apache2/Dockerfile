FROM httpd:alpine

# config files
COPY ./httpd.conf /usr/local/apache2/conf/httpd.conf
COPY ./httpd-dav.conf /usr/local/apache2/conf/extra/httpd-dav.conf

# password file (use bind mount instead)
COPY ./user.passwd /usr/local/apache2/user.passwd
RUN chown www-data:www-data /usr/local/apache2/user.passwd

# davlock directory
RUN mkdir -p /usr/local/apache2/var/DavLock
RUN chown -R www-data:www-data /usr/local/apache2/var

# webdav target directory
RUN mkdir -p /usr/local/apache2/webdav
RUN chown www-data:www-data /usr/local/apache2/webdav
