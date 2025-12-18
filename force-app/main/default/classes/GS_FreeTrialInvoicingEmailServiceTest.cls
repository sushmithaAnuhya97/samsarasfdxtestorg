/**
 * Created by vikasmishra on 2021-09-26.
 */

@IsTest
private class GS_FreeTrialInvoicingEmailServiceTest {
    @IsTest
    static void shouldReturnEmailMessage() {
        GS_FreeTrialInvoicingEmailService thisService = new GS_FreeTrialInvoicingEmailService();
        Messaging.SingleEmailMessage email = thisService.getEmailMessage(
                new Quote(Id = generateId(Quote.SObjectType, 101)),
                new Opportunity(
                        Id = generateId(Opportunity.SObjectType, 101),
                        Trial_Primary_Contact__c = generateId(Contact.SObjectType, 101)
                        ),
                Blob.valueOf('This is the test')
        );
        System.assert(email.whatId == generateId(Opportunity.SObjectType, 101), 'Should set Opportunity id as what id');
        System.assert(email.targetObjectId == generateId(Contact.SObjectType, 101), 'Should set Opportunity.Trial_Primary_Contact__c  as targetObjectId');
        System.assert(!email.saveAsActivity, 'SaveAsActivity should be false');
    }

    public static Id generateId(SObjectType sobjectType, Integer sequenceNum) {
        String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(keyPrefix + String.valueOf(sequenceNum).leftPad(12, '0'));
    }
}