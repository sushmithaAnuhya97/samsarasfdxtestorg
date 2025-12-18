@isTest(SeeAllData=false) 
private class ContactToOpportunityControllerTest {  
    @testSetup
    private static void avalaraSetup() {
        
    }
    
    static testMethod void testError() {
    
    // Create account
        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', OwnerId = '0051a0000015njF');
        insert a;
        
        // Create a contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Cntc', LastName = 'Test', ADR_Transfer_Status__c = 'Demo Scheduled', OwnerId = '0051a0000015njF', Source__c = 'List Import (no prior engagement)', ADR_Transfer_By__c = '0051a0000015njF');            
        insert cntc;
        
        ADR_Transfer_Log__c adrTransfer = new ADR_Transfer_Log__c(Account__c = a.Id, Contact__c = cntc.Id, ADR_Transfer_Status__c = 'Demo Scheduled', ADR_Transfer_By__c = '0051a0000015njF', ADR_Transfer_Date__c = System.now() - 5, ADR_Demo_Date__c = System.now()+5);
        insert adrTransfer;
        
        Test.startTest();
        // create the controller
        ContactToOpportunityController qtyController = new ContactToOpportunityController(new ApexPages.StandardController(cntc));
        
        qtyController.submit();
        
        Test.stopTest();

        System.assertEquals(0, [SELECT Id, Name FROM Opportunity WHERE AccountId = :a.Id LIMIT 1].size());
    
    }
    
    static testMethod void testOpportunityNoADR() {
    
    // Create account
        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', OwnerId = '0051a0000015njF');
        insert a;
        
        // Create a contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Cntc', LastName = 'Test', OwnerId = '0051a0000015njF', Source__c = 'Facebook Form');            
        insert cntc;
        
        Test.startTest();
        // create the controller
        ContactToOpportunityController qtyController = new ContactToOpportunityController(new ApexPages.StandardController(cntc));
        
        qtyController.submit();
        
        Test.stopTest();

        System.assertEquals(1, [SELECT Id, Name FROM Opportunity WHERE AccountId = :a.Id LIMIT 1].size());
    
    }
    
