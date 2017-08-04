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
java.util.concurrent.ThreadLocalRandom"

%>

<%

String testDataString = Util.readFromFile("/usr/local/apache-tomcat-7.0.79/webapps/wildbook_data_dir/pendingResultsIdentification.json");

out.println(testDataString);

String context = ServletUtilities.getContext(request);
out.println("context is: " + context);

// String taskId = findTaskIDFromJobID("jobid-0001", context);
// out.println("taskID is " + taskID);

// processCallbackIdentify(String taskID, ArrayList<IdentityServiceLog> logs, JSONObject resp, HttpServletRequest request);
%>
