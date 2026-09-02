#!/bin/bash

THRESHOLD=80
USAGE=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

if [ "$USAGE" -ge "$THRESHOLD" ]; then
    echo "WARNING: Disk usage is at ${USAGE}% — above the ${THRESHOLD}% threshold!"
else
    echo "OK: Disk usage is at ${USAGE}% — within normal range."
fi
