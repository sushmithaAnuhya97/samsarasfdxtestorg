({
    doInit : function(component, event, helper) {
        var recordId = component.get('v.recordId');
        var flow = component.find("flowData");
        var inputVariables = [
            {
                name : "inputLeadRecordId",
                type : "String",
                value: recordId
            }
        ];
        // In that component, start your flow. Reference the flow's API Name.
        flow.startFlow("Submit_Deal_Registration_for_Approval", inputVariables);
    }
})