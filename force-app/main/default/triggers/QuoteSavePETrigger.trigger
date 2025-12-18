trigger QuoteSavePETrigger on Quote_Save__e (after insert) {
	new QuoteSavePETriggerHandler().run();
}