@IsTest
private class OrderValidationAutomation_Batch_TEST {
    @IsTest
   static void execute_Batch_Test(){
    SBQQ.TriggerControl.disable();
        OrderValidationServiceAutomationAsync asyncHandler = new OrderValidationServiceAutomationAsync();
        
        // Create test data
        Account acc = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Belgium', BillingCountryCode = 'BE',CurrencyIsoCode = 'MXN', Record_Type_Stamp_for_Dupes__c = 'Fleet',Industry = 'Unknown',Enable_Delinquency_Process__c = false, Current_Telematics_Provider__c = 'Azuga', Number_of_Vehicles__c= 101);
        insert acc;
        Id pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
        User userRecord = new User();
        userRecord = (User)TestFactory.createSObject(new User(ProfileId = pId,
                                                              EmployeeNumber = '123',
                                                              LastName = 'last',
                                                              Email = 'puser000@amamama.com',
                                                              Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
                                                              CompanyName = 'TEST',
                                                              Title = 'title',
                                                              Alias = 'alias',
                                                              TimeZoneSidKey = 'America/Los_Angeles',
                                                              EmailEncodingKey = 'UTF-8',
                                                              LanguageLocaleKey = 'en_US',
                                                              LocaleSidKey = 'en_US',
                                                              Order_Admin_Fallback_User__c = TRUE,
                                                              isActive = TRUE,
                                                              Region__c = 'North America',
                                                              Level__c = 'AE 1'));
        insert userRecord;
        Opportunity opp1 = new Opportunity(AccountId = acc.Id, 
                                           Type = 'Rebate Opportunity',
                                           Name = 'Rebate Testers 2 Inc',
                                           StageName = 'Proposal',
                                           closedate = System.today(),
                                           Rebate_Amount__c = 150,
                                           Price_Book_Name__c = 'Standard');
        insert opp1;
        Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='Dallas', Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = acc.id);
        insert sa;
        Opportunity opp = new Opportunity(AccountId = acc.Id, 
                                          Type = 'Revenue Opportunity',
                                          Name = 'Opp Testers 2 Inc',
                                          StageName = 'Proposal',
                                          closedate = System.today()-10,
                                          Price_Book_Name__c = 'Standard',
                                          License_Term__c = 36,
                                          Shipping_and_Handling_Amount__c = 99999.99,
                                          OwnerId = userRecord.Id,
                                          Buyout_Opportunity__c  = opp1.id,
                                          Shipping_Address_NEW__c  = sa.id,
                                          Sales_Tax_Historical__c  = 99999.99,
                                          Amount_Received__c = 150,
                                          CurrencyIsoCode ='MXN',
                                          Payment_Method__c = 'Credit Card',
                                          Camera_Only_Deal__c = true,
                                          Selected_Payment_Type__c = 'Direct Annual');
        insert opp;
        dsfs__DocuSign_Status__c  dstatus = new dsfs__DocuSign_Status__c(
            Account_Name__c = acc.name,
            dsfs__Envelope_Status__c =  'Completed',
            dsfs__Opportunity__c =  opp.id,
            License_Term__c = 36,
            of_HW_Products__c= '3', 
            of_LIC_Products__c= '2',
            Selected_Payment_Type__c = 'Direct Monthly');
        insert dstatus;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'First Quote ', SBQQ__Opportunity2__c =opp.Id, of_HW_Products__c = 2,of_LIC_Products__c = 2,
                                                  SBQQ__SubscriptionTerm__c =10,License_Term__c = '36', Estimated_Annual_Payment__c = 24, SBQQ__Primary__c = true,Selected_Payment_Type__c = 'Direct Monthly');
        insert quote;
        
        Opportunity oppRec  = new Opportunity();
        oppRec.SBQQ__PrimaryQuote__c = quote.Id;
        oppRec.Id = opp.Id;
        update OppRec;
        
        List<Opportunity> oppsToNotify = new List<Opportunity>{opp};
                    
        Test.startTest();
            Id jobId = Database.executeBatch(new OrderValidationAutomation_Batch(new Set<Id>{opp.Id}),1);
           new OrderValidationAutomation_Batch(new Set<Id>{opp.Id}).sendEmailMethod(jobId);
        Test.stopTest();
       new OrderValidationAutomation_Batch(new Set<Id>{opp.Id}).setCvsReviewMethod(new List<Opportunity>{opp});
       
   }
}