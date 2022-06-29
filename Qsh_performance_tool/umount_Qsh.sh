#/bin/bash

# Current path
CURRENT_PATH=$(pwd)

# Config directory path
CONFIG_DIR="/Config"

# Config file
org="/Config_Qsh.ini"

# Config file path
CONFIG_FILE=${CURRENT_PATH}/$CONFIG_DIR$org

mgt_zpool_name=$(awk '/^MGT_ZPOOL_NAME/{print $3}' ${CONFIG_FILE})
mgt_path=$(awk '/^MGT_PATH/{print $3}' ${CONFIG_FILE})

mdt_index=$(awk '/^MDT_INDEX/{print $3}' ${CONFIG_FILE})
mdt_zpool_name=$(awk '/^MDT_ZPOOL_NAME/{print $3}' ${CONFIG_FILE})
mdt_path=$(awk '/^MDT_PATH/{print $3}' ${CONFIG_FILE})

ost_index=$(awk '/^OST_INDEX/{print $3}' ${CONFIG_FILE})
ost_zpool_name=$(awk '/^OST_ZPOOL_NAME/{print $3}' ${CONFIG_FILE})
ost_path=$(awk '/^OST_PATH/{print $3}' ${CONFIG_FILE})


echo " Umount Start!!..."
sleep 1
echo -n 3..
sleep 1
echo -n 2..
sleep 1
echo -n 1..
sleep 1

# mount check
echo "Mount Check..."
df -Th

# Umount OST & directory remove
if [ -n "$ost_path" ]; then
    echo "OST umount & OST directory remove ..."

    # destroy zfs
    umount $ost_path$ost_index
    ost_zpool_name_split=$(echo $ost_zpool_name | awk -F / '{print $1}')
    zpool destroy $ost_zpool_name_split
    rm -rf $ost_path$ost_index
fi
# MGT umount (only in mgs)
if [ -n "$mgt_path" ]; then
    echo "MGT umount & zpool destroy..."
    
    # MGT umount & delete directory 
    umount $mgt_path
    mgt_zpool_name_split=$(echo $mgt_zpool_name | awk -F / '{print $1}')
    zpool destroy $mgt_zpool_name_split
    rm -rf $mgt_path
fi


# MDT umount (only in mds)
if [ -n "$mdt_path" ]; then
    echo "MDT umount & zpool destroy..."
    
    # MDT umount & delete directory 
    umount $mdt_path$mdt_index
    mdt_zpool_name_split=$(echo $mdt_zpool_name | awk -F / '{print $1}')
    zpool destroy $mdt_zpool_name_split
    rm -rf $mdt_path$mdt_index
fi

# Cache remove
echo "Cache remove..."
echo 3 > /proc/sys/vm/drop_caches
sleep 1
echo -n 3..
sleep 1
echo -n 2..
sleep 1
echo -n 1..
sleep 1
echo "Umount Exit!!..."
