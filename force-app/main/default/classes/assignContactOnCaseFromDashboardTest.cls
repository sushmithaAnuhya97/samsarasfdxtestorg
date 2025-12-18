@isTest
public class assignContactOnCaseFromDashboardTest {
    static testMethod void insertDashboardCaseFromSamsara() {
        Account aSamsara = new Account(Name='Samsara');
            aSamsara.Type = 'Fleet';
            aSamsara.Industry = 'Other';
            aSamsara.organization_size__c = '1 - 99';
            aSamsara.billingstreet = '123 Main St, San Francisco CA, 94110';
            aSamsara.billingstate = 'California';
            aSamsara.billingcountry = 'United States';
            aSamsara.billingcity = 'San Francisco';
            aSamsara.billingPostalCode = '94110';
            aSamsara.shippingstreet = '123 Main St, San Francisco CA, 94110';
            aSamsara.shippingstate = 'California';
            aSamsara.shippingcountry = 'United States';
            aSamsara.shippingcity = 'San Francisco';
            aSamsara.shippingPostalCode = '94110';
        insert aSamsara;

        Hardcoded_Id__c samsaraAcct = new Hardcoded_Id__c(Name = 'Samsara Account', Id__c = aSamsara.Id);
        insert samsaraAcct;
        
        Account aDummy = new Account(Name ='Dummy');
            aDummy.Type = 'Fleet';
            aDummy.Industry = 'Other';
            aDummy.organization_size__c = '1 - 99';
            aDummy.billingstreet = '201 Potrero St, San Francisco CA, 94113';
            aDummy.billingstate = 'California';
            aDummy.billingcountry = 'United States';
            aDummy.billingcity = 'San Francisco';
            aDummy.billingPostalCode = '94110';
            aDummy.shippingstreet = '201 Potrero St, San Francisco CA, 94113';
            aDummy.shippingstate = 'California';
            aDummy.shippingcountry = 'United States';
            aDummy.shippingcity = 'San Francisco';
            aDummy.shippingPostalCode = '94113';

        system.debug('x - aDummyId = ' + aDummy.Id);
        Database.SaveResult sr = Database.insert(aDummy); 
        Id aDummyRealId = sr.getId();
        
        system.debug('x2 - aDummyRealId = ' + aDummyRealId);
        test.startTest();
        
        Case newCase = new Case();
            newCase.Origin = 'Dashboard';
            newCase.Samsara_Dashboard_Email__c = 'bwaldman@SAMsara.com';
            newCase.Subject = 'xxx123xxx!'; //Instead of using this to search I could get Database.SaveResult to get the new id after the insert, but i'm lazy
            newCase.AccountId = aDummyRealId;    
        insert newCase;
        
        system.debug('x3');
        
        newCase = [SELECT id, Subject, AccountId FROM case WHERE subject = 'xxx123xxx!' LIMIT 1]; //Must re-find newCase after adding it so trigger has run on it.
        
        System.assertEquals(aSamsara.Id, newCase.AccountId); //Verify trigger set new case account to Samsara
        
        test.stopTest();
    }
        
