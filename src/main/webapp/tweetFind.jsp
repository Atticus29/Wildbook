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
out.println("rootDir is " + rootDir);
String dataDir = ServletUtilities.dataDir("context0", rootDir);
String context = ServletUtilities.getContext(request);
Long sinceId = 890302524275662848L;
String twitterTimeStampFile = "/twitterTimeStamp.txt";
String iaPendingResultsFile = "/pendingAssetsIA.json";
JSONArray iaPendingResults = null;

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
out.println("sinceId is " + sinceId);
QueryResult qr = TwitterUtil.findTweets("@wildmetweetbot", sinceId);
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
// out.println("size of the arrayList of statuses is " + Integer.toString(qr.getTweets().size()));
List<Status> tweetStatuses = qr.getTweets();
for(int i = 0 ; i<tweetStatuses.size(); i++){  //int i = 0 ; i<qr.getTweets().size(); i++
  Status tweet = tweetStatuses.get(i);
  // out.println("i is " + Integer.toString(i));

  if(i == 0){
    mostRecentTweetID = (Long) tweet.getId();
  }
  tweetID = (Long) tweet.getId();
  if(tweetID == null){
    // out.println("tweetID is null. Skipping");
    continue;
  }

  // out.println("newIncomingTweet: " + tweetID);

	JSONObject p = new JSONObject();
	p.put("id", tweet.getId());

  // Attempt to find MediaAsset for tweet, and skip media asset creation if it exists
	MediaAsset ma = tas.find(p, myShepherd);
	if (ma != null) {
		continue;
	}

	// ##################Check for tweet and entities##################
	JSONObject jtweet = TwitterUtil.toJSONObject(tweet);
	if (jtweet == null){
    continue;
  }
  try{
    tweetText = tweet.getText();
    if(tweetText == null){
      continue;
    }
  }catch(Exception e){
    out.println("something went terribly wrong getting tweet text");
    e.printStackTrace();
    continue;
  }


  try{
    ArrayList<String> locations = ParseDateLocation.parseLocation(tweetText, context);
    out.println(locations);
  } catch(Exception e){
    out.println("something went terribly wrong getting locations from the tweet text");
    e.printStackTrace();
    continue;
  }

  try{
    ArrayList<String> dates = ParseDateLocation.parseDateToArrayList(tweetText,context);
    //TODO parseDateToArrayList may need to be updated (and overloaded?)?
  } catch(Exception e){
    out.println("something went terribly wrong getting dates from the tweet text");
    e.printStackTrace();
    continue;
  }

  try{
    tweeterScreenName = tweet.getUser().getScreenName();
    if(tweeterScreenName == null){
      out.println("screen name is null. Skipping");
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
    TwitterUtil.sendCourtesyTweet(tweeterScreenName, "", twitterInst, tweetID+1);
    continue;
  }

  //sendPhotoSpecificCourtesyTweet will detect a photo in your tweet object and tweet the user an acknowledgement about this. If multiple images are sent in the same tweet, this response will only happen once.
  TwitterUtil.sendPhotoSpecificCourtesyTweet(emedia, tweeterScreenName, twitterInst);
  ArrayList<String> photoIds = TwitterUtil.getPhotoIds(emedia, tweeterScreenName, twitterInst);
  ArrayList<String> photoUrls = TwitterUtil.getPhotoUrls(emedia, tweeterScreenName, twitterInst);
  System.out.println("PhotoUrls: ");
  System.out.println(photoUrls);

  tj = TwitterUtil.makeParentTweetMediaAssetAndSave(myShepherd, tas, tweet, tj);

  System.out.println("twitter obj:");
  System.out.println(tj.toString());


  //retrieve ma now that it has been saved
  ma = tas.find(p, myShepherd);

  List<MediaAsset> mas = TwitterAssetStore.entitiesAsMediaAssetsGsonObj(ma, tweetID);

  // dates = addPhotoDatesToPreviouslyParsedDates(dates, mas); //TODO write this/ think about when we want this to happen. We will ultimately add the dates and locations to encounter objects, so perhaps this should only occur downstream of successful detection? Another question is how to tack all of the previously-captured date candidates (or just the best one from ParseDateLocation.parseDate()?) onto each photo while keeping the photo-specific captured date strings attached to only their parent photo...

  iaPendingResults = TwitterUtil.saveEntitiesAsMediaAssetsToSheperdDatabaseAndSendEachToImageAnalysis(mas, tweetID, myShepherd, tj, request, tarr, iaPendingResults, photoIds, photoUrls);
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
  out.println("wrote a new twitterTimeStamp: " + newSinceIdString);
} catch(FileNotFoundException e){
  e.printStackTrace();
}

// Write pending results array to file
try {
	String iaPendingResultsAsString = iaPendingResults.toString();
	Util.writeToFile(iaPendingResultsAsString, dataDir + iaPendingResultsFile);
	out.println("Successfully wrote pending results to file");
} catch (Exception e){
	e.printStackTrace();
}

rtn.put("success", true);
rtn.put("data", tarr);
out.println(rtn);

// Check if JSON data exists
if(iaPendingResults != null){
	// TODO: check if IA has finished processing the pending results
  out.println("iaPendingResults:");
	out.println(iaPendingResults);

  //TODO: check if there are any entries that are older than 24 hours, tweet user, and remove

  JSONObject pendingResult = null;
  String currentJobId = null;
  Boolean curlStatus = null;
  String currentIPAddress = "52.88.31.154"; //@TODO put this somewhere more permanent
  String getJobStatusBaseURL = "http://" + currentIPAddress + "/IBEISIAGetJobStatus.jsp?jobid=";
  for(int i = 0; i<iaPendingResults.length(); i++){
    pendingResult = iaPendingResults.getJSONObject(i);
    currentJobId = IBEISIA.findJobIDFromTaskID(pendingResult.getString("taskId"), context);

    // try{
    //   JSONObject status = IBEISIA.getJobStatus(currentJobId, context);
    // } catch(Exception e){
    //   e.printStackTrace();
    // }
    //@TODO change the curl call below to IBEISIA.getJobStatus(String jobid, String context), then, if status is error tweet about it and drop from iaPendingResults. If ok, use IBEISIA.getJobResult(String jobid, String context)
    //these can possibly throw exceptions (like IA has gone away) so best to catch those too.  i guess that was case 0 on the whiteboard

    //@TODO add check for results and confidences having the same number of elements

    String[] cmd = {"curl", getJobStatusBaseURL + currentJobId};
    Process p = Runtime.getRuntime().exec(cmd);

    DateTime resultCreation = new DateTime(pendingResult.getString("creationDate"));
    DateTime timeNow = new DateTime();
    Interval interval = new Interval(resultCreation, timeNow);
    out.println("Interval: " + interval);
    out.println("Interval duration: " + interval.toDuration().plus(5000000).getStandardHours()); //TODO what does the plus(5000000) do? -Mark F.
    if(interval.toDuration().getStandardHours() >= 24){
    	out.println("Object " + pendingResult.getString("taskId") + " has timed out in IA. Notifying sender.");
    	TwitterUtil.sendTimeoutTweet(pendingResult.getString("tweeterScreenName"), twitterInst, pendingResult.getString("photoUrl"), request);
      //Remove
    }
  }

} else {
	out.println("No pending results");
	iaPendingResults = new JSONArray();
}
// END PENDING IA RETRIEVAL


myShepherd.closeDBTransaction();

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
