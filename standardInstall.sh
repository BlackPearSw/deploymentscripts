#extract parameters
npmu=$1
npmp=$2
npma=$3

#install node
sudo apt-get update
curl -sL https://deb.nodesource.com/setup_0.12 | sudo bash -
sudo apt-get install -y nodejs

#update npm
sudo npm install npm -g

#configure local npm
su - pyrusCloud -c 'npm set registry https://npm.blackpear.com'
su - pyrusCloud -c 'npm set $npma'
su - pyrusCloud -c 'npm set always-auth true'

#install pm2
sudo npm install pm2 -g

#install git
sudo apt-get update
sudo apt-get install --yes build-essential libssl-dev libcurl4-gnutls-dev libexpat1-dev gettext unzip
wget https://github.com/git/git/archive/v2.5.2.zip
unzip v2.5.2.zip
cd git-*
make prefix=/usr/local all
sudo make prefix=/usr/local install
#git config --global user.name $npmu
#git config --global user.email $npmp