    static testMethod void insertDashboardCaseForMatchedContact() {
        Account aSamsara = new Account(Name='Samsara');
            aSamsara.Type = 'Fleet';
            aSamsara.Industry = 'Other';
            aSamsara.organization_size__c = '1 - 99';
            aSamsara.billingstreet = '123 Main St, San Francisco CA, 94110';
            aSamsara.billingstate = 'California';
            aSamsara.billingcountry = 'United States';
            aSamsara.billingcity = 'San Francisco';
            aSamsara.billingPostalCode = '94110';
            aSamsara.shippingstreet = '123 Main St, San Francisco CA, 94110';
            aSamsara.shippingstate = 'California';
            aSamsara.shippingcountry = 'United States';
            aSamsara.shippingcity = 'San Francisco';
            aSamsara.shippingPostalCode = '94110';
        insert aSamsara;

        Hardcoded_Id__c samsaraAcct = new Hardcoded_Id__c(Name = 'Samsara Account', Id__c = aSamsara.Id);
        insert samsaraAcct;
        
        Account aDummy = new Account(Name ='Dummy');
            aDummy.Type = 'Fleet';
            aDummy.Industry = 'Other';
            aDummy.organization_size__c = '1 - 99';
            aDummy.billingstreet = '123 Larkin St, San Francisco CA, 94113';
            aDummy.billingstate = 'California';
            aDummy.billingcountry = 'United States';
            aDummy.billingcity = 'San Francisco';
            aDummy.billingPostalCode = '94113';
            aDummy.shippingstreet = '123 Larkin St, San Francisco CA, 94113';
            aDummy.shippingstate = 'California';
            aDummy.shippingcountry = 'United States';
            aDummy.shippingcity = 'San Francisco';
            aDummy.shippingPostalCode = '94113';
        insert aDummy;   
        
        Contact aContact = new Contact(LastName ='TestLastName', AccountId=aDummy.Id);
            aContact.email = 'test@test.com';
        insert aContact;
        
        test.startTest();
        
        Case newCase = new Case();
            newCase.Origin = 'Dashboard';
            newCase.Samsara_Dashboard_Email__c = 'test@test.com';
            newCase.AccountId = aDummy.Id; 
            newCase.Subject = 'xxx123xxx!'; //Instead of using this to search I could get Database.SaveResult to get the new id after the insert, but i'm lazy
        insert newCase;
        
        //Verify trigger found contact on specified account aDummy, and set the contact and account fields on the case
        newCase = [SELECT id, ContactId, AccountId FROM case WHERE subject = 'xxx123xxx!' LIMIT 1]; //Must re-find newCase after adding it so trigger has run on it.
        System.assertEquals(newCase.AccountId, aDummy.Id);
        System.assertEquals(newCase.ContactId, aContact.Id);             
        
        test.stopTest();
    }
    
    static testMethod void insertDashboardCaseForUnMatchedContactNoAccount() {
        Account aSamsara = new Account(Name='Samsara');
            aSamsara.Type = 'Fleet';
            aSamsara.Industry = 'Other';
            aSamsara.organization_size__c = '1 - 99';
            aSamsara.billingstreet = '139 Mina St, San Francisco CA, 94116';
            aSamsara.billingstate = 'California';
            aSamsara.billingcountry = 'United States';
            aSamsara.billingcity = 'San Francisco';
            aSamsara.billingPostalCode = '94116';
            aSamsara.shippingstreet = '139 Mina St, San Francisco CA, 94116';
            aSamsara.shippingstate = 'California';
            aSamsara.shippingcountry = 'United States';
            aSamsara.shippingcity = 'San Francisco';
            aSamsara.shippingPostalCode = '94116';
        insert aSamsara;

        Hardcoded_Id__c samsaraAcct = new Hardcoded_Id__c(Name = 'Samsara Account', Id__c = aSamsara.Id);
        insert samsaraAcct;
        
        Account aDummy = new Account(Name ='Dummy');
            aDummy.Type = 'Fleet';
            aDummy.Industry = 'Other';
            aDummy.organization_size__c = '1 - 99';
            aDummy.billingstreet = '123 Main St, San Francisco CA, 94110';
            aDummy.billingstate = 'California';
            aDummy.billingcountry = 'United States';
            aDummy.billingcity = 'San Francisco';
            aDummy.billingPostalCode = '94110';
            aDummy.shippingstreet = '123 Main St, San Francisco CA, 94110';
            aDummy.shippingstate = 'California';
            aDummy.shippingcountry = 'United States';
            aDummy.shippingcity = 'San Francisco';
            aDummy.shippingPostalCode = '94110';
        insert aDummy;   

        test.startTest();
        
        Contact aContact = new Contact(LastName ='TestLastName', AccountId=aDummy.Id);
            aContact.email = 'testNOMATCH@test.com';
        insert aContact;
        
        Case newCase = new Case();
            newCase.Origin = 'Dashboard';
            newCase.Samsara_Dashboard_Email__c = 'test@test.com';
            newCase.Subject = 'xxx123xxx!'; //Instead of using this to search I could get Database.SaveResult to get the new id after the insert, but i'm lazy
        insert newCase;
        
        //Verify trigger matched account with existing contact and set the contact and account fields on the case
        newCase = [SELECT id, ContactId, AccountId FROM case WHERE subject = 'xxx123xxx!' LIMIT 1]; //Must re-find newCase after adding it so trigger has run on it.
        system.assertEquals(null, newCase.ContactId); //Should not be set because we didn't match a contact
        system.assertEquals(null, newCase.AccountId); //Should not be set because we didn't match a contact
        
        test.stopTest();
    }
    
