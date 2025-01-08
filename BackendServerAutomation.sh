#!/bin/bash

NODE_VER=$(node -v)
DATE=$(date +%Y-%m-%d)
if [ -d "/var/log/InstallationLogs/" ]; then
       echo "Logs Directory exists.."     
else
    echo "Creating Logs Directory"
    mkdir /var/log/InstallationLogs/
fi
if [ "$NODE_VER" == "v20.17.0" ]; then
   echo "The Current Node JS version is v20.17.0"
else 
    dnf module disable nodejs -y &> /var/log/InstallationLogs/$DATE-Install-logs.log
    echo "--------------------Step-1-Complete------------------------" >> /var/log/InstallationLogs/$DATE-Install-logs.log
    dnf module enable nodejs:20 -y &>> /var/log/InstallationLogs/$DATE-Install-logs.log
    echo "--------------------Step-2-Complete------------------------" >> /var/log/InstallationLogs/$DATE-Install-logs.log
    dnf install nodejs -y &>> /var/log/InstallationLogs/$DATE-Install-logs.log
    echo "--------------------Step-3-Complete------------------------" >> /var/log/InstallationLogs/$DATE-Install-logs.log
fi

if id "expense" &>/dev/null; then
    echo "User 'expense' already exists."
else
    echo "User 'expense' does not exist. Creating the user..."
    useradd -m expense 2>>/var/log/InstallationLogs/$DATE-Install-logs.log
    if [ $? -eq 0 ]; then
        echo "User 'expense' created successfully."
        echo "--------------------Step-4-Complete------------------------" >> /var/log/InstallationLogs/$DATE-Install-logs.log
    else
        echo "Failed to create user 'expense'. Please check permissions and logs"
    fi
fi

ls -l / | grep app

if [ $? -eq 0 ]; then
   echo "The Directory app was present at root location(/)"
else
    echo "app directory missing creating the app directory at root location"
    mkdir /app
    echo "--------------------Step-5-Complete------------------------" >> /var/log/InstallationLogs/$DATE-Install-logs.log

fi
ls -l /tmp | grep backend.zip
if [ $? -ne 0 ]; then
   echo "Backend.zip file Missing. Downloading the file.."
   curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip
   echo "--------------------Step-6-Complete------------------------" >> /var/log/InstallationLogs/$DATE-Install-logs.log
else
    echo "Application Code Zip file present at /tmp/backend.zip"
fi

cd /app
PRESENTW_D=$(pwd)
if [ "$PRESENTW_D" == "/app" ]; then
   echo "Current working directory is /app"
   echo "--------------------Step-7-Complete------------------------" >> /var/log/InstallationLogs/$DATE-Install-logs.log
else
   echo "Unable to change directory."
   exit 1
fi

echo "Trying to Unzip the File content"

cat /var/log/InstallationLogs/$DATE-Install-logs.log | grep "Archive:  /tmp/backend.zip"

if [ $? -eq 0 ]; then
   echo "Already Unzipping Finished..Cant unzip again.."
else 
    unzip /tmp/backend.zip
    echo "--------------------Step-8-Complete------------------------" >> /var/log/InstallationLogs/$DATE-Install-logs.log
fi

cd /app
PRESENTW_D=$(pwd)
if [ "$PRESENTW_D" == "/app" ]; then
   echo "Current working directory is /app"
   echo "--------------------Step-9-Complete------------------------" >> /var/log/InstallationLogs/$DATE-Install-logs.log
else
   echo "Unable to change directory."
   exit 1
fi

NPM_V=$(npm -v)

if [ "$NPM_V" == "10.8.2" ]; then
   echo "node package manager already installed.."
else
   echo "Installing the npm."
   npm install
   echo "--------------------Step-10-Complete------------------------" >> /var/log/InstallationLogs/$DATE-Install-logs.log

fi

grep -q "Environment=DB_HOST" /etc/systemd/system/backend.service

if [ $? -eq 0 ]; then
   echo "backend service file already configured..Please check if required"
   cat /etc/systemd/system/backend.service
else
    echo '[Unit]
Description = Backend Service

[Service]
User=expense
Environment=DB_HOST="10.1.2.175"
ExecStart=/bin/node /app/index.js
SyslogIdentifier=backend

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/backend.service
echo "--------------------Step-11-Complete------------------------" >> /var/log/InstallationLogs/$DATE-Install-logs.log
fi

systemctl daemon-reload
echo "--------------------Step-12-Complete------------------------" >> /var/log/InstallationLogs/$DATE-Install-logs.log
systemctl start backend
echo "--------------------Step-13-Complete------------------------" >> /var/log/InstallationLogs/$DATE-Install-logs.log
systemctl enable backend
echo "--------------------Step-14-Complete------------------------" >> /var/log/InstallationLogs/$DATE-Install-logs.log
dnf list installed | grep mysql &>/dev/null

if [ $? -eq 0 ]; then
    echo "Mysql Command line client already installed.."
else
    echo "Mysql client not installed installing Now.."
    dnf install mysql -y &>>/var/log/InstallationLogs/$DATE-Install-logs.log
    echo "--------------------Step-15-Complete------------------------" >> /var/log/InstallationLogs/$DATE-Install-logs.log
fi
mysql -h 10.1.2.175 -uroot -pExpenseApp@1 < /app/schema/backend.sql
echo "--------------------Step-16-Complete------------------------" >> /var/log/InstallationLogs/$DATE-Install-logs.log
systemctl restart backend
echo "--------------------Step-17-Complete------------------------" >> /var/log/InstallationLogs/$DATE-Install-logs.log
