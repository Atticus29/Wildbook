
<style>

.mediaasset {
	position: relative;
}
.mediaasset img {
	position: absolute;
	top: 0;
	right: 20px;
	max-width: 350px;
}

.deprecated {
	color: #888;
}

</style>

<%@ page contentType="text/html; charset=utf-8" 
		language="java"
        import="org.ecocean.servlet.ServletUtilities,org.ecocean.*,
org.ecocean.media.*,
java.util.ArrayList,
org.json.JSONObject,
java.util.Properties" %>

<%!

	public Shepherd myShepherd = null;

	private ArrayList<Object> shown = new ArrayList<Object>();

	private String showForm() {
		return "(form)";
	}

	private String niceJson(JSONObject j) {
		if (j == null) return "<b>[none]</b>";
		return "<pre class=\"json\">" + j.toString().replaceAll(",", ",\n") + "</pre>";
	}

	private String showEncounter(Encounter enc) {
		if (enc == null) return "<b>[none]</b>";
		String h = "<div class=\"encounter shown\"><a target=\"_new\" href=\"encounters/encounter.jsp?number=" + enc.getCatalogNumber() + "\">Encounter <b>" + enc.getCatalogNumber() + "</b></a>";
		if ((enc.getAnnotations() != null) && (enc.getAnnotations().size() > 0)) {
			h += "<div>Annotations:<ul>";
			for (int i = 0 ; i < enc.getAnnotations().size() ; i++) {
				h += "<li><a href=\"obrowse.jsp?type=Annotation&id=" + enc.getAnnotations().get(i).getId() + "\">Annotation " + enc.getAnnotations().get(i).getId() + "</a></li>";
			}
			h += "</ul></div>";
		}
		return h + "</div>";
	}

	private String showFeature(Feature f) {
		if (f == null) return "<b>[none]</b>";
		if (shown.contains(f)) return "<div class=\"feature shown\">Feature <b>" + f.getId() + "</b></div>";
		shown.add(f);
		String h = "<div class=\"feature\">Feature <b>" + f.getId() + "</b><ul>";
		h += "<li>type: <b>" + ((f.getType() == null) ? "[null] (unity)" : f.getType()) + "</b></li>";
		h += "<li>" + showMediaAsset(f.getMediaAsset()) + "</li>";
		h += "<li>" + showAnnotation(f.getAnnotation()) + "</li>";
		h += "<li>parameters: " + niceJson(f.getParameters()) + "</li>";
		return h + "</ul></div>";
	}

	private String showAnnotation(Annotation ann) {
		if (ann == null) return "annotation: <b>[none]</b>";
		if (shown.contains(ann)) return "<div class=\"annotation shown\">Annotation <b>" + ann.getId() + "</b></div>";
		shown.add(ann);
		String h = "<div class=\"annotation\">Annotation <b>" + ann.getId() + "</b><ul>";
		h += "<li>species: <b>" + ((ann.getSpecies() == null) ? "[null]" : ann.getSpecies()) + "</b></li>";
		h += "<li>features: " + showFeatureList(ann.getFeatures()) + "</li>";
		h += "<li>encounter: " + showEncounter(Encounter.findByAnnotation(ann, myShepherd)) + "</li>";
		h += "<li class=\"deprecated\">" + showMediaAsset(ann.getMediaAsset()) + "</li>";
		return h + "</ul></div>";
	}

	private String showLabels(ArrayList<String> l) {
		if ((l == null) || (l.size() < 1)) return "[none]";
		String h = "<ul>";
		for (int i = 0 ; i < l.size() ; i++) {
			h += "<li>" + l.get(i) + "</li>";
		}
		return h + "</ul>";
	}

	private String showMediaAssetList(ArrayList<MediaAsset> l) {
		if ((l == null) || (l.size() < 1)) return "[none]";
		return "";
	}

	private String showFeatureList(ArrayList<Feature> l) {
		if ((l == null) || (l.size() < 1)) return "[none]";
		String h = "<ul>";
		for (int i = 0 ; i < l.size() ; i++) {
			h += "<li>" + showFeature(l.get(i)) + "</li>";
		}
		return h + "</ul>";
	}

	private String showMediaAsset(MediaAsset ma) {
		if (ma == null) return "asset: <b>[none]</b>";
		if (shown.contains(ma)) return "<div class=\"mediaasset shown\">MediaAsset <b>" + ma.getId() + "</b></div>";
		shown.add(ma);
		String h = "<div class=\"mediaasset\">MediaAsset <b>" + ma.getId() + "</b><ul>";
		h += "<img src=\"" + ma.webURL() + "\" />";
		h += "<li>store: <b>" + ma.getStore() + "</b></li>";
		h += "<li>labels: <b>" + showLabels(ma.getLabels()) + "</b></li>";
		h += "<li>features: " + showFeatureList(ma.getFeatures()) + "</li>";
		h += "<li>parameters: " + niceJson(ma.getParameters()) + "</li>";
		return h + "</ul></div>";
	}
%>

<%

myShepherd = new Shepherd("context0");

/*
String context="context0";
context=ServletUtilities.getContext(request);

  //setup our Properties object to hold all properties
  //String langCode = "en";
  String langCode=ServletUtilities.getLanguageCode(request);
  


//set up the file input stream
  Properties props = new Properties();
  //props.load(getClass().getResourceAsStream("/bundles/" + langCode + "/login.properties"));
  props = ShepherdProperties.getProperties("login.properties", langCode,context);
*/

String id = request.getParameter("id");
String type = request.getParameter("type");
if (type == null) type = "Encounter";
if (id == null) {
	out.println(showForm());
	return;
}

boolean needForm = false;

if (type.equals("Encounter")) {
	try {
		Encounter enc = ((Encounter) (myShepherd.getPM().getObjectById(myShepherd.getPM().newObjectIdInstance(Encounter.class, id), true)));
		out.println(showEncounter(enc));
	} catch (Exception ex) {
		out.println("<p>ERROR: " + ex.toString() + "</p>");
		needForm = true;
	}

} else if (type.equals("MediaAsset")) {
	try {
		MediaAsset ma = ((MediaAsset) (myShepherd.getPM().getObjectById(myShepherd.getPM().newObjectIdInstance(MediaAsset.class, id), true)));
		out.println(showMediaAsset(ma));
	} catch (Exception ex) {
		out.println("<p>ERROR: " + ex.toString() + "</p>");
		needForm = true;
	}

} else if (type.equals("Annotation")) {
	try {
		Annotation ann = ((Annotation) (myShepherd.getPM().getObjectById(myShepherd.getPM().newObjectIdInstance(Annotation.class, id), true)));
		out.println(showAnnotation(ann));
	} catch (Exception ex) {
		out.println("<p>ERROR: " + ex.toString() + "</p>");
		needForm = true;
	}

} else if (type.equals("Feature")) {
	try {
		Feature f = ((Feature) (myShepherd.getPM().getObjectById(myShepherd.getPM().newObjectIdInstance(Feature.class, id), true)));
		out.println(showFeature(f));
	} catch (Exception ex) {
		out.println("<p>ERROR: " + ex.toString() + "</p>");
		needForm = true;
	}
} else {
	out.println("<p>unknown type</p>>");
	needForm = true;
}


if (needForm) out.println(showForm());

%>

