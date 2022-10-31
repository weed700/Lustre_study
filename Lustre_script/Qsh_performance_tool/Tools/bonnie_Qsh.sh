#!/bin/bash

# Result directory create
mkdir -p ${1}/bonnie_result
# bonnie exec
bonnie++ -d $1 -s0 -n $2:$3:$3:$2 -u root >  ${1}/bonnie_result/result_bonnie.re
