package org.ecocean.servlet;
import javax.servlet.*;
import javax.servlet.http.*;
import java.io.*;
import org.ecocean.*;


public class EncounterSetColorCode extends HttpServlet {

  public void init(ServletConfig config) throws ServletException {
      super.init(config);
    }


  public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException,IOException {
    doPost(request, response);
  }


  public void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException{
    Shepherd myShepherd=new Shepherd();
    //set up for response
    response.setContentType("text/html");
    PrintWriter out = response.getWriter();
    boolean locked=false;

    String encNum="None";



    encNum=request.getParameter("encounter");
    String colorCode="";
    myShepherd.beginDBTransaction();
    if ((myShepherd.isEncounter(encNum))&&(request.getParameter("colorCode")!=null)) {
      Encounter enc=myShepherd.getEncounter(encNum);
      colorCode=request.getParameter("colorCode").trim();
      try{

        if(colorCode.equals("None")){enc.setColorCode(null);}
        else{
        	enc.setColorCode(colorCode);
		}


      }
      catch(Exception le){
        locked=true;
        myShepherd.rollbackDBTransaction();
        myShepherd.closeDBTransaction();
      }

      if(!locked){
        myShepherd.commitDBTransaction();
        myShepherd.closeDBTransaction();
        out.println(ServletUtilities.getHeader());
        out.println("<strong>Success!</strong> I have successfully changed the colorCode for encounter "+encNum+" to "+colorCode+".</p>");

        out.println("<p><a href=\"http://"+CommonConfiguration.getURLLocation()+"/encounters/encounter.jsp?number="+encNum+"\">Return to encounter "+encNum+"</a></p>\n");
        out.println(ServletUtilities.getFooter());
        String message="The colorCode for encounter "+encNum+" was set to "+colorCode+".";
      }
      else{

        out.println(ServletUtilities.getHeader());
        out.println("<strong>Failure!</strong> This encounter is currently being modified by another user, or an exception occurred. Please wait a few seconds before trying to modify this encounter again.");

        out.println("<p><a href=\"http://"+CommonConfiguration.getURLLocation()+"/encounters/encounter.jsp?number="+encNum+"\">Return to encounter "+encNum+"</a></p>\n");
        out.println(ServletUtilities.getFooter());

      }
                  }
                else {
                  myShepherd.rollbackDBTransaction();
                out.println(ServletUtilities.getHeader());
                out.println("<strong>Error:</strong> I was unable to set the colorCode. I cannot find the encounter that you intended in the database.");
                out.println(ServletUtilities.getFooter());

                  }
                out.close();
                myShepherd.closeDBTransaction();
                }





    }


