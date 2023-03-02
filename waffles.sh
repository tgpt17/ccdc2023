#!/bin/bash

# Install libapache2-modsecurity package
sudo apt-get install libapache2-modsecurity

# Configure dpkg if necessary
sudo dpkg --configure -a

# Check installation
apachectl -M | grep security

# Rename modsecurity config file
sudo mv /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf

# Turn on rules
sudo sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/modsecurity/modsecurity.conf

# Remove default rules
sudo rm -rf /usr/share/modsecurity-crs

# Download OWASP ModSecurity Core Rule Set (CRS)
sudo git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git /usr/share/modsecurity-crs

# Rename CRS setup file
sudo mv /usr/share/modsecurity-crs/crs-setup.conf.example /usr/share/modsecurity-crs/crs-setup.conf

# Add all new rules to Apache security2.conf
sudo sh -c 'cat << EOF > /etc/apache2/mods-enabled/security2.conf
<IfModule security2_module>
    SecDataDir /var/cache/modsecurity
    IncludeOptional /etc/modsecurity/*.conf
    IncludeOptional /usr/share/modsecurity-crs/*.conf
    IncludeOptional /usr/share/modsecurity-crs/rules/*.conf
</IfModule>
EOF'

# Restart Apache service
sudo systemctl restart apache2

# Raise paranoia level to 2 out of 5
sudo sed -i 's/setvar:tx\.paranoia_level=1/setvar:tx.paranoia_level=2/' /usr/share/modsecurity-crs/crs-setup.conf

# Test WAF with example URLs
echo "Testing WAF..."
curl -I "http://localhost/?q=\"\>\<script\>alert(1)\</script\>"
curl -I "http://localhost/?q='1 OR 1=1'"

echo "Installation and testing of WAF is complete."