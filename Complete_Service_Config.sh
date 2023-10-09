#!/bin/bash

# Bind application for DNS server setup
sudo dnf install bind bind-utils -y

# bind-utils has good utilities like dig utility, below manual pages give more information
man named.conf

ip -c a
sudo cat /etc/named.conf
listen-on port 53 { 127.0.0.1; };
allow-query     { localhost; };
recursion yes;
allow-query    { 0.0.0.0/0; }; # Add this line in it under recursing-file  "/var/named/data/named.recursing"; line
sudo vi /etc/named.conf
listen-on port 53 { 127.0.0.1; 127.0.0.11; }; # Modified
listen-on port 53 { any; }; # Modified
allow-query     { localhost; 127.0.0.0/8; }; # Modified
allow-query     { any; };  # Modified
recursion no; # Modified

# Start and enable bind
sudo systemctl start named.service
sudo systemctl enable named.service
sudo firewall-cmd --add-service=dns --permanent

# Test that bind is setup and working
dig @127.0.0.1 google.com
;; Query time: 1213 msec
dig @127.0.0.1 google.com
;; Query time: 0 msec

# So why did the time reduce - Maintain a DNS Zone, the first section we look at is below
sudo cat /etc/named.conf
zone "." IN {
        type hint;
        file "named.ca";
};

# We will use it as a template and add below entries
sudo vi /etc/named.conf
zone "example.com" IN {
        type master;
        file "example.com.zone";
};

# We will create a zone file from above file name directive - by using a template
sudo ls /var/named/
data  dynamic  named.ca  named.empty  named.localhost  named.loopback  slaves
sudo cp --preserve=ownership /var/named/named.localhost /var/named/example.com.zone
sudo vi /var/named/example.com.zone

# Original Version
$TTL 1D
@       IN SOA  @ rname.invalid. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
        NS      @
        A       127.0.0.1
        AAAA    ::1

# Modified Version

$TTL 1H
@               IN SOA  @ administrator.example.com. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
@               NS          ns1.example.com.
@               NS          ns2.example.com.
ns1             A           10.1.1.1
ns2             A           10.2.2.1
@               A           203.2.1.1
www             A           203.2.1.1
www             CNAME       203.2.1.1
example.com.    MX 10       mail1.example.com.
                MX 20       mail2.example.com.    
mail1           A           203.2.1.80
mail2           A           203.2.1.88
server1         AAAA        22gb:34mb::10:2
example.com.    TXT         "We can write anything here"

# Effecting the changes and testing
sudo systemctl restart named.service
dig @localhost example.com ANY

# Configuring Email Aliases
ec2-user@example.com        = /var/spool/mail/ec2-user

# Install, Start and enable  an email server
sudo dnf install postfix mailx -y
sudo systemctl start postfix
sudo systemctl enable postfix

# Test emails
sendmail ec2-user@localhost <<< "Hello EC2-USER, I am just sending a test email"
cat /var/spool/mail/ec2-user
echo "This is a test email" | mailx -s "Hi John" john

# Add an alias and test it
sudo vi /etc/aliases
cedric: ec2-user
sudo newaliases
sendmail cedric@localhost <<< "Hello, I am just sending a test email to Cedric"

# Initiall setup of  IMAP(Internet Messaging Access Protocol) and IMAPS services bu installing an IMAP server
sudo dnf install dovecot -y
sudo systemctl start dovecot
sudo systemctl enable dovecot
sudo firewall-cmd --add-service=imap
sudo firewall-cmd --add-service=imaps
sudo firewall-cmd --runtime-to-permanent

# Configure dovecot
sudo ls /etc/dovecot/
conf.d  dovecot.conf

sudo vi /etc/dovecot/dovecot.conf
#protocols = imap pop3 lmtp submission
#listen = *, ::
protocols = imap
listen = *, ::
listen = 2.2.2.2

