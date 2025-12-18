trigger AccountBookTrigger on Book_Of_Business__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
	new AccountBookTriggerHandler().run(); 
}