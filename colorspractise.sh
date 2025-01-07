#!/bin/bash

RED='\e[31m'
GREEN='\e[32m'
RESET='\e[0m'

if [ 11 -eq 12 ];
   then
        echo -e "$GREEN Condition Correct. $RESET"
else
        echo -e "$RED Condition incorrect..$RESET"
        echo "Please check."
fi
