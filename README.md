# vsftp docker image that support virtual users to use different config file
base: wildscamp/docker-vsftpd

# new changes:
(the belows is only functioned in this repo,because the modification and the PR not been merged to the master.)

# how to use this vsftp docker
```bash
  docker run -d --name vsftpd -i  \
  -v /data/ftp/files:/home/virtual \
  -v /data/ftp/vsftpd:/data/ftp/vsftpd \
  -v /data/ftp/log:/var/log/vsftpd \
  -e "PASV_ADDRESS=1.1.1.1" \
  -e "PASV_MIN_PORT=30000" -e "PASV_MAX_PORT=30009" \
  -p "21:21" -p "30000-30009:30000-30009" \
  -t hiproz/vsftpd
```

## Create multiple users with different config
- step 1: modify the users.sh to add the users who you want
- step 2: add or modify the ./vusers/[username] file, edit the access options that you can refer from the demo config file.
- step 3: set the update flag, [0] not update, [1]updated. 
```
echo '1'>update_flag
```
- step 4: restart the docker:
```
docker restart vsfptd
```
