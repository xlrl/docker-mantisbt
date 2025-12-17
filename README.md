# Docker image for MantisBT

`MantisBT` is an open source issue tracker that provides
a delicate balance between simplicity and power.

## Example docker-compose.yml

The examples suppose you will have the data for your containers in `/srv/mantis`. Adapt for your server.

Note: make sure the credentials in the "docker-compose.yml" environment variables match this you supply in "install.php".

```yaml
services:
    mantisbt:
        image: xlrl/mantisbt:latest
        environment:
            MANTIS_TIMEZONE: Europe/Berlin
            MANTIS_ENABLE_ADMIN: 0
        ports:
            - "8989:80"
        volumes:
            - ./config:/var/www/html/config
            - ./custom:/var/www/html/custom
        restart: always

    mysql:
        image: mariadb:latest
        environment:
            MYSQL_ROOT_PASSWORD: root
            MYSQL_DATABASE: bugtracker
            MYSQL_USER: mantisbt
            MYSQL_PASSWORD: mantisbt
        volumes:
            - ./mysql:/var/lib/mysql
        restart: always
```

You can use `mysql`/`postgres` instead of `mariadb`.

## Install

Important: To be able to reach the "admin" directory, this has to be enabled with "MANTIS_ENABLE_ADMIN=1"

```bash
$ firefox http://localhost:8989/admin/install.php
>>> username: administrator
>>> password: root
```

```text
==================================================================================
Installation Options
==================================================================================
Type of Database                                        MySQL/MySQLi
Hostname (for Database Server)                          mysql
Username (for Database)                                 mantisbt
Password (for Database)                                 mantisbt
Database name (for Database)                            bugtracker
Admin Username (to create Database if required)         root
Admin Password (to create Database if required)         root
Print SQL Queries instead of Writing to the Database    [ ]
Attempt Installation                                    [Install/Upgrade Database]
==================================================================================
```

## Email

Append following to `/srv/mantis/config/config_inc.php`

```php
$g_phpMailer_method = PHPMAILER_METHOD_SMTP;
$g_administrator_email = 'admin@example.org';
$g_webmaster_email = 'webmaster@example.org';
$g_return_path_email = 'mantisbt@example.org';
$g_from_email = 'mantisbt@example.org';
$g_smtp_host = 'smtp.example.org';
$g_smtp_port = 25;
$g_smtp_connection_mode = 'tls';
$g_smtp_username = 'mantisbt';
$g_smtp_password = '********';
```

## LDAP

Append following to `/srv/mantis/config/config_inc.php` for LDAP
authentication against an Active Directory server:

```php
$g_login_method = LDAP;
$g_ldap_server = 'ldap://dc.example.com';
$g_ldap_root_dn = 'dc=example,dc=com';
$g_ldap_bind_dn = 'cn=readuser, dc=example, dc=com';
$g_ldap_bind_passwd = 'geheim123';
$g_ldap_organization = '';
$g_use_ldap_email = ON;
$g_use_ldap_realname = ON;
$g_ldap_protocol_version = 3;
$g_ldap_follow_referrals = OFF;
$g_ldap_uid_field = 'sAMAccountName';
```

## Upload size

By default, there is a mismatch of the maximum upload size between
mantis (=5MB) and php (=2MB). To mitigate this error, adapt the
mantis config the following.

```php
$g_max_file_size = 2 * 1024 * 1024;
```

Alternatively, the value for php can be adapted via `PHP_MAX_UPLOAD_SIZE` (default 2MB).
The php setting allows shortcuts for byte values, including K (kilo), M (mega) and G (giga).
Calculations like the example above won't work for the php parameter.
There is a dependency between upload_max_filesize and post_max_size (default 8MB).
`PHP_MAX_UPLOAD_SIZE` may not be set higher than 8M, otherwise further php config is necessary.

## Maintainers

This is the maintainer's section for this repository.

If you want to upgrade to a new mantis version `X.Y.Z` run the script `update-dockerfile.py`:

```sh
python3 update-dockerfile.py X.Y.Z
```

This will update the link and sha hash for the mantisbt source tarball and it will also try to find out the latest version the php base image (this makes the used base image tag explicit and adds transpaceny).

Build the new image and tag it:

```sh
docker build -t xlrl/mantisbt:X.Y.Z .
```

Run the image on your system or some test machine. Once you are satisfied with your tests, create the "latest" tag and push both tags:

```sh
docker tag X.Y.Z xlrl/mantisbt:X.Y.Z xlrl/mantisbt:latest
docker login
docker push xlrl/mantisbt:X.Y.Z
docker push xlrl/mantisbt:latest
```

Also do not forget the git commit and tags:

```sh
git add Dockerfile
git commit -m "Update to X.Y.Z"
git tag X.Y.Z
git push origin/main X.Y.Z
```

This should be all!
