({
    getCountries: function(component) {
        var countries = [
            { label: 'Canada', value: 'ca', iconName: 'utility:world' },
            { label: 'Canada - Français', value: 'fr-ca', iconName: 'utility:world' },
            { label: 'DACH', value: 'de', iconName: 'utility:world' },
            { label: 'France', value: 'fr', iconName: 'utility:world' },
            { label: 'México', value: 'mx', iconName: 'utility:world' },
            { label: 'Nederland', value: 'nl', iconName: 'utility:world' },
            { label: 'United Kingdom', value: 'uk', iconName: 'utility:world' },
        ];
            component.set("v.countryOptions", countries);
      },
      handleCountryChange: function(component) {
            //countrySelect
         	var sel = component.find("countrySelect");
  			var nav = sel.get("v.value");
            component.set('v.selCountry',nav);
      }
})