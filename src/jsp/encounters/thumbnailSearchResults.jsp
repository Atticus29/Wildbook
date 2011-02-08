<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%@ page contentType="text/html; charset=utf-8" language="java" import="org.apache.sanselan.*,java.awt.Dimension,java.util.Collections,java.io.File,com.drew.imaging.jpeg.*, com.drew.metadata.*,java.util.StringTokenizer,org.ecocean.*, java.lang.Integer, java.lang.NumberFormatException, java.util.Vector, java.util.Iterator, java.util.GregorianCalendar, java.util.Properties, javax.jdo.*"%>

<html>
<head>


<%
int startNum=1;
int endNum=45;

try{ 

	if (request.getParameter("startNum")!=null) {
		startNum=(new Integer(request.getParameter("startNum"))).intValue();
	}
	if (request.getParameter("endNum")!=null) {
		endNum=(new Integer(request.getParameter("endNum"))).intValue();
	}

} catch(NumberFormatException nfe) {
	startNum=1;
	endNum=45;
}

//let's load thumbnailSearch.properties
String langCode="en";
if(session.getAttribute("langCode")!=null){langCode=(String)session.getAttribute("langCode");}

Properties encprops=new Properties();
encprops.load(getClass().getResourceAsStream("/bundles/"+langCode+"/thumbnailSearchResults.properties"));


Shepherd myShepherd=new Shepherd();

Vector rEncounters=new Vector();			

myShepherd.beginDBTransaction();
EncounterQueryResult queryResult=new EncounterQueryResult(new Vector<Encounter>(),"","");


  			if(request.getParameter("noQuery")==null){
  				queryResult=EncounterQueryProcessor.processQuery(myShepherd, request, "year descending, month descending, day descending");
  				rEncounters = queryResult.getResult();
  			}
  			else{
  				Iterator allEncounters=myShepherd.getAllEncounters();
  				while(allEncounters.hasNext()){
  					Encounter enc=(Encounter)allEncounters.next();
  					rEncounters.add(enc);
  				}
  			}
  			
  			String[] keywords=request.getParameterValues("keyword");
  			if(keywords==null){keywords=new String[0];}

  			int numThumbnails = myShepherd.getNumThumbnails(rEncounters.iterator(), keywords);



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
	

	
<!--
	1 ) Reference to the files containing the JavaScript and CSS.
	These files must be located on your server.
-->

<script type="text/javascript" src="../highslide/highslide/highslide-with-gallery.js"></script>
<link rel="stylesheet" type="text/css" href="../highslide/highslide/highslide.css" />

<!--
	2) Optionally override the settings defined at the top
	of the highslide.js file. The parameter hs.graphicsDir is important!
-->

<script type="text/javascript">
hs.graphicsDir = '../highslide/highslide/graphics/';
hs.align = 'center';
hs.transitions = ['expand', 'crossfade'];
hs.outlineType = 'rounded-white';
hs.fadeInOut = true;

// define the restraining box
hs.useBox = true;
hs.width = 810;
hs.height=500;

//block user copying
hs.blockRightClick=true;


// Add the controlbar
hs.addSlideshow({
	//slideshowGroup: 'group1',
	interval: 5000,
	repeat: false,
	useControls: true,
	fixedControls: 'fit',
	overlayOptions: {
		opacity: 0.75,
		position: 'top center',
		hideOnMouseOut: true
		
	}
});

</script>	
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
<div id="page"><jsp:include page="../header.jsp" flush="true">
	
	<jsp:param name="isAdmin" value="<%=request.isUserInRole(\"admin\")%>" />
</jsp:include>
<div id="main">

<%
String rq="";
if(request.getQueryString()!=null){rq=request.getQueryString();}
if(request.getParameter("noQuery")==null){
%>

<ul id="tabmenu">

	<li><a href="searchResults.jsp?<%=rq.replaceAll("startNum","uselessNum").replaceAll("endNum","uselessNum") %>"><%=encprops.getProperty("table")%></a></li>
	<li><a class="active"><%=encprops.getProperty("matchingImages")%></a></li>
	<li><a href="mappedSearchResults.jsp?<%=rq.replaceAll("startNum","uselessNum").replaceAll("endNum","uselessNum") %>"><%=encprops.getProperty("mappedResults")%></a></li>
	<li><a href="../xcalendar/calendar2.jsp?<%=rq.replaceAll("startNum","uselessNum").replaceAll("endNum","uselessNum") %>"><%=encprops.getProperty("resultsCalendar")%></a></li>
	<li><a href="searchResultsExport.jsp?<%=request.getQueryString().replaceAll("startNum","uselessNum").replaceAll("endNum","uselessNum") %>">Exported Results</a></li>
	
</ul>
<%
}
%>

