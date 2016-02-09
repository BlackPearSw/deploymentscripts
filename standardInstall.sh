#extract parameters
npma=$1
gitu=$2
gitp=$3
uname=$4
beanu=$5
beanp=$6
rabbit=$7
nginx=$8
keymet=$9
pm2pr=${10}
pm2pu=${11}
host=${12}
rabbitu=${13}
tunnel=${14}
dbhost=${15}
dbuser=${16}
dbpw=${17}

#upgrade server install
sudo apt-get update && sudo apt-get -y upgrade

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
fi

: <<'COMMENT'
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

#configure local npm
su - $uname -c "npm set registry https://npm.blackpear.com"
su - $uname -c "npm set $npma"
su - $uname -c "npm set always-auth true"

#install pm2
sudo npm install pm2 -g

#configure pm2 to restart on server reboot
su - $uname -c "pm2 startup ubuntu -u $uname"
sudo su -c "env PATH=$PATH:/usr/bin pm2 startup ubuntu -u $uname --hp /home/$uname"
su - $uname -c "pm2 save"

#Install pm2 server monitor
su $uname -c "pm2 install pm2-server-monit"

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
	su $uname -c "pm2 install pm2-rabbitmq"
fi

#add hosts
su - $uname -c "ssh-keyscan -t rsa github.com > ~/.ssh/known_hosts"
su - $uname -c "ssh-keyscan -t rsa blackpear.git.beanstalkapp.com >> ~/.ssh/known_hosts"

#create ssh key
su - $uname -c "cd ~/.ssh && ssh-keygen -f id_rsa -t rsa -N ''"

#add ssh key to github
su - $uname -c "curl -u \"$gitu:$gitp\" --data '{\"title\":\"$uname\",\"key\":\"`cat ~/.ssh/id_rsa.pub`\"}' https://api.github.com/user/keys"

#add ssh key to beanstalk
su - $uname -c "curl -H \"Content-Type: application/json\" -u \"$beanu:$beanp\" --data '{\"public_key\": {\"name\": \"$uname\",\"content\": \"`cat ~/.ssh/id_rsa.pub`\"}}' https://blackpear.beanstalkapp.com/api/public_keys"

#link pm2 to keymetrics if required
if [ "$keymet" = "y" ]
then
	#su - $uname -c "pm2 link $pm2pr $pm2pu $host"
fi
COMMENT