/*
 * Wildbook - A Mark-Recapture Framework
 * Copyright (C) 2011-2014 Jason Holmberg
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

package org.ecocean.servlet;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URL;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.concurrent.ThreadPoolExecutor;

import javax.jdo.Query;
import javax.servlet.ServletRequest;
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;

import org.apache.commons.lang.exception.ExceptionUtils;
import org.apache.commons.lang3.math.NumberUtils;
import org.apache.shiro.crypto.SecureRandomNumberGenerator;
import org.apache.shiro.crypto.hash.Sha512Hash;
import org.apache.shiro.util.ByteSource;
import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.Element;
import org.dom4j.io.OutputFormat;
import org.dom4j.io.SAXReader;
import org.dom4j.io.XMLWriter;
import org.ecocean.CommonConfiguration;
import org.ecocean.ContextConfiguration;
import org.ecocean.Encounter;
import org.ecocean.Global;
import org.ecocean.MarkedIndividual;
import org.ecocean.Occurrence;
import org.ecocean.Shepherd;
import org.ecocean.ShepherdProperties;
import org.ecocean.email.old.MailThreadExecutorService;
import org.ecocean.email.old.NotificationMailer;
import org.ecocean.email.old.NotificationMailerHelper;
import org.ecocean.mmutil.StringUtilities;
import org.ecocean.rest.SimpleUser;
import org.ecocean.security.UserFactory;
import org.ecocean.util.Jade4JUtils;
import org.joda.time.DateTime;
import org.joda.time.format.DateTimeFormatter;
import org.joda.time.format.ISODateTimeFormat;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.samsix.database.ConnectionInfo;
import com.samsix.database.Database;
import com.samsix.database.DatabaseException;
import com.sun.syndication.feed.synd.SyndCategory;
import com.sun.syndication.feed.synd.SyndCategoryImpl;
import com.sun.syndication.feed.synd.SyndContent;
import com.sun.syndication.feed.synd.SyndContentImpl;
import com.sun.syndication.feed.synd.SyndEntry;
import com.sun.syndication.feed.synd.SyndEntryImpl;
import com.sun.syndication.feed.synd.SyndFeed;
import com.sun.syndication.io.SyndFeedInput;
import com.sun.syndication.io.SyndFeedOutput;
import com.sun.syndication.io.XmlReader;

//ATOM feed


public class ServletUtilities {
    private static Logger logger = LoggerFactory.getLogger(ServletUtilities.class);
    private static final String DEFAULT_LANG_CODE = "en";


  public static String getHeader(final HttpServletRequest request) {
    try {
      FileReader fileReader = new FileReader(findResourceOnFileSystem("servletResponseTemplate.htm"));
      BufferedReader buffread = new BufferedReader(fileReader);
      String templateFile = "", line;
      StringBuffer SBreader = new StringBuffer();
      while ((line = buffread.readLine()) != null) {
        SBreader.append(line).append("\n");
      }
      fileReader.close();
      buffread.close();
      templateFile = SBreader.toString();

      String context=getContext(request);

      //process the CSS string
      templateFile = templateFile.replaceAll("CSSURL", CommonConfiguration.getCSSURLLocation(request,context));

      //set the top header graphic
      templateFile = templateFile.replaceAll("TOPGRAPHIC", CommonConfiguration.getURLToMastheadGraphic(request, context));

      int end_header = templateFile.indexOf("INSERT_HERE");
      return (templateFile.substring(0, end_header));
    }
    catch (Exception e) {
      //out.println("I couldn't find the template file to read from.");
      e.printStackTrace();
      String error = "<html><body><p>An error occurred while attempting to read from the template file servletResponseTemplate.htm. This probably will not affect the success of the operation you were trying to perform.";
      return error;
    }
  }

  /**
   * At present this just returns our one db connection. I'm wrapping it in this class
   * so that in the future we could have a different db per context and then we can
   * just return that db as we would get the context from the HttpServletRequest.
   *
   * @param request
   * @return
   */
  public static Database getDb(final ServletRequest request) {
      return Global.INST.getDb();
  }

  public static ConnectionInfo getConnectionInfo(final ServletRequest request) {
      return Global.INST.getConnectionInfo();
  }


  public static String getFooter(final String context) {
    try {
      FileReader fileReader = new FileReader(findResourceOnFileSystem("servletResponseTemplate.htm"));
      BufferedReader buffread = new BufferedReader(fileReader);
      String templateFile = "", line;
      StringBuffer SBreader = new StringBuffer();
      while ((line = buffread.readLine()) != null) {
        SBreader.append(line).append("\n");
      }
      fileReader.close();
      buffread.close();
      templateFile = SBreader.toString();
      templateFile = templateFile.replaceAll("BOTTOMGRAPHIC", CommonConfiguration.getURLToFooterGraphic(context));

      int end_header = templateFile.indexOf("INSERT_HERE");
      return (templateFile.substring(end_header + 11));
    } catch (Exception e) {
      //out.println("I couldn't find the template file to read from.");
      e.printStackTrace();
      String error = "An error occurred while attempting to read from an HTML template file. This probably will not affect the success of the operation you were trying to perform.</p></body></html>";
      return error;
    }


  }

  /**
   * Inform (via email) researchers who've logged an interest in encounter.
   * @param request servlet request
   * @param encounterNumber ID of encounter to inform about
   * @param message message to include in email notification
   * @param context webapp context
   */
  public static void informInterestedParties(final HttpServletRequest request, final String encounterNumber, final String message, final String context) {
    Shepherd shep = new Shepherd(context);
    shep.beginDBTransaction();
    if (shep.isEncounter(encounterNumber)) {
      Encounter enc = shep.getEncounter(encounterNumber);
      if(enc.getInterestedResearchers() != null){
        Collection<String> notifyMe = enc.getInterestedResearchers();
        if (!notifyMe.isEmpty()) {
          ThreadPoolExecutor es = MailThreadExecutorService.getExecutorService();
          for (String mailTo : notifyMe) {
            Map<String, String> tagMap = NotificationMailerHelper.createBasicTagMap(request, enc);
            tagMap.put(NotificationMailer.EMAIL_NOTRACK, "number=" + encounterNumber);
            tagMap.put(NotificationMailer.EMAIL_HASH_TAG, StringUtilities.getHashOf(mailTo));
            tagMap.put(NotificationMailer.STANDARD_CONTENT_TAG, message == null ? "" : message);
//            String langCode = ServletUtilities.getLanguageCode(request);
            NotificationMailer mailer = new NotificationMailer(context, null, mailTo, "encounterDataUpdate", tagMap);
            es.execute(mailer);
          }
          es.shutdown();
        }
      }
    }
    shep.rollbackDBTransaction();
    shep.closeDBTransaction();
  }

  /**
   * Inform (via email) researchers who've logged an interest in individual.
   * @param request servlet request
   * @param individualID ID of individual to inform about
   * @param message message to include in email notification
   * @param context webapp context
   */
  public static void informInterestedIndividualParties(final HttpServletRequest request, final String individualID, final String message, final String context) {
    Shepherd shep = new Shepherd(context);
    shep.beginDBTransaction();
    if (shep.isMarkedIndividual(individualID)) {
      MarkedIndividual ind = shep.getMarkedIndividual(individualID);
      if (ind.getInterestedResearchers() != null) {
        Collection<String> notifyMe = ind.getInterestedResearchers();
        if (!notifyMe.isEmpty()) {
          ThreadPoolExecutor es = MailThreadExecutorService.getExecutorService();
          for (String mailTo : notifyMe) {
            Map<String, String> tagMap = NotificationMailerHelper.createBasicTagMap(request, ind);
            tagMap.put(NotificationMailer.EMAIL_NOTRACK, "individual=" + individualID);
            tagMap.put(NotificationMailer.EMAIL_HASH_TAG, StringUtilities.getHashOf(mailTo));
            tagMap.put(NotificationMailer.STANDARD_CONTENT_TAG, message == null ? "" : message);
//            String langCode = ServletUtilities.getLanguageCode(request);
            NotificationMailer mailer = new NotificationMailer(context, null, mailTo, "individualDataUpdate", tagMap);
            es.execute(mailer);
          }
          es.shutdown();
        }
      }
    }
    shep.rollbackDBTransaction();
    shep.closeDBTransaction();
  }

