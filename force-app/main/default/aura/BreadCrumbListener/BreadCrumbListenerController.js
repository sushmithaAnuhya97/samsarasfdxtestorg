({
    "afterLodashLoaded": function (cmp, event, helper) {
        window.lodash = window._;
    },
    "doInit": function (cmp, event, helper) {
        helper.initSettings(cmp, event);
    },
    "handleLocationChangeEvent": function (cmp, event, helper) {
        cmp.set('v.routeChangeCounter', cmp.get('v.routeChangeCounter') + 1);
        console.log('routeChangeCounter' + cmp.get('v.routeChangeCounter'));
        helper.saveBreadCrumbEvent(cmp, event);
    }
})