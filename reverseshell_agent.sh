#!/bin/sh

BRED="\033[1;31m"
BYELLOW='\033[1;93m'
BORANGE='\033[01;38;5;214m'
BGREEN='\033[1;92m'
NOCOLOR='\033[0m'

if [ "$1" == "-h" ] || [ "$1" == "--h" ] || [ "$1" == "--help" ] || [ "$1" == "-help" ]; then
        echo "this scripts will run an agent in screen that will keep trying to redirect the shell to the listening server."
        echo "just run this script to get a wizard to loop a config activation."
fi

cname=$1
installdir=~/.ReverseShell #For local only, remote is static

if [ -f $installdir/$cname/$cname.cfg ]; then
	. $installdir/$cname/$cname.cfg
else
	echo "error: $cname config not found! please check $installdir or run reverseshell_configmaker.sh again!!"
	echo "valid configs: $(ls $installdir | xargs)"
	exit 2
fi

#Make sure there are no previous sessions running!
echo -e "${BYELLOW}Making sure there are no previous sessions active...${NOCOLOR}"
ssh -t -p $sshport -l $sshuser $rhost "screen -ls | grep reverseshellAgent_$cname | cut -d '.' -f 1 | xargs kill -9 2>/dev/null && screen -wipe"

echo -e "${BYELLOW}Starting screen for agent...${NOCOLOR}"
#Start the screen for the agent
screen -dmS reverseshellAgent_$cname
#Start the agent in the screen in a loop
screen -S reverseshellAgent_$cname -X stuff "while true;do echo '' | ./reverseshell_activator.sh $cname;done"`echo -ne '\015'`

echo -e "${BYELLOW}Starting screen for control...${NOCOLOR}"
#Start the screen for the controlline
screen -dmS reverseshellControl_$cname
#Start the control process in a loop, but first give the activator some time to create the listener on the other host
sleep 1
screen -S reverseshellControl_$cname -X stuff "while true;do ssh -t -p $sshport -l $sshuser $rhost \"screen -ls | grep listener_$cname | wc -l\" 2> /dev/null > /tmp/screens_$cname; cat /tmp/screens_$cname;sleep 5"`echo -ne '\015'`
screen -S reverseshellControl_$cname -X stuff "if [[ \$(cat /tmp/screens_$cname) = *'0'* ]]; then echo restarting session...;ps aux | grep s_client | grep $rport | awk '{print \$2}' | xargs kill -9;fi; done"`echo -ne '\015'`
