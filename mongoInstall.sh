privip=$1

#upgrade server install
sudo apt-get update && sudo apt-get -y upgrade

#switch auto updates on for security updates
sudo apt-get install -y unattended-upgrades
sudo sed -i -e '$a\APT::Periodic::Unattended-Upgrade "1";' /etc/apt/apt.conf.d/10periodic

#install ntp
sudo apt-get update
sudo apt-get install --yes ntp

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

#update config
sudo sed -i "/bind_ip/s/127.0.0.1/$privip/" /etc/mongod.conf

#restart mongodb
sudo service mongod restart