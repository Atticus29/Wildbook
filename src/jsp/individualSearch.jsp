<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%@ page contentType="text/html; charset=utf-8" language="java"
	import="java.util.ArrayList, org.ecocean.*, javax.jdo.*, java.lang.StringBuffer, java.util.Vector, java.util.Enumeration, java.util.Iterator, java.util.GregorianCalendar, java.util.Properties"%>
<%
Shepherd myShepherd=new Shepherd();
Extent allKeywords=myShepherd.getPM().getExtent(Keyword.class,true);		
Query kwQuery=myShepherd.getPM().newQuery(allKeywords);

GregorianCalendar cal=new GregorianCalendar();
int nowYear=cal.get(1);

int firstYear = 1980;
myShepherd.beginDBTransaction();
try{
	firstYear = myShepherd.getEarliestSightingYear();
	nowYear = myShepherd.getLastSightingYear();
}
catch(Exception e){
	e.printStackTrace();
}

//let's load out properties
Properties props=new Properties();
String langCode="en";
if(session.getAttribute("langCode")!=null){langCode=(String)session.getAttribute("langCode");}
props.load(getClass().getResourceAsStream("/bundles/"+langCode+"/individualSearch.properties"));

%>

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
<script type="text/javascript" src="javascript/animatedcollapse.js"></script>	 
<!-- /STEP1 Place inside the head section -->
<!-- STEP2 Place inside the head section -->
 <script type="text/javascript">
	animatedcollapse.addDiv('location', 'fade=1')
	animatedcollapse.addDiv('map', 'fade=1')
	animatedcollapse.addDiv('date', 'fade=1')
	animatedcollapse.addDiv('observation', 'fade=1')
	animatedcollapse.addDiv('identity', 'fade=1')

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
<div id="wrapper">
<div id="page"><jsp:include page="header.jsp" flush="true">
	<jsp:param name="isResearcher"
		value="<%=request.isUserInRole("researcher")%>" />
	<jsp:param name="isManager"
		value="<%=request.isUserInRole("manager")%>" />
	<jsp:param name="isReviewer"
		value="<%=request.isUserInRole("reviewer")%>" />
	<jsp:param name="isAdmin" value="<%=request.isUserInRole("admin")%>" />
</jsp:include>
<div id="main">
<table width="720">
	<tr>
		<td>
		<p>
		<h1 class="intro"><strong><span class="para">
		<img src="images/tag_big.gif" width="50" align="absmiddle" /></span></strong>
		<%=props.getProperty("title")%></h1>
		</p>
		<p><em><%=props.getProperty("instructions")%></em></p>
		<form action="individualThumbnailSearchResults.jsp" method="get" name="search"
			id="search">
		<table width="810px">
		
		<tr><td width="810px">
			
			<h4 class="intro" style="background-color: #cccccc; padding:3px; border: 1px solid #000066; "><a href="javascript:animatedcollapse.toggle('map')" style="text-decoration:none"><img src="images/Black_Arrow_down.png" width="14" height="14" border="0" align="absmiddle" /></a> <a href="javascript:animatedcollapse.toggle('map')" style="text-decoration:none"><font color="#000000">Location filter (map)</font></a></h4>
			</td>
			</tr>
			<tr><td width="810px">
			<script
				src="http://maps.google.com/maps?file=api&amp;v=3.2&amp;key=<%=CommonConfiguration.getGoogleMapsKey() %>"
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
                			buttonHTML: '<img title="Drag Zoom In" src="javascript/zoomin.gif">',
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
    <script src="javascript/dragzoom.js" type="text/javascript"></script>
<div id="map">
<p>Use the arrow and +/- keys to navigate to a portion of the globe of interest, then click and drag the <img src="javascript/zoomin.gif" align="absmiddle"/> icon to select the specific search boundaries. You can also use the text boxes below the map to specify exact boundaries.</p>
	
