#!/bin/bash

RED="\e[31m"
GREEN="\e[33m"
YELLOW="\e[32m"
DEF="\e[0m"

echo "Running the script as Root User..."
DATE=$(date +%Y/%m/%d)
Checking_Software()
{
  $1 -v > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo -e "$YELLOW$1 is already Installed..$DEF"
  else
      echo -e "$RED$1 is not installed..Installing Now..$DEF"
      dnf install -y $1 &>>/var/log/InstallLogs/$DATE-Installation.log
      if [ $? -eq 0 ]; then
         echo -e "$GREEN$1 Successfully Installed..$DEF"
     else
         echo -e "$RED Error Installing $1..Please check the Logs"
         echo -e "Terminating the script..$DEF"
         exit 1
    fi
  fi
}
Checking_Software git

Checking_Software mysql-server

systemctl start mysqld &>>/dev/null 

Checking_Conf()
{
  if [ $? -eq 0 ]; then
     echo -e "$GREEN$1 Mysql Server..$DEF"
  else 
      echo -e "$RED Failed to Start/enable the Mysql server.."
      echo -e "Terminating the Script..$DEF"
      exit 1
  fi
}
Checking_Conf Started

systemctl enable mysqld

Checking_Conf Enabled

ROOT_PASSWORD="ExpenseApp@1"
mysql_secure_installation --set-root-pass "$ROOT_PASSWORD" 2>/tmp/mysql_secure_error.log

if [ $? -eq 0 ]; then
   echo -e "$GREEN Root Password Set successfully..$DEF"
else 
    echo -e "$RED Password already created or cant change now...For Quality Assurance added this action to logs.. $DEF"
fi

mysql &>>/var/log/InstallLogs/$DATE-Installation.log
if [ $? -eq 0 ]; then
   echo "$GREEN DB SERVER IMPLEMENTED SUCCESSFULLY....$DEF"
else
    echo "$RED Implementing the DB Server Failed..Please Check Logs and Try again.."
    exit 1
fi