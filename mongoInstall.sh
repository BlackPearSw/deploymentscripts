privip=$1
keymet=$2
pm2pr=$3
pm2pu=$4
uname=$5
host=$6

#upgrade server install
sudo apt-get update && sudo apt-get -y upgrade

#switch auto updates on for security updates
sudo apt-get install -y unattended-upgrades
sudo sed -i -e '$a\APT::Periodic::Unattended-Upgrade "1";' /etc/apt/apt.conf.d/10periodic

#install ntp
sudo apt-get update
sudo apt-get install --yes ntp

#install node
sudo apt-get update
curl -sL https://deb.nodesource.com/setup_0.12 | sudo bash -
sudo apt-get install -y nodejs

#update npm
sudo npm install npm -g

# Configure mongodb.list file with the correct location
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list

# Install updates
sudo apt-get -y update

#Install Mongo DB
sudo apt-get install -y mongodb-org

#Disable THP for Mongo DB
sudo su -c "cat << EOF > /etc/init.d/disable-transparent-hugepages
#!/bin/sh
### BEGIN INIT INFO
# Provides:          disable-transparent-hugepages
# Required-Start:    $local_fs
# Required-Stop:
# X-Start-Before:    mongod mongodb-mms-automation-agent
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Disable Linux transparent huge pages
# Description:       Disable Linux transparent huge pages, to improve
#                    database performance.
### END INIT INFO

case $1 in
  start)
    if [ -d /sys/kernel/mm/transparent_hugepage ]; then
      thp_path=/sys/kernel/mm/transparent_hugepage
    elif [ -d /sys/kernel/mm/redhat_transparent_hugepage ]; then
      thp_path=/sys/kernel/mm/redhat_transparent_hugepage
    else
      return 0
    fi

    echo 'never' > ${thp_path}/enabled
    echo 'never' > ${thp_path}/defrag

    unset thp_path
    ;;
esac
EOF"

sudo chmod 755 /etc/init.d/disable-transparent-hugepages
sudo update-rc.d disable-transparent-hugepages defaults

#install pm2
sudo npm install pm2 -g

#Install pm2 server monitor
su - $uname -c "pm2 install pm2-server-monit"

#mount data disk
hdd="/dev/sdc"
sudo echo "n
p
1


w
"|sudo fdisk $hdd
sudo mkfs -t ext4 /dev/sdc1
sudo mkdir /datadrive
sudo mount /dev/sdc1 /datadrive
sudo mkdir /datadrive/mongodb
sudo chown mongodb:mongodb /datadrive/mongodb

#update mongo config
sudo sed -i "/dbPath/s/var\/lib/datadrive/" /etc/mongod.conf

#restart mongodb
sudo service mongod restart

#Install pm2 mongodb module
su - $uname -c "pm2 install pm2-mongodb"

#create autossh user and create empty authorised_keys file
sudo adduser --system --group --shell /bin/bash --disabled-password autossh
su - autossh -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys"
sudo chsh --shell /bin/false autossh

#sudo adduser --system --group --shell /bin/false --disabled-password autossh
#sudo mkdir -p /home/autossh/.ssh
#sudo touch /home/autossh/.ssh/authorized_keys
#sudo chown -R autossh:autossh /home/autossh/.ssh

#link pm2 to keymetrics
if [ "$keymet" = "y" ]
then
	su - $uname -c "pm2 link $pm2pr $pm2pu $host"
fi
