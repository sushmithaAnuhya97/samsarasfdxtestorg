({
    fireRedirect : function(component) {
        // Get the Lightning event that opens a record in a new tab
        var redirect = $A.get("e.force:navigateToSObject");
        
        // Pass the record ID to the event
        redirect.setParams({
           "recordId": component.get("v.recordId")
        });
             
        // Open the record
        redirect.fire();
    },

    fireToast : function(component) {
        if (component.get('v.showToast') != true) return;

        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: 'dismissable',
            type: 'success',
            message: 'Mandatory Message',
            messageTemplate: (component.get('v.toastMessage') > ' ' ? component.get('v.toastMessage') : 'Record {0} created!'),
            messageTemplateData: [{
                url: '/'+component.get("v.recordId"),
                label: component.get('v.recordName')
            }]
        });
        toastEvent.fire();
    }
})