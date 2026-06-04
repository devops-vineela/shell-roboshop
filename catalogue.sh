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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling nodejs module"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling nodejs 20 module"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? " Installing nodejs"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "creating system roboshop user"

mkdir -p /app 
VALIDATE $? "creating app directory"


curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading catalogue code"

cd /app 
unzip /tmp/catalogue.zip
VALIDATE $? "Unzipping catalogue code"

npm install &>>$LOG_FILE
VALIDATE $? "Installing Dependencies"

cp $PATH/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copying catalogue systemd service file"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "reloading systemd daemon"

systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "enabling catalogue service"

systemctl start catalogue &>>$LOG_FILE
VALIDATE $? "starting catalogue service"

cp $PATH/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copying MongoDB repository file"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing MongoDB shell"

mongosh --host MONGODB-SERVER-IPADDRESS </app/db/master-data.js &>>$LOG_FILE
VALIDATE $? "Loading data to MongoDB"




