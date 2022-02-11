#!/bin/bash

runningProcId=$(ps aux | grep -v grep | grep "java -jar ./metabase.jar" | awk '{print $2}')
if [ -z $runningProcId ]; then
    echo "MetaBase is not running, nothing to do"
else
    kill -s TERM $runningProcId
    echo "Stoping MetaBase……"
    sleep 5
    runningProcId=$(ps aux | grep -v grep | grep "java -jar ./metabase.jar" | awk '{print $2}')
    if [ -z "$runningProcId" ]; then
        echo "MetaBase has been stopped"
    else
        echo "Failed to stop MetaBase"
        echo "Please run 'kill -s TERM $runningProcId' manually to stop it"
    fi
fi
