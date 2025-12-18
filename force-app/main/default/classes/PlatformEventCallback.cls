public class PlatformEventCallback implements EventBus.EventPublishFailureCallback,EventBus.EventPublishSuccessCallback{
    
    public void onFailure(EventBus.FailureResult result) {
        List<String> failedEventUuids = result.getEventUuids();
        apiLogging(failedEventUuids);
        system.debug('result Failed'+result);
        System.debug('failedEventUuids--->'+failedEventUuids);
    }
    
    public void onSuccess(EventBus.SuccessResult result) {
        List<String> successfulEventUuids = result.getEventUuids();
        system.debug('result Success'+result);
        System.debug('successfulEventUuids--->'+successfulEventUuids);
    }  
    public void apiLogging(List<String> EventStatus) {
        List<Api_Logger__c> apiLogs = new List<Api_Logger__c>();
        for(String EvntDetails : EventStatus){
            Api_Logger__c aplog = new Api_Logger__c();
            apLog.Opportunity_Name__c =  'Webstore createPlatformEvent';
            apLog.DML__c= true;
            apLog.Request__c= EvntDetails;
            apLog.Exception_Message__c = 'Creating Platform Event for Webstore';
            apLog.Response__c=EvntDetails;
            apLog.Quote_Number__c = system.UserInfo.getName();
            apiLogs.add(aplog);
            system.debug('aplog'+aplog);
        }
        if(apiLogs.size()>0){insert apiLogs;}
    }
    
    public static Boolean checkPlatformEventLimits(){
        Map<String, OrgLimit> mapOrgLimit = OrgLimits.getMap();
        Integer intLimit, intValue ;
        if (mapOrgLimit != null && (mapOrgLimit.containsKey('HourlyPublishedPlatformEvents'))) {
            intLimit = mapOrgLimit.get('HourlyPublishedPlatformEvents').getLimit();
            intValue = mapOrgLimit.get('HourlyPublishedPlatformEvents').getValue();
            system.debug('HourlyPublishedPlatformEvents usage is ' + intLimit + ' - ' + intValue);
        }
        return intValue<intLimit;
    }
}