#!/bin/bash

# Variables
NODE_VER=$(node -v)
DATE=$(date +%Y-%m-%d)
LOG_DIR="/var/log/InstallationLogs"
LOG_FILE="$LOG_DIR/$DATE-Install-logs.log"
APP_DIR="/app"
BACKEND_ZIP="/tmp/backend.zip"
BACKEND_URL="https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip"
BACKEND_SERVICE="/etc/systemd/system/backend.service"
DB_HOST="10.1.2.175"
DB_USER="root"
DB_PASS="ExpenseApp@1"
DB_SCHEMA="/app/schema/backend.sql"

# Ensure Logs Directory Exists
mkdir -p $LOG_DIR

echo "Checking Node.js version..."
if [ "$NODE_VER" == "v20.17.0" ]; then
    echo "The Current Node.js version is v20.17.0"
else
    echo "Updating Node.js to version 20..."
    dnf module disable nodejs -y &> $LOG_FILE
    echo "Step 1 Complete: Disabled Node.js module" >> $LOG_FILE
    dnf module enable nodejs:20 -y &>> $LOG_FILE
    echo "Step 2 Complete: Enabled Node.js module" >> $LOG_FILE
    dnf install nodejs -y &>> $LOG_FILE
    echo "Step 3 Complete: Installed Node.js" >> $LOG_FILE
fi

# Check and Create User
if id "expense" &>/dev/null; then
    echo "User 'expense' already exists."
else
    echo "Creating user 'expense'..."
    useradd -m expense 2>>$LOG_FILE
    if [ $? -eq 0 ]; then
        echo "User 'expense' created successfully."
        echo "Step 4 Complete: Created user 'expense'" >> $LOG_FILE
    else
        echo "Error: Failed to create user 'expense'." >> $LOG_FILE
        exit 1
    fi
fi

# Check and Create App Directory
if [ -d "$APP_DIR" ]; then
    echo "The Directory $APP_DIR already exists."
else
    echo "Creating directory $APP_DIR..."
    mkdir $APP_DIR
    echo "Step 5 Complete: Created directory $APP_DIR" >> $LOG_FILE
fi

# Check and Download Backend Zip
if [ ! -f "$BACKEND_ZIP" ]; then
    echo "Downloading backend zip file..."
    curl -o $BACKEND_ZIP $BACKEND_URL
    echo "Step 6 Complete: Downloaded backend zip file" >> $LOG_FILE
else
    echo "Backend zip file already exists at $BACKEND_ZIP."
fi

# Change to App Directory
cd $APP_DIR || { echo "Error: Unable to change directory to $APP_DIR."; exit 1; }
echo "Step 7 Complete: Changed directory to $APP_DIR" >> $LOG_FILE

# Unzip Backend Code
if grep -q "Archive:  $BACKEND_ZIP" $LOG_FILE; then
    echo "Backend zip already unzipped. Skipping..."
else
    echo "Unzipping backend zip..."
    unzip $BACKEND_ZIP &>> $LOG_FILE
    echo "Step 8 Complete: Unzipped backend code" >> $LOG_FILE
fi

# Check NPM Version
NPM_V=$(npm -v)
if [ "$NPM_V" == "10.8.2" ]; then
    echo "NPM is already at version 10.8.2."
else
    echo "Installing NPM dependencies..."
    npm install &>> $LOG_FILE
    echo "Step 9 Complete: Installed NPM dependencies" >> $LOG_FILE
fi

# Configure Backend Service
if grep -q "Environment=DB_HOST" $BACKEND_SERVICE; then
    echo "Backend service already configured."
else
    echo "Configuring backend service..."
    cat <<EOF > $BACKEND_SERVICE
[Unit]
Description=Backend Service

[Service]
User=expense
Environment=DB_HOST="$DB_HOST"
ExecStart=/bin/node $APP_DIR/index.js
SyslogIdentifier=backend

[Install]
WantedBy=multi-user.target
EOF
    echo "Step 10 Complete: Configured backend service" >> $LOG_FILE
fi

# Reload and Start Backend Service
systemctl daemon-reload
systemctl start backend
systemctl enable backend

if [ $? -eq 0 ]; then
    echo "Step 11 Complete: Backend service started and enabled" >> $LOG_FILE
else
    echo "Error: Failed to start backend service." >> $LOG_FILE
    exit 1
fi

# Check and Install MySQL Client
dnf list installed | grep mysql &>/dev/null
if [ $? -eq 0 ]; then
    echo "MySQL client already installed."
else
    echo "Installing MySQL client..."
    dnf install mysql -y &>> $LOG_FILE
    echo "Step 12 Complete: Installed MySQL client" >> $LOG_FILE
fi

# Import Database Schema
mysql -h $DB_HOST -u$DB_USER -p$DB_PASS < $DB_SCHEMA
if [ $? -eq 0 ]; then
    echo "Step 13 Complete: Imported database schema" >> $LOG_FILE
else
    echo "Error: Failed to import database schema." >> $LOG_FILE
    exit 1
fi

# Restart Backend Service
systemctl restart backend
if [ $? -eq 0 ]; then
    echo "Step 14 Complete: Restarted backend service" >> $LOG_FILE
else
    echo "Error: Failed to restart backend service." >> $LOG_FILE
    exit 1
fi
echo "Also Installing the Other dependencies.."
npm install mysql2
systemctl daemon-reload
systemctl restart backend
echo "Script completed successfully. Check $LOG_FILE for details."
