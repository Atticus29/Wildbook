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

  String oldTaskID = "be8f3a7d-6efa-4a65-85ac-604c9ff15a66"; //@TODO you'll have to modify this line to test
  String newTaskID = "testWorked"; //@TODO you'll have to modify this line to test
  if(rootDir != null){
    TwitterUtil.updatePendingResultsWithNewIdentificationTaskID(oldTaskID, newTaskID, rootDir); //@TODO you'll have to modify this line to test
  }

  %>
