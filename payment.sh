#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)

# Color codes
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# Logging
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(basename "$0" | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

# Check root privileges
if [ $USERID -ne 0 ]; then
    echo -e "$R ERROR: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

# Validation function
VALIDATE() {
    if [ $1 -eq 0 ]; then
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

# Install dependencies
dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "Installing Python3 packages"

# Create system user
id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop already exists ... $Y SKIPPING $N" | tee -a $LOG_FILE
fi

# Prepare application
mkdir -p /app
VALIDATE $? "Creating /app directory"

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading payment zip"

rm -rf /app/*
cd /app

unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "Unzipping payment zip"

pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "Installing Python dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>$LOG_FILE
VALIDATE $? "Copying payment.service"

# Systemd setup
systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reload"

systemctl enable payment &>>$LOG_FILE
VALIDATE $? "Enabling payment service"

systemctl start payment &>>$LOG_FILE
VALIDATE $? "Starting payment service"

# Final log
END_TIME=$(date +%s)
TOTAL_TIME=$(( END_TIME - START_TIME ))
echo -e "$G Script execution completed successfully. $Y Time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
