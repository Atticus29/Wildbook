<%@ page contentType="text/plain; charset=utf-8" language="java"

import="org.ecocean.*,
java.util.ArrayList,
java.io.FileNotFoundException,
java.io.IOException,
java.util.Map,
java.util.List,
java.io.BufferedReader,
java.io.IOException,
java.io.InputStream,
java.io.InputStreamReader,
java.io.File,
java.util.Date,
org.json.JSONObject,
org.json.JSONArray,
org.joda.time.DateTime,
org.joda.time.Interval,
org.ecocean.identity.IBEISIA,
twitter4j.QueryResult,
twitter4j.Status,
twitter4j.*,
org.ecocean.servlet.ServletUtilities,
org.ecocean.media.*,
org.ecocean.ParseDateLocation.*,
java.util.concurrent.ThreadLocalRandom,
java.io.*
              "
%>

<%
String baseUrl = null;
String tweeterScreenName = null;
Long tweetID = null;
String tweetText = null;
Long mostRecentTweetID = null;
String rootDir = request.getSession().getServletContext().getRealPath("/");
String dataDir = ServletUtilities.dataDir("context0", rootDir);
String context = ServletUtilities.getContext(request);
Long sinceId = 951926801697095680L;
String twitterTimeStampFile = "/twitterTimeStamp.txt";
String iaPendingResultsFile = "/pendingAssetsIA.json";
String tweetQueueFile = "/tweetQueue.txt";
String pathToQueueFile = dataDir + tweetQueueFile;
JSONArray iaPendingResults = null;
QueryResult qr = null;

out.println("tweetFind.jsp currently being executed");

try {
    baseUrl = CommonConfiguration.getServerURL(request, request.getContextPath());
} catch (java.net.URISyntaxException ex) {}

JSONObject rtn = new JSONObject("{\"success\": false}");

Twitter twitterInst = TwitterUtil.init(request);

Shepherd myShepherd = new Shepherd(ServletUtilities.getContext(request));
myShepherd.setAction("tweetFind.jsp");

// Find or create TwitterAssetStore and make it persistent with myShepherd
TwitterAssetStore tas = TwitterAssetStore.find(myShepherd);
if(tas == null){
	myShepherd.beginDBTransaction();
	tas = new TwitterAssetStore("twitterAssetStore");
	myShepherd.getPM().makePersistent(tas);
	myShepherd.commitDBTransaction();
}

myShepherd.beginDBTransaction();
// Retrieve timestamp for the last twitter check
try{
	// the timestamp is written with a new line at the end, so we need to strip that out before converting
  String timeStampAsText = Util.readFromFile(dataDir + twitterTimeStampFile);
  timeStampAsText = timeStampAsText.replace("\n", "");
  sinceId = Long.parseLong(timeStampAsText, 10);
} catch(FileNotFoundException e){
	e.printStackTrace();
} catch(IOException e){
	e.printStackTrace();
} catch(NumberFormatException e){
	e.printStackTrace();
}
rtn.put("sinceId", sinceId);



try{
  qr = TwitterUtil.findTweets("@FlukeBot", sinceId);
} catch(Exception e){
  out.println("something went wrong running findTweets");
  e.printStackTrace();
}

JSONArray tarr = new JSONArray();
// out.println(qr.getTweets().size());

// Retrieve current results that are being processed by IA
try {
	String iaPendingResultsAsString = Util.readFromFile(dataDir + iaPendingResultsFile);
	iaPendingResults = new JSONArray(iaPendingResultsAsString);
} catch(Exception e){
	e.printStackTrace();
}

