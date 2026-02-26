#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
IPADDRESS=$1
LOGS_FOLDER="/var/log/expense-logs"
mkdir -p $LOGS_FOLDER
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

echo -e "$G Started backend server configuration $N "
 
echo "Script started at: $TIMESTAMP" &>>$LOG_FILE_NAME

if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: $N You dont have correct permisiions to execute this file"
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$R ERROR:: $N $2 Failed"
    else
        echo -e "$G Sucess:: $N $2 Success"
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "DEFAULT NODEJS VERSION DISABILING..."

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "Nodejs 20 version download...."

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Nodejs installation...."

useradd expense &>>$LOG_FILE_NAME
if [ $? -ne 0 ]
then
    echo -e "$G User already exists $N "
else
    echo -e "$G user add success $N"
mkdir -p /app &>>$LOG_FILE_NAME
VALIDATE $? "Creating app directory..."

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Doenload backend..."

cd /app
rm -rf /app/*
unzip /tmp/backend.zip &>>$LOG_FILE_NAME
VALIDATE $? "Unziping the backend code ..."

npm install &>>$LOG_FILE_NAME
VALIDATE $? " Installing dependencies..."

cp /home/ec2-user/Devops_VeeraManikanta/expense-shell_scripting/backend.service /etc/systemd/system/backend.service

#PREPARE MYSQL SCHEMA

dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing MySQL Client"

mysql -h $IPADDRESS -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE_NAME
VALIDATE $? "SETTING UP THE TRANSACTIONS AND DATABASES"

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "Daemon Reload ..."

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "Enabling backend service"

systemctl restart backend &>>$LOG_FILE_NAME
VALIDATE $? "Start backend service"






