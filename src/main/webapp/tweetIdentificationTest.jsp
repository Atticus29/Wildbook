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
  //Test JSON identification file
  //@TODO test these all on JSON results containing more than one match and less than one match

  Shepherd myShepherd = new Shepherd(ServletUtilities.getContext(request));
  myShepherd.setAction("tweetFind.jsp");

  String identificationJSONStr = Util.readFromFile("/Users/mf/Desktop/identification_result.json");
  JSONObject identificationJSON = new JSONObject(identificationJSONStr);
  try{
    String uuid = TwitterUtil.getQueryUUIDFromJSONIdentificaitonResult(identificationJSON);
    out.println(uuid);
  } catch(Exception e){
    e.printStackTrace();
  }
  try{
    ArrayList<Double> confidences = TwitterUtil.getArrayOfConfidencesFromJSONIdentificaitonResult(identificationJSON);
    out.println(confidences);
    int maxIndex = Util.getIndexOfMax(confidences);
    System.out.println(maxIndex);
  } catch(Exception e){
    e.printStackTrace();
  }

  try{
    ArrayList<Double> test1 = new ArrayList<Double>();
    Double a = 1.0;
    test1.add(a);
    test1.add(2.3);
    test1.add(4.8);
    test1.add(3.1415);
    int maxIndex = Util.getIndexOfMax(test1);
    System.out.println(maxIndex);
    ArrayList<Double> test3 = new ArrayList<Double>();
    test3.add(1.0);
    test3.add(4.8);
    test3.add(4.8);
    test3.add(3.1415);
    maxIndex = Util.getIndexOfMax(test3);
    System.out.println(maxIndex);
  } catch(Exception e){
    e.printStackTrace();
  }

  try{
    ArrayList<Double> test2 = new ArrayList<Double>();
    int maxIndex = Util.getIndexOfMax(test2);
    System.out.println(maxIndex);
  } catch(Exception e){
    e.printStackTrace();
  }

  try{
    ArrayList<String> correspondingUUIDs = TwitterUtil.getArrayOfUUIDsFromJSONIdentificaitonResult(identificationJSON);
    out.println(correspondingUUIDs);
  } catch(Exception e){
    e.printStackTrace();
  }

  try{
    String bestUUID = TwitterUtil.getUUIDOfBestMatchFromIdentificationJSONResults(identificationJSON);
    System.out.println("bestUUID is: " + bestUUID);
  } catch(Exception e){
    e.printStackTrace();
  }

  // try{
  //   String bestUUID = TwitterUtil.getUUIDOfBestMatchFromIdentificationJSONResults(identificationJSON);
  //   String markedIndividualID = getMarkedIndividualIDFromEncounterUUID(bestUUID);
  //   System.out.println("markedIndividualID is " + markedIndividualID);
  //   out.println(markedIndividualID);
  // } catch(Exception e){
  //   e.printStackTrace();
  // }

  //Test with non-result JSON
  String identificationJSONStr = Util.readFromFile("/Users/mf/Desktop/patternMatchResultNoMatches.json");
  JSONObject identificationJSON = new JSONObject(identificationJSONStr);
  try{
    String uuid = TwitterUtil.getQueryUUIDFromJSONIdentificaitonResult(identificationJSON);
    out.println(uuid);
  } catch(Exception e){
    e.printStackTrace();
  }

  try{
    String bestUUID = TwitterUtil.getUUIDOfBestMatchFromIdentificationJSONResults(identificationJSON);
    System.out.println("bestUUID is: " + bestUUID);
  } catch(Exception e){
    e.printStackTrace();
  }

  //Test with two-result JSON
  String identificationJSONStr = Util.readFromFile("/Users/mf/Desktop/patternMatchResultsTwoMatchesFaked.json");
  JSONObject identificationJSON = new JSONObject(identificationJSONStr);
  try{
    String uuid = TwitterUtil.getQueryUUIDFromJSONIdentificaitonResult(identificationJSON);
    out.println(uuid);
  } catch(Exception e){
    e.printStackTrace();
  }

  try{
    String bestUUID = TwitterUtil.getUUIDOfBestMatchFromIdentificationJSONResults(identificationJSON);
    System.out.println("bestUUID is: " + bestUUID);
  } catch(Exception e){
    e.printStackTrace();
  }
  %>

  <%!
  //@TODO test with db intact?
  public String getMarkedIndividualIDFromEncounterUUID(String encounterUUID) throws Exception{
    String returnVal=null;
    Encounter currentEncounter = myShepherd.getEncounter(encounterUUID);
    returnVal = currentEncounter.getIndividualID();
    if (returnVal != null){
      return returnVal;
    } else{
      throw new Exception("markedIndividualID was null in getMarkedIndividualIDFromEncounterUUID method from TwitterUtil.java");
    }
  }
  %>
