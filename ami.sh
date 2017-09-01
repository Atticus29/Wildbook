#!/bin/bash

cp /home/ubuntu/Wildbook_javaTweetBot/twitter.properties /home/ubuntu/Wildbook_javaTweetBot/src/main/resources/bundles/twitter.properties
cp /home/ubuntu/Wildbook_javaTweetBot/twitter.properties /data/whaleshark_data_dirs/shepherd_data_dir/WEB-INF/classes/bundles/

rm -rf /var/lib/tomcat7/webapps/wildbook.war

rm -rf /var/lib/tomcat7/webapps/wildbook

rm -rf /var/lib/tomcat7/logs/catalina.out

mvn clean install -DskipTests -Dmaven.javadoc.skip=true
#cp /home/ubuntu/Wildbook_javaTweetBot/target/wildbook-6.0.0-EXPERIMENTAL.war /var/lib/tomcat7/webapps/wildbook.war
sudo mkdir /var/lib/tomcat7/webapps
cp -R /home/ubuntu/Wildbook_javaTweetBot/target/wildbook-6.0.0-EXPERIMENTAL/ /var/lib/tomcat7/webapps/wildbook/
#sudo chmod 777 /var/lib/tomcat7/webapps/wildbook.war

cd /var/lib; sudo chmod -R 777 tomcat7/; sudo chown -R tomcat7 tomcat7/; sudo chgrp -R tomcat7 tomcat7/
