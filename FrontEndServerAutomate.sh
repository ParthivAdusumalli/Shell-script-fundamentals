#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
DEF="\e[0m"

USERNAME=$(id -u)
if [ $USERNAME -ne 0 ]; then
   echo "Run the script with Root user Privilages.."
   exit 1 
fi
echo "Running the script as Root User..."
DATE=$(date +%Y%m%d)

if [ -d "/var/log/InstallLogs/" ]; then
    echo -e "$GREEN Directory /var/log/InstallLogs/ exists.$DEF"
else
    echo -e "$YELLOW Directory does not exist. Creating Now..$DEF"
    mkdir /var/log/InstallLogs/
fi

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

Checking_Software nginx
systemctl start nginx &>>/dev/null 

Checking_Conf()
{
  if [ $? -eq 0 ]; then
     echo -e "$GREEN$1 Nginx Web Server..$DEF"
  else 
      echo -e "$RED Failed to Start/enable the Nginx Web server.."
      echo -e "Terminating the Script..$DEF"
      exit 1
  fi
}
Checking_Conf Started

systemctl enable nginx

Checking_Conf Enabled

LOG_FILE="/var/log/InstallLogs/$DATE-Installation.log"

# Check if the log entry indicating the files were removed already exists
grep -q "Removing HTML Files for the first time" "$LOG_FILE" &>>/dev/null
if [ $? -eq 0 ]; then
    echo "Files have already been configured in the Nginx directory; skipping deletion."
else
    rm -rf /usr/share/nginx/html/* &>>"$LOG_FILE"
    if [ $? -eq 0 ]; then
        # Log the message indicating successful removal
        echo -e "$GREEN Removing HTML Files for the first time" >>"$LOG_FILE"
        echo "HTML files in the Nginx directory have been successfully removed for the first time.$DEF"
    else
        echo "$RED Failed to remove the Nginx files; please check the logs for more details.$DEF" >&2
        exit 1
    fi
fi
#Downloading the frontend Content of application
if [ -f "/tmp/frontend.zip" ]; then
   echo "Front End Zip file Already Present.."
else
    echo -e "$GREEN Downloading the Front end Content.."
    curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip 2>&1 | tee -a "$LOG_FILE"
    echo -e "Unzipping the content $DEF"
    cp /tmp/frontend.zip /usr/share/nginx/html
    if [ $? -eq 0 ]; then
       echo "Copied Zip file successfully"
    else 
        echo "Copying files failed.."
    fi
    unzip /tmp/frontend.zip
fi

if [ -f "/etc/nginx/default.d/expense.conf" ]; then
   echo -e "$GREEN Nginx conf set up Already completed..$DEF"
else
touch /etc/nginx/default.d/expense.conf

echo "proxy_http_version 1.1;

location /api/ { proxy_pass http://10.1.2.190:8080/; }

location /health {
  stub_status on;
  access_log off;
}" >> /etc/nginx/default.d/expense.conf

fi
cd /usr/share/nginx/html
PRE_WD=$(pwd)
if [ "$PRE_WD" == "/usr/share/nginx/html" ]; then
   echo "Present working directory is /usr/share/nginx/html"
   unzip /usr/share/nginx/html/frontend.zip
else 
    echo "Changing directory failed.."
fi
echo -e "$GREEN Restarting the Nginx Service...$DEF"
systemctl restart nginx