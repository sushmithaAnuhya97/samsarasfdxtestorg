@IsTest
public class SubmitPartnerApplicationTest {
    
    @IsTest
    static void testPartnerLeadSubmission(){
         String orgId = UserInfo.getOrganizationId();
        String partnerUsername = 'partner@test.com'+orgId;
        RecordType leadDealRegRT = [Select Id from RecordType Where SObjectType = 'Lead' and DeveloperName = 'Partner_Application' LIMIT 1]; 
        Lead dealRegLead = new Lead (LastName = 'Test Client', Email = 'dealreglead@test.com'+orgId, RecordTypeId = leadDealRegRT.id, phone = '+1234567890', Company = 'Test company', Business_unit__c = 'Fleet', LeadSource = 'Deal Reg Form', Country='United States', State='Texas', Status = 'New');
        insert dealRegLead;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SubmitLeadToNotreDameTest.NotreDameHTTPServiceTestMocks());
        //The partner user should be the owner of the Lead record after creation.
        //Lead queriedLead = [Select Id, OwnerId from Lead where Id =: dealRegLead.Id];
        //System.assert(queriedLead.OwnerId == partnerUser.Id);
        
        //The partner user submits the Deal Reg Lead for approval.
        SubmitPartnerApplicationEvent__e event = new SubmitPartnerApplicationEvent__e();
        event.Lead_Id__c = dealRegLead.Id;
        EventBus.publish(event);
        
        Test.stopTest();
    }

    @IsTest
    static void testPartnerLeadSubmission2(){
        String orgId = UserInfo.getOrganizationId();
        Id accountPartnerRT = sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();//[Select Id from RecordType Where SObjectType = 'Account' and Name = 'Partner' LIMIT 1]; 
        Account partnerAccount = new Account(Name='Partner Account', Organization_Size__c='1 - 99', BillingCountry='Belgium', BillingCountryCode = 'BE', RecordTypeId = accountPartnerRT);
        insert partnerAccount;
        
        //Create Partner Contact
        Id contactPartnerRT = sObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();//[Select Id from RecordType Where SObjectType = 'Contact' and Name = 'Partner' LIMIT 1]; 
        Contact partnerContact = new Contact(FirstName = 'Partner', LastName = 'Contact', recordTypeId=contactPartnerRT, AccountId = partnerAccount.Id, Email = 'partner@test.com'+orgId);
        insert partnerContact;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SubmitLeadToNotreDameTest.NotreDameHTTPServiceTestMocks());
        //The partner user should be the owner of the Lead record after creation.
        //Lead queriedLead = [Select Id, OwnerId from Lead where Id =: dealRegLead.Id];
        //System.assert(queriedLead.OwnerId == partnerUser.Id);
        
        //The partner user submits the Deal Reg Lead for approval.
        SubmitPartnerApplicationEvent__e event = new SubmitPartnerApplicationEvent__e();
        event.Contact_Id__c = partnerContact.Id;
        event.Process_Type__c = 'Create User';
        EventBus.publish(event);
        
        Test.stopTest();
    }
}