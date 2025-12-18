({
    updateOwnerPilot : function(component, event, helper) {
        var action = component.get("c.updatePilotOnQuote");
        action.setParams({ quoteId : component.get("v.recordId") });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log("QuoteOpptyOwnerPnP Component update successfully.");
            } else {
                console.error("Error in updating QuoteOpptyOwnerPnP Component: " + state);
            }
        })

        $A.enqueueAction(action);
    }
})