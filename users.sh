#!/bin/env bash

# clear the old config env
for VARIABLE in $(env); do
	if [[ "${VARIABLE}" =~ ^VSFTPD_USER_[[:digit:]]+=.*$ ]]; then
		ENV_VAL="$(echo ${VARIABLE} | cut -d'=' -f2)"
		
		if [ "$(echo ${ENV_VAL} | awk -F ':' '{ print NF }')" -ne 4 ]; then
            		echo "'${ENV_VAL}' user has invalid syntax. Skipping."
            		continue
        	fi
		ENV_NAME="$(echo ${VARIABLE} | cut -d'=' -f1)"
		ENV_NAME=`eval echo '$'"${ENV_NAME}"`
		echo $ENV_NAME
		unset ENV_NAME
		echo 'new env:'$ENV_NAME
	fi
done

# add the new config env, we need only to modify below
export VSFTPD_USER_1=admin:admin::
export VSFTPD_USER_2=upload:upload::
export VSFTPD_USER_3=download:download::
