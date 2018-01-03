#!/bin/bash

sudo cp /home/ubuntu/Wildbook_javaTweetBot/twitter.properties /home/ubuntu/Wildbook_javaTweetBot/src/main/resources/bundles/twitter.properties
#sudo cp /home/ubuntu/Wildbook_javaTweetBot/twitter.properties /data/whaleshark_data_dirs/shepherd_data_dir/WEB-INF/classes/bundles/
sudo cp /home/ubuntu/Wildbook_javaTweetBot/twitter.properties /data/wildbook_data_dir/WEB-INF/classes/bundles/

#rm -rf /var/lib/tomcat7/webapps/wildbook.war
#
#rm -rf /var/lib/tomcat7/webapps/wildbook
#
#rm -rf /var/lib/tomcat7/logs/catalina.out
#
rm -rf /opt/tomcat/webapps/wildbook.war

rm -rf /opt/tomcat/webapps/wildbook

rm -rf /opt/tomcat/logs/catalina.out


mvn clean install -DskipTests -Dmaven.javadoc.skip=true
#cp /home/ubuntu/Wildbook_javaTweetBot/target/wildbook-6.0.0-EXPERIMENTAL.war /var/lib/tomcat7/webapps/wildbook.war
cp /home/ubuntu/Wildbook_javaTweetBot/target/wildbook-6.0.0-EXPERIMENTAL.war /opt/tomcat/webapps/wildbook.war
##sudo mkdir /var/lib/tomcat7/webapps
##sudo mkdir /opt/tomcat/webapps
#cp -R /home/ubuntu/Wildbook_javaTweetBot/target/wildbook-6.0.0-EXPERIMENTAL/ /var/lib/tomcat7/webapps/wildbook/
##cp -R /home/ubuntu/Wildbook_javaTweetBot/target/wildbook-6.0.0-EXPERIMENTAL/ /opt/tomcat/webapps/wildbook/
#sudo chmod 777 /var/lib/tomcat7/webapps/wildbook.war
sudo chmod 777 /opt/tomcat/webapps/wildbook.war

#cd /var/lib; sudo chmod -R 777 tomcat7/; sudo chown -R tomcat7 tomcat7/; sudo chgrp -R tomcat7 tomcat7/
#cd /opt/; sudo chmod -R 777 tomcat/; sudo chown -R ubuntu tomcat/; sudo chgrp -R ubuntu tomcat/
sudo cd /opt/; sudo chmod -R 777 tomcat/; sudo chown -R tomcat tomcat/; sudo chgrp -R tomcat tomcat/

