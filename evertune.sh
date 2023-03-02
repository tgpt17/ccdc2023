#!/bin/bash

# Install mod_evasive
sudo apt-get install libapache2-mod-evasive

# Create Log
sudo mkdir /var/log/mod_evasive
sudo chown -R www-data:www-data /var/log/mod_evasive

# Create blocking script
sudo mkdir /etc/apache2/scripts
sudo tee /etc/apache2/scripts/ban_ip.sh <<-'EOF'
#!/bin/sh

IP=$1
IPTABLES=/sbin/iptables

$IPTABLES -A banned -s $IP -p TCP --dport 80 -j DROP
$IPTABLES -A banned -s $IP -p TCP --dport 443 -j DROP

echo "$IPTABLES -D banned -s $IP -p TCP --dport 80 -j DROP" | at now + 3 minutes
echo "$IPTABLES -D banned -s $IP -p TCP --dport 443 -j DROP" | at now + 3 minutes
EOF

# Adjust properties of script
sudo chown www-data:www-data /etc/apache2/scripts/ban_ip.sh
sudo chmod 550 /etc/apache2/scripts/ban_ip.sh

# Create mod_evasive config file
sudo tee /etc/apache2/mods-enabled/evasive.conf <<-'EOF'
<IfModule mod_evasive20.c>
    DOSHashTableSize 3097 
    DOSPageCount 5
    DOSSiteCount 50
    DOSPageInterval 1 
    DOSSiteInterval 10 
    DOSBlockingPeriod 180
    #DOSEmailNotify email@yourdomain.com 
    DOSSystemCommand "sudo /etc/apache2/scripts/ban_ip.sh %s'" 
    DOSLogDir "/var/log/mod_evasive" 
</IfModule>
EOF

# Restart Apache
sudo service apache2 restart