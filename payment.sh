#!/bin/bash
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

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "Installing Python3 and dependencies"

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

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading payment code"

cd /app 
rm -rf /app/*
unzip /tmp/payment.zip & >>$LOG_FILE
VALIDATE $? "Unzipping payment code"

pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "Installing payment dependencies"

cp $script_dir/payment.service /etc/systemd/system/payment.service &>>$LOG_FILE
VALIDATE $? "copying payment systemd service file"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "reloading systemd daemon"

systemctl enable payment &>>$LOG_FILE
VALIDATE $? "enabling payment service"

systemctl start payment &>>$LOG_FILE
VALIDATE $? "starting payment service"

END_TIME=$(date +%s)
EXECUTION_TIME=$(($END_TIME - $START_TIME))
echo -e "Total execution time: $EXECUTION_TIME seconds" | tee -a $LOG_FILE



