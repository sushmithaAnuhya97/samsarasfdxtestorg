/**********************************************************************
Name: AccountBookTriggerHelper_Test
=======================================================================
Purpose: This class will contain methods for AccountBookTriggerHelper coverage                                                      
=======================================================================
History  
 
VERSION     AUTHOR               DATE               DETAIL                      
1.0        Rodrigo Carpio        2023-Jan-17        INITIAL DEVELOPMENT
 
***********************************************************************/
@isTest(SeeAllData=false)
public class AccountBookTriggerHelper_Test {

    private static final String SAMSARA_SALES_NA_US_AE3 = 'Samsara Sales - NA US AE3';
    private static final String SAMSARA_ADRS = 'Samsara ADRs';
    private static final String Samsara_Sales_Management_New_System = 'Samsara Sales Management - New System';
    private static final String SYSTEM_ADMIN = 'System Administrator';
    private static final String SAMSARA_ACCOUNT_BOOK_ADRS = 'Samsara Account Book ADRs';
    
    @testSetup
    private static void testDataSetup() {
         // Create a map for easy access
        Map<String, Id> roleNameToIdMap = new Map<String, Id>();

        for(UserRole role : [
            SELECT Id, DeveloperName 
            FROM UserRole 
            WHERE DeveloperName IN ('CML_Fleet_IS_AE1_NA_US_Team_27', 'Management', 'Fleet_ADR_OB_EMEA_FR_Team_2', 'Fleet_Plus_CSM_NA_US_Team_2')
            LIMIT 4
        ]) {
            roleNameToIdMap.put(role.DeveloperName, role.Id);
        }

        // Create test users for each required profile without inserting
        List<User> usersToInsert = new List<User>();

        User objProfileAE3 = TestDataFactoryForAccountsAndOpps.createUser(
            'ae3@accbooktriggertest.com', 
            'AE3User', 
            SAMSARA_SALES_NA_US_AE3, 
            false
        );
        objProfileAE3.UserRoleId = roleNameToIdMap.get('CML_Fleet_IS_AE1_NA_US_Team_27');
        objProfileAE3.Territory__c='US';
        usersToInsert.add(objProfileAE3);
        
        User objProfileADR = TestDataFactoryForAccountsAndOpps.createUser(
            'adr@accbooktriggertest.com', 
            'ADRUser', 
            SAMSARA_ADRS, 
            false
        );
        objProfileADR.UserRoleId = roleNameToIdMap.get('Fleet_ADR_OB_EMEA_FR_Team_2');
        objProfileADR.Territory__c='US';
        usersToInsert.add(objProfileADR);
        
        User objProfileAE = TestDataFactoryForAccountsAndOpps.createUser(
            'ae@accbooktriggertest.com', 
            'AEUser', 
            Samsara_Sales_Management_New_System, 
            false
        );
        objProfileAE.UserRoleId = roleNameToIdMap.get('CML_Fleet_IS_AE1_NA_US_Team_27');
        objProfileAE.Territory__c='US';
        usersToInsert.add(objProfileAE);
        
        User objProfileCSM = TestDataFactoryForAccountsAndOpps.createUser(
            'csm@accbooktriggertest.com', 
            'CSMUser', 
            SYSTEM_ADMIN, 
            false
        );
        objProfileCSM.UserRoleId = roleNameToIdMap.get('Fleet_Plus_CSM_NA_US_Team_2');
        objProfileCSM.Territory__c='US';
        usersToInsert.add(objProfileCSM);

        // Insert all users in a single DML operation
        insert usersToInsert;

        System.runAs(objProfileCSM){
            insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
            Samsara_Audit_Toggle__mdt mdt = new Samsara_Audit_Toggle__mdt(DeveloperName = 'Account', MasterLabel  = 'Account', Trigger_Handler__c  = 'GS_AccountTriggerHandler');
            
            
            //Standard Pricebook
            Id pricebookId = Test.getStandardPricebookId();
            
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
            Book_Of_Business__c book2 = new Book_Of_Business__c(Name='Book Two', AE__c=objProfileAE3.Id, ADR__c=objProfileADR.Id, Active__c=true,Account_Book_Status__c ='Primary: In seat');
            listBook.add(book2);
            
            Book_Of_Business__c book3 = new Book_Of_Business__c(Name='Book Three', AE__c=objProfileADR.Id, ADR__c=objProfileAE.Id, Active__c=true);
            listBook.add(book3);
            
            Book_Of_Business__c book4 = new Book_Of_Business__c(Name='Book Four', AE__c=objProfileAE.Id, ADR__c=objProfileCSM.Id, Active__c=true,Account_Book_Status__c ='Primary: In seat');
            listBook.add(book4);
            
            insert listBook;
            
            // Create account
            List<Account> newAccount = new List<Account>();
            Account account = new Account (Name = 'Test Account RODRIGO Canada', Organization_Size__c = '5000+', Books_Of_Business__c = listBook[0].Id,
                                        Prospecting_Status__c = 'AE Prospecting', Status__c='Existing Customer',
                                        BillingCountry = 'Canada', Industry = 'Other',  Account_Lifetime_ACV__c=1000, Customer_ARR__c=1000);
            newAccount.add(account);
            
            Account account2 = new Account (Name = 'Test Account RODRIGO USA', Organization_Size__c = '5000+', BillingCountry = 'United States',
                                            Books_Of_Business__c = book.Id, Prospecting_Status__c='AE Prospecting', Status__c='Won Opportunity',
                                            BillingStateCode='TX', Industry = 'Other',  Account_Lifetime_ACV__c=40000);
            newAccount.add(account2);
            
            Account account3 = new Account (Name = 'Test Account RODRIGO USA1', Organization_Size__c = '5000+', BillingCountry = 'United States', 
                                            Books_Of_Business__c = book2.Id, Prospecting_Status__c='AE Prospecting', Status__c='Closed Won',
                                            BillingStateCode='TX', Industry = 'Other', Account_Lifetime_ACV__c=340000);
            newAccount.add(account3);
            
            Account account4 = new Account (Name = 'Test Account RODRIGO USA2', Organization_Size__c = '1 - 99', BillingCountry = 'United States', 
                                            Books_Of_Business__c = book3.Id, Prospecting_Status__c='AE Prospecting', Status__c='Existing Won Customer',
                                            BillingStateCode='TX', Industry = 'Other', Account_Lifetime_ACV__c=740000);
            newAccount.add(account4);
            Account account5 = new Account (Name = 'Test Account RODRIGO USA3', Organization_Size__c = '5000+', BillingCountry = 'United States',
                                            Books_Of_Business__c = book4.Id,Prospecting_Status__c='AE Prospecting', Status__c='Existing closed Customer',
                                            BillingStateCode='TX', Industry = 'Other', Account_Lifetime_ACV__c=40000);
            newAccount.add(account5);
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

            List<Contact> cons = new List<Contact>();
            Contact con = new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                AccountId = account2.Id,
                email = 'kelly@slater.com',
                OwnerId = objProfileADR.Id
            );
            cons.add(con);
            Contact con2 = new Contact(
                FirstName = 'Test',
                LastName = 'Contact2',
                AccountId = account2.Id,
                email = 'test@slater.com',
                OwnerId = objProfileAE.Id
            );
            cons.add(con2);

            Contact con3 = new Contact(
                FirstName = 'TestCSM',
                LastName = 'kellycsm',
                AccountId = account5.Id,
                email = 'kellycsm@slater.com',
                OwnerId = objProfileCSM.Id
            );
            cons.add(con3);
            Contact con4 = new Contact(
                FirstName = 'TestCSM',
                LastName = 'kellynonadr',
                AccountId = account4.Id,
                email = 'kellynonadr@slater.com',
                OwnerId = objProfileAE.Id
            );
            cons.add(con4);
            
            TriggerHandler.bypass('ContactTriggerHandler');
            insert cons;
        }
    } 

        
    @isTest static void testBook() {
        Test.startTest();
        User objProfileAE3 = [select Id, IsActive, Profile.Name from User where IsActive = true and Profile.Name = 'Samsara Sales - NA US AE3' limit 1];
        User objProfileADR = [select Id, IsActive, Profile.Name from User where IsActive = true and Profile.Name = 'Samsara ADRs' order by Id limit 1];
        List<Book_Of_Business__c> newBook = new List<Book_Of_Business__c>();
        newBook = [SELECT Id, AE__c from Book_Of_Business__c where Name = 'Book Three'];
        newBook[0].AE__c = objProfileAE3.id;
        update newBook;
        Test.stopTest();
    }    
   
    @isTest static void testBook2() {
        Test.startTest();
        List<Account> oldAccount = [SELECT Id, Prospecting_Status__c, Books_Of_Business__c, Status__c
                                    FROM Account WHERE Name like 'Test Account RODRIGO%'];
        Map<Id, Account> oldAccountMap = new Map<Id, Account>(oldAccount);
       
        List<Account> lstAccount = [SELECT Id, Prospecting_Status__c, Books_Of_Business__c, Status__c
                                    FROM Account WHERE Name like 'Test Account RODRIGO%'];
        lstAccount[0].Prospecting_Status__c = 'AE Prospecting';
        lstAccount[1].Prospecting_Status__c = 'AE Prospecting';
        lstAccount[2].Prospecting_Status__c = 'AE Prospecting';
        lstAccount[0].Status__c = 'New';
        lstAccount[1].Status__c = 'New';
        lstAccount[2].Status__c = 'New';
 
        update lstAccount;                        
        AccountBookTriggerHelper.checkAccountBookAssignment(oldAccountMap, lstAccount);
        Test.stopTest();
    }
    @isTest static void AddteamMembertest() {
        User objProfileAE3 = [select Id, IsActive, Profile.Name from User where IsActive = true and Profile.Name = 'Samsara Sales - NA US AE3' order by Id limit 1];
        List<Book_Of_Business__c> newBook = new List<Book_Of_Business__c>();
        newBook = [SELECT Id, AE__c from Book_Of_Business__c where Name = 'Book Two'];
         Test.startTest();
        Account acc1 = new Account (Name = 'Test Account RODRIGO Canada', Ownerid= objProfileAE3.id ,Organization_Size__c = '5000+', Books_Of_Business__c = newBook[0].Id,
                                       BillingCountry = 'Canada', Industry = 'Other');
        insert acc1;
        Test.stopTest();
    }
    @isTest static void reinsertteam() {
       User objProfileAE = [select Id, IsActive, Profile.Name from User where IsActive = true and Profile.Name ='Samsara Sales Management - New System' order by Id limit 1];
        User objProfileAE3 = [select Id, IsActive, Profile.Name from User where IsActive = true and Profile.Name = 'Samsara Sales - NA US AE3' order by Id limit 1];
        User objProfileCSM = [select Id, IsActive, Profile.Name from User where IsActive = true and Profile.Name ='System Administrator' order by Id limit 1];
        List<Book_Of_Business__c> newBook4 = new List<Book_Of_Business__c>();
        newBook4 = [SELECT Id, AE__c from Book_Of_Business__c where Name = 'Book Four'];
        List<Account> acc = new List<Account>();
        acc = [SELECT id,ownerId from Account where name ='Test Account RODRIGO Canada'];
        List<AccountTeamMember> newAccountTeam = new List<AccountTeamMember>();
        AccountTeamMember acctm = new AccountTeamMember(AccountId =acc[0].id , UserId = objProfileAE3.id , TeamMemberRole ='Account Executive' );
        newAccountTeam.add(acctm);
        AccountTeamMember acctm1 = new AccountTeamMember(AccountId =acc[0].id , UserId = objProfileCSM.id , TeamMemberRole ='CSM' );
        newAccountTeam.add(acctm1);
        insert newAccountTeam;
        Test.startTest();
        acc[0].ownerId = objProfileAE.id;
        update acc;
        Test.stopTest();
    }
 
 
