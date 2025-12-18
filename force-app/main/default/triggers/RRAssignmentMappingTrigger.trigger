trigger RRAssignmentMappingTrigger on RR_Assignment_Mapping__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
	new RRAssignmentMappingHandler().run();
}