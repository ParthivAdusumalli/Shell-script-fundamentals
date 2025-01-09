#!/bin/bash
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
DEF="\e[0m"

NODE_VER=$(node -v)
DATE=$(date +%Y-%m-%d)
if [ -d "/var/log/InstallationLogs/" ]; then
       echo -e "$YELLOW Logs Directory exists..$DEF"     
else
    echo -e "$GREEN Creating Logs Directory $DEF"
    mkdir /var/log/InstallationLogs/
fi
if [ "$NODE_VER" == "v20.17.0" ]; then
   echo -e "$YELLOW The Current Node JS version is v20.17.0 $DEF"
else 
    echo -e "$GREEN Configuring the Node JS v20.17.0 $DEF"
    dnf module disable nodejs -y &> /var/log/InstallationLogs/$DATE-Install-logs.log
    dnf module enable nodejs:20 -y &>> /var/log/InstallationLogs/$DATE-Install-logs.log
    dnf install nodejs -y &>> /var/log/InstallationLogs/$DATE-Install-logs.log
    NODE_VER_RECHECK=$(node -v)
    if [ "$NODE_VER_RECHECK" == "v20.17.0" ]; then
       echo -e "$GREEN Successfully configured the nodejs v20 $DEF"
    else 
        echo -e "$RED Configuring Node JS v20 Failed..Check logs $DEF"
        exit 1
   fi
fi

if id "expense" &>/dev/null; then
    echo -e "$YELLOW User 'expense' already exists.$DEF "
else
    echo "$YELLOW User 'expense' does not exist. Creating the user...$DEF"
    useradd -m expense 2>>/var/log/InstallationLogs/$DATE-Install-logs.log
    if [ $? -eq 0 ]; then
        echo -e "$GREEN User 'expense' created successfully.$DEF"
    else
        echo -e "$RED Failed to create user 'expense'. Please check permissions and logs $DEF"
        exit 1
    fi
fi

ls -l / | grep app

if [ $? -eq 0 ]; then
   echo -e "$YELLOW The Directory app was present at root location(/) $DEF"
else
    echo -e "$YELLOW app directory missing creating the app directory at root location $DEF"
    mkdir /app
    ls -l / | grep app
    if [ $? -eq 0 ]; then
       echo -e "$GREEN Directory /app successfully created $DEF"
   else
       echo -e "$RED app directory cant be created..ERROR $DEF"
      fi
fi
ls -l /tmp | grep backend.zip
if [ $? -ne 0 ]; then
   echo -e "$YELLOW Backend.zip file Missing. Downloading the file..$DEF"
   curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip
else
    echo -e "$YELLOW Application Code Zip file present at /tmp/backend.zip $DEF"
fi

cd /app
PRESENTW_D=$(pwd)
if [ "$PRESENTW_D" == "/app" ]; then
   echo -e "$GREEN Current working directory is /app $DEF"
else
   echo -e "$RED Unable to change directory.$DEF"
   exit 1
fi

echo -e "$YELLOW Trying to Unzip the File content $DEF"

cat /var/log/InstallationLogs/$DATE-Install-logs.log | grep "Archive:  /tmp/backend.zip"

if [ $? -eq 0 ]; then
   echo -e "$YELLOW Already Unzipping Finished..Cant unzip again..$DEF"
else 
    unzip /tmp/backend.zip
fi

cd /app
PRESENTW_D=$(pwd)
if [ "$PRESENTW_D" == "/app" ]; then
   echo -e "$GREEN Current working directory is /app $DEF"
else
   echo -e "$RED Unable to change directory. $DEF"
   exit 1
fi

NPM_V=$(npm -v)

if [ "$NPM_V" == "10.8.2" ]; then
   echo -e "$YELLOW node package manager already installed..$DEF"
else
   echo -e "$GREEN Installing the npm.$DEF"
   npm install
fi

grep -q "Environment=DB_HOST" /etc/systemd/system/backend.service

if [ $? -eq 0 ]; then
   echo "$YELLOW backend service file already configured..Please check if required$DEF"
   cat /etc/systemd/system/backend.service
else
    echo '[Unit]
Description = Backend Service

[Service]
User=expense
Environment=DB_HOST="10.1.2.124"
ExecStart=/bin/node /app/index.js
SyslogIdentifier=backend

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/backend.service
fi

systemctl daemon-reload
systemctl start backend
systemctl enable backend
dnf list installed | grep mysql &>/dev/null

if [ $? -eq 0 ]; then
    echo -e "$YELLOW Mysql Command line client already installed..$DEF"
else
    echo -e "$YELLOW Mysql client not installed installing Now..$DEF"
    dnf install mysql -y &>>/var/log/InstallationLogs/$DATE-Install-logs.log
fi
grep "Configuring Schema Completed" $DATE-Install-logs.log
if [ $? -eq 0 ]; then
   echo -e "$YELLOW DB Schema Already configured..$DEF"
else
    mysql -h 10.1.2.124 -uroot -pExpenseApp@1 < /app/schema/backend.sql
    echo -e "$GREEN Configuring Schema Completed $DEF" >> $DATE-Install-logs.log
fi
systemctl restart backend
systemctl status backend | grep "failed"
if [ $? -eq 0 ];then
   echo -e "$RED Backend Service Failed to run.. Installing Other dependencies..$DEF"
   npm install mysql2
   else
       echo -e "$GREEN Backend Service is up and running $DEF"
fi
systemctl status backend | grep "active (running)"
if [ $? -eq 0 ];then
   echo -e "$GREEN Backend Service up and running..$DEF"
   else
       echo -e "$RED Backend Service Still failing $DEF"
       exit 1
fi
systemctl daemon-reload
systemctl restart backend
echo -e "$GREEN Script completed successfully. Check $LOG_FILE for details.$DEF"