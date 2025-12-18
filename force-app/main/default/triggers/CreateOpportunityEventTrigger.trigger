trigger CreateOpportunityEventTrigger on CreateOpportunityEvent__e (after insert) {
	new CreateOpportunityEventHandler().run();
}