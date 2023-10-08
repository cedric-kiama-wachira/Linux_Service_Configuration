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
