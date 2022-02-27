## Usage

0. **Only support single word msg yet**

1. Fill your webHookUrl of bizWeChat in ***local.properties.sample***

2. Rename ***local.properties.sample*** to ***local.properties***

3. 
``` shell
# to run in background sending "HiThere" every 3600 seconds
./sendHeartbeatMsgToBizWeChatInBg HiThere 3600

# to stop background process
./stopHeartbeat

# to run in foreground sending "Bazinga" every 7200 seconds
./sendHeartbeatMsgToBizWeChat Bazinga 7200
```