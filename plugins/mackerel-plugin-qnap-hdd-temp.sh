#!/bin/bash

max_hdd_num=$1
timestamp=`date +%s`
for ((i=1; i<$max_hdd_num+1; i++)); do
    temp=`get_hd_temp $i`
    echo -e "custom.hdd-temperature.Drive$i\t$temp\t$timestamp"
done
