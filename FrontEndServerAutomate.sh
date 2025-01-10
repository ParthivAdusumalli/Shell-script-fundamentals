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
nginx -v &>>/dev/null
if [ $? -eq 0 ]; then
   echo "Nginx Web server already Installed..Type in y to redownload the Nginx"
   read "CHOICE"
   if [ "$CHOICE" == "y" ]; then
      echo "Installing Nginx Web server.."
      dnf install -y nginx &>>/var/log/InstallLogs/$DATE-Installation.log
      nginx -v &>>/dev/null
      if [ $? -eq 0 ]; then
         echo "Nginx Successfully Installed.."
      else 
          echo "Installing Nginx Failed.."
          exit 1
      fi
    else 
        echo "Skipping the Installation of Nginx.."
    fi
else 
   echo "Installing Nginx Web server.."
   dnf install -y nginx &>>/var/log/InstallLogs/$DATE-Installation.log
   nginx -v &>>/dev/null
      if [ $? -eq 0 ]; then
         echo "Nginx Successfully Installed.."
      else 
          echo "Installing Nginx Failed.."
          exit 1
      fi
fi
Checking_Conf()
{
  $1
  if [ $? -eq 0 ]; then
     echo -e "$GREEN$2 Nginx Web Server..$DEF"
  else 
      echo -e "$RED Failed to Start/enable the Nginx Web server.."
      echo -e "Terminating the Script..$DEF"
      exit 1
  fi
}
Checking_Conf "systemctl start nginx" "Started"

Checking_Conf "systemctl enable nginx" "Enabled"

LOG_FILE="/var/log/InstallLogs/$DATE-Installation.log"

rm -rf /usr/share/nginx/html/* &>>"$LOG_FILE"
if [ $? -eq 0 ]; then
        echo -e "$GREEN Removing HTML Files at /usr/share/nginx/html$DEF" >>"$LOG_FILE"
    else
        echo "$RED Failed to remove the Nginx files; please check the logs for more details.$DEF" >&2
        exit 1
fi

if test -f "/tmp/frontend.zip"; then
         echo "frontend.zip already exists removing the zip file and redownloading.."
         rm -f /tmp/frontend.zip
         curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE
         if [ $? -eq 0 ]; then
            echo "Downloaded the Zip file content successfully.."
         else 
            echo "Downloading the Zip file failed.."
            exit 1
         fi
else
    echo "Downloading the zip file.."
    curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE
    if [ $? -eq 0 ]; then
            echo "Downloaded the Zip file content successfully.."
    else 
            echo "Downloading the Zip file failed.."
            exit 1
    fi
fi
cd /usr/share/nginx/html
PRE=$(pwd)
if [ "$PRE" == "/usr/share/nginx/html" ]; then
   echo "Directory changed to /usr/share/nginx/html"
   echo "Unzipping the zip file content.."
   cd /usr/share/nginx/html
   unzip /tmp/frontend.zip
else
   echo "Failed to change the directory.."
   exit 1
fi
if  test -f "/etc/nginx/default.d/expense.conf"; then
    echo -e "$GREEN Reconfiguring the expense.conf $DEF"
    echo "proxy_http_version 1.1;
location /api/ { proxy_pass http://10.1.2.80:8080/; }
location /health {
  stub_status on;
  access_log off;
}" > /etc/nginx/default.d/expense.conf
else
    echo "Configuring the expense.conf file"
    echo "proxy_http_version 1.1;
location /api/ { proxy_pass http://10.1.2.80:8080/; }
location /health {
  stub_status on;
  access_log off;
}" > /etc/nginx/default.d/expense.conf
if [ $? -eq 0 ]; then
   echo "Successfully configured the expense.conf"
else 
   echo "Configuring the expense.conf failed.."
   exit 1
fi
fi
systemctl restart nginx
echo -e "$GREEN Restarted the Nginx Service...$DEF"