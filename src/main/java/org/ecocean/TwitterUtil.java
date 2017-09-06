package org.ecocean;

import javax.servlet.http.HttpServletRequest;
import java.util.Properties;
import org.ecocean.servlet.ServletUtilities;
import org.joda.time.LocalDateTime;
import org.json.JSONObject;
import org.json.JSONArray;
import org.json.JSONException;

import org.ecocean.media.TwitterAssetStore;
import org.ecocean.media.MediaAsset;
import org.ecocean.media.MediaAssetMetadata;
import org.ecocean.media.MediaAssetFactory;
import org.ecocean.identity.IBEISIA;

import com.google.gson.Gson;
import java.util.List;
import java.util.ArrayList;
import java.util.Arrays;
import java.io.IOException;
import java.io.FileNotFoundException;

/*
import java.net.URL;
import java.io.File;

import java.io.IOException;
import java.net.MalformedURLException;
import java.security.NoSuchAlgorithmException;
import java.security.InvalidKeyException;
*/
import twitter4j.*;
import twitter4j.conf.ConfigurationBuilder;
import twitter4j.Status;

public class TwitterUtil {
  private static TwitterFactory tfactory = null;

  public static Twitter init(HttpServletRequest request) {
    String context = ServletUtilities.getContext(request);
    tfactory = getTwitterFactory(context);
    System.out.println("INFO: initialized TwitterUtil.tfactory");
    return tfactory.getInstance();
  }

  public static boolean isActive() {
    return (tfactory != null);
  }


  //https://dev.twitter.com/rest/public/search   e.g. "whaleshark filter:media"
  public static QueryResult findTweets(String search) throws TwitterException {
    return findTweets(search, -1l);
  }
  public static QueryResult findTweets(String search, long sinceId) throws TwitterException {
    Twitter tw = tfactory.getInstance();
    Query query = new Query(search);
    if (sinceId >= 0l){
      System.out.println("sinceId is " + Long.toString(sinceId) + " and is >= 0l");
      query.setSinceId(sinceId);
    }
    return tw.search(query);
  }

  public static Status getTweet(long tweetId) {
    Twitter tw = tfactory.getInstance();
    try {
      return tw.showStatus(tweetId);
    } catch (TwitterException tex) {
      System.out.println("ERROR: TwitterUtil.getTweet(" + tweetId + ") threw " + tex.toString());
      return null;
    } catch (Exception ex) {
      System.out.println("ERROR: TwitterUtil.getTweet(" + tweetId + ") threw " + ex.toString());
    }
    return null;
  }

  public static String toJSONString(Object obj) {
    String returnVal = null;
    Gson gson = new Gson();
    returnVal = gson.toJson(obj);
    if(returnVal == null){
      System.out.println("returnVal in toJSONString is null");
    }
    System.out.println(returnVal);
    return returnVal;
  }
  public static JSONObject toJSONObject(Object obj) {
    String s = toJSONString(obj);
    if (s == null){
      System.out.println("toJSONString is null");
      return null;
    }
    try {
      JSONObject j = new JSONObject(s);
      return j;
    } catch (JSONException ex) {
      System.out.println("ERROR: TwitterUtil.toJSONObject() could not parse '" + s + "' as JSON: " + ex.toString());
      return null;
    }
  }

  //http://twitter4j.org/en/configuration.html
  public static TwitterFactory getTwitterFactory(String context) {
    Properties props = ShepherdProperties.getProperties("twitter.properties", "", context);
    if (props == null) throw new RuntimeException("no twitter.properties");
    String debug = props.getProperty("debug");
    String consumerKey = props.getProperty("consumerKey");
    if ((consumerKey == null) || consumerKey.equals("")) throw new RuntimeException("twitter.properties missing consumerKey");  //hopefully enough of a hint
    String consumerSecret = props.getProperty("consumerSecret");
    String accessToken = props.getProperty("accessToken");
    String accessTokenSecret = props.getProperty("accessTokenSecret");
    ConfigurationBuilder cb = new ConfigurationBuilder();
    cb.setDebugEnabled((debug != null) && debug.toLowerCase().equals("true"))
    .setOAuthRequestTokenURL("https://api.twitter.com/oauth2/request_token")
    .setOAuthAuthorizationURL("https://api.twitter.com/oauth2/authorize")
    .setOAuthAccessTokenURL("https://api.twitter.com/oauth2/access_token")
    .setOAuthConsumerKey(consumerKey)
    .setOAuthConsumerSecret(consumerSecret)
    .setOAuthAccessToken(accessToken)
    .setJSONStoreEnabled(true)
    .setOAuthAccessTokenSecret(accessTokenSecret);
    return new TwitterFactory(cb.build());
  }

