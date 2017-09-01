#!/bin/bash

cp /usr/local/apache-tomcat-7.0.79/webapps/wildbook/tweetFind.jsp ~/Desktop/temp/Wildbook_javaTweetBot/src/main/webapp/
cp /usr/local/apache-tomcat-7.0.79/webapps/wildbook/tweetTest.jsp ~/Desktop/temp/Wildbook_javaTweetBot/src/main/webapp/
cp /usr/local/apache-tomcat-7.0.79/webapps/wildbook/tweetImageTest.jsp ~/Desktop/temp/Wildbook_javaTweetBot/src/main/webapp/

rm -rf /usr/local/apache-tomcat-7.0.79/webapps/wildbook.war

rm -rf /usr/local/apache-tomcat-7.0.79/webapps/wildbook

rm -rf /usr/local/apache-tomcat-7.0.79/logs/catalina.out

mvn clean install -DskipTests -Dmaven.javadoc.skip=true && cp /Users/mf/Desktop/temp/Wildbook_javaTweetBot/target/wildbook-6.0.0-EXPERIMENTAL.war /usr/local/apache-tomcat-7.0.79/webapps/wildbook.war

cp ~/Desktop/temp/Wildbook_javaTweetBot/twitter.properties /Desktop/temp/Wildbook_javaTweetBot/target/classes/bundles/
cp ~/Desktop/temp/Wildbook_javaTweetBot/twitter.properties /Desktop/temp/Wildbook_javaTweetBot/target/wildbook-6.0.0-EXPERIMENTAL/WEB-INF/classes/bundles/
cp ~/Desktop/temp/Wildbook_javaTweetBot/twitter.properties /Users/mf/Applications/tomcat/webapps/wildbook/WEB-INF/classes/bundles/
cp ~/Desktop/temp/Wildbook_javaTweetBot/twitter.properties /Users/mf/Applications/tomcat/webapps/wildbook_data_dir/WEB-INF/classes/bundles/twitter.properties

