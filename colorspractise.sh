#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0;31m'

if [ 12 -eq 12 ];
   then
        echo "$GREEN Condition Correct. $RESET"
else
        echo "$RED Condition incorrect..$RESET"
        echo "Please check."
fi
