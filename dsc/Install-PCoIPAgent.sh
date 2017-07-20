#!/bin/bash

install_driver()
{
    # Install kernel-source/kernel-devel and gcc
    sudo yum -y install kernel-source kernel-devel gcc
    FILE_NAME='NVIDIA-Linux-x86_64-367.106-grid.run'
    FILE_LOCATION='/root/'$FILE_NAME
    # Download Driver first
    echo "Downloading and Installing Nvidia driver"
    sudo wget --retry-connrefused --tries=3 --waitretry=5 -O $FILE_LOCATION https://binarystore.blob.core.windows.net/thirdparty/nvidia/$FILE_NAME
    exitCode=$?
    if [ $exitCode -ne 0 ]
    then
        echo "failed to download Nvidia driver."
        # let's define exit code 103 for this case
        exit 103
    fi
    # Change file permission
    sudo chmod 744 $FILE_LOCATION
    # run installer
    sudo $FILE_LOCATION -Z -X -s
    exitCode=$?
    
    if [ $exitCode -eq 0 ]
    then
        echo "Driver is installed successfully"
    else
        echo "failed to install Nvidia driver. Will create a script to install driver when machine boots up"
        file_path=/root/install_driver.sh
        cat <<EOF >$file_path
#!/bin/bash
if [ -e /root/.first_boot ]
then
    if [ -e /root/.second_boot ]
    then
        exit 0
    else
        touch /root/.second_boot
        sudo $FILE_LOCATION -Z -X -s        
    fi
else
    touch /root/.first_boot
    sudo $FILE_LOCATION -Z -X -s
    (sleep 2;  sudo shutdown -f -r +0)&
fi
EOF
        sudo chmod 744 $file_path
        (crontab -l 2>/dev/null; echo "@reboot $file_path") | crontab -
        # let's define exit code 104 for this case
        #exit 104
    fi
}

# the first argument is the Registration Code of PCoIP agent
REGISTRATION_CODE=$1
# the second argument is the agent type
AGENT_TYPE=$2

# Make sure Linux OS is up to date
echo "--> Updating Linux OS to latest"
# Exclude WALinuxAgent due to it failing to update from within an Azure Custom Script
sudo yum -y update --exclude=WALinuxAgent

# If it's graphic agent, install Nvidia Driver
case "$AGENT_TYPE" in 
    "Graphics")
        install_driver
        AGENT_TYPE='graphics'
        ;;
    "Standard")
        AGENT_TYPE='standard'
        ;;   
    *)
        echo "unknown agent type $AGENT_TYPE."
        # let's define exit code 105 for this case
        exit 105
        ;;       
esac

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
echo "-->Install the PCoIP $AGENT_TYPE agent"
for idx in {1..3}
do
    sudo yum -y install pcoip-agent-$AGENT_TYPE
    exitCode=$?
    
    if [ $exitCode -eq 0 ]
    then
        break
    else
        #delay 5 seconds
        sleep 5
        sudo yum -y remove pcoip-agent-$AGENT_TYPE
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
    pcoip-register-host --registration-code=$REGISTRATION_CODE
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
        sleep 5
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