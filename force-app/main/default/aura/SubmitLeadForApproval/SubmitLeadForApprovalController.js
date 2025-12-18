/**
 * Created by vikasmishra on 2021-06-28.
 */

({
    doInit : function(component, event, helper) {
        let recordId = component.get('v.recordId');
        let action = component.get("c.approveLead");
        action.setParams({ recordId : recordId });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {

                let result = response.getReturnValue();
                if(result.hasError){
                    component.set("v.errorMessage",result.errorMessage);
                }
                else{
                    $A.get('e.force:refreshView').fire();
                    $A.get("e.force:closeQuickAction").fire();
                }

                //$A.get('e.force:close').fire();
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                let errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                            errors[0].message);
                        component.set("v.errorMessage", errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
    }
})