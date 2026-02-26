#!/bin/bash
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-logs"
mkdir -p $LOGS_FOLDER
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

CHECK_ROOTUSER (){
    if [ $USERID -ne 0 ]
    then
        echo -e "$R Switch to root user"
    else
        echo -e "$G Have Root Access"
    fi
}

echo -e "Script started......" &>>$LOG_FILE_NAME

CHECK_ROOTUSER &>>$LOG_FILE_NAME

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$R ERROR:: $N $2 Failed"
    else
        echo -e "$G Sucess:: $N $2 Success"
    fi
}

dnf install nginx -y &>>$LOG_FILE_NAME
VALIDATE $? "Nginx installation ..."

systemctl enable nginx &>>$LOG_FILE_NAME
VALIDATE $? "Nginx enable ...."

rm -rf /usr/share/nginx/html/*
VALIDATE $? "Removing conetnt in html folder ..."

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip
VALIDATE $? "FrontEnd zip folder created ...."

cd /usr/share/nginx/html

unzip /tmp/frontend.zip
VALIDATE $? "unzipping frontend code...."

cp /home/ec2-user/Devops_VeeraManikanta/expense-shell_scripting/expense.conf /etc/nginx/default.d/expense.conf
VALIDATE $? "Copied expense config"

systemctl start nginx &>>$LOG_FILE_NAME
VALIDATE $? "Restarting nginx"

