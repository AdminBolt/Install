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
cp /usr/local/bolt/web/server/php/php-fpm.conf /usr/local/omega/php/etc/php-fpm.conf

#bolt-cli run-repair

service bolt start

CURRENT_IP=$(hostname -I | awk '{print $1}')

echo "AdminBolt services started."
echo "Please visit https://$CURRENT_IP:8443 to continue installation of the panel."
