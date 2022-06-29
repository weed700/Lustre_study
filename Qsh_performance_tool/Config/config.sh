#!/bin/bash

server_conf="server_Config_Qsh.ini"
echo "[INI per SERVER]" >> $server_conf

# Input value
# Default 
echo "********** Common default value input... **********"
read -p "MGS IP input: " ip
read -p "Type( ex: @tcp, @o2ib0 ) input: " typ
read -p "Backfstype input: " backfstype
read -p "FSname input: " fsname

echo ""

# MGS config file create
echo "********** MGS config creat... **********"
read -p "MGS hostname input: " mgs_hostname
echo "HOST_NAME_MGS     = $mgs_hostname" >> $server_conf
read -p "MGT zpool name input: " mgt_zpool_name
read -p "MGT path input: " mgt_path
read -p "MGT devices input: " mgt_devs

mgs_conf=${mgs_hostname}.mgs_Config_Qsh.ini
echo "CONF_MGS     = $mgs_conf" >> $server_conf
echo "[MGS]" >> $mgs_conf
# default value
echo "IP            = $ip" >> $mgs_conf
echo "TYPE          = $typ" >> $mgs_conf
echo "BACKFSTYPE    = $backfstype" >> $mgs_conf
echo "FSNAME        = $fsname" >> $mgs_conf
# mgs value
echo "MGT_ZPOOL_NAME    = " $mgt_zpool_name >> $mgs_conf 
echo "MGT_PATH    = " $mgt_path >> $mgs_conf 
i=0
for mgt_dev in ${mgt_devs[*]}
do
    echo "MGT_DEV"$i      "=" $mgt_dev >> $mgs_conf; 
    i=`expr $i + 1`
done
# RAID
read -p "RAID input(if not, Enter): " mgt_raid
if [ -n "$mgt_raid" ]; then
    echo "[RAID]" >> $mgs_conf
    echo "RAID          = $mgt_raid" >> $mgs_conf
fi

echo ""

# MDS config file create
echo "********** MDS config creat... **********"
# Enter the number of MDS
while :
do
    echo "Enter the number of MDS"
    read -p "MDS hostname input(if not, Enter): " mds_hostname
    if [ -z "$mds_hostname" ]; then break; fi
    read -p "MDT count(if not, Enter): " mdt_count
    echo "HOST_NAME_MDS     = $mds_hostname" >> $server_conf
    
    for ((i=0;i < $mdt_count; i++))
    do
        # MDS(by the number)
        read -p "MDT index input: " mdt_index
        read -p "MDT zpool name input: " mdt_zpool_name
        read -p "MDT path input: " mdt_path
        read -p "MDT devices input(ex: /dev/sda /dev/sdb ...): " -a mdt_devs
        
        mds_conf=${mds_hostname}.mds_${mdt_index}_Config_Qsh.ini
        echo "CONF_MDS     = $mds_conf" >> $server_conf
        echo "[MDS]" >> $mds_conf
        # default value
        echo "IP            = $ip" >> $mds_conf
        echo "TYPE          = $typ" >> $mds_conf
        echo "BACKFSTYPE    = $backfstype" >> $mds_conf
        echo "FSNAME        = $fsname" >> $mds_conf
        
        echo "MDT_INDEX         = $mdt_index" >> $mds_conf
        echo "MDT_ZPOOL_NAME    = $mdt_zpool_name" >> $mds_conf
        echo "MDT_PATH          = $mdt_path" >> $mds_conf
        num=0
        for mdt_dev in ${mdt_devs[*]}
        do
            echo "MDT_DEV"$num      "=" $mdt_dev >> $mds_conf
            num=`expr $num + 1`
        done
        # RAID
        read -p "RAID input(if not, Enter): " mdt_raid
        if [ -n "$mdt_raid" ]; then
            echo "[RAID]" >> $mds_conf
            echo "RAID          = $mdt_raid" >> $mds_conf
        fi
    done
    echo ""
done

echo ""

# OSS config file create
echo "********** OSS config creat... **********"
# Enter the number of OSS
while :
do
    echo "Enter the number of OSS"
    read -p "OSS hostname input(if not, Enter): " oss_hostname
    if [ -z "$oss_hostname" ]; then break; fi
    read -p "OST count(if not, Enter): " ost_count
    echo "HOST_NAME_OSS     = $oss_hostname" >> $server_conf
    
    for ((i=0;i < $ost_count; i++))
    do
        # OSS(by the number)
        read -p "OST index input: " ost_index
        read -p "OST zpool name input: " ost_zpool_name
        read -p "OST path input: " ost_path
        read -p "OST devices input(ex: /dev/sda /dev/sdb ...): " -a ost_devs
        
        oss_conf=${oss_hostname}.oss_${ost_index}_Config_Qsh.ini
        echo "CONF_OSS     = $oss_conf" >> $server_conf
        echo "[OSS]" >> $oss_conf
        # default value
        echo "IP            = $ip" >> $oss_conf
        echo "TYPE          = $typ" >> $oss_conf
        echo "BACKFSTYPE    = $backfstype" >> $oss_conf
        echo "FSNAME        = $fsname" >> $oss_conf
        
        echo "OST_INDEX         = $ost_index" >> $oss_conf
        echo "OST_ZPOOL_NAME    = $ost_zpool_name" >> $oss_conf
        echo "OST_PATH          = $ost_path" >> $oss_conf
        num=0
        for ost_dev in ${ost_devs[*]}
        do
            echo "OST_DEV"$num      "=" $ost_dev >> $oss_conf
            num=`expr $num + 1`
        done
        # RAID
        read -p "RAID input(if not, Enter): " ost_raid
        if [ -n "$ost_raid" ]; then
            echo "[RAID]" >> $oss_conf
            echo "RAID          = $ost_raid" >> $oss_conf
        fi
    done
    echo ""
done

echo ""

# Client config file create
echo "********** client config creat... **********"
# Enter the number of Client
while :
do
    client_count=0
    echo "Enter the number of Client"
    read -p "Client hostname input(if not, Enter): " client_hostname
    if [ -z "$client_hostname" ]; then break; fi
    read -p "Client path input: " client_path

    client_conf=${client_hostname}.${client_count}_client_Config_Qsh.ini
    echo "CONF_CLIENT     = $client_conf" >> $server_conf
    echo "[client]" >> $client_conf
    # default value
    echo "IP            = $ip" >> $client_conf
    echo "TYPE          = $typ" >> $client_conf
    echo "BACKFSTYPE    = $backfstype" >> $client_conf
    echo "FSNAME        = $fsname" >> $client_conf
    # client path
    echo "CLIENT_PATH   = $client_path" > $client_conf

    # Benchmark config file create
    echo "********** Benchmark config creat... **********"
    read -p "Benchmark tool name input: " benchmark_tool_name
    read -p "Benchmark job count input: " benchmark_job_count
    read -p "Benchmark file size input(ex: 4k): " benchmark_file_size
    read -p "Benchmark test type(ex: normal, stripe, dom): " benchmark_test_type 

    echo "[Benchmark]" >> $client_conf
    echo "BENCHMARK_TOOL_NAME            = $benchmark_tool_name" >> $client_conf
    echo "BENCHMARK_JOB_COUNT            = $benchmark_job_count" >> $client_conf
    echo "BENCHMARK_FILE_SIZE            = $benchmark_file_size" >> $client_conf
    echo "BENCHMARK_TEST_TYPE            = $benchmark_test_type" >> $client_conf
done