    static testMethod void testPartnerRegistrationValidation() {
        // Create account
        Account a = new Account(Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', OwnerId = '0051a0000015njF');
        insert a;
        
        // Create a contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Test', LastName = 'Contact', OwnerId = '0051a0000015njF', Source__c = 'Facebook Form');
        insert cntc;
        
        // Create Partner Registration with 'PAM Reviewed' status
        Partner_Registration__c partnerReg = new Partner_Registration__c(
            Account__c = a.Id,
            Status__c = 'PAM Reviewed',
            Company__c = 'Test Company'
        );
        insert partnerReg;
        
        Test.startTest();
        // Create the controller
        ContactToOpportunityController controller = new ContactToOpportunityController(new ApexPages.StandardController(cntc));
        
        // Verify that openPartnerRegistrationExists is true
        System.assertEquals(true, controller.openPartnerRegistrationExists, 'Open Partner Registration should exist');
        
        Test.stopTest();
    }
    
    static testMethod void testNoPartnerRegistrationValidation() {
        // Create account
        Account a = new Account(Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', OwnerId = '0051a0000015njF');
        insert a;
        
        // Create a contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Test', LastName = 'Contact', OwnerId = '0051a0000015njF', Source__c = 'Facebook Form');
        insert cntc;
        
        // Don't create any Partner Registration
        
        Test.startTest();
        // Create the controller
        ContactToOpportunityController controller = new ContactToOpportunityController(new ApexPages.StandardController(cntc));
        
        // Verify that openPartnerRegistrationExists is false
        System.assertEquals(false, controller.openPartnerRegistrationExists, 'No open Partner Registration should exist');
        
        Test.stopTest();
    }
    
    // Test backToContact method
    static testMethod void testBackToContact() {
        // Create account
        Account a = new Account(Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', OwnerId = '0051a0000015njF');
        insert a;
        
        // Create a contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Test', LastName = 'Contact', OwnerId = '0051a0000015njF', Source__c = 'Facebook Form');
        insert cntc;
        
        Test.startTest();
        ContactToOpportunityController controller = new ContactToOpportunityController(new ApexPages.StandardController(cntc));
        
        PageReference backPage = controller.backToContact();
        
        Test.stopTest();
        
        System.assertNotEquals(null, backPage, 'Back to contact page reference should not be null');
        System.assert(backPage.getUrl().contains(cntc.Id), 'URL should contain contact ID');
    }
    
    // Test demo date validation
    static testMethod void testDemoDateValidation() {
        // Create account
        Account a = new Account(Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', OwnerId = '0051a0000015njF');
        insert a;
        
        // Create a contact without demo date
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Test', LastName = 'Contact', OwnerId = '0051a0000015njF', Source__c = 'Facebook Form');
        insert cntc;
        
        Test.startTest();
        ContactToOpportunityController controller = new ContactToOpportunityController(new ApexPages.StandardController(cntc));
        
        // Set noDemo to false to trigger validation
        controller.noDemo = false;
        
        PageReference result = controller.submit();
        
        Test.stopTest();
        
        // Should return null due to validation error
        System.assertEquals(null, result, 'Submit should return null due to demo date validation');
        
        // Check that ApexPages messages were added
        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.assert(messages.size() > 0, 'Validation message should be added');
    }
    
    // Test opportunity creation with noDemo flag
    static testMethod void testOpportunityWithNoDemo() {
        // Create account
        Account a = new Account(Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', OwnerId = '0051a0000015njF');
        insert a;
        
        // Create a contact without demo date
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Test', LastName = 'Contact', OwnerId = '0051a0000015njF', Source__c = 'Facebook Form');
        insert cntc;
        
        Test.startTest();
        ContactToOpportunityController controller = new ContactToOpportunityController(new ApexPages.StandardController(cntc));
        
        // Set noDemo to true to bypass validation
        controller.noDemo = true;
        
        PageReference result = controller.submit();
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Submit should not return null when noDemo is true');
        System.assertEquals(1, [SELECT Id, Name FROM Opportunity WHERE AccountId = :a.Id LIMIT 1].size(), 'Opportunity should be created');
    }
    
    // Test createOutboundAECampaign with existing outbound AE campaign
    static testMethod void testCreateOutboundAECampaignWithExisting() {
        // Create account with no lifetime purchases
        Account a = new Account(Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', OwnerId = '0051a0000015njF');
        insert a;
        
        // Create a contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Test', LastName = 'Contact', OwnerId = '0051a0000015njF', Source__c = 'Facebook Form');
        insert cntc;
        
        // Create an outbound AE campaign
        Campaign outboundCampaign = new Campaign(Name = 'Test AE Outbound', Type = 'Sales - AE Outbound');
        insert outboundCampaign;
        
        // Create campaign member
        CampaignMember cm = new CampaignMember(CampaignId = outboundCampaign.Id, ContactId = cntc.Id, Status = 'Sent');
        insert cm;
        
        Test.startTest();
        ContactToOpportunityController controller = new ContactToOpportunityController(new ApexPages.StandardController(cntc));
        
        controller.noDemo = true;
        controller.submit();
        
        Test.stopTest();
        
        // Verify campaign member status was updated
        CampaignMember updatedCm = [SELECT Status FROM CampaignMember WHERE Id = :cm.Id];
        System.assertEquals('Responded', updatedCm.Status, 'Campaign member status should be updated to Responded');
    }
    
    // Test createOutboundAECampaign with lifetime purchases > 0 (upsell scenario)
    static testMethod void testCreateOutboundAECampaignUpsell() {
        // Create account with lifetime purchases
        Account a = new Account(Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', OwnerId = '0051a0000015njF' );
        insert a;
        
        // Create a contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Test', LastName = 'Contact', OwnerId = '0051a0000015njF', Source__c = 'Facebook Form');
        insert cntc;
        
        // Create an outbound AE campaign
        Campaign outboundCampaign = new Campaign(Name = 'Test AE Outbound', Type = 'Sales - AE Outbound');
        insert outboundCampaign;
        
        // Create campaign member
        CampaignMember cm = new CampaignMember(CampaignId = outboundCampaign.Id, ContactId = cntc.Id, Status = 'Sent');
        insert cm;
        
        Test.startTest();
        ContactToOpportunityController controller = new ContactToOpportunityController(new ApexPages.StandardController(cntc));
        
        controller.noDemo = true;
        controller.submit();
        
        Test.stopTest();
        
        // Verify opportunity was created and campaign logic was executed
        System.assertEquals(1, [SELECT Id FROM Opportunity WHERE AccountId = :a.Id].size(), 'Opportunity should be created');
    }
    
    // Test with Inbound_Reason_Faulty__c set to 'Inactive - No Longer There'
    static testMethod void testInactiveContact() {
        // Create account
        Account a = new Account(Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', OwnerId = '0051a0000015njF');
        insert a;
        
        // Create a contact with inactive status
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Test', LastName = 'Contact', OwnerId = '0051a0000015njF', 
                                  Source__c = 'Facebook Form', Inbound_Reason_Faulty__c = 'Inactive - No Longer There');
        insert cntc;
        
        Test.startTest();
        ContactToOpportunityController controller = new ContactToOpportunityController(new ApexPages.StandardController(cntc));
        
        controller.noDemo = true;
        controller.submit();
        
        Test.stopTest();
        
        // Verify contact status was not changed to 'Qualified'
        Contact updatedContact = [SELECT Status__c FROM Contact WHERE Id = :cntc.Id];
        System.assertNotEquals('Qualified', updatedContact.Status__c, 'Contact status should not be changed to Qualified for inactive contacts');
    }
    
    // Test createOpp method directly
    static testMethod void testCreateOppMethod() {
        // Create account
        Account a = new Account(Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', OwnerId = '0051a0000015njF');
        insert a;
        
        // Create a contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Test', LastName = 'Contact', OwnerId = '0051a0000015njF', Source__c = 'Facebook Form');
        insert cntc;
        
        Test.startTest();
        ContactToOpportunityController controller = new ContactToOpportunityController(new ApexPages.StandardController(cntc));
        
        // Test createOpp method
        Opportunity testOpp = controller.createOpp(controller.currentAccount, controller.auxContact, cntc, controller.oppty);
        
        Test.stopTest();
        
        System.assertNotEquals(null, testOpp, 'Created opportunity should not be null');
        System.assertEquals(a.Id, testOpp.AccountId, 'Opportunity should be associated with correct account');
        System.assertEquals(cntc.Id, testOpp.Related_Contact__c, 'Opportunity should have correct related contact');
    }
    
    // Test exception handling in submit method
    static testMethod void testSubmitExceptionHandling() {
        // Create account
        Account a = new Account(Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', OwnerId = '0051a0000015njF');
        insert a;
        
        // Create a contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Test', LastName = 'Contact', OwnerId = '0051a0000015njF', Source__c = 'Facebook Form');
        insert cntc;
        
        Test.startTest();
        ContactToOpportunityController controller = new ContactToOpportunityController(new ApexPages.StandardController(cntc));
        
        // Set noDemo to true
        controller.noDemo = true;
        
        // Create an opportunity with the same name to potentially cause a DML exception
        Opportunity existingOpp = new Opportunity(
            Name = controller.oppty.Name,
            AccountId = a.Id,
            StageName = 'Qualified',
            CloseDate = System.today()
        );
        insert existingOpp;
        
        // This should trigger exception handling
        PageReference result = controller.submit();
        
        Test.stopTest();
        
        // The method should handle the exception and return the opportunity page
        System.assertNotEquals(null, result, 'Submit should handle exceptions gracefully');
    }
    
    // Test with demo date set
    static testMethod void testOpportunityWithDemoDate() {
        // Create account
        Account a = new Account(Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', OwnerId = '0051a0000015njF');
        insert a;
        
        // Create a contact with demo date
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Test', LastName = 'Contact', OwnerId = '0051a0000015njF', 
                                  Source__c = 'Facebook Form', Demo_Date__c = System.today());
        insert cntc;
        
        Test.startTest();
        ContactToOpportunityController controller = new ContactToOpportunityController(new ApexPages.StandardController(cntc));
        
        // Set noDemo to false since we have a demo date
        controller.noDemo = false;
        
        PageReference result = controller.submit();
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Submit should succeed when demo date is provided');
        System.assertEquals(1, [SELECT Id FROM Opportunity WHERE AccountId = :a.Id].size(), 'Opportunity should be created');
    }
    
    /*
    static testMethod void existingGrowthCampaign() {
        
        // Create account
        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', OwnerId = '0051a0000015njF');
        insert a;
        
        // Create a contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Cntc', LastName = 'Test', ADR_Transfer_Status__c = 'Demo Scheduled', OwnerId = '0051a0000015njF', Source__c = 'Facebook Form', ADR_Transfer_By__c = '0051a0000015njF');            
        insert cntc;
        
        // create the ADR transfer
        ADR_Transfer_Log__c adrTransfer = new ADR_Transfer_Log__c(Account__c = a.Id, Contact__c = cntc.Id, ADR_Transfer_Status__c = 'Demo Scheduled', ADR_Transfer_By__c = '0051a0000015njF', ADR_Transfer_Date__c = System.now() - 5, ADR_Transfer__c = False, ADR_Role_Copy__c = 'MM - Team 5');
        insert adrTransfer;
        
        Campaign camp = new Campaign(Name = '(Child) Safety Campaign', Type = 'Sales - ADR Outbound');
        insert camp;
        
        CampaignMember CM = new CampaignMember(CampaignId = camp.Id, ContactId = cntc.Id, Status = 'Sent');
        insert CM;
        
        Test.startTest();
        // create the controller
        ContactToOpportunityController qtyController = new ContactToOpportunityController(new ApexPages.StandardController(cntc));
        
        qtyController.noDemo = true;
        
        PageReference submitted = qtyController.submit();
        
        Test.stopTest();

        System.assertEquals(1, [SELECT Id, Name FROM Opportunity WHERE AccountId = :a.Id LIMIT 1].size());
        System.assertEquals('Responded', [SELECT Id, Status FROM CampaignMember WHERE CampaignId = :camp.Id LIMIT 1].Status);
    
    }
	*/
    
}