global class EmailFinancePartners{
    @InvocableMethod(label='Email Finance Partners' description='Emails finance partners with relevant information for partners to execute assessment')
    webservice static void sendEmail(List<Id> newOppList){

        Opportunity opps = [Select Id, Amount, License_Term__c, Subsidize_Financing__c, Finance_Partner_Notes__c, AccountId, CloseDate, Balance_Due__c,Sales_Tax__c, S_H_Tax__c,Shipping_and_Handling_Amount__c FROM Opportunity Where Id IN :newOppList];

        Account account = [Select Id, Name, BillingStreet, BillingCity, BillingStateCode, BillingCountryCode, BillingPostalCode, DUNS_Number__c, Website FROM Account Where Id = :opps.AccountId];
                
        String accountaddress = account.BillingStreet+' '+account.BillingCity+', '+account.BillingStateCode+' '+account.BillingPostalCode+' '+account.BillingCountryCode;
        //String accountName_URL = account.Name.replace(' ','+');
        String  opportunity_URL= System.URL.getSalesforceBaseUrl().toExternalForm()+'/'+opps.Id;
        String accountAddress_URL = accountaddress.replace(' ','+');

        String subsidize_string = 'No';
        if(opps.Subsidize_Financing__c) subsidize_string = 'Yes';
        OrgWideEmailAddress owa = [Select Id from OrgWideEmailAddress Where Address = 'deal-desk@samsara.com'];
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setOrgWideEmailAddressId(owa.Id);
            message.setToAddresses(new String[]{'deal-desk@samsara.com'});
            message.setCcAddresses(new String[]{'deal-desk@samsara.com'});
            message.optOutPolicy = 'FILTER';
            message.subject = 'Samsara: Customer Financing Form - '+account.Name;
            String intro = 'Hello, ';
            String email = intro+'\r\n\r\nBilling Name: '+account.Name+'\r\n\r\nBilling Address: '+accountaddress+'\r\n\r\nClose Date: '+opps.CloseDate+'\r\n\r\nOpportunity SFDC Link: '+opportunity_URL+'\r\n\r\nOpportunity Amount: $'+opps.Amount+'\r\n\r\nTerm: '+opps.License_Term__c+' Months\r\n\r\nSales Tax: '+opps.Sales_Tax__c+'\r\n\r\nShipping & Handling: ' + opps.Shipping_and_Handling_Amount__c+'\r\n\r\nTotal Contract Value: ' + opps.Balance_Due__c;
            if(opps.Finance_Partner_Notes__c != ''){
                email = email + '\r\n\r\nNotes: '+opps.Finance_Partner_Notes__c;
            }
            message.plainTextBody = email;

            Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
            if (results[0].success) {
                System.debug('The email was sent successfully.');
            } else {
                System.debug('The email failed to send: ' + results[0].errors[0].message);
            }
       // }
        
    }

}