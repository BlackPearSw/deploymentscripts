#extract parameters
npmu=$1
npmp=$2
npma=$3
gitu=$4
gitp=$5
uname=$6

#update packages
sudo apt-get update

#create log folder
logfile=/home/$uname/logs/install.log
su - $uname -c "mkdir /home/$uname/logs"

#install node
su $uname -c "echo 'Installing nodejs' > $logfile"
curl -sL https://deb.nodesource.com/setup_0.12 | sudo bash -
sudo apt-get install -y nodejs
su $uname -c "echo 'Finished installing nodejs' >> $logfile"

#update npm
su $uname -c "echo 'Updating npm' >> $logfile"
sudo npm install npm -g
su $uname -c "echo 'Finished updating npm' >> $logfile"

#configure local npm
su $uname -c "echo 'Configure local npm' >> $logfile"
su - $uname -c "npm set registry https://npm.blackpear.com"
su - $uname -c "npm set $npma"
su - $uname -c "npm set always-auth true"
su $uname -c "echo 'Finished configuring local npm' >> $logfile"

#install nginx
su $uname -c "echo 'Installing nginx' >> $logfile"
nginx=stable
sudo add-apt-repository --yes ppa:nginx/$nginx
sudo apt-get update
sudo apt-get install --yes nginx
su $uname -c "echo 'Finished installing nginx' >> $logfile"

#install pm2
su $uname -c "echo 'Installing pm2' >> $logfile"
sudo npm install pm2 -g
su $uname -c "echo 'Finished installing pm2' >> $logfile"

#configure pm2 to restart on server reboot
su $uname -c "echo 'Configuring pm2 for restart' >> $logfile"
su - $uname -c "pm2 startup ubuntu -u $uname"
su $uname -c "echo 'pm2 startup step 1 done' >> $logfile"
sudo su -c "env PATH=$PATH:/usr/bin pm2 startup ubuntu -u $uname"
su $uname -c "echo 'pm2 startup step 2 done' >> $logfile"
su - $uname -c "pm2 save"
su $uname -c "echo 'Finished configuring pm2' >> $logfile"

#install git
su $uname -c "echo 'Installing GIT' >> $logfile"
sudo apt-get update
sudo apt-get install --yes build-essential libssl-dev libcurl4-gnutls-dev libexpat1-dev gettext unzip
wget https://github.com/git/git/archive/v2.5.2.zip
unzip v2.5.2.zip
cd git-*
make prefix=/usr/local all
sudo make prefix=/usr/local install
git config --global user.name "$npmu"
git config --global user.email "$npmp"
su $uname -c "echo 'Finished installing GIT' >> $logfile"

#add hosts
su $uname -c "echo 'Adding known hosts' >> $logfile"
su - $uname -c "ssh-keyscan -t rsa github.com > ~/.ssh/known_hosts"
su - $uname -c "ssh-keyscan -t rsa blackpear.git.beanstalkapp.com >> ~/.ssh/known_hosts"
su $uname -c "echo 'Finished adding known hosts' >> $logfile"

#create ssh key
su $uname -c "echo 'Creating ssh key' >> $logfile"
su - $uname -c "cd ~/.ssh && ssh-keygen -f id_rsa -t rsa -N ''"
su $uname -c "echo 'Finished creating ssh key' >> $logfile"

#add ssh key to github
su $uname -c "echo 'Adding ssh key to GitHub' >> $logfile"
su - $uname -c "curl -u \"$gitu:$gitp\" --data '{\"title\":\"$uname\",\"key\":\"`cat /home/$uname/.ssh/id_rsa.pub`\"}' https://api.github.com/user/keys"
su $uname -c "echo 'Finished adding ssh key to GitHub' >> $logfile"
