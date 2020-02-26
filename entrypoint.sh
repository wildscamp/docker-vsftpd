#!/usr/bin/env bash

##
# Generate a random sixteen-character
# string of alphabetical characters
randname() {
    local -x LC_ALL=C
    tr -dc '[:lower:]' < /dev/urandom |
        dd count=1 bs=16 2>/dev/null
}

setfolderpermissions() {
    if [ $# -ne 2 ] || [ ! -e "$2" ] || [ -z "$(getent passwd $1)" ]; then
        echo "Set the permissions on a folder based on a user and it's associated group."
        echo "Usage: setfolderpermissions <username> <folder>"

        return 1
    fi

    # get the user's group to use when chowning the home directory
    usergroupid="$(getent passwd "$1" | cut -d':' -f4)"
    usergroup="$(getent group "$usergroupid" | cut -d':' -f1)"

    echo "Chown: $username:$usergroup $2" >> /etc/vsftpd/tmp.txt
    chown "$username:$usergroup" "$2"
}

createuser() {
    if [ $# -lt 1 ] || [ $# -gt 2 ]; then
        echo "Creates a system user (and group) from the given parameter if they don't exist."
        echo "Usage: createuser <id> [<name>] OR"
        echo "       createuser <name>"

        return 1
    fi

    username="$(getent passwd "$1")"

    # if a user exists already, lets get the username and make sure
    # the home directory exists with correct permissions.
    if [ ! -z "$username" ]; then
        # extract just the username portion
        username="$(echo $username | cut -d':' -f1)"

        # grab the user's home directory path
        homedir="$(getent passwd "$1" | cut -d':' -f6)"

        # make the home directory if it doesn't already exist
        if [ ! -z "$homedir" ] && [ ! -e "$homedir" ]; then
            mkdir -p "$homedir"
        fi

        setfolderpermissions "$username" "$homedir"
    else
        # no user exists with the given ID or name, so we need to create one.

        # check if we were given an ID
        if [[ "$1" =~ ^[0-9]+$ ]]; then
            if [ ! -z "$2" ] && [ -z "$(getent passwd "$2")" ]; then
                username="$2"
            else
                username=$(randname)
            fi

            # check if a group with the given user ID exists and
            # create one if one does not exist.
            groupid="$(getent group "$1" | cut -d':' -f3)"
            if [ -z "$groupid" ]; then
                addgroup --system --gid "$1" "$username" > /dev/null
                groupid="$1"
            fi

            adduser --system --uid="$1" --gid="$groupid" "$username" > /dev/null
        else
            # we were given a name
            groupid="$(getent group "$1" | cut -d':' -f3)"
            if [ -z "$groupid" ]; then
                addgroup --system "$username" > /dev/null
                groupid="$(getent group "$username" | cut -d':' -f3)"
            fi

            # make sure a user does not exist with the given group ID before setting
            # that user's UID to be the same as the group ID. If one does exist, we
            # just create a user with an automatic UID but assign the GID to be the
            # same as the group ID we identified above.
            if [ ! -z "$(getent passwd "$groupid")" ]; then
                adduser --system --gid="$groupid" "$username" > /dev/null
            else
                adduser --system --uid="$groupid" --gid="$groupid" "$username" > /dev/null
            fi
        fi
    fi

    # write out the username to be captured
    echo "$username"
}

setftpconfigsetting() {
    if [ $# -ne 3 ] || [ ! -e "$3" ]; then
        echo "Set an FTP configuration setting in the given file."
        echo "Usage: setftpconfigsetting <setting_hame> <setting_value> <config_file>"

        return 1
    fi

    if [ -z "$(grep -m1 -Gi "^${1}=" "$3")" ]; then
        echo "${1}=${2}" >> "$3"
    else
        sed -i "s~^${1}=.*~${1}=${2}~" "$3"
    fi
}

setftpconfigsetting "pasv_address" "$PASV_ADDRESS" /etc/vsftpd/vsftpd.conf
setftpconfigsetting "pasv_min_port" "$PASV_MIN_PORT" /etc/vsftpd/vsftpd.conf
setftpconfigsetting "pasv_max_port" "$PASV_MAX_PORT" /etc/vsftpd/vsftpd.conf

# make sure the passwd file exists
touch $PASSWD_FILE

cat << EOB
 *************************************************
 *                                               *
 *  Docker image: wildscamp/vsftpd               *
 *  https://github.com/wildscamp/docker-vsftpd   *
 *                                               *
 *************************************************

 SERVER SETTINGS
 ---------------
 . Log file: $LOG_FILE
 . Redirect vsftpd log to STDOUT: No.

EOB

for VARIABLE in $(env); do
    if [[ "${VARIABLE}" =~ ^VSFTPD_USER_[[:digit:]]+=.*$ ]]; then

        # remove VSFTPD_USER_:digit:= from beginning of variable
        VARIABLE="$(echo ${VARIABLE} | cut -d'=' -f2)"

        if [ "$(echo ${VARIABLE} | awk -F ':' '{ print NF }')" -ne 4 ]; then
            echo "'${VARIABLE}' user has invalid syntax. Skipping."
            continue
        fi

        VSFTPD_USER_NAME="$(echo ${VARIABLE} | cut -d':' -f1)"
        VSFTPD_USER_PASS="$(echo ${VARIABLE} | cut -d':' -f2)"
        VSFTPD_USER_ID="$(echo ${VARIABLE} | cut -d':' -f3)"
        VSFTPD_USER_HOME_DIR="$(echo ${VARIABLE} | cut -d':' -f4)"

        if [ -z "$VSFTPD_USER_NAME" ] || [ -z "$VSFTPD_USER_PASS" ]; then
            echo "'${VARIABLE}' is missing a username or password. Skipping."
            continue
        fi

        # add the user credentials to the vsftpd.passwd file
        entry="${VSFTPD_USER_NAME}:$(openssl passwd -1 "${VSFTPD_USER_PASS}")"
        sedr="s~^${VSFTPD_USER_NAME}.*~${entry}~"

        # check if the user exists already in the file
        if [ ! -z "$(grep -G -i "^${VSFTPD_USER_NAME}" $PASSWD_FILE)" ]; then
            sed -i "${sedr}" $PASSWD_FILE
        else
            printf "%s:%s\n" "$VSFTPD_USER_NAME" "$(openssl passwd -1 "$VSFTPD_USER_PASS")" >> "$PASSWD_FILE"
        fi

        USER_CONFIG_FILE="${USER_CONFIG_DIR}/${VSFTPD_USER_NAME}"

        cp $DEFAULT_USER_CONFIG "$USER_CONFIG_FILE"

        # pull the default username from the config file
        username="$(grep -Gi '^guest_username=' "$USER_CONFIG_FILE" | cut -d'=' -f2)"

        # set username to default if it's still not set to anything
        if [ -z "$username" ]; then
            username="ftp"
        fi

        # make sure the user ID is actually a number before setting it
        if [[ "$VSFTPD_USER_ID" =~ ^[0-9]+$ ]] ; then
            username="$(createuser "$VSFTPD_USER_ID" "$VSFTPD_USER_NAME")"
        else
            # make sure a system user exists for the username
            # that the new user is supposed to operate as.
            username="$(createuser "$username")"

            VSFTPD_USER_ID="$(getent passwd "$username" | cut -d':' -f3)"
        fi

        setftpconfigsetting "guest_username" "$username" "$USER_CONFIG_FILE"

        if [ -d "$VSFTPD_USER_HOME_DIR" ]; then
            setftpconfigsetting "local_root" "$VSFTPD_USER_HOME_DIR" "$USER_CONFIG_FILE"
        else
            usersubtoken="$(cat "$USER_CONFIG_FILE" /etc/vsftpd/vsftpd.conf | grep -m1 -Gi "^user_sub_token=" | cut -d'=' -f2)"
            VSFTPD_USER_HOME_DIR="$(cat "$USER_CONFIG_FILE" /etc/vsftpd/vsftpd.conf | grep -m1 -Gi "^local_root=" | cut -d'=' -f2)"

            if [ ! -z "$usersubtoken" ]; then
                VSFTPD_USER_HOME_DIR="$(echo $VSFTPD_USER_HOME_DIR | sed "s/$usersubtoken/$VSFTPD_USER_NAME/")"
            fi
        fi

        # make sure the virtual home directory exists
        if [ ! -d "$VSFTPD_USER_HOME_DIR" ]; then
            mkdir -p "$VSFTPD_USER_HOME_DIR"
        fi

cat << EOB
 USER SETTINGS
 ---------------
 . FTP User: $VSFTPD_USER_NAME
 . FTP Password: $VSFTPD_USER_PASS
 . System User: $username
 . System UID: $VSFTPD_USER_ID
 . FTP Home Dir: $VSFTPD_USER_HOME_DIR

EOB

    fi
done


# Trap code borrowed from https://github.com/panubo/docker-vsftpd/blob/master/entry.sh
function vsftpd_stop() {
  echo "Received SIGINT or SIGTERM. Shutting down vsftpd"
  # Get PID
  pid=$(cat /var/run/vsftpd/vsftpd.pid)
  # Set TERM
  kill -SIGTERM "${pid}"
  # Wait for exit
  wait "${pid}"
  # All done.
  echo "Done"
}

if [ "$1" == "vsftpd" ]; then
  trap vsftpd_stop SIGINT SIGTERM
  echo "Running $@"
  $@ &
  pid="$!"
  echo "${pid}" > /var/run/vsftpd/vsftpd.pid
  wait "${pid}" && exit $?
else
  exec "$@"
fi

copy -rf /data/ftp/vsftpd/* /etc/vsftpd/
