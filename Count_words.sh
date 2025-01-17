#!/bin/bash

WORDS=()

while read -r line; do
      echo "$line" | awk '{for (i=1; i<=NF; i++) WORDS+=$i}'
done < /etc/passwd

for item in "${WORDS[@]}"; do
    echo "$item"
done