#!/bin/bash
START_TIME=$(date +%s)
userid=$(id -u)
PATH=$PWD
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 |cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
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

cp $PATH/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying mongo.repo file"

dnf install mongodb-org -y &>> $LOG_FILE
VALIDATE $? "Installing MongoDB"

systemctl enable mongod &>> $LOG_FILE
VALIDATE $? "Enabling MongoDB"

systemctl start mongod &>> $LOG_FILE
VALIDATE $? "Starting MongoDB"

sed -i "s/127.0.0.0/0.0.0.0/g" /etc/mongod.conf
VALIDATE $? "Allowing remote access to MongoDB"

systemctl restart mongod &>> $LOG_FILE
VALIDATE $? "Restarting MongoDB"

END_TIME=$(date +%s)
EXECUTION_TIME=$(($END_TIME - $START_TIME))
echo -e "Total execution time: $EXECUTION_TIME seconds" | tee -a $LOG_FILE