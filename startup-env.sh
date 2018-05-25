#/bin/bash
echo on

isServiceRunning(){
	echo check $1 status
	if ps ax | grep -v grep | grep $1 > /dev/null
		then
		    # 0 = true
		    return 0
		else
		    # 1 = false
		    return 1
	fi
}

getWindowId(){
	# get window id by name
	echo $(wmctrl -l | grep -i $1 | cut -f1 -d' ')
}

moveWindowToWorkspace(){
	local windowId=$(getWindowId $1)
	if [[ -z "${windowId// }" ]]
	then
		[[ ! $3 ]] && echo "waiting for $1 to open"
		sleep 1 && moveWindowToWorkspace $1 $2 0
	else
		echo "move $1 [id:$windowId] workspace #$2"
		# move window by id -> workspace by index
		wmctrl -i -r $windowId -t $2
	fi
}

startService(){
	SERVICE_NAME=$1
	WORKSPACE_NUM=$2
	COMMAND=$3
	if ! isServiceRunning $SERVICE_NAME
	then
		echo 'open '$SERVICE_NAME
		nohup $COMMAND > /dev/null 2>&1 &
		moveWindowToWorkspace $SERVICE_NAME $WORKSPACE_NUM &
	else
		echo $1' already up'
		moveWindowToWorkspace $SERVICE_NAME $WORKSPACE_NUM &
	fi	
}

SLACK_WORKSPACE_NUM=0
BROWSER_WORKSPACE_NUM=4
IDE_WORKSPACE_NUM=5
ZOOM_WORKSPACE_NUM=3

# teleport terminal to workspace #0 to see slack first
wmctrl -r :ACTIVE: -t 0
wmctrl -s 0

# ssh tunnel
echo start ssh tunnel
nohup ssh -T ci  > /dev/null 2>&1 &

# kafka
cd /home/hazem/Documents/source/inf_backbone
if ! docker-compose ps | grep -v grep | grep 'kafka' > /dev/null
then
	echo 'start kafka env'
	docker-compose down -v
	docker-compose up -d
else
	echo 'kafka env already up'
fi

# intellij
startService 'intellij' $IDE_WORKSPACE_NUM '/home/hazem/Documents/env/JetBrains/idea-IU-173.4674.33/bin/idea.sh'

# slack
startService 'slack' $SLACK_WORKSPACE_NUM '/usr/bin/slack --disable-gpu %U'

# chrome
startService 'google' $BROWSER_WORKSPACE_NUM '/usr/bin/google-chrome-stable %U'

# zoom
startService 'zoom' $ZOOM_WORKSPACE_NUM '/usr/bin/zoom %U'