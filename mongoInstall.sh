privip=$1
keymet=$2
pm2pr=$3
pm2pu=$4
host=$5
encpw=$6
hdd=$7

#upgrade server install
sudo apt-get update && sudo apt-get -y upgrade

#switch auto updates on for security updates
sudo apt-get install -y unattended-upgrades
sudo sed -i -e '$a\APT::Periodic::Unattended-Upgrade "1";' /etc/apt/apt.conf.d/10periodic

#install ntp
sudo apt-get update
sudo apt-get install --yes ntp
sudo timedatectl set-timezone Europe/London

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

#add user to run pm2 processes
sudo adduser --system --group --shell /bin/bash --disabled-password pm2user

#Install pm2 server monitor
su - pm2user -c "pm2 install pm2-server-monit"

#mount data disk
ldev=$hdd"1"
sudo apt-get update
sudo apt-get install cryptsetup
sudo echo "n
p
1


w
"|sudo fdisk $hdd
sudo su -c "echo $encpw|cryptsetup -y -v luksFormat $ldev"
sudo su -c "echo $encpw|cryptsetup luksOpen $ldev datadrive"
sudo mkfs -t ext4 /dev/mapper/datadrive
sudo mkdir /datadrive
sudo mount /dev/mapper/datadrive /datadrive
sudo mkdir /datadrive/mongodb
sudo chown mongodb:mongodb /datadrive/mongodb

#auto mount encrypted drive
sudo dd if=/dev/urandom of=/root/keyfile bs=1024 count=4
sudo chmod 0400 /root/keyfile
sudo su -c "echo $encpw|cryptsetup luksAddKey /dev/$ldev /root/keyfile"
ddmnt="/dev/mapper/datadrive   /datadrive           ext4     defaults    1       2"
sudo su -c "echo \"$ddmnt\" >> /etc/fstab"
decryt="datadrive                $ldev         /root/keyfile         luks"
sudo su -c "echo \"$decryt\" >> /etc/crypttab"

#update mongo config
sudo sed -i "/dbPath/s/var\/lib/datadrive/" /etc/mongod.conf

#restart mongodb
sudo service mongod restart

#Install pm2 mongodb module
su - pm2user -c "pm2 install pm2-mongodb"

#create autossh user and create empty authorised_keys file
sudo adduser --system --group --shell /bin/bash --disabled-password autossh
su - autossh -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys"
sudo chsh --shell /bin/false autossh

#link pm2 to keymetrics
if [ "$keymet" = "y" ]
then
	su - pm2user -c "pm2 link $pm2pr $pm2pu $host"
fi