//  public static String getConfigDir(final HttpServletRequest request) {
////      return request.getServletContext().getInitParameter("config.dir");
//      return Global.INST.getInitResources().getString("config.dir", null);
//  }

  //Loads a String of text from a specified file.
  //This is generally used to load an email template for automated emailing
  public static String getText(final String shepherdDataDir, final String fileName, final String langCode) {
    String overrideText=loadOverrideText(shepherdDataDir, fileName, langCode);
    if (overrideText != null) {
      return overrideText;
    }

    try {
        StringBuffer SBreader = new StringBuffer();
        File file = findResourceOnFileSystem(fileName);

        try (FileReader fileReader = new FileReader(file)) {
            try (BufferedReader buffread = new BufferedReader(fileReader)) {
                String line;
                while ((line = buffread.readLine()) != null) {
                    SBreader.append(line + "\n");
                }
            }
        }

        return SBreader.toString();
    } catch (Exception ex) {
        ex.printStackTrace();
        return "";
  }
  }

  //Logs a new ATOM entry
  public static synchronized void addATOMEntry(final String title, final String link, final String description, final File atomFile, final String context) {
    try {

      if (atomFile.exists()) {

        //System.out.println("ATOM file found!");
        /** Namespace URI for content:encoded elements */
//        String CONTENT_NS = "http://www.w3.org/2005/Atom";

        /** Parses RSS or Atom to instantiate a SyndFeed. */
        SyndFeedInput input = new SyndFeedInput();

        /** Transforms SyndFeed to RSS or Atom XML. */
        SyndFeedOutput output = new SyndFeedOutput();

        // Load the feed, regardless of RSS or Atom type
        SyndFeed feed = input.build(new XmlReader(atomFile));

        // Set the output format of the feed
        feed.setFeedType("atom_1.0");

        @SuppressWarnings("unchecked")
        List<SyndEntry> items = feed.getEntries();
        int numItems = items.size();
        if (numItems > 9) {
          items.remove(0);
          feed.setEntries(items);
        }

        SyndEntry newItem = new SyndEntryImpl();
        newItem.setTitle(title);
        newItem.setLink(link);
        newItem.setUri(link);
        SyndContent desc = new SyndContentImpl();
        desc.setType("text/html");
        desc.setValue(description);
        newItem.setDescription(desc);
        desc.setType("text/html");
        newItem.setPublishedDate(new java.util.Date());

        List<SyndCategory> categories = new ArrayList<SyndCategory>();
        if(CommonConfiguration.getProperty("htmlTitle",context)!=null){
            SyndCategory category2 = new SyndCategoryImpl();
            category2.setName(CommonConfiguration.getProperty("htmlTitle",context));
            categories.add(category2);
        }
        newItem.setCategories(categories);
        if(CommonConfiguration.getProperty("htmlAuthor",context)!=null){
            newItem.setAuthor(CommonConfiguration.getProperty("htmlAuthor",context));
        }
        items.add(newItem);
        feed.setEntries(items);

        feed.setPublishedDate(new java.util.Date());


        FileWriter writer = new FileWriter(atomFile);
        output.output(feed, writer);
        writer.toString();

      }
    } catch (IOException ioe) {
          System.out.println("ERROR: Could not find the ATOM file.");
          ioe.printStackTrace();
    } catch (Exception e) {
          System.out.println("Unknown exception trying to add an entry to the ATOM file.");
          e.printStackTrace();
    }

  }

  //Logs a new entry in the library RSS file
  public static synchronized void addRSSEntry(final String title, final String link, final String description, final File rssFile) {
    //File rssFile=new File("nofile.xml");

    try {
        System.out.println("Looking for RSS file: "+rssFile.getCanonicalPath());
      if (rssFile.exists()) {

        SAXReader reader = new SAXReader();
        Document document = reader.read(rssFile);
        Element root = document.getRootElement();
        Element channel = root.element("channel");
        @SuppressWarnings("rawtypes")
        List items = channel.elements("item");
        int numItems = items.size();
        items = null;
        if (numItems > 9) {
          Element removeThisItem = channel.element("item");
          channel.remove(removeThisItem);
        }

        Element newItem = channel.addElement("item");
        Element newTitle = newItem.addElement("title");
        Element newLink = newItem.addElement("link");
        Element newDescription = newItem.addElement("description");
        newTitle.setText(title);
        newDescription.setText(description);
        newLink.setText(link);

        Element pubDate = channel.element("pubDate");
        pubDate.setText((new java.util.Date()).toString());

        //now save changes
        FileWriter mywriter = new FileWriter(rssFile);
        OutputFormat format = OutputFormat.createPrettyPrint();
        format.setLineSeparator(System.getProperty("line.separator"));
        XMLWriter writer = new XMLWriter(mywriter, format);
        writer.write(document);
        writer.close();

      }
    }
    catch (IOException ioe) {
          System.out.println("ERROR: Could not find the RSS file.");
          ioe.printStackTrace();
    }
    catch (DocumentException de) {
          System.out.println("ERROR: Could not read the RSS file.");
          de.printStackTrace();
    } catch (Exception e) {
          System.out.println("Unknown exception trying to add an entry to the RSS file.");
          e.printStackTrace();
    }
  }

  public static File findResourceOnFileSystem(final String resourceName) {
      if (logger.isDebugEnabled()) {
          logger.debug("Looking for resource [" + resourceName + "]");
      }

      URL resourceURL = ServletUtilities.class.getClassLoader().getResource(resourceName);

      if (resourceURL == null) {
          if (logger.isDebugEnabled()) {
              logger.debug("Resource is not found");
          }
          return null;
      }

      if (logger.isDebugEnabled()) {
          logger.debug("Looking for resourceURL [" + resourceURL + "]");
      }

      String resourcePath = resourceURL.getPath();
      if (resourcePath == null) {
          if (logger.isDebugEnabled()) {
              logger.debug("Resource path is null");
          }
          return null;
      }

      File tmp = new File(resourcePath);
      if (tmp.exists()) {
          return tmp;
      }

      if (logger.isDebugEnabled()) {
          logger.debug("Resource URL is not found");
      }

      return null;
  }

    public static SimpleUser getUser(final HttpServletRequest request) {
        //
        // I decided to swallow the error here because I didn't want to bother
        // catching errors in the jsp files which lead me to write this method.
        // Not critical if you want to change it.
        //
        try (Database db = getDb(request)) {
            return UserFactory.getUser(db, NumberUtils.createInteger(request.getRemoteUser()));
        } catch (DatabaseException ex) {
            logger.error("Can't get user from idstring [" + request.getRemoteUser() + "]", ex);
            return null;
        }
    }

  public static boolean isUserAuthorizedForEncounter(final Encounter enc, final HttpServletRequest request) {
    boolean isOwner = false;
    if (request.getUserPrincipal()!=null) {
      isOwner = true;
    }
    return isOwner;
  }

  public static boolean isUserAuthorizedForIndividual(final MarkedIndividual sharky, final HttpServletRequest request) {
    if (request.getUserPrincipal()!=null) {
      return true;
    }
    return false;
  }

  //occurrence
  public static boolean isUserAuthorizedForOccurrence(final Occurrence sharky, final HttpServletRequest request) {
    if (request.getUserPrincipal()!=null) {
      return true;
    }
    return false;
  }


  public static Query setRange(final Query query, final int iterTotal, final int highCount, final int lowCount) {

    if (iterTotal > 10) {

      //handle the normal situation first
      if ((lowCount > 0) && (lowCount <= highCount)) {
        if (highCount - lowCount > 50) {
          query.setRange((lowCount - 1), (lowCount + 50));
        } else {
          query.setRange(lowCount - 1, highCount);
        }
      } else {
        query.setRange(0, 10);
      }


    } else {
      query.setRange(0, iterTotal);
    }
    return query;

  }


  public static String cleanFileName(final String myString){
    return myString.replaceAll("[^a-zA-Z0-9\\.\\-]", "_");
  }

  /*public static String cleanFileName(String aTagFragment) {
    final StringBuffer result = new StringBuffer();

    final StringCharacterIterator iterator = new StringCharacterIterator(aTagFragment);
    char character = iterator.current();
    while (character != CharacterIterator.DONE) {
      if (character == '<') {
        result.append("_");
      } else if (character == '>') {
        result.append("_");
      } else if (character == '\"') {
        result.append("_");
      } else if (character == '\'') {
        result.append("_");
      } else if (character == '\\') {
        result.append("_");
      } else if (character == '&') {
        result.append("_");
      } else if (character == ' ') {
        result.append("_");
      } else if (character == '#') {
        result.append("_");
      } else {
        //the char is not a special one
        //add it to the result as is
        result.append(character);
      }
      character = iterator.next();
    }
    return result.toString();
  }
  */

  public static String preventCrossSiteScriptingAttacks(String description) {
    description = description.replaceAll("<", "&lt;").replaceAll(">", "&gt;");
    description = description.replaceAll("eval\\((.*)\\)", "");
    description = description.replaceAll("[\\\"\\\'][\\s]*((?i)javascript):(.*)[\\\"\\\']", "\"\"");
    description = description.replaceAll("((?i)script)", "");
    return description;
  }

  public static String getDate() {
    DateTime dt = new DateTime();
    DateTimeFormatter fmt = ISODateTimeFormat.date();
    return (fmt.print(dt));
  }

  public static Connection getConnection() throws SQLException {

    Connection conn = null;
    Properties connectionProps = new Properties();
    connectionProps.put("user", CommonConfiguration.getProperty("datanucleus.ConnectionUserName","context0"));
    connectionProps.put("password", CommonConfiguration.getProperty("datanucleus.ConnectionPassword","context0"));


    conn = DriverManager.getConnection(
           CommonConfiguration.getProperty("datanucleus.ConnectionURL","context0"),
           connectionProps);

    System.out.println("Connected to database for authentication.");
    return conn;
}

