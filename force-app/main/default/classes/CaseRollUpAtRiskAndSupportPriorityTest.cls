@isTest(SeeAllData=false)
private class CaseRollUpAtRiskAndSupportPriorityTest {
    
    static testMethod void mainTest() {
        // create account, contact, opportunity, issue and case (samsara account is needed as well)
        Account a = new Account(Name = 'Han Co', Phone = '415 555 5255', Organization_Size__c = '1 - 99', BillingCountry = 'United States',BillingState = 'California');
        insert a;
        Account samsaraAcct = new Account(Name = 'Samsara', Organization_Size__c = '1 - 99', BillingCountry = 'United States',BillingState = 'California');
        insert samsaraAcct;
        Hardcoded_Id__c samsaracustomsetting = new Hardcoded_Id__c(Name = 'Samsara Account', Id__c = samsaraAcct.Id);
        insert samsaracustomsetting;
        Contact c = new Contact(FirstName = 'Han', LastName = 'Chubaca', Phone = '415 555 5255', Email = 'han@chubaca.com', AccountId = a.Id);
        insert c;
        Opportunity o = new Opportunity(AccountId = a.Id, Name = 'Oppty 30VG', CloseDate = System.today(), StageName = 'Qualified', Amount=100000);
        insert o;
        Issue__c issue = new Issue__c(Issue_Subject__c = 'New issue', Area_Impacted__c = 'Fleet - Dashcam', Issue_Status__c = 'TO DO');
        insert issue;
        Case case_c = new Case(AccountId = a.Id, ContactId = c.Id, Related_Issue__c = issue.Id);
        insert case_c;

        Test.startTest();
        
        //System.assertEquals(0, [SELECT AtRisk__c FROM Issue__c WHERE Id =: issue.Id LIMIT 1].AtRisk__c);
        //System.assertEquals('s2', [SELECT Support_Priority__c FROM Issue__c WHERE Id =: issue.Id LIMIT 1].Support_Priority__c);
        
        // add another case, check issue was updated
        Account newA = new Account(Name = 'Jupyter Inc', Organization_Size__c = '1 - 99', BillingCountry = 'United States',BillingState = 'California');
        insert newA;
        Contact newC = new Contact(FirstName = 'Han', LastName = 'Jupyter', Email = 'han@jupyter.com', AccountId = newA.Id);
        insert newC;
        Opportunity newO = new Opportunity(AccountId = newA.Id, Name = 'Oppty 30VG', CloseDate = System.today(), StageName = 'Qualified', Amount=500000);
        insert newO;
        Case newCase_c = new Case(AccountId = newA.Id, ContactId = newC.Id, Related_Issue__c = issue.Id);
        insert newCase_c;
        
        Test.stopTest();
        
        //System.assertEquals(0, [SELECT AtRisk__c FROM Issue__c WHERE Id =: issue.Id LIMIT 1].AtRisk__c);
        //System.assertEquals('s2', [SELECT Support_Priority__c FROM Issue__c WHERE Id =: issue.Id LIMIT 1].Support_Priority__c);
    }
    
}