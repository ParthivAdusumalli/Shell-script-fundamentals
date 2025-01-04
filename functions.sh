#!/bin/bash

square() {
    local VALUE=$(($1 * $1)) # Declare VALUE as local
    echo $VALUE
    echo "The result of given number is:$VALUE" >&2
}

# Capture the function's output using command substitution
RESULT=$(square 19)
echo "Square of the given number was: $RESULT"
