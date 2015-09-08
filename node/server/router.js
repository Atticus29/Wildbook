//
// TODO: Uncomment when you are ready to use the database.
//
//var mongodb = require('mongodb');
//var dbPort = 27017;
//var dbHost = 'localhost';
//var dbName = 'wildbook';
//
//// establish the database connection
//var db = new mongodb.Db(dbName, new mongodb.Server(dbHost, dbPort, {auto_reconnect: true}), {w: 1});
//    db.open(function(ex, db) {
//    if (ex) {
//        console.log(ex);
//    } else {
//        console.log('connected to database [' + dbName + ']');
//    }
//});

var request = require('request-promise');
var extend = require('extend');
var VError = require('verror');
var moment = require('moment');

//
// Switching to markdowndeep so that we can add target=_blank links in hand-coded html references.
// But this doesn't work for <a href="#" ng-model="terms()">Usage Agreement</a>. It *still* escapes
// the < > in that case. ugh.
//
//var markdown = require("markdown").markdown;
var MarkdownDeep = require('markdowndeep');
var mdd = new MarkdownDeep.Markdown();
mdd.ExtraMode = true;
//
// This will make it so that html code is escaped which we don't want for our Help page.
//
//mdd.SafeMode = true;

var fs = require('fs');

//
// Set up social data grabbing
//
var home = {
    spotlight: {
        name: "Frosty",
        species: "Humpback Whale",
        id: "Cascadia #12492",
        place: "Monterey Bay, CA"
    },
    social: {"instagram": {"feed": []},
             "twitter": {"feed": []}}
};

// Instagram photos
function instagramFeed(config, secrets) {
    var url = "https://api.instagram.com/v1/users/"
        + config.client.social.instagram.user_id
        + "/media/recent/?count="
        + (config.client.social.instagram.feed_count ? config.client.social.instagram.feed_count : 16)
        + "&access_token="
        + secrets.social.instagram.access_token;
//    console.log(url);
    request(url)
    .then(function(response) {
        home.social.instagram.feed = JSON.parse(response).data;
    })
    .catch(function(ex) {
        console.log(ex);
        home.social.instagram.feed = [];
    });
}

//take an encDate data object and return a moment object
function toMoment(encDate) {
    var dateString = encDate.year + '-' + encDate.monthValue + '-' + encDate.dayOfMonth;
    return moment(dateString, 'YYYY-M-D');
}

var Codebird = require("codebird");
function twitterFeed(config) {
    //
    // This will call the following, but with the required authentication
    //    https://api.twitter.com/1.1/statuses/user_timeline.json?screen_name=happyhumpback&count=4
    //
    var cb = new Codebird;
//    cb.setConsumerKey(config.client.social.twitter.consumer_key, secrets.social.twitter.consumer_secret);
    cb.setBearerToken(home.social.twitter.token);
    cb.__call(
        "statuses_userTimeline",
        {
            "screen_name": config.client.social.twitter.id,
            "count": config.client.social.twitter.feed_count || 4
        },
        function (reply) {
            if( Object.prototype.toString.call( reply ) !== '[object Array]' ) {
                console.log("Twitter feed issue:");
                console.log(reply);
                return;
            }
            //
            // Since we are only using the text, just return that. We need the map function anyway
            // to convert the string to html so that we can convert any links.
            //
            home.social.twitter.feed = reply.map(function(value) {
                var tweet = value.text || "";
                var tweetDate = moment(value.created_at, 'dd MMM DD HH:mm:ss ZZ YYYY', 'en').format("ll");
//                console.log(tweet);
                var value;
                var startIndex = 0;
                var index = tweet.indexOf("http");
                if (index < 0) {
                    value = tweet;
                } else {
                    value = "";
                    while (index >= 0) {
                        value += tweet.slice(startIndex, index);
                        startIndex = tweet.indexOf(" ", index);
                        var link;
                        if (startIndex <= -1) {
                            link = tweet.slice(index);
                            index = -1;
                        } else {
                            link = tweet.slice(index, startIndex);
                            index = tweet.indexOf("http", startIndex);
                        }
                        value += '<a href="' + link + '" target="_blank">' + link + '</a>';

                        //
                        // If this is the last then we need to make sure we get the rest of it.
                        //
                        if (index < 0 && startIndex >= 0) {
                            value += tweet.slice(startIndex);
                        }
                    };
                }

                return {
                    text: value,
                    created_at: tweetDate
                };
            });

//            console.log(home.social.twitter.feed);
//            console.log(reply);
        },
        true // this parameter required for AppAuthentication, which is done without the consumer key and secret.
    );
}
//
// End social data grabbing.
//

function makeError(ex) {
    if (typeof ex === "string") {
        console.log(ex);
        return {message: ex};
    }

    console.log(ex.stack);
    return {message: ex.message, stack: ex.stack};
}

