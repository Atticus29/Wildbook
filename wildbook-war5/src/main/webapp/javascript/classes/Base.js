
wildbook.Model.BaseClass = Backbone.Model.extend({
    defaults: function() {
        var f = this.fields();
        var def = {};
        for (var fn in f) {
            var val = f[fn].defaultValue || this._defaultValueFor(f[fn].javaType);
            def[fn] = val;
        }
        return def;
    },


/* note: some combinations may return more than one encounter, which should be a collection (e.g /individualID==something)
   however, we still should allow that type of arbitrary field matching to get ONE encounter... maybe return only first?   */
    url: function() {
        var u = wildbookGlobals.baseUrl + '/rest/' + this.className().replace('_', '.');
        if (this.id != undefined) u += '/' + this.id;  //if we dont have an id, we may be POSTing a new object (with no id) e.g. .save()
        return u;
    },

    classNameShort: function() {
        return this.meta().className;
    },
    className: function() {
        return 'org.ecocean.' + this.classNameShort();
    },

    fields: function() {
        if (!wildbookGlobals.classDefinitions[this.className()]) return;
        var rtn = {};
        for (var fn in wildbookGlobals.classDefinitions[this.className()].fields) {
            if (fn.indexOf('jdo') == 0) continue;
            var fh = { javaType: wildbookGlobals.classDefinitions[this.className()].fields[fn] };
            fh.value = this[fn];
            fh.settable = !(wildbookGlobals.classDefinitions[this.className()].permissions && (wildbookGlobals.classDefinitions[this.className()].permissions[fn] == 'deny'));
            rtn[fn] = fh;
        }
        return rtn;
    },

    //walks through attributes and turns stuff into Models when it can
    modelifyProperties: function() {
        for (var prop in this.attributes) {
            this.attributes[prop] = wildbook.toModel(this.attributes[prop]);
        }
    },

    parse: function(response, options) {
        var rtn = {};
        for (var prop in response) {
            rtn[prop] = wildbook.toModel(response[prop]);
        }
        return rtn;
    },

    //pass name (of field) and Collection class
    fetchSub: function(name, opts) {
        //a little hacky but refClass.fieldName is only the final string from classname, rather than real reference to class
        if (!this.refClass[name]) return false;
        var cls = wildbook.Collection[this.refClass[name]];
        this[name] = new cls();
        if (!opts) opts = {};
        if (!opts.jdoql) opts.jdoql = 'SELECT x FROM ' + this.className() + ' WHERE ' + this.idAttribute + '=="' + this.id + '" && ' + name + '.contains(x)';
        this[name].fetch(opts);
        return true;
    },

    _defaultValueFor: function(type) {
        //if (type == 'java.lang.String') return '';  //nah, let this be null
        if (type == 'boolean') return false;
        if (type == 'int') return 0;
        if (type == 'long') return 0;
        //if ((type == 'int') || (type == 'java.lang.Double') || (type == 'java.lang.Long')) return 0;
//console.info('default for fell thru on %o', type);
        return null;
    }
});


wildbook.Collection.BaseClass = Backbone.Collection.extend({
    //we override to allow passing jdo and fields in addition to standard Backbone options
    fetch: function(options) {
        delete(this._altUrl);
        if (options && options.jdoql) {
            //this allows us to be "lazy" and not have to put "SELECT FROM [classname] WHERE..." but just "WHERE..."
            if (options.jdoql.toLowerCase().indexOf('where') == 0) options.jdoql = 'SELECT FROM ' + this.model.prototype.className() + ' ' + options.jdoql;
            this._altUrl = 'jdoql?' + options.jdoql;  //note this does not need the classname like /api/org.ecocean.Foo
        } else if (options && options.fields) {
            this._altUrl = this.model.prototype.className();
            var arg = [];
            for (var f in options.fields) {
                arg.push(f + '=="' + options.fields[f] + '"');  //TODO probably need some kind of encoding here? or does .ajax take care of it?
            }
            this._altUrl += '?' + arg.join('&&');
        }
    Backbone.Collection.prototype.fetch.apply(this, arguments);
    },

    url: function() {
//console.log('_altUrl => %o', this._altUrl);
        var u = wildbookGlobals.baseUrl + '/rest/';
        if (this._altUrl) {
            u += this._altUrl;
        } else {
            u += this.model.prototype.className().replace('_', '.');
        }
        return u;
    },
});