//##################Begin loop through the each of the tweets since the last timestamp##################
out.println("is qr null?: " + Boolean.toString(qr == null));
out.println("size of the arrayList of statuses is " + Integer.toString(qr.getTweets().size()));
List<Status> tweetStatuses = qr.getTweets();
for(int i = 0 ; i<tweetStatuses.size(); i++){  //int i = 0 ; i<qr.getTweets().size(); i++
  //@TODO check that the 0th tweet is the most recent? Or oldest of the current batch?
  Status tweet = tweetStatuses.get(i);
  out.println("total number of tweets captured is " + Integer.toString(tweetStatuses.size()));
  out.println(tweet.getText());


  if(i == 0){
    mostRecentTweetID = (Long) tweet.getId();
    out.println("tweet with index 0 has tweetId: " + Long.toString(mostRecentTweetID));
  }
  tweetID = (Long) tweet.getId();
  out.println("current tweet with index " + Integer.toString(i) + " has id: " + Long.toString(tweetID));
  Date tweetDate = tweet.getCreatedAt();
  out.println("Date is: " + tweetDate.toString());
  if(tweetID == null){
    continue;
  }


	JSONObject p = new JSONObject();
	p.put("id", tweet.getId());

  // Attempt to find MediaAsset for tweet, and skip media asset creation if it exists
	MediaAsset ma = tas.find(p, myShepherd);
	if (ma != null) {
    out.println("Media asset associated with tweet " + tweet.getId() + " is already known");
		continue;
	}

	// ##################Check for tweet and entities##################
	JSONObject jtweet = TwitterUtil.toJSONObject(tweet);
	if (jtweet == null){
    out.println("The tweet object for tweet + " + tweet.getId() + " is null");
    continue;
  }
  try{
    tweetText = tweet.getText();
    out.println("Tweet text is " + tweet.getText());
    if(tweetText == null){
      continue;
    }
  }catch(Exception e){
    e.printStackTrace();
    continue;
  }

  try{
    //@TODO add this back in
    // ArrayList<String> locations = ParseDateLocation.parseLocation(tweetText, context);
    // out.println(locations);
  } catch(Exception e){
    e.printStackTrace();
    continue;
  }

  try{
    ArrayList<String> dates = ParseDateLocation.parseDateToArrayList(tweetText,context);
    //TODO parseDateToArrayList may need to be updated (and overloaded?)?
  } catch(Exception e){
    e.printStackTrace();
    continue;
  }

  try{
    tweeterScreenName = tweet.getUser().getScreenName();
    if(tweeterScreenName == null){
      continue;
    }
  } catch(Exception e){
    e.printStackTrace();
    continue;
  }

	JSONObject tj = new JSONObject();  //just for output purposes
	tj.put("tweet", TwitterUtil.toJSONObject(tweet));

	JSONArray emedia = null;
	emedia = jtweet.optJSONArray("extendedMediaEntities");
  if((emedia == null) || (emedia.length() < 1)){
    out.println("There were no extendedMediaEntities in tweet reading " + tweet.getText());
    TwitterUtil.addCourtesyTweetToQueue(tweeterScreenName, "", twitterInst, null, pathToQueueFile);
    continue;
  }

  //sendPhotoSpecificCourtesyTweet will detect a photo in your tweet object and tweet the user an acknowledgement about this. If multiple images are sent in the same tweet, this response will only happen once. @TODO make this send photo URLs instead of IDs
  TwitterUtil.addPhotoSpecificCourtesyTweetToQueue(emedia, tweeterScreenName, twitterInst, pathToQueueFile);

  ArrayList<String> photoIds = TwitterUtil.getPhotoIds(emedia, tweeterScreenName, twitterInst);
  ArrayList<String> photoUrls = TwitterUtil.getPhotoUrls(emedia, tweeterScreenName, twitterInst);
  // System.out.println(photoUrls);


  //LEFT OFF HERE
  tj = TwitterUtil.makeParentTweetMediaAssetAndSave(myShepherd, tas, tweet, tj);

  // System.out.println("twitter obj:");
  // System.out.println(tj.toString());


  //retrieve ma now that it has been saved
  ma = tas.find(p, myShepherd);
  if (ma == null){
    out.println("Something went wrong ma has not been saved or retrieved correctly");
  }

  List<MediaAsset> mas = TwitterAssetStore.entitiesAsMediaAssetsGsonObj(ma, tweetID);
  // out.println(mas); //working as expected here

  // dates = addPhotoDatesToPreviouslyParsedDates(dates, mas); //TODO write this/ think about when we want this to happen. We will ultimately add the dates and locations to encounter objects, so perhaps this should only occur downstream of successful detection? Another question is how to tack all of the previously-captured date candidates (or just the best one from ParseDateLocation.parseDate()?) onto each photo while keeping the photo-specific captured date strings attached to only their parent photo...
  out.println("About to call saveEntitiesAsMediaAssetsToSheperdDatabaseAndSendEachToImageAnalysis");
  iaPendingResults = TwitterUtil.saveEntitiesAsMediaAssetsToSheperdDatabaseAndSendEachToImageAnalysis(mas, tweetID, myShepherd, tj, request, tarr, iaPendingResults, photoIds, photoUrls);
  // out.println(iaPendingResults);
	tarr.put(tj);
}
//End looping through the tweets

