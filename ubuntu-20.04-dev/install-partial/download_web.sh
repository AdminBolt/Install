GIT_BRANCH="stable"
if [ -n "$1" ]; then
    GIT_BRANCH=$1
fi

wget https://license.adminbolt.com/mirrorlist/any/any/admin-bolt-web-build-stable.zip
unzip -qq -o admin-bolt-web-build.zip -d /usr/local/bolt/web
rm -rf admin-bolt-web-build.zip

chmod 711 /home
chmod -R 750 /usr/local/bolt

ln -s /usr/local/bolt/web/bolt-shell.sh /usr/bin/bolt-shell
chmod +x /usr/local/bolt/web/bolt-shell.sh

ln -s /usr/local/bolt/web/bolt-cli.sh /usr/bin/bolt-cli
chmod +x /usr/local/bolt/web/bolt-cli.sh

mkdir -p /usr/local/bolt/ssl
cp /usr/local/bolt/web/server/ssl/bolt.crt /usr/local/bolt/ssl/bolt.crt
cp /usr/local/bolt/web/server/ssl/bolt.key /usr/local/bolt/ssl/bolt.key
