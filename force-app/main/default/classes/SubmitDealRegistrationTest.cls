@isTest
private class SubmitDealRegistrationTest {
    @TestSetup
    static void makeData(){
        //TO DO - move to a test data factory class
        //Create Partner Account
        String orgId = UserInfo.getOrganizationId();
        RecordType accountPartnerRT = [Select Id from RecordType Where SObjectType = 'Account' and Name = 'Partner' LIMIT 1]; 
        Account partnerAccount = new Account(Name='Partner Account', Organization_Size__c='1 - 99', BillingCountry='Belgium', BillingCountryCode = 'BE', RecordTypeId = accountPartnerRT.Id);
        insert partnerAccount;
        
        //Emable as Partner
        partnerAccount.IsPartner = true;
        update partnerAccount;

        //Create Partner Contact
        RecordType contactPartnerRT = [Select Id from RecordType Where SObjectType = 'Contact' and Name = 'Partner' LIMIT 1]; 
        Contact partnerContact = new Contact(FirstName = 'Partner', LastName = 'Contact', AccountId = partnerAccount.Id, Email = 'partner@test.com'+orgId);
        insert partnerContact;

        //Create Partner User
        Profile partnerProfile = [SELECT Id FROM Profile WHERE Name = 'Samsara Partner Community Login License User'];
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User partnerUser = new User(lastName = partnerContact.LastName,
                        email = partnerContact.Email,
                        Username = partnerContact.Email,
                        ContactId = partnerContact.Id,
                        EmailEncodingKey = 'ISO-8859-1',
                        Alias = uniqueName.substring(10, 15),
                        TimeZoneSidKey = 'America/Los_Angeles',
                        LocaleSidKey = 'en_US',
                        LanguageLocaleKey = 'en_US',
                        ProfileId = partnerProfile.Id,
                        EmployeeNumber='123');
        insert partnerUser;
    }

    @isTest 
    static void testDealSubmission() {
        String orgId = UserInfo.getOrganizationId();
        String partnerUsername = 'partner@test.com'+orgId;
        
        //Before state - Assert that the running user(PSM) has no lead records visible to them
        List<Lead> myLeadsAtStart = (List<Lead>)Database.Query('Select Id from Lead');
        System.assert(myLeadsAtStart.size() == 0);
        
        //Get partner user
        User partnerUser = [Select Id, Account.OwnerId from User where username =: partnerUsername];
        System.runAs(partnerUser) {
            
            //Insert a Deal Reg Lead record to simulate the Partner community action
            RecordType leadDealRegRT = [Select Id from RecordType Where SObjectType = 'Lead' and Name = 'Channel Registration' LIMIT 1]; 
            Lead dealRegLead = new Lead (LastName = 'Test Client', Email = 'dealreglead@test.com'+orgId, RecordTypeId = leadDealRegRT.id, phone = '+1234567890', Company = 'Test company', Business_unit__c = 'Fleet', LeadSource = 'Deal Reg Form', Country='United States', State='Texas', Status = 'New');
            insert dealRegLead;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SubmitLeadToNotreDameTest.NotreDameHTTPServiceTestMocks());
            //The partner user should be the owner of the Lead record after creation.
            Lead queriedLead = [Select Id, OwnerId from Lead where Id =: dealRegLead.Id];
            System.assert(queriedLead.OwnerId == partnerUser.Id);
			
            //The partner user submits the Deal Reg Lead for approval.
            SubmitDealRegistrationEvent__e event = new SubmitDealRegistrationEvent__e();
            event.Lead_Record_Id_t__c = dealRegLead.Id;
            EventBus.publish(event);
     
            Test.stopTest();
            
            //The partner user should no longer have access to the lead record. Owner changed to PSM user
            List<Lead> partnerLeadsAtEnd = (List<Lead>)Database.Query('Select Id from Lead where Id =\''+dealRegLead.Id+'\'');
        	//System.assert(partnerLeadsAtEnd.size() == 0);
        }
        
        //After state - Assert that the running user(PSM) has the Deal Reg lead records visible to them
        List<Lead> myLeadsAtEnd = (List<Lead>)Database.Query('Select Id from Lead');
        //System.assert(myLeadsAtEnd.size() == 1);
    }

    @IsTest
    static void shouldCallSubmitDealRegistrationToNotreDame(){
        String orgId = UserInfo.getOrganizationId();
        String partnerUsername = 'partner@test.com'+orgId;

        //Before state - Assert that the running user(PSM) has no lead records visible to them
        List<Lead> myLeadsAtStart = (List<Lead>)Database.Query('Select Id from Lead');
        System.assert(myLeadsAtStart.size() == 0);

        //Get partner user
        User partnerUser = [Select Id, Account.OwnerId from User where username =: partnerUsername];
        Lead dealRegLead = new Lead();
        System.runAs(partnerUser) {

            //Insert a Deal Reg Lead record to simulate the Partner community action
            RecordType leadDealRegRT = [Select Id from RecordType Where SObjectType = 'Lead' and Name = 'Channel Registration' LIMIT 1];
            dealRegLead = new Lead (LastName = 'Test Client', Email = 'dealreglead@test.com'+orgId, RecordTypeId = leadDealRegRT.id, phone = '+1234567890', Company = 'Test company', Business_unit__c = 'Fleet', LeadSource = 'Deal Reg Form', Country='United States', State='Texas', Status = 'New');
            insert dealRegLead;
        }

        Test.startTest();
        //The partner user should be the owner of the Lead record after creation.
        Lead queriedLead = [Select Id, OwnerId from Lead where Id =: dealRegLead.Id];
        SubmitDealRegToNotreDame.Payload payload = new SubmitDealRegToNotreDame.Payload();
        payload.leadId = queriedLead.Id;
        SubmitDealRegToNotreDame.submitLeadForConversion(new List<SubmitDealRegToNotreDame.Payload>{
                payload
        });
    }
    
    
}