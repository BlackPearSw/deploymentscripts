#extract parameters
npmu=$1
npmp=$2
npma=$3
gitu=$4
gitp=$5
uname=$6

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

#install nginx
sudo nginx=stable
sudo add-apt-repository ppa:nginx/$nginx
sudo apt-get update
sudo apt-get install nginx

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
git config --global user.name "$npmu"
git config --global user.email "$npmp"

#add hosts
su - $uname -c "ssh-keyscan -t rsa github.com > ~/.ssh/known_hosts"
su - $uname -c "ssh-keyscan -t rsa blackpear.git.beanstalkapp.com >> ~/.ssh/known_hosts"

#create ssh key
su - $uname -c "cd ~/.ssh && ssh-keygen -f id_rsa -t rsa -N ''"

#add ssh key to github
su - $uname -c "curl -u \"$gitu:$gitp\" --data '{\"title\":\"$uname\",\"key\":\"`cat /home/$uname/.ssh/id_rsa.pub`\"}' https://api.github.com/user/keys"
