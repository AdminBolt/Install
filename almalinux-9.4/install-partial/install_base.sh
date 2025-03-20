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
    "supervisor"
)
# Check if the dependencies are installed
for DEPENDENCY in "${DEPENDENCIES_LIST[@]}"; do
    dnf install -y $DEPENDENCY
done

## Start MySQL
systemctl start mysqld
systemctl enable mysqld

wget https://raw.githubusercontent.com/AdminBolt/Install/refs/heads/main/almalinux-9.4/greeting.sh -q
mv greeting.sh /etc/profile.d/bolt-greeting.sh

wget https://raw.githubusercontent.com/AdminBolt/Install/refs/heads/main/almalinux-9.4/repos/bolt.repo -q
mv bolt.repo /etc/yum.repos.d/bolt.repo

dnf install -y bolt-php --enablerepo=bolt
dnf install -y bolt-nginx --enablerepo=bolt
dnf install -y bolt-updater --enablerepo=bolt
dnf install -y httpd --enablerepo=bolt

systemctl start httpd
systemctl enable httpd

BOLT_PHP=/usr/local/bolt/php/bin/php
ln -s $BOLT_PHP /usr/bin/bolt-php
