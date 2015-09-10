/*
 * The Shepherd Project - A Mark-Recapture Framework
 * Copyright (C) 2011 Jason Holmberg
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

import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.ecocean.CommonConfiguration;
import org.ecocean.Shepherd;
import org.ecocean.User;
import org.ecocean.media.MediaAsset;

public class UserInfo extends HttpServlet {

    @Override
    public void init(final ServletConfig config) throws ServletException {
        super.init(config);
    }

    @Override
    public void doGet(final HttpServletRequest request, final HttpServletResponse response) throws ServletException, IOException {
        doPost(request, response);
    }

    @Override
    public void doPost(final HttpServletRequest request, final HttpServletResponse response) throws ServletException, IOException {
        String context="context0";
        //context=ServletUtilities.getContext(request);
        Shepherd myShepherd = new Shepherd(context);
        //set up for response
        response.setContentType("text/html");
        PrintWriter out = response.getWriter();

        String username = request.getParameter("username").trim();

        User user = myShepherd.getUserOLD(username);

        if (!CommonConfiguration.showUsersToPublic(context)) {
            out.println("<p>invalid</p>");
        } else if (user == null) {
            //out.println(ServletUtilities.getHeader(request));
            out.println("Error: bad username " + username);
            //out.println(ServletUtilities.getFooter(context));
        } else {
            String profilePhotoUrl = getPhotoURL(user);

            String displayName = username;
            if (user.getFullName() != null) displayName = user.getFullName();

            String h = "<div id=\"popup-bio-" + username + "\" title=\"" + displayName + "\" class=\"popup-bio\">";
            h += "<div class=\"photo-name-wrapper\"><img src=\"" + profilePhotoUrl + "\" /><div class=\"name\">" + displayName + "</div></div>";
            if (user.getAffiliation() != null) h += "<div class=\"bio-attribute affiliation\"><strong>Affiliation:</strong> " + user.getAffiliation() + "</div>";
            if (user.getUserProject() != null) h += "<div class=\"bio-attribute project\"><strong>Research Project:</strong> " + user.getUserProject() + "</div>";
            if (user.getUserURL() != null) h += "<div class=\"bio-attribute url\"><strong>Web site:</strong> <a href=\"" + user.getUserURL() + "\">" + user.getUserURL() + "</a></div>";
            if (user.getUserStatement() != null) h += "<div class=\"user-statement\">" + user.getUserStatement() + "</div>";
            h += "</div>";
            out.println(h);
        }

        out.close();
    }

    private String getPhotoURL(final User user) {
        MediaAsset image = user.getUserImage();
        if (image != null) {
            return image.webPathString();
        }

        // fallback
        File baseDir = new File(getServletContext().getRealPath("/"));
        return "/" + baseDir.getName() + "/images/empty_profile.jpg";
    }
}