<table width="810" border="0" cellspacing="0" cellpadding="0">
	<tr>
		<td>
		<p>
		<h1 class="intro"><%=encprops.getProperty("title")%></h1>
		</p>
			
	  <p><strong>Matching sightings</strong>: <%=rEncounters.size()%></p>
	
			
			<p><strong>
			<%=encprops.getProperty("totalMatches")%></strong>: <%=numThumbnails%></p>
	
		<p><%=encprops.getProperty("belowMatches")%> <%=startNum%> - <%=endNum%> <%=encprops.getProperty("thatMatched")%></p>
		</td>
	</tr>
</table>

<%
String qString=rq;
int startNumIndex=qString.indexOf("&startNum");
if(startNumIndex>-1) {
	qString=qString.substring(0,startNumIndex);
}

%>
<table width="810px">
  <tr>
  <%
if((startNum)>1) {%>
<td align="left">
<p><a href="thumbnailSearchResults.jsp?<%=qString%>&startNum=<%=(startNum-45)%>&endNum=<%=(startNum-1)%>"><img src="../images/Black_Arrow_left.png" width="28" height="28" border="0" align="absmiddle" title="<%=encprops.getProperty("seePreviousResults")%>" /></a>  <a href="thumbnailSearchResults.jsp?<%=qString%>&startNum=<%=(startNum-45)%>&endNum=<%=(startNum-1)%>"><%=(startNum-45)%> - <%=(startNum-1)%></a></p>
</td>
<%
}
%>
 <td align="right">
	<p><a href="thumbnailSearchResults.jsp?<%=qString%>&startNum=<%=(startNum+45)%>&endNum=<%=(endNum+45)%>"><%=(startNum+45)%> - <%=(endNum+45)%></a> <a href="thumbnailSearchResults.jsp?<%=qString%>&startNum=<%=(startNum+45)%>&endNum=<%=(endNum+45)%>"><img src="../images/Black_Arrow_right.png" border="0" align="absmiddle" title="<%=encprops.getProperty("seeNextResults")%>" /></a></p>
	</td>
</tr>
</table>







