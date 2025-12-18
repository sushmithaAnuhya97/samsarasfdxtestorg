/**
 * @description       : 
 * @author            : Navees Ahmed
 * @group             : 
 * @last modified on  : 10-03-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger SBQQSubscriptionTrigger on SBQQ__Subscription__c (before insert, before update, before delete, after insert, after update, after delete, after undelete){
    new SBQQSubscriptionTriggerHandler().run();
}