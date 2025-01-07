#!/bin/bash

#Simple For
for ((i=0; i < 5; i++)); do
    echo "Iterating the loop $i"
done

#For Method 2
for i in {1..5}; do
    echo "Iteration $i"
done

WORDS=("Apple" "Pappaya" "Pineapple")

for WORD in "${WORDS[@]}"; do
    echo "$WORD"
done 


#Checking the Application Installation Status 

RED='\e[31m'
GREEN='\e[32m'
RESET='\e[0m'
echo "Enter the list of packages you want to check. Type 'done' once finished."

ALLPACKAGES=()
PACKAGENAME=""

while [ "$PACKAGENAME" != "done" ]; do
   read "PACKAGENAME" 
      if [ "$PACKAGENAME" != "done" ];
      then
      ALLPACKAGES+=("$PACKAGENAME") # Append to the array
      fi
done

echo "The packages need to be checked are:${ALLPACKAGES[@]}"

LENGTH=${#ALLPACKAGES[@]}

echo "Total number of packages to be checked:$LENGTH"

check_Install_status()
{
    ssh -i /c/Users/parth/repos/AWSKeyForAll.pem ec2-user@13.232.90.221 "$1 -v" > /dev/null 2>&1
    if [ $? -eq 0 ];
    then 
        echo -e "$GREEN $1 Already installed.. $RESET"
    else
        echo -e "$RED $1 not installed $RESET"
    fi
}


for ((i=0; i < $LENGTH; i++)) do
   check_Install_status "${ALLPACKAGES[$i]}"
done

