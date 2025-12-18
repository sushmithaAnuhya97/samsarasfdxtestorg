trigger SubmitPartnerApplicationTrigger on SubmitPartnerApplicationEvent__e (after insert) {
	new SubmitPartnerApplicationHandler().run();
}