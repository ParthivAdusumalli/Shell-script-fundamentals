#!/bin/bash

USERID=$(id -u)

if [ "$USERID" -eq 0 ]
then
    echo "Root user is using"
else
    echo "Non-root user is using"
fi