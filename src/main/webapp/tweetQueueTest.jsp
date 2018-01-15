<%@ page contentType="text/plain; charset=utf-8" language="java"

  import="org.ecocean.*,
  java.util.ArrayList,
  java.io.FileNotFoundException,
  java.io.IOException,
  java.util.List,
  java.io.BufferedReader,
  java.io.IOException,
  java.io.InputStream,
  java.io.InputStreamReader,
  java.io.File,
  org.json.JSONObject,
  org.json.JSONArray,
  twitter4j.*,
  org.ecocean.servlet.ServletUtilities,
  java.util.concurrent.ThreadLocalRandom,
  org.joda.time.DateTime,
  org.joda.time.Interval"
  %>

  <%
  String rootDir = null;
  String dataDir = null;
  String tweetQueueFile = "/tweetQueue.txt";
  try{
    rootDir = request.getSession().getServletContext().getRealPath("/");
    dataDir = ServletUtilities.dataDir("context0", rootDir);
    System.out.println("dataDir is: " + dataDir);
  } catch(Exception e){
    System.out.println("couldn't get rootDir or dataDir in sendThisManyTweetsFromTheQueue method");
  }
  String reply1 = "@markaaronfisher, this is a test";
  String reply2 = "@markaaronfisher, this is the second test";
  String reply3 = "@markaaronfisher, this is the third test";
  String reply4 = "@markaaronfisher, this is the fourth test";
  String reply5 = "@markaaronfisher, this is the fifth test";
  Twitter twitterInst = TwitterUtil.init(request);
  if(rootDir != null && dataDir != null){
    TwitterUtil.addTweetToQueue(reply1, twitterInst, dataDir + tweetQueueFile);
    TwitterUtil.addTweetToQueue(reply2, twitterInst, dataDir + tweetQueueFile);
    TwitterUtil.addTweetToQueue(reply3, twitterInst, dataDir + tweetQueueFile);
    TwitterUtil.addTweetToQueue(reply4, twitterInst, dataDir + tweetQueueFile);
    TwitterUtil.addTweetToQueue(reply5, twitterInst, dataDir + tweetQueueFile);
    TwitterUtil.removeTweetFromQueue(reply1, twitterInst, dataDir + tweetQueueFile);
    TwitterUtil.sendThisManyTweetsFromTheQueue(3, dataDir + tweetQueueFile, twitterInst);
  }
  %>
