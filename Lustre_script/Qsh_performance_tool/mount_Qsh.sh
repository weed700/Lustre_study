#/bin/bash

Nickname="Qsh"

# Current path
CURRENT_PATH=$(pwd)

# Config direcotry path
CONFIG_DIR="/Config"

# Config file 
org="/Config_Qsh.ini"

# Config file path
CONFIG_FILE=${CURRENT_PATH}/$CONFIG_DIR$org

ip=$(awk '/^IP/{print $3}' ${CONFIG_FILE})
typ=$(awk '/^TYPE/{print $3}' ${CONFIG_FILE})
fsname=$(awk '/^FSNAME/{print $3}' ${CONFIG_FILE})
backfstype=$(awk '/^BACKFSTYPE/{print $3}' ${CONFIG_FILE})
raid=$(awk '/^RAID/{print $3}' ${CONFIG_FILE})

mgt_zpool_name=$(awk '/^MGT_ZPOOL_NAME/{print $3}' ${CONFIG_FILE})
mgt_path=$(awk '/^MGT_PATH/{print $3}' ${CONFIG_FILE})
mgt_dev=$(awk '/^MGT_DEV/{print $3}' ${CONFIG_FILE})

mdt_index=$(awk '/^MDT_INDEX/{print $3}' ${CONFIG_FILE})
mdt_zpool_name=$(awk '/^MDT_ZPOOL_NAME/{print $3}' ${CONFIG_FILE})
mdt_path=$(awk '/^MDT_PATH/{print $3}' ${CONFIG_FILE})
mdt_dev=$(awk '/^MDT_DEV/{print $3}' ${CONFIG_FILE})

ost_index=$(awk '/^OST_INDEX/{print $3}' ${CONFIG_FILE})
ost_zpool_name=$(awk '/^OST_ZPOOL_NAME/{print $3}' ${CONFIG_FILE})
ost_path=$(awk '/^OST_PATH/{print $3}' ${CONFIG_FILE})
ost_dev=$(awk '/^OST_DEV/{print $3}' ${CONFIG_FILE})

client_path=$(awk '/^CLIENT/{print $3}' ${CONFIG_FILE})

echo "--- Mount Start!!..."
sleep 1
echo -n 3..
sleep 1
echo -n 2..
sleep 1
echo -n 1..
sleep 1


# MGT mount(only in mgs)
if [ -n "$mgt_path" ]; then
    echo "--- MGT server format & mount..."
    echo $mgt_dev
    # MGT format
    mkfs.lustre --mgs --backfstype=$backfstype --mgsnode=$ip$typ --fsname=$fsname --reformat $mgt_zpool_name $mgt_dev

    # MGT mount directory create
    mkdir -p $mgt_path
    mount -t lustre $mgt_zpool_name $mgt_path
fi

# MDT mount(only in mds)
if [ -n "$mdt_path" ]; then
    echo "--- MDT server format & mount..."

    # MDT format
    mkfs.lustre --mdt --backfstype=$backfstype --index=$mdt_index --mgsnode=$ip$typ --fsname=$fsname --reformat $mdt_zpool_name$mdt_index $mdt_dev

    # MDT mount directory create
    mkdir -p $mdt_path$mdt_index
    mount -t lustre $mdt_zpool_name$mdt_index $mdt_path$mdt_index
fi


# OST format
if [ -n "$ost_path" ]; then
    echo "--- OST format..." 
    mkfs.lustre --ost --backfstype=$backfstype --index=$ost_index --mgsnode=$ip$typ --fsname=$fsname --reformat $ost_zpool_name$ost_index $raid $ost_dev

    # OST mount
    # Mount directory create
    echo "--- OST mount directory create & mount..."
    mkdir -p $ost_path$ost_index
    mount -t lustre $ost_zpool_name$ost_index $ost_path$ost_index
fi

# Client lustre mount(only in client server)
if [ -n "$client_path" ]; then
    echo "--- Client server lustre mount..."

    # Client mount directory create
    mkdir -p $client_path
    mount -t lustre $ip${typ}:/$fsname $client_path
fi
# mount check
echo "--- Mount Check..."
df -Th

sleep 1
echo -n 3..
sleep 1
echo -n 2..
sleep 1
echo -n 1..
sleep 1
echo "--- Mount Exit!!..."
