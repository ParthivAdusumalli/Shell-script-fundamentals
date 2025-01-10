#!/bin/bash
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
DEF="\e[0m"
DATE=$(date +%Y-%m-%d)
if  test -d "/var/log/InstallationLogs/" ; then
       echo -e "$YELLOW Logs Directory exists..$DEF"     
else
    echo -e "$GREEN Creating Logs Directory $DEF"
    mkdir /var/log/InstallationLogs/
fi
if [ "$(node -v)" == "v20.17.0" ]; then
   echo "Node JS version is already on v20.17.0"
   echo "Type 'y' if you would like to re-install.. "
   read "CHOICE"
   if [ "$CHOICE" == "y" ]; then
      echo "Installing Node JS v20.17.0"
      dnf module disable nodejs -y &> /var/log/InstallationLogs/$DATE-Install-logs.log
      dnf module enable nodejs:20 -y &>> /var/log/InstallationLogs/$DATE-Install-logs.log
      dnf install nodejs -y &>> /var/log/InstallationLogs/$DATE-Install-logs.log
      if [ "$(node -v)" == "v20.17.0" ]; then
       echo -e "$GREEN Successfully configured the nodejs v20 $DEF"
      else 
        echo -e "$RED Configuring Node JS v20 Failed..Check logs $DEF"
        exit 1
      fi
   else 
       echo "Skipping the Node.JS Installation."
       fi
else 
    echo "Installing Node JS now.."
    dnf module disable nodejs -y &> /var/log/InstallationLogs/$DATE-Install-logs.log
      dnf module enable nodejs:20 -y &>> /var/log/InstallationLogs/$DATE-Install-logs.log
      dnf install nodejs -y &>> /var/log/InstallationLogs/$DATE-Install-logs.log
      if [ "$(node -v)" == "v20.17.0" ]; then
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
rm -rf /app &>>/var/log/InstallationLogs/$DATE-Install-logs.log
if [ $? -eq 0 ]; then
   echo "Removed the already existing /app Directory... "
else
   echo "Directory Not exist.Creating Now"
   sudo mkdir /app
fi
ls -l / | grep app
if [ $? -eq 0 ]; then
   echo -e "$GREEN Directory /app Successfully created. $DEF"
else
    echo -e "$RED Directory /app creating failed. $DEF"
    exit 1
fi
if  test -f "/tmp/backend.zip" ; then
    echo "backend.zip already exist. Deleting now and will be redownloaded."
    rm -f /tmp/backend.zip
    curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip
    cd /app
    echo "Unzipping the backend.zip at /app"
    unzip /tmp/backend.zip
    cd /app
else
    echo "Downloading the backend.zip file.."
    curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip
    cd /app
    PRESENTW_D=$(pwd)
    if [ "$PRESENTW_D" == "/app" ]; then
       echo -e "$GREEN Current working directory is /app $DEF"
       echo "Unzipping the backend.zip at /app"
       unzip /tmp/backend.zip
    else
       echo -e "$RED Unable to change directory.$DEF"
       exit 1
    fi
    cd /app
fi
if [ "$(pwd)" == "/app" ]; then
   echo -e "$GREEN Current working directory is /app $DEF"
else
   echo -e "$RED Unable to change directory.$DEF"
   exit 1
fi
echo "Installing Node Package manager."
npm install
if [ $? -eq 0 ]; then
   echo "Installing NPM Success"
else
    echo "installing NPM Failed."
    exit 1
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
Environment=DB_HOST="10.1.2.103"
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
    echo -e "$YELLOW Mysql Command line client already installed..Type y if you would like to redownload..$DEF"
    read "CHOICE_2"
    if [ "$CHOICE_2" == "y" ]; then
            echo "Installing Mysql Command line client.."
            dnf install mysql -y &>>/var/log/InstallationLogs/$DATE-Install-logs.log
    else
        echo "Skipping installation of Mysql.."
   fi
else
    echo -e "$YELLOW Mysql client not installed installing Now..$DEF"
    dnf install mysql -y &>>/var/log/InstallationLogs/$DATE-Install-logs.log
fi
grep "Configuring Schema Completed" /var/log/InstallationLogs/$DATE-Install-logs.log
if [ $? -eq 0 ]; then
   echo -e "$YELLOW DB Schema Already configured..$DEF"
else
    mysql -h 10.1.2.103 -uroot -pExpenseApp@1 < /app/schema/backend.sql
    echo -e "$GREEN Configuring Schema Completed $DEF" >> /var/log/InstallationLogs/$DATE-Install-logs.log
fi
systemctl restart backend
#echo -e "$GREEN Adding Other dependencies...$DEF"
 #  npm install mysql2
#systemctl status backend | grep "active (running)"
#if [ $? -eq 0 ];then
 #  echo -e "$GREEN Backend Service up and running..$DEF"
  # else
   #    echo -e "$RED Backend Service Still failing $DEF"
    #   exit 1
#fi
systemctl daemon-reload
systemctl restart backend