sudo ls /etc/dovecot/conf.d/
10-auth.conf      10-master.conf   15-mailboxes.conf  20-submission.conf  auth-checkpassword.conf.ext  auth-master.conf.ext      auth-system.conf.ext
10-director.conf  10-metrics.conf  20-imap.conf       90-acl.conf         auth-deny.conf.ext           auth-passwdfile.conf.ext
10-logging.conf   10-ssl.conf      20-lmtp.conf       90-plugin.conf      auth-dict.conf.ext           auth-sql.conf.ext
10-mail.conf      15-lda.conf      20-pop3.conf       90-quota.conf       auth-ldap.conf.ext           auth-static.conf.ext

sudo vi /etc/dovecot/conf.d/10-master.conf
service imap-login {
  inet_listener imap {
    #port = 143
  }
  inet_listener imaps {
    #port = 993
    #ssl = yes
  }

  service imap-login {
  inet_listener imap {
    #port = 143
  }
  inet_listener imaps {
    port = 2222         # Uncommented and changed from 993
    #ssl = yes
  }

sudo vi /etc/dovecot/conf.d/10-mail.conf

#   mail_location = maildir:~/Maildir
#   mail_location = mbox:~/mail:INBOX=/var/mail/%u
#   mail_location = mbox:/var/mail/%d/%1n/%n:INDEX=/var/indexes/%d/%1n/%n

#   mail_location = maildir:~/Maildir
  mail_location = mbox:~/mail:INBOX=/var/mail/%u
#   mail_location = mbox:/var/mail/%d/%1n/%n:INDEX=/var/indexes/%d/%1n/%n

sudo vi /etc/dovecot/conf.d/10-ssl.conf
ssl = required
ssl = yes

# Configure SSH Servers and clients
sudo vi /etc/ssh/sshd_config # for deamon for server configuration
#Port 22
#AddressFamily any
#ListenAddress 0.0.0.0
#ListenAddress ::

#LoginGraceTime 2m
#PermitRootLogin prohibit-password
#StrictModes yes
#MaxAuthTries 6
#MaxSessions 10


# To disable tunneled clear text passwords, change to no here!
#PasswordAuthentication yes
#PermitEmptyPasswords no

#AllowAgentForwarding yes
#AllowTcpForwarding yes
#GatewayPorts no
#X11Forwarding no
#X11DisplayOffset 10
#X11UseLocalhost yes
#PermitTTY yes
#PrintMotd yes
#PrintLastLog yes
#TCPKeepAlive yes
#PermitUserEnvironment no
#Compression delayed
#ClientAliveInterval 0
#ClientAliveCountMax 3
#UseDNS no

Port 999
AddressFamily inet
ListenAddress 1.1.1.1
#ListenAddress ::

#LoginGraceTime 2m
PermitRootLogin no
#StrictModes yes
#MaxAuthTries 6
#MaxSessions 10


# To disable tunneled clear text passwords, change to no here!
PasswordAuthentication no
Match user john
        PasswordAuthentication yes
#PermitEmptyPasswords no

#AllowAgentForwarding yes
#AllowTcpForwarding yes
#GatewayPorts no
X11Forwarding no
#X11DisplayOffset 10
#X11UseLocalhost yes
#PermitTTY yes
#PrintMotd yes
#PrintLastLog yes
#TCPKeepAlive yes
#PermitUserEnvironment no
#Compression delayed
#ClientAliveInterval 0
#ClientAliveCountMax 3
#UseDNS no

sudo systemctl reload sshd.service

sudo vi /etc/ssh/ssh_config # for client configuration

#  Setup HTTP Proxy server using squid
sudo dnf install squid -y
sudo firewall-cmd --add-service=squid --permanent
sudo systemctl start squid
sudo systemctl enable squid

# Add access rules
sudo vi /etc/squid/squid.conf
acl localnet src 10.11.12.0/8
acl external src 203.0.113.0/24

acl youtube dstdomain .youtube.com
# Add the Hash sign infront of all the ACL entries that we don't require

# We strongly recommend the following be uncommented to protect innocent
# web applications running on the proxy server who think the only
# one who can access services on "localhost" is a local user
#http_access deny to_localhost

# We strongly recommend the following be uncommented to protect innocent
# web applications running on the proxy server who think the only
# one who can access services on "localhost" is a local user
http_access deny to_localhost                                           # Uncommented this line
http_access deny youtube
# Example rule allowing access from your local networks.
# Adapt localnet in the ACL section to list your (internal) IP networks
# from where browsing should be allowed
http_access allow localnet
http_access allow localhost
http_access allow external                                             # Added this entry


sudo systemctl reload squid.service
sudo systemctl restart squid.service

# Setup and start the HTTP Server
sudo dnf install -y httpd
sudo systemctl enable httpd
sudo systemctl start httpd
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --add-service=https --permanent


# More information about configuring http server can be found in
man httpd.conf
ls /etc/httpd/
conf  conf.d  conf.modules.d  logs  modules  run  state

sudo vi /etc/httpd/conf/httpd.conf
Listen 1.1.1.1:8080
ServerAdmin  john@localhost
ServerName   www.example.com:80 or 2.2.2.2

DocumentRoot "/var/www/html"

sudo mkdir /var/www/store/
sudo mkdir /var/www/blog/
sudo vi /etc/httpd/conf.d/two-websites.conf
<VirtualHost *:80>
        ServerName store.example.com
        DocumentRoot /var/www/store/
</VirtualHost>

<VirtualHost *:80>
        ServerName blog.example.com
        DocumentRoot /var/www/blog/
</VirtualHost>

<VirtualHost 1.1.1.1:80>
        ServerName blog.example.com
        DocumentRoot /var/www/blog/
</VirtualHost>

sudo apachectl configtest
sudo systemctl reload httpd.service

# TLS/SSL Settings
sudo vi /etc/httpd/conf.d/ssl.conf
Listen 443 https

sudo vi /etc/httpd/conf.d/two-websites.conf

<VirtualHost *:443>
        SSLName www.example.com
        SSLEngine on
        SSLCertificateFile "Path to Certificate"
        SSLCertificateKeyFile "Path to keyfile"
</VirtualHost>

# Modules Location for httpd deamon 
sudo ls /etc/httpd/conf.modules.d/
00-base.conf  00-brotli.conf  00-dav.conf  00-lua.conf  00-mpm.conf  00-optional.conf  00-proxy.conf  00-systemd.conf  01-cgi.conf  10-h2.conf  10-proxy_h2.conf  README

sudo dnf install -y mod_ssl
sudo ls /etc/httpd/conf.modules.d/
00-base.conf    00-dav.conf  00-mpm.conf       00-proxy.conf  00-systemd.conf  10-h2.conf        README
00-brotli.conf  00-lua.conf  00-optional.conf  00-ssl.conf    01-cgi.conf      10-proxy_h2.conf

sudo vi /etc/httpd/conf.modules.d/00-mpm.conf
#LoadModule mpm_prefork_module modules/mod_mpm_prefork.so
LoadModule mpm_event_module modules/mod_mpm_event.so

LoadModule mpm_prefork_module modules/mod_mpm_prefork.so
#LoadModule mpm_event_module modules/mod_mpm_event.so

# Below we can uncomment modules that we need
sudo vi /etc/httpd/conf.modules.d/00-optional.conf
#
# This file lists modules included with the Apache HTTP Server
# which are not enabled by default.
# 

#LoadModule asis_module modules/mod_asis.so
#LoadModule buffer_module modules/mod_buffer.so
#LoadModule heartbeat_module modules/mod_heartbeat.so
#LoadModule heartmonitor_module modules/mod_heartmonitor.so
#LoadModule usertrack_module modules/mod_usertrack.so
#LoadModule dialup_module modules/mod_dialup.so
#LoadModule charset_lite_module modules/mod_charset_lite.so
#LoadModule log_debug_module modules/mod_log_debug.so
#LoadModule log_forensic_module modules/mod_log_forensic.so
#LoadModule ratelimit_module modules/mod_ratelimit.so
#LoadModule reflector_module modules/mod_reflector.so
#LoadModule sed_module modules/mod_sed.so
#LoadModule speling_module modules/mod_speling.so

# Below we can comment out things that we dont need
sudo vi /etc/httpd/conf.modules.d/00-base.conf

#
# This file loads most of the modules included with the Apache HTTP
# Server itself.
#

LoadModule access_compat_module modules/mod_access_compat.so
LoadModule actions_module modules/mod_actions.so
LoadModule alias_module modules/mod_alias.so
LoadModule allowmethods_module modules/mod_allowmethods.so
LoadModule auth_basic_module modules/mod_auth_basic.so
LoadModule auth_digest_module modules/mod_auth_digest.so
LoadModule authn_anon_module modules/mod_authn_anon.so
LoadModule authn_core_module modules/mod_authn_core.so
LoadModule authn_dbd_module modules/mod_authn_dbd.so
LoadModule authn_dbm_module modules/mod_authn_dbm.so
LoadModule authn_file_module modules/mod_authn_file.so
LoadModule authn_socache_module modules/mod_authn_socache.so
LoadModule authz_core_module modules/mod_authz_core.so
LoadModule authz_dbd_module modules/mod_authz_dbd.so
LoadModule authz_dbm_module modules/mod_authz_dbm.so
LoadModule authz_groupfile_module modules/mod_authz_groupfile.so
LoadModule authz_host_module modules/mod_authz_host.so
LoadModule authz_owner_module modules/mod_authz_owner.so
LoadModule authz_user_module modules/mod_authz_user.so
LoadModule autoindex_module modules/mod_autoindex.so
LoadModule cache_module modules/mod_cache.so
LoadModule cache_disk_module modules/mod_cache_disk.so
LoadModule cache_socache_module modules/mod_cache_socache.so
LoadModule data_module modules/mod_data.so
LoadModule dbd_module modules/mod_dbd.so
LoadModule deflate_module modules/mod_deflate.so
LoadModule dir_module modules/mod_dir.so
LoadModule dumpio_module modules/mod_dumpio.so
LoadModule echo_module modules/mod_echo.so
LoadModule env_module modules/mod_env.so
LoadModule expires_module modules/mod_expires.so
LoadModule ext_filter_module modules/mod_ext_filter.so
LoadModule filter_module modules/mod_filter.so
LoadModule headers_module modules/mod_headers.so
LoadModule include_module modules/mod_include.so
LoadModule info_module modules/mod_info.so
LoadModule log_config_module modules/mod_log_config.so
LoadModule logio_module modules/mod_logio.so
LoadModule macro_module modules/mod_macro.so
LoadModule mime_magic_module modules/mod_mime_magic.so
LoadModule mime_module modules/mod_mime.so
LoadModule negotiation_module modules/mod_negotiation.so
LoadModule remoteip_module modules/mod_remoteip.so
LoadModule reqtimeout_module modules/mod_reqtimeout.so
LoadModule request_module modules/mod_request.so
LoadModule rewrite_module modules/mod_rewrite.so
LoadModule setenvif_module modules/mod_setenvif.so
LoadModule slotmem_plain_module modules/mod_slotmem_plain.so
LoadModule slotmem_shm_module modules/mod_slotmem_shm.so
LoadModule socache_dbm_module modules/mod_socache_dbm.so
LoadModule socache_memcache_module modules/mod_socache_memcache.so
LoadModule socache_redis_module modules/mod_socache_redis.so
LoadModule socache_shmcb_module modules/mod_socache_shmcb.so
LoadModule status_module modules/mod_status.so
LoadModule substitute_module modules/mod_substitute.so
LoadModule suexec_module modules/mod_suexec.so
LoadModule unique_id_module modules/mod_unique_id.so
LoadModule unixd_module modules/mod_unixd.so
LoadModule userdir_module modules/mod_userdir.so
LoadModule version_module modules/mod_version.so
LoadModule vhost_alias_module modules/mod_vhost_alias.so
LoadModule watchdog_module modules/mod_watchdog.so

# Configure HTTP Server Logs - Access log and Error log
sudo vi /etc/httpd/conf/httpd.conf
ServerRoot "/etc/httpd"
ErrorLog "logs/error_log" #A symbolic link to 
sudo ls  /var/log/httpd/
access_log  error_log

LogLevel warn 

sudo vi /etc/httpd/conf.d/two-websites.conf
<VirtualHost *:80>
        ServerName store.example.com
        DocumentRoot /var/www/store/
        CustomLog /var/log/httpd/store.example.com_access.log combined  # Added
        ErrorLog /var/log/httpd/store.example.com_error.log             # Added
</VirtualHost>

<VirtualHost *:80>
        ServerName blog.example.com
        DocumentRoot /var/www/blog/
</VirtualHost>

sudo systemctl reload httpd.conf

# Restrict Access to a web page
sudo mv /etc/httpd/conf.d/two-websites.conf /etc/httpd/conf.d/two-websites.conf.disabled
sudo systemctl releoad httpd.service

sudo vi /etc/httpd/conf/httpd.conf
#
# DocumentRoot: The directory out of which you will serve your
# documents. By default, all requests are taken from this directory, but
# symbolic links and aliases may be used to point to other locations.
#
DocumentRoot "/var/www/html"

#
# Relax access to content within /var/www.
#
<Directory "/var/www">
    AllowOverride None
    # Allow open access:
    Require all granted
</Directory>

# Further relax access to the default document root:
<Directory "/var/www/html">
    #
    # Possible values for the Options directive are "None", "All",
    # or any combination of:
    #   Indexes Includes FollowSymLinks SymLinksifOwnerMatch ExecCGI MultiViews
    #
    # Note that "MultiViews" must be named *explicitly* --- "Options All"
    # doesn't give it to you.
    #
    # The Options directive is both complicated and important.  Please see
    # http://httpd.apache.org/docs/2.4/mod/core.html#options
    # for more information.
    #
    # Options Indexes FollowSymLinks                                        Commented Out
    Options  FollowSymLinks                                                 # Without Indexes Options
    #
    # AllowOverride controls what directives may be placed in .htaccess files.
    # It can be "All", "None", or any combination of the keywords:
    #   Options FileInfo AuthConfig Limit
    #
    AllowOverride None

    #
    # Controls who can get stuff from this server.
    #
    Require all granted
</Directory>
# These lines we can edit  
Options Indexes FollowSymLinks # To disable browsing files and symbolic links
 AllowOverride None            # To manage special files like .htaccess  or .htpasswd file we can modify this with None or All or Have both of them there

 # We can choose to give access(allow or denied) to users by creating the relevant block as below
 <Directory "/var/www/html/test-directory">
    AllowOverride None
    # Allow open access:
    Require all denied
</Directory>

# We can opt to give a select users access based on IP
 <Directory "/var/www/html/test-directory">
    AllowOverride None
    # Allow open access:
    Require ip 1.1.1.1 8.8.8.8
</Directory>

sudo systemctl reload httpd.service

#
# The following lines prevent .htaccess and .htpasswd files from being 
# viewed by Web clients. 
#
<Files ".ht*">
    Require all denied
</Files>

<Files ".txt">
    Require all denied
</Files>

sudo systemctl reload httpd.service

 <Directory "/var/www/html/test-directory">
    AllowOverride None
    # Allow open access:
    Require ip 1.1.1.1 8.8.8.8
    AuthType Basic
    AuthBasicProvider file
    AuthName "Secret Admin Page"
    AuthUserFile /etc/httpd/password
    Require valid-user
</Directory>

# 
sudo htpasswd -c  /etc/httpd/password john
sudo htpasswd  /etc/httpd/password second_user

# Delet users on the password file we can use below
sudo htpasswd  -D /etc/httpd/password second_user

# Configure a database server
sudo dnf install -y mariadb-server
sudo systemctl enable mariadb
sudo systemctl start mariadb
sudo firewall-cmd --add-service=mysql --permanent
sudo mysql -u root
sudo mysql_secure_installation
cat /etc/my.cnf
sudo vi /etc/my.cnf.d/mariadb-server.cnf

# Manage and configure containers
docker search nginx
docker pull nginx
docker rmi -f hello-world
docker run --detach --publish 8080:80 --name mywebserver nginx




