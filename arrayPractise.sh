#!/bin/bash
SKILLS=("JAVA" "AWS" "Basic Of Shell scripts" "PowerShell" 1 2 true 't')
echo "First Element:${SKILLS[4]}"
echo "Second Element:${SKILLS[5]}"
echo "All elements are : ${SKILLS[7]}" 
echo "The script running was: $0"

ARG1=$1
ARG2=$2

echo "The total Number of arguments passed are: $# and the values are $@"
SINGLESTRING=$* #"54 67"
echo "$SINGLESTRING" | cut -d " " -f1


echo "I am learning AWS with DevSecOps"

echo "Process ID OF current Script: $$"

echo "Current Shell options enabled are:$-"

echo "hello world" > file.txt

echo "Current Working directory: $PWD"

echo "Home directory of the user who is running the script is: $HOME with Username:$USER"

if [ 12 -lt 11 ] || [ 12 -lt 12 ];
then 
    echo "Either one or Both statements are correct"
else
    echo "Both statements are wrong"
fi