public static String hashAndSaltPassword(final String clearTextPassword, final String salt) {
    return new Sha512Hash(clearTextPassword, salt, 200000).toHex();
}

public static ByteSource getSalt() {
    return new SecureRandomNumberGenerator().nextBytes();
}

public static Shepherd getShepherd(final HttpServletRequest request) {
    return new Shepherd(getContext(request));
}

public static String getContext(final HttpServletRequest request) {
  Properties contexts = ShepherdProperties.getContextsProperties();

  //check the URL for the context attribute
  //this can be used for debugging and takes precedence
  if (request.getParameter("context") != null) {
    //get the available contexts
    if (contexts.containsKey((request.getParameter("context") + "DataDir"))) {
      return request.getParameter("context");
    }
  }

  //the request cookie is the next thing we check. this should be the primary means of figuring context out
  Cookie[] cookies = request.getCookies();
  if (cookies != null) {
      for (Cookie cookie : cookies) {
          if ("wildbookContext".equals(cookie.getName())) {
              return cookie.getValue();
          }
      }
  }

  //finally, we will check the URL vs values defined in context.properties to see if we can set the right context
  String currentURL=request.getServerName();
  for (int q=0; q < contexts.size(); q++) {
      String thisContext="context"+q;
      ArrayList<String> domainNames = ContextConfiguration.getContextDomainNames(thisContext);
      int numDomainNames=domainNames.size();
      for (int p=0;p<numDomainNames;p++) {
          if (currentURL.indexOf(domainNames.get(p)) != -1) {
              return thisContext;
          }
      }
  }

  return ContextConfiguration.getDefaultContext();
}


    public static String getLanguageCode(final HttpServletRequest request) {
        String context=ServletUtilities.getContext(request);

        ArrayList<String> supportedLanguages;
        if (CommonConfiguration.getSequentialPropertyValues("language", context) != null) {
            supportedLanguages = CommonConfiguration.getSequentialPropertyValues("language", context);
        } else {
            supportedLanguages = new ArrayList<String>();
        }

        //if specified directly, always accept the override
        String langCode = request.getParameter("langCode");
        if (langCode != null && supportedLanguages.contains(langCode)) {
            return langCode;
        }

        //the request cookie is the next thing we check. this should be the primary means of figuring langCode out
        Cookie[] cookies = request.getCookies();
        if (cookies != null) {
            for (Cookie cookie : cookies){
                if ("wildbookLangCode".equals(cookie.getName())) {
                    if (supportedLanguages.contains(cookie.getValue())) {
                        return cookie.getValue();
                    }
                }
            }
        }

        //
        // TODO: finally, we will check the URL vs values defined in context.properties to see if we can set the right context
        // - future - detect browser supported language codes and locale from the HTTPServletRequest object

        //try to detect a default if defined
        if (CommonConfiguration.getProperty("defaultLanguage", context) != null) {
            return CommonConfiguration.getProperty("defaultLanguage", context);
        }

        return DEFAULT_LANG_CODE;
    }


    public static File dataDir(final String context, final String rootWebappPath)
    {
        File webappsDir = new File(rootWebappPath).getParentFile();
        File shepherdDataDir = new File(webappsDir, CommonConfiguration.getDataDirectoryName(context));
        if (!shepherdDataDir.exists()) {
            shepherdDataDir.mkdirs();
        }
        return shepherdDataDir;
    }

    public static File dataDir(final String context, final String rootWebappPath, final String subdir) {
        return new File(dataDir(context, rootWebappPath), subdir);
    }


    private static String renderError(final HttpServletRequest request, final Throwable ex) {
        if (ex == null) {
            return "<NULL>";
        }

        Map<String, Object> map = null;
        map = new HashMap<String, Object>();
        map.put("message", ex.getMessage());
        map.put("stack", ExceptionUtils.getStackTrace(ex));

        try {
            return Jade4JUtils.renderFile(request.getServletContext().getRealPath("/jade/error"), map);
        } catch (Throwable ex2) {
            ex2.printStackTrace();
            return ex2.getMessage();
        }
    }


    /**
     *
     * @param request
     * @param jadeFile can have slashes in it to indicate sub-directories
     * @return
     */
    public static String renderJade(final HttpServletRequest request, final String jadeFile) {
        return renderJade(request, jadeFile, null);
    }


    /**
     *
     * @param request
     * @param jadeFile can have slashes in it to indicate sub-directories
     * @return
     */
    public static String renderJade(final HttpServletRequest request,
                                    final String jadeFile,
                                    final Map<String, Object> vars) {
        try {
            return Jade4JUtils.renderFile(request.getServletContext().getRealPath("/jade/" + jadeFile), vars);
        } catch (Throwable ex) {
            return renderError(request, ex);
        }
    }