    static testMethod void insertDashboardCaseForUnMatchedContactWithAccount() {
        Account aSamsara = new Account(Name='Samsara');
            aSamsara.Type = 'Fleet';
            aSamsara.Industry = 'Other';
            aSamsara.organization_size__c = '1 - 99';
            aSamsara.billingstreet = '123 Main St, San Francisco CA, 94110';
            aSamsara.billingstate = 'California';
            aSamsara.billingcountry = 'United States';
            aSamsara.billingcity = 'San Francisco';
            aSamsara.billingPostalCode = '94110';
            aSamsara.shippingstreet = '123 Main St, San Francisco CA, 94110';
            aSamsara.shippingstate = 'California';
            aSamsara.shippingcountry = 'United States';
            aSamsara.shippingcity = 'San Francisco';
            aSamsara.shippingPostalCode = '94110';
        insert aSamsara;

        Hardcoded_Id__c samsaraAcct = new Hardcoded_Id__c(Name = 'Samsara Account', Id__c = aSamsara.Id);
        insert samsaraAcct;
        
        Account aDummy = new Account(Name ='Dummy');
            aDummy.Type = 'Fleet';
            aDummy.Industry = 'Other';
            aDummy.organization_size__c = '1 - 99';
            aDummy.billingstreet = '155 Mina St, San Francisco CA, 94104';
            aDummy.billingstate = 'California';
            aDummy.billingcountry = 'United States';
            aDummy.billingcity = 'San Francisco';
            aDummy.billingPostalCode = '94104';
            aDummy.shippingstreet = '155 Mina St, San Francisco CA, 94104';
            aDummy.shippingstate = 'California';
            aDummy.shippingcountry = 'United States';
            aDummy.shippingcity = 'San Francisco';
            aDummy.shippingPostalCode = '94104';
        Database.SaveResult sr = Database.insert(aDummy); 
        Id aDummyRealId = sr.getId();  

        test.startTest();
        
        Contact aContact = new Contact(LastName ='TestLastName', AccountId=aDummy.Id);
            aContact.email = 'testNOMATCH@test.com';
        insert aContact;
        
        Case newCase = new Case();
            newCase.Origin = 'Dashboard';
            newCase.AccountId = aDummyRealId;
            newCase.Samsara_Dashboard_Email__c = 'test@test.com';
            newCase.Subject = 'xxx123xxx!'; //Instead of using this to search I could get Database.SaveResult to get the new id after the insert, but i'm lazy
        insert newCase;
        
        //Verify trigger created new contact in provided account
        newCase = [SELECT id, Contact.Email, Contact.LastName, AccountId FROM case WHERE subject = 'xxx123xxx!' LIMIT 1]; //Must re-find newCase after adding it so trigger has run on it.
        system.assertEquals('test@test.com', newCase.Contact.Email);
        system.assertEquals('test@test.com', newCase.Contact.LastName);
        system.assertEquals(aDummyRealId, newCase.AccountId); //Should not be set because we didn't match a contact
        
        test.stopTest();
    }    
    
