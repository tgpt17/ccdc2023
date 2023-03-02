#!/bin/bash

# Install required packages
sudo apt update
sudo apt install php-xml php-mbstring -y

# Reload Apache service
sudo systemctl reload apache2

# Create database and user
sudo mysql <<EOF
CREATE DATABASE openemr;
CREATE USER 'openemr_user'@'localhost' IDENTIFIED BY 'Worldbigbad667';
GRANT ALL PRIVILEGES ON openemr.* TO 'openemr_user'@'localhost';
FLUSH PRIVILEGES;
exit
EOF

# Configure php.ini file
sudo nano /etc/php/7.4/apache2/php.ini <<EOF
max_input_vars = 3000
max_execution_time = 60
max_input_time = -1
post_max_size = 30M
memory_limit = 256M
mysqli.allow_local_infile = On
EOF

# Reload Apache service
sudo systemctl reload apache2

# Download and extract OpenEMR
wget https://downloads.sourceforge.net/project/openemr/OpenEMR%20Current/5.0.2.1/openemr-5.0.2.tar.gz
tar xvzf openemr*.tar.gz
mv openemr-5.0.2 openemr
sudo mv openemr /var/www/html/
sudo chown -R www-data:www-data /var/www/html/openemr

# Allow write access to sqlconf.php file
sudo chmod 666 /var/www/html/openemr/sites/default/sqlconf.php

# Configure Apache virtual host
sudo nano /etc/apache2/sites-available/openemr.conf <<EOF
 <Directory "/var/www/html/openemr">
      AllowOverride FileInfo
      Require all granted
  </Directory>
  <Directory "/var/www/html/openemr/sites">
      AllowOverride None
  </Directory>
  <Directory "/var/www/html/openemr/sites/*/documents">
      Require all denied
  </Directory>
EOF

# Enable Apache virtual host
sudo a2ensite openemr.conf

# Reload Apache service
sudo systemctl restart apache2

# Set appropriate permissions on specific files
sudo chmod 644 openemr/library/sqlconf.php
sudo chmod 600 openemr/acl_setup.php
sudo chmod 600 openemr/acl_upgrade.php
sudo chmod 600 openemr/setup.php
sudo chmod 600 openemr/sql_upgrade.php
sudo chmod 600 openemr/gacl/setup.php

echo "OpenEMR installation complete."