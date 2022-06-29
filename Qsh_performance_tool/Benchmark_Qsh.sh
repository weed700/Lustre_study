#/bin/bash

Nickname="Qsh"
date=$(date '+%Y-%m-%d_%H-%M-%S')
mount_qsh="mount_Qsh.sh"
umount_qsh="umount_Qsh.sh"

fio_result_merged="fio_result_merged.sh"

# log backup directory
log="/log"

# tool script directory
tools="/Tools"

# Current path
CURRENT_PATH=$(pwd)

# Config direcotry path
CONFIG_DIR="/Config"

# Config file
server_conf="/server_Config_Qsh.ini"
server_conf_file=${CURRENT_PATH}/$CONFIG_DIR$server_conf
config_ini=$(awk '/^CONF/{print $3}' ${server_conf_file})
client_ini=$(awk '/^CONF_CLIENT/{print $3}' ${server_conf_file})
all_hostname=$(awk '/^HOST_NAME/{print $3}' ${server_conf_file}) 

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

# Client 
for cini in ${client_ini[*]}
do
    client_hostname=$(echo $cini | awk -F . '{print $1}')
    CONFIG_FILE=$CURRENT_PATH${CONFIG_DIR}/$cini

    client_path=$(awk '/^CLIENT/{print $3}' ${CONFIG_FILE})
    test_type=$(awk '/^BENCHMARK_TEST_TYPE/{print $3}' ${CONFIG_FILE})
    tool_name=$(awk '/^BENCHMARK_TOOL_NAME/{print $3}' ${CONFIG_FILE})
    job_count=$(awk '/^BENCHMARK_JOB_COUNT/{print $3}' ${CONFIG_FILE})
    file_size=$(awk '/^BENCHMARK_FILE_SIZE/{print $3}' ${CONFIG_FILE})
    test_path=/${tool_name}/${test_type}dir

    echo "--- Becnhmark tool Start!!..."
    sleep 1
    echo -n 3..
    sleep 1
    echo -n 2..
    sleep 1
    echo -n 1..
    sleep 1

    # Benchmark tools exec(only in client server)
    # Benchmark directory create
    echo "--- " $tool_name "directory create..."
    mkdir -p $client_path$test_path 

    echo ""

    # iostat log
    echo "--- iostat log..."
    for hs in ${all_hostname[*]}
    do
        hostname=$(echo $hs | awk -F . '{print $1}')

        ssh root@$hostname "mkdir -p $CURRENT_PATH${log}/${tool_name}_$date; iostat -mtx 10 > $CURRENT_PATH${log}/${tool_name}_${date}/iostat.log &"
    done

    echo ""

    # Benchmark exec
    echo "--- " ${tool_name} testing...
    ssh root@$client_hostname "$CURRENT_PATH${tools}/${tool_name}_${Nickname}.sh $client_path$test_path $job_count $file_size"

    # Benchmark exit
    echo --- Benchmark exit...
    sleep 1
    echo -n 3..
    sleep 1
    echo -n 2..
    sleep 1
    echo -n 1..
    sleep 1

    echo ""

    # Result save & iostat stop
    echo "--- result save & iostat stop ..."

    #iostst exit
    for hs in ${all_hostname[*]}
    do
        hostname=$(echo $hs | awk -F . '{print $1}')
        ssh root@$hostname "${CURRENT_PATH}/iostat_kill.sh iostat"
    done

    cp -r $client_path${test_path}/${tool_name}_result $CURRENT_PATH${log}/${tool_name}_$date

    if [ "$tool_name" == "fio" ]; then
        # fio result merged
        echo "--- fio result merged exec..."
        cp ${CURRENT_PATH}${tools}/$fio_result_merged $CURRENT_PATH${log}/${tool_name}_${date}/${tool_name}_result
        # fio result merged exec
        $CURRENT_PATH${log}/${tool_name}_${date}/${tool_name}_result/$fio_result_merged $CURRENT_PATH${log}/${tool_name}_${date}/${tool_name}_result
    fi
    # Benchmark test direcotry delete
    rm -rf $client_path$test_path

    sleep 1
    echo -n 3..
    sleep 1
    echo -n 2..
    sleep 1
    echo -n 1..
    sleep 1
    echo "--- init..."
    echo ""

    # local & Remote Umount command exec(mgs, mds, oss1, oss2)

    # client umount
    echo "--- Client umount..."
    umount $client_path
done


for all_ini in ${config_ini[*]}
do
    echo "--- umount..."
    hostname=$(echo $all_ini | awk -F . '{print $1}')
    ssh root@$hostname "cd $CURRENT_PATH;\cp $CURRENT_PATH${CONFIG_DIR}/$all_ini $CURRENT_PATH${CONFIG_DIR}/$org;${CURRENT_PATH}/$umount_qsh" 
done

echo "------------------- All Clear SUCCESS!!---------------------------"