<table id="results" border="0" width="100%" >
	<%		

			
			int countMe=0;
			Vector thumbLocs=new Vector();
			
			try {
				thumbLocs=myShepherd.getThumbnails(rEncounters.iterator(), startNum, endNum, keywords);

				//now let's order these alphabetical by the highest keyword
				//Cascadia Research only! TBD--remove on release of Shepherd Project
				Collections.sort(thumbLocs, (new ThumbnailKeywordComparator()));
				
				
				
			
					for(int rows=0;rows<15;rows++) {		%>

						<tr valign="top">

							<%
							for(int columns=0;columns<3;columns++){
								if(countMe<thumbLocs.size()) {
									String combined=(String)thumbLocs.get(countMe);
									StringTokenizer stzr=new StringTokenizer(combined,"BREAK");
									String thumbLink=stzr.nextToken();
									String encNum=stzr.nextToken();
									int fileNamePos=combined.lastIndexOf("BREAK")+5;
									String fileName=combined.substring(fileNamePos);
									boolean video=true;
									if(!thumbLink.endsWith("video.jpg")){
										thumbLink="http://"+CommonConfiguration.getURLLocation()+"/encounters/"+thumbLink;
										video=false;
									}
									String link="http://"+CommonConfiguration.getURLLocation()+"/encounters/"+encNum+"/"+fileName;
						
							%>

									<td>
										<table>
										<tr>
											<td valign="top">
												
												<a href="<%=link%>" class="highslide" onclick="return hs.expand(this)"><img src="<%=thumbLink%>" alt="photo" border="1" title="Click to enlarge" /></a>
						
										
										
										<div class="highslide-caption" id="localImage<%=(countMe+startNum) %>">
										
										<h3><%=(countMe+startNum) %>/<%=numThumbnails %></h3>
																									<%
										if(request.getParameter("referenceImageName")!=null){
										%>
											<h4>Reference Image</h4>
											<table id="table<%=(countMe+startNum) %>">
											<tr>
											<td>
											
						
											
											<img width="790px" class="highslide-image" id="refImage<%=(countMe+startNum) %>" src="<%=request.getParameter("referenceImageName") %>" />
											
											<SCRIPT LANGUAGE="JAVASCRIPT" TYPE="TEXT/JAVASCRIPT">
											<!--
											//document.images["refImage<%=(countMe+startNum) %>"].style.width = document.getElementById('highslider').clientWidth;
											//-->
											</SCRIPT>
											
											</td>
											</tr>	
											</table>									
										<%
										}
										%>
										<h4><%=encprops.getProperty("imageMetadata") %></h4>
										
										<table>
											<tr>
												<td align="left" valign="top">
										
												<table>
										<%
											
										int kwLength=keywords.length;
										Encounter thisEnc = myShepherd.getEncounter(encNum);
										%>
								
										<tr><td><span class="caption"><em><%=(countMe+startNum) %>/<%=numThumbnails %></em></span></td></tr>
										<tr><td><span class="caption"><%=encprops.getProperty("location") %>: <%=thisEnc.getLocation() %></span></td></tr>
										<tr><td><span class="caption"><%=encprops.getProperty("locationID") %>: <%=thisEnc.getLocationID() %></span></td></tr>
										<tr><td><span class="caption"><%=encprops.getProperty("date") %>: <%=thisEnc.getDate() %></span></td></tr>
										<tr><td><span class="caption"><%=encprops.getProperty("individualID") %>: <a href="../individuals.jsp?number=<%=thisEnc.getIndividualID() %>"><%=thisEnc.getIndividualID() %></a></span></td></tr>
										<tr><td><span class="caption"><%=encprops.getProperty("catalogNumber") %>: <a href="encounter.jsp?number=<%=thisEnc.getCatalogNumber() %>"><%=thisEnc.getCatalogNumber() %></a></span></td></tr>
											<tr><td><span class="caption">Research Group: <%=thisEnc.getSubmitterName() %></span></td></tr>
										

										
										
<%
										if(thisEnc.getVerbatimEventDate()!=null){
										%>
											<tr>
											
											<td><span class="caption"><%=encprops.getProperty("verbatimEventDate") %>: <%=thisEnc.getVerbatimEventDate() %></span></td></tr>
										<%
										}
										%>
										<tr>
										<td><span class="caption">
											<%=encprops.getProperty("matchingKeywords") %>
											<%
											//int numKeywords=myShepherd.getNumKeywords();
											Iterator allKeywords2=myShepherd.getAllKeywords();
											
											while(allKeywords2.hasNext()){
												Keyword word=(Keyword)allKeywords2.next();
									            if(word.isMemberOf(encNum+"/"+fileName)) {
									            	
									            	String renderMe=word.getReadableName();
									                	
										          	for(int kwIter=0;kwIter<kwLength;kwIter++) {
											              String kwParam=keywords[kwIter];
											              if(kwParam.equals(word.getIndexname())) {
											            	  renderMe="<strong>"+renderMe+"</strong>";
											              }
											       }	
									            	

								                	%>
													<br /><%= renderMe%>
													<%
									              
									            }
									         }
											
											%>
										</span></td>
										</tr>

										</table>
										</td>
										
										<%
										if(CommonConfiguration.showEXIFData()){
										%>
										
												<td align="left" valign="top">
												<span class="caption">
						<ul>
					<%
					if((fileName.toLowerCase().endsWith("jpg"))||(fileName.toLowerCase().endsWith("jpeg"))){
						File exifImage=new File(getServletContext().getRealPath(("/"+CommonConfiguration.getImageDirectory()+"/"+thisEnc.getCatalogNumber()+"/"+fileName)));
						Metadata metadata = JpegMetadataReader.readMetadata(exifImage);
						// iterate through metadata directories 
						Iterator directories = metadata.getDirectoryIterator();
						while (directories.hasNext()) { 
							Directory directory = (Directory)directories.next(); 
							// iterate through tags and print to System.out  
							Iterator tags = directory.getTagIterator(); 
							while (tags.hasNext()) { 
								Tag tag = (Tag)tags.next(); 
								
								%>
								<li><%=tag.toString() %></li>
								<% 
							} 
						} 
					
					}					
					%>
   									
   								</ul>
   								</span>
												
												
												</td>
									<%
										}
									%>
											</tr>
								
										</table>
</div>
												</div>
											</td>
										</tr>
							
										
										<tr><td><span class="caption"><%=encprops.getProperty("location") %>: <%=thisEnc.getLocation() %></span></td></tr>
										<tr><td><span class="caption"><%=encprops.getProperty("locationID") %>: <%=thisEnc.getLocationID() %></span></td></tr>
										<tr><td><span class="caption"><%=encprops.getProperty("date") %>: <%=thisEnc.getDate() %></span></td></tr>
										<tr><td><span class="caption"><%=encprops.getProperty("individualID") %>: <a href="../individuals.jsp?number=<%=thisEnc.getIndividualID() %>"><%=thisEnc.getIndividualID() %></a></span></td></tr>
										<tr><td><span class="caption"><%=encprops.getProperty("catalogNumber") %>: <a href="encounter.jsp?number=<%=thisEnc.getCatalogNumber() %>"><%=thisEnc.getCatalogNumber() %></a></span></td></tr>
											<tr><td><span class="caption">Research Group: <%=thisEnc.getSubmitterName() %></span></td></tr>
										<tr>
										<td><span class="caption">
											<%=encprops.getProperty("matchingKeywords") %>
											<%
											//int numKeywords=myShepherd.getNumKeywords();
											Iterator allKeywords=myShepherd.getAllKeywords();
											
											while(allKeywords.hasNext()){
												Keyword word=(Keyword)allKeywords.next();
									            if(word.isMemberOf(encNum+"/"+fileName)) {
									            	
									            	String renderMe=word.getReadableName();
									                	
										          	for(int kwIter=0;kwIter<kwLength;kwIter++) {
											              String kwParam=keywords[kwIter];
											              if(kwParam.equals(word.getIndexname())) {
											            	  renderMe="<strong>"+renderMe+"</strong>";
											              }
											       }	
									            	

								                	%>
													<br /><%= renderMe%>
													<%
									              
									            }
									         }
											
											%>
										</span></td>
										</tr>
										
										</table>
									</td>
							<%
					
								countMe++;
								} //end if
							} //endFor
							%>
					</tr>
				<%} //endFor
	
				} catch(Exception e) {
					e.printStackTrace();
				%>
	<tr>
		<td>
		<p><%=encprops.getProperty("error")%></p>.</p>
		</td>
	</tr>
	<%}