  public static void sendCourtesyTweet(String screenName, String mediaType,  Twitter twitterInst, Long twitterId) {
    String reply = null;
    if(mediaType.equals("photo")) {
      reply = "Thank you for the photo(s), including id " + Long.toString(twitterId) + ", @" + screenName + "! Result pending!";
    } else {
      reply = "Thanks for tweet " + Long.toString(twitterId) + ", @" + screenName + "! Could you send me a pic in a new tweet?";
    }
    try {
      String status = createTweet(reply, twitterInst);
    } catch(TwitterException e) {
      e.printStackTrace();
    }
  }

  public static void sendCourtesyTweet(String screenName, String mediaType,  Twitter twitterInst, String id) {
    String reply = null;
    if(mediaType.equals("photo")) {
      reply = "Thank you for the photo(s), including id " + id + ", @" + screenName + "! Result pending!";
    } else {
      reply = "Thanks for tweet " + id + ", @" + screenName + "! Could you send me a pic in a new tweet?";
    }
    try {
      String status = createTweet(reply, twitterInst);
    } catch(TwitterException e) {
      e.printStackTrace();
    }
  }

  public static void sendPhotoSpecificCourtesyTweet(org.json.JSONArray emedia, String tweeterScreenName, Twitter twitterInst){
    int photoCount = 0;
    org.json.JSONObject jent = null;
    String mediaType = null;
    Long mediaEntityId = null;
    for(int j=0; j<emedia.length(); j++){
      try{
        jent = emedia.getJSONObject(j);
        mediaType = jent.getString("type");
        mediaEntityId = Long.parseLong(jent.getString("id"));
      } catch(Exception e){
        System.out.println("Error with JSONObject capture");
        e.printStackTrace();
      }

      try{
        if(mediaType.equals("photo")){
          //For now, just one courtesy tweet per tweet, even if the tweet contains multiple images
          if(photoCount<1){
            TwitterUtil.sendCourtesyTweet(tweeterScreenName, mediaType, twitterInst, mediaEntityId);
          }
          photoCount += 1;
        }
      } catch(Exception e){
        e.printStackTrace();
      }
    }
  }

  public static ArrayList<String> getPhotoIds(org.json.JSONArray emedia, String tweeterScreenName, Twitter twitterInst) throws Exception{
    ArrayList<String> photoIds = new ArrayList<>();
    int photoCount = 0;
    org.json.JSONObject jent = null;
    // Long mediaEntityId = null;
    for(int j=0; j<emedia.length(); j++){
      try{
        jent = emedia.getJSONObject(j);
        System.out.println("emedia element:");
        System.out.println(jent.toString());
        photoIds.add(jent.getString("id"));
      } catch(Exception e){
        System.out.println("Error with JSONObject capture getPhotoIds method");
        e.printStackTrace();
      }
    }
    if (photoIds ==null & photoIds.size()<1){
      throw new Exception ("photoIds was null or contained no elements");
    }
    return photoIds;
  }

  public static JSONObject makeParentTweetMediaAssetAndSave(Shepherd myShepherd, TwitterAssetStore tas, Status tweet, JSONObject tj){
    myShepherd.beginDBTransaction();
    try{
      MediaAsset ma = tas.create(Long.toString(tweet.getId()));  //parent (aka tweet)
      ma.addLabel("_original");
      MediaAssetMetadata md = ma.updateMetadata();
      MediaAssetFactory.save(ma, myShepherd);
      // JSONObject test = TwitterUtil.toJSONObject(ma);
      tj.put("maId", ma.getId());
      tj.put("metadata", ma.getMetadata().getData());
      System.out.println(tweet.getId() + ": created tweet asset " + ma);
      myShepherd.commitDBTransaction();
      return tj;
    } catch(Exception e){
      myShepherd.rollbackDBTransaction();
      e.printStackTrace();
      return tj;
    }
  }

