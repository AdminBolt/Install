GIT_BRANCH="stable"
if [ -n "$1" ]; then
    GIT_BRANCH=$1
fi

INSTALL_DIR="/bolt/install"

yum update -y
dnf -y install sudo wget
export NON_INT=1
sudo wget -q -O - http://www.atomicorp.com/installers/atomic | sh
dnf install epel-release -y
dnf config-manager --set-enabled epel
dnf config-manager --set-enabled crb
yum install -y libsodium libsodium-devel

mkdir -p $INSTALL_DIR

cd $INSTALL_DIR

DEPENDENCIES_LIST=(
    "apg"
    "openssl"
    "jq"
    "curl"
    "wget"
    "unzip"
    "zip"
    "tar"
    "mysql-common"
    "mysql-server"
    "lsb-release"
    "gnupg2"
    "ca-certificates"
    "apt-transport-https"
    "software-properties-common"
    "supervisor"
)
# Check if the dependencies are installed
for DEPENDENCY in "${DEPENDENCIES_LIST[@]}"; do
    dnf install -y $DEPENDENCY
done
#
## Start MySQL
systemctl start mysqld
systemctl enable mysqld
#
wget https://raw.githubusercontent.com/AdminBolt/Install/refs/heads/main/almalinux-9.4/greeting.sh
mv greeting.sh /etc/profile.d/bolt-greeting.sh

wget https://raw.githubusercontent.com/AdminBolt/Install/refs/heads/main/almalinux-9.4/repos/bolt.repo
mv bolt.repo /etc/yum.repos.d/bolt.repo

dnf install -y bolt-php
dnf install -y bolt-nginx
dnf install -y my-apache

ufw allow 8443
ufw allow 80
ufw allow 443

systemctl start httpd
systemctl enable httpd

BOLT_PHP=/usr/local/bolt/php/bin/php
ln -s $BOLT_PHP /usr/bin/bolt-php
HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -I | cut -d " " -f 1)

