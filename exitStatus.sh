#!/bin/bash

USERID=$(id -u)

if [ $? -eq 0 ]
then
    echo "Root user is using"
else
    echo "Non-root user is using"
fi