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
java.util.Date,
org.json.JSONObject,
org.json.JSONArray,
org.ecocean.identity.IBEISIA,
twitter4j.QueryResult,
twitter4j.Status,
twitter4j.*,
org.ecocean.servlet.ServletUtilities,
org.ecocean.media.*,
org.ecocean.ParseDateLocation.*,
java.util.concurrent.ThreadLocalRandom,
org.joda.time.DateTime,
org.joda.time.Interval,
java.io.File
              "
%>

<%
String context = ServletUtilities.getContext(request);
String rootDir = request.getSession().getServletContext().getRealPath("/");
String dataDir = ServletUtilities.dataDir("context0", rootDir);
String twitterTestTimeStampFile = "/twitterTestTimeStampFile.txt";
Long timeStamp = 890302524275662848L;

// Twitter Instance
Twitter twitterInst = TwitterUtil.init(request);

// ### Test different tweets against the Twitterbot ###

String simpleTweetText = "@wildmetweetbot! I saw a whale!";
String dateTweetText = "@wildmetweetbot, I saw a whale on June 3, 2017!";
String oneImageTweetText = "@wildmetweetbot, I took a picture of a whale!";
String multImageTweetText = "@wildmetweetbot, I took some pictures of whales!";
String locationTweetText = "@wildmetweetbot Saw this cool humpback whale in the galapagos, Ecuador!";
String nonEnglishLocationTweetText = "@wildmetweetbot! Ayer vi una ballena increible en los galapagos en mexico.";
String textTweetGpsText = "@wildmetweetbot saw a whale at 45.5938,-122.737 in ningaloo. #bestvacationever";
String futureTweetText = "@wildmetweetbot Saw a whale on July 2, 2017. I'm going to see one tomorrow too!";
String pastTweetText = "@wildmetweetbot Saw a whale on July 2, 2017. I saw one yesterday, too!";

File imageFile1 = new File(dataDir + "/images/testWhale1.jpg");
File imageFile2 = new File(dataDir + "/images/testWhale2.jpg");
File imageFile3 = new File(dataDir + "/images/notAWhale.jpg");

// Test simple tweet
try {
  TwitterUtil.createTweet(simpleTweetText + new Date().toString(), twitterInst);
} catch(TwitterException e){
  e.printStackTrace();
  out.println("Unable to send simple tweet.");
}
// Test tweet with date
try {
  TwitterUtil.createTweet(dateTweetText + new Date().toString(), twitterInst);
} catch(TwitterException e){
  e.printStackTrace();
  out.println("Unable to send date tweet.");
}
// Test tweet with location
try {
  TwitterUtil.createTweet(locationTweetText + new Date().toString(), twitterInst);
} catch(TwitterException e){
  e.printStackTrace();
  out.prinln("Unable to send location tweet.");
}
// Test tweet with non English text
try {
  TwitterUtil.createTweet(nonEnglishLocationTweetText + new Date().toString(), twitterInst);
} catch(TwitterException e){
  e.printStackTrace();
  out.prinln("Unable to send non-English location tweet.");
}
// Test tweet with GPS text
try {
  TwitterUtil.createTweet(textTweetGpsText + new Date().toString(), twitterInst);
} catch(TwitterException e){
  e.printStackTrace();
  out.prinln("Unable to send GPS location tweet.");
}
// Test tweet with future text
try {
  TwitterUtil.createTweet(futureTweetText + new Date().toString(), twitterInst);
} catch(TwitterException e){
  e.printStackTrace();
  out.prinln("Unable to send future tweet.");
}
// Test tweet with past text
try {
  TwitterUtil.createTweet(pastTweetText + new Date().toString(), twitterInst);
} catch(TwitterException e){
  e.printStackTrace();
  out.prinln("Unable to send past tweet.");
}
// Test tweet with one image
StatusUpdate status = new StatusUpdate(oneImageTweetText + new Date().toString());
status.setMedia(imageFile1);
try {
  twitterInst.updateStatus(status);
} catch(TwitterException e){
  e.printStackTrace();
  out.println("Unable to send single image tweet.");
}
// Test tweet with multiple images
long mediaIds[] = new long[2];
try {
  // Upload media and get ids
  UploadedMedia media = twitterInst.uploadMedia(imageFile1);
  out.println("Uploaded Media: " + media.getMediaId());
  mediaIds[0] = media.getMediaId();
  media = twitterInst.uploadMedia(imageFile2);
  out.println("Uploaded Media: " + media.getMediaId());
  mediaIds[1] = media.getMediaId();
  // Set media ids to status
  StatusUpdate multiStatus = new StatusUpdate(multImageTweetText + new Date().toString());
  multiStatus.setMediaIds(mediaIds);
  twitterInst.updateStatus(multiStatus);
} catch(TwitterException e){
  e.printStackTrace();
  out.println("Unable to send multi-image tweet.");
}

// ###              End tweet tests                 ###

%>
