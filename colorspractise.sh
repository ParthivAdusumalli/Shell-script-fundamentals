#!/bin/bash

RED='\e[31m'
GREEN='\e[32m'
RESET='\0e[31m'

if [ 12 -eq 12 ];
   then
        echo "$GREEN Condition Correct. $RESET"
else
        echo "$RED Condition incorrect..$RESET"
        echo "Please check."
fi
