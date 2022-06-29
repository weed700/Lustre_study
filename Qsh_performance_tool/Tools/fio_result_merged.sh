#!/bin/bash

merged_re="/merged.re"

echo $1

grep WRITE: ${1}/result_write | awk '{print $1 $2}' >> $1$merged_re
grep READ: ${1}/result_read | awk '{print $1 $2}' >> $1$merged_re
grep WRITE: ${1}/result_randwrite | awk '{print $1 $2}' >> $1$merged_re
grep READ: ${1}/result_randread | awk '{print $1 $2}' >> $1$merged_re

# read, write -> randread, randwrite change
sed -i '3 s/WRITE/RANDWRITE/' $1$merged_re
sed -i '4 s/READ/RANDREAD/' $1$merged_re
