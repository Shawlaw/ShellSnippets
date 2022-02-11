#!/bin/bash

# this script is under the same folder of metabase.jar

PARAM_RUN_IN_BG="bg"
needRunInBackground="false"
for arg in "$@"; do
  case "$arg" in
  "$PARAM_RUN_IN_BG")
    needRunInBackground="true"
    ;;
  *)
    echo ""
    echo "Unsupport arg[$arg]"
    ;;
  esac
done

enableSsl="true"
sslParam="&sslmode=require&ssl=true&sslfactory=org.postgresql.ssl.NonValidatingFactory"
if [ "$enableSsl" != "true" ]; then
    sslParam=""
fi

dbHost="dbHost"
dbPort="5432"
dbUser="user"
dbPwd="pwd"
dbName="metabase"

export MB_DB_CONNECTION_URI="jdbc:postgresql://$dbHost:$dbPort/$dbName?user=$dbUser&password=$dbPwd$sslParam"
export MB_DB_TYPE="postgres"

export JAVA_TIMEZONE="Asia/Shanghai"

export MB_JETTY_PORT=3000
export MB_JETTY_HOST="0.0.0.0"

if [ "$needRunInBackground" == "true" ]; then
    logPath="./mb_startAt_$(date +%Y%m%d_%H%M%S).log"
    java -jar ./metabase.jar > $logPath 2>&1 &
    echo "MetaBase is starting..."
    sleep 5
    runningProcId=$(ps aux | grep -v grep | grep "java -jar ./metabase.jar" | awk '{print $2}')
    if [ ! -z "$runningProcId" ]; then
        echo "MetaBase started successfully, procId = $runningProcId"
        echo "Logs are located in file $logPath"
    else
        echo "MetaBase fails to start"
        echo "Please check $logPath for more detail"
    fi
else
    java -jar ./metabase.jar
fi