# ReverseShell
Reverse bash shell with ssl and ssh push

The scripts are expected to be run on the host that will push its shell outbound to a server that will listen for the shell inbound.

# Example
You have a host which is heavily NAT'ed, and you are not able to open up a port for ssh. However, outgoing ports do work, and you have other servers at your disposal where you CAN open up ports on the internet.
An outgoing port is all you need to be able to connect to your shell on another server. The listening server here will be a server you completely own, that collects all the shells of hosts who are hard to connect to.

# Prerequisites
I'm listing all prerequisites here who are *a bit* less common.

* screen
* openssl
* mkfifo

# Usage
## reverseshell_configmaker.sh

This scripts will create configs in a predefined installdir, to store vars of our hosts (defaults to ~/.ReverseShell, setable in the scripts $installdir constant)
This is an interactive wizard which needs no parameters. It will also generate the certificates.
All certs, keys and configs WILL be synced between the sender and listener hosts, so they are accesible everywhere.
configs are distinguished by their name (asked in the wizard), and can be overwritten if needed when using the same name.

```bash
./reverseshell_configmaker.sh
```

I mean... seriously...

```bash
./reverseshell_configmaker.sh --h
```

What more can I say?


## reverseshell_activator.sh

This script will make it all happen. It expects the configname as only parameter (given in the reverseshell_configmaker.sh script), and will load all needed variables from it.
It will start the listener (with SSL) on the receiving host in a screen session, connect a bash shell (over SSL) with the specified parameters.
When the shell is redirected, you can open up the given screen session in the receiving host, this is now an interactive shell on your sending host!

```bash
./reverseshell_activator.sh $(ls ~/.ReverseShell/ | head -n1)
```
or just...


And yes,...

```bash
./reverseshell_activator.sh --h
```

## reverseshell_agent.sh

This script will just run the activator in a loop in a screen as an agent. Put this script in crontab if you want to autostart the agent on a system to automaticly connect its shell to a listening host.
This also comes with an extra control proces. See section *Autoreconnect Robustness* below.

```bash
./reverseshell_agent.sh configname
```

And yes,...

```bash
./reverseshell_agent.sh --h
```

## minimalfiles
These scripts have the same usage, but provide a more slimmed down version to work in environments like busybox.
You can use this 'branch' of the scripts to use an alternative client, for example when your shell has limitations or when you are missing vital binaries.

## reverseshell_stopper
This script will stop all processes involved on the client (sending host) of that particular config. The server's (listening host) screen/process is cleaned out automaticly with each start. 

```bash
./reverseshell_stopper.sh configname
```

And ofcourse,...

```bash
./reverseshell_agent.sh --h
```

# AutoReconnect Robustness
## explanation
The proces is created (read: 'looped') to restart the OPENSSL sender on the client automaticly when it stops, gets killed, whatever. Then, in turn, the activator will recreate the listener tener on the listening host, to make sure all points are up and running.

*However,*

Sometimes the openssl client gets "stuck" when a connection is abruptly broken off, leaving it in a perpetual TIMEOUT state. This is where the above explained restarter **does not intervene**. I have added an extra controlproces for that:

## reverseshell agent extra control proces
The controlproces will check if the listener screen is still present on the listening host. When this is not the case, it will restart the entire reverseshell proces automaticly.
**This effectively means that, when a user aborts the listening screen on the listening host, the proces will be restarted from the clients side, effectively giving the user to initiate a remote restart of the reverseshell.**
this is extremely usefull when the reverse shell is run in a heavily firewalled environment (cuts off random idle connections) or a heavily bad-quality network.
