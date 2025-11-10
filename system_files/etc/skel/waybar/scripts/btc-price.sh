#!/bin/bash
# Bitcoin price from CoinGecko API

price=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd" | \
        grep -o '"usd":[0-9.]*' | cut -d':' -f2)

if [ -n "$price" ]; then
    formatted=$(printf "%'.0f" "$price")
    echo "{\"text\":\"$${formatted}\",\"tooltip\":\"Bitcoin Price (USD)\"}"
else
    echo "{\"text\":\"--\",\"tooltip\":\"Price unavailable\"}"
fi