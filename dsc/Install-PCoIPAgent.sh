#!/bin/bash

# the first argument is the Registration Code of PCoIP agent

# Install the EPEL repository
echo "-->Install the EPEL repository"
sudo rpm -Uvh --quiet https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

# Install the Teradici package key
echo "-->Install the Teradici package key"
sudo rpm --import https://downloads.teradici.com/rhel/teradici.pub.gpg

# Add the Teradici repository
echo "-->Add the Teradici repository"
sudo wget --retry-connrefused --tries=3 --waitretry=5 -O /etc/yum.repos.d/pcoip.repo https://downloads.teradici.com/rhel/pcoip.repo
exitCode=$?
if [ $exitCode -ne 0 ]
then
    echo "failed to add teradici repository."
    # let's define exit code 100 for this case
    exit 100
fi

# Install the PCoIP Agent
echo "-->Install the PCoIP Agent"
sudo yum -y update

for idx in {1..3}
do
    sudo yum -y install pcoip-agent-standard
    exitCode=$?
    
    if [ $exitCode -eq 0 ]
    then
        break
    else
        #delay 5 seconds
        sleep 5
        sudo yum -y remove pcoip-agent-standard
        if [ $idx -eq 3 ]
        then
            echo "failed to install pcoip agent."
            # let's define exit code 101 for this case
            exit 101
        fi
        #delay 5 seconds        
        sleep 5
    fi
done
    

# register license code
echo "-->Register license code"
for idx in {1..3}
do
    pcoip-register-host --registration-code=$1
    pcoip-validate-license    
    exitCode=$?
    
    if [ $exitCode -eq 0 ]
    then
        break
    else
        if [ $idx -eq 3 ]
        then
            echo "failed to register pcoip agent license."
            # let's define exit code 102 for this case
            exit 102
        fi
    fi
done

# Install Desktop
echo "-->Install desktop"
# sudo yum -y groupinstall "Server with GUI"
sudo yum -y groupinstall 'X Window System' 'GNOME'

# install firefox
echo "-->Install firefox"
sudo yum -y install firefox

echo "-->set default graphical target"
# The below command will change runlevel from runlevel 3 to runelevel 5 
sudo systemctl set-default graphical.target

# skip the gnome initial setup
echo "-->create file gnome-initial-setup-done to skip gnome desktop initial setup"
for homeDir in $( find /home -mindepth 1 -maxdepth 1 -type d )
do 
    confDir=$homeDir/.config
    sudo mkdir -p $confDir
    sudo chmod 777 $confDir
    echo "yes" | sudo tee $confDir/gnome-initial-setup-done
    sudo chmod 777 $confDir/gnome-initial-setup-done
done

echo "-->start graphical target"
sudo systemctl start graphical.target

(sleep 2;  sudo shutdown -f -r +0)&
exit 0