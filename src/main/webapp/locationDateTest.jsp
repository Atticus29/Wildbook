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
  org.ecocean.identity.IBEISIA,
  twitter4j.QueryResult,
  twitter4j.Status,
  twitter4j.*,
  org.ecocean.servlet.ServletUtilities,
  org.ecocean.media.*,
  org.ecocean.ParseDateLocation.*,
  java.util.concurrent.ThreadLocalRandom,
  org.joda.time.DateTime,
  org.joda.time.Interval"

  %>

  <%
  String monthYearString = "Saw a whale April, 2017.";
  String context = ServletUtilities.getContext(request);
  String yearString = "Saw a whale in 2015.";
  String dateTest = "Saw a whale on monday June 13, 2017";
  String dateTest2 = "Saw a whale on 6/13/2017";
  String testTweetText = "Saw this cool humpback whale in the galapagos, Ecuador!";
  String testTweetTextNonEnglish = "Ayer vi una ballena increible en los galapagos en mexico. Sé que no están en mexico. No sea camote.";
  String textTweetGpsText = "saw a whale at 45.5938,-122.737 in ningaloo. #bestvacationever";
  String testTweetMultipleLocations = "whale! In Phuket, Thailand!";
  String testTweetNLPLocation = "land whale! In Nashville, tennessee!";
  String futureString = "Saw a whale on July 2, 2017. I'm going to see one tomorrow too! Tomorrow will be a better day for whale-watching.";
  String pastString = "Saw a whale on July 2, 2017. I saw one yesterday, too! Yesterday's was cooler. Yesterday it was warm outside.";
  String futureFirstString = "I'm going to see whales tomorrow! I saw one on July 3 2017 as well.";
  String pastFirstString = "I saw a whale yesterday, and last week! I saw one on July 4 2017 as well.";
  String yesterdayString = "Saw a whale yesterday.";
  
  ArrayList<String> results = null;
  results = ParseDateLocation.parseLocation(monthYearString, context);
  out.println("results from " + monthYearString + " is " + results);

  results = ParseDateLocation.parseLocation(yearString, context);
  out.println("results from " + yearString + " is " + results);

  results = ParseDateLocation.parseLocation(dateTest, context);
  out.println("results from " + dateTest + " is " + results);

  results = ParseDateLocation.parseLocation(dateTest2, context);
  out.println("results from " + dateTest2 + " is " + results);

  results = ParseDateLocation.parseLocation(testTweetText, context);
  out.println("results from " + testTweetText + " is " + results);

  results = ParseDateLocation.parseLocation(testTweetTextNonEnglish, context);
  out.println("results from " + testTweetTextNonEnglish + " is " + results);

  results = ParseDateLocation.parseLocation(textTweetGpsText, context);
  out.println("results from " + textTweetGpsText + " is " + results);

  results = ParseDateLocation.parseLocation(testTweetMultipleLocations, context);
  out.println("results from " + testTweetMultipleLocations + " is " + results);

  results = ParseDateLocation.parseLocation(testTweetNLPLocation, context);
  out.println("results from " + testTweetNLPLocation + " is " + results);

  out.println("Don't forget to conduct additional tests on an emulator with gps coordinates from somewhere in asia.");
  %>
