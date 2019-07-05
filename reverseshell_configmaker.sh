#!/bin/bash

installdir=~/.ReverseShell #Local only

if [ "$1" == "-h" ] || [ "$1" == "--h" ] || [ "$1" == "--help" ] || [ "$1" == "-help" ]; then
	echo "this script creates the configs for diffrent hosts where you want to 'steal' a shell from without using ssh in the config dir $installdir"
	echo "just run this script to get a wizard to write a config, which you can use later with the reverseshell_activator.sh <configname> script."
fi

read -p "How would you like to name this config [$(hostname)]: " cname

if [ "$cname" == "" ]; then
	cname=$(hostname)
fi

mkdir -p $installdir/$cname
rm -f $installdir/$cname/$cname.cfg 2> /dev/null
read -p "To what remote location would you like to redirect your shell?: " rhost
redirecthost_IP=$(getent hosts $rhost | awk '{ print $1 }')
read -p "To what remote port would you like to redirect your shell?: " rport

read -p "What is the remote ssh port of that remote location? [22]: " sshport
if [ "$sshport" == "" ]; then
	sshport=22
fi

read -p "What is the sshuser of that remote location? [root]: " sshuser
if [ "$sshuser" == "" ]; then
	sshuser="root"
fi

echo "cname=$cname" >> $installdir/$cname/$cname.cfg
echo "rhost=$rhost" >> $installdir/$cname/$cname.cfg
echo "rport=$rport" >> $installdir/$cname/$cname.cfg
echo "sshport=$sshport" >> $installdir/$cname/$cname.cfg
echo "sshuser=$sshuser" >> $installdir/$cname/$cname.cfg

echo "creating SSL certs on remote/listening host!"
ssh -p $sshport -l $sshuser $rhost "mkdir -p ~/.ReverseShell/$cname;cd ~/.ReverseShell/$cname;yes '' | openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes" || echo "ssh connection FAILED, please start again!!!"
echo "backing up config to central listening server.."
scp -P $sshport ~/.ReverseShell/$cname/$cname.cfg  $sshuser@$rhost:~/.ReverseShell/$cname/$cname.cfg
echo "config $cname has been stored in $installdir/$cname/$cname.cfg !"
echo "run \"reverseshell_activator.sh $cname\" to activate this profile!"