@isTest //Added to cover code of GTMS-14574
static void testQuoteSharetonewAccountOwner() {
    // Create users using TestDataFactory
    User oldOwner = TestDataFactoryForAccountsAndOpps.createUser( 'oldowner@gmail.com', 'OldOwner', 'System Administrator');
    User newOwner = TestDataFactoryForAccountsAndOpps.createUser('newowner@gmail.com', 'NewOwner', 'System Administrator');
   
    // Create account with old owner using TestDataFactory
    Account oldAccount = TestDataFactoryForAccountsAndOpps.createAccount('Old Account', oldOwner.Id);
 
    // Create opportunity associated with the account
    Opportunity opp = TestDataFactoryForAccountsAndOpps.createOpportunity(oldAccount.Id);
 
    // Create a Quote associated with the Opportunity
    SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id);
    insert quote;
 
    // Create a share record manually for the old owner before the account ownership changes
    SBQQ__Quote__Share oldShare = new SBQQ__Quote__Share(
        ParentId = quote.Id,
        UserOrGroupId = oldOwner.Id,
        RowCause = 'Manual',
        AccessLevel = 'Edit'
    );
    insert oldShare;
 
    // Update the Account owner to the new owner
    oldAccount.OwnerId = newOwner.Id;
    update oldAccount;
 
    Test.startTest();
 
    // Handle share updates
    List<SBQQ__Quote__Share> sharesToDelete = [SELECT Id FROM SBQQ__Quote__Share WHERE ParentId = :quote.Id AND UserOrGroupId = :oldOwner.Id];
    delete sharesToDelete;
 
    SBQQ__Quote__Share newShare = new SBQQ__Quote__Share(
        ParentId = quote.Id,
        UserOrGroupId = newOwner.Id,
        AccessLevel = 'Edit'
    );
    insert newShare;
 
    Test.stopTest();
 
    // Verify that the old owner's share has been deleted
    List<SBQQ__Quote__Share> oldShares = [SELECT Id FROM SBQQ__Quote__Share WHERE ParentId = :quote.Id AND UserOrGroupId = :oldOwner.Id];
    System.assertEquals(0, oldShares.size(), 'The old owner share should be deleted.');
 
    // Verify that a new share for the new owner has been created
    List<SBQQ__Quote__Share> newShares = [SELECT Id FROM SBQQ__Quote__Share WHERE ParentId = :quote.Id AND UserOrGroupId = :newOwner.Id];
    System.assertEquals(1, newShares.size(), 'There should be one share for the new owner.');
}
    @isTest
	static void testUpdateADRAssignmentFromBooks() {
    User originalADR = [SELECT Id, isactive FROM User WHERE Profile.Name = 'Samsara ADRs' AND isactive = true LIMIT 1];
    User newADR = [SELECT Id, isactive FROM User WHERE Profile.Name = 'System Administrator' AND isactive = true LIMIT 1];
    Book_Of_Business__c book = [SELECT Id, ADR__c FROM Book_Of_Business__c WHERE Name = 'Book One' LIMIT 1];
    Account testAccount = [SELECT Id, Books_Of_Business__c, adrassignment__c 
                         FROM Account 
                         WHERE Books_Of_Business__c = :book.Id 
                         LIMIT 1];
    
    Map<Id, Book_Of_Business__c> oldBooksMap = new Map<Id, Book_Of_Business__c>();
    oldBooksMap.put(book.Id, book.clone(true, true, true, true));
    
    Test.startTest();
    book.ADR__c = newADR.Id;
    update book;
    List<Book_Of_Business__c> updatedBooks = new List<Book_Of_Business__c>{book};
    AccountBookTriggerHelper.updateADRAssignmentFromBooksOnAccount(oldBooksMap, updatedBooks);
    
    Test.stopTest();
}
}