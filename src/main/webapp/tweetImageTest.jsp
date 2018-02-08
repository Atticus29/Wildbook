<%@ page contentType="text/plain; charset=utf-8" language="java"

import="org.ecocean.*,
java.util.ArrayList,
java.io.FileNotFoundException,
java.io.IOException,
java.util.List,
java.util.Map,
java.util.HashMap,
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
Twitter twitterInst = TwitterUtil.init(context);


//Check on status posting limits
Map<String,RateLimitStatus> rateLimitStatusMap = twitterInst.getRateLimitStatus();
 //.get("/statuses/mentions_timeline");
 // System.out.println(rateLimitStatusMap);
// System.out.println("Limit: " + rateLimitStatusMap.getLimit());
// System.out.println("Remaining: " + rateLimitStatusMap.getRemaining());
// System.out.println("ResetTimeInSeconds: " + rateLimitStatusMap.getResetTimeInSeconds());
// System.out.println("SecondsUntilReset: " + rateLimitStatusMap.getSecondsUntilReset());

// ### Test different tweets against the Twitterbot ###

String simpleTweetText = "@FlukeBot! I saw a whale!";
String dateTweetText = "@FlukeBot, I saw a whale on June 3, 2017!";
String oneImageTweetText = "@FlukeBot, I took a picture of a whale!";
String oneImageNotWhaleTweetText = "@FlukeBot, I took a picture of a whale! This is a whale, right?";
String multImageTweetText = "@FlukeBot, I took some pictures of whales!";
String multImageNotWhaleTweetText = "@FlukeBot, I took some pictures of whales! These are whales, aren't they?";
String multImageOneNotWhaleTweetText = "@FlukeBot, I took some pictures of whales! These are both whales, aren't they?";
String locationTweetText = "@FlukeBot Saw this cool humpback whale in the galapagos, Ecuador!";
String nonEnglishLocationTweetText = "@FlukeBot! Ayer vi una ballena increible en los galapagos en mexico.";
String textTweetGpsText = "@FlukeBot saw a whale at 45.5938,-122.737 in ningaloo. #bestvacationever";
String futureTweetText = "@FlukeBot Saw a whale on July 2, 2017. I'm going to see one tomorrow too!";
String pastTweetText = "@FlukeBot Saw a whale on July 2, 2017. I saw one yesterday, too!";

File imageFileWhale1 = new File(dataDir + "/images/testWhale1.jpg");
File imageFileWhale2 = new File(dataDir + "/images/testWhale2.jpg");
File imageFileWhale3 = new File(dataDir + "/images/testWhale3.jpg");
File imageFileWhale4 = new File(dataDir + "/images/testWhale4.jpg");
File imageFileNotAWhale1 = new File(dataDir + "/images/notAWhale1.jpg");
File imageFileNotAWhale2 = new File(dataDir + "/images/notAWhale2.jpg");
File imageFileNotAWhale3 = new File(dataDir + "/images/notAWhale3.jpg");
File imageFileNotAWhale4 = new File(dataDir + "/images/notAWhale4.jpg");

// // Test simple tweet
// try {
//   TwitterUtil.createTweet(simpleTweetText + new Date().toString(), twitterInst);
// } catch(TwitterException e){
//   e.printStackTrace();
//   out.println("Unable to send simple tweet.");
// }
// // Test tweet with date
// try {
//   TwitterUtil.createTweet(dateTweetText + new Date().toString(), twitterInst);
// } catch(TwitterException e){
//   e.printStackTrace();
//   out.println("Unable to send date tweet.");
// }
// // Test tweet with location
// try {
//   TwitterUtil.createTweet(locationTweetText + new Date().toString(), twitterInst);
// } catch(TwitterException e){
//   e.printStackTrace();
//   out.println("Unable to send location tweet.");
// }
// // Test tweet with non English text
// try {
//   TwitterUtil.createTweet(nonEnglishLocationTweetText + new Date().toString(), twitterInst);
// } catch(TwitterException e){
//   e.printStackTrace();
//   out.println("Unable to send non-English location tweet.");
// }
// // Test tweet with GPS text
// try {
//   TwitterUtil.createTweet(textTweetGpsText + new Date().toString(), twitterInst);
// } catch(TwitterException e){
//   e.printStackTrace();
//   out.println("Unable to send GPS location tweet.");
// }
// // Test tweet with future text
// try {
//   TwitterUtil.createTweet(futureTweetText + new Date().toString(), twitterInst);
// } catch(TwitterException e){
//   e.printStackTrace();
//   out.println("Unable to send future tweet.");
// }
// // Test tweet with past text
// try {
//   TwitterUtil.createTweet(pastTweetText + new Date().toString(), twitterInst);
// } catch(TwitterException e){
//   e.printStackTrace();
//   out.println("Unable to send past tweet.");
// }


// Test tweet with one non-whale image
StatusUpdate status = new StatusUpdate(oneImageNotWhaleTweetText + new Date().toString());
status.setMedia(imageFileNotAWhale1);
try {
  twitterInst.updateStatus(status);
} catch(TwitterException e){
  e.printStackTrace();
  out.println("Unable to send single image tweet.");
}

// Test tweet with one whale image
status = new StatusUpdate(oneImageTweetText + new Date().toString());
status.setMedia(imageFileWhale1);
try {
  twitterInst.updateStatus(status);
} catch(TwitterException e){
  e.printStackTrace();
  out.println("Unable to send single image tweet.");
}



// Test tweet with multiple whale images
long mediaIds[] = new long[2];
try {
  // Upload media and get ids
  UploadedMedia media = twitterInst.uploadMedia(imageFileWhale2);
  out.println("Uploaded Media: " + media.getMediaId());
  mediaIds[0] = media.getMediaId();
  media = twitterInst.uploadMedia(imageFileWhale3);
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

// Test tweet with one non-whale image and one whale image
mediaIds = new long[2];
try {
  // Upload media and get ids
  UploadedMedia media = twitterInst.uploadMedia(imageFileNotAWhale4);
  out.println("Uploaded Media: " + media.getMediaId());
  mediaIds[0] = media.getMediaId();
  media = twitterInst.uploadMedia(imageFileWhale4);
  out.println("Uploaded Media: " + media.getMediaId());
  mediaIds[1] = media.getMediaId();
  // Set media ids to status
  StatusUpdate multiStatus = new StatusUpdate(multImageOneNotWhaleTweetText + new Date().toString());
  multiStatus.setMediaIds(mediaIds);
  twitterInst.updateStatus(multiStatus);
} catch(TwitterException e){
  e.printStackTrace();
  out.println("Unable to send multi-image tweet.");
}

// Test tweet with multiple non-whale images
mediaIds = new long[2]; //may need long mediaIds[] = new long[2];
try {
  // Upload media and get ids
  UploadedMedia media = twitterInst.uploadMedia(imageFileNotAWhale2);
  out.println("Uploaded Media: " + media.getMediaId());
  mediaIds[0] = media.getMediaId();
  media = twitterInst.uploadMedia(imageFileNotAWhale3);
  out.println("Uploaded Media: " + media.getMediaId());
  mediaIds[1] = media.getMediaId();
  // Set media ids to status
  StatusUpdate multiStatus = new StatusUpdate(multImageNotWhaleTweetText + new Date().toString());
  multiStatus.setMediaIds(mediaIds);
  twitterInst.updateStatus(multiStatus);
} catch(TwitterException e){
  e.printStackTrace();
  out.println("Unable to send multi-image tweet.");
}
// ###              End tweet tests                 ###

rateLimitStatusMap = twitterInst.getRateLimitStatus();
System.out.println(rateLimitStatusMap);

%>
