############################################
# Information relevant to PHP OCI / Oracle installation
# https://www.davescripts.com/docker-container-with-centos-7-apache-php-73
# https://www.oracle.com/webfolder/technetwork/tutorials/obe/db/oow10/php_db/php_db.htm#t2
# https://stackoverflow.com/questions/26145605/pecl-oci8-failed-install-after-upgrade-to-php5-6/26145627
# https://alvinbunk.wordpress.com/2018/12/29/fatal-error-oci8_dtrace_gen-h-no-such-file-or-directory/
# https://stackoverflow.com/questions/44163450/php-oci8-wont-install-through-pecl-fatal-error-oci8-dtrace-gen-h
# https://unix.stackexchange.com/questions/256083/installing-oci8-php-extension
# https://superuser.com/questions/1079175/php-5-6-oci8-install-issue
# https://www.unixmen.com/install-oracle-client-centos/
# https://medium.com/@asasmoyo/setup-php-oci8-on-centos-7-ubuntu14-04-b9d97383fda4
# https://medium.com/@asasmoyo/setup-php-oci8-on-centos-7-ubuntu14-04-b9d97383fda4
# https://www.drupal.org/node/59680
############################################

FROM centos:7

############################################
# Install Apache
############################################
RUN yum -y update
RUN yum -y install httpd httpd-tools

############################################
# Install EPEL Repo
############################################
RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN rpm -Uvh http://rpms.remirepo.net/enterprise/remi-release-7.rpm

############################################
# Install PHP
############################################
RUN yum --enablerepo=remi-php73 -y install php php-bcmath php-cli php-common php-gd php-intl php-ldap php-mbstring \
    php-mysqlnd php-pear php-soap php-xml php-xmlrpc php-zip php-devel php-oci8

############################################
# Install Other packages
############################################
RUN yum -y install wget unzip make systemtap-sdt-devel

############################################
# Install Oracle instantclient
############################################
RUN wget https://download.oracle.com/otn_software/linux/instantclient/195000/oracle-instantclient19.5-basic-19.5.0.0.0-1.x86_64.rpm
RUN wget https://download.oracle.com/otn_software/linux/instantclient/195000/oracle-instantclient19.5-devel-19.5.0.0.0-1.x86_64.rpm
RUN yum -y localinstall oracle* --nogpgcheck

############################################
# Configure Oracle instant client
############################################
RUN mkdir /usr/lib/oracle/19.5/client64/network/admin -p
RUN touch /usr/lib/oracle/19.5/client64/network/admin/tnsnames.ora

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Expose tnsnames.ora outside container
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

############################################
# Configure Environment Variables
############################################
RUN touch /etc/profile.d/client.sh
RUN echo "export ORACLE_HOME=/usr/lib/oracle/19.5/client64" >> /etc/profile.d/client.sh
RUN echo "export PATH=$PATH:$ORACLE_HOME/bin" >> /etc/profile.d/client.sh
RUN echo "export LD_LIBRARY_PATH=$ORACLE_HOME/lib" >> /etc/profile.d/client.sh
RUN echo "export TNS_ADMIN=$ORACLE_HOME/network/admin" >> /etc/profile.d/client.sh
## sh /etc/profile.d/client.sh

############################################
# Install PECL
############################################
RUN export PHP_DTRACE=yes && echo "instantclient,/usr/lib/oracle/19.5/client64/lib"|pecl install oci8

############################################
# Update PHP configuration
############################################
RUN echo " " >> /etc/php.ini
RUN echo "[OCI8]" >> /etc/php.ini
RUN echo "extension=oci8.so" >> /etc/php.ini

############################################
# Update Apache Configuration
############################################
RUN sed -E -i -e '/<Directory "\/var\/www\/html">/,/<\/Directory>/s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf
RUN sed -E -i -e 's/DirectoryIndex (.*)$/DirectoryIndex index.php \1/g' /etc/httpd/conf/httpd.conf

RUN echo " " >> /etc/httpd/conf/httpd.conf
RUN echo "SetEnv LD_LIBRARY_PATH /usr/lib/oracle/19.5/client64/lib/" >> /etc/httpd/conf/httpd.conf

############################################
# PHPInfo testfile - should be deleted later.
############################################
RUN touch /var/www/html/test.php
RUN echo "<?php" >> /var/www/html/test.php
RUN echo "phpinfo();" >> /var/www/html/test.php
RUN echo "?>" >> /var/www/html/test.php

############################################
# Expose port
############################################
EXPOSE 80

############################################
# Start Apache
############################################
CMD ["/usr/sbin/httpd","-D","FOREGROUND"]