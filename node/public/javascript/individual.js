'use strict';

var individualPage = (function () {
    function init(config, photos, encounters, voyages) {
        // build photos array for phototool
        var fotos = [];

        if (photos) {
            photos.forEach(function(photo){
                fotos.push({src: photo.midUrl, w: 0, h:0});
            });
        }

        phototool.setPhotos(fotos);

        var map = maptool.createMap('map-sightings');
        //
        // Add encounters to map and set view to be centered around these encounters.
        //
        var individuals = [];
        if (encounters) {
            encounters.forEach(function(encounter) {
                map.addEncounter(encounter);
            });
        }

        if (voyages) {
            voyages.forEach(function(voyage) {
                map.addVoyage(voyage);
            });
        }

        map.fitToData();
    }

    return {init: init};
})();