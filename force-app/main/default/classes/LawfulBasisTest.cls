/*
 *	This class tests 3 triggers:
 *	- StampLawfulBasisOnContactCreate
 *	- StampLawfulBasisOnAccountUpdate
 *	- StampLawfulBasisOnCampaignMemberCreate
 *	@author: Vijay Manohar
 */


@isTest
private class LawfulBasisTest {
	static testMethod void LawfulBasis() {
		/****
		 ****	Test StampLawfulBasisOnContactCreate
		 ****/
        Account a = new Account (Name = 'Slater Co', Organization_Size__c = '5000+', BillingCountry = 'United Kingdom', Industry = 'Other');
        insert a;
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'John', LastName = 'Florence', Source__c = 'Other');
        insert cntc;
        String associatedLawfulBasis = [SELECT Associated_Lawful_Basis__c FROM Contact WHERE Id =: cntc.Id][0].Associated_Lawful_Basis__c;
        System.assertEquals(associatedLawfulBasis, 'Legitimate Interest');
    }

    static testMethod void LawfulBasis2() {
        /****
		 ****	Test StampLawfulBasisOnAccountUpdate
		 ****/
        Account a1 = new Account (Name = 'Test Co', Organization_Size__c = '5000+', BillingCountry = 'United Kingdom', Industry = 'Other');
        insert a1;
        Contact cntc1 = new Contact(AccountId = a1.Id, FirstName = 'Bob', LastName = 'Jones', email = 'bob@jones.com', Source__c = 'Other');
        insert cntc1;
        a1.Status__c = 'Existing Customer';
        update a1;
        String associatedLawfulBasis1 = [SELECT Associated_Lawful_Basis__c FROM Contact WHERE Id =: cntc1.Id][0].Associated_Lawful_Basis__c;
        System.assertEquals(associatedLawfulBasis1, 'Contract');
    }

    static testMethod void LawfulBasis3() {
        /****
		 ****	Test StampLawfulBasisOnCampaignMemberCreate
		 ****/
        Account a2 = new Account (Name = 'Job Co', Organization_Size__c = '5000+', BillingCountry = 'United Kingdom', Industry = 'Other');
        insert a2;
        Contact cntc2 = new Contact(AccountId = a2.Id, FirstName = 'Jason', LastName = 'Statham', email = 'taken@taken.com', Source__c = 'Other');
        insert cntc2;
        
        // Create and insert campaigns
        // Structure campaigns such that C3 has a parent of C2 and a Master of C1. 
        Campaign cmp1 = new Campaign(Name = 'List1');
        insert cmp1;
        // Get the ID of cmp1 so that we can pass in as the Parent of cmp2
        List <Campaign> cmp1_id = [SELECT Id FROM Campaign WHERE Name = 'List1'];
        Campaign cmp2 = new Campaign(Name = 'List2', ParentId = cmp1_id[0].Id);
        insert cmp2;
        // Get the ID of cmp2 so we can pass in as the parent of cmp3
		List <Campaign> cmp2_id = [SELECT Id FROM Campaign WHERE Name = 'List2'];
        Campaign cmp3 = new Campaign(Name = 'Master (Event)', ParentId = cmp2_id[0].Id);
        insert cmp3;
        
        Campaignmember C1 = new Campaignmember(ContactId = cntc2.Id, CampaignId = cmp1.Id, Status = 'Responded', Campaign_Interaction_Date__c = System.today() -10);
        insert C1;

        String associatedLawfulBasis2 = [SELECT Associated_Lawful_Basis__c FROM Contact WHERE Id =: cntc2.Id][0].Associated_Lawful_Basis__c;
        System.assertEquals(associatedLawfulBasis2, 'Consent');
	}
}