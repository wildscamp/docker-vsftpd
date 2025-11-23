# `vsftpd` FTP Server for Docker

**Note on Security:** This container has been developed primarily
for **local and development environments** and should not be used in
a production environment without rigorous security review and
customisation.

This Docker image provides a **vsftpd** server, incorporating the
following core features:

* Based on the official **`debian:bookworm-slim`** image.
* Support for **Virtual Users**, allowing the specification of a
    custom home directory (`local_root`) and associated system user
    ID (`FTP_UID`).
* **Passive Mode (PASV)** support is included.

The pre-built image can be found on the **Docker registry** at
[`alexs77/vsftpd`](https://www.google.com/search?q=%5Bhttps://hub.docker.com/r/alexs77/vsftpd/%5D\(https://hub.docker.com/r/alexs77/vsftpd/\)).

-----

### **Attribution**

This work is based on the foundation laid by
**[wildscamp/docker-vsftpd](https://github.com/wildscamp/docker-vsftpd)**.
For reference, their Docker registry page is available at
**[`wildscamp/vsftpd`](https://www.google.com/search?q=%5Bhttps://hub.docker.com/r/wildscamp/vsftpd/%5D\(https://hub.docker.com/r/wildscamp/vsftpd/\))**.

-----

## **Table of Contents**

* [`vsftpd` FTP Server for Docker](#vsftpd-ftp-server-for-docker)
  * [**Attribution**](#attribution)
  * [**Table of Contents**](#table-of-contents)
  * [**Configuration**](#configuration)
    * [**Environment Variables**](#environment-variables)
      * [`VSFTPD_USER_[0-9]+`](#vsftpd_user_0-9)
        * [Examples](#examples)
        * [Caveats](#caveats)
      * [`PASV_ADDRESS`](#pasv_address)
        * [Common Values](#common-values)
      * [`PASV_MIN_PORT`](#pasv_min_port)
      * [`PASV_MAX_PORT`](#pasv_max_port)
  * [**Ports**](#ports)
  * [**Volumes**](#volumes)
    * [**Considerations**](#considerations)
    * [**Named Volumes**](#named-volumes)
  * [**Example Deployment**](#example-deployment)
  * [**Using Environment Variables with Docker
    Compose**](#using-environment-variables-with-docker-compose)
  * [**Links**](#links)

-----

## **Configuration**

This image supports run-time configuration via standard
**environment variables**.

### **Environment Variables**

#### `VSFTPD_USER_[0-9]+`

These are **compound variables** that enable the addition of an
arbitrary number of virtual FTP users.

* **Accepted format:** A string in the format
    `<username>:<password>:<system_uid>:<ftp_root_dir>`.
* **Description:** The `<system_uid>` and `<ftp_root_dir>`
    parameters are optional, but the separating colons (`:`) must be
    maintained. If the system user ID is omitted, it defaults to the
    UID of the built-in `ftp` account (`104`). If the root directory
    is omitted, it defaults to `/home/virtual/<username>`.

##### Examples

* `VSFTPD_USER_1=hello:world::` - Creates an FTP user **hello** with
    the password **world**. The system user's UID will default to
    `104`, and the FTP root directory will be `/home/virtual/hello`.
* `VSFTPD_USER_1=user1:docker:33:` - Creates an FTP user **user1**
    with the password **docker**. The system user's UID will be
    **33**. If a system user with this ID already exists, the FTP
    user will be mapped to it. The FTP root directory defaults to
    `/home/virtual/user1`.
* `VSFTPD_USER_1=mysql:mysql:999:/srv/ftp/mysql` - Creates an FTP
    user **mysql** with the password **mysql**. The system user's
    UID is **999**, and the FTP root directory is explicitly set to
    `/srv/ftp/mysql`.

##### Caveats

* **Reserved Username:** vsftpd applies special handling to the FTP
    username `ftp`. It is therefore recommended to avoid using this
    name when defining a virtual FTP user.
* **Writable Root:** The container configures
    `allow_writeable_chroot=YES` in the default user configuration.

#### `PASV_ADDRESS`

* **Accepted values:** The DNS name or IP address used by the FTP
    client to connect to this container.
* **Description:** This variable instructs vsftpd as to which
    address it should advertise to clients for passive mode data
    connections. Setting an IP address is recommended, as the
    container's DNS resolution may not be identical to the Docker
    host's.
* **Note:** If this parameter is not specified, FTP communication
    may fail. vsftpd will automatically advertise the internal
    Docker IP of the interface on which the connection was received,
    which is usually unreachable from the client host.

##### Common Values

| Environment | IP | Comment |
| :--- | :--- | :--- |
| Docker for Windows | `10.0.75.1` | Default Hyper-V host IP |
| boot2docker | `192.168.99.100` | Default `docker-machine` IP |

#### `PASV_MIN_PORT`

* **Default value:** `30000`
* **Accepted values:** An integer lower than `PASV_MAX_PORT`.
* **Description:** The minimum port number to be used for passive
    connections.

#### `PASV_MAX_PORT`

* **Default value:** `30009`
* **Accepted values:** An integer higher than `PASV_MIN_PORT`.
* **Description:** The maximum port number to be used for passive
    connections.

-----

## **Ports**

The container exposes the following ports:

* **Port 20/tcp:** FTP Data (Active Mode)
* **Port 21/tcp:** FTP Control (Command Channel)
* **Ports 30000-30009/tcp:** Passive Mode (PASV) data ports. This
    range is defined by the default values for `PASV_MIN_PORT` and
    `PASV_MAX_PORT`.

When running the container, ensure all necessary ports are published
to your host machine using the `-p` flag or in your
`docker-compose.yaml`.

-----

## **Volumes**

For the FTP server to be useful, a minimum of one data volume should
be mounted.

* **Data Directories:** The FTP user's root directory must be
    mounted from the host system or a named volume. For example, a
    user with `local_root=/home/virtual/user1` will require a volume
    mount at `/home/virtual/user1` inside the container.
* **Log Directory:** The container writes logs to `/var/log/vsftpd`.
    It is recommended to mount this directory to retain logs outside
    of the container lifecycle.
* **Configuration Overrides:** An individual user's configuration
    can be overridden by mounting a vsftpd configuration file to
    `/etc/vsftpd/vusers/<username>`. Global default settings can be
    overridden by mounting a file to
    `/etc/vsftpd/default_user.conf`.

### **Considerations**

When mounting host folders, the directory mounted must possess the
correct permissions. The directory owner/group IDs on the host must
match the **system user ID** (`FTP_UID`) that the FTP user is
operating under. For instance, if `VSFTPD_USER_1=user1:pass:33:` is
defined, any mounted folders must be owned by the user with UID `33`
on the host for the FTP user to access them.

### **Named Volumes**

Using **named volumes** offers a significant performance advantage
over direct host-to-container shared folder mounting. Named volumes
are fully supported and can be concurrently attached to multiple
containers, enabling data sharing between this FTP server and other
application containers (e.g., a web server or database).

-----

## **Example Deployment**

A simple deployment, using the default user configuration, can be
launched with `docker run` :

```bash
docker run -d \
    --name vsftpd \
    -e "PASV_ADDRESS=<Your_External_IP>" \
    -e "VSFTPD_USER_1=hello:world:33:/var/www/html" \
    -e "VSFTPD_USER_2=mysql:mysql:999:/var/lib/mysql" \
    -v /path/to/host/html:/var/www/html \
    -v /path/to/host/mysql:/var/lib/mysql \
    -p "20-21:20-21" \
    -p "30000-30009:30000-30009" \
    --restart=always \
    alexs77/vsftpd
```

For more complex or multi-container setups, a `docker-compose.yaml`
file is recommended:

```yaml
services:
  vsftpd:
    image: alexs77/vsftpd
    container_name: vsftpd
    restart: always
    env_file:
      - .env
    ports:
      - "20-21:20-21"
      - "30000-30009:30000-30009"
    environment:
      LOG_STDOUT: "Yes"
    volumes:
      - ftp-home:/home/virtual
      - ftp-srv:/srv/ftp
      - ./logs:/var/log/vsftpd
      - ./conf/default_user.conf:/etc/vsftpd/default_user.conf:ro

volumes:
  ftp-srv:
    name: ftp-srv
    external: true
  
  ftp-home:
    name: ftp-home
    external: true
```

-----

## **Using Environment Variables with Docker Compose**

A crucial consideration for the **`VSFTPD_USER_[0-9]+`** environment
variables within a `docker-compose.yaml` is the optional nature of
the final parameter (the root directory). If the final parameter is
omitted, the variable string will end with a colon (`:`), which has
a specific interpretation in the YAML format (representing a
dictionary key without a value).

To correctly define these variables when the root directory is not
specified, you **must** use the explicit *dictionary method* for
environment variables, as illustrated below, or use an external
`.env` file:

```yaml
  services:
    vsftpd:
      # ... other configuration ...
      environment:
        PASV_ADDRESS: 10.0.75.1
        VSFTPD_USER_1: "hello:world:33:"
        # Note the quotes around the value to prevent YAML parsing errors.
```

-----

## **Links**

* **GitHub Repository:**
    [`alexs77/docker-vsftpd`](https://www.google.com/search?q=%5Bhttps://github.com/alexs77/docker-vsftpd%5D\(https://github.com/alexs77/docker-vsftpd\))
    (You are here)
* **Docker Registry:**
    [`alexs77/vsftpd`](https://www.google.com/search?q=%5Bhttps://hub.docker.com/r/alexs77/vsftpd/%5D\(https://hub.docker.com/r/alexs77/vsftpd/\))
    (Assumed)

This video provides a quick demonstration on setting up an FTP
server with Docker, which is directly relevant to this repository.
[How to Setup FTP Server within 15
Seconds](https://www.youtube.com/watch?v=iadE-Px-aYQ)

<http://googleusercontent.com/youtube_content/0>
