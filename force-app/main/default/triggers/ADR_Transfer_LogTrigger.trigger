/**
 * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
 * @date 2020-08-24
 * @lastModified 2020-08-25
 */
trigger ADR_Transfer_LogTrigger on ADR_Transfer_Log__c
(before delete, before insert, before update, after delete, after insert, after undelete, after update)
{ 
    new ADR_Transfer_LogTriggerHandler().run();
}