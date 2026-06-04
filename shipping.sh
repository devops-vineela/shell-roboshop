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
script_dir=$PWD
mkdir -p $LOGS_FOLDER
echo "please enter mysql root password:"
read -s MYSQL_ROOT_PASSWORD


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

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing maven"

id roboshop
if [ $? -ne 0 ]
then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
  VALIDATE $? "creating system roboshop user"
else
  echo -e "roboshop User already created....$Y SKIPPING $N" | tee -a $LOG_FILE
fi

mkdir -p /app 
VALIDATE $? "creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading shipping code"

cd /app 
rm -rf /app/*
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Unzipping shipping code"

mvn clean package &>>$LOG_FILE
VALIDATE $? "building shipping code"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "Renaming shipping jar file"

cp $script_dir/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
VALIDATE $? "Copying shipping systemd service file"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Reloading systemd manager configuration"

systemctl enable shipping &>>$LOG_FILE
systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Starting shipping service"

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing mysql client"

mysql -h mysql.daws-84s.bond -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql
mysql -h mysql.daws-84s.bond -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql 
mysql -h mysql.daws-84s.bond -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql
VALIDATE $? "Loading shipping schema and data in mysql"

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Restarting shipping service"

END_TIME=$(date +%s)
EXECUTION_TIME=$(($END_TIME - $START_TIME))
echo -e "Total execution time: $EXECUTION_TIME seconds" | tee -a $LOG_FILE




