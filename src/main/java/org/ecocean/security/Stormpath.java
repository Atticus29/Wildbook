package org.ecocean.security;




import java.util.HashMap;

import org.ecocean.User;
import org.ecocean.Util;
import org.ecocean.rest.UserController;

import com.stormpath.sdk.account.Account;
import com.stormpath.sdk.account.AccountList;
import com.stormpath.sdk.api.ApiKey;
import com.stormpath.sdk.api.ApiKeys;
import com.stormpath.sdk.application.Application;
import com.stormpath.sdk.application.ApplicationList;
import com.stormpath.sdk.application.Applications;
import com.stormpath.sdk.authc.AuthenticationResult;
import com.stormpath.sdk.authc.UsernamePasswordRequest;
import com.stormpath.sdk.client.Client;
import com.stormpath.sdk.client.Clients;
import com.stormpath.sdk.directory.CustomData;
import com.stormpath.sdk.resource.ResourceException;
import com.stormpath.sdk.tenant.Tenant;

/************************************************************
      DOCS:  http://docs.stormpath.com/java/quickstart/
*************************************************************/

public class Stormpath {

    /*  note: docs say "The client instance is intended to be an application singleton. You should reuse this instance throughout your application code.
        You should not create multiple Client instances as it could negatively affect caching." ... so this is what we reuse */
    private static Client myClient = null;

    // we cache the application too.  is this lame?
    private static Application myApplication = null;

    public static Client getClient(final String configDir) {
        if (myClient != null) return myClient;

        ApiKey apiKey = ApiKeys.builder().setFileLocation(configDir + "/stormpathApiKey.properties").build();
        myClient = Clients.builder().setApiKey(apiKey).build();
        //If using Google App Engine, you must use Basic authentication:
        //Client client = Clients.builder().setApiKey(apiKey)
        //    .setAuthenticationScheme(AuthenticationScheme.BASIC)
        //    .build();
        return myClient;
    }

/*
    public Application getApplication() {
        if (myClient == null) return null;
        return getApplication(myClient);
    }
*/

    //just get default (no appName passed)
    public static Application getApplication(final Client client) {
        return getApplication(client, null);
    }

    public static Application getApplication(final Client client, String appName) {
        //NOTE DANGER! this caching assumes only one application will be used ever.  lame? maybe!
        if (myApplication != null) return myApplication;

        if (appName == null) appName = "animalus";  //default  TODO ok?  read from properties?  etc.
        Tenant tenant = client.getCurrentTenant();
        ApplicationList applications = tenant.getApplications(
            Applications.where(Applications.name().eqIgnoreCase(appName))
        );
        myApplication = applications.iterator().next();
        return myApplication;
    }

    //note: username and custom are optional (username becomes email address if not provided); the rest are required
    public static Account createAccount(final Client client, final String givenName, final String surname, final String email, final String password, final String username, final HashMap<String,Object> custom) throws Exception {
        if (isEmpty(givenName) || isEmpty(surname) || isEmpty(email) || isEmpty(password)) throw new Exception("missing required fields to create user");
        Account account = client.instantiate(Account.class);
        account.setGivenName(givenName);
        account.setSurname(surname);
        account.setEmail(email);
        account.setPassword(password);
        if (!isEmpty(username)) account.setUsername(username);

        if (custom != null) {
            CustomData customData = account.getCustomData();
            for (String k : custom.keySet()) {
                customData.put(k, custom.get(k));
            }
        }
        Application app = getApplication(client);
        app.createAccount(account);
        return account;
    }


    //convenience by-username version of below
    public static AccountList getAccounts(final Client client, final String username) {
        HashMap<String, Object> q = new HashMap<String, Object>();
        q.put("username", username);
        return getAccounts(client, q);
    }

    public static AccountList getAccounts(final Client client, final HashMap<String, Object> q) {
        Application app = getApplication(client);
        return app.getAccounts(q);
    }


    public static Account createAccount(final Client client, final User user) throws Exception {
        String[] name = UserController.parseName(user.getFullName());
        HashMap<String,Object> h = new HashMap<String,Object>();
        h.put("creationNote", "created from Wildbook User");
        return createAccount(client, name[0], name[1], user.getEmailAddress(), randomInitialPassword(), user.getUsername(), h);
    }

    //satisfies Stormcloud requirements, and is sufficiently unguessable
    public static String randomInitialPassword() {
        return "X" + Util.generateUUID() + "X";
    }

    public static Account sendPasswordResetEmail(final Client client, final String email) {
        Application app = getApplication(client);
        return app.sendPasswordResetEmail(email);
    }

    //note: "username" can also be email, apparently
    public static Account loginAccount(final Client client, final String username, final String password) throws ResourceException {
        Application app = getApplication(client);
        UsernamePasswordRequest req = new UsernamePasswordRequest(username, password);
        AuthenticationResult res = app.authenticateAccount(req);
        return res.getAccount();
    }

    private static boolean isEmpty(final String s) {
        return ((s == null) || s.equals(""));
    }


}
