#!/usr/bin/env bash

# VM health check:
# Declares the VM "Not healthy" if CPU idle, available memory,
# or available disk space is below 60%.

set -u

THRESHOLD=60

# CPU available percentage, calculated from CPU idle time.
CPU_IDLE=$(top -bn1 | awk -F'[, ]+' '/Cpu\(s\)/ {
    for (i = 1; i <= NF; i++) {
        if ($i ~ /id/) {
            gsub(/[^0-9.]/, "", $i)
            print int($i)
            exit
        }
    }
}')

# Memory available percentage.
MEMORY_AVAILABLE=$(free | awk '/Mem:/ {
    if ($2 > 0) {
        printf "%.0f", ($7 / $2) * 100
    } else {
        print 0
    }
}')

# Disk available percentage for the root filesystem.
DISK_AVAILABLE=$(df -P / | awk 'NR==2 {
    used = $3
    available = $4
    total = used + available

    if (total > 0) {
        printf "%.0f", (available / total) * 100
    } else {
        print 0
    }
}')

echo "VM Health Check"
echo "---------------"
echo "CPU available:    ${CPU_IDLE}%"
echo "Memory available: ${MEMORY_AVAILABLE}%"
echo "Disk available:   ${DISK_AVAILABLE}%"

if (( CPU_IDLE < THRESHOLD ||
      MEMORY_AVAILABLE < THRESHOLD ||
      DISK_AVAILABLE < THRESHOLD )); then
    echo "Health: Not healthy"
    exit 1
else
    echo "Health: Healthy"
    exit 0
fi
