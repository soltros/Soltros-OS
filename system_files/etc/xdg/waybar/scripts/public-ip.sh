#!/bin/bash
# Display public IP address

ip=$(curl -s ifconfig.me 2>/dev/null)

if [ -n "$ip" ]; then
    # Mask last octet for privacy
    masked=$(echo "$ip" | sed 's/\.[0-9]*$/.xxx/')
    echo "{\"text\":\"${masked}\",\"tooltip\":\"Public IP: ${ip}\"}"
else
    echo "{\"text\":\"--\",\"tooltip\":\"IP unavailable\"}"
fi