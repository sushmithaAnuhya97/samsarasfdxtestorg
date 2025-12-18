@isTest(SeeAllData=false) 
private class LastMarketingEngagementDateTest {
    static testMethod void addCampaign1() {
         // Create account
        Account a = new Account (Name = 'Lannister Corp', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState='California' ,Industry = 'Other');
        insert a;
        
        // Create a contact with owner = Alex Fisher
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Tyrion', LastName = 'Lannister', email = 'tyrion@lannister.com',
                                   OwnerId = '0051a000002lS2l');           
        insert cntc;
        
        System.assertEquals(Null, [SELECT Last_Marketing_Engagement_Date__c FROM Contact WHERE email = 'tyrion@lannister.com' LIMIT 1].Last_Marketing_Engagement_Date__c);
        System.assertEquals(Null, [SELECT Last_Marketing_Engagement_Date__c FROM Account WHERE Name = 'Lannister Corp' LIMIT 1].Last_Marketing_Engagement_Date__c);
    
        Campaign c1 = new Campaign(Name = '(Master) Inbound');
        insert c1;
        
        Campaign c2 = new Campaign(Name = '(Parent) MVF', ParentId = c1.Id);
        insert c2;
        
        Campaign c3 = new Campaign(Name = '(Child) MVF', ParentId = c2.Id);
        insert c3;
        System.debug(c3);
        
        CampaignMember cm = new CampaignMember(CampaignId = c3.Id, ContactId = cntc.Id, Status = 'Responded');
        insert cm;
    } 
    
    static testMethod void addCampaign2() {
         // Create account
        Account a = new Account (Name = 'Lannister Corp', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState='California' ,Industry = 'Other');
        insert a;
        
        // Create a contact with owner = Alex Fisher
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Tyrion', LastName = 'Lannister', email = 'tyrion@lannister.com',
                                   OwnerId = '0051a00000154rfAAA');           
        insert cntc;
        
        System.assertEquals(Null, [SELECT Last_Marketing_Engagement_Date__c FROM Contact WHERE email = 'tyrion@lannister.com' LIMIT 1].Last_Marketing_Engagement_Date__c);
        System.assertEquals(Null, [SELECT Last_Marketing_Engagement_Date__c FROM Account WHERE Name = 'Lannister Corp' LIMIT 1].Last_Marketing_Engagement_Date__c);
    
        Campaign c1 = new Campaign(Name = '(Master) Inbound');
        insert c1;
        
        Campaign c2 = new Campaign(Name = '(Parent) MVF', ParentId = c1.Id);
        insert c2;
        
        Campaign c3 = new Campaign(Name = '(Child) MVF', ParentId = c2.Id);
        insert c3;
        System.debug(c3);
        
        CampaignMember cm = new CampaignMember(CampaignId = c3.Id, ContactId = cntc.Id, Status = 'Responded');
        insert cm;
    } 
  
}