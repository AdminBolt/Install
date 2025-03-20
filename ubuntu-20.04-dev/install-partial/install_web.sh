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

chmod -R o+w /usr/local/bolt/web/storage/
chmod -R o+w /usr/local/bolt/web/bootstrap/cache/

rm -rf /usr/local/bolt/php/lib/php.ini
ln -s /usr/local/bolt/web/server/php/php.ini /usr/local/bolt/php/lib/php.ini

rm -rf /usr/local/bolt/php/etc/php-fpm.conf
ln -s /usr/local/bolt/web/server/php/php-fpm.conf /usr/local/bolt/php/etc/php-fpm.conf

rm -rf /usr/local/bolt/nginx/conf/nginx.conf
ln -s /usr/local/bolt/web/server/nginx/nginx.conf /usr/local/bolt/nginx/conf/nginx.conf


service bolt start

bolt-php /usr/local/bolt/web/artisan bolt:install-core
