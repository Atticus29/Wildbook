<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%@ page contentType="text/html; charset=utf-8" language="java" import="org.ecocean.*, javax.jdo.*, java.lang.StringBuffer, java.lang.Integer, java.lang.NumberFormatException, java.io.*, java.util.Vector, java.util.Iterator, java.util.StringTokenizer, java.util.Properties"%>
<%@ taglib uri="di" prefix="di"%>

<html>
<head>
<%

//let's load out properties
Properties props=new Properties();
String langCode="en";
if(session.getAttribute("langCode")!=null){langCode=(String)session.getAttribute("langCode");}
props.load(getClass().getResourceAsStream("/bundles/"+langCode+"/individualSearchResults.properties"));


int startNum=1;
int endNum=10;


try{ 

	if (request.getParameter("startNum")!=null) {
		startNum=(new Integer(request.getParameter("startNum"))).intValue();
	}
	if (request.getParameter("endNum")!=null) {
		endNum=(new Integer(request.getParameter("endNum"))).intValue();
	}

} catch(NumberFormatException nfe) {
	startNum=1;
	endNum=10;
}
int listNum=endNum;

int day1=1, day2=31, month1=1, month2=12, year1=0, year2=3000;
try{month1=(new Integer(request.getParameter("month1"))).intValue();} catch(NumberFormatException nfe) {}
try{month2=(new Integer(request.getParameter("month2"))).intValue();} catch(NumberFormatException nfe) {}
try{year1=(new Integer(request.getParameter("year1"))).intValue();} catch(NumberFormatException nfe) {}
try{year2=(new Integer(request.getParameter("year2"))).intValue();} catch(NumberFormatException nfe) {}


Shepherd myShepherd=new Shepherd();

/*
String sexParam="";
if(request.getParameter("sex")!=null) {sexParam="&sex="+request.getParameter("sex");}
String keywordParam="";
if(request.getParameter("keyword")!=null) {keywordParam="&keyword="+request.getParameter("keyword");}
String numResightsParam="";
if(request.getParameter("numResights")!=null) {numResightsParam="&numResights="+request.getParameter("numResights");}
String lengthParams="";
if((request.getParameter("selectLength")!=null)&&(request.getParameter("lengthField")!=null)) {
	lengthParams="&selectLength="+request.getParameter("selectLength")+"&lengthField="+request.getParameter("lengthField");
}
String locCodeParam="";
if(request.getParameter("locationCodeField")!=null) {locCodeParam="&locationCodeField="+request.getParameter("locationCodeField");}
String dateParams="day1="+day1+"&day2="+day2+"&month1="+month1+"&month2="+month2+"&year1="+year1+"&year2="+year2;
String exportParam="";
if(request.getParameter("export")!=null) {exportParam="&export=true";}
String numberSpots="";
if(request.getParameter("numspots")!=null) {numberSpots="&numspots="+request.getParameter("numspots");}
String qString=dateParams+sexParam+numResightsParam+locCodeParam+lengthParams+exportParam+keywordParam+numberSpots;
*/

int numResults=0;


Vector<MarkedIndividual> rIndividuals=new Vector<MarkedIndividual>();			
myShepherd.beginDBTransaction();
String order="";

MarkedIndividualQueryResult result = IndividualQueryProcessor.processQuery(myShepherd, request, order);
rIndividuals = result.getResult();




if(rIndividuals.size()<listNum) {listNum=rIndividuals.size();}
%>
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

</head>
<style type="text/css">
#tabmenu {
	color: #000;
	border-bottom: 2px solid black;
	margin: 12px 0px 0px 0px;
	padding: 0px;
	z-index: 1;
	padding-left: 10px
}

#tabmenu li {
	display: inline;
	overflow: hidden;
	list-style-type: none;
}

#tabmenu a,a.active {
	color: #DEDECF;
	background: #000;
	font: bold 1em "Trebuchet MS", Arial, sans-serif;
	border: 2px solid black;
	padding: 2px 5px 0px 5px;
	margin: 0;
	text-decoration: none;
	border-bottom: 0px solid #FFFFFF;
}

#tabmenu a.active {
	background: #FFFFFF;
	color: #000000;
	border-bottom: 2px solid #FFFFFF;
}

#tabmenu a:hover {
	color: #ffffff;
	background: #7484ad;
}

#tabmenu a:visited {
	color: #E8E9BE;
}