// Write new timestamp to track last twitter pull
Long newSinceIdString;
if(mostRecentTweetID == null){
	newSinceIdString = sinceId;
} else {
	newSinceIdString = mostRecentTweetID;
}
try{
  Util.writeToFile(Long.toString(newSinceIdString), dataDir + twitterTimeStampFile);

} catch(FileNotFoundException e){
  e.printStackTrace();
}

// Write pending results array to file
try {
	String iaPendingResultsAsString = iaPendingResults.toString();
	Util.writeToFile(iaPendingResultsAsString, dataDir + iaPendingResultsFile);

} catch (Exception e){
	e.printStackTrace();
}

rtn.put("success", true);
rtn.put("data", tarr);


// Check if JSON data exists
if(iaPendingResults != null){
	// TODO: check if IA has finished processing the pending results



  //TODO: check if there are any entries that are older than 24 hours, tweet user, and remove

  JSONObject pendingResult = null;
  String currentJobId = null;
  String currentImageURL = null;
  String currentTaskId = null;
  Boolean curlStatus = null;
  String currentIPAddress = "54.68.97.153"; //@TODO put this somewhere more permanent
  String getJobStatusBaseURL = "http://" + currentIPAddress + "/IBEISIAGetJobStatus.jsp?jobid=";
  for(int i = 0; i<iaPendingResults.length(); i++){
    pendingResult = iaPendingResults.getJSONObject(i);
    currentTaskId = pendingResult.getString("taskId");
    System.out.println("current taskId is: " + currentTaskId);
    currentJobId = IBEISIA.findJobIDFromTaskID(currentTaskId, context);
    // currentJobId = "jobid-0797";
    System.out.println("current JobId is: " + currentJobId);
    currentImageURL = TwitterUtil.findImageUrlInIaPendingLogFromTaskId(pendingResult.getString("taskId"),request);

    try{
      String status = IBEISIA.getJobStatus(currentJobId, context).getJSONObject("response").getString("jobstatus");
      System.out.println("Job status ==>" + status);
      if (status.equals("completed")){
        //@TODO takea look at IBEISIAGetJobStatus parsing to see whether everything is useable
        JSONObject jobResult = IBEISIA.getJobResult(currentJobId, context);
        JSONObject rlog = new JSONObject();
    		rlog.put("jobID", currentJobId);
    		rlog.put("_action", "getJobResult");
    		rlog.put("_response", jobResult);
    		IBEISIA.log(currentTaskId, currentJobId, rlog, context);
    		// all.put("jobResult", rlog);
    		JSONObject proc = IBEISIA.processCallback(currentTaskId, rlog, request);
        IBEISIA.processCallback(currentTaskId, jobResult, request);

        //@TODO move code block below into IBEISIA.java?? Or move some of that stuff here? It's weird that half of it is there and half is here
        //@TODO find out where the jobId and taskId for an identification are given out, and make sure that's added to pendingResults
        // if(TwitterUtil.isSuccessfulDetection(jobResult)){
        //   //Do nothing. Wait for it to return an identification result.
        // } else {
        //   //@TODO we can rule out successful detection, unsuccessful anything else will fail below. Can we assume that this will only run if there is successful identification?
        //   String bestUUIDMatch = TwitterUtil.getUUIDOfBestMatchFromIdentificationJSONResults(jobResult);
        //   if(bestUUIDMatch.equals("")){
        //     TwitterUtil.addDetectionAndIdentificationTweetToQueue(tweeterScreenName, currentImageURL, twitterInst, null, true, false, null, request);
        //     //@TODO add an encounter for a novel animal and flag for review by a human
        //   }
        //   String markedIndividualID = getMarkedIndividualIDFromEncounterUUID(bestUUIDMatch,request);
        //   // @TODO mature ^ and move to TwitterUtil.java
        //   String info = "http://" + currentIPAddress + "/individuals.jsp/?number=" + markedIndividualID;
        //   TwitterUtil.addDetectionAndIdentificationTweetToQueue(tweeterScreenName, currentImageURL, twitterInst, markedIndividualID , true, true, info, request);
        //   //@TODO add an encounter to the markedIndividualID
        // }
      } else if (status.equals("unknown")){
        //Ignore and let it try until 72 hours pass?
      }
    } catch(Exception e){
      //@TODO this is the case where IBEIS is not responding. Do nothing = keep it on the list for next time (unless it's old, which is handled below)
      e.printStackTrace();
    }

    //@TODO change the curl call below to IBEISIA.getJobStatus(String jobid, String context), then, if status is error tweet about it and drop from iaPendingResults. If ok, use IBEISIA.getJobResult(String jobid, String context)
    //these can possibly throw exceptions (like IA has gone away) so best to catch those too.  i guess that was case 0 on the whiteboard

    //@TODO add check for results and confidences having the same number of elements

    // String[] cmd = {"curl", getJobStatusBaseURL + currentJobId};
    // Process p = Runtime.getRuntime().exec(cmd);

    DateTime resultCreation = new DateTime(pendingResult.getString("creationDate"));
    DateTime timeNow = new DateTime();
    Interval interval = new Interval(resultCreation, timeNow);


    if(interval.toDuration().getStandardHours() >= 72){

    	TwitterUtil.addTimeoutTweetToQueue(pendingResult.getString("tweeterScreenName"), twitterInst, pendingResult.getString("photoUrl"), request, pathToQueueFile);
      //Note that sendTimeoutTweet calls removeEntryFromPendingIaByImageUrl.
    }
  }

} else {

	iaPendingResults = new JSONArray();
}
// END PENDING IA RETRIEVAL


