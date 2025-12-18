@isTest(SeeAllData=false)
public class OpportunityTeamMemberTests {
	@testSetup 
    public static void dataSetup() {
        
 	Account accountOne = new Account(Name = 'Testers 1 Inc',
                                BillingCountry = 'United Kingdom',
                                Organization_Size__c = '100 - 499',
                                Industry = 'Other');
        
        insert accountOne;

        Contact contact = new Contact(FirstName = 'Test', LastName='Tester', AccountId = accountOne.Id, Email = 'test@test.com');
        insert contact;

        Opportunity opp = new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 2 Inc',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = contact.Id, 
                                                      CloseDate = Date.today());

        insert opp;
        
    }
    
    @isTest
    public static void testStampFields() {    
        Test.startTest();
    		Opportunity opportunity = [SELECT id, StageName FROM Opportunity];
        	OpportunityTeamMember otm = new OpportunityTeamMember (OpportunityId = opportunity.Id,UserId = UserInfo.getUserId(),TeamMemberRole = 'Product Specialist');
        	insert otm;
        Test.stopTest();
    }
}