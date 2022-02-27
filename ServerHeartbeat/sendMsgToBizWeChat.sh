#!/bin/bash

webHookUrl=$1
msg=$2

curl ''"$webHookUrl"'' \
   -H 'Content-Type: application/json' \
   -d '
   {
    	"msgtype": "text",
    	"text": {
        	"content": "'"$msg"'"
    	}
   }'

echo ""
echo "sent msg $msg"