    static testMethod void insertDashboardCaseForUnMatchedContactInAccount() {
        //Same as prior test except that a matching account exists, just on a different account. 
        
        Account aSamsara = new Account(Name='Samsara');
            aSamsara.Type = 'Fleet';
            aSamsara.Industry = 'Other';
            aSamsara.organization_size__c = '1 - 99';
            aSamsara.billingstreet = '333 John St, San Francisco CA, 94122';
            aSamsara.billingstate = 'California';
            aSamsara.billingcountry = 'United States';
            aSamsara.billingcity = 'San Francisco';
            aSamsara.billingPostalCode = '94122';
            aSamsara.shippingstreet = '333 John St, San Francisco CA, 94122';
            aSamsara.shippingstate = 'California';
            aSamsara.shippingcountry = 'United States';
            aSamsara.shippingcity = 'San Francisco';
            aSamsara.shippingPostalCode = '94122';
        insert aSamsara;

        Hardcoded_Id__c samsaraAcct = new Hardcoded_Id__c(Name = 'Samsara Account', Id__c = aSamsara.Id);
        insert samsaraAcct;
        
        Account aDummy = new Account(Name ='Dummy');
            aDummy.Type = 'Fleet';
            aDummy.Industry = 'Other';
            aDummy.organization_size__c = '1 - 99';
            aDummy.billingstreet = '123 Main St, San Francisco CA, 94110';
            aDummy.billingstate = 'California';
            aDummy.billingcountry = 'United States';
            aDummy.billingcity = 'San Francisco';
            aDummy.billingPostalCode = '94110';
            aDummy.shippingstreet = '123 Main St, San Francisco CA, 94110';
            aDummy.shippingstate = 'California';
            aDummy.shippingcountry = 'United States';
            aDummy.shippingcity = 'San Francisco';
            aDummy.shippingPostalCode = '94110';
        Database.SaveResult sr = Database.insert(aDummy); 
        Id aDummyRealId = sr.getId();  
       
        Account aDummy2 = new Account(Name ='Dummy Trucking Delivery 2');
            aDummy2.Type = 'Fleet';
            aDummy2.Industry = 'Other';
            aDummy2.organization_size__c = '1 - 99';
            aDummy2.billingstreet = '1024 Main St, San Francisco CA, 94199';
            aDummy2.billingstate = 'California';
            aDummy2.billingcountry = 'United States';
            aDummy2.billingcity = 'San Francisco';
            aDummy2.billingPostalCode = '94199';
            aDummy2.shippingstreet = '1024 Main St, San Francisco CA, 94199';
            aDummy2.shippingstate = 'California';
            aDummy2.shippingcountry = 'United States';
            aDummy2.shippingcity = 'San Francisco';
            aDummy2.shippingPostalCode = '94199';
        sr = Database.insert(aDummy2); 
        Id aDummy2RealId = sr.getId();
        
        test.startTest();
        
        Contact aContact = new Contact(LastName ='TestLastName', AccountId=aDummy.Id);
            aContact.email = 'test@test.com';
            aContact.AccountId = aDummy2RealId; //This should not match because the case is specified for aDummy not aDummy2.
        insert aContact;
        
        Case newCase = new Case();
            newCase.Origin = 'Dashboard';
            newCase.Samsara_Dashboard_Email__c = 'test@test2.com';
            newCase.AccountId = aDummyRealId;
            newCase.Subject = 'xxx123xxx!'; //Instead of using this to search I could get Database.SaveResult to get the new id after the insert, but i'm lazy
        insert newCase;
        
        //Verify trigger matched account with existing contact and set the contact and account fields on the case
        newCase = [SELECT id, ContactId, Contact.Email, AccountId FROM case WHERE subject = 'xxx123xxx!' LIMIT 1]; //Must re-find newCase after adding it so trigger has run on it.
        
        system.assertNotEquals(aContact.Id, newCase.ContactId); //Should be set to a new contact because there's no match on the specified account
        system.assertEquals(aDummyRealId,newCase.AccountId); 
        //system.assertEquals('test@test.com', newCase.Contact.Email); 
        
        test.stopTest();
    }
}