%>

</table>

<%




	startNum=startNum+45;	
	endNum=endNum+45;

%>

<table width="810px">
  <tr>
  <%
if((startNum-45)>1) {%>
<td align="left">
<p><a href="thumbnailSearchResults.jsp?<%=qString%>&startNum=<%=(startNum-90)%>&endNum=<%=(startNum-46)%>"><img src="../images/Black_Arrow_left.png" width="28" height="28" border="0" align="absmiddle" title="<%=encprops.getProperty("seePreviousResults")%>" /></a>  <a href="thumbnailSearchResults.jsp?<%=qString%>&startNum=<%=(startNum-90)%>&endNum=<%=(startNum-46)%>"><%=(startNum-90)%> - <%=(startNum-46)%></a></p>
</td>
<%
}
%>
 <td align="right">
	<p><a href="thumbnailSearchResults.jsp?<%=qString%>&startNum=<%=startNum%>&endNum=<%=endNum%>"><%=startNum%> - <%=endNum%></a> <a href="thumbnailSearchResults.jsp?<%=qString%>&startNum=<%=startNum%>&endNum=<%=endNum%>"><img src="../images/Black_Arrow_right.png" border="0" align="absmiddle" title="<%=encprops.getProperty("seeNextResults")%>" /></a></p>
	</td>
</tr>
</table>
<%
myShepherd.rollbackDBTransaction();
myShepherd.closeDBTransaction();

if(request.getParameter("noQuery")==null){
%>
<table><tr><td align="left">

<p><strong><%=encprops.getProperty("queryDetails")%></strong></p>

	<p class="caption"><strong><%=encprops.getProperty("prettyPrintResults") %></strong><br /> 
	<%=queryResult.getQueryPrettyPrint().replaceAll("locationField",encprops.getProperty("location")).replaceAll("locationCodeField",encprops.getProperty("locationID")).replaceAll("verbatimEventDateField",encprops.getProperty("verbatimEventDate")).replaceAll("alternateIDField",encprops.getProperty("alternateID")).replaceAll("behaviorField",encprops.getProperty("behavior")).replaceAll("Sex",encprops.getProperty("sex")).replaceAll("nameField",encprops.getProperty("nameField")).replaceAll("selectLength",encprops.getProperty("selectLength")).replaceAll("numResights",encprops.getProperty("numResights")).replaceAll("vesselField",encprops.getProperty("vesselField"))%></p>
	
	<!--  
	<p class="caption"><strong><%=encprops.getProperty("jdoql")%></strong><br /> 
	<%=queryResult.getJDOQLRepresentation()%></p>
	-->

</td></tr></table>
<%
}
%>
 
<br /> <jsp:include page="../footer.jsp" flush="true" />
</div>
</div>
<!-- end page --></div>
<!--end wrapper -->

</body>
</html>