//    public static String getText2(final HttpServletRequest request,
//                                  final String fileName) throws IOException {
//        String configDir = getConfigDir(request);
//        String langCode = getLanguageCode(request);
//
//        File file = new File(configDir + "/text/" + langCode + "/" + fileName);
//
//        if (file.exists()) {
//            return OsUtils.readFileToString(file);
//        }
//
//        file = new File(configDir + "/text/" + DEFAULT_LANG_CODE + "/" + fileName);
//        if (file.exists()) {
//            return OsUtils.readFileToString(file);
//        }
//
//        throw new FileNotFoundException(file.getAbsolutePath());
//    }


  private static String loadOverrideText(final String shepherdDataDir, final String fileName, final String langCode) {
      if (logger.isDebugEnabled()) {
          logger.debug("Calling getText with shepherdDataDir [" + shepherdDataDir
                     + "], fileName [" + fileName
                     + "], langCode [" + langCode + "]");
      }

    File configDir = new File("webapps/"+shepherdDataDir+"/WEB-INF/classes/bundles/"+langCode);

    if (logger.isDebugEnabled()) {
        logger.debug("configDir [" + configDir.getAbsolutePath() + "]");
    }

    //
    //sometimes this ends up being the "bin" directory of the J2EE container
    //we need to fix that
    //
    if ((configDir.getAbsolutePath().contains("/bin/"))
         || (configDir.getAbsolutePath().contains("\\bin\\"))) {
      String fixedPath=configDir.getAbsolutePath().replaceAll("/bin", "").replaceAll("\\\\bin", "");

      configDir = new File(fixedPath);

      if (logger.isDebugEnabled()) {
          logger.debug("Fixed configDir to [" + configDir.getAbsolutePath() + "]");
      }
    }

    if (!configDir.exists()) {
        configDir.mkdirs();
    }

    File configFile = new File(configDir, fileName);

    if (logger.isDebugEnabled()) {
        logger.debug("Looking for overriding file [" + configFile.getAbsolutePath() + "]");
    }

    if (!configFile.exists()) {
        if (logger.isDebugEnabled()) {
            logger.debug("File does not exist");
        }
        return null;
    }

    StringBuffer myText = new StringBuffer("");

    FileInputStream fileInputStream = null;
    try {
        fileInputStream = new FileInputStream(configFile);
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(fileInputStream))){
            String line;
            while ((line = reader.readLine()) != null) {
                myText.append(line);
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
    finally {
        if (fileInputStream != null) {
            try {
                fileInputStream.close();
            } catch (Exception e2) {
                e2.printStackTrace();
            }
        }
    }

    return myText.toString();
  }
}