System.out.println("ABOUT TO COMMIT");
myShepherd.commitDBTransaction();

//@TODO change this number to that from the limit call to the API
//@ATTN this is currently running 1 tweet per minute (assuming the cron job is per minute). It's a precaution if you can't ever see the API limit status call decrementing and use that as your count of how many tweets are remaining
TwitterUtil.sendThisManyTweetsFromTheQueue(1, dataDir + tweetQueueFile, twitterInst);
Map<String,RateLimitStatus> rateLimitStatusMap = twitterInst.getRateLimitStatus();
System.out.println(rateLimitStatusMap);

/*
String ids[] = null;
String forminput = request.getParameter("ids");
if ((forminput != null) && !forminput.equals("")) {
	ids = forminput.split("[^0-9]");
} else {
	ids = request.getParameterValues("id");
}
if ((ids == null) || (ids.length < 1)) {
	out.println("<h1>pass <b>?id=A&id=B...</b> with tweet ids or <b>enter below</b></h1><form method=\"post\"><textarea style=\"width: 25%; height: 30%;\" name=\"ids\" placeholder=\"twitter ids\"></textarea><br /><input type=\"submit\" value=\"create\" /></form>");
	return;
}


ArrayList<MediaAsset> detectMAs = new ArrayList<MediaAsset>();

for (int i = 0 ; i < ids.length ; i++) {
	out.println("<hr /><h1>" + ids[i] + "</h1>");
	MediaAsset ma = tas.find(p, myShepherd);
	long idLong = -1;
        try {
        	idLong = Long.parseLong(ids[i]);
        } catch (NumberFormatException ex) {
	}
	if (idLong < 0) {
		out.println("<b>could not convert to long:</b> " + ids[i]);
	} else if (ma != null) {
		out.println("<b>tweet already stored:</b> " + ma);
	} else {
		twitter4j.Status tweet = TwitterUtil.getTweet(idLong);
		JSONObject jtweet = TwitterUtil.toJSONObject(tweet);
		if ((tweet == null) || (jtweet == null)) {  //or other weirdness?
			out.println("could not getTweet or parse json thereof");
		} else {
			JSONObject ents = jtweet.optJSONObject("entities");
			JSONArray emedia = null;
			if (ents != null) emedia = ents.optJSONArray("media");
			if ((ents == null) || (emedia == null) || (emedia.length() < 1)) {
				out.println("could not find .entities.media on tweet data <pre>" + jtweet.toString() + "</pre>");
			} else {
				out.println("<b>media found: " + emedia.length() + "</b>");
				//now we do the real thing!
				ma = tas.create(ids[i]);
				ma.addLabel("_original");
				MediaAssetMetadata md = ma.updateMetadata();
				out.println("<p>" + ma + "</p>");
				MediaAssetFactory.save(ma, myShepherd);
				System.out.println("created " + ma);
				out.println("<p><b>Tweet asset:</b> <a title=\"" + ma + "\" href=\"obrowse.jsp?type=MediaAsset&id=" + ma.getId() + "\">" + ma.getId() + "</a>; entities:<ul>");
out.println("<xmp>" + ma.getMetadata().getDataAsString() + "</xmp>");
				List<MediaAsset> mas = TwitterAssetStore.entitiesAsMediaAssets(ma);
				if ((mas == null) || (mas.size() < 1)) {  // "should never happen"
					out.println("<li>no media entities</li>");
				} else {
					for (MediaAsset ent : mas) {
                    				ent.setDetectionStatus(IBEISIA.STATUS_PROCESSING);
						MediaAssetFactory.save(ent, myShepherd);
						detectMAs.add(ent);
						out.println("<li><a title=\"" + ent + "\" href=\"obrowse.jsp?type=MediaAsset&id=" + ent.getId() + "\">" + ent.getId() + "</a></li>");
					}
				}
				out.println("</ul></p>");
			}
		}
	}
}

if (detectMAs.size() < 1) {
	return;
}

boolean success = true;
String taskId = Util.generateUUID();
JSONObject res = new JSONObject();
res.put("taskId", taskId);
try {
    res.put("sendMediaAssets", IBEISIA.sendMediaAssets(detectMAs));
    JSONObject sent = IBEISIA.sendDetect(detectMAs, baseUrl);
    res.put("sendDetect", sent);
    String jobId = null;
    if ((sent.optJSONObject("status") != null) && sent.getJSONObject("status").optBoolean("success", false)) jobId = sent.optString("response", null);
    res.put("jobId", jobId);
    //IBEISIA.log(taskId, validIds.toArray(new String[validIds.size()]), jobId, new JSONObject("{\"_action\": \"initDetect\"}"), context);
} catch (Exception ex) {
    success = false;
    throw new IOException(ex.toString());
}

if (!success) {
    for (MediaAsset ma : mas) {
        ma.setDetectionStatus(IBEISIA.STATUS_ERROR);
    }
}
*/


%>

<%!
  //@TODO test with db intact?
  public String getMarkedIndividualIDFromEncounterUUID(String encounterUUID, HttpServletRequest request) throws Exception{
    String returnVal=null;
    Shepherd newShepherd = new Shepherd(ServletUtilities.getContext(request));
    Encounter currentEncounter = newShepherd.getEncounter(encounterUUID);
    returnVal = currentEncounter.getIndividualID();
    if (returnVal != null){
      return returnVal;
    } else{
      throw new Exception("markedIndividualID was null in getMarkedIndividualIDFromEncounterUUID method from TwitterUtil.java");
    }
  }
  %>
