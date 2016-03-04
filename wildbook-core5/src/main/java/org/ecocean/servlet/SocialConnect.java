package org.ecocean.servlet;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.ecocean.CommonConfiguration;
import org.ecocean.Shepherd;
import org.ecocean.User;
//import org.ecocean.*;
import org.ecocean.security.SocialAuth;
import org.pac4j.core.context.J2EContext;
import org.pac4j.core.context.WebContext;
import org.pac4j.oauth.client.FacebookClient;
//import org.pac4j.oauth.client.YahooClient;
import org.pac4j.oauth.credentials.OAuthCredentials;
import org.pac4j.oauth.profile.facebook.FacebookProfile;
//import org.pac4j.oauth.profile.yahoo.YahooProfile;
import org.scribe.model.OAuthRequest;
import org.scribe.model.Response;
import org.scribe.model.Token;
import org.scribe.model.Verb;
import org.scribe.model.Verifier;
import org.scribe.oauth.OAuthService;



/**
 * Uses JSecurity to authenticate a user
 * If user can be authenticated successfully
 * forwards user to /secure/index.jsp
 *
 * If user cannot be authenticated then forwards
 * user to the /login.jsp which will display
 * an error message
 *
 */
 public class SocialConnect extends javax.servlet.http.HttpServlet implements javax.servlet.Servlet {
   static final long serialVersionUID = 1L;

    /* (non-Java-doc)
     * @see javax.servlet.http.HttpServlet#HttpServlet()
     */
    public SocialConnect() {
        super();
    }

    /* (non-Java-doc)
     * @see javax.servlet.http.HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
     */
    @Override
    protected void doGet(final HttpServletRequest request, final HttpServletResponse response) throws ServletException, IOException {

        doPost(request, response);
    }

    /* (non-Java-doc)
     * @see javax.servlet.http.HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
     */
    @Override
    protected void doPost(final HttpServletRequest request, final HttpServletResponse response) throws ServletException, IOException {
    HttpSession session = request.getSession(true);

    PrintWriter out = response.getWriter();
        String context = "context0";
        Shepherd myShepherd = new Shepherd(context);
        //myShepherd.beginDBTransaction();

        String socialType = request.getParameter("type");

        String username = null;
        if (request.getUserPrincipal() != null) username = request.getUserPrincipal().getName();
        if (username == null) username = "";
        User user = myShepherd.getUserOLD(username);

        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        if ("facebook".equals(socialType)) {
        FacebookClient fbclient = null;
        try {
            fbclient = SocialAuth.getFacebookClient(context);
        } catch (Exception ex) {
            System.out.println("SocialAuth.getFacebookClient threw exception " + ex.toString());
        }
            WebContext ctx = new J2EContext(request, response);
            //String callbackUrl = "http://localhost.wildme.org/a/SocialConnect?type=facebook";
            String callbackUrl = "http://" + CommonConfiguration.getURLLocation(request) + "/SocialConnect?type=facebook";
            if (request.getParameter("disconnect") != null) callbackUrl += "&disconnect=1";
            fbclient.setCallbackUrl(callbackUrl);

            OAuthCredentials credentials = null;
            try {
                credentials = fbclient.getCredentials(ctx);
            } catch (Exception ex) {
                System.out.println("caught exception on facebook credentials: " + ex.toString());
            }

            if (credentials != null) {
                FacebookProfile facebookProfile = fbclient.getUserProfile(credentials, ctx);
                User fbuser = myShepherd.getUserBySocialId("facebook", facebookProfile.getId());
                System.out.println("getId() = " + facebookProfile.getId() + " -> user = " + fbuser);
if (fbuser != null) System.out.println("user = " + user.getUsername() + "; fbuser = " + fbuser.getUsername());
                if ((fbuser != null) && (fbuser.getUsername().equals(user.getUsername())) && (request.getParameter("disconnect") != null)) {
                    fbuser.unsetSocial("facebook");
                    //myShepherd.getPM().makePersistent(user);
                    session.setAttribute("message", "disconnected from facebook");
                    response.sendRedirect("myAccount.jsp");
                    return;

                } else if (fbuser != null) {
                    session.setAttribute("error", "looks like this account is already connected to an account");
                    response.sendRedirect("myAccount.jsp");
                    return;

                } else {  //lets do this
                    user.setSocial("facebook", facebookProfile.getId());
                    //myShepherd.getPM().makePersistent(user);
                    session.setAttribute("message", "connected to facebook");
                    response.sendRedirect("myAccount.jsp");
                    return;
                }
            } else {

System.out.println("*** trying redirect?");
                try {
                    fbclient.redirect(ctx, false, false);
                } catch (Exception ex) {
                    System.out.println("caught exception on facebook processing: " + ex.toString());
                }
                return;
            }


        } else if ("flickr".equals(socialType)) {
            String overif = request.getParameter("oauth_verifier");
            String otoken = request.getParameter("oauth_token");

            OAuthService service = null;
            String callbackUrl = "http://" + CommonConfiguration.getURLLocation(request) + "/SocialConnect?type=flickr";
            if (request.getParameter("disconnect") != null) callbackUrl += "&disconnect=1";
            try {
                service = SocialAuth.getFlickrOauth(context, callbackUrl);
            } catch (Exception ex) {
                System.out.println("SocialAuth.getFlickrOauth() threw exception " + ex.toString());
            }
            //WebContext ctx = new J2EContext(request, response);
            //String callbackUrl = "http://localhost.wildme.org/a/SocialConnect?type=facebook";
/*
            String callbackUrl = "http://" + CommonConfiguration.getURLLocation(request) + "/SocialConnect?type=flickr";
            if (request.getParameter("disconnect") != null) callbackUrl += "&disconnect=1";
            yclient.setCallbackUrl(callbackUrl);
*/

            if (overif == null) {
                Token requestToken = service.getRequestToken();
                session.setAttribute("requestToken", requestToken);
       System.out.println("==============================================requestToken = " + requestToken);
                String authorizationUrl = service.getAuthorizationUrl(requestToken) + "&perms=read";
System.out.println(authorizationUrl);

//http://localhost.wildme.org/a/SocialConnect?type=xxflickr&oauth_token=72157652805581432-a5b8f3598c13e2a6&oauth_verifier=d3325223f923442e
                response.sendRedirect(authorizationUrl);
                return;

            } else {
System.out.println("verifier -> " + overif);
                Token requestToken = (Token)session.getAttribute("requestToken");
                Verifier verifier = new Verifier(overif);
                Token accessToken = service.getAccessToken(requestToken, verifier);
       System.out.println("==============================================requestToken = " + requestToken);
       System.out.println("=- - - - - - - - - - - - - -==================accessToken = " + accessToken);
System.out.println("-----------------------------------------otoken= " + otoken);
       System.out.println("verifier = " + verifier);

                OAuthRequest oRequest = new OAuthRequest(Verb.GET, SocialAuth.FLICKR_URL);
                oRequest.addQuerystringParameter("method", "flickr.test.login");
                service.signRequest(accessToken, oRequest);
                Response oResponse = oRequest.send();
System.out.println("GOT RESPONSE!!!!!!!!!!!!!!!!!!!!!!!!!!");
System.out.println(oResponse.getBody());

                String fusername = null;   //should we use <user id="XXXXXXXXX"> instead?  TODO
                int i = oResponse.getBody().indexOf("<username>");
                if (i > -1) {
                    fusername = oResponse.getBody().substring(i + 10);
                    i = fusername.indexOf("</username>");
                    if (i > -1) fusername = fusername.substring(0, i);
                }
                User fuser = myShepherd.getUserBySocialId("flickr", fusername);
   System.out.println("fusername = " + fusername + " -> user = " + fuser);
if (fuser != null) System.out.println("user = " + user.getUsername() + "; fuser = " + fuser.getUsername());
                if ((fuser != null) && (fuser.getUsername().equals(user.getUsername())) && (request.getParameter("disconnect") != null)) {
                    fuser.unsetSocial("flickr");
                    session.setAttribute("message", "disconnected from flickr");
                    response.sendRedirect("myAccount.jsp");
                    return;

                } else if (fuser != null) {
                    session.setAttribute("error", "looks like this account is already connected to an account");
                    response.sendRedirect("myAccount.jsp");
                    return;

                } else {  //lets do this
                    user.setSocial("flickr", fusername);
                    //myShepherd.getPM().makePersistent(user);
                    session.setAttribute("message", "connected to flickr");
                    response.sendRedirect("myAccount.jsp");
                    return;
                }

            }

///
/*
    Verifier verifier = new Verifier(in.nextLine());
    System.out.println();

    // Trade the Request Token and Verfier for the Access Token
    System.out.println("Trading the Request Token for an Access Token...");
    Token accessToken = service.getAccessToken(requestToken, verifier);
    System.out.println("Got the Access Token!");
    System.out.println("(if your curious it looks like this: " + accessToken + " )");
    System.out.println("(you can get the username, full name, and nsid by parsing the rawResponse: " + accessToken.getRawResponse() + ")");
    System.out.println();

    // Now let's go and ask for a protected resource!
    System.out.println("Now we're going to access a protected resource...");
    OAuthRequest request = new OAuthRequest(Verb.GET, FLICKR_URL);
    request.addQuerystringParameter("method", "flickr.test.login");
    service.signRequest(accessToken, request);
    Response response = request.send();
    System.out.println("Got it! Lets see what we found...");
    System.out.println();
    System.out.println(response.getBody());
*/



/*
            OAuthCredentials credentials = null;
            try {
                credentials = yclient.getCredentials(ctx);
            } catch (Exception ex) {
                System.out.println("caught exception on yahoo credentials: " + ex.toString());
            }

            if (credentials != null) {
                YahooProfile yahooProfile = yclient.getUserProfile(credentials, ctx);
                User yuser = myShepherd.getUserBySocialId("yahoo", yahooProfile.getId());
                System.out.println("getId() = " + yahooProfile.getId() + " -> user = " + yuser);
if (yuser != null) System.out.println("user = " + user.getUsername() + "; yuser = " + yuser.getUsername());
                if ((yuser != null) && (yuser.getUsername().equals(user.getUsername())) && (request.getParameter("disconnect") != null)) {
                    yuser.unsetSocial("yahoo");
                    //myShepherd.getPM().makePersistent(user);
                    session.setAttribute("message", "disconnected from flickr");
                    response.sendRedirect("myAccount.jsp");
                    return;

                } else if (yuser != null) {
                    session.setAttribute("error", "looks like this account is already connected to an account");
                    response.sendRedirect("myAccount.jsp");
                    return;

                } else {  //lets do this
                    user.setSocial("flickr", yahooProfile.getId());
                    //myShepherd.getPM().makePersistent(user);
                    session.setAttribute("message", "connected to flickr");
                    response.sendRedirect("myAccount.jsp");
                    return;
                }
            } else {

System.out.println("*** trying redirect?");
                try {
                    yclient.redirect(ctx, false, false);
                } catch (Exception ex) {
                    System.out.println("caught exception on yahoo processing: " + ex.toString());
                }
                return;
            }

*/


        } else {
            session.setAttribute("error", "invalid type");
         //response.sendRedirect("http://" + CommonConfiguration.getURLLocation(request) + "/login.jsp");
         response.sendRedirect("login.jsp");
            return;
        }


        //out.println("ok????");
    }
}