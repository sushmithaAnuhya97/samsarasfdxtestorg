({
    "initSettings": function (cmp, event, callbackFn) {
        var action = cmp.get("c.initializeSettings");
        action.setCallback(this, function (response) {
            var state = response.getState();

            if (state === "SUCCESS") {
                console.log(response.getReturnValue());
                cmp.set("v.settings", response.getReturnValue());
                console.log(new Date() + ' - Settings fetched and initialized');
                console.log(new Date() + ' - callbackFn !=null : ' + (callbackFn != null ? "Yes" : "No"));
                if (callbackFn) {
                    callbackFn(cmp, event);
                }
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                            errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);

    },
    "saveBreadCrumbEvent": function (cmp, event) {
        var evtLoc = event.getParam("token");
        var evtQryString = event.getParam("querystring");
        console.log(new Date() + ' - Location:' + evtLoc + ',queryString=' + evtQryString);
        var settings = cmp.get('v.settings');
        if (!settings) {
            this.initSettings(cmp, event, this.saveBreadCrumbEventCallback);
        } else {
            this.saveBreadCrumbEventCallback(cmp, event);
        }
    },
    "saveBreadCrumbEventCallback": function (cmp, event) {
        var evtLoc = window.location.pathname;
        console.log('evtLoc' + evtLoc);
        var evtQryString = window.location.search;
        console.log('evtQryString' + evtQryString);
        evtQryString = evtQryString.substring(1);
        console.log('evtQryString2' + evtQryString);
        var settings = cmp.get('v.settings');

        console.log(new Date() + ' - path = ' + evtLoc + ',queryString = ' + evtQryString);
        var breadCrumbMatch;
        for (var i = 0; i < settings.urlMappings.length; i++) {
            console.log('settings' + JSON.stringify(settings));
            var theUrl = settings.urlMappings[i];
            var urlRegEx = new RegExp(theUrl.Url__c);
            // myArray: URL String of interest, i.e /lightning/page/home w/ RegEx from CustomMetadata
            var myArray = urlRegEx.exec(evtLoc);
            var qryStrArray;
            var urlMatch = false,
                qryStringMatch = false;
            if (myArray) {
                urlMatch = true;
            }
            if (myArray && theUrl.Query_String__c && evtQryString) {
                var qryStrMatch = new RegExp(theUrl.Query_String__c);
                qryStrArray = qryStrMatch.exec(evtQryString);
                if (qryStrArray) {
                    qryStringMatch = true;
                }
            }
            if (urlMatch || qryStringMatch) {
                breadCrumbMatch = new Object();
                breadCrumbMatch.eventType = theUrl.MasterLabel;
                console.log('myArray' + JSON.stringify(myArray))
                breadCrumbMatch.eventObject = myArray[1];
                console.log('breadCrumbMatch.eventObject' + breadCrumbMatch.eventObject);
                console.log('theUrl.Object__c' + theUrl.Object__c);

                if (myArray.length == 3) {
                    breadCrumbMatch.recordId = myArray[2]
                }
                if (!breadCrumbMatch.eventObject && theUrl.Object__c) {
                    breadCrumbMatch.eventObject = theUrl.Object__c;
                }
                if (qryStringMatch) {
                    breadCrumbMatch.queryStringParams = qryStrArray[1];
                }
                break;
            }
        }


        if (breadCrumbMatch) {
            console.log('breadCrumbMatch:\n' + JSON.stringify(breadCrumbMatch, null, 4));
            console.log('about to fire a Buddy action ...');

            var appEvent = $A.get("e.c:BuddyEvent");
            var eventParams = {
                // i.e object = 'Home'
                object: breadCrumbMatch.eventObject,
                // i.e pageType = 'Home
                pageType: breadCrumbMatch.eventType,
                recordId: breadCrumbMatch.recordId
            };
            if (breadCrumbMatch.queryStringParams) {
                eventParams.record = {
                    "fields": {
                        "filterName": {
                            "value": breadCrumbMatch.queryStringParams
                        }
                    }
                };
            }
            console.log('eventParams.record ' + JSON.stringify(eventParams.record));
            appEvent.setParams(eventParams);
            appEvent.fire();
        }
    }
})