#!/bin/bash
userid=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs
SCRIPT_NAME=$(echo $0 |cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
PATH=$PWD
mkdir -p $LOGS_FOLDER

# checks the user has root priviliges or not
if [ $userid -ne 0 ]
then 
  echo -e "$R Error:: you should run this script with root access $N" | tee -a $LOG_FILE
  exit 1
else
  echo -e "$G you are running with root access $N" | tee -a $LOG_FILE
fi

VALIDATE(){
    if [ $1 -ne 0 ]
    then
      echo  -e "$2 is  $R FAILURE $N" | tee -a $LOG_FILE
      exit 1
    else
      echo -e "$2 is $G SUCCESS $N" |tee -a $LOG_FILE
    fi
}

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "disabling nginx module"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "enabling nginx:1.24 module"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "installing nginx"

systemctl enable nginx &>>$LOG_FILE
systemctl start nginx &>>$LOG_FILE
VALIDATE $? "starting nginx"
rm -rf /usr/share/nginx/html/* 
VALIDATE $? "removing default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
VALIDATE $? "Downloading frontend code"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Unzipping frontend code"

rm -rf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "removing nginx default configuration"

cp $PATH/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copying nginx configuration"

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Restarting nginx"