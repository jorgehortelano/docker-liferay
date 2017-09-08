FROM openjdk:8-jdk-alpine
LABEL Maintainer="Jorge Hortelano" \
      Description="Liferay installation over a Tomcat 8 & MariaDB. Based on Alpine Linux."

# Install required packages
RUN apk --no-cache add curl supervisor pwgen mysql mysql-client bash

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Install liferay
ENV liferay_folder	/opt/liferay-ce-portal-7.0-ga4
ENV tomcat_folder	/opt/liferay-ce-portal-7.0-ga4/tomcat-8.0.32

RUN curl -O -s -k -L -C - https://downloads.sourceforge.net/project/lportal/Liferay%20Portal/7.0.3%20GA4/liferay-ce-portal-tomcat-7.0-ga4-20170613175008905.zip \	
	&& mkdir /opt \
	&& unzip liferay-ce-portal-tomcat-7.0-ga4-20170613175008905.zip -d /opt \
	&& rm liferay-ce-portal-tomcat-7.0-ga4-20170613175008905.zip

#ADD liferay-ce-portal-tomcat-7.0-ga4-20170613175008905.zip /tmp
#RUN mkdir /opt \
#	&& unzip /tmp/liferay-ce-portal-tomcat-7.0-ga4-20170613175008905.zip -d /opt \
#	&& rm /tmp/liferay-ce-portal-tomcat-7.0-ga4-20170613175008905.zip

# Add config to tomcat
RUN /bin/echo -e '\nCATALINA_OPTS="$CATALINA_OPTS -Dfile.encoding=UTF8 -Djava.net.preferIPv4Stack=true"' >> ${tomcat_folder}/bin/setenv.sh

# Add configuration liferay file and disable installation wizard
ADD config/portal-bundle.properties ${liferay_folder}/portal-bundle.properties
ADD config/portal-bd-MYSQL.properties ${liferay_folder}/portal-bd-MYSQL.properties

#Set home variable
RUN sed -i "s|HOME|${liferay_folder}|g" ${liferay_folder}/portal-bundle.properties \
	&& echo -e ${liferay_folder} > /tmp/liferay_home;

WORKDIR ${liferay_folder}

# Volumes
VOLUME /var/liferay ${liferay_folder}

#Install MySQL
RUN /usr/bin/mysql_install_db --user=mysql \
    && cp /usr/share/mysql/mysql.server /etc/init.d/mysqld
    
# Entrypoint to prepare mysql-database
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

# Ports
EXPOSE 8080

VOLUME /var/lib/mysql

# EXEC
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]