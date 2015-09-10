#extract parameters
username = $1
emailaddress = $2

#install node
sudo apt-get update
curl -sL https://deb.nodesource.com/setup_0.12 | sudo bash -
sudo apt-get install -y nodejs

#update npm
sudo npm install npm -g

#install pm2
sudo npm install pm2 -g

#install git
sudo apt-get update
sudo apt-get install build-essential libssl-dev libcurl4-gnutls-dev libexpat1-dev gettext unzip
wget https://github.com/git/git/archive/v2.5.0.zip
unzip v2.5.0.zip
cd git-*
make prefix=/usr/local all
sudo make prefix=/usr/local install
git config --global user.name $username
git config --global user.email $emailaddress