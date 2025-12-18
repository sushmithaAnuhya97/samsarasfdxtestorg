({
	doInit : function(component, event, helper) {
		 var action = component.get('c.getMessage');
         var artId = component.get('v.recordId');
        action.setParams({
        	'recordId':artId
   		});
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS') {
                component.set('v.message', response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
	}
})