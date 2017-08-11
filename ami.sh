#!/bin/bash

cp /home/ubuntu/Wildbook_javaTweetBot/twitter.properties /home/ubuntu/Wildbook_javaTweetBot/src/main/resources/bundles/twitter.properties
cp /var/lib/tomcat/webapps/wildbook/tweetFind.jsp /home/ubuntu/Wildbook_javaTweetBot/src/main/webapp/

#rm -rf /var/lib/tomcat/webapps/wildbook.war

rm -rf /var/lib/tomcat/webapps/wildbook

rm -rf /var/lib/tomcat/logs/catalina.out

mvn clean install -DskipTests -Dmaven.javadoc.skip=true
cp /home/ubuntu/Wildbook_javaTweetBot/target/wildbook-6.0.0-EXPERIMENTAL.war /var/lib/tomcat/webapps/wildbook.war

cd /var/lib; sudo chmod -R 777 tomcat

