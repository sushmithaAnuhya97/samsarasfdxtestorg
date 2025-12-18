({
    invoke : function(component, event, helper) {

        var type = component.get("v.type").toLowerCase(); //force user entered attribute to all lowercase
        var title = component.get("v.title");
        var message = component.get("v.message");
        var duration = component.get("v.duration")+"000"; //convert duration value from seconds to milliseconds
        var mode = component.get("v.mode").toLowerCase(); //force user entered attribute to all lowercase
        var urlLink = component.get("v.urlLink");
        var redirectAfter = component.get("v.redirectAfter")*1000;

        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type,
            "duration": duration,
            "mode": mode
        });
        toastEvent.fire();
        
        if(urlLink){
            window.setTimeout(function(){ 
            	window.location = urlLink;
            }, redirectAfter);
            
        }
        
    }
})