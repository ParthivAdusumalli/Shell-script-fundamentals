#!/bin/bash
if [ $(id -u) -eq 0 ]; then
   echo "Running the script with Root user privilages.."
else
    echo "Run the script with Root user privilages.."
    exit 1
fi

if [ -d "var/log/InstallLogs/" ]; then
   echo "Log directory already exists"
else 
    mkdir var/log/InstallLogs/
fi

DATE=$(date +%Y-%m-%d)

LOGFILE="var/log/InstallLogs/$DATE-Installs.log"

CheckAll()
{
  if [ $? -ne 0 ]; then
   echo "Error configuring the application server..Check the Logs.."
   exit 1
   fi
}

grep "Software Installation done" $LOGFILE &>/dev/null
if [ $? -eq 0 ]; then
{
    echo "Software configuration already completed.."
    exit 1
}
else 
    echo "Starting Application layer configuration"
    dnf module disable nodejs -y &>var/log/InstallLogs/$DATE-Installs.log
    CheckAll
    dnf module enable nodejs:20 -y &>>var/log/InstallLogs/$DATE-Installs.log
    CheckAll
    dnf install nodejs -y &>>var/log/InstallLogs/$DATE-Installs.log
    CheckAll
    useradd expense &>>var/log/InstallLogs/$DATE-Installs.log
    CheckAll
    mkdir /app &>>var/log/InstallLogs/$DATE-Installs.log
    CheckAll
    curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>var/log/InstallLogs/$DATE-Installs.log
    CheckAll
    unzip /tmp/backend.zip &>>var/log/InstallLogs/$DATE-Installs.log
    CheckAll
    cd /app
    npm install &>>var/log/InstallLogs/$DATE-Installs.log
    CheckAll
    echo '[Unit]
Description = Backend Service

[Service]
User=expense
Environment=DB_HOST="10.1.2.215"
ExecStart=/bin/node /app/index.js
SyslogIdentifier=backend

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/backend.service 
if [ $? -ne 0 ]; then
   echo "Error configuring the backend service..Check the Logs.."
   exit 1
fi
systemctl daemon-reload &>>var/log/InstallLogs/$DATE-Installs.log
CheckAll
systemctl start backend &>>var/log/InstallLogs/$DATE-Installs.log
CheckAll
systemctl enable backend &>>var/log/InstallLogs/$DATE-Installs.log
CheckAll
dnf install mysql -y &>>var/log/InstallLogs/$DATE-Installs.log
CheckAll
mysql -h "10.1.2.215" -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>var/log/InstallLogs/$DATE-Installs.log
CheckAll
systemctl restart backend &>>var/log/InstallLogs/$DATE-Installs.log
CheckAll
echo "Software Installation done" > $LOGFILE
fi
