trigger assignContactOnCaseFromDashboard on Case (before insert) {

    Hardcoded_Id__c samsaraAcct = [SELECT Name, Id__c FROM Hardcoded_Id__c WHERE Name = 'Samsara Account' LIMIT 1];
	   
    for (Case c : Trigger.new) {
        if (c.Origin.equals('Dashboard')) {
            
            //Set case account to Samsara if case/feedback came from Samsara user. 
			String dashboardEmail = c.Samsara_Dashboard_Email__c;
            String dashboardEmailDomain;
            if(dashboardEmail != NULL) {
                dashboardEmailDomain = dashboardEmail.split('@').get(1).toLowerCase();
            }
			Id dashboardAccountId = c.AccountId;
                
            if (dashboardEmailDomain.equals('samsara.com')) {	
                c.AccountId = samsaraAcct.Id__c; 
            }
            else {
                //Find or create contact based on dashboard-account-email and AccountId provided from Dashboard 
                List<Contact> matchedContacts = [SELECT Id, AccountId, Email FROM Contact WHERE Email = :dashboardEmail AND AccountId = :dashboardAccountId];
                if (matchedContacts.isEmpty()) {
                    
                    //No matched contacts, lets make a new one - provided we have an account to create it in.
                    if (dashboardAccountId != null) {
                        Contact newContact = new Contact();
                        newContact.Email = dashboardEmail; 
                        newContact.LastName = dashboardEmail;
                        newContact.AccountId = dashboardAccountId;
                        insert newContact;
                        
                        c.ContactId = newContact.Id;
                    }
                    
                }
                else {
                    //Found contact in the specified account. Use the first one, since even if there's more than one, we have to pick
                    c.ContactId = matchedContacts[0].Id;     			                       
                }
            }
		} 
    }
}