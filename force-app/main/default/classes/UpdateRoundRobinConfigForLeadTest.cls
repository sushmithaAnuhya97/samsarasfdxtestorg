/* 
* Class Created: 08/01/2023 - @author: Saiteja
* Test Class: UpdateRoundRobinConfigForLeadTest
* 
*/
@isTest
private class UpdateRoundRobinConfigForLeadTest {
    @isTest static void leadTests() {
        Lead lead1 = (Lead)TestFactory.createSOBject(new Lead(FirstName = 'TestFirst', LastName = 'TestLast', Company = 'TestCompany', 
                                                              Partner_Type__c = 'Insurance', Program_Type__c = 'Subsidy', Business_Unit__c = 'Fleet', Country = 'United States', State = 'California', LeadSource = 'Adwords'));
        insert lead1;
        Lead lead2 = (Lead)TestFactory.createSOBject(new Lead(FirstName = 'TestFirst2', LastName = 'TestLast2', Company = 'TestCompany', 
                                                              Partner_Type__c = 'Insurance',  Program_Type__c = 'Subsidy', Business_Unit__c = 'Fleet', Country = 'United States', State = 'California', LeadSource = 'Adwords'));
        insert lead2;
    }
    
    @isTest static void updateRRLeadConfigsTest(){
        Account a = new Account (Name = 'Testing Acct', 
                                Organization_Size__c =' 1 - 99', 
                                BillingCountry = 'United States', 
                                Hashtag__c = '#Testing123',
                                Industry = 'Agriculture', 
                                ADR_Transfer__c = false, 
                                BillingState = 'California');
        insert a;
        Lead lead1 =  new Lead(FirstName = 'Ron Testing31',
                            LastName = 'JulyTenth2019',
                            Company = 'Account Test',
                            Organization_Size__c = '1 - 99',
                            Number_of_Vehicles__c = 10, 
                            Number_of_Assets__c = 30,
                            Number_of_Trailers__c = 30,
                            RR_Duplicate_Account__c = a.Id,
                            Website = 'www.ronpbtransitiontest.com',
                            Country = 'United States',
                            State = 'California',
                            Industry = 'Agriculture',
                            LeadSource = 'Partner Referral',
                            Description = 'Hello World: How you doin?',
                            Email = 'rontestingleadspbtransition@testing.com',
                            Hashtag__c = '#TestyMcTesterson',
                            Phone = '423462346573',
                            Campaign_to_Add__c = '7011a000000S897AAC',
                            Campaign_Member_Status__c = 'Responded',
                            Partner_Type__c = 'Insurance',
                            Program_Type__c = 'Subsidy',
                            Inbound_Lead__c = true);
        insert lead1;
        
        Lead lead2 =  new Lead(FirstName = 'Ron Testing312',
                            LastName = 'JulyTenth20192',
                            Company = 'Account Test',
                            Organization_Size__c = '1 - 99',
                            Number_of_Vehicles__c = 10, 
                            Number_of_Assets__c = 30,
                            Number_of_Trailers__c = 30,
                            RR_Duplicate_Account__c = a.Id,
                            Website = 'www.ronpbtransitiontest.com',
                            Country = 'United States',
                            State = 'California',
                            Industry = 'Agriculture',
                            LeadSource = 'Partner Referral',
                            Description = 'Hello World: How you doin?',
                            Email = 'rontestingleadspbtransition@testing.com',
                            Hashtag__c = '#TestyMcTesterson',
                            Phone = '423462346573',
                            Campaign_to_Add__c = '7011a000000S897AAC',
                            Campaign_Member_Status__c = 'Responded',
                            Partner_Type__c = 'Insurance',
                            Program_Type__c = 'Subsidy',
                            Inbound_Lead__c = true);
        insert lead2;
        List<Lead> leads = [Select Id, Name, Partner_Type__c from Lead];
        System.debug('The leads size are: '+leads.size());
        insert new CommercialLead_Count__c(SetupOwnerId=UserInfo.getOrganizationId(), Count__c=0);
        insert new InsuranceLead_Count__c(SetupOwnerId=UserInfo.getOrganizationId(), Count__c=1);
        UpdateRoundRobinConfigForLead.updateRRLeadConfigs(leads);
    }
}