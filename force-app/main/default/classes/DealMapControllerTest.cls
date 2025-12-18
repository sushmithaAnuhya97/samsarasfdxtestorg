@isTest
private class DealMapControllerTest {
	static testMethod void checkController() {
		PageReference pageRef = new PageReference('http://www.google.com'); 
		Test.setCurrentPage(pageRef);

		// putting parameters in Apex Class, setting min and max string
		ApexPages.currentPage().getParameters().put('minString', '0');
		ApexPages.currentPage().getParameters().put('maxString', '10000');

		// Insert test account
		Account acc = new Account(Name = 'Lannister Corp', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState='California' ,Industry = 'Other');
		insert acc;

		// Initialising Standard Controller Extension
		ApexPages.StandardController sc = new ApexPages.StandardController(acc);
		// Initialising controller
		DealMapControllerExtension dmce = new DealMapControllerExtension(sc);

		// Call getters and setters
		dmce.minString = '0';
		dmce.maxString = '10000';
		User user = [SELECT Id, map_default__c FROM User LIMIT 1];
		dmce.userId = user.Id;

		// Call Methods
		try {
			dmce.doSubmit();
			Integer minInt = dmce.getMinInt();
			Integer maxInt = dmce.getMaxInt();
		}
		catch (exception e) {
		}
		try {
			dmce.defaultShow();
		}
		catch (exception e) {}
		try {
			dmce.defaultHide();
		}
		catch (exception e) {}
	}
}