  public static JSONArray saveEntitiesAsMediaAssetsToSheperdDatabaseAndSendEachToImageAnalysis(List<MediaAsset> mas, Long tweetID, Shepherd myShepherd, JSONObject tj, HttpServletRequest request, JSONArray tarr, JSONArray iaPendingResults, ArrayList<String> photoIds){
    if ((mas == null) || (mas.size() < 1)) {
    } else {
      JSONArray jent = new JSONArray();
      for(int i=0; i<mas.size(); i++){
        MediaAsset ent = mas.get(i);
        myShepherd.beginDBTransaction();
        try {
          JSONObject ej = new JSONObject();
          // MediaAssetMetadata entMd = ent.updateMetadata();
          MediaAssetFactory.save(ent, myShepherd);
          System.out.println("Ent's mediaAssetID is " + ent.toString());
          // MediaAssetFactory.save(ent, myShepherd);
          String taskId = IBEISIA.IAIntake(ent, myShepherd, request);
          ej.put("maId", ent.getId());
          ej.put("taskId", taskId);
          ej.put("creationDate", new LocalDateTime());
          String tweeterScreenName = tj.getJSONObject("tweet").getJSONObject("user").getString("screenName");
          ej.put("tweeterScreenName", tweeterScreenName);
          if(photoIds.size() != mas.size()){
            System.out.println("Yikes! photoIds is not the same size as mas");
          } else{
            ej.put("photoId", photoIds.get(i));
          }


          //jent = emedia.getJSONObject(j);
          // mediaType = jent.getString("type");
          // mediaEntityId = Long.parseLong(jent.getString("id"));

          jent.put(ej);
          iaPendingResults.put(ej);
          // myShepherd.getPM().makePersistent(ej); //maybe?
          myShepherd.commitDBTransaction();
        } catch(Exception e){
          myShepherd.rollbackDBTransaction();
          e.printStackTrace();
        }
      }
      tj.put("entities", jent);
    }
    tarr.put(tj);
    return iaPendingResults;
  }


  public static void sendDetectionAndIdentificationTweet(String screenName, String imageId, Twitter twitterInst, String whaleId, boolean detected, boolean identified, String info, HttpServletRequest request){
    String tweet = null, tweet2 = null;
    if(detected && identified){
      tweet = "Hi, @" + screenName + "! We detected a whale in " + imageId + " and identified it as " + whaleId + "!";
      tweet2 = "@" + screenName + ", here's some info on " + whaleId + ": " + info; //TODO flesh out either by pulling info from db now that whaleId is available, or by passing some info as an additional argument in this method
    } else if(detected && !identified){
      tweet =  "Hi, @" + screenName + "! We detected a whale in " + imageId + " but we were not able to identify it.";
      tweet2 = "@" + screenName + ", if you'd like to make a manual submission for " + imageId + ", please go to http://www.flukebook.org/submit.jsp";
    } else {
      tweet =  "Hi, @" + screenName + "! We were not able to identify a whale in " + imageId + ".";
      tweet2 = "@" + screenName + ", if you'd like to make a manual submission for " + imageId + ", please go to http://www.flukebook.org/submit.jsp";
    }

    try {
      String status1 = createTweet(tweet, twitterInst);
      String status2 = createTweet(tweet2, twitterInst);
      try{
        removeEntryFromPendingIaByImageId(imageId, request);
      } catch(Exception f){
        System.out.println("removeEntryFromPendingIaByImageId failed inside sendDetectionAndIdentificationTweet method");
        f.printStackTrace();
      }
    } catch(TwitterException e){
      e.printStackTrace();
    }
  }

  public static void sendTimeoutTweet(String screenName, Twitter twitterInst, String id) {
    String reply = "Hello @" + screenName + "The image you sent for tweet " + id + " was unable to be processed";
    String reply2 = "@" + screenName + ", if you'd like to make a manual submission, please go to http://www.flukebook.org/submit.jsp";
    try {
      String status = createTweet(reply, twitterInst);
      String status2 = createTweet(reply2, twitterInst);
    } catch(TwitterException e) {
      e.printStackTrace();
    }
  }

  public static String createTweet(String tweet, Twitter twitterInst) throws TwitterException {
    String returnVal = null;
    try {
      Status status = twitterInst.updateStatus(tweet);
      returnVal = status.getText();
    } catch(TwitterException e) {
      e.printStackTrace();
    }
    return returnVal;
  }

  public static JSONArray removePendingEntry(JSONArray pendingResults, int index){
    ArrayList<JSONObject> list = new ArrayList<>();
    for(int i = 0; i < pendingResults.length(); i++){
      if(i == index){
        continue;
      } else {
        list.add(pendingResults.getJSONObject(i));
      }
    }
    return new JSONArray(list);
  }

