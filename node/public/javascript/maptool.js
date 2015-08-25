'use strict'

var maptool = (function () {
    var config = null;
    var encIcons = {};
    var vesselIcons = {};

    function init(conf) {
        config = conf;
    }

    var MapWrap = function(theMap) {
        var map = theMap;

        var voyages;
        var currentPopup = null;

        var encounters;

        function fitToData(maxZoom) {
            var data = [];
            if (encounters) {
                data.push(encounters);
            }

            if (voyages) {
                data.push(voyages);
            }

            if (data.length === 0) {
                map.fitWorld();
                return;
            }

            if (! maxZoom) {
                maxZoom = 8;
            }

            var group = new L.featureGroup(data);
            map.fitBounds(group.getBounds(), {maxZoom: maxZoom});
        }

        L.easyButton("glyphicon-globe", function( buttonArg, mapArg ) {
            fitToData();
          }).addTo(map);


        function getVoyageLayer() {
            if (voyages) {
                return voyages;
            }

            voyages = new L.MarkerClusterGroup({
                iconCreateFunction: function(cluster) {
                    var iconDef = config.voyage.vessel.icons.boat;
                    return new L.divIcon({className: 'individual-cluster',
                                          iconSize: iconDef.iconSize,
                                          iconAnchor: iconDef.iconAnchor,
                                          html: '<div class="individual-cluster-count"><span>'
                                              + cluster.getChildCount()
                                              + '</span></div><img src="'
                                              + iconDef.iconUrl + '"/>'});
                }
            });
            map.addLayer(voyages);
            return voyages;
        }

        function getEncounterLayer() {
            if (encounters) {
                return encounters;
            }

            encounters = new L.MarkerClusterGroup({
                iconCreateFunction: function(cluster) {
                    var iconDef = config.encounter.icons.cluster;
                    return new L.divIcon({className: 'individual-cluster',
                                          iconSize: iconDef.iconSize,
                                          iconAnchor: iconDef.iconAnchor,
                                          html: '<div class="individual-cluster-count"><span>'
                                              + cluster.getChildCount()
                                              + '</span></div><img src="'
                                              + iconDef.iconUrl + '"/>'});
                }
            });
            map.addLayer(encounters);
            return encounters;
        }

        map.on("popupopen", function(evt) {
            currentPopup = evt.popup;

            //
            // This is not working, I don't know why. Oh well.
            //
            $(currentPopup._container).keypress(function(evt) {
                if (evt.keyCode == 27) {
                    closeCurrentPopup();
                }
            });

            //
            // Not sure I want this afterall. I think it's fine to leave the popup on until
            // they close it (or open another popup)
            //
//            currentPopup._container.onmouseleave = function(evt) {
//                closeCurrentPopup();
//            };
        });

        function closeCurrentPopup() {
            if (!currentPopup) {
                return;
            }

            currentPopup._source.closePopup();
            currentPopup = null;
        }

        //
        // To close the current popup. popup source is marker. can also do marker.closePopup.
        //
//        if (currentPopup != null) currentPopup._source.closePopup();

        function getEncounterIcon(species) {
            if (encIcons[species]) {
                return encIcons[species];
            }

            if (config.encounter.icons[species]) {
                var icon = {icon: L.icon(config.encounter.icons[species])};
                encIcons[species] = icon;
                return icon;
            }

            getEncounterIcon("default");
        }

        function getVesselIcon(type) {
            if (vesselIcons[type]) {
                return vesselIcons[type];
            }

            if (config.voyage.vessel.icons[type]) {
                var icon = {icon: L.icon(config.voyage.vessel.icons[type])};
                vesselIcons[type] = icon;
                return icon;
            }

            getVesselIcon("default");
        }

        function getMarker(latlng, icon, popup) {
            var marker = L.marker(latlng, icon);
            if (popup) {
                marker.bindPopup(popup);

                marker.on('mouseover', function (evt) {
                    closeCurrentPopup();
                    this.openPopup();
                });
            }

            return marker;
        }

        function addEncounter(encounter) {
            //
            // Just passed in a latlng because we have no other info. Also use default icon.
            // Later, we can make sure we pass in a species somehow if we have it.
            //
            var layer = getEncounterLayer();

            if (Array.isArray(encounter)) {
                layer.addLayer(getMarker(encounter, getEncounterIcon("default")));
                return;
            }

            if (! encounter.latitude || ! encounter.longitude) {
                return;
            }

            var iconIndividual = encounter.individual ? getEncounterIcon(encounter.individual.species) : getEncounterIcon('default');
            var nameIndividual = encounter.individual ? encounter.individual.displayName : 'unknown';

            var popup = $("<dl>", { class: 'individual-popup' });
            popup.append($("<dt/>", { class: 'popup-avatar-label' }).text('Individual Sighted'));
            if (encounter.individual) {
                popup.append($("<dd/>", { class: 'popup-avatar' }).append(app.beingDiv(encounter.individual)));
            }
            popup.append($("<dd/>", { class: 'popup-name' }).text(nameIndividual));

            popup.append($("<dt/>", { class: 'popup-date-label' }).text('Date Sighted'));
            popup.append($("<dd/>", { class: 'popup-date' }).text(moment(encounter.dateInMilliseconds).format('LL')));

            popup.append($("<dt/>", { class: 'popup-location-date'}).text('Sighting Location'));
            popup.append($("<dd/>", { class: 'popup-location'}).text(encounter.verbatimLocation));

            popup.append($("<dt/>", { class: 'popup-submitter-label' }).text('Submitted By'));
            popup.append($("<dd/>", { class: 'popup-submitter'}).append(app.beingDiv(encounter.submitter)));

            layer.addLayer(getMarker([encounter.latitude, encounter.longitude], iconIndividual, popup[0]));
        }

        function addVoyage(voyage) {
            if (! voyage.points || voyage.points.length === 0) {
                return;
            }

            var vPoints = [];
            voyage.points.forEach(function(point) {
                vPoints.push([point.latitude, point.longitude]);
            })

            var timetrack = L.polyline(vPoints, {color: 'red'});

            var popup = $("<div>");
            popup.append($("<span>").addClass("sight-data-text").text(voyage.name));

            var point = vPoints[vPoints.length-1];
            var marker = getMarker(point, getVesselIcon("boat"), popup[0]);
            getVoyageLayer().addLayer(new L.featureGroup([timetrack, marker]));
        }

        return {
            map: map,
            addEncounter: addEncounter,
            addVoyage: addVoyage,
            fitToData: fitToData,
            clear: function() {
                map.removeLayer(encounters);
                map.removeLayer(voyages);
                encounters = null;
                voyages = null;
            }
        };
    };


    function createMap(divId) {
        var map = L.map(divId, {scrollWheelZoom: false});

        L.tileLayer('http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; <a href="http://openstreetmap.org/copyright">OpenStreetMap</a> contributors',
            maxZoom: 18
        }).addTo(map);

        return new MapWrap(map);
    }

    return {
        init: init,
        createMap: createMap
    };
})();
