({
    init : function (component) {
        // Find the component whose aura:id is "flowData"
        var flow = component.find("flowData");
        // In that component, start your flow. Reference the flow's Unique Name.
        var inputVariables = [
            {
                name : "recordId",
                type : "String",
                value : component.get("v.recordId")
            }
        ];
        flow.startFlow("Create_Return_Flow",inputVariables);
    },
	handleStatusChange : function (component, event) {
   		if(event.getParam("status") === "FINISHED_SCREEN") {
            var toastEvent = $A.get("e.force:showToast");
    		toastEvent.setParams({
        		"title": "Success!",
        	    "type" : 'success',
        		"message": "The record has been created successfully."
    		});
    		toastEvent.fire();
        	var outputVariables = event.getParam("outputVariables");
      		var outputVar;
      		for(var i = 0; i < outputVariables.length; i++) {
         		outputVar = outputVariables[i];
         		if(outputVar.name === "NewlycreatedrecordId") {
            		var urlEvent = $A.get("e.force:navigateToSObject");
            		urlEvent.setParams({
               		"recordId": outputVar.value,
               		"isredirect": "true"
            		});
            		urlEvent.fire();
         		}
      		}
    	}
	}
})