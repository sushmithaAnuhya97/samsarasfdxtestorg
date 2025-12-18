@isTest
public class flex_openAmendmentOpportunityTest {
    @isTest
    public static void testGetAmendmentOpportunities() {
        
       Account acc = new Account();
acc.Name = 'End Customer Test';
acc.Organization_Size__c = '1 - 99';
acc.Industry = 'Agriculture';
acc.BillingState = 'California';
acc.BillingCountry = 'United States';
 insert acc;
        
        Contract cont1 = new Contract(
            AccountId = acc.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1
            );
        
        Contract cont2 = new Contract(
            AccountId = acc.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1
            );
        
        Opportunity opportunity1 = new Opportunity(
            Name = 'Opportunity 1',
            StageName = 'Qualified',
            CloseDate = Date.today().addDays(30),
            Amount = 5000,
            ContractId = cont1.Id,
            SBQQ__AmendedContract__c = cont1.Id,
            ACV_Amount_Multi_Currency__c = '4000'
        );
        
        Opportunity opportunity2 = new Opportunity(
            Name = 'Opportunity 2',
            StageName = 'Qualified',
            CloseDate = Date.today().addDays(45),
            Amount = 7000,
            ContractId = cont2.Id,
            SBQQ__AmendedContract__c = cont2.Id,
            ACV_Amount_Multi_Currency__c = '6000'
        );

			 insert new List<Opportunity>{opportunity1, opportunity2};
        
        // Step 2: Create a test method that calls the method to be tested
        Test.startTest();
        
        // Pass the Contract Ids to the method
        List<Id> contractIds = new List<Id>{cont1.Id, cont2.Id};
        List<Opportunity> opportunities = flex_OpenAmendmentOpportunityController.getAmendmentOpportunities(contractIds);
        
        Test.stopTest();        
    }

}