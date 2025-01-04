#!/bin/bash

# Try to connect to the remote server
ssh -i /c/Users/parth/repos/AWSKeyForAll.pem ec2-user@13.234.67.35 exit > /dev/null 2>&1

# Check if SSH was successful
if [ $? -eq 0 ]; then
    echo "Connection success..Proceeding with the script"
    ssh -i /c/Users/parth/repos/AWSKeyForAll.pem ec2-user@13.234.67.35 "dnf installed list available | grep git" > /dev/null 2>&1
    if [ $? -eq 0 ];
    then
        echo "Git already installed.."
    else
        echo "Git not installed installing mysql command line.."
        ssh -i /c/Users/parth/repos/AWSKeyForAll.pem ec2-user@13.234.67.35 "sudo dnf update -y" > /dev/null
        echo "Updated the repos"
        ssh -i /c/Users/parth/repos/AWSKeyForAll.pem ec2-user@13.234.67.35 "sudo dnf install -y git" > /dev/null 2>&1
    fi
    if [ $? -eq 0 ]
    then 
        echo "Successfully installed Git"
    else 
        echo "Installing Git failed.."
    fi
else
    echo "Connection failed"
    echo "Script terminated..."
    exit 1
fi