DISTRO_VERSION=$(cat /etc/os-release | grep -w "VERSION_ID" | cut -d "=" -f 2)
DISTRO_VERSION=${DISTRO_VERSION//\"/} # Remove quotes from version string

DISTRO_NAME=$(cat /etc/os-release | grep -w "NAME" | cut -d "=" -f 2)
DISTRO_NAME=${DISTRO_NAME//\"/} # Remove quotes from name string

LOG_JSON='{"os": "'$DISTRO_NAME-$DISTRO_VERSION'", "host_name": "'$HOSTNAME'", "ip": "'$IP_ADDRESS'"}'

curl -s https://adminbolt.com/api/bolt-installation-log -X POST -H "Content-Type: application/json" -d "$LOG_JSON"
GIT_BRANCH="stable"
if [ -n "$1" ]; then
    GIT_BRANCH=$1
fi

wget https://license.adminbolt.com/mirrorlist/any/any/admin-bolt-web-build-stable.zip -O adminbolt-cp.zip
unzip -qq -o adminbolt-cp.zip -d /usr/local/bolt/web
rm -rf adminbolt-cp.zip

chmod 711 /home
chmod -R 750 /usr/local/bolt

ln -s /usr/local/bolt/web/bolt-shell.sh /usr/bin/bolt-shell
chmod +x /usr/local/bolt/web/bolt-shell.sh

ln -s /usr/local/bolt/web/bolt-cli.sh /usr/bin/bolt-cli
chmod +x /usr/local/bolt/web/bolt-cli.sh

mkdir -p /usr/local/bolt/ssl
cp /usr/local/bolt/web/server/ssl/bolt.crt /usr/local/bolt/ssl/bolt.crt
cp /usr/local/bolt/web/server/ssl/bolt.key /usr/local/bolt/ssl/bolt.key
GIT_BRANCH="stable"
if [ -n "$1" ]; then
    GIT_BRANCH=$1
fi

# Check dir exists
if [ ! -d "/usr/local/bolt/web" ]; then
  echo "AdminBolt directory not found."
  return 1
fi

# Go to web directory
cd /usr/local/bolt/web

#
## Create MySQL OMEGA user
#MYSQL_BOLT_ROOT_USERNAME="bolt"
#MYSQL_BOLT_ROOT_PASSWORD="$(apg -a 1 -m 50 -x 50 -M NCL -n 1)"
#
#mysql -u root <<MYSQL_SCRIPT
#  CREATE USER "$MYSQL_BOLT_ROOT_USERNAME"@"%" IDENTIFIED BY "$MYSQL_BOLT_ROOT_PASSWORD";
#  GRANT ALL PRIVILEGES ON *.* TO "$MYSQL_BOLT_ROOT_USERNAME"@"%" WITH GRANT OPTION;
#  FLUSH PRIVILEGES;
#MYSQL_SCRIPT
#
## Create database
#ADMIN_BOLT_DB_PASSWORD="$(apg -a 1 -m 50 -x 50 -M NCL -n 1)"
#ADMIN_BOLT_DB_NAME="bolt_$(tr -dc a-za-z0-9 </dev/urandom | head -c 13; echo)"
#ADMIN_BOLT_DB_USER="bolt_$(tr -dc a-za-z0-9 </dev/urandom | head -c 13; echo)"
#
#mysql -u root <<MYSQL_SCRIPT
#  CREATE DATABASE $ADMIN_BOLT_DB_NAME;
#  CREATE USER '$ADMIN_BOLT_DB_USER'@'localhost' IDENTIFIED BY "$ADMIN_BOLT_DB_PASSWORD";
#  GRANT ALL PRIVILEGES ON $ADMIN_BOLT_DB_NAME.* TO '$ADMIN_BOLT_DB_USER'@'localhost';
#  FLUSH PRIVILEGES;
#MYSQL_SCRIPT
#
#
## Change mysql root password
#MYSQL_ROOT_PASSWORD="$(apg -a 1 -m 50 -x 50 -M NCL -n 1)"
#mysql -u root <<MYSQL_SCRIPT
#  ALTER USER 'root'@'localhost' IDENTIFIED BY "$MYSQL_ROOT_PASSWORD";
#  FLUSH PRIVILEGES;
#MYSQL_SCRIPT
#
## Save mysql root password
#echo "$MYSQL_ROOT_PASSWORD" > /root/.mysql_root_password
#
## Configure the application
#bolt-php artisan bolt:set-ini-settings APP_ENV "local"
#bolt-php artisan bolt:set-ini-settings APP_URL "127.0.0.1:8443"
#bolt-php artisan bolt:set-ini-settings APP_NAME "ADMIN_BOLT"
#bolt-php artisan bolt:set-ini-settings DB_DATABASE "$ADMIN_BOLT_DB_NAME"
#bolt-php artisan bolt:set-ini-settings DB_USERNAME "$ADMIN_BOLT_DB_USER"
#bolt-php artisan bolt:set-ini-settings DB_PASSWORD "$ADMIN_BOLT_DB_PASSWORD"
#bolt-php artisan bolt:set-ini-settings DB_CONNECTION "mysql"
#bolt-php artisan bolt:set-ini-settings MYSQL_ROOT_USERNAME "$MYSQL_BOLT_ROOT_USERNAME"
#bolt-php artisan bolt:set-ini-settings MYSQL_ROOT_PASSWORD "$MYSQL_BOLT_ROOT_PASSWORD"
#bolt-php artisan bolt:key-generate
#
#bolt-php artisan migrate
#bolt-php artisan db:seed
#
#bolt-php artisan bolt:set-ini-settings APP_ENV "production"

chmod -R o+w /usr/local/bolt/web/storage/
chmod -R o+w /usr/local/bolt/web/bootstrap/cache/

cp /usr/local/bolt/web/server/nginx/nginx.conf /usr/local/bolt/nginx/conf/nginx.conf
cp /usr/local/bolt/web/server/php/php-fpm.conf /usr/local/bolt/php/etc/php-fpm.conf

#bolt-cli run-repair

service bolt start

CURRENT_IP=$(hostname -I | awk '{print $1}')

echo "AdminBolt services started."
echo "Please visit https://$CURRENT_IP:8443 to continue installation of the panel."
