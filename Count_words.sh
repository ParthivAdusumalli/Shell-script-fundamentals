#!/bin/bash

WORDS=()

while read -r line; do
      for word in "${line[@]}"; do
          WORDS+=word
        done
done < /etc/passwd

for item in "${WORDS[@]}"; do
    echo "$item"
done