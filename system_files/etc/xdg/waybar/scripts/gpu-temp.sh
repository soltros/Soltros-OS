#!/bin/bash
# AMD GPU temperature monitoring

if command -v sensors &> /dev/null; then
    temp=$(sensors | grep -i "edge" | awk '{print $2}' | sed 's/+//;s/°C//')
    if [ -n "$temp" ]; then
        echo "{\"text\":\"${temp}°C\",\"tooltip\":\"GPU Temperature\"}"
    else
        echo "{\"text\":\"N/A\",\"tooltip\":\"GPU not found\"}"
    fi
else
    echo "{\"text\":\"N/A\",\"tooltip\":\"lm_sensors not installed\"}"
fi