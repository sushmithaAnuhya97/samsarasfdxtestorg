@isTest(SeeAllData=false) 
private class CreateOpportunityADRTransferTest {  
    
    static testMethod void inboundADRFlow() {
        
        // Create account
        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', OwnerId = '0051a0000015njF');
        insert a;
        
        // Create a contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Cntc', LastName = 'Test', ADR_Transfer_Status__c = 'Demo Scheduled', OwnerId = '0051a0000015njF', Source__c = 'Facebook Form', ADR_Transfer_By__c = '0051a0000015njF');            
        insert cntc;
        
        // create the ADR transfer
        ADR_Transfer_Log__c adrTransfer = new ADR_Transfer_Log__c(Account__c = a.Id, Contact__c = cntc.Id, ADR_Transfer_Status__c = 'Demo Scheduled', ADR_Transfer_By__c = '0051a0000015njF', ADR_Transfer_Date__c = System.now() - 5,ADR_Demo_Date__c = System.now() - 5, ADR_Transfer__c = False, ADR_Role_Copy__c = 'IB');
        insert adrTransfer;
        
        List<String> adrTransferId = new List<String>{adrTransfer.Id};
        
        Test.startTest();
        // Invoke the method
		CreateOpportunityADRTransfer.adrCampaignAttribution(adrTransferId);
        Test.stopTest();
        
    }
    
    static testMethod void outboundADRFlow() {
        
        // Create account
        Account a = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other', OwnerId = '0051a0000015njF');
        insert a;
        
        // Create a contact
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Cntc', LastName = 'Test', ADR_Transfer_Status__c = 'Demo Scheduled', OwnerId = '0051a0000015njF', Source__c = 'Facebook Form', ADR_Transfer_By__c = '0051a0000015njF');            
        insert cntc;
        
        // create the ADR transfer
        ADR_Transfer_Log__c adrTransfer = new ADR_Transfer_Log__c(Account__c = a.Id, Contact__c = cntc.Id, ADR_Transfer_Status__c = 'Demo Scheduled', ADR_Transfer_By__c = '0051a0000015njF', ADR_Transfer_Date__c = System.now() - 5,ADR_Demo_Date__c = System.now() - 5, ADR_Transfer__c = False, ADR_Role_Copy__c = 'MM - Team 5');
        insert adrTransfer;
        
        List<String> adrTransferId = new List<String>{adrTransfer.Id};

        Test.startTest();
        // Invoke the method
		CreateOpportunityADRTransfer.adrCampaignAttribution(adrTransferId);
        Test.stopTest();
    
    }
    
}