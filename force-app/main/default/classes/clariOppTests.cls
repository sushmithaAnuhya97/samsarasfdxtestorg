@IsTest
private class clariOppTests {
    @IsTest
    private static void createTestData(){
        //create test account
        Account acc              = new Account();
        acc.Name                 = 'Clari Test Acc';
        acc.Organization_Size__c = '1 - 99';
        acc.Industry             = 'Construction';
        acc.BillingCountry       = 'United States';
        acc.BillingState         = 'California';
        insert acc;
        
        
        //create test opportunity
        Opportunity opp = new Opportunity();
        opp.Name        = 'Clari Test Opp';
        opp.AccountId   = acc.Id;
        opp.CloseDate   = date.today();
        opp.StageName   = 'Incubate';
        insert opp;
        
        //query for created Clari Opp and inserted Opp
        Clari_Opp__c clariOpp = [SELECT Id,
                                		Opportunity__c
                                		FROM Clari_Opp__c WHERE Opportunity__c = :opp.Id];
        
        Opportunity updatedOpp = [SELECT Id, 
                                  		 Clari_Opp__c
                                 		 FROM Opportunity WHERE Id = :opp.Id];
        
        
        
        System.assertEquals(updatedOpp.Id, clariOpp.Opportunity__c);
        
    }
    
    @isTest private static void testPArtnerPopulator(){

        List <Account> accsToInsert = new List <Account>();
        Test.startTest();
        Account acc = new Account();
        acc.Name = 'End Customer Test';
        acc.Organization_Size__c = '1 - 99';
        acc.Industry = 'Agriculture';
        acc.BillingState = 'California';
        acc.BillingCountry = 'United States';
        accsToInsert.add(acc);

        Account accReseller = new Account();
        accReseller.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
                                                      
        accReseller.Name = 'Reseller Test';
        accReseller.Organization_Size__c = '1 - 99';
        accReseller.BillingState = 'California';
        accReseller.BillingCountry = 'United States';
        accsToInsert.add(accReseller);

        insert accsToInsert;
        
        //Update Account with partner info
        acc.Latest_Partner_Account_Interaction__c = accReseller.id;
        acc.Latest_Partner_Program_Interaction__c = 'Resale';
        update acc;

        Opportunity opp = new Opportunity();
        opp.Name = 'Original Oppty';
        opp.AccountId = acc.Id;
        opp.CloseDate = Date.today();
        opp.StageName = 'Closed Won';
        opp.Reseller_Partner__c = accReseller.Id;
        insert opp;

        Contract con = new Contract();
        con.AccountId = acc.Id;
        con.Original_Contracted_Opportunity__c = opp.Id;
        con.StartDate = Date.today();
        con.EndDate = Date.today() + 365;
     
        insert con;
       Contract newContract = [SELECT id, Name, Original_Reseller_ID__c, StartDate, EndDate, Original_Contracted_Opportunity__c, SBQQ__Opportunity__r.AccountId, ContractNumber FROM CONTRACT LIMIT 1];

        
        
        Opportunity amendOpp = new Opportunity();
        amendOpp.Name = 'Amendment Oppty';
        amendOpp.AccountId = acc.Id;
        amendOpp.CloseDate = Date.today() + 90;
        amendOpp.ContractId = newContract.Id;
        //Zak
        amendOpp.SBQQ__AmendedContract__c = newContract.Id;
        
        amendOpp.StageName = 'Incubate';
        amendOpp.Reseller_Partner__c = accReseller.ID;
        OpportunityTriggerHandler.resetAll();
        insert amendOpp;
        
        Opportunity renOpps = [SELECT id, Name, Reseller_Partner__c, ContractId from Opportunity WHERE id = :amendOpp.Id LIMIT 1];
        
        System.assertEquals(amendOpp.Reseller_Partner__c, accReseller.id);
        Test.stopTest();
    }

}