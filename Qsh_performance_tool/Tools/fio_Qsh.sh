#!/bin/bash

re_path=${1}/fio_result

# Result directory create
mkdir -p $re_path

# seq write
fio --name='fio_seqwrite' --directory=$1 --rw=write --filesize=$3 --numjobs=$2 --nrfiles=1021 > ${re_path}/result_write
# seq read
fio --name='fio_seqread' --directory=$1 --rw=read --filesize=$3 --numjobs=$2 --nrfiles=1021 > ${re_path}/result_read
# random write
fio --name='fio_randwrite' --directory=$1 --rw=randwrite --filesize=$3 --numjobs=$2 --nrfiles=1021 > ${re_path}/result_randwrite
# random read
fio --name='fio_randread' --directory=$1 --rw=randread --filesize=$3 --numjobs=$2 --nrfiles=1021 > ${re_path}/result_randread