function sendError(res, ex, status) {
    //
    // Intentionally reject a promise with undefined just so that it stops
    // but I don't want it to be an exception. So I reject with undefined as
    // a work around. Makes sense to not report an undefined exception to the
    // user anyway should this happen by accident.
    //
    if (! ex) {
        return;
    }

    if (! status) {
        status = 500;
    }

    res.status(status).send(makeError(ex));
}


//note: this will only return *first*
function regexInArray(r, arr) {
  if (!arr) return false;
  for (var i = 0 ; i < arr.length ; i++) {
      if (r.test(arr[i])) return arr[i];
  }
  return false;
}

//does a little logic with voyage data returned for sake of recent sightings/activity
function voyageParser(data) {
    //data.media has a bunch of media, we have to chop up by tags etc (while maintaining ordering)
    if (!data.media) return;
    data.media.reverse();  //in-place, ouch?
    var featured = [];
    var msub = {};
    var msubOrder = [];
    for (var i = 0 ; i < data.media.length ; i++) {
        var f = regexInArray(/^feature/, data.media[i].tags);
        if (f) {
            var fnum = parseInt(f.substr(7));
            if (!featured[fnum]) featured[fnum] = [];
            featured[fnum].push(data.media[i]);
        } else {  //TODO could also filter other stuff, like kill trashed stuff etc
            if (!msub[data.media[i].mediaSubmissionSource]) {
                msubOrder.push(data.media[i].mediaSubmissionSource);
                msub[data.media[i].mediaSubmissionSource] = {
                    user: data.contribMap[data.media[i].mediaSubmissionSource],
                    media: []
                };
            }
            msub[data.media[i].mediaSubmissionSource].media.push(data.media[i]);
            //recent.push(data.media[i]);
        }
    }

    var f2 = [];  //this will get featured items in featureN order (by N)
    for (var i = 0 ; i < featured.length ; i++) {
        if (!featured[i]) continue;
        for (var j = 0 ; j < featured[i].length ; j++) {
            f2.push(featured[i][j]);
        }
    }

    var recent = [];
    for (var i = 0 ; i < msubOrder.length ; i++) {
        recent.push(msub[msubOrder[i]]);
    }

    data.mediaParsed = {
        featured: f2,
        recent: recent
    };
}


