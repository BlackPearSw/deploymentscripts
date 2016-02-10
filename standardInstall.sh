#extract parameters
npma=$1
gitu=$2
gitp=$3
beanu=$4
beanp=$5
rabbit=$6
nginx=$7
keymet=$8
pm2pr=$9
pm2pu=${10}
host=${11}
rabbitu=${12}
tunnel=${13}
dbhost=${14}
dbuser=${15}
dbpw=${16}
sshport=${17}

#upgrade server install
sudo apt-get update && sudo apt-get -y upgrade

#switch auto updates on for security updates
sudo apt-get install -y unattended-upgrades
sudo sed -i -e '$a\APT::Periodic::Unattended-Upgrade "1";' /etc/apt/apt.conf.d/10periodic

#install ntp
sudo apt-get update
sudo apt-get install --yes ntp

#install git
sudo apt-get update
sudo apt-get install --yes build-essential libssl-dev libcurl4-gnutls-dev libexpat1-dev gettext unzip
wget https://github.com/git/git/archive/v2.5.2.zip
unzip v2.5.2.zip
cd git-*
make prefix=/usr/local all
sudo make prefix=/usr/local install

#install node
sudo apt-get update
curl -sL https://deb.nodesource.com/setup_0.12 | sudo bash -
sudo apt-get install -y nodejs

#update npm
sudo npm install npm -g

#install pm2
sudo npm install pm2 -g

#add user to run pm2 processes
sudo adduser --system --group --shell /bin/bash --disabled-password pm2user
su - pm2user -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cd ~/.ssh && ssh-keygen -f id_rsa -t rsa -N ''"

#configure local npm
su - pm2user -c "npm set registry https://npm.blackpear.com"
su - pm2user -c "npm set $npma"
su - pm2user -c "npm set always-auth true"

#configure pm2 to restart on server reboot
su - pm2user -c "pm2 startup ubuntu -u pm2user"
sudo su -c "env PATH=$PATH:/usr/bin pm2 startup ubuntu -u pm2user --hp /home/pm2user"
su - pm2user -c "pm2 save"

#Install pm2 server monitor
su - pm2user -c "pm2 install pm2-server-monit"

#install nginx
if [ "$nginx" = "y" ]
then
	nginx=stable
	sudo add-apt-repository --yes ppa:nginx/$nginx
	sudo apt-get update
	sudo apt-get install --yes nginx
fi

#install RabbitMQ if required
if [ "$rabbit" = "y" ]
then
	sudo bash -c 'echo "deb http://www.rabbitmq.com/debian testing main" >> /etc/apt/sources.list'
	wget https://www.rabbitmq.com/rabbitmq-signing-key-public.asc
	sudo apt-key add rabbitmq-signing-key-public.asc
	sudo apt-get update
	sudo apt-get install -y rabbitmq-server
	sudo rabbitmqctl add_user blackpear $rabbitu
	sudo rabbitmqctl set_user_tags blackpear administrator
	sudo rabbitmqctl set_permissions blackpear ".*" ".*" ".*"
	sudo rabbitmq-plugins enable rabbitmq_management
	su - pm2user -c "pm2 install pm2-rabbitmq"
fi

#create ssh tunnel to mongodb database
if [ "$tunnel" = "y" ]
then
	sudo apt-get update
	sudo apt-get install --yes sshpass
	sudo adduser --system --group --shell /bin/bash --disabled-password autossh
	su - autossh -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh && ssh-keyscan -t rsa $dbhost > ~/.ssh/known_hosts && cd ~/.ssh && ssh-keygen -f id_rsa -t rsa -N ''"
	su - autossh -c "cat ~/.ssh/id_rsa.pub | sshpass -p $dbpw ssh $dbuser@$dbhost \"sudo su -c 'cat >> /home/autossh/.ssh/authorized_keys'\""
	sudo chsh --shell /bin/false autossh
	sudo apt-get --purge remove --yes sshpass

	#create autossh.sh script
	sudo apt-get update
	sudo apt-get install --yes autossh
	sudo su -c "cat << EOF > /etc/init/autossh.conf
description \"Start autossh to control ssh tunnel\"
author \"Steve Reynolds\"
start on (local-filesystems and net-device-up IFACE=eth0)
stop on runlevel [016]
setuid autossh
respawn
respawn limit 5 60
exec autossh -M 0 -N -o \"ServerAliveInterval 60\" -o \"ServerAliveCountMax 3\" -L $sshport:localhost:27017 -i /home/autossh/.ssh/id_rsa autossh@$dbhost
EOF"
	sudo service autossh start
fi

#add github and beanstalk to known hosts
su - pm2user -c "ssh-keyscan -t rsa github.com > ~/.ssh/known_hosts"
su - pm2user -c "ssh-keyscan -t rsa blackpear.git.beanstalkapp.com >> ~/.ssh/known_hosts"

#add ssh key to github
su - pm2user -c "curl -u \"$gitu:$gitp\" --data '{\"title\":\"$host\",\"key\":\"`su - pm2user -c \"cat ~/.ssh/id_rsa.pub\"`\"}' https://api.github.com/user/keys"

#add ssh key to beanstalk
su - pm2user -c "curl -H \"Content-Type: application/json\" -u \"$beanu:$beanp\" --data '{\"public_key\": {\"name\": \"$host\",\"content\": \"`su - pm2user -c \"cat ~/.ssh/id_rsa.pub\"`\"}}' https://blackpear.beanstalkapp.com/api/public_keys"

#link pm2 to keymetrics if required
if [ "$keymet" = "y" ]
then
	su - pm2user -c "pm2 link $pm2pr $pm2pu $host"
fi