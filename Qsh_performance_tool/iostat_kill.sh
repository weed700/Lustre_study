#!/bin/bash

# PID 추출
pid=`ps -ef | grep -v "grep" | grep $1 | awk '{print $2}'`

# PID kill
kill -9 $pid
