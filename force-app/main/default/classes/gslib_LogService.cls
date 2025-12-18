/**
 * Created by vikasmishra on 2021-07-14.
 */

public with sharing class gslib_LogService implements IService{

    @TestVisible
    static gslib_ILoggerAppender thisAppender = new Samsara_DatabaseAppender();
    public void processLogEvents(List<gslib_Log__e> eventList){
        List<Log__c> thisLogList = new List<Log__c>();
        for(gslib_Log__e thisLogEvent : eventList){
            thisLogList.add(getLogInstanceFromEventRecord(thisLogEvent));
        }
        thisAppender = new Samsara_DatabaseAppender(thisLogList);
        thisAppender.dispatch();
    }

    private Log__c getLogInstanceFromEventRecord(gslib_Log__e thisEvent){
        Log__c thisLog = new Log__c();
        thisLog.ClassName__c = thisEvent.Class_Name__c;
        thisLog.Method__c = thisEvent.Method_Name__c;
        thisLog.Context_User__c = thisEvent.Context_User__c;
        thisLog.Message__c = thisEvent.Message__c;
        thisLog.SessionKey__c = thisEvent.Session_Key__c;
        thisLog.StackTrace__c = thisEvent.Stack_Trace__c;
        thisLog.Timestamp__c = thisEvent.Timestamp__c;
        thisLog.LogLevel__c = thisEvent.LogLevel__c;
        thisLog.Severity__c = thisEvent.Severity__c;
        thisLog.ExceptionMessage__c = thisEvent.Exception_Message__c;
        thisLog.Exception_Type__c = thisEvent.Exception_Type__c;
        thisLog.Response__c = thisEvent.Response__c;
        return thisLog;
    }

    public interface IService{
        void processLogEvents(List<gslib_Log__e> eventList);
    }

}