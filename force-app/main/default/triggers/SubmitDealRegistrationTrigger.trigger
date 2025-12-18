trigger SubmitDealRegistrationTrigger on SubmitDealRegistrationEvent__e (after insert) {
    new SubmitDealRegistrationHanlder().run();
}