({
	doInit : function(component, event, helper) {
        component.set("v.showSpinner",true);
        
        var action = component.get("c.getQuoteDetail");
         action.setParams({
            "QuoteID" : component.get("v.recordId"),
        })
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS")
            {
                var response = response.getReturnValue();
                component.set("v.showSpinner",false);
                component.set("v.LegalName", response.LegalName); 
                component.set("v.Tcv", response.Tcv); 
                component.set("v.Term", response.Term);  
                component.set("v.ExpCloseDate", response.ExpCloseDate); 
                component.set("v.Address", response.Address); 
                component.set("v.Duns", response.Duns); 
                component.set("v.opportunityOwner", response.opportunityOwner);
            }
            else if(state === "INCOMPLETE")
            {
                component.set("v.showSpinner",false);
            }
            else if(state === "ERROR")
            {
                component.set("v.showSpinner",false);
             var error = response.getError();
             if(error)
             {
                 component.set("v.showSpinner",false);
                 console.log("error"+errors);
             }
            }
        });
          $A.enqueueAction(action);
    },
    
    handleOnLoad: function(component,event,helper){
        let record = JSON.parse(JSON.stringify(event.getParam('recordUi')));
        let fields = record.record.fields;
        let fdValue = fields.Financing_Decision__c.value;
        let oldExpValue = fields.Expiration_Date__c.value;
        component.set("v.oldFdValue",fdValue);
        component.set("v.oldExpDateValue",oldExpValue);
        
    },
    
    handleFieldChange: function(component,event,helper){
        let showExpDate = (event.getSource().get("v.fieldName") == 'Financing_Decision__c' && event.getSource().get("v.value") == "Approved");
        console.log(showExpDate);
         component.set("v.showExpDate",showExpDate);
    },
    /*
    handleSave : function(component, event, helper) {
        component.set("v.showSpinner",true);
        	var approvedstatus = component.find("Financing_Decision__c").get("v.value");
        var recordId =component.get("v.recordId");
        console.log('approvedstatus__'+approvedstatus);
        if(approvedstatus == 'Approved'){
           var action = component.get("c.approvalSubmit");
             action.setParams({
                "QuoteID" : component.get("v.recordId"),
            })
            action.setCallback(this, function(response){
                var state = response.getReturnValue();
                if(state === "SUCCESS")
                {
                    component.set("v.showSpinner",false);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                          "type" : 'success',
                        "message": "The record has been Approved successfully."
                    });
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                }            
                else {
                    component.set("v.showSpinner",false);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                          "type" : 'error',
                        "message": state
                    });
                    toastEvent.fire();
                }
            });
          $A.enqueueAction(action); 
        }
        else{
            component.set("v.showSpinner",false);
            $A.get("e.force:closeQuickAction").fire();
        }

    },
    */
    handleOnSubmit : function(component, event, helper) {
        event.preventDefault();
        component.set("v.showSpinner",true);
        var fields = event.getParam('fields');
        if(fields.Financing_Decision__c == 'Approved' && component.get('v.oldFdValue') != 'Approved'){
            let timezone = $A.get("$Locale.timezone");
			let dateVal = new Date();//.toLocaleString("en-US", {timeZone: timezone}) 
            fields.Financing_Decision_Date__c = dateVal;
        }else{
            fields.Expiration_Date__c = component.get("v.oldExpDateValue");
        }
        component.find('form').submit(fields);
    },
    
    
    
    handleSuccess : function(component, event, helper) {
        component.set("v.showSpinner",false);
        let record = event.getParams();
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
              "type" : 'success',
            "message": "The record has been updated successfully."
        });
        toastEvent.fire();
        $A.get("e.force:closeQuickAction").fire();
     },
    
    handleOnError: function(component,event,helper){
        component.set("v.showSpinner",false);
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
              "type" : 'error',
            "message": event.getParam('detail')
        });
        toastEvent.fire();
    },
    handleUploadFinished: function (cmp, event) {
        // Get the list of uploaded files
        var uploadedFiles = event.getParam("files");
        //alert("Files uploaded : " + uploadedFiles.length);

        // Get the file name
        uploadedFiles.forEach(file => console.log(file.name));
        cmp.set("v.hasDocument", true); 
        console.log(cmp.get("v.hasDocument"));
        var action = cmp.get("c.sendPOUploadEmail");
         action.setParams({
            "QuoteID" : cmp.get("v.recordId"),
        })
        action.setCallback(this, function(response){
            var state = response.getState();
            console.log(state);
            
            
        });
          $A.enqueueAction(action);
    },

})