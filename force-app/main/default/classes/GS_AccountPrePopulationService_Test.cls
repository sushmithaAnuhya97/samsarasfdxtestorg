/**********************************************************************
Name: GS_AccountPrePopulationService_Test
=======================================================================
Purpose: This class will contain methods for GS_AccountPrePopulationService test coverage
=======================================================================
History
VERSION     AUTHOR               DATE               DETAIL
1.0        Rodrigo Carpio        2023-Jan-11        INITIAL DEVELOPMENT
***********************************************************************/
@isTest(SeeAllData=false)
public class GS_AccountPrePopulationService_Test {
    Static Account testAccount;
    Static Opportunity testOpportunity;
    // Do not add any insert statements - It will cause CPU Time limit issues. Data insert until the quote is taking aroung 75% of CPU time.
    @testSetup
    private static void testDataSetup() {
        Profile pf= [Select Id from profile where Name='System Administrator'];
        List<User> userList2 = new List<User>();
    User adminUser = new User(
            ProfileId = pf.Id,
            LastName = 'Admin',
             EmployeeNumber='123455',
            Email = 'admin21@testorg.com',
            Username = 'admin21@testorg.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'Title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        userList2.add(adminUser);
 User adminUser2 = new User(
            ProfileId = pf.Id,
            LastName = 'Admin2',
             EmployeeNumber='1234558',
            Email = 'admin22@testorg.com',
            Username = 'admin22@testorg.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'Title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        userList2.add(adminUser2);
        insert userList2; 
        
        UserRole objRoleAE3NA,objRoleENTNA,objRoleAE1NA, objRoleADR;
        System.runAs(adminUser) {
            // Handle all setup objects together
           List<UserRole> objRoleList = new List<UserRole>();
            objRoleAE3NA = new UserRole(Name= 'Fleet IS AE3 NA US Team 8');
            objRoleList.add(objRoleAE3NA);
             objRoleENTNA = new UserRole(Name= 'Fleet ENT AE NA US Team 8');
            objRoleList.add(objRoleENTNA);
             objRoleAE1NA = new UserRole(Name= 'Fleet IS AE1 NA US Team 8');
            objRoleList.add(objRoleAE1NA); 
            objRoleADR= new UserRole(Name= 'Fleet ADR OB NA US Team 5');
            objRoleList.add(objRoleADR);
            insert objRoleList;
            // Insert Custom Setting
            insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
        }

        List<Profile> profileList=[Select id,Name from profile where Name IN ('Samsara Sales - NA US AE3','Samsara ADRs'  )];
        Profile profileAE3,profileADR;
        User objProfileAE3,objProfileADR,objProfileAE1;

        System.runAs(adminUser2){
            for(Profile p: profileList){
            if(p.Name == 'Samsara Sales - NA US AE3'){
                profileAE3 = p;
                }
                if(p.Name == 'Samsara ADRs'){
                    profileADR = p;
                }
            }
            User usrAdr= createUser(profileADR.Id, 'ADR', 'ADR@testorg.com', 'ADR@testorg.com_'+System.currentTimeMillis(), objRoleADR.Id);
            insert usrAdr;
            List<User> userList = new List<User>();
            objProfileAE3 = createUser(profileAE3.Id, 'AE3NA', 'AE3NA@testorg.com', 'AE3NA@testorg.com_'+System.currentTimeMillis(), objRoleAE3NA.Id);
            objProfileADR = createUser(profileADR.Id, 'ENTNA', 'ENTNA@testorg.com', 'ENTNA@testorg.com_'+System.currentTimeMillis(), objRoleENTNA.Id);
            objProfileAE1 = createUser(pf.Id, 'AE1NA', 'AE1NA@testorg.com', 'AE1NA@testorg.com_'+System.currentTimeMillis(), objRoleAE1NA.Id);
            objProfileAE3.ADR_Assignment__c = usrAdr.Id;
            objProfileADR.ADR_Assignment__c = usrAdr.Id;
            objProfileAE1.ADR_Assignment__c = usrAdr.Id;
           
            userList.add(objProfileAE3);
            userList.add(objProfileADR);
            userList.add(objProfileAE1);
            insert userList;  
        }

       

        // Run all non-setup object DML operations in a separate context
        System.runAs(adminUser) {
            TriggerHandler.bypass('AccountTriggerHandler');
            TriggerHandler.bypass('GS_AccountTriggerHandler');
            TriggerHandler.bypass('ContactTriggerHandler');
            TriggerHandler.bypass('GS_ContactTriggerHandler');
            TriggerHandler.bypass('OpportunityTriggerHandler');
            TriggerHandler.bypass('GS_OpportunityTriggerHandler');
            //UserRole objRoleAE3 = [SELECT Id from UserRole where Name Like 'Fleet IS AE3%' limit 1];
            //UserRole objRoleENT = [SELECT Id from UserRole where Name Like 'Fleet ENT%' limit 1];
       

            //User objProfileAE3 = [select Id, IsActive, Profile.Name from User where IsActive = true and Profile.Name = 'Samsara Sales - NA US AE3' order by Id limit 1];
            //User objProfileADR = [select Id, IsActive, Profile.Name from User where IsActive = true and Profile.Name = 'Samsara ADRs' order by Id limit 1];
            //insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
            Samsara_Audit_Toggle__mdt mdt = new Samsara_Audit_Toggle__mdt(DeveloperName = 'Account', MasterLabel  = 'Account', Trigger_Handler__c  = 'GS_AccountTriggerHandler');
            MX_Non_Compliant_Taxpayers__c mx = new MX_Non_Compliant_Taxpayers__c();
            mx.RFC__c  = '12345';
            mx.Status__c  = 'OK';
            mx.Taxpayer_Name__c  = '12345MX';
            insert mx;
        Shipping_Countries__mdt scUS= new Shipping_Countries__mdt(DeveloperName='US', MasterLabel ='US', BillingCountryCode__c='US', Currency__c='USD');
        Shipping_Countries__mdt scMX= new Shipping_Countries__mdt(DeveloperName='MX', MasterLabel ='MX', BillingCountryCode__c='MX', Currency__c='PHP');
        /*String orgId=UserInfo.getOrganizationId();
//String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-',''));
Integer RandomId=Integer.valueOf(Math.rint(Math.random()*1000000));
String uniqueName=orgId+RandomId;
List<User> listUser = new List<User>();
User uu=new User(firstname = 'Test AE3 Role',
lastName = 'Test AE3 Role',
email = uniqueName + '@test' + orgId + '.org',
Username = uniqueName + 'AE3@test' + orgId + '.org',
EmailEncodingKey = 'ISO-8859-1',
Alias = uniqueName.substring(18, 23),
TimeZoneSidKey = 'America/Los_Angeles',
LocaleSidKey = 'en_US',
LanguageLocaleKey = 'en_US',
ProfileId = pf.Id,
UserRoleId = objRoleAE3.Id);
listUser.add(uu);
User uu2=new User(firstname = 'Test ENT Role',
lastName = 'Test ENT Role',
email = uniqueName + '@test' + orgId + '.org',
Username = uniqueName + 'ENT@test' + orgId + '.org',
EmailEncodingKey = 'ISO-8859-1',
Alias = uniqueName.substring(18, 23),
TimeZoneSidKey = 'America/Los_Angeles',
LocaleSidKey = 'en_US',
LanguageLocaleKey = 'en_US',
ProfileId = pf.Id,
UserRoleId = objRoleENT.Id);
listUser.add(uu2);
insert listUser;
*/
        //Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        User objRoleAE3 = objProfileAE3;
        User objRoleENT = objProfileADR;
        User objRoleAE1 = objProfileAE1;
           //Create Products
        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33-BUNDLE', Family = 'Test', Geo_Availablity__c='USA');
        products.add(vg33);
        Product2 vgLicense = new Product2(Name= 'LIC-VG-36MO', ProductCode = 'LIC-VG-36MO', Family = 'Test', Geo_Availablity__c='USA');
        products.add(vgLicense);
        insert products;
        //Create PriceBookEntries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        PricebookEntry vgLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgLicense.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vgLicensePB);
        insert pricebookEntries;
        List<Book_Of_Business__c> listBook = new List<Book_Of_Business__c>();
        Book_Of_Business__c book = new Book_Of_Business__c(Name='Book One', AE__c=objProfileAE3.Id, ADR__c=objProfileADR.Id, Active__c=true);
        listBook.add(book);
        Book_Of_Business__c book2 = new Book_Of_Business__c(Name='Book Two', AE__c=objProfileAE3.Id, ADR__c=objProfileADR.Id, Active__c=true);
        listBook.add(book2);
        Book_Of_Business__c book3 = new Book_Of_Business__c(Name='Book Three', AE__c=objProfileADR.Id, ADR__c=objProfileADR.Id, Active__c=true);
        listBook.add(book3);
        insert listBook;
        // Create account
        String fleetId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Fleet').getRecordTypeId();
        String partnerId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        List<Account> newAccount = new List<Account>();
        List<Task> newTask = new List<Task>();
        Account account = new Account (Name = 'Test Account RODRIGO Canada', Organization_Size__c = '5000+', Record_Type_Stamp_for_Dupes__c = 'Fleet',
                                       RecordTypeId=fleetId,Books_Of_Business__c = listBook[0].Id,Number_of_Powered_Assets__c = 200,
                                       BillingCountry = 'Canada', Industry = 'Other', OwnerId=objRoleAE3.Id, Account_Lifetime_ACV__c=1000, Customer_ARR__c=1000);
        newAccount.add(account);
        Account account2 = new Account (Name = 'Test Account RODRIGO USA', Organization_Size__c = '5000+', BillingCountry = 'United States',Number_of_Powered_Assets__c = 200,
                                        Record_Type_Stamp_for_Dupes__c = 'Fleet', RecordTypeId=fleetId,Books_Of_Business__c = listBook[0].Id,
                                        BillingStateCode='TX', Industry = 'Other', OwnerId=System.Label.SmallFleetAccountOwnerId, Billing_Email__c = 'hajie@yahoo.com',
                                        Account_Lifetime_ACV__c=40000, CSM_Initial_onboarding_completed_Time__c = datetime.now());
        newAccount.add(account2);
        Account account3 = new Account (Name = 'Test Account RODRIGO USA1', Organization_Size__c = '5000+', BillingCountry = 'United States',
                                        Record_Type_Stamp_for_Dupes__c = 'Fleet', RecordTypeId=fleetId,Books_Of_Business__c = listBook[0].Id,
                                        BillingStateCode='TX', Industry = 'Other', OwnerId=objRoleAE3.Id, Account_Lifetime_ACV__c=340000);
        newAccount.add(account3);
        Account account4 = new Account (Name = 'Test Account RODRIGO USA2', Organization_Size__c = '1 - 99', BillingCountry = 'United States',
                                        Record_Type_Stamp_for_Dupes__c = 'Fleet', RecordTypeId=fleetId, Number_of_Vehicles__c =21,Books_Of_Business__c = listBook[1].Id,
                                        BillingStateCode='TX', Industry = 'Other', OwnerId=objRoleAE3.Id, Account_Lifetime_ACV__c=740000);
        newAccount.add(account4);
        Account account5 = new Account (Name = 'Test Account RODRIGO USA - Partner', Organization_Size__c = '5000+', BillingCountry = 'United States',
                                        RecordTypeId=partnerId,Partner_Type__c='Insurance', Program_Type__c='Paid Referral',Books_Of_Business__c = listBook[2].Id,
                                        BillingStateCode='TX', Industry = 'Other', OwnerId=objRoleENT.Id, Account_Lifetime_ACV__c=40000,
                                        CSM_Initial_onboarding_completed_Time__c = datetime.now());
        newAccount.add(account5);
        Account account9 = new Account (Name = 'Test Account RODRIGO USA2 - MX', Organization_Size__c = '5000+', BillingCountry = 'Mexico', Books_Of_Business__c = listBook[2].Id,
                                        BillingStateCode='', Industry = 'Other', Account_Lifetime_ACV__c=10000,NAICS_Code__c = '12345NAIC',
                                        Record_Type_Stamp_for_Dupes__c = 'Fleet', RecordTypeId=fleetId,VATId__c='12345');
        newAccount.add(account9);
        Account account10 = new Account (Name = 'Test Account RODRIGO USA - AE1', Organization_Size__c = '5000+', BillingCountry = 'United States', Books_Of_Business__c = listBook[2].Id,
                                         BillingStateCode='TX', Industry = 'Other', Account_Lifetime_ACV__c=10000,NAICS_Code__c = '12345NAIC',
                                         Record_Type_Stamp_for_Dupes__c = 'Fleet', RecordTypeId=fleetId,VATId__c='12345', OwnerId = objRoleAE1.Id, Number_of_Powered_Assets__c = 5,
                                         Number_of_Unpowered_Assets__c = 5,Number_of_Vehicles__c  = 5);
        newAccount.add(account10);
        /*
Account account6 = new Account (Name = 'Test Account RODRIGO USA1', Organization_Size__c = '5000+', BillingCountry = 'United States',
BillingStateCode='TX', Industry = 'Other', Account_Lifetime_ACV__c=340000);
newAccount.add(account6);
Account account7 = new Account (Name = 'Test Account RODRIGO USA2', Organization_Size__c = '5000+', BillingCountry = 'United States',
BillingStateCode='TX', Industry = 'Other', Account_Lifetime_ACV__c=10000);
newAccount.add(account7);
Account account8 = new Account (Name = 'Test Account RODRIGO USA2', Organization_Size__c = '5000+', BillingCountry = 'United States',
BillingStateCode='TX', Industry = 'Other', Account_Lifetime_ACV__c=0);
newAccount.add(account8);
Account account9 = new Account (Name = 'Test Account RODRIGO USA2', Organization_Size__c = '5000+', BillingCountry = 'United States',
BillingStateCode='TX', Industry = 'Other', Account_Lifetime_ACV__c=10000);
newAccount.add(account9);*/
        insert newAccount;
        Contract cont = new Contract(
            AccountId = newAccount[0].Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            Status = 'Draft'
        );
        insert cont;
        cont.Status = 'Activated';
        update cont;
        // Create Contact
        List<Contact> newContacts = new List<Contact>();
        Contact contact = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'test@test.com', AccountId=newAccount[0].Id);
        newContacts.add(contact);
        Contact contact2 = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'test@test.com', AccountId=newAccount[1].Id);
        newContacts.add(contact2);
    Contact contact3 = new Contact (FirstName = 'SamsaraClient', LastName = 'ADROwned', Email = 'testadrowned@samsaraclient.com', AccountId=account.Id, OwnerId = objProfileADR.Id);
        newContacts.add(contact3);
        
        // Disable triggers during test setup to prevent SOQL limits
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('GS_ContactTriggerHandler');
        insert newContacts;
        TriggerHandler.clearAllBypasses();
        //Create Shipping Address
        List<Shipping_Address__c> shippingAddresses = new  List<Shipping_Address__c>();
        Shipping_Address__c shipTo = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '444 Deharo St'
                                                             , Shipping_City__c = 'San Francisco', Shipping_State__c = 'California', Shipping_Country__c ='United States'
                                                             , Shipping_Zip_Code__c = '95054', Name = 'Ship To One');
        shippingAddresses.add(shipTo);
        Shipping_Address__c shipToTwo = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '610 Park View Dr'
                                                                , Shipping_Address_Line_2__c= 'XYZ', Shipping_City__c = 'Santa Clara'
                                                                , Shipping_State__c = 'California', Shipping_Country__c ='United States'
                                                                , Shipping_Zip_Code__c = '95054', Name = 'Ship To Two');
        shippingAddresses.add(shipToTwo);
        Shipping_Address__c shipToThree = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id,
                                                                  Shipping_Address_Line_1__c = '1 Parliment St'
                                                                  , Shipping_City__c = 'London'
                                                                  , Shipping_Country__c ='United Kingdom'
                                                                  , Shipping_Zip_Code__c = 'SW1A2JR', Name = 'Ship To Three');
        shippingAddresses.add(shipToThree);
        Shipping_Address__c shipToFour = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '1 Parliment St'
                                                                 , Shipping_Address_Line_2__c= 'XYZ'
                                                                 , Shipping_City__c = 'London'
                                                                 , Shipping_Country__c ='United Kingdom'
                                                                 , Shipping_Zip_Code__c = 'SW1A2JR', Name = 'Ship To Four');
        shippingAddresses.add(shipToFour);
        Shipping_Address__c shipToMexico = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '1 Parliment St'
                                                                   , Shipping_Address_Line_2__c= 'XYZ'
                                                                   , Shipping_City__c = 'Mexico'
                                                                   , Shipping_State__c = 'Distrito Federal'
                                                                   , Shipping_Country__c ='Mexico'
                                                                   , Shipping_Zip_Code__c = 'SW1A2JR', Name = 'Ship To Mexico');
        shippingAddresses.add(shipToMexico);
        insert shippingAddresses;
        //Create Opportunity
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = newAccount[0].Id, License_Term__c =36, Pricebook2Id = pricebookId,
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book',
                                                         CloseDate = System.today() + 60, StageName = 'Closed Lost', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');
        newOpportunities.add(revenueOpportunity);
        Opportunity revenueOpportunity5 = new Opportunity( AccountId = newAccount[0].Id, License_Term__c =36, Pricebook2Id = pricebookId, Sub_Type__c = 'Paid Pilot',
                                                          Max_Approved_Discount__c=0, Name = 'Paid Pilot', Price_Book_Name__c = 'Standard Price Book',
                                                          License_End_Date__c = System.today()-15,
                                                          CloseDate = System.today() + 60, StageName = 'Closed Won', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8', Shipping_Address_NEW__c=null);
        newOpportunities.add(revenueOpportunity5);
        Opportunity revenueOpportunity8 = new Opportunity( AccountId = newAccount[0].Id, License_Term__c =36, Pricebook2Id = pricebookId, SBQQ__Renewal__c=true,
                                                          Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book',
                                                          CloseDate = System.today() + 60, StageName = 'Qualified', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');
        newOpportunities.add(revenueOpportunity8);
        Opportunity revenueOpportunity2 = new Opportunity( AccountId = newAccount[1].Id, License_Term__c =36, Pricebook2Id = pricebookId, Type = 'Rebate',
                                                          Max_Approved_Discount__c=0, Name = 'Rebate', Price_Book_Name__c = 'Standard Price Book',
                                                          CloseDate = System.today() + 60, StageName = 'Refunded - Closed', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8', Shipping_Address_NEW__c=null);
        newOpportunities.add(revenueOpportunity2);
        Opportunity revenueOpportunity3 = new Opportunity( AccountId = newAccount[2].Id, License_Term__c =36, Pricebook2Id = pricebookId, Type = 'Remorse Refund',
                                                          Max_Approved_Discount__c=0, Name = 'Remorse Refund', Price_Book_Name__c = 'Standard Price Book',
                                                          CloseDate = System.today() + 60, StageName = 'Refunded - Closed', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8', Shipping_Address_NEW__c=null);
        newOpportunities.add(revenueOpportunity3);
        Opportunity revenueOpportunity6 = new Opportunity( AccountId = newAccount[3].Id, License_Term__c =36, Pricebook2Id = pricebookId,
                                                          Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book',
                                                          CloseDate = System.today() + 60, StageName = 'Qualified', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');
        newOpportunities.add(revenueOpportunity6);
        /*
Opportunity revenueOpportunity4 = new Opportunity( AccountId = newAccount[3].Id, License_Term__c =36, Pricebook2Id = pricebookId, Sub_Type__c = 'Paid Pilot',
Max_Approved_Discount__c=0, Name = 'Paid Pilot', Price_Book_Name__c = 'Standard Price Book',
CloseDate = System.today() + 60, StageName = 'Closed Won', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8', Shipping_Address_NEW__c=null);
newOpportunities.add(revenueOpportunity4);
Opportunity revenueOpportunity6 = new Opportunity( AccountId = newAccount[5].Id, License_Term__c =36, Pricebook2Id = pricebookId,
Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book',
CloseDate = System.today() + 60, StageName = 'Qualified', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');
newOpportunities.add(revenueOpportunity6);
Opportunity revenueOpportunity7 = new Opportunity( AccountId = newAccount[6].Id, License_Term__c =36, Pricebook2Id = pricebookId,
Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book',
CloseDate = System.today() + 60, StageName = 'Closed Won', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');
newOpportunities.add(revenueOpportunity7);
Opportunity revenueOpportunity8 = new Opportunity( AccountId = newAccount[7].Id, License_Term__c =36, Pricebook2Id = pricebookId,
Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book',
CloseDate = System.today() + 60, StageName = 'Qualified', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');
newOpportunities.add(revenueOpportunity8);
Opportunity revenueOpportunity9 = new Opportunity( AccountId = newAccount[8].Id, License_Term__c =36, Pricebook2Id = pricebookId,
Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book',
CloseDate = System.today() + 60, StageName = 'Closed Lost', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');
newOpportunities.add(revenueOpportunity9);*/
        insert newOpportunities;
        TriggerHandler.clearAllBypasses();
        /*//Create Quote
List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version One', SBQQ__Account__c = account.Id, SBQQ__Opportunity2__c=revenueOpportunity.Id, SBQQ__Primary__c = false);
newQuotes.add(quote);
insert newQuotes;
//Create QuoteLines
List<SBQQ__QuoteLine__c> newQuoteLines = new List<SBQQ__QuoteLine__c>();
SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = vg33PB.Id, SBQQ__Quantity__c  = 5,
SBQQ__Discount__c = 0, SBQQ__Product__c = vg33.Id);
newQuoteLines.add(quoteLineOne);
SBQQ__QuoteLine__c quoteLineTwo =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = vgLicensePB.Id, SBQQ__Quantity__c  = 5,
SBQQ__Discount__c =0, SBQQ__Product__c = vgLicense.Id);
newQuoteLines.add(quoteLineTwo);
insert newQuoteLines;*/
        } // End of System.runAs block
    }
    private static User createUser(Id profileid, String lastName, String email, String username, Id userRoleId){
        User adminUser = new User(
            ProfileId = profileid,
            LastName = lastName,
             EmployeeNumber='123455',
            Email = email,
            Username = username,
            CompanyName = 'TEST',
            Title = 'Title',
            UserRoleId = userRoleId,
            Alias = email.substring(0, 4),
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
           Territory__c='Central' 
        );
        return adminUser; 
     
    }
    /*  @isTest static void testAccount_MXPartner()
{
Test.startTest();
Account mxAccnt = [SELECT Id,OwnerId from Account where Name = 'Test Account RODRIGO USA - Partner'];
User objRoleENT = [select Id, IsActive, UserRole.Name from User where IsActive = true and ADR_Assignment__c != null and UserRole.Name like 'Fleet ENT AE NA US%' limit 1];
Contact contact = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'test@test.com', AccountId=mxAccnt.Id);
insert contact;
mxAccnt.Status__c = 'Paid Pilot';
mxAccnt.NAICS_Code__c = '12345NAIC';
mxAccnt.Billing_First_Name__c = 'hajie@yahoo.com';
mxAccnt.Phone = '5125687839';
mxAccnt.Validation_Complete__c = true;
mxAccnt.BillingCountry = 'Mexico';
mxAccnt.BillingState = '';
mxAccnt.Customer_ARR__c = 750000;
mxAccnt.Number_of_Vehicles__c  = 26;
mxAccnt.Send_to_My_ADR__c = true;
mxAccnt.Billing_Contact__c = contact.Id;
system.RunAS(new user(Id=mxAccnt.OwnerId)){
mxAccnt.OwnerId = objRoleENT.Id;
update mxAccnt;
//mxAccnt.Partner_Type__c = 'Commercial';
update mxAccnt;
mxAccnt.Partner_Type__c = 'Insurance';
mxAccnt.Program_Type__c='Premium Discount';
update mxAccnt;
}
Test.stopTest();
}
@isTest static void testAccount_MX()
{
Test.startTest();
Account mxAccnt = [SELECT Id,OwnerId from Account where Name = 'Test Account RODRIGO USA2'];
User objRoleENT = [select Id, IsActive, UserRole.Name from User where IsActive = true and ADR_Assignment__c != null and UserRole.Name like 'Fleet ENT AE NA US%' limit 1];
Contact contact = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'test@test.com', AccountId=mxAccnt.Id);
insert contact;
mxAccnt.Status__c = 'Paid Pilot';
mxAccnt.NAICS_Code__c = '12345NAIC';
mxAccnt.Billing_Email__c = 'hajie@yahoo.com';
mxAccnt.Phone = '5125687839';
mxAccnt.Validation_Complete__c = true;
mxAccnt.BillingCountry = 'Mexico';
mxAccnt.BillingState = '';
mxAccnt.Customer_ARR__c = 750000;
mxAccnt.Number_of_Vehicles__c  = 26;
mxAccnt.Send_to_My_ADR__c = true;
mxAccnt.Billing_Contact__c = contact.Id;
system.RunAS(new user(Id=mxAccnt.OwnerId)){
mxAccnt.OwnerId = objRoleENT.Id;
update mxAccnt;
}
Test.stopTest();
}*/
    @isTest static void testAccount_USA()
    {
        Test.startTest();
        List<Account> newAccount = new List<Account>();
        newAccount = [SELECT Id,OwnerId from Account where Name Like 'Test Account RODRIGO%'];
        newAccount[1].Status__c = 'Paid Pilot';
        //newAccount[0].Send_to_My_ADR__c = true;
        newAccount[1].Billing_Email__c = 'hajie@yahoo.com';
        newAccount[1].Phone = '5125687839';
        newAccount[1].Validation_Complete__c = true;
        newAccount[1].Customer_ARR__c = 30000;
        newAccount[1].CSM_Initial_onboarding_completed_Time__c = datetime.now();
        newAccount[1].Account_Lifetime_ACV__c = 30000;
        newAccount[1].Netsuite_Delinquent_Status__c = 'Written-Off';
        //newAccount[1].Billing_Contact__c
        newAccount[0].Status__c = 'Existing Customer';
        //newAccount[0].Send_to_My_ADR__c = true;
        newAccount[0].Billing_Email__c = 'hajie@yahoo.com';
        newAccount[0].Phone = '5125687839';
        newAccount[1].Account_Lifetime_ACV__c = 0;
        newAccount[0].Number_of_Vehicles__c  = 26;
        newAccount[0].Number_of_unpowered_assets__c= 35;
        newAccount[0].Number_of_powered_assets__c = 35;
        //newAccount[1].ParentId = newAccount[0].Id;
        //newAccount[0].OwnerId=System.Label.SmallFleetAccountOwnerId;
        newAccount[0].Billing_Email__c = 'hajie@yahoo.com';
        newAccount[0].Initiate_Round_Robin__c = true;
        newAccount[0].Push_to_Webstore__c = true;
        update newAccount;
        Test.stopTest();
    }
    @isTest static void testAccount_USA_2()
    {
        Test.startTest();
        List<Account> newAccount = new List<Account>();
        newAccount = [SELECT Id from Account where Name Like 'Test Account RODRIGO%'];
        newAccount[3].Status__c = 'Existing Customer';
        newAccount[3].Customer_ARR__c = 30000;
        newAccount[3].Account_Lifetime_ACV__c = 30000;
        newAccount[3].Status__c = 'Paid Pilot';
        newAccount[3].Initiate_Round_Robin__c = true;
        update newAccount;
        Test.stopTest();
    }
    /*
    @isTest static void testAccount_CA() {
        Test.startTest();
        List<Account> newAccount = new List<Account>();
        String fleetId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Fleet').getRecordTypeId();
        User objRoleAE3 = [select Id, IsActive, UserRole.Name, ADR_Assignment__c from User where IsActive = true and ADR_Assignment__c != null and UserRole.Name like '%Fleet IS AE3 NA US%' AND LastName='AE3NA' limit 1];
        User objRoleENT = [select Id, IsActive, UserRole.Name from User where IsActive = true and ADR_Assignment__c != null and UserRole.Name like '%Fleet ENT AE NA US%' AND LastName='ENTNA' limit 1];
        Account account = new Account (Name = 'Test Account MX', Organization_Size__c = '5000+', BillingCountry = 'Canada', Number_of_Vehicles__c =50,
                                       Industry = 'Other', VATId__c='12345', Overwrite_Validation_Rule__c=true, OwnerId= objRoleENT.Id,SIC__c=objRoleENT.Id, CSM__c=objRoleENT.Id,
                                       Record_Type_Stamp_for_Dupes__c = 'Fleet', RecordTypeId=fleetId, BigCommerce_Id__c = '2234544');
        newAccount.add(account);
        insert newAccount;
        Contract contr = new Contract(
            AccountId = newAccount[0].Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            Status = 'Draft'
        );
        insert contr;
        Contact contact = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'test@test.com', AccountId=newAccount[0].Id);
        insert contact;
        newAccount[0].Status__c = 'New';
        newAccount[0].NAICS_Code__c = '12345NAIC';
        newAccount[0].Billing_Email__c = 'hajie@yahoo.com';
        newAccount[0].Phone = '5125687839';
        newAccount[0].Validation_Complete__c = true;
        newAccount[0].Customer_ARR__c = 750000;
        newAccount[0].Number_of_Vehicles__c  = 26;
        newAccount[0].Billing_Contact__c = contact.Id;
        newAccount[0].Send_to_My_ADR__c = true;
        newAccount[0].OwnerId = objRoleAE3.Id;
        newAccount[0].Latest_Active_Contract__c = contr.id;
        newAccount[0].Push_to_Webstore__c = true;
        update newAccount[0];
        Test.stopTest();
    }
    @isTest static void testAccount_MX0() {
        Test.startTest();
        List<Account> newAccount = new List<Account>();
        String fleetId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Fleet').getRecordTypeId();
        User objRoleAE3 = [select Id, IsActive, UserRole.Name, ADR_Assignment__c from User where IsActive = true and ADR_Assignment__c != null and UserRole.Name like '%Fleet IS AE3 NA US%' AND LastName='AE3NA' limit 1];
        User objRoleENT = [select Id, IsActive, UserRole.Name from User where IsActive = true and ADR_Assignment__c != null and UserRole.Name like '%Fleet ENT AE NA US%' AND LastName= 'ENTNA' limit 1];
        Account account = new Account (Name = 'Test Account MX', Organization_Size__c = '5000+', BillingCountry = 'Mexico',
                                       Industry = 'Other', VATId__c='12345', Overwrite_Validation_Rule__c=true, OwnerId= objRoleAE3.Id,SIC__c=objRoleAE3.Id, CSM__c=objRoleAE3.Id,
                                       Record_Type_Stamp_for_Dupes__c = 'Fleet', RecordTypeId=fleetId);
        newAccount.add(account);
        insert newAccount;
        Contact contact = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'test@test.com', AccountId=newAccount[0].Id);
        insert contact;
        newAccount[0].Status__c = 'New';
        newAccount[0].NAICS_Code__c = '12345NAIC';
        newAccount[0].Billing_Email__c = 'hajie@yahoo.com';
        newAccount[0].Phone = '5125687839';
        newAccount[0].Validation_Complete__c = true;
        newAccount[0].Customer_ARR__c = 750000;
        newAccount[0].Number_of_Vehicles__c  = 26;
        newAccount[0].Send_to_My_ADR__c = true;
        newAccount[0].Billing_Contact__c = contact.Id;
        newAccount[0].OwnerId = objRoleENT.Id;
        update newAccount[0];
        Test.stopTest();
    }
    */
    @isTest static void testAccount0() {
        Test.startTest();
        List<Account> newAccount = new List<Account>();
        Account account = new Account (Name = 'Test Account ' + System.now().getTime(), Organization_Size__c = '5000+', BillingCountry = 'United States', BillingStateCode='TX',
                                       Number_of_Powered_Assets__c = 200,
                                       Industry = 'Other', OwnerId=System.Label.SmallFleetAccountOwnerId, Billing_Email__c = 'hajie@yahoo.com');
        newAccount.add(account);
        insert newAccount;
        Id pricebookId = Test.getStandardPricebookId();
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = newAccount[0].Id, License_Term__c =36, Pricebook2Id = pricebookId,
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book',
                                                         CloseDate = System.today() + 60, StageName = 'Qualified', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');
        newOpportunities.add(revenueOpportunity);
        insert newOpportunities;
        newAccount[0].Status__c = 'Existing Customer';
        //newAccount[0].Send_to_My_ADR__c = true;
        newAccount[0].Billing_First_Name__c = 'hajie@yahoo.com';
        newAccount[0].Phone = '5125687839';
        newAccount[0].Validation_Complete__c = true;
        newAccount[0].Customer_ARR__c = 40000;
        newAccount[0].CSM_Initial_onboarding_completed_Time__c = datetime.now();
        newAccount[0].Account_Lifetime_ACV__c = 40000;
        newAccount[0].Netsuite_Delinquent_Status__c = 'Written-Off';
        //newAccount[0].OwnerId=System.Label.SmallFleetAccountOwnerId;
        update newAccount[0];
        Test.stopTest();
    }
    @isTest static void testAccountPartner() {
        Test.startTest();
        String partnerId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        List<Account> newAccount = new List<Account>();
        Account account = new Account (Name = 'Test Account US', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingStateCode='TX',
                                       Industry = 'Other', OwnerId=System.Label.SmallFleetAccountOwnerId, Billing_Email__c = 'hajie@yahoo.com',
                                       RecordTypeId=partnerId, Partner_Type__c='Insurance', Program_Type__c='Paid Referral');
        newAccount.add(account);
        insert newAccount;
        Id pricebookId = Test.getStandardPricebookId();
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = newAccount[0].Id, License_Term__c =36, Pricebook2Id = pricebookId,
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book',
                                                         CloseDate = System.today() + 60, StageName = 'Qualified', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');
        newOpportunities.add(revenueOpportunity);
        insert newOpportunities;
        newAccount[0].Status__c = 'Existing Customer';
        //newAccount[0].Send_to_My_ADR__c = true;
        newAccount[0].Billing_First_Name__c = 'hajie@yahoo.com';
        newAccount[0].Phone = '5125687839';
        newAccount[0].Validation_Complete__c = true;
        newAccount[0].Customer_ARR__c = 30000;
        newAccount[0].CSM_Initial_onboarding_completed_Time__c = datetime.now();
        newAccount[0].Account_Lifetime_ACV__c = 30000;
        newAccount[0].Netsuite_Delinquent_Status__c = 'Written-Off';
        //newAccount[0].BillingCountryCode = 'MX';
        //newAccount[0].BillingStateCode = '';
        //newAccount[0].OwnerId=System.Label.SmallFleetAccountOwnerId;
        update newAccount[0];
        //newAccount[0].Program_Type__c=null;
        newAccount[0].OwnerId=System.Label.SmallFleetAccountOwnerId;
        update newAccount[0];
        Test.stopTest();
    }
    @isTest static void testAccountPartner2() {
        Test.startTest();
        String partnerId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        List<Account> newAccount = new List<Account>();
        Account account = new Account (Name = 'Test Account US', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingStateCode='TX',
                                       Industry = 'Other', OwnerId=System.Label.SmallFleetAccountOwnerId, Billing_Email__c = 'hajie@yahoo.com',
                                       RecordTypeId=partnerId, Partner_Type__c='Insurance', Program_Type__c='Subsidy', Status__c = 'Existing Customer',
                                       Customer_ARR__c = 35000, Account_Lifetime_ACV__c= 35000);
        newAccount.add(account);
        insert newAccount;
        Id pricebookId = Test.getStandardPricebookId();
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = newAccount[0].Id, License_Term__c =36, Pricebook2Id = pricebookId,
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book',
                                                         CloseDate = System.today() + 60, StageName = 'Qualified', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');
        newOpportunities.add(revenueOpportunity);
        insert newOpportunities;
        //newAccount[0].Partner_Type__c = 'Commercial';
        //newAccount[0].Send_to_My_ADR__c = true;
        newAccount[0].Billing_First_Name__c = 'hajie@yahoo.com';
        newAccount[0].Phone = '5125687839';
        newAccount[0].Validation_Complete__c = true;
        //newAccount[0].Customer_ARR__c = 30000;
        newAccount[0].CSM_Initial_onboarding_completed_Time__c = datetime.now();
        //newAccount[0].Account_Lifetime_ACV__c = 30000;
        newAccount[0].Netsuite_Delinquent_Status__c = 'Written-Off';
        //newAccount[0].BillingCountryCode = 'MX';
        //newAccount[0].BillingStateCode = '';
        //newAccount[0].OwnerId=System.Label.SmallFleetAccountOwnerId;
        update newAccount[0];
        newAccount[0].Partner_Type__c = 'Insurance';
        newAccount[0].Program_Type__c='Premium Discount';
        update newAccount[0];
        Test.stopTest();
    }
    @isTest static void testAccount1() {
        Test.startTest();
        List<Account> newAccount = new List<Account>();
        Account account = new Account (Name = 'Test Account ' + System.now().getTime(), Organization_Size__c = '5000+', BillingCountry = 'United States', BillingStateCode='TX', Industry = 'Other');
        newAccount.add(account);
        insert newAccount;
        Id pricebookId = Test.getStandardPricebookId();
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = newAccount[0].Id, License_Term__c =36, Pricebook2Id = pricebookId,
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book',
                                                         CloseDate = System.today() + 60, StageName = 'Closed Won', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');
        newOpportunities.add(revenueOpportunity);
        insert newOpportunities;
        newAccount[0].Status__c = 'New';
        //newAccount[0].Send_to_My_ADR__c = true;
        newAccount[0].Billing_Email__c = 'hajie@yahoo.com';
        newAccount[0].Phone = '5125687839';
        newAccount[0].Validation_Complete__c = true;
        newAccount[0].Customer_ARR__c = 30000;
        newAccount[0].CSM_Initial_onboarding_completed_Time__c = datetime.now();
        newAccount[0].Account_Lifetime_ACV__c = 30000;
        newAccount[0].Netsuite_Delinquent_Status__c = 'Written-Off';
        update newAccount[0];
        Test.stopTest();
    }
    @isTest static void testAccount_MX1() {
        Test.startTest();
        List<Account> newAccount = new List<Account>();
        Account account = new Account (Name = 'Test Account MX', Organization_Size__c = '5000+', BillingCountry = 'Mexico', Industry = 'Other');
        newAccount.add(account);
        insert newAccount;
        newAccount[0].Status__c = 'New';
        //newAccount[0].Send_to_My_ADR__c = true;
        newAccount[0].Billing_Email__c = 'hajie@yahoo.com';
        newAccount[0].Phone = '5125687839';
        newAccount[0].Validation_Complete__c = true;
        newAccount[0].Customer_ARR__c = 750000;
        update newAccount[0];
        Test.stopTest();
    }
    @isTest static void testMultiAccount() {
        Test.startTest();
        List<Account> newAccount = new List<Account>();
        Account account = new Account (Name = 'Test Account ' + System.now().getTime(), Organization_Size__c = '5000+', BillingCountry = 'United States', BillingStateCode='TX', Industry = 'Other');
        newAccount.add(account);
        Account account2 = new Account (Name = 'Test Account ' + System.now().getTime(), Organization_Size__c = '5000+', BillingCountry = 'United States', BillingStateCode='TX', Industry = 'Other');
        newAccount.add(account2);
        insert newAccount;
        Id pricebookId = Test.getStandardPricebookId();
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = newAccount[0].Id, License_Term__c =36, Pricebook2Id = pricebookId,
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book',
                                                         CloseDate = System.today() + 60, StageName = 'Closed Lost', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');
        newOpportunities.add(revenueOpportunity);
        Opportunity revenueOpportunity2 = new Opportunity( AccountId = newAccount[1].Id, License_Term__c =36, Pricebook2Id = pricebookId, Type = 'Rebate',
                                                          Max_Approved_Discount__c=0, Name = 'Rebate', Price_Book_Name__c = 'Standard Price Book',
                                                          CloseDate = System.today() + 60, StageName = 'Refunded - Closed', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8', Shipping_Address_NEW__c=null);
        newOpportunities.add(revenueOpportunity2);
        Opportunity revenueOpportunity3 = new Opportunity( AccountId = newAccount[1].Id, License_Term__c =36, Pricebook2Id = pricebookId, Type = 'Remorse Refund',
                                                          Max_Approved_Discount__c=0, Name = 'Remorse Refund', Price_Book_Name__c = 'Standard Price Book',
                                                          CloseDate = System.today() + 60, StageName = 'Refunded - Closed', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8', Shipping_Address_NEW__c=null);
        newOpportunities.add(revenueOpportunity3);
        Opportunity revenueOpportunity4 = new Opportunity( AccountId = newAccount[1].Id, License_Term__c =36, Pricebook2Id = pricebookId, Sub_Type__c = 'Paid Pilot',
                                                          Max_Approved_Discount__c=0, Name = 'Paid Pilot', Price_Book_Name__c = 'Standard Price Book',
                                                          CloseDate = System.today() + 60, StageName = 'Closed Won', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8', Shipping_Address_NEW__c=null);
        newOpportunities.add(revenueOpportunity4);
        Opportunity revenueOpportunity5 = new Opportunity( AccountId = newAccount[0].Id, License_Term__c =36, Pricebook2Id = pricebookId, Sub_Type__c = 'Paid Pilot',
                                                          Max_Approved_Discount__c=0, Name = 'Paid Pilot', Price_Book_Name__c = 'Standard Price Book',
                                                          License_End_Date__c = System.today()-15,
                                                          CloseDate = System.today() + 60, StageName = 'Closed Won', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8', Shipping_Address_NEW__c=null);
        newOpportunities.add(revenueOpportunity5);
        insert newOpportunities;
        newAccount[0].Status__c = 'New';
        //newAccount[0].Send_to_My_ADR__c = true;
        newAccount[0].Billing_Email__c = 'hajie@yahoo.com';
        newAccount[0].Customer_ARR__c = 450000;
        update newAccount[0];
        Test.stopTest();
    }
    @isTest static void testMultiAccount2() {
        Test.startTest();
        List<Account> newAccount = new List<Account>();
        Account account = new Account (Name = 'Test Account ' + System.now().getTime(), Organization_Size__c = '5000+', BillingCountry = 'United States', BillingStateCode='TX', Industry = 'Other');
        newAccount.add(account);
        Account account2 = new Account (Name = 'Test Account ' + System.now().getTime(), Organization_Size__c = '5000+', BillingCountry = 'United States', BillingStateCode='TX', Industry = 'Other');
        newAccount.add(account2);
        insert newAccount;
        Id pricebookId = Test.getStandardPricebookId();
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = newAccount[0].Id, License_Term__c =36, Pricebook2Id = pricebookId,
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book',
                                                         CloseDate = System.today() + 60, StageName = 'Closed Lost', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');
        newOpportunities.add(revenueOpportunity);
        Opportunity revenueOpportunity2 = new Opportunity( AccountId = newAccount[1].Id, License_Term__c =36, Pricebook2Id = pricebookId, Type = 'Rebate',
                                                          Max_Approved_Discount__c=0, Name = 'Rebate', Price_Book_Name__c = 'Standard Price Book',
                                                          CloseDate = System.today() + 60, StageName = 'Refunded - Closed', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8', Shipping_Address_NEW__c=null);
        newOpportunities.add(revenueOpportunity2);
        Opportunity revenueOpportunity3 = new Opportunity( AccountId = newAccount[1].Id, License_Term__c =36, Pricebook2Id = pricebookId, Type = 'Remorse Refund',
                                                          Max_Approved_Discount__c=0, Name = 'Remorse Refund', Price_Book_Name__c = 'Standard Price Book',
                                                          CloseDate = System.today() + 60, StageName = 'Refunded - Closed', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8', Shipping_Address_NEW__c=null);
        newOpportunities.add(revenueOpportunity3);
        Opportunity revenueOpportunity4 = new Opportunity( AccountId = newAccount[1].Id, License_Term__c =36, Pricebook2Id = pricebookId, Sub_Type__c = 'Paid Pilot',
                                                          Max_Approved_Discount__c=0, Name = 'Paid Pilot', Price_Book_Name__c = 'Standard Price Book',
                                                          CloseDate = System.today() + 60, StageName = 'Closed Won', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8', Shipping_Address_NEW__c=null);
        newOpportunities.add(revenueOpportunity4);
        Opportunity revenueOpportunity5 = new Opportunity( AccountId = newAccount[0].Id, License_Term__c =36, Pricebook2Id = pricebookId, Sub_Type__c = 'Paid Pilot',
                                                          Max_Approved_Discount__c=0, Name = 'Paid Pilot', Price_Book_Name__c = 'Standard Price Book',
                                                          License_End_Date__c = System.today()-15,
                                                          CloseDate = System.today() + 60, StageName = 'Closed Won', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8', Shipping_Address_NEW__c=null);
        newOpportunities.add(revenueOpportunity5);
        insert newOpportunities;
        newAccount[0].BillingCountryCode = 'MX';
        newAccount[0].BillingStateCode = '';
        newAccount[0].VATId__c = '1234546';
        newAccount[0].NAICS_Code__c = '1234567';
        newAccount[0].Customer_ARR__c = 150000;
        newAccount[0].Number_of_Vehicles__c  = 26;
        newAccount[1].Netsuite_Delinquent_Status__c = 'Written-off';
        newAccount[1].NAICS_Code__c = '1234567';
        newAccount[1].Status__c = 'New';
        //newAccount[1].Send_to_My_ADR__c = true;
        newAccount[1].Billing_Email__c = 'hajie@yahoo.com';
        newAccount[1].Overwrite_Validation_Rule__c = true;
        //newAccount[1].First_Purchase_Date__c = system.today().addDays(-5);
        newAccount[1].ownerid = System.Label.SmallFleetAccountOwnerId;
        newAccount[1].Customer_ARR__c = 10000;
        update newAccount;
        Test.stopTest();
    }
    @isTest
    static void testTaskCreation_PublicSector()
    {
        List<Account> newAccounts = new List<Account>();
        Account account = new Account (Name = 'public works 1', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingStateCode='TX', Industry = 'Other',
                                       Number_of_Unpowered_Assets__c = 200, Sub_Industry__c = 'Local');
        newAccounts.add(account);
        Test.startTest();
        insert newAccounts;
        Test.stopTest();
        //List<Task> tasks = [SELECT Id FROM Task WHERE WhatId IN:newAccounts AND RecordType.DeveloperNAme = 'Task'];
        //System.assertEquals(5, tasks.size(), 'Expected same number of tasks');
    }
    @isTest
    static void testTaskCreation()
    {
        List<Account> newAccounts = new List<Account>();
        Account account = new Account (Name = 'test account 1', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingStateCode='TX', Industry = 'Other',
                                       Number_of_Unpowered_Assets__c = 200);
        newAccounts.add(account);
        Test.startTest();
        insert newAccounts;
        Test.stopTest();
        //List<Task> tasks = [SELECT Id FROM Task WHERE WhatId IN:newAccounts AND RecordType.DeveloperNAme = 'Task'];
        //System.assertEquals(5, tasks.size(), 'Expected same number of tasks');
    }
    @isTest static void testAccEventFailureCallback() {
        Test.StartTest();
        PlatformEventCallback PEC = new PlatformEventCallback();
        Account_Sync_event__e accSyncEvt = (Account_Sync_event__e)Account_Sync_event__e.sObjectType.newSObject(null, true);
        accSyncEvt.Id__c ='12345678901234567890';
        EventBus.publish(accSyncEvt, PEC);
        Test.getEventBus().fail();
        Test.StopTest();
    }
    @isTest static void testAccEventSuccessCallback() {
        PlatformEventCallback PECS = new PlatformEventCallback();
        Account_Sync_event__e accSyncEvtS = (Account_Sync_event__e)Account_Sync_event__e.sObjectType.newSObject(null, true);
        accSyncEvtS.Id__c ='01234567890123456789';
        EventBus.publish(accSyncEvtS, PECS);
        Test.getEventBus().deliver();
    }
    @isTest
    static void testTaskCreation_onChange_unpowered_assets()
    {
        List<Account> newAccounts = new List<Account>();
        Account account = new Account (Name = 'test account 1', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingStateCode='TX', Industry = 'Other',
                                       Number_of_Unpowered_Assets__c = 200);
        newAccounts.add(account);
        Account acc = [Select Id from Account Limit 1];
        Test.startTest();
        acc.Number_of_unpowered_assets__c = 10;
        update acc;
        //insert newAccounts;
        Test.stopTest();
        //List<Task> tasks = [SELECT Id FROM Task WHERE WhatId IN:newAccounts AND RecordType.DeveloperNAme = 'Task'];
        //System.assertEquals(5, tasks.size(), 'Expected same number of tasks');
    }
    @isTest
    static void testTaskCreation_onchange_Number_of_powered_assets()
    {
        List<Account> newAccounts = new List<Account>();
        Account account = new Account (Name = 'test account 1', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingStateCode='TX', Industry = 'Other',
                                       Number_of_Unpowered_Assets__c = 200);
        newAccounts.add(account);
        Account acc = [Select Id from Account Limit 1];
        Test.startTest();
        acc.Number_of_powered_assets__c = 10;
        update acc;
        // insert newAccounts;
        Test.stopTest();
        //List<Task> tasks = [SELECT Id FROM Task WHERE WhatId IN:newAccounts AND RecordType.DeveloperNAme = 'Task'];
        //System.assertEquals(5, tasks.size(), 'Expected same number of tasks');
    }
    @isTest static void testAccount_updatingQuoteBillingAddress()
    {
        Account mxAccnt = [SELECT Id,OwnerId from Account where Name = 'Test Account RODRIGO USA - Partner'];
        Opportunity oppt = [Select Id from opportunity where isClosed = false Limit 1];
        Test.startTest();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version One', SBQQ__Account__c = mxAccnt.Id, SBQQ__Opportunity2__c=oppt.Id, SBQQ__Primary__c = false,Bill_to_Account__c = mxAccnt.Id);
        opportunity  opp = new opportunity ();
        opp.DCA_Enabled__c = 'DCA';
        opp.Is_Webstore_Upsell_Opportunity__c = false;
        opp.Small_Fleet_Opportunity__c = false;
        opp.Id = oppt.Id;
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        SBQQ.TriggerControl.disable();
        update opp;
        insert quote;
        SBQQ.TriggerControl.enable();
        TriggerHandler.clearAllBypasses();
        mxAccnt.Billing_Email__c = 'Test@gmail.com';
        update mxAccnt;
        Test.stopTest();
    }
    /*
@isTest static void testAccountInsertsAndUpdate() {
Map<ID, Schema.RecordTypeInfo> rt_Map = Account.sObjectType.getDescribe().getRecordTypeInfosById();
List<Account> updateList = new List<Account>();
Profile p = [SELECT Id FROM Profile WHERE Name = 'Samsara Inbound ADRs'];
String orgId = UserInfo.getOrganizationId();
String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
String uniqueName = orgId + dateString + randomInt;
User u = new User(lastName = 'blah',
email = uniqueName + '@test' + orgId + '.org',
Username = uniqueName + '@test' + orgId + '.org',
EmailEncodingKey = 'ISO-8859-1',
Alias = uniqueName.substring(18, 23),
TimeZoneSidKey = 'America/Los_Angeles',
LocaleSidKey = 'en_US',
LanguageLocaleKey = 'en_US',
ProfileId = p.Id,
EmployeeNumber='123');
insert u;
Account acc = [SELECT Id FROM Account LIMIT 1];
for(Account a : [SELECT Id, RecordTypeId, CSM_First_30d_Stage__c FROM Account]) {
a.RecordTypeId = rt_Map.values()[0].getRecordTypeId();
a.OwnerId = u.Id;
a.Overwrite_Validation_Rule__c = true;
a.Record_Type_Stamp_for_Dupes__c = 'Fleet';
a.Unload_Account__c = true;
a.Status__c = 'Existing Customer';
a.Global_Geography__c = 'Canada';
if(a.CSM_First_30d_Stage__c == 'Additional followup needed'){
a.CSM_First_30d_Stage__c = 'Pending Intro';
}
else if(a.CSM_First_30d_Stage__c == 'Pending Intro'){
a.CSM_First_30d_Stage__c = 'Pending Delivery';
}
else if(a.CSM_First_30d_Stage__c == 'Pending Delivery'){
a.CSM_First_30d_Stage__c = 'Attempting Training';
}
else if(a.CSM_First_30d_Stage__c == 'Attempting Training'){
a.CSM_First_30d_Stage__c = 'Scheduled Training';
}
else if(a.CSM_First_30d_Stage__c == 'Scheduled Training'){
a.CSM_First_30d_Stage__c = 'Health Check';
}
else if(a.CSM_First_30d_Stage__c == 'Health Check'){
a.CSM_First_30d_Stage__c = 'Scheduled Additional Training';
a.Validation_Complete__c = true;
}
else if(a.CSM_First_30d_Stage__c == 'Health Check'){
a.CSM_First_30d_Stage__c = 'Scheduled Additional Training';
a.Validation_Complete__c = true;
}
updateList.add(a);
}
if(updateList.size() > 0) {
Test.startTest();
update updateList;
Test.stopTest();
}
}
*/
    @isTest
    static void testIsStateRampLicenseValidation() {
        // Setup test data with multiple StateRamp accounts under the same SAM Number
        Account oldAccount1 = new Account(Name = 'Old StateRamp Account',SAM_Number_Undecorated__c = 'SAM001',IsStateRamp_Flag__c = true,Organization_Size__c = '1 - 99',BillingCountry = 'United States',BillingState = 'New York');
        Account oldAccount2 = new Account(Name = 'Old Non-StateRamp Account',SAM_Number_Undecorated__c = 'SAM001',IsStateRamp_Flag__c = false,Organization_Size__c = '1 - 99',BillingCountry = 'United States',BillingState = 'New York');
        Account additionalStateRampAccount = new Account(Name = 'Additional StateRamp Account',SAM_Number_Undecorated__c = 'SAM001',IsStateRamp_Flag__c = true,Organization_Size__c = '1 - 99',BillingCountry = 'United States',BillingState = 'New York');
        insert new List<Account>{oldAccount1, oldAccount2, additionalStateRampAccount};
            
        // Prepare updates that violate validation rules
        Account updatedAccount1 = new Account(Id = oldAccount1.Id,Name = 'Updated StateRamp Account',SAM_Number_Undecorated__c = 'SAM002',IsStateRamp_Flag__c = true,Organization_Size__c = '1 - 99',BillingCountry = 'United States',BillingState = 'New York');
        Account updatedAccount2 = new Account(Id = oldAccount2.Id,Name = 'Updated Non-StateRamp Account',SAM_Number_Undecorated__c = 'SAM002', IsStateRamp_Flag__c = false,Organization_Size__c = '1 - 99',BillingCountry = 'United States',BillingState = 'New York');
        
        Test.startTest();
        try {
            // Attempt to update with validation logic
            update new List<Account>{updatedAccount1, updatedAccount2};
        } catch (DmlException e) {
        }
        Test.stopTest();
    }
    @isTest
    static void testPreventLastStateRampDeletion() {
        // Setup test data with multiple StateRamp accounts under the same SAM Number
        Account stateRampAccount1 = new Account(Name = 'StateRamp Account 1',SAM_Number_Undecorated__c = 'SAM003',IsStateRamp_Flag__c = true,Organization_Size__c = '1 - 99',BillingCountry = 'United States',BillingState = 'New York');
        Account stateRampAccount2 = new Account(Name = 'StateRamp Account 2',SAM_Number_Undecorated__c = 'SAM003',IsStateRamp_Flag__c = true,Organization_Size__c = '1 - 99',BillingCountry = 'United States',BillingState = 'New York');
        insert new List<Account>{stateRampAccount1, stateRampAccount2};
            
            Test.startTest();
        try {
            delete stateRampAccount1;
        } catch (DmlException e) {
            //System.assert(false, 'Unexpected exception during deletion: ' + e.getMessage());
        }
        
        try {
            delete stateRampAccount2;
        } catch (DmlException e) {
        }
        Test.stopTest();
    }
@isTest
private static void testGlobalGeographyOthersForUnmappedState() {
    // Setup test data
    Account testAccount = new Account(
        Name = 'Test Account',
        Organization_Size__c = '1 - 99',BillingCountry = 'United States',BillingState = 'American Samoa',
        BillingStateCode = 'AS',  // Use a state code that doesn't exist in StateCode_Global_Geography__mdt
        BillingCountryCode = 'US' // Use a country code that exists in CountryCode_Global_Geography__mdt
    );
    
    // Act
    Test.startTest();
    insert testAccount;
    Test.stopTest();
    
    // Assert
    Account updatedAccount = [SELECT Id, Global_Geography__c FROM Account WHERE Id = :testAccount.Id];
    
}
@isTest
    static void testHandleAccountUpdate() {
        bypass();
        
        // Create a fresh account that will have no First_Purchase_Date__c initially
        Account testAccount = new Account(
            Name = 'Test Account for First Purchase Date',
            Organization_Size__c = '1 - 99',
            BillingCountry = 'United States',
            BillingStateCode = 'CA',
            Industry = 'Other',
            Account_Lifetime_ACV__c = 5000
        );
        insert testAccount;
        
         Contact testContact = new Contact(
            LastName = 'Test Contact',
            AccountId = testAccount.Id,
            HasOptedOutOfEmail = true,
            Email_Resource_Opt_In__c = false,
            Email_Newsletter_Opt_In__c = false, 
            Email_Surveys_Opt_In__c = false,
            Email_Using_Samsara_Opt_In__c = false,
            Email_Product_Ann_Updates_Opt_In__c = false
        );
        // Disable triggers during test setup to prevent SOQL limits
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('GS_ContactTriggerHandler');
        insert testContact;
        TriggerHandler.clearAllBypasses();
       
        Test.startTest();
        
        Account oldAccount = [SELECT Id, First_Purchase_Date__c, Lifetime_ACV_to_USD__c 
                                  FROM Account WHERE Id = :testAccount.Id LIMIT 1];
        
        Id pricebookId = Test.getStandardPricebookId();
        Opportunity revenueOpportunity = new Opportunity(
            AccountId = testAccount.Id, 
            License_Term__c = 36, 
            Pricebook2Id = pricebookId,
            Amount = 1000,
            Max_Approved_Discount__c = 0, 
            Name = 'Revenue Opportunity', 
            Price_Book_Name__c = 'Standard Price Book',
            CloseDate = System.today(), 
            StageName = 'Closed Won', 
            Owner_Role_Copy__c = 'Fleet IS AE2 NA US Team 8'
        );
        insert revenueOpportunity;
        
        Account newAccount = [SELECT Id, First_Purchase_Date__c, Lifetime_ACV_to_USD__c 
                                  FROM Account WHERE Id = :testAccount.Id LIMIT 1];
        
       Map<Id, Account> oldMap = new Map<Id, Account>{newAccount.Id => oldAccount};
       List<Account> newList = new List<Account>{newAccount};
        
                GS_AccountWorkflowConversionService.handleAccountUpdate(newList, oldMap);
        
        Test.stopTest();
    }
  
    public static void bypass() {
        
        SBQQ.TriggerControl.disable();
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('GS_ContactTriggerHandler');
        TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        OpportunityTriggerHandler.addCall('beforeUpdate');
        OpportunityTriggerHandler.addCall('afterUpdate');
        OpportunityTriggerHandler.addCall('afterInsert');
    }
	/*	
	@isTest
    static void test_updateOpportunityOwnerBasedAccOwner() {
        bypass(); // disables triggers/automation if implemented
        Account acc = new Account(
            Name = 'Test Account ' + System.now().getTime(),
            Organization_Size__c = '1 - 99',
            BillingCountry = 'United States',
            BillingState = 'California',
            BillingCity = 'San Francisco',
            BillingStreet = '123 Main St',
            BillingPostalCode = '94110'
        );
        insert acc;
        Opportunity opp = new Opportunity(Name = 'Test Opp', AccountId = acc.Id, StageName = 'Prospecting', CloseDate = System.today().addDays(10));
        insert opp;
        Map<Id, Account> oldAccountMap = new Map<Id, Account>();
        List<Account> newAccountList = new List<Account>{acc};
        GS_AccountPrePopulationService.updateOpportunityOwnerBasedAccOwner(oldAccountMap, newAccountList);
    }
	*/

    /*@isTest
    static void test_revertOpportunityOwner() {
        bypass(); // disables triggers/automation if implemented
        Account acc = new Account(
            Name = 'Test Account ' + System.now().getTime(),
            Organization_Size__c = '1 - 99',
            BillingCountry = 'United States',
            BillingState = 'California',
            BillingCity = 'San Francisco',
            BillingStreet = '123 Main St',
            BillingPostalCode = '94110'
        );
        insert acc;
        Opportunity opp = new Opportunity(Name = 'Test Opp', AccountId = acc.Id, StageName = 'Prospecting', CloseDate = System.today().addDays(10));
        insert opp;
        Map<Id, Id> mapOppOldOwner = new Map<Id, Id>{opp.Id => UserInfo.getUserId()};
        GS_AccountPrePopulationService.revertOpportunityOwner(mapOppOldOwner);
    }*/

    @isTest
    static void test_updateZendeskFlag() {
		bypass();
        GS_AccountPrePopulationService.updateZendeskFlag(new List<Account>(), new Map<Id, Account>());
    }

	@isTest
    static void test_populatePOCFields() {
		bypass();
        Account acc = new Account(
            Name = 'POC Test Account ' + System.now().getTime(),
            Organization_Size__c = '1 - 99',
            BillingCountry = 'United States',
            BillingState = 'California',
            BillingCity = 'San Francisco',
            BillingStreet = '123 Main St',
            BillingPostalCode = '94110',
            Billing_Email__c = 'test@example.com',
            Billing_First_Name__c = 'John',
            Billing_Phone__c = '1234567890'
        );
        insert acc;

        GS_AccountPrePopulationService svc = new GS_AccountPrePopulationService();
        svc.populatePOCFields(acc);

        System.assert(
            acc.CS_POC_Email_Address__c == acc.Billing_Email__c &&
            acc.CS_POC_First_Name__c == acc.Billing_First_Name__c &&
            acc.CS_POC_Phone__c == acc.Billing_Phone__c,
            'POC fields should be populated from billing fields'
        );
    }

    @isTest
    static void test_updateUltimateParentCheck() {
		bypass();
        // Create an Account with required fields
        Account acc = new Account(
            Name = 'Ultimate Parent Test ' + System.now().getTime(),
            Organization_Size__c = '1 - 99',
            BillingCountry = 'United States',
            BillingState = 'California',
            BillingCity = 'San Francisco',
            BillingStreet = '123 Main St',
            BillingPostalCode = '94110'
        );
        insert acc;

        // Call the method with the inserted Account's Id
        GS_AccountPrePopulationService svc = new GS_AccountPrePopulationService();
        svc.updateUltimateParentCheck(new Set<Id>{acc.Id});

        // Query the Account to verify the field was updated
        Account updated = [SELECT Is_Ultimate_Parent__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(true, updated.Is_Ultimate_Parent__c, 'Is_Ultimate_Parent__c should be set to true');
    }
	@isTest
    static void test_updateUltimateAccount() {
        bypass();
        
        List<Account> listOfAccounts = [Select id,
                                      name,
                                      BillingCountry,
                                      BillingState,
                                      Industry,
                                      Organization_Size__c,
                                      Is_Ultimate_Parent__c,
                                      Ultimate_Parent__c,
                                      ParentId,
                                      MX_Non_Compliant_Tax_Payer__c,
                                      VATId__c
                                      from Account LIMIT 4];
        
		// Create ultimate parent account
        Account ultimateParent = listOfAccounts[0];
        Account intermediateParent = listOfAccounts[1];
        Account childAccount1 = listOfAccounts[2];
        Account childAccount2 = listOfAccounts[3];
        
        ultimateParent.Is_Ultimate_Parent__c = true;
        
        intermediateParent.Ultimate_Parent__c = ultimateParent.Id;
        intermediateParent.ParentId = ultimateParent.Id;
        intermediateParent.VATId__c = '12345'; 
        
        childAccount2.Ultimate_Parent__c = ultimateParent.Id;
        childAccount2.ParentId = ultimateParent.Id;
        update listOfAccounts;
        
        Map<String,Account> TaxIdAccountMap = new Map<String,Account>();
        TaxIdAccountMap.put('12345',intermediateParent);
        
        Test.startTest();
        // Create old account map
        Map<Id, Account> oldAccountMap = new Map<Id, Account>();
        oldAccountMap.put(childAccount1.Id, new Account(Id = childAccount1.Id, ParentId = null));
        oldAccountMap.put(childAccount2.Id, new Account(Id = childAccount2.Id, ParentId = ultimateParent.Id));
        // Update accounts: child1 gets parent, child2 loses parent
        childAccount1.ParentId = intermediateParent.Id;
        childAccount2.ParentId = null;
        List<Account> accountsToUpdate = new List<Account>{ childAccount1, childAccount2 };
        // Create service instance and call the method
        GS_AccountPrePopulationService service = new GS_AccountPrePopulationService();
        service.updateUltimateAccount(accountsToUpdate, oldAccountMap);
        service.processAccounts(TaxIdAccountMap);
        Test.stopTest();
        Account updatedUltimateParent = [SELECT Id, Is_Ultimate_Parent__c FROM Account WHERE Id = :ultimateParent.Id];
        
    }
	/*@isTest
    static void test_updateOpportunityOwnerBasedAccOwner() {
		bypass();
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt1 = Integer.valueOf(math.rint(math.random()*1000000));
        Integer randomInt2 = randomInt1 + 1;

        User oldOwner = new User(
            LastName = 'OldOwner',
            Email = 'oldowner' + orgId + dateString + randomInt1 + '@test.com',
            Username = 'oldowner' + orgId + dateString + randomInt1 + '@test.com',
            Alias = 'oldown',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            EmployeeNumber = '123',
            IsActive = true
        );
        User newOwner = new User(
            LastName = 'NewOwner',
            Email = 'newowner' + orgId + dateString + randomInt2 + '@test.com',
            Username = 'newowner' + orgId + dateString + randomInt2 + '@test.com',
            Alias = 'newown',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            EmployeeNumber = '124',
            IsActive = true
        );
        insert new List<User>{oldOwner, newOwner};

        System.runAs(oldOwner) {
            // Create Account with old owner
            Account acc = new Account(
                Name = 'Test Account ' + System.now().getTime(),
                Organization_Size__c = '1 - 99',
                BillingCountry = 'United States',
                BillingState = 'California',
                BillingCity = 'San Francisco',
                BillingStreet = '123 Main St',
                BillingPostalCode = '94110',
                OwnerId = oldOwner.Id
            );
            insert acc;

            // Create Opportunity with required LeadSource
            Opportunity opp = new Opportunity(
                Name = 'Test Opp',
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = System.today().addDays(10),
                LeadSource = 'Partner business registration'
            );
            insert opp;

            // Simulate owner change: create a new Account instance with the same Id but new owner
            Account accNew = acc.clone(false, true, false, false);
            accNew.Id = acc.Id;
            accNew.OwnerId = newOwner.Id;

            // oldAccountMap: old version (before change)
            Map<Id, Account> oldAccountMap = new Map<Id, Account>{acc.Id => acc};
            // newAccountList: new version (after change)
            List<Account> newAccountList = new List<Account>{accNew};
			Test.startTest();
            // Call the method
            GS_AccountPrePopulationService.updateOpportunityOwnerBasedAccOwner(oldAccountMap, newAccountList);
			Test.stopTest();
            // Assert Opportunity owner was updated
            //Opportunity updatedOpp = [SELECT OwnerId FROM Opportunity WHERE Id = :opp.Id];
            //System.assertEquals(newOwner.Id, updatedOpp.OwnerId, 'Opportunity owner should be updated to new Account owner');
        }
    }*/
	
    @isTest
    static void test_updateCSMDetails() {
		bypass();
        // Create old and new Account values
        Account acc = new Account(
            Name = 'CSM Test Account',
            Organization_Size__c = '1 - 99',
            BillingCountry = 'United States',
            BillingState = 'California',
            BillingCity = 'San Francisco',
            BillingStreet = '123 Main St',
            BillingPostalCode = '94110',
            CS_Tier__c = 'Plus' // new value
            // SIC__c left null
        );
        insert acc;

        // Simulate the old Account with a different CS_Tier__c
        Account oldAcc = acc.clone(false, true, false, false);
        oldAcc.CS_Tier__c = 'None'; // old value

        // Prepare parameters
        Map<Id, Account> oldAccountMap = new Map<Id, Account>{acc.Id => oldAcc};
        List<Account> newAccountList = new List<Account>{acc};

        // Call the method (instance method)
        GS_AccountPrePopulationService svc = new GS_AccountPrePopulationService();
        svc.updateCSMDetails(oldAccountMap, newAccountList);

        // (Optional) Query the account and assert that fields were updated
        // Account updatedAcc = [SELECT RR_Assignment_Rule__c, RR_Assignment_Mapping__c, Account_Assignment_Date__c FROM Account WHERE Id = :acc.Id];
        // System.assertNotEquals(null, updatedAcc.RR_Assignment_Rule__c, 'Assignment rule should be set');
    }
	@isTest
    static void testTaskCreation_USQueue()
    {
            List<Account> newAccounts = new List<Account>();
            Account account = new Account (Name = 'public works 1', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingStateCode='TX', Industry = 'Other',
                                           Sub_Industry__c = 'Local',Number_of_Vehicles__c=40);
            newAccounts.add(account);
    
            Test.startTest();
            insert newAccounts;
            Test.stopTest();
    }
	@isTest
    static void testUpdateContactOwner() {
        
       List<User> testUsers = [SELECT Id, LastName, Email, ProfileId 
                               FROM User 
                               WHERE LastName IN ('Admin', 'Admin2', 'AE3NA', 'ENTNA', 'AE1NA', 'ADR')
                               AND IsActive = true
                               ORDER BY LastName
                               LIMIT 2];
        
        User originalOwner = testUsers[0];
        User newOwner = testUsers[1];
        // Create test account with original owner
        Account testAccount = new Account(
            Name = 'Test Account',
            OwnerId = originalOwner.Id,
            BillingCountry = 'United States',
            BillingState = 'California',
            Industry = 'Technology',
            Organization_Size__c = '5000+'
        );
        TriggerHandler.bypass('AccountTriggerHandler');
        insert testAccount;
        // Create test contacts
        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 1; i <= 3; i++) {
            testContacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                Email = 'test' + i + '@example.com',
                AccountId = testAccount.Id,
                OwnerId = originalOwner.Id,
                New_Inbound_Lead__c = true
            ));
        }
        // Disable triggers during test setup to prevent SOQL limits
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('GS_ContactTriggerHandler');
        
        insert testContacts;
        TriggerHandler.clearAllBypasses();
        Test.startTest();
        // Create old account map
        Map<Id, Account> oldAccountMap = new Map<Id, Account>();
        oldAccountMap.put(testAccount.Id, new Account(Id = testAccount.Id, OwnerId = originalOwner.Id));
        // Update account owner and call the method
        testAccount.OwnerId = newOwner.Id;
         TriggerHandler.bypass('AccountTriggerHandler');
        update testAccount;
        GS_AccountPrePopulationService.updateContactOwner(new List<Account>{ testAccount }, oldAccountMap);
        Test.stopTest();
        // Verify contacts were updated
        List<Contact> updatedContacts = [SELECT Id, OwnerId, New_Inbound_Lead__c FROM Contact WHERE AccountId = :testAccount.Id];
        System.assertEquals(3, updatedContacts.size(), 'Should have 3 contacts');
        for (Contact con : updatedContacts) {
            System.assertEquals(newOwner.Id, con.OwnerId, 'Contact owner should be updated');
            System.assertEquals(false, con.New_Inbound_Lead__c, 'New_Inbound_Lead__c should be false');
        }
    }
    @isTest
    static void testPopulateGeographySegment() {
        // 1. Create test Account
        Account acc = new Account(Name = 'Test Account', BillingState = 'Alabama', Organization_Size__c = '1 - 99', BillingCountry = 'United States');
        insert acc;

        // 3. Simulate an update where BillingState changed
        Account accUpdated = [SELECT Id, BillingState FROM Account WHERE Id = :acc.Id];
        accUpdated.BillingState = 'California'; // assume CA exists in CMDT
        update accUpdated;

        Map<Id, Account> oldAccountMap = new Map<Id, Account>{
            acc.Id => acc
        };

        List<Account> updatedAccounts = new List<Account>{ accUpdated };

        Test.startTest();
        new GS_AccountPrePopulationService().populateGeographySegment(updatedAccounts, oldAccountMap);
        Test.stopTest();
    }
	
}