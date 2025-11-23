# FTP Server for Local Development Environments

![Docker Logo](https://www.gravatar.com/avatar/def8e498c0e2b4d1b0cb398ca164cddd?s=115)

**Disclaimer:** This container was created with a local development environment in mind and
therefore may not be very secure.

This Docker container implements a vsftpd server, with the following features:

 * Debian:jesse base image.
 * Virtual users with the ability to specify home directory and system user ID
 * Passive mode

The compiled versions of this container can be found in the
[Docker registry](https://hub.docker.com/r/wildscamp/vsftpd/).

Environment variables
----

This image uses environment variables to allow the configuration of some parameters at run time:

`VSFTPD_USER_[0-9]+`

* **Accepted values:** A string in the format `<username>:<password>:<system_uid>:<ftp_root_dir>`.
  The `<system_uid>` and `<ftp_root_dir>` are optional, but the separating colons must still
  exist.
* **Description:** These are compound variables that allow for addition of any number of users.

_Examples_

* `VSFTPD_USER_1=hello:world::` - Create a user named **hello** with a password of **world**. The
  system user's UID will be the same as that of the built-in `ftp` account (UID: `104`) and
  the FTP user's root directory will default to `/home/virtual/hello`.
* `VSFTPD_USER_1=user1:docker:33:` - Create a user named **user1** with a password of **docker**. The
  system user's UID will be **33** and the FTP user's root directory will default to
  `/home/virtual/user1`. If a system user with that ID already exists, vsftpd will tie that
  existing user to this user.
* `VSFTPD_USER_1=mysql:mysql:999:/srv/ftp/mysql` - Create a user named **mysql** with a password
  of **mysql**. The system user's UID will be **999** and the FTP user's root directory will be
  set to `/srv/ftp/mysql`.

_Caveats_

* vsftpd apparently has special handling of an FTP user with the name `ftp`, so it's
  recommended to not use this name when defining an FTP user.

----

`PASV_ADDRESS`

* **Accepted values:** DNS name or IP address that you use to FTP into this container.
* **Description:** This tells vsftpd which address to advertise to FTP clients as its address
  for passive connections. It's recommended to set this as an IP address since the container
  may not have the same DNS lookup settings as the Docker host.
* **Note:** If this is not specified, FTP communication most likely will not work as vsftpd
  will automatically use the IP of the interface on which the connection was received and that
  IP will usually be internal to the docker container.

_Common Values_

| Environment        | IP             | Comment                   |
|--------------------|----------------|---------------------------|
| Docker for Windows | 10.0.75.1      | Default Hyper-V host IP   |
| boot2docker        | 192.168.99.100 | Default docker-machine IP |

----

`PASV_MIN_PORT`

* **Default value:** 30000
* **Accepted values:** an integer less than `PASV_MAX_PORT`.
* **Description:** The minimum port to use for passive connections.

----

`PASV_MAX_PORT`

* **Default value:** 30009
* **Accepted values:** an integer that is greater than `PASV_MIN_PORT`.
* **Description:** The minimum port to use for passive connections.

Ports
----

vsftpd is configured to listen on port `21`. The container will need to open that port up as well
as the range of passive ports (defaults of `30000-30009`).

Volumes
----

By default, a user is given an FTP home directory of `/home/virtual/${username}`. Any volumes
that you want a user to access should be mounted underneath the user's home folder. 

_Considerations_

1. It's important that these are not mounted directly to the user's home directory but instead
   to a sub-directory of the user's home directory. The reason for this is because the user
   does not have write permissions in the root of their home directory.
2. Any folder that is mounted must already have the same permissions as the system user that
   the FTP user is operating under. So, if the we define a `VSFTPD_USER_1=user1:pass:33:`, then
   the mounted folders must be owned by a user with ID of `33` for the FTP user to access it.

### Named Volumes

Folders that are mounted directly from the host computer are orders of magnitude slower than
named volumes. That is one of the reasons (a big one) to use named volumes instead of shared
folders from the host.

Named volumes work nicely with this container. Docker supports the ability to mount the same
named volumes to multiple containers at the same time. So, your application data is stored
in a named volume and that same volume can be attached to this container to present FTP
access to that data. That is one of the main reasons this container was created.

_Example_

```bash
  # create the volume
  docker volume create --name html-data
  
  # start the FTP daemon connected to the 'html-data' volume
  docker run --rm -d --name vsftpd \
       -v html-data:/home/virtual/hello/html \
       -e "PASV_ADDRESS=10.0.75.1" \
       -e "VSFTPD_USER_1=hello:world::" \
       -p "21:21" -p "30000-30009:30000-30009" \
       -t wildscamp/vsftpd
  
  # start the application that uses the 'html-data' volume
  docker run --rm -i --name webapp \
       -v html-data:/var/www/html \
       -t debian:jesse /bin/bash
```

You'll notice that both containers are given the same named volume but mounted in different
locations. If one container changed something in the named volume, that change will be
reflected in the other container.

Use cases
----

1) Spin up an the FTP server with a user named **hello**, password of **world** and mount a
   named volume under **hello**'s FTP root directory:

```bash
  docker run --rm --name vsftpd -i \
    -v docker-html:/home/virtual/hello/html \
    -e "PASV_ADDRESS=10.0.75.1" \
    -e "VSFTPD_USER_1=hello:world::" \
    -p "21:21" -p "30000-30009:30000-30009" \
    -t wildscamp/vsftpd
```

2) Create multiple users with access to different volumes:

```bash
  docker run --rm --name vsftpd -i \
    -v docker-html:/home/virtual/hello/html \
    -v docker-mysql:/home/virtual/mysql/mysql \
    -e "PASV_ADDRESS=10.0.75.1" \
    -e "VSFTPD_USER_1=hello:world:33:" \
    -e "VSFTPD_USER_2=mysql:mysql:999:" \
    -p "21:21" -p "30000-30009:30000-30009" \
    -t wildscamp/vsftpd
```

User Environment Variables and Docker Compose
----

There is one special consideration regarding the `VSFTPD_USER_[0-9]+` environment variables
and Docker Compose. If you do not specify a root directory in a user configuration variable,
the variable will end with a `:` and that has special meaning in a YAML file. In this case,
it is necessary to define the environment variables using the
[dictionary method](https://docs.docker.com/compose/compose-file/#/environment)
as demonstrated here.

```yaml
  services:
    vsftpd:
      container_name: vsftpd
      image: wildscamp/vsftpd
      hostname: vsftpd
      ports:
        - "21:21"
        - "30000-30009:30000-30009"
      volumes:
        - docker-html:/home/virtual/www-data/html
        - docker-certificates:/home/virtual/certs/certs
        - docker-mysql:/home/virtual/mysql/mysql
      environment:
        PASV_ADDRESS: 10.0.75.1
        PASV_MIN_PORT: 30000
        PASV_MAX_PORT: 30009
        VSFTPD_USER_1: 'www-data:ftp:33:'
        VSFTPD_USER_2: 'mysql:mysql:999:'
        VSFTPD_USER_3: 'certs:certs:50:'
```