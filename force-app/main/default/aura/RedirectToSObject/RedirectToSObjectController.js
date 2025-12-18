({
    invoke : function(component, event, helper) {
        helper.fireToast(component);
        helper.fireRedirect(component);
    }
})