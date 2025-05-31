#!/bin/bash
# usage: $0 <FILE> <DEVICE>
DEVICE=$2
FILE=$1
echo "transfer ${1} to ${2} ..."
read -p 'ok?'
echo

SIZE=$(cat ${FILE} | wc -c)
COUNT=0
while IFS= read -r -n1 CHAR; do
    echo -n "${CHAR}" > "${DEVICE}"
    COUNT=$((COUNT + 1))
    echo -ne "${COUNT} / ${SIZE}\r"
    # 0.002s = 500 bytes/sec
    sleep 0.002s
done < "${FILE}"
echo