  public static void removeEntryFromPendingIaByImageId(String imageId, HttpServletRequest request) throws Exception{ //TODO this is ugly and could be made DRYer -Mark F.
    ArrayList<JSONObject> list = new ArrayList<>();
    String iaPendingResultsFile = "/pendingAssetsIA.json";
    JSONArray iaPendingResults = null;
    String rootDir = null;
    try{
      rootDir = request.getSession().getServletContext().getRealPath("/");
    } catch(Exception e){
      try{
        rootDir = "/var/lib/tomcat7/webapps/wildbook/";
        e.printStackTrace();
      } catch(Exception f){
        System.out.println("Can't find rootdir in removeEntryFromPendingIaByImageId in TwitterUtil.java");
        f.printStackTrace();
      }
    }
    String dataDir = ServletUtilities.dataDir("context0", rootDir);
    try {
    	String iaPendingResultsAsString = Util.readFromFile(dataDir + iaPendingResultsFile);
      System.out.println(iaPendingResultsAsString);
    	iaPendingResults = new JSONArray(iaPendingResultsAsString);
    } catch(Exception e){
      System.out.println("Failed to open iaPendingResults from file in TwitterUtil.java removeEntryFromPendingIaByImageId");
    	e.printStackTrace();
    }
    for(int i = 0; i < iaPendingResults.length(); i++){
      JSONObject entry = iaPendingResults.getJSONObject(i);
      System.out.println("entry in removeEntryFromPendingIaByImageId:");
      // System.out.println(entry.toString());
      if(entry.getString("photoId") == imageId){
        continue;
      } else {
        list.add(iaPendingResults.getJSONObject(i));
      }
    }
    JSONArray results = new JSONArray(list);
    try{
      Util.writeToFile(results.toString(), dataDir + iaPendingResultsFile);
    } catch(Exception e){
      System.out.println("Failed to re-write iaPendingResultsFile in removeEntryFromPendingIaByImageId in TwitterUtil.java");
      e.printStackTrace();
    }
  }

  public static Long getSinceIdFromTwitterTimeStampFile(String path) throws Exception{
    Long sinceId = null;
    try{
    	// the timestamp is written with a new line at the end, so we need to strip that out before converting
      String timeStampAsText = Util.readFromFile(path); //dataDir + twitterTimeStampFile
      timeStampAsText = timeStampAsText.replace("\n", "");
      sinceId = Long.parseLong(timeStampAsText, 10);
    } catch(FileNotFoundException e){
    	e.printStackTrace();
    } catch(IOException e){
    	e.printStackTrace();
    } catch(NumberFormatException e){
    	e.printStackTrace();
    }
    if(sinceId != null){
        return sinceId;
    } else{
      throw new Exception ("sinceId in getSinceIdFromTwitterTimeStampFile is null");
    }
  }

  public static String findImageIdInIaPendingLogFromTaskId(String taskId, HttpServletRequest request) throws Exception{
    String returnVal = null;
    String rootDir = null;
    try{
      rootDir = request.getSession().getServletContext().getRealPath("/");
    } catch(Exception e){
      try{
        rootDir = "/var/lib/tomcat7/webapps/wildbook/";
        e.printStackTrace();
      } catch(Exception f){
        System.out.println("Can't find rootdir in findImageIdInIaPendingLogFromTaskId in TwitterUtil.java");
        f.printStackTrace();
      }
    }
    String dataDir = ServletUtilities.dataDir("context0", rootDir);
    String iaPendingResultsFile = "/pendingAssetsIA.json";
    try {
    	String iaPendingResultsAsString = Util.readFromFile(dataDir + iaPendingResultsFile);
    	JSONArray iaPendingResults = new JSONArray(iaPendingResultsAsString);
      for(int i =0; i<iaPendingResults.length(); i++){
        JSONObject entry = iaPendingResults.getJSONObject(i);
        if (entry.getString("taskId").equals(taskId)){
          returnVal = entry.getString("photoId");
          break;
        }
      }
    } catch(Exception e){
    	e.printStackTrace();
    }

    if (returnVal != null){
      return returnVal;
    } else{
      throw new Exception ("imageId in findImageIdInIaPendingLogFromTaskId was null");
    }
  }

  public static String findScreenNameInIaPendingLogFromTaskId(String taskId, HttpServletRequest request) throws Exception{
    String returnVal = null;
    System.out.println("Is request null? " + Boolean.toString(request == null));
    String rootDir = null;
    try{
      rootDir = request.getSession().getServletContext().getRealPath("/");
    } catch(Exception e){
      try{
        rootDir = "/var/lib/tomcat7/webapps/wildbook/";
        e.printStackTrace();
      } catch(Exception f){
        System.out.println("Can't find rootdir in findScreenNameInIaPendingLogFromTaskId in TwitterUtil.java");
        f.printStackTrace();
      }
    }
    String dataDir = ServletUtilities.dataDir("context0", rootDir);
    String iaPendingResultsFile = "/pendingAssetsIA.json";
    try {
    	String iaPendingResultsAsString = Util.readFromFile(dataDir + iaPendingResultsFile);
    	JSONArray iaPendingResults = new JSONArray(iaPendingResultsAsString);
      for(int i =0; i<iaPendingResults.length(); i++){
        JSONObject entry = iaPendingResults.getJSONObject(i);
        if (entry.getString("taskId").equals(taskId)){
          returnVal = entry.getString("tweeterScreenName");
          break;
        }
      }
    } catch(Exception e){
    	e.printStackTrace();
    }
    if (returnVal != null){
      return returnVal;
    } else{
      throw new Exception ("imageId in findImageIdInIaPendingLogFromTaskId was null");
    }
  }
}
