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
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list

# Disable THP
sudo echo never > /sys/kernel/mm/transparent_hugepage/enabled
sudo echo never > /sys/kernel/mm/transparent_hugepage/defrag
sudo grep -q -F 'transparent_hugepage=never' /etc/default/grub || echo 'transparent_hugepage=never' >> /etc/default/grub

# Install updates
sudo apt-get -y update

#Install Mongo DB
sudo apt-get install -y mongodb-org

#update mongo config
sudo sed -i "/bindIp/s/127.0.0.1/$privip/" /etc/mongod.conf

#restart mongodb
sudo service mongod restart

#install pm2
sudo npm install pm2 -g

#Install pm2 server monitor
su - $uname -c "pm2 install pm2-server-monit"

#update pm2 mongodb ip
su - $uname -c "pm2 set pm2-mongodb:ip $privip"

#link pm2 to keymetrics
if [ "$keymet" = "y" ]
then
	su - $uname -c "pm2 link $pm2pr $pm2pu $host"
fi
