#!/bin/bash
# Weather information using wttr.in

LOCATION="${WEATHER_LOCATION:-Toronto}"

weather=$(curl -s "wttr.in/${LOCATION}?format=%t+%C" 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$weather" ]; then
    echo "{\"text\":\"${weather}\",\"tooltip\":\"Weather in ${LOCATION}\"}"
else
    echo "{\"text\":\"--\",\"tooltip\":\"Weather unavailable\"}"
fi