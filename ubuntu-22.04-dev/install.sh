INSTALL_DIR="/bolt/install"

GIT_BRANCH="stable"
if [ -n "$1" ]; then
    GIT_BRANCH=$1
fi

apt-get update && apt-get install ca-certificates -y

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
    "mysql-client"
    "lsb-release"
    "gnupg2"
    "ca-certificates"
    "apt-transport-https"
    "software-properties-common"
    "supervisor"
    "libonig-dev"
    "libzip-dev"
    "libcurl4-openssl-dev"
    "libsodium23"
    "libpq5"
    "libssl-dev"
    "zlib1g-dev"
)
# Check if the dependencies are installed
for DEPENDENCY in "${DEPENDENCIES_LIST[@]}"; do
    apt-get install -y $DEPENDENCY
done

# Start MySQL
service mysql start

wget https://raw.githubusercontent.com/AdminBolt/Panel/$GIT_BRANCH/installers/ubuntu-22.04/greeting.sh
mv greeting.sh /etc/profile.d/bolt-greeting.sh

# Install BOLT PHP
wget https://github.com/AdminBolt/Dist/raw/main/compilators/debian/php/dist/bolt-php-8.2.0-ubuntu-22.04.deb
dpkg -i bolt-php-8.2.0-ubuntu-22.04.deb

# Install BOLT NGINX
wget https://github.com/AdminBolt/Dist/raw/main/compilators/debian/nginx/dist/bolt-nginx-1.24.0-ubuntu-22.04.deb
dpkg -i bolt-nginx-1.24.0-ubuntu-22.04.deb

service bolt start

OMEGA_PHP=/usr/local/bolt/php/bin/php
ln -s $OMEGA_PHP /usr/bin/bolt-php

ln -s /usr/local/bolt/web/bolt-shell.sh /usr/bin/bolt-shell
chmod +x /usr/local/bolt/web/bolt-shell.sh

ln -s /usr/local/bolt/web/bolt-cli.sh /usr/bin/bolt-cli
chmod +x /usr/local/bolt/web/bolt-cli.sh
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

wget https://github.com/AdminBolt/WebCompiledVersions/raw/main/adminbolt-latest.zip
unzip -qq -o adminbolt-latest.zip -d /usr/local/bolt/web
rm -rf adminbolt-latest.zip

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

# Create MySQL BOLT user
MYSQL_OMEGA_ROOT_USERNAME="bolt"
MYSQL_OMEGA_ROOT_PASSWORD="$(apg -a 1 -m 50 -x 50 -M NCL -n 1)"

mysql -u root <<MYSQL_SCRIPT
  CREATE USER "$MYSQL_OMEGA_ROOT_USERNAME"@"%" IDENTIFIED BY "$MYSQL_OMEGA_ROOT_PASSWORD";
  GRANT ALL PRIVILEGES ON *.* TO "$MYSQL_OMEGA_ROOT_USERNAME"@"%" WITH GRANT OPTION;
  FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Create database
ADMINBOLT_DB_PASSWORD="$(apg -a 1 -m 50 -x 50 -M NCL -n 1)"
ADMINBOLT_DB_NAME="omega_$(tr -dc a-za-z0-9 </dev/urandom | head -c 13; echo)"
ADMINBOLT_DB_USER="omega_$(tr -dc a-za-z0-9 </dev/urandom | head -c 13; echo)"

mysql -u root <<MYSQL_SCRIPT
  CREATE DATABASE $ADMINBOLT_DB_NAME;
  CREATE USER '$ADMINBOLT_DB_USER'@'localhost' IDENTIFIED BY "$ADMINBOLT_DB_PASSWORD";
  GRANT ALL PRIVILEGES ON $ADMINBOLT_DB_NAME.* TO '$ADMINBOLT_DB_USER'@'localhost';
  FLUSH PRIVILEGES;
MYSQL_SCRIPT


# Change mysql root password
MYSQL_ROOT_PASSWORD="$(apg -a 1 -m 50 -x 50 -M NCL -n 1)"
mysql -u root <<MYSQL_SCRIPT
  ALTER USER 'root'@'localhost' IDENTIFIED BY "$MYSQL_ROOT_PASSWORD";
  FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Save mysql root password
echo "$MYSQL_ROOT_PASSWORD" > /root/.mysql_root_password

# Configure the application
bolt-php artisan bolt:set-ini-settings APP_ENV "local"
bolt-php artisan bolt:set-ini-settings APP_URL "127.0.0.1:8443"
bolt-php artisan bolt:set-ini-settings APP_NAME "ADMIN_BOLT"
bolt-php artisan bolt:set-ini-settings DB_DATABASE "$ADMINBOLT_DB_NAME"
bolt-php artisan bolt:set-ini-settings DB_USERNAME "$ADMINBOLT_DB_USER"
bolt-php artisan bolt:set-ini-settings DB_PASSWORD "$ADMINBOLT_DB_PASSWORD"
bolt-php artisan bolt:set-ini-settings DB_CONNECTION "mysql"
bolt-php artisan bolt:set-ini-settings MYSQL_ROOT_USERNAME "$MYSQL_OMEGA_ROOT_USERNAME"
bolt-php artisan bolt:set-ini-settings MYSQL_ROOT_PASSWORD "$MYSQL_OMEGA_ROOT_PASSWORD"
bolt-php artisan bolt:key-generate

bolt-php artisan migrate
bolt-php artisan db:seed

bolt-php artisan bolt:set-ini-settings APP_ENV "production"

chmod -R o+w /usr/local/bolt/web/storage/
chmod -R o+w /usr/local/bolt/web/bootstrap/cache/

bolt-cli run-repair

service bolt start

CURRENT_IP=$(hostname -I | awk '{print $1}')

echo "AdminBolt downloaded successfully."
echo "Please visit https://$CURRENT_IP:8443 to continue installation of the panel."