<div id="map_canvas" style="width: 510px; height: 340px; "></div>
<p>Northeast corner latitude: <input type="text" id="ne_lat" name="ne_lat"></input> longitude: <input type="text" id="ne_long" name="ne_long"></input><br /><br />
Southwest corner latitude: <input type="text" id="sw_lat" name="sw_lat"></input> longitude: <input type="text" id="sw_long" name="sw_long"></input></p>
</div>

			</td>
			</tr>

		<tr>
			<td>
			<h4 class="intro" style="background-color: #cccccc; padding:3px; border: 1px solid #000066; "><a href="javascript:animatedcollapse.toggle('location')" style="text-decoration:none"><img src="images/Black_Arrow_down.png" width="14" height="14" border="0" align="absmiddle" /> <font color="#000000">Location filters (text)</font></a></h4>
			<div id="location" style="display:none; ">
				<p>Use the fields below to filter the search by a location string (e.g. "Mexico") or to a specific, pre-defined location identifier.</p>
					<p><strong><%=props.getProperty("locationNameContains")%>:</strong> 
					<input name="locationField" type="text" size="60"> <br> <em><%=props.getProperty("leaveBlank")%></em>
				</p>
				<p><strong><%=props.getProperty("locationID")%>:</strong> <span class="para"><a href="<%=CommonConfiguration.getWikiLocation()%>locationID"
					target="_blank"><img src="images/information_icon_svg.gif"
					alt="Help" border="0" align="absmiddle" /></a></span> <br> 
					(<em><%=props.getProperty("locationIDExample")%></em>)</p>

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
				%>
					<option value="<%=word%>"><%=word%></option>
				<%}
					}
				%>
				</select>
				<%
				}
				else{
					%>
					<p><em><%=props.getProperty("noLocationIDs")%></em></p>
					<%
				}
				%>
				</div>
				</td>

			</tr>
			
			
			<tr>
				<td>
					<h4 class="intro" style="background-color: #cccccc; padding:3px; border: 1px solid #000066; "><a href="javascript:animatedcollapse.toggle('date')" style="text-decoration:none"><img src="images/Black_Arrow_down.png" width="14" height="14" border="0" align="absmiddle" /> <font color="#000000">Date filters</font></a></h4>
				</td>
			</tr>

<tr>
				<td>
				<div id="date" style="display:none;">
				<p>Use the fields below to limit the timeframe of your search.</p>
				<strong><%=props.getProperty("sightingDates")%>:</strong><br />
				<table width="720">
					<tr>
						<td width="670"><label><em>
						&nbsp;<%=props.getProperty("day")%></em> <em> <select name="day1" id="day1">
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
						</select> <%=props.getProperty("month")%></em> <em> <select name="month1" id="month1">
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
						</select> <%=props.getProperty("year")%></em> <select name="year1" id="year1">
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
						</select> &nbsp;to <em>&nbsp;<%=props.getProperty("day")%></em> <em> <select name="day2"
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
						</select> <%=props.getProperty("month")%></em> <em> <select name="month2" id="month2">
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
						</select> <%=props.getProperty("year")%></em> 
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
				
				<p><strong><%=props.getProperty("verbatimEventDate")%>:</strong> <span class="para"><a href="<%=CommonConfiguration.getWikiLocation()%>verbatimEventDate"
					target="_blank"><img src="images/information_icon_svg.gif"
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
					<p><em><%=props.getProperty("noVBDs")%></em></p>
					<%
				}
				%>
				</div>
				</td>
			</tr>



			<tr>
				<td>
					<h4 class="intro" style="background-color: #cccccc; padding:3px; border: 1px solid #000066; "><a href="javascript:animatedcollapse.toggle('observation')" style="text-decoration:none"><img src="images/Black_Arrow_down.png" width="14" height="14" border="0" align="absmiddle" /> <font color="#000000">Observation attribute filters</font></a></h4>
				</td>
			</tr>



			<tr>
				<td><div id="observation" style="display:none; ">
				<p>Use the fields below to filter your search based on observed attributes.</p>
				<table align="left">
					<tr><td><table><tr>
						<td width="62"><strong><%=props.getProperty("sex")%>: </strong></td>
						<td width="62"><label> <input name="sex" type="radio"
							value="all" checked> <%=props.getProperty("all")%></label></td>
						<td width="138"><label> <input name="sex"
							type="radio" value="mf"> <%=props.getProperty("maleOrFemale")%></label></td>

						<td width="76"><label> <input type="radio" name="sex"
							value="male"> <%=props.getProperty("male")%></label></td>

						<td width="79"><label> <input type="radio" name="sex"
							value="female"><%=props.getProperty("female")%></label></td>
						<td width="112"><label> <input type="radio"
							name="sex" value="unknown"> <%=props.getProperty("unknown")%></label></td>
					</tr>
					</table></td>
					</tr>
					<%
