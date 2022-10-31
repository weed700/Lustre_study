#/bin/bash

umount_qsh="umount_Qsh.sh"


# Current path
CURRENT_PATH=$(pwd)

# Config direcotry path
CONFIG_DIR="/Config"

# Config file
server_conf="/server_Config_Qsh.ini"
server_conf_file=${CURRENT_PATH}/$CONFIG_DIR$server_conf
config_ini=$(awk '/^CONF/{print $3}' ${server_conf_file})

org="Config_Qsh.ini"


array=()
arr=()

# reverse 
for temp in ${config_ini[*]}
do
    array+=($temp);
done
 
n=$((${#array[*]}-1))

for ((i=$n; i >=0; i--));
do
    arr+=(${array[$i]})
done

for all_ini in ${arr[*]}
do
    echo "--- umount..."
    hostname=$(echo $all_ini | awk -F . '{print $1}')
    ssh root@$hostname "cd $CURRENT_PATH;\cp $CURRENT_PATH${CONFIG_DIR}/$all_ini $CURRENT_PATH${CONFIG_DIR}/$org;${CURRENT_PATH}/$umount_qsh" 
done

echo "------------------- All Clear SUCCESS!!---------------------------"
