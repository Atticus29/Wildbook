<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%@ page contentType="text/html; charset=utf-8" language="java" import="java.util.ArrayList,javax.jdo.*,org.ecocean.*,java.util.GregorianCalendar, java.util.Properties, java.util.Iterator"%>

<html xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml" >

<head>
<title><%=CommonConfiguration.getHTMLTitle() %></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="Description"
	content="<%=CommonConfiguration.getHTMLDescription() %>" />
<meta name="Keywords"
	content="<%=CommonConfiguration.getHTMLKeywords() %>" />
<meta name="Author" content="<%=CommonConfiguration.getHTMLAuthor() %>" />
<link href="<%=CommonConfiguration.getCSSURLLocation() %>"
	rel="stylesheet" type="text/css" />
<link rel="shortcut icon"
	href="<%=CommonConfiguration.getHTMLShortcutIcon() %>" />
	
<!-- Sliding div content: STEP1 Place inside the head section -->
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js"></script>
<script type="text/javascript" src="../javascript/animatedcollapse.js"></script>	 
<!-- /STEP1 Place inside the head section -->
<!-- STEP2 Place inside the head section -->
 <script type="text/javascript">
	animatedcollapse.addDiv('location', 'fade=1')
	animatedcollapse.addDiv('map', 'fade=1')
	animatedcollapse.addDiv('date', 'fade=1')
	animatedcollapse.addDiv('observation', 'fade=1')
	animatedcollapse.addDiv('identity', 'fade=1')
	animatedcollapse.addDiv('metadata', 'fade=1')
	animatedcollapse.addDiv('export', 'fade=1')

	animatedcollapse.ontoggle=function($, divobj, state){ //fires each time a DIV is expanded/contracted
	    //$: Access to jQuery
	    //divobj: DOM reference to DIV being expanded/ collapsed. Use "divobj.id" to get its ID
	    //state: "block" or "none", depending on state
	}
	animatedcollapse.init()
</script>
<!-- /STEP2 Place inside the head section -->	
	

	
</head>