int totalKeywords=myShepherd.getNumKeywords();
%>
			<tr>
				<td><p><%=props.getProperty("hasKeywordPhotos")%></p>
				<%
				
				if(totalKeywords>0){
				%>
				
				<select multiple size="<%=(totalKeywords+1) %>" name="keyword" id="keyword">
					<option value="None"></option>
					<% 
				

			  	Iterator keys=myShepherd.getAllKeywords(kwQuery);
			  	for(int n=0;n<totalKeywords;n++) {
					Keyword word=(Keyword)keys.next();
				%>
					<option value="<%=word.getIndexname()%>"><%=word.getReadableName()%></option>
					<%}
				
				%>

				</select>
				<%
				}
				else{
					%>
					
					<p><em><%=props.getProperty("noKeywords")%></em></p>
					
					<%
					
				}
				%>
				</td>
			</tr>

				</table>

				</div>
				</td>
			</tr>
			
			<tr>
				<td>
					<h4 class="intro" style="background-color: #cccccc; padding:3px; border: 1px solid #000066; "><a href="javascript:animatedcollapse.toggle('identity')" style="text-decoration:none"><img src="images/Black_Arrow_down.png" width="14" height="14" border="0" align="absmiddle" /> <font color="#000000">Identity filters</font></a></h4>
				</td>
			</tr>
			
			<tr>
				<td>
				<div id="identity" style="display:none; ">
				<table><tr><td>
				<%=props.getProperty("maxYearsBetweenResights")%>: <select
					name="numResightsOperator" id="numResightsOperator">
					<option value="greater" selected="selected">&#8250;=</option>
					<option value="equals">=</option>
					<option value="less">&#8249;=</option>
				</select> &nbsp; <select name="numResights" id="numResights">
					<%
					
					int maxYearsBetweenResights = 0;
					try{
						maxYearsBetweenResights = Math.abs(nowYear-firstYear);
					}
					catch(Exception e){}
					
					%>
					
					<option value="" selected="selected"></option>
					
					<%
					for(int u=0;u<=maxYearsBetweenResights;u++){
					%>
					<option value="<%=u%>"><%=u%></option>
					<%
					}
					%>
				</select> <%=props.getProperty("yearsApart")%>
				</td>
				
				</tr>
				<tr>
				<td>
				<p><strong><%=props.getProperty("alternateID")%>:</strong> <em> <input
					name="alternateIDField" type="text" id="alternateIDField" size="25"
					maxlength="100"> <span class="para"><a
					href="<%=CommonConfiguration.getWikiLocation()%>alternateID"
					target="_blank"><img src="images/information_icon_svg.gif"
					alt="Help" width="15" height="15" border="0" align="absmiddle" /></a></span>
				<br></em></p>
				</td>
			</tr>
				
				</table>
				</td>
				
			</tr>


			
			
			
<%
myShepherd.rollbackDBTransaction();
%>

			

			<tr>
				<td>
		
				<p><em> <input name="submitSearch" type="submit" id="submitSearch" value="<%=props.getProperty("goSearch")%>"></em>
				</td>
			</tr>
		</table>
		</form>
		</td>
	</tr>
</table>
<br> <jsp:include page="footer.jsp" flush="true" />
</div>
</div>
<!-- end page --></div>
<!--end wrapper -->

<%
kwQuery.closeAll();
myShepherd.closeDBTransaction();
kwQuery=null;
myShepherd=null;
%>

</body>
</html>


