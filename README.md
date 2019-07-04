# ReverseShell
Reverse bash shell with ssl and ssh push

The scripts are expected to be run on the host that will push its shell outbound to a server that will listen for the shell inbound.

# Example
You have a host which is heavily NAT'ed, and you are not able to open up a port for ssh. However, outgoing ports do work, and you have other servers at your disposal where you CAN open up ports on the internet.
An outgoing port is all you need to be able to connect to your shell on another server.

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

```bash
./reverseshell_activator.sh configname)
```