<style type="text/css">v\:* {behavior:url(#default#VML);}</style>

<script>
function resetMap()
{
	var ne_lat_element = document.getElementById('ne_lat');
	var ne_long_element = document.getElementById('ne_long');
	var sw_lat_element = document.getElementById('sw_lat');
	var sw_long_element = document.getElementById('sw_long');

	ne_lat_element.value = "";
	ne_long_element.value = "";
	sw_lat_element.value = "";
	sw_long_element.value = "";
            		
}
</script>

<body onload="initialize();resetMap()" onunload="GUnload();resetMap()">

<%
GregorianCalendar cal=new GregorianCalendar();
int nowYear=cal.get(1);
int firstYear = 1980;

Shepherd myShepherd=new Shepherd();
Extent allKeywords=myShepherd.getPM().getExtent(Keyword.class,true);		
Query kwQuery=myShepherd.getPM().newQuery(allKeywords);
myShepherd.beginDBTransaction();
try{
	firstYear = myShepherd.getEarliestSightingYear();
	nowYear = myShepherd.getLastSightingYear();
}
catch(Exception e){
	e.printStackTrace();
}

//let's load encounterSearch.properties
String langCode="en";
if(session.getAttribute("langCode")!=null){langCode=(String)session.getAttribute("langCode");}

Properties encprops=new Properties();
encprops.load(getClass().getResourceAsStream("/bundles/"+langCode+"/encounterSearch.properties"));
				

%>


<div id="wrapper">
<div id="page"><jsp:include page="../header.jsp" flush="true">
	<jsp:param name="isResearcher"
		value="<%=request.isUserInRole("researcher")%>" />
	<jsp:param name="isManager"
		value="<%=request.isUserInRole("manager")%>" />
	<jsp:param name="isReviewer"
		value="<%=request.isUserInRole("reviewer")%>" />
	<jsp:param name="isAdmin" value="<%=request.isUserInRole("admin")%>" />
</jsp:include>
<div id="main">
<table width="810">
	<tr>
		<td>
		<p>
		<h1 class="intro"><%=encprops.getProperty("title")%> 
			<a href="<%=CommonConfiguration.getWikiLocation()%>searching#encounter_search" target="_blank">
				<img src="../images/information_icon_svg.gif" alt="Help" border="0" align="absmiddle" />
			</a>
		</h1>
		</p>
		<p><em><%=encprops.getProperty("instructions")%></em></p>
		<form action="thumbnailSearchResults.jsp" method="get" name="search" id="search">
		<table>
			
<tr><td width="810px">
			
			<h4 class="intro" style="background-color: #cccccc; padding:3px; border: 1px solid #000066; "><a href="javascript:animatedcollapse.toggle('map')" style="text-decoration:none"><img src="../images/Black_Arrow_down.png" width="14" height="14" border="0" align="absmiddle" /></a> <a href="javascript:animatedcollapse.toggle('map')" style="text-decoration:none"><font color="#000000">Location filter (map)</font></a></h4>

			<script
				src="http://maps.google.com/maps?file=api&amp;v=2&amp;key=<%=CommonConfiguration.getGoogleMapsKey() %>"
				type="text/javascript"></script> <script type="text/javascript">
    			function initialize() {
      				if (GBrowserIsCompatible()) {
        				var map = new GMap2(document.getElementById("map_canvas"));
       					 map.setMapType(G_HYBRID_MAP);
						map.addControl(new GSmallMapControl());
						map.setCenter(new GLatLng(0, 180), 1);
		
        				map.addControl(new GMapTypeControl());
						map.setMapType(G_HYBRID_MAP);
        				var otherOpts = { 
                			buttonStartingStyle: {background: '#FFF', paddingTop: '4px', paddingLeft: '4px', border:'1px solid black'},
                			buttonHTML: '<img title="Drag Zoom In" src="../javascript/zoomin.gif">',
               				buttonStyle: {width:'25px', height:'23px'},
                			buttonZoomingHTML: 'Drag a region on the map (click here to reset)',
                			buttonZoomingStyle: {background:'yellow',width:'75px', height:'100%'},
                			backButtonHTML: '<img title="Zoom Back Out" src="../javascript/zoomout.gif">',  
                			backButtonStyle: {display:'none',marginTop:'5px',width:'25px', height:'23px'},
                			backButtonEnabled: true, 
                			overlayRemoveTime: 1500} 
        				var callbacks = {
               				dragend: function(nw,ne,se,sw,nwpx,nepx,sepx,swpx){
            				var ne_lat_element = document.getElementById('ne_lat');
            				var ne_long_element = document.getElementById('ne_long');
            				var sw_lat_element = document.getElementById('sw_lat');
            				var sw_long_element = document.getElementById('sw_long');

            				ne_lat_element.value = ne.y;
            				ne_long_element.value = ne.x;
            				sw_lat_element.value = sw.y;
            				sw_long_element.value = sw.x;
            			}
        			};
              
       				 map.addControl(new DragZoomControl({},otherOpts, callbacks));
     			 }
    		}
    </script>
    <script src="../javascript/dragzoom.js" type="text/javascript"></script>
<div id="map">
<p>Use the arrow and +/- keys to navigate to a portion of the globe of interest, then click and drag the <img src="../javascript/zoomin.gif" align="absmiddle"/> icon to select the specific search boundaries. You can also use the text boxes below the map to specify exact boundaries.</p>
	
<div id="map_canvas" style="width: 510px; height: 340px; "></div>
<p>Northeast corner latitude: <input type="text" id="ne_lat" name="ne_lat"></input> longitude: <input type="text" id="ne_long" name="ne_long"></input><br /><br />
Southwest corner latitude: <input type="text" id="sw_lat" name="sw_lat"></input> longitude: <input type="text" id="sw_long" name="sw_long"></input></p>
			</div>

			</td>
			</tr>
			<tr>
			<td>
			<h4 class="intro" style="background-color: #cccccc; padding:3px; border: 1px solid #000066; "><a href="javascript:animatedcollapse.toggle('location')" style="text-decoration:none"><img src="../images/Black_Arrow_down.png" width="14" height="14" border="0" align="absmiddle" /> <font color="#000000">Location filters (text)</font></a></h4>
			<div id="location" style="display:none; ">
				<p>Use the fields below to filter the search by a location string (e.g. "Mexico") or to a specific, pre-defined location identifier.</p>
					<p><strong><%=encprops.getProperty("locationNameContains")%>:</strong> 
					<input name="locationField" type="text" size="60"> <br> <em><%=encprops.getProperty("leaveBlank")%></em>
				</p>
				<p><strong><%=encprops.getProperty("locationID")%>:</strong> <span class="para"><a href="<%=CommonConfiguration.getWikiLocation()%>locationID"
					target="_blank"><img src="../images/information_icon_svg.gif"
					alt="Help" border="0" align="absmiddle" /></a></span> <br> 
					(<em><%=encprops.getProperty("locationIDExample")%></em>)</p>

				<%
				ArrayList<String> locIDs = myShepherd.getAllLocationIDs();
				int totalLocIDs=locIDs.size();

				
				if(totalLocIDs>0){
				%>
				
				<select multiple size="<%=(totalLocIDs+1) %>" name="locationCodeField" id="locationCodeField">
					<option value="None"></option>
				<% 
			  	for(int n=0;n<totalLocIDs;n++) {
					String word=locIDs.get(n);
					if(!word.equals("")){
						
						String expandedWord=word;
						
						//let's insert the correct name options
						if(word.equals("Asia-OG")){expandedWord=word+" (Asia-Ogasawara)";}
						else if(word.equals("Asia-OK")){expandedWord=word+" (Asia-Okinawa)";}
						else if(word.equals("Asia-PHI")){expandedWord=word+" (Asia-Philippines)";}
						else if(word.equals("Bering")){expandedWord=word+" (Bering Sea)";}
						else if(word.equals("CA-OR")){expandedWord=word+" (California-Oregon)";}
						else if(word.equals("Cent Am")){expandedWord=word+"(Central America)";}
						else if(word.equals("Hawaii")){expandedWord=word+" (Hawaiian Islands)";}
						else if(word.equals("E Aleut.")){expandedWord=word+" (Eastern Aleutian Islands, Pacific Side)";}
						else if(word.equals("MX-AR")){expandedWord=word+" (Mexico- Archipielago Revillagigedo)";}
						else if(word.equals("MX-BC")){expandedWord=word+" (Mexico- Baja Calfiornia)";}
						else if(word.equals("MX-ML")){expandedWord=word+" (Mexico- Mainland)";}
						else if(word.equals("NBC")){expandedWord=word+" (Northern British Columbia)";}
						else if(word.equals("NGOA")){expandedWord=word+" (Northern Gulf of Alaska)";}
						else if(word.equals("NWA-SBC")){expandedWord=word+" (Northern Washington- Southern British Columbia)";}
						else if(word.equals("Russia-CI")){expandedWord=word+" (Russia- Commander Islands)";}
						else if(word.equals("Russia-GA")){expandedWord=word+" (Russia- Gulf of Anadyr)";}
						else if(word.equals("Russia-K")){expandedWord=word+" (Russia- Kamchatka Peninsula)";}
						else if(word.equals("SEAK")){expandedWord=word+" (Southeast Alaska)";}
						else if(word.equals("W Aleut.")){expandedWord=word+" (Western Aleutian Islands, Pacific Side)";}
						else if(word.equals("WGOA")){expandedWord=word+" (Western Gulf of Alaska, Kodiak Island)";}
						
				%>
					<option value="<%=word%>"><%=expandedWord%></option>
				<%}
					}
				%>
				</select>
				<%
				}
				else{
					%>
					<p><em><%=encprops.getProperty("noLocationIDs")%></em></p>
					<%
				}
				%>
				</div>
				</td>

			</tr>
			
			
			<tr>
				<td>
					<h4 class="intro" style="background-color: #cccccc; padding:3px; border: 1px solid #000066; "><a href="javascript:animatedcollapse.toggle('date')" style="text-decoration:none"><img src="../images/Black_Arrow_down.png" width="14" height="14" border="0" align="absmiddle" /> <font color="#000000">Date filters</font></a></h4>
				</td>
			</tr>
			
			
			<tr>
				<td>
				<div id="date" style="display:none;">
				<p>Use the fields below to limit the timeframe of your search.</p>
				<strong><%=encprops.getProperty("sightingDates")%>:</strong>< br/>
				<table width="720">
					<tr>
						<td width="670"><label><em>
						&nbsp;<%=encprops.getProperty("day")%></em> <em> <select name="day1" id="day1">
							<option value="1" selected>1</option>
							<option value="2">2</option>
							<option value="3">3</option>
							<option value="4">4</option>
							<option value="5">5</option>
							<option value="6">6</option>
							<option value="7">7</option>
							<option value="8">8</option>
							<option value="9">9</option>
							<option value="10">10</option>
							<option value="11">11</option>
							<option value="12">12</option>
							<option value="13">13</option>
							<option value="14">14</option>
							<option value="15">15</option>
							<option value="16">16</option>
							<option value="17">17</option>
							<option value="18">18</option>
							<option value="19">19</option>
							<option value="20">20</option>
							<option value="21">21</option>
							<option value="22">22</option>
							<option value="23">23</option>
							<option value="24">24</option>
							<option value="25">25</option>
							<option value="26">26</option>
							<option value="27">27</option>
							<option value="28">28</option>
							<option value="29">29</option>
							<option value="30">30</option>
							<option value="31">31</option>
						</select> <%=encprops.getProperty("month")%></em> <em> <select name="month1" id="month1">
							<option value="1" selected>1</option>
							<option value="2">2</option>
							<option value="3">3</option>
							<option value="4">4</option>
							<option value="5">5</option>
							<option value="6">6</option>
							<option value="7">7</option>
							<option value="8">8</option>
							<option value="9">9</option>
							<option value="10">10</option>
							<option value="11">11</option>
							<option value="12">12</option>
						</select> <%=encprops.getProperty("year")%></em> <select name="year1" id="year1">
							<% for(int q=firstYear;q<=nowYear;q++) { %>
							<option value="<%=q%>" 
							
							<%
							if(q==firstYear){
							%>
								selected
							<%
							}
							%>
							><%=q%></option>

							<% } %>
						</select> &nbsp;to <em>&nbsp;<%=encprops.getProperty("day")%></em> <em> <select name="day2"
							id="day2">
							<option value="1">1</option>
							<option value="2">2</option>
							<option value="3">3</option>
							<option value="4">4</option>
							<option value="5">5</option>
							<option value="6">6</option>
							<option value="7">7</option>
							<option value="8">8</option>
							<option value="9">9</option>
							<option value="10">10</option>
							<option value="11">11</option>
							<option value="12">12</option>
							<option value="13">13</option>
							<option value="14">14</option>
							<option value="15">15</option>
							<option value="16">16</option>
							<option value="17">17</option>
							<option value="18">18</option>
							<option value="19">19</option>
							<option value="20">20</option>
							<option value="21">21</option>
							<option value="22">22</option>
							<option value="23">23</option>
							<option value="24">24</option>
							<option value="25">25</option>
							<option value="26">26</option>
							<option value="27">27</option>
							<option value="28">28</option>
							<option value="29">29</option>
							<option value="30">30</option>
							<option value="31" selected>31</option>
						</select> <%=encprops.getProperty("month")%></em> <em> <select name="month2" id="month2">
							<option value="1">1</option>
							<option value="2">2</option>
							<option value="3">3</option>
							<option value="4">4</option>
							<option value="5">5</option>
							<option value="6">6</option>
							<option value="7">7</option>
							<option value="8">8</option>
							<option value="9">9</option>
							<option value="10">10</option>
							<option value="11">11</option>
							<option value="12" selected>12</option>
						</select> <%=encprops.getProperty("year")%></em> 
						<select name="year2" id="year2">
							<% for(int q=nowYear;q>=firstYear;q--) { %>
							<option value="<%=q%>" 
							
							<%
							if(q==nowYear){
							%>
								selected
							<%
							}
							%>
							><%=q%></option>

							<% } %>
						</select>
						</label></td>
					</tr>
				</table>
				
				<p><strong><%=encprops.getProperty("verbatimEventDate")%>:</strong> <span class="para"><a href="<%=CommonConfiguration.getWikiLocation()%>verbatimEventDate"
					target="_blank"><img src="../images/information_icon_svg.gif"
					alt="Help" border="0" align="absmiddle" /></a></span></p>

				<%
				ArrayList<String> vbds = myShepherd.getAllVerbatimEventDates();
				int totalVBDs=vbds.size();

				
				if(totalVBDs>0){
				%>
				
				<select multiple size="<%=(totalVBDs+1) %>" name="verbatimEventDateField" id="verbatimEventDateField">
					<option value="None"></option>
					<%
					for(int f=0;f<totalVBDs;f++) {
						String word=vbds.get(f);
						if(word!=null){
							%>
							<option value="<%=word%>"><%=word%></option>
						<%	
							
						}

					}
					%>
					</select>
					<%

				}
				else{
					%>
					<p><em><%=encprops.getProperty("noVBDs")%></em></p>
					<%
				}
				%>
				</div>
				</td>
			</tr>
			
			<tr>
				<td>
					<h4 class="intro" style="background-color: #cccccc; padding:3px; border: 1px solid #000066; "><a href="javascript:animatedcollapse.toggle('observation')" style="text-decoration:none"><img src="../images/Black_Arrow_down.png" width="14" height="14" border="0" align="absmiddle" /> <font color="#000000">Observation attribute filters</font></a></h4>
				</td>
			</tr>
			
			<tr>
				<td>
				<div id="observation" style="display:none; ">
				<p>Use the fields below to filter your search based on observed attributes.</p>
							<input name="alive" type="hidden" id="alive" value="alive" /> 
							<input name="dead" type="hidden" id="dead" value="dead" /> 
							<input name="male" type="hidden" id="male" value="male" />
							<input name="female" type="hidden" id="female" value="female" />
						 	<input name="unknown" type="hidden" id="unknown" value="unknown" />
							<input type="hidden" name="approved" value="acceptedEncounters"></input>
							<input name="unapproved" type="hidden" value="allEncounters"></input>
							<input name="unidentifiable" type="hidden" value="allEncounters"></input>
				<p>
				<table align="left">

				
				<tr>
					<td valign="top"><strong><%=encprops.getProperty("behavior")%>:</strong>
						<em> <span class="para">
								<a href="<%=CommonConfiguration.getWikiLocation()%>behavior" target="_blank">
									<img src="../images/information_icon_svg.gif" alt="Help" border="0" align="absmiddle" />
								</a>
							</span> 
						</em><br />
				<%
				ArrayList<String> behavs = myShepherd.getAllBehaviors();
				int totalBehavs=behavs.size();

				
				if(totalBehavs>0){
				%>
				
				<select multiple name="behaviorField" id="behaviorField">
					<option value="None"></option>
					<%
					for(int f=0;f<totalBehavs;f++) {
						String word=behavs.get(f);
						if(word!=null){
							%>
							<option value="<%=word%>"><%=word%></option>
						<%	
							
						}

					}
					%>
					</select>
					<%

				}
				else{
					%>
					<p><em><%=encprops.getProperty("noBehaviors")%></em></p>
					<%
				}
				%>
							
					</p>
					</td>
				</tr>

				
				<tr>
					<td valign="top"><strong><%=encprops.getProperty("submitterName")%>:</strong>
						<em> <span class="para">
								<a href="<%=CommonConfiguration.getWikiLocation()%>recordedBy" target="_blank">
									<img src="../images/information_icon_svg.gif" alt="Help" border="0" align="absmiddle" />
								</a>
							</span> 
						</em><br />
				<%
				ArrayList<String> records = myShepherd.getAllRecordedBy();
				int totalRecords=records.size();

				
				if(totalRecords>0){
				%>
				
				<select multiple name="nameField" id="nameField">
					<option value="None"></option>
					<%
					for(int f=0;f<totalRecords;f++) {
						String word=records.get(f);
						if(word!=null){
							%>
							<option value="<%=word%>"><%=word%></option>
						<%	
							
						}

					}
					%>
					</select>
					<%

				}
				else{
					%>
					<p><em><%=encprops.getProperty("noRecordedBy")%></em></p>
					<%
				}
				%>
							
					</p>
					</td>
				</tr>
				
				<tr>
				<td>
				<input name="hasTissueSample" type="checkbox" value="true" /> <strong>Include only those sightings that include a tissue sample.</strong>
				</td>
				</tr>
				
				
			</table>
			</p>
			</div>
				</td>
			</tr>
			
			<tr>
				<td>
					<h4 class="intro" style="background-color: #cccccc; padding:3px; border: 1px solid #000066; "><a href="javascript:animatedcollapse.toggle('identity')" style="text-decoration:none"><img src="../images/Black_Arrow_down.png" width="14" height="14" border="0" align="absmiddle" /> <font color="#000000">Identity filters</font></a></h4>
				</td>
			</tr>
			<tr>
				<td>
				<div id="identity" style="display:none; ">
				<p>Use the fields below to limit your search to marked individuals with the following properties.</p>
				<input name="resightOnly" type="checkbox" id="resightOnly"
					value="true"> <strong><%=encprops.getProperty("include")%></strong> <select
					name="numResights" id="numResights">
					<option value="1" selected>1</option>
					<option value="2">2</option>
					<option value="3">3</option>
					<option value="4">4</option>
					<option value="5">5</option>
					<option value="6">6</option>
					<option value="7">7</option>
					<option value="8">8</option>
					<option value="9">9</option>
					<option value="10">10</option>
					<option value="11">11</option>
					<option value="12">12</option>
					<option value="13">13</option>
					<option value="14">14</option>
					<option value="15">15</option>
				</select> <strong><%=encprops.getProperty("times")%></strong>
				
				<p><strong><%=encprops.getProperty("alternateID")%>:</strong> <em> <input
					name="alternateIDField" type="text" id="alternateIDField" size="10"
					maxlength="35"> <span class="para"><a
					href="<%=CommonConfiguration.getWikiLocation()%>alternateID"
					target="_blank"><img src="../images/information_icon_svg.gif"
					alt="Help" width="15" height="15" border="0" align="absmiddle" /></a></span>
				<br></em></p>
				</div>
				</td>
			</tr>

						<%
myShepherd.rollbackDBTransaction();
myShepherd.closeDBTransaction();
%>


			<tr>
				<td>
				
				<!-- 
				<h4 class="intro" style="background-color: #cccccc; padding:3px; border: 1px solid #000066; "><a href="javascript:animatedcollapse.toggle('export')" style="text-decoration:none"><img src="../images/Black_Arrow_down.png" width="14" height="14" border="0" align="absmiddle" /> <font color="#000000">Export options</font></a></h4>
				<div id="export" style="display:none; ">
				<p>Use the fields below to specify data export options.</p>
				<p><input name="export" type="checkbox" id="export" value="true">
				<strong><%=encprops.getProperty("generateExportFile")%></strong><br>
				&nbsp;&nbsp;&nbsp;&nbsp;<input name="locales" type="checkbox"
					id="locales" value="true"> <%=encprops.getProperty("localeExport")%></p>
				</p>
				
				<p><input name="addTimeStamp" type="checkbox" id="addTimeStamp" value="true">
				<strong><%=encprops.getProperty("addTimestamp2KML")%></strong></p>
				
				<p><input name="generateEmails" type="checkbox"
					id="generateEmails" value="true"> <strong><%=encprops.getProperty("generateEmailList")%></strong></p>
				</p>
				</div>
				 -->
				<p><em> <input name="submitSearch" type="submit"
					id="submitSearch" value="<%=encprops.getProperty("goSearch")%>"></em>
					
				</td>
			</tr>
			
			
			
		</table>
		</form>
		</td>
	</tr>
</table>
<br> <jsp:include page="../footer.jsp" flush="true" />
</div>
</div>
<!-- end page --></div>
<!--end wrapper -->

</body>
</html>


