git stash
git checkout counterTweet
sudo service tomcat7 stop
sudo ./ami.sh>buildOutput.txt 2>buildError.txt
sudo service tomcat7 restart
curl http://34.213.108.79/tweetImageTest.jsp >> buildOutput.txt 2>>buildError.txt
sudo service tomcat7 stop
git checkout overloadCallbacks
git pop
