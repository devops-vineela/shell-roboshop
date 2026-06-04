#!/bin/bash
START_TIME=$(date +%s)
userid=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
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
dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "disabling redis module"

dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "enabling redis:7 module"

dnf install redis -y &>>$LOG_FILE
VALIDATE $? "installing redis"

sed -i -e 's/127.0.0.0/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "allowing remote access to redis"

systemctl enable redis &>>$LOG_FILE
VALIDATE $? "enabling redis"

systemctl start redis &>>$LOG_FILE
VALIDATE $? "starting redis"

END_TIME=$(date +%s)
EXECUTION_TIME=$(($END_TIME - $TART_TIME))
echo -e "Total execution time: $EXECUTION_TIME seconds" | tee -a $LOG_FILE