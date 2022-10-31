#/bin/bash

mount_qsh="mount_Qsh.sh"

# Current path
CURRENT_PATH=$(pwd)

# Config direcotry path
CONFIG_DIR="/Config"

# Config file
server_conf="/server_Config_Qsh.ini"
server_conf_file=${CURRENT_PATH}/$CONFIG_DIR$server_conf
config_ini=$(awk '/^CONF/{print $3}' ${server_conf_file})

org="Config_Qsh.ini"

# mount
echo "---------- Mount on each server... ----------"
for all_ini in ${config_ini[*]}
do
    hostname=$(echo $all_ini | awk -F . '{print $1}')

    echo $hostname "---------------------------start--------------------------"
    ssh root@$hostname "cd $CURRENT_PATH;\cp $CURRENT_PATH${CONFIG_DIR}/$all_ini $CURRENT_PATH${CONFIG_DIR}/$org;${CURRENT_PATH}/$mount_qsh;"
    echo $hostname "---------------------------end--------------------------"
done

# all mount check
echo ""
echo "-------- All mount check ----------"
lfs df -h
echo ""

