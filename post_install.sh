#!/bin/sh

# Enable the service
sysrc -f /etc/rc.conf backuppc_enable="YES"
sysrc -f /etc/rc.conf apache24_enable="YES"

# Configure the service
echo "" | sh /usr/local/etc/backuppc/update.sh

chmod 755 /usr/local/www/cgi-bin/BackupPC_Admin

# Start the service
service backuppc start 2>/dev/null
service apache24 restart 2>/dev/null

#From geoff.jukes
# Prepare the Apache config
config="
LoadModule scgi_module        libexec/apache24/mod_scgi.so
SCGIMount /admin 127.0.0.1:10268
<Location /admin>
    AuthUserFile /usr/local/etc/backuppc/htpasswd
    AuthType basic
    AuthName "access"
    require valid-user
</Location>
"

# Write the config to the Includes
echo "$config" > /usr/local/etc/apache24/Includes/backuppc.conf

# Installed the extra packages requirements
pkg install -y ap24-mod_scgi p5-SCGI rsync-bpc

# Enable the SCGI port, fix the image location, allow 'admin' user as an Admin
sed -i .bak 's|^$Conf{SCGIServerPort}.*|$Conf{SCGIServerPort} = 10268;|g' /usr/local/etc/backuppc/config.pl
sed -i .bak 's|^$Conf{CgiAdminUsers}.*|$Conf{CgiAdminUsers}     = "*";|g' /usr/local/etc/backuppc/config.pl
sed -i .bak 's|^$Conf{CgiImageDirURL}.*|\$Conf{CgiImageDirURL} = "";|g' /usr/local/etc/backuppc/config.pl

# Create the htpasswd file
htpasswd -b -c /usr/local/etc/backuppc/htpasswd admin password

# Allow backuppc user to modify the config
chown backuppc /usr/local/etc/backuppc

# Restart services to implement chnages
service backuppc restart
service apache24 restart
