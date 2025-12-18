/**
 * Created by vikasmishra on 2021-07-14.
 */

public with sharing class gslib_LogTriggerHandler extends TriggerHandler{
    private Map<Id, gslib_Log__e> oldEventMap;
    private Map<Id, gslib_Log__e> newEventMap;
    private List<gslib_Log__e> newEventList;
    @TestVisible
    static gslib_LogService.IService thisLogService = new gslib_LogService();
    public gslib_LogTriggerHandler() {
        this.oldEventMap = (Map<Id, gslib_Log__e>) Trigger.oldMap;
        this.newEventMap = (Map<Id, gslib_Log__e>) Trigger.newMap;
        this.newEventList = (List<gslib_Log__e>) Trigger.new;
    }

    public override void afterInsert() {
        thisLogService.processLogEvents(this.newEventList);
    }

}