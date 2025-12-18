@isTest
private class LeadTests {
	
	@isTest static void leadTests() {
		Lead l = (Lead)TestFactory.createSOBject(new Lead(FirstName = 'TestFirst', LastName = 'TestLast', Company = 'TestCompany', Business_Unit__c = 'Fleet', Country = 'United States', State = 'California', LeadSource = 'Adwords'));
		insert l;
	}

	@isTest static void PBTransitionTest() {

		Account a = new Account (Name = 'Testing Acct', 
                                Organization_Size__c =' 1 - 99', 
                                BillingCountry = 'United States', 
								Hashtag__c = '#Testing123',
                                Industry = 'Agriculture', 
                                ADR_Transfer__c = false, 
                                BillingState = 'California');
        insert a;

		Lead l =  new Lead(FirstName = 'Ron Testing31',
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
							Inbound_Lead__c = true);
		test.startTest();
		insert l;
		test.StopTest();

		Lead ll = [SELECT Id, Business_Unit__c, RR_Duplicate_Account__c FROM Lead WHERE Id = :l.Id]; //, LFBN__Duplicate_Account__c
		
		ll.Business_Unit__c = NULL;
		update ll;
	}

}