module.exports = function(app, config, secrets, debug) {
    var vars = {config: config.client};

    function makeVars(extraVars) {
        return extend({}, vars, extraVars);
    }

    function renderError(res, ex) {
        res.render('error', makeVars({
            error: makeError(ex),
            page: {
                title: "Error"
            }
        }));
    }

    var cb = new Codebird;
    cb.setConsumerKey(config.client.social.twitter.consumer_key, secrets.social.twitter.consumer_secret);
    cb.__call(
        "oauth2_token",
        {},
        function (reply) {
            home.social.twitter.token = reply.access_token;
            twitterFeed(config);
        }
    );

    setInterval(function() {
        twitterFeed(config);
    }, 60*1000);

    instagramFeed(config, secrets);
    setInterval(function() {
        instagramFeed(config, secrets);
    }, 15*60*1000);

    //
    // Main site
    //
    app.get('/', function(req, res) {
        //
        // NOTE: i18n available as req.i18n.t or just req.t
        // Also res.locals.t
        //
        res.render('home', makeVars({
            home: home,
            page: {
                title: req.t("home.title")
            }
        }));
    });

    app.get('/config', function(req,res) {
        res.send(config.client);
    });

    app.get('/submitMedia', function(req, res) {
        res.render('mediasubmission', makeVars({
            page: {
                title: req.t("media.title")
            }
        }));
    });

    app.get("/about", function(req, res) {
        res.render('page', makeVars({
            page: {
                title: req.t("about.title"),
                content: mdd.Transform(fs.readFileSync(config.cust.serverDir + "/docs/About.md", "utf8"))
            }
        }));
    });

    var usageAgreement = mdd.Transform(fs.readFileSync(config.cust.serverDir + "/docs/UsageAgreement.md", "utf8"));

    app.get("/termsModal", function(req, res) {
        res.send(usageAgreement);
    });

    app.get("/terms", function(req, res) {
        res.render('page', makeVars({
            page: {
                title: req.t("terms.title"),
                content: usageAgreement
            }
        }));
    });

    app.get("/help", function(req, res) {
        res.render('page', makeVars({
            page: {
                title: req.t("help.title"),
                content: mdd.Transform(fs.readFileSync(config.cust.serverDir + "/docs/HelpAndFaq.md", "utf8"))
            }
        }));
    });

    app.get("/voyage/*", function(req, res) {
        var arr = req.url.slice(8).split('/');
        var data = { trackID: arr[0], mediaID: arr[1], matchID: arr[2] };
        var url = config.wildbook.authUrl + "/obj/surveytrack/get/voyage/" + req.url.slice(8);
        request(url)
        .then(function(response) {
            data.voyage = JSON.parse(response);
            data.page = {
                title: req.t(voyage.title)
            }
            voyageParser(data.voyage);
            res.render('voyage', makeVars(data));
        })
        .catch(function(ex) {
            renderError(res, new VError(ex, "Trouble getting voyage [" + arr[0] + "]"));
        });
    });

    app.get("/spPasswordReset", function(req, res) {
        var resetData = {
            tokenInfo: {},
            page: {
                title: req.t("passwordReset.title")
            }
        };
        var tokenVarIndex = req.url.indexOf("?sptoken=");
        if(tokenVarIndex > 0) {
            var token = req.url.substr(tokenVarIndex + 9);
            resetData.tokenInfo.token = token;
            request(config.wildbook.url + "/PasswordReset?verify&token=" + token)
            .then(function(response) {
                var data = JSON.parse(response);
                if(!data.resp.success) {
                    console.error("token (" + tokenInfo.token + ") failed to validate: " + tokenInfo.resp.error);
                    delete resetData.tokenInfo.token;
                }
            })
            .catch(function(ex) {
                renderError(res, new VError(ex, "Trouble verifying token"));
            });
        }
        else {
            var emailVarIndex = req.url.indexOf("?email=");
            resetData.tokenInfo.error = "no token passed";
            resetData.passedEmail = emailVarIndex > 0 ? req.url.substr(emailVarIndex + 7) : "";
        }
        res.render('spPasswordReset', makeVars(resetData));
    });

    app.get("/individual/*", function(req, res) {
        var id = req.url.slice(12);
//        http://tomcat:tomcat123@wildbook.happywhale.com/rest/org.ecocean.MarkedIndividual?individualID==%27<search_string>%27

        var url = config.wildbook.authUrl + "/data/individual/get/" + id;
        if (debug) {
            console.log(url);
        }

        request(url)
        .then(function(response) {
            if (debug) {
                console.log("URL [" + url + "]:\n" + JSON.stringify(vars, null, 4));
            }

            var data = JSON.parse(response);
            var first;
            var last;
            for (encounter of data.encounters) {
                theDate = toMoment(encounter.encDate);
                if (!first && !last) {
                    first = theDate;
                    last = theDate;
                }
                if (theDate.isBefore(first)) {
                    first = theDate;
                }
                if (theDate.isAfter(last)) {
                    last = theDate;
                }
            }
            first = (!first) ? "" : first.format("ll");
            last = (!last) ? "" : last.format("ll");

            res.render("individual", makeVars({
                page: {
                    title: data.individual.displayName + " (" + data.individual.speciesDisplayName + ")"
                },
                data: {
                    info: data,
                    firstSeen: first,
                    lastSeend: last
                }
            }));
        })
        .catch(function(ex) {
            renderError(res, new VError(ex, "Can't get individual [" + id + "]"));
        });
    });

    app.get("/user/*", function(req, res) {
        var username = req.url.slice(6);

        var url = config.wildbook.authUrl + "/data/userinfo/get/" + username;

        request(url)
        .then(function(response) {
            var data = JSON.parse(response);
            res.render("userpage", makeVars({
                page: {
                    title: data.user.displayName
                },
                data: {
                    userinfo: data
                }
            }));
        })
        .catch(function(ex) {
            renderError(res, new VError(ex, "Can't get individual [" + id + "]"));
        });
    });

    //
    // Proxy over to wildbook
    //
    app.get('/wildbook/*', function(req, res) {
        //
        // Extract out the * part of the address and forward it through
        // a pipe and request like so. Have to handle error on each section of the pipe.
        //
        var url = config.wildbook.url + req.url.slice(9);

        if (debug) {
            console.log("wildbook GET: " + url);
        }

        req.pipe(request(url))
        .on('error', function(ex) {
            sendError(res, new VError(ex, "Trouble calling GET on [" + url + "]"));
        })
        .pipe(res)
        .on('error', function(ex) {
            console.log("Trouble piping GET result on [" + url + "]");
            sendError(res, ex);
        });
    });

    //
    // Proxy over to wildbook
    //
    app.post('/wildbook/*', function(req, res) {
        //
        // Extract out the * part of the address and forward it through
        // a pipe and request like so. Have to handle error on each section of the pipe.
        //
        var url = config.wildbook.url + req.url.slice(9);

        if (debug) {
            console.log("wildbook POST: " + url);
        }
        console.log(req);

        req.pipe(request.post({uri: url}))
        .pipe(res)
        .on('error', function(ex) {
            console.log("Trouble calling POST result on [" + url + "]");
            sendError(res, ex);
        });


        //
        // TODO: Why does this catching of the error not work? We get funny tomcat error otherwise.
        // Not that bad but?
        //
//        req.pipe(
//            request.post({uri: url})
//            .catch(function(ex) {
//                sendError(res, new VError(ex, "Trouble calling GET on [" + url + "]"));
//            })
//         )
//        .pipe(res)
//        .on('error', function(ex) {
//            console.log("Trouble piping POST result on [" + url + "]");
//            sendError(res, ex);
//        });
    });

    //=================
    // Catch-all
    //=================

    app.get('*', function(req, res) {
        renderError(res, "I'm sorry, the page or resource at [" + req.url + "] you are searching for is currently unavailable.");
    });
};