#tabmenu a.active:hover {
	background: #7484ad;
	color: #DEDECF;
	border-bottom: 2px solid #000000;
}
</style>
<body>
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
<ul id="tabmenu">


	<li><a class="active" ><%=props.getProperty("table")%></a></li>
	<li><a href="individualThumbnailSearchResults.jsp?<%=request.getQueryString().replaceAll("startNum","uselessNum").replaceAll("endNum","uselessNum") %>"><%=props.getProperty("matchingImages")%></a></li>

</ul>
<table width="810" border="0" cellspacing="0" cellpadding="0">
	<tr>
		<td>
		<br />
		<h1 class="intro"><span class="para"><img src="images/tag_big.gif" width="35" align="absmiddle" />
		<%=props.getProperty("title")%></h1>
		<p><%=props.getProperty("instructions")%></p>
		</td>
	</tr>
</table>



<table width="810" border="1">
	<tr>
		<td bgcolor="#99CCFF"></td>
		<td align="left" valign="top" bgcolor="#99CCFF"><strong><%=props.getProperty("markedIndividual")%></strong></td>
		<td align="left" valign="top" bgcolor="#99CCFF"><strong>No. Seasons Sighted</strong></td>
		<td align="left" valign="top" bgcolor="#99CCFF"><strong><%=props.getProperty("numLocationsSighted")%></strong></td>
		<td align="left" valign="top" bgcolor="#99CCFF"><strong><%=props.getProperty("sex")%></strong></td>


	</tr>

	<%	

//set up the statistics counters	
int count=0;
int numNewlyMarked = 0;

Vector histories=new Vector();
for(int f=0;f<rIndividuals.size();f++) {
	MarkedIndividual indie=(MarkedIndividual)rIndividuals.get(f);
	count++;
	
	//check if this individual was newly marked in this period
	Encounter[] dateSortedEncs=indie.getDateSortedEncounters(true);
	int sortedLength=dateSortedEncs.length-1;
	Encounter temp=dateSortedEncs[sortedLength];

	
		if((temp.getYear()==year1)&&(temp.getYear()<year2)&&(temp.getMonth()>=month1)){
			numNewlyMarked++;
		}
		else if((temp.getYear()>year1)&&(temp.getYear()==year2)&&(temp.getMonth()<=month2)){
			numNewlyMarked++;
		}
		else if((temp.getYear()>=year1)&&(temp.getYear()<=year2)&&(temp.getMonth()>=month1)&&(temp.getMonth()<=month2)){
			numNewlyMarked++;
		}
	
	
	if((count>=startNum)&&(count<=endNum)) {			
		Encounter tempEnc=indie.getEncounter(0);		
%>
	<tr>
		<td width="102" bgcolor="#000000"><img
			src="<%=("encounters/"+tempEnc.getEncounterNumber()+"/thumb.jpg")%>"></td>
		<td><a
			href="http://<%=CommonConfiguration.getURLLocation()%>/individuals.jsp?number=<%=indie.getName()%>"><%=indie.getName()%></a>
		<%
		  if((indie.getAlternateID()!=null)&&(!indie.getAlternateID().equals("None"))){
		  %> <br><font size="-1"><%=props.getProperty("alternateID")%>: <%=indie.getAlternateID()%></font> <%
		  }
			%>
		  <br><font size="-1"><%=props.getProperty("firstIdentified")%>: <%=temp.getMonth() %>/<%=temp.getYear() %></font>
		
		</td>
		<td><%=indie.totalEncounters()%></td>
		
		<td><%=indie.getMaxNumYearsBetweenSightings()%></td>
		
		<td><%=indie.getSex()%></td>
		
		<td><%=indie.particpatesInTheseVerbatimEventDates().size()%></td>
	</tr>
	<%
} //end if to control number displayed
if (((request.getParameter("export")!=null)||(request.getParameter("capture")!=null))&&(request.getParameter("startNum")==null)) {
	//let's generate a programMarkEntry for this shark or check for an existing one
  	//first generate a history
	int startYear=3000;
	int endYear=3000;
	int startMonth=3000;
	int endMonth=3000;
	String history="";
	if(year1>year2){startYear=year2;endYear=year1;startMonth=month2;endMonth=year1;}
  	else{startYear=year1; endYear=year2;startMonth=month1; endMonth=month2;}
	int NumHistoryYears=(endYear-startYear)+1;

	//there will be yearDiffs histories
	while(startYear<=endYear){
		if(request.getParameter("subsampleMonths")!=null){
			int monthIter=startMonth;
			while(monthIter<=endMonth) {
				if(indie.wasSightedInMonth(startYear, monthIter)){history=history+"1";}
				else{history=history+"0";}
				monthIter++;
			} //end while
		}
		else {
			if(indie.wasSightedInYear(startYear)){history=history+"1";}
			else{history=history+"0";}
		}
		startYear++;
	}
	
	boolean foundIdenticalHistory=false;
	for(int h=0;h<histories.size();h++){

	}
	if(!foundIdenticalHistory){
		
		if(history.indexOf("1")!=-1) {

		}
	}	
	

  } //end if export
  
 } //end for
