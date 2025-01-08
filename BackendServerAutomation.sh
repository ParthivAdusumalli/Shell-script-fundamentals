#!/bin/bash

# Initialize variables
DATE=$(date +%Y-%m-%d)
LOG_FILE="/var/log/InstallLogs/${DATE}-Installation.log"
TARGET="/app"

# Check for root privileges
if [ $(id -u) -ne 0 ]; then
    echo "Run the script with root privileges."
    exit 1
fi

# Ensure log directory exists
mkdir -p /var/log/InstallLogs/

# Function to check command success
Checking_Configuration() {
    $1 &>>"$LOG_FILE"
    if [ $? -ne 0 ]; then
        echo "$2"
        exit 1
    fi
}

# Ensure script runs only once
if grep -q "Configuration Of Backend Service complete" "$LOG_FILE" &>/dev/null; then
    echo "Backend Service Configuration completed already."
    exit 1
fi

# Disable and enable Node.js module
echo "Configuring the backend service with Node.js v20..."
Checking_Configuration "dnf module disable nodejs -y" "Disabling Node.js v16 failed. Check logs."
Checking_Configuration "dnf module enable nodejs:20 -y" "Enabling Node.js v20 failed. Check logs."

# Install Node.js
Checking_Configuration "dnf install nodejs -y" "Installing Node.js v20 failed."

# Create user if not exists
id -u expense &>/dev/null || useradd expense

# Ensure application directory exists
mkdir -p "$TARGET"

# Download and extract backend application
if [ ! -f "/tmp/backend.zip" ]; then
    curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>"$LOG_FILE"
fi
cd "$TARGET" || { echo "Failed to change directory to $TARGET"; exit 1; }
unzip -o /tmp/backend.zip &>>"$LOG_FILE"

# Install dependencies
if [ "$PWD" == "$TARGET" ]; then
    Checking_Configuration "npm install" "Installing npm dependencies failed."
else
    echo "Current directory is not $TARGET. Terminating."
    exit 1
fi

# Create and configure systemd service
if [ ! -f "/etc/systemd/system/backend.service" ]; then
    cat <<EOL > /etc/systemd/system/backend.service
[Unit]
Description=Backend Service

[Service]
User=expense
Environment=DB_HOST="54.196.22.207"
ExecStart=/bin/node /app/index.js
SyslogIdentifier=backend

[Install]
WantedBy=multi-user.target
EOL
fi

# Reload systemd, enable and restart the service
Checking_Configuration "systemctl daemon-reload" "Reloading systemd daemon failed."
Checking_Configuration "systemctl enable backend" "Enabling backend service failed."
Checking_Configuration "systemctl restart backend" "Restarting backend service failed."

# Install MySQL and load schema
Checking_Configuration "dnf install mysql -y" "Installing MySQL CLI failed."
Checking_Configuration "mysql -h 54.196.22.207 -uroot -p ExpenseApp@1 < /app/schema/backend.sql" "Loading schema failed."

# Mark installation as complete
echo "Configuration Of Backend Service complete" >>"$LOG_FILE"