boolean includeZeroYears=true;

boolean subsampleMonths=false;
if(request.getParameter("subsampleMonths")!=null){
	subsampleMonths=true;
}
numResults=count;
  %>
</table>



<%
	myShepherd.rollbackDBTransaction();
	startNum+=10;	
	endNum+=10;
	if(endNum>numResults) {
		endNum=numResults;
	}



%>
<table width="810px">
<tr>
<%
if((startNum-10)>1) {%>
 <td align="left">
<p>
<a href="individualSearchResults.jsp?<%=request.getQueryString().replaceAll("startNum","uselessNum").replaceAll("endNum","uselessNum") %>&startNum=<%=(startNum-20)%>&endNum=<%=(startNum-11)%>&sort=<%=request.getParameter("sort")%>"><img src="images/Black_Arrow_left.png" width="28" height="28" border="0" align="absmiddle" title="<%=props.getProperty("seePreviousResults")%>" /></a> <a href="individualSearchResults.jsp?<%=request.getQueryString().replaceAll("startNum","uselessNum").replaceAll("endNum","uselessNum") %>&startNum=<%=(startNum-20)%>&endNum=<%=(startNum-11)%>&sort=<%=request.getParameter("sort")%>"><%=(startNum-20)%> - <%=(startNum-11)%></a>
</p>
</td>
<%
}

if(startNum<numResults) {
%>
<td align="right">
<p>
<a href="individualSearchResults.jsp?<%=request.getQueryString().replaceAll("startNum","uselessNum").replaceAll("endNum","uselessNum") %>&startNum=<%=startNum%>&endNum=<%=endNum%>&sort=<%=request.getParameter("sort")%>"><%=startNum%> - <%=endNum%></a> <a href="individualSearchResults.jsp?<%=request.getQueryString().replaceAll("startNum","uselessNum").replaceAll("endNum","uselessNum") %>&startNum=<%=startNum%>&endNum=<%=endNum%>&sort=<%=request.getParameter("sort")%>"><img src="images/Black_Arrow_right.png" width="28" height="28" border="0" align="absmiddle" title="<%=props.getProperty("seeNextResults")%>" /></a>
</p>
</td>
<%
}
%>
</tr></table>

<p>
<table width="810" border="0" cellspacing="0" cellpadding="0">
	<tr>
		<td align="left">
		<p><strong><%=props.getProperty("matchingMarkedIndividuals")%></strong>: <%=count%><br />
		<%=props.getProperty("numFirstSighted")%>: <%=numNewlyMarked %>
		</p>
		<%myShepherd.beginDBTransaction();%>
		<p><strong><%=props.getProperty("totalMarkedIndividuals")%></strong>: <%=(myShepherd.getNumMarkedIndividuals())%></p>
		</td>
		<%
	  myShepherd.rollbackDBTransaction();
	  myShepherd.closeDBTransaction();
	  
	  %>
	</tr>
</table>
<%
if(request.getParameter("noQuery")==null){
%>
<table><tr><td align="left">

<p><strong><%=props.getProperty("queryDetails")%></strong></p>

	<p class="caption"><strong><%=props.getProperty("prettyPrintResults") %></strong><br /> 
	<%=result.getQueryPrettyPrint().replaceAll("locationField",props.getProperty("location")).replaceAll("locationCodeField",props.getProperty("locationID")).replaceAll("verbatimEventDateField",props.getProperty("verbatimEventDate")).replaceAll("Sex",props.getProperty("sex")).replaceAll("Keywords",props.getProperty("keywords")).replaceAll("alternateIDField",(props.getProperty("alternateID"))).replaceAll("alternateIDField",(props.getProperty("size")))%></p>
	
	<p class="caption"><strong><%=props.getProperty("jdoql")%></strong><br /> 
	<%=result.getJDOQLRepresentation()%></p>

</td></tr></table>
<%
}
%>
</p>
<br>
<p></p>
<jsp:include page="footer.jsp" flush="true" />
</div>
</div>
<!-- end page --></div>
<!--end wrapper -->
</body>
</html>


