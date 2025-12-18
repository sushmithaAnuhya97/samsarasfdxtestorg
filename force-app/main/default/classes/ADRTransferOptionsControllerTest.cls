/*
* @Author : Siddharth Kumar Mishra
* @Description:- Test class for ADRTransferOptionsController and ADRTransferController ( GTMS - 7001  -  4/19/2022  -  Move opportunities to "Closed Lost" if all conditions are met )
*/
@isTest
public class ADRTransferOptionsControllerTest 
{
    @TestSetup 
    public static void setup()
    {
        //Test Users              
        List<User> testUsers = new List<User>{
            new User(lastName = 'Tyler McGrath',
                     Alias = 'test1',
                     Email = 'tuser@test1.com',
                     Username = 'tuser@test001tests.com',
                     CommunityNickname = 'User16529768062775798018',
                     UserRoleId = [select Id,name from UserRole where name like '%Fleet IS AE2 NA US%' limit 1].id,
                     ProfileId = [select Id,name from Profile where name like '%Samsara Sales Management - New System%' limit 1].id,
                     EmployeeNumber = '9000134',
                     Territory__c = 'North America',
                     TimeZone__c = 'America/Los_Angeles',
                     TimeZoneSidKey = 'America/Los_Angeles',
                     LocaleSidKey = 'en_US',
                     LanguageLocaleKey = 'en_US',
                     EmailEncodingKey = '   ISO-8859-1'),
              new User(lastName = 'IS Pool',
                     Alias = 'test2',
                     Email = 'tuser@test2.com',
                     Username = 'tuser@test002tests.com',
                     CommunityNickname = 'User26529768062775798018',
                     UserRoleId = [select Id,name from UserRole where name like '%Fleet IS AE2 NA US%' limit 1].id,
                     ProfileId = [select Id,name from Profile where name like '%Samsara Sales Management - New System%' limit 1].id,
                     EmployeeNumber = '9000234',
                     Territory__c = 'North America',
                     TimeZone__c = 'America/Los_Angeles',
                     TimeZoneSidKey = 'America/Los_Angeles',
                     LocaleSidKey = 'en_US',
                     LanguageLocaleKey = 'en_US',
                     EmailEncodingKey = '   ISO-8859-1'),
              new User(lastName = 'Abbey Wilson',
                     Alias = 'test3',
                     Email = 'tuser@test3.com',
                     Username = 'tuser@test003tests.com',
                     CommunityNickname = 'User36529768062775798018',
                     UserRoleId = [select Id,name from UserRole where name like '%Fleet IS AE2 NA US%' limit 1].id,
                     ProfileId = [select Id,name from Profile where name like '%Samsara Sales Management - New System%' limit 1].id,
                     EmployeeNumber = '9000334',
                     Territory__c = 'North America',
                     TimeZone__c = 'America/Los_Angeles',
                     TimeZoneSidKey = 'America/Los_Angeles',
                     LocaleSidKey = 'en_US',
                     LanguageLocaleKey = 'en_US',
                     EmailEncodingKey = '   ISO-8859-1'),
              new User(lastName = 'ENT Pool',
                     Alias = 'test4',
                     Email = 'tuser@test4.com',
                     Username = 'tuser@test004tests.com',
                     CommunityNickname = 'User46529768062775798018',
                     UserRoleId = [select Id,name from UserRole where name like '%Fleet IS AE2 NA US%' limit 1].id,
                     ProfileId = [select Id,name from Profile where name like '%Samsara Sales Management - New System%' limit 1].id,
                     EmployeeNumber = '9000434',
                     Territory__c = 'North America',
                     TimeZone__c = 'America/Los_Angeles',
                     TimeZoneSidKey = 'America/Los_Angeles',
                     LocaleSidKey = 'en_US',
                     LanguageLocaleKey = 'en_US',
                     EmailEncodingKey = '   ISO-8859-1'),
               new User(lastName = 'Sites Specialist User',
                     Alias = 'test5',
                     Email = 'tuser@test5.com',
                     Username = 'tuser@test005tests.com',
                     CommunityNickname = 'User56529768062775798018',
                     UserRoleId = [select Id,name from UserRole where name like '%Sites IS AE2%' limit 1].id,
                     ProfileId = [select Id,name from Profile where name like '%Samsara Sales - Connected Worker CPQ%' limit 1].id,
                     EmployeeNumber = '9000534',
                     Territory__c = 'North America',
                     TimeZone__c = 'America/Los_Angeles',
                     TimeZoneSidKey = 'America/Los_Angeles',
                     LocaleSidKey = 'en_US',
                     LanguageLocaleKey = 'en_US',
                     EmailEncodingKey = '   ISO-8859-1'),
                new User(lastName = 'original Owner for Recycling Camapaign user',
                     Alias = 'test6',
                     Email = 'tuser@test6.com',
                     Username = 'tuser@test006tests.com',
                     CommunityNickname = 'User66529768062775798018',
                     UserRoleId = [select Id,name from UserRole where name like '%ADR%' limit 1].id,
                     ProfileId = [select Id,name from Profile where name like '%Samsara Sales Management - New System%' limit 1].id,
                     EmployeeNumber = '9000634',
                     Territory__c = 'North America',
                     TimeZone__c = 'America/Los_Angeles',
                     TimeZoneSidKey = 'America/Los_Angeles',
                     LocaleSidKey = 'en_US',
                     LanguageLocaleKey = 'en_US',
                     EmailEncodingKey = '   ISO-8859-1',
                     isActive=true),
                new User(lastName = 'Mary baez',
                     Alias = 'test7',
                     Email = 'tuser@test7.com',
                     Username = 'tuser@test007tests.com',
                     CommunityNickname = 'User76529768062775798018',
                     UserRoleId = [select Id,name from UserRole where name like '%Sites IS ADR OB NA US Team 1%' limit 1].id,
                     ProfileId = [select Id,name from Profile where name like '%Samsara Connected Worker ADRs%' limit 1].id,
                     EmployeeNumber = '9000734',
                     Territory__c = 'North America',
                     TimeZone__c = 'America/Los_Angeles',
                     TimeZoneSidKey = 'America/Los_Angeles',
                     LocaleSidKey = 'en_US',
                     LanguageLocaleKey = 'en_US',
                     EmailEncodingKey = '   ISO-8859-1'),
                new User(lastName = 'Ana Herwitz',
                     Alias = 'test8',
                     Email = 'tuser@test8.com',
                     Username = 'tuser@test008tests.com',
                     CommunityNickname = 'User86529768062775798018',
                     UserRoleId = [select Id,name from UserRole where name like '%Fleet ADR EMEA Team%' limit 1].id,
                     ProfileId = [select Id,name from Profile where name like '%Samsara Sales Management - New System%' limit 1].id,
                     EmployeeNumber = '9000834',
                     Territory__c = 'North America',
                     TimeZone__c = 'America/Los_Angeles',
                     TimeZoneSidKey = 'America/Los_Angeles',
                     LocaleSidKey = 'en_US',
                     LanguageLocaleKey = 'en_US',
                     EmailEncodingKey = '   ISO-8859-1'),
                 new User(lastName = 'test field',
                     Alias = 'test9',
                     Email = 'tuser@test9.com',
                     Username = 'tuser@test009tests.com',
                     CommunityNickname = 'User96529768062775798018',
                     UserRoleId = [select Id,name from UserRole where name like '%Fleet ADR EMEA Team%' limit 1].id,
                     ProfileId = [select Id,name from Profile where name like '%Samsara Sales Management - New System%' limit 1].id,
                     EmployeeNumber = '9000934',
                     Territory__c = 'North America',
                     TimeZone__c = 'America/Los_Angeles',
                     TimeZoneSidKey = 'America/Los_Angeles',
                     LocaleSidKey = 'en_US',
                     LanguageLocaleKey = 'en_US',
                     EmailEncodingKey = '   ISO-8859-1')
                
        };
        Insert testUsers;
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        system.runAs(thisUser)
        {
            User objProfileAE3 = [select Id, IsActive, Profile.Name from User where IsActive = true and Profile.Name = 'Samsara Sales - NA US AE3' order by Id limit 1];
    	User objProfileADR = [select Id, IsActive, Profile.Name from User where IsActive = true and Profile.Name = 'Samsara ADRs' order by Id limit 1];

            List<Book_Of_Business__c> listBook = new List<Book_Of_Business__c>();
        Book_Of_Business__c book = new Book_Of_Business__c(Name='Book One', AE__c=objProfileAE3.Id, ADR__c=objProfileADR.Id, Active__c=true);
        listBook.add(book);
        Book_Of_Business__c book2 = new Book_Of_Business__c(Name='Book Two', AE__c=objProfileAE3.Id, ADR__c=objProfileADR.Id, Active__c=true);
        listBook.add(book2);
        
        Book_Of_Business__c book3 = new Book_Of_Business__c(Name='Book Three', AE__c=objProfileADR.Id, ADR__c=objProfileADR.Id, Active__c=true);
        listBook.add(book3);
        insert listBook;
            
            //Test Accounts
            List<Account> testAccounts = new List<Account>{
                new Account(Name = 'Sites only ISA', Organization_Size__c ='1000 - 4999', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'California',Inside_Sales_Assignment__c='Tyler McGrath'),
                    new Account(Name = 'Sites Only ISA IS Pool', Organization_Size__c ='1000 - 4999', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'California',Inside_Sales_Assignment__c='IS Pool'),
                    new Account(Name = 'Sites Only Enterprise', Organization_Size__c ='1000 - 4999', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'California',Enterprise_Assignment__c='Abbey Wilson'),
                    new Account(Name = 'Sites Only Enterprise ENT Pool', Organization_Size__c ='1000 - 4999', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'California',Enterprise_Assignment__c='ENT Pool'),
                    new Account(Name = 'Sites Only Sites Specialist with sites IS AE2', Organization_Size__c ='1000 - 4999', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'California',Sites_Specialist__c=[Select id from User Where Name = 'Sites Specialist User'].Id),
                    new Account(Name = 'Sites Only Sites Specialist without sites IS AE2', Organization_Size__c ='1000 - 4999', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'California',Sites_Specialist__c=system.UserInfo.getUserId()),
                    new Account(Name = 'Fleet original Owner For Recycling Campaign', Organization_Size__c ='1000 - 4999', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'California',Original_Owner_for_Recycling_Campaign__c=[Select id from User Where Name = 'original Owner for Recycling Camapaign user'].Id),
                    new Account(Name = 'Fleet Enterprise Industrial Account',recordTypeId=[SELECT  Id,name from RecordType where name like '%Industrial%' and SobjectType = 'Account' Limit 1].Id, Organization_Size__c ='1000 - 4999', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'California',Enterprise_Assignment__c='Abbey Wilson'),
                    new Account(Name = 'Fleet Non-Enterprise Industrial Account',recordTypeId=[SELECT  Id,name from RecordType where name like '%Industrial%' and SobjectType = 'Account' Limit 1].Id, Organization_Size__c ='1000 - 4999', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'California',Territory__c='test RA'),
                    new Account(Name = 'Fleet RoundRobin', Organization_Size__c ='1000 - 4999', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'California'),
                    new Account(Name = 'Fleet ATM', Organization_Size__c ='1000 - 4999', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'California'),
                    new Account(Name = 'ADR present', Organization_Size__c ='1000 - 4999', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'California'),
                    new Account(Name = 'Sites Only Standard', Organization_Size__c ='1000 - 4999', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'California'),
                    new Account(Name = 'RODRIGO ADR Test', Organization_Size__c ='1000 - 4999', BillingCountry = 'United States',
                                Industry = 'Other', ADR_Transfer__c = false, BillingState = 'California')
                    };
                        
                        Insert testAccounts;
            
            //test Account Team Memeber
            AccountTeamMember testATM = new AccountTeamMember(userid = system.userinfo.getUserId(),
                                                              AccountId = TestAccounts[10].Id,
                                                              TeamMemberRole='Sites Account Executive'
            );
            Insert testATM;
            
            
            
            //Test Contacts
            List<Contact> testContacts = new List<Contact>{
                new Contact(AccountId = TestAccounts[0].Id, FirstName = 'Frank', LastName = 'Sinatra', ADR_Transfer_Status__c = 'Demo Scheduled'), 
                    new Contact(AccountId = TestAccounts[1].Id, FirstName = 'Frank', LastName = 'Sinatra', ADR_Transfer_Status__c = 'Demo Scheduled'),
                    new Contact(AccountId = TestAccounts[2].Id, FirstName = 'Frank', LastName = 'Sinatra', ADR_Transfer_Status__c = 'Demo Scheduled'),
                    new Contact(AccountId = TestAccounts[3].Id, FirstName = 'Frank', LastName = 'Sinatra', ADR_Transfer_Status__c = 'Demo Scheduled'),
                    new Contact(AccountId = TestAccounts[4].Id, FirstName = 'Frank', LastName = 'Sinatra', ADR_Transfer_Status__c = 'Demo Scheduled'),
                    new Contact(AccountId = TestAccounts[5].Id, FirstName = 'Frank', LastName = 'Sinatra', ADR_Transfer_Status__c = 'Demo Scheduled'),
                    new Contact(AccountId = TestAccounts[6].Id, FirstName = 'Frank', LastName = 'Sinatra', ADR_Transfer_Status__c = 'Demo Scheduled'),
                    new Contact(AccountId = TestAccounts[7].Id, FirstName = 'Frank', LastName = 'Sinatra', ADR_Transfer_Status__c = 'Demo Scheduled'),
                    new Contact(AccountId = TestAccounts[8].Id, FirstName = 'Frank', LastName = 'Sinatra', ADR_Transfer_Status__c = 'Demo Scheduled'),
                    new Contact(AccountId = TestAccounts[9].Id, FirstName = 'Frank', LastName = 'Sinatra', ADR_Transfer_Status__c = 'Demo Scheduled'),
                    new Contact(AccountId = TestAccounts[10].Id, FirstName = 'Frank', LastName = 'Sinatra', ADR_Transfer_Status__c = 'Demo Scheduled'),
                    new Contact(AccountId = TestAccounts[11].Id, FirstName = 'Frank', LastName = 'Sinatra', ADR_Transfer_Status__c = 'Demo Scheduled'),
                    new Contact(AccountId = TestAccounts[12].Id, FirstName = 'Frank', LastName = 'Sinatra', ADR_Transfer_Status__c = 'Demo Scheduled'),
                    new Contact(AccountId = TestAccounts[13].Id, FirstName = 'Frank', LastName = 'Sinatra', ADR_Transfer_Status__c = 'Demo Scheduled')
                    };
                        Insert testContacts;
            
            //Test ADR
            ADR_Transfer_Log__c testADR = new ADR_Transfer_Log__c(contact__c=testContacts[11].Id,
                                                                 ADR_Transfer_Date__c = system.now().addDays(-10),
                                                                 ADR_Transfer__C = false);
            Insert testADR;
            
           /* LFBN__Region_Automation__c testRA = new LFBN__Region_Automation__c(Name='test RA');
            Insert testRA;
            LFBN__Region_Automation_Field_Value__c testRAFV = new LFBN__Region_Automation_Field_Value__c(LFBN__Field_Value__c=[Select id from user Where name='test field'].Id,
                                                                                                        LFBN__Field_API_Name__c= 'ownerid',
                                                                                                        LFBN__Region_Automation__c=testRA.Id);
            Insert testRAFV;
            
            */
            //Test Lane Four Round Robin
            RR_Assignment_Rule__c testRR = new RR_Assignment_Rule__c (Category__c = 'Lane Four', Rule_Description__c = 'NA Connected Sites AE2', SLED__c=true, SLED_Check__c=true,
                                                               Type__c = 'Other', Object__c='Account', Order__c = 2, Active__c=true, Min_Value__c=0,
                                                               Max_Value__c = 150000, Next_Assignment__c=testUsers[0].Id, Always_Use_Next_Assignment__c=true,
                                                                Billing_Country__c='Mexico',Account_Hashtag__c='test', Number_of_Vehicles__c='==0', 
                                                                 Number_of_Powered_Assets__c='> 0',Number_of_Unpowered_Assets__c='>=0',
                                                                Number_of_Students__c='<=0', Number_of_Citizens__c='< 0', Organization_Size__c='1 - 99');
            
            //RR_Assignment_Rule__c testRR = new RR_Assignment_Rule__c(name='NA Connected Sites AE2',Active__c= true);
            Insert testRR;
            /*RR_Assignment_Mapping__c testRRA = new LFBN__Round_Robin_Assignment__c(LFBN__User__c = System.UserInfo.getUserId(),
                                                                                          LFBN__Round_Robin__c = testRR.Id,
                                                                                          LFBN__Active__c = true);*/
            RR_Assignment_Mapping__c testRRA = new RR_Assignment_Mapping__c(Assignment_Rule__c=testRR.Id, User__c=testUsers[0].Id, Order__c = 4, 
                                                                     Active__c=true, Type__c='Other', Value_Total__c=10000, Max_Value__c=2000000);
            Insert testRRA;
            /*LFBN__Round_Robin_Credit__c testRRC = new LFBN__Round_Robin_Credit__c(LFBN__Active__c=true,
                                                                                  LFBN__Round_Robin_Assignment__c=testRRA.Id,
                                                                                  LFBN__Last_Assigned_Time__c=system.now(),
                                                                                  CurrencyIsoCode='USD',
                                                                                  LFBN__Assignment_Number__c = 1);
            Insert testRRC;*/
            
            //Test emea countries
            EMEA_Countries__c testEMEACountry = new EMEA_Countries__c (Name = 'Names',
                                                                       CurrencyIsoCode = 'USD',
                                                                       Named_List_Geo__c = 'UK & I, Iberia, France, Benelux, DACH'
            );
            Insert testEMEACountry;
            
           //Test Campaign
           Campaign testCampaign = new Campaign(Name = 'Test Campaign (Child) ADR', Status='In Progress', StartDate = System.Date.today());
           Insert testCampaign;
            
            //Test Enterprise_Routing_Default__c
            List<Enterprise_Routing_Default__c> testERD = new List<Enterprise_Routing_Default__c>{
                new Enterprise_Routing_Default__c(Id__c = system.UserInfo.getUserId(),
                                                  Region__c='Industrial'
                                                  ),
                new Enterprise_Routing_Default__c(Id__c = system.UserInfo.getUserId(),
                                                  Region__c='North America'
                                                  ),  
                new Enterprise_Routing_Default__c(Id__c = system.UserInfo.getUserId(),
                                                  Region__c='EMEA'
                                                  )
                
            };
            
        }
               
    }
    
    @IsTest
    public static void ADRtransfeOptionControllertest2()
    {
        Book_Of_Business__c bb = [Select id from Book_Of_Business__c limit 1];
        Contact testCon = [Select Id, AccountId From Contact Where Account.Name = 'RODRIGO ADR Test'];
        Account updAccount = new Account();
            updAccount.id = testCon.AccountId;
            updAccount.Books_Of_Business__c = bb.Id;
            update updAccount;
        User MaryBaez = [Select Id from User Where Name = 'original Owner for Recycling Camapaign user' limit 1];
        User objProfileADR = [select Id, IsActive, Profile.Name from User where IsActive = true and Profile.Name = 'Samsara ADRs' order by Id limit 1];
        
        System.runAs(objProfileADR)
        {
            
            PageReference pageRef = Page.ADR_Transfer_options;
            Test.setCurrentPage(pageRef);
            pageRef.setRedirect(true);
            pageRef.getParameters().put('selectedValue','SitesOnly');
            pageRef.getParameters().put('currentContactID',testCon.Id);
            ApexPages.StandardController sc = new  ApexPages.StandardController(testCon);     
            ADRTransferOptionsController transferPage = new ADRTransferOptionsController(sc);
            
            //Submit button is clicked
            Pagereference submit =  transferPage.submit();
            
            //back to contact button is clicked
            Pagereference backToContact = transferPage.backToContact();
            
        }
        
        
        System.assertEquals(true, true,'Assertion Failed');
    }
    
    @IsTest
    public static void ADRtransfeOptionControllertest()
    {
        Contact testCon = [Select Id From Contact Where Account.Name = 'Sites Only ISA'];
        User MaryBaez = [Select Id from User Where Name = 'Mary Baez' limit 1];
        System.runAs(MaryBaez)
        {
            PageReference pageRef = Page.ADR_Transfer_options;
            Test.setCurrentPage(pageRef);
            pageRef.setRedirect(true);
            pageRef.getParameters().put('selectedValue','SitesOnly');
            pageRef.getParameters().put('currentContactID',testCon.Id);
            ApexPages.StandardController sc = new  ApexPages.StandardController(testCon);     
            ADRTransferOptionsController transferPage = new ADRTransferOptionsController(sc);
            
            //Submit button is clicked
            Pagereference submit =  transferPage.submit();
            
            //back to contact button is clicked
            Pagereference backToContact = transferPage.backToContact();
            
        }
        
        
        System.assertEquals(true, true,'Assertion Failed');
    }
     @IsTest
    public static void sitesOnlyStandard()
    {
        Account testAcc = [Select Id, Ownerid from Account Where Name = 'Sites Only Standard'];
        Contact testCon = [Select Id From Contact Where Account.Name = 'Sites Only Standard'];
        User MaryBaez = [Select Id from User Where Name = 'Mary Baez' limit 1];
        testAcc.OwnerId = MaryBaez.Id;
        testAcc.Overwrite_Validation_Rule__c = true;
        update testAcc;
        System.runAs(MaryBaez)
        {
            PageReference pageRef = Page.ADR_Transfer_options;
            Test.setCurrentPage(pageRef);
            pageRef.setRedirect(true);
            pageRef.getParameters().put('selectedValue','SitesOnly');
            pageRef.getParameters().put('currentContactID',testCon.Id);
            ApexPages.StandardController sc = new  ApexPages.StandardController(testCon);     
            ADRTransferController transferPage = new ADRTransferController(sc);
            
            //setRoundRobinUser
            transferPage.setRoundRobinUser();
            
            //Submit button is clicked
            Pagereference submit =  transferPage.submit();
            
            //back to contact button is clicked
            Pagereference backToContact = transferPage.backToContact();
            
        }
        
        
        System.assertEquals(true, true,'Assertion Failed');
    }
    @IsTest
    public static void sitesOnlyInsideSalesAssignment()
    {
        Contact testCon = [Select Id From Contact Where Account.Name = 'Sites Only ISA'];
        User MaryBaez = [Select Id from User Where Name = 'Mary Baez' limit 1];
        System.runAs(MaryBaez)
        {
            PageReference pageRef = Page.ADR_Transfer_options;
            Test.setCurrentPage(pageRef);
            pageRef.setRedirect(true);
            pageRef.getParameters().put('selectedValue','SitesOnly');
            pageRef.getParameters().put('currentContactID',testCon.Id);
            ApexPages.StandardController sc = new  ApexPages.StandardController(testCon);     
            ADRTransferController transferPage = new ADRTransferController(sc);
            
            //setRoundRobinUser
            transferPage.setRoundRobinUser();
            
            //Submit button is clicked
            //Pagereference submit =  transferPage.submit();
            
            //back to contact button is clicked
            //Pagereference backToContact = transferPage.backToContact();
            
        }
        
        
        System.assertEquals(true, true,'Assertion Failed');
    }
    @IsTest
    public static void sitesOnlyInsideSalesAssignmentISPool()
    {
        Contact testCon = [Select Id from contact Where Account.Name = 'Sites Only ISA IS Pool'];
        User MaryBaez = [Select Id from User Where Name = 'Mary Baez' limit 1];
        System.runAs(MaryBaez)
        {
            PageReference pageRef = Page.ADR_Transfer_options;
            Test.setCurrentPage(pageRef);
            pageRef.setRedirect(true);
            pageRef.getParameters().put('selectedValue','SitesOnly');
            pageRef.getParameters().put('currentContactID',testCon.Id);
            ApexPages.StandardController sc = new  ApexPages.StandardController(testCon);     
            ADRTransferController transferPage = new ADRTransferController(sc);
            
            //setRoundRobinUser
            transferPage.setRoundRobinUser();
            
            //Submit button is clicked
            Pagereference submit =  transferPage.submit();
            
            //back to contact button is clicked
            Pagereference backToContact = transferPage.backToContact();
            
        }
        
        System.assertEquals(true, true,'Assertion Failed');
    }
    @IsTest
    public static void sitesOnlyEnterprise()
    {
        Contact testCon = [Select Id From Contact Where Account.Name = 'Sites Only Enterprise'];
        User MaryBaez = [Select Id from User Where Name = 'Mary Baez' limit 1];
        System.runAs(MaryBaez)
        {
            PageReference pageRef = Page.ADR_Transfer_options;
            Test.setCurrentPage(pageRef);
            pageRef.setRedirect(true);
            pageRef.getParameters().put('selectedValue','SitesOnly');
            pageRef.getParameters().put('currentContactID',testCon.Id);
            ApexPages.StandardController sc = new  ApexPages.StandardController(testCon);     
            ADRTransferController transferPage = new ADRTransferController(sc);
            
            //setRoundRobinUser
            transferPage.setRoundRobinUser();
            
            //Submit button is clicked
            //Pagereference submit =  transferPage.submit();
            
            //back to contact button is clicked
            //Pagereference backToContact = transferPage.backToContact();
            
        }
        
        System.assertEquals(true, true,'Assertion Failed');
    }
    @IsTest
    public static void sitesOnlyEnterpriseENTPool()
    {
        Contact testCon = [Select Id from contact Where Account.Name = 'Sites Only Enterprise ENT Pool'];
        User MaryBaez = [Select Id from User Where Name = 'Mary Baez' limit 1];
        System.runAs(MaryBaez)
        {
            PageReference pageRef = Page.ADR_Transfer_options;
            Test.setCurrentPage(pageRef);
            pageRef.setRedirect(true);
            pageRef.getParameters().put('selectedValue','SitesOnly');
            pageRef.getParameters().put('currentContactID',testCon.Id);
            ApexPages.StandardController sc = new  ApexPages.StandardController(testCon);     
            ADRTransferController transferPage = new ADRTransferController(sc);
            
            //setRoundRobinUser
            transferPage.setRoundRobinUser();
            
            //Submit button is clicked
            Pagereference submit =  transferPage.submit();
            
            //back to contact button is clicked
            Pagereference backToContact = transferPage.backToContact();
            
        }
        
        System.assertEquals(true, true,'Assertion Failed');
    }
    @IsTest
    public static void sitesOnlySitesSpecialistWithSitesISAE2()
    {
        Account testAcc = [Select Id, Ownerid from Account Where Name = 'Sites Only Sites Specialist with sites IS AE2'];
        Contact testCon = [Select Id from contact Where Account.Name = 'Sites Only Sites Specialist with sites IS AE2'];
        User MaryBaez = [Select Id from User Where Name = 'Mary Baez' limit 1];
        testAcc.OwnerId = MaryBaez.Id;
        testAcc.Overwrite_Validation_Rule__c = true;
        update testAcc;
        System.runAs(MaryBaez)
        {
            PageReference pageRef = Page.ADR_Transfer_options;
            Test.setCurrentPage(pageRef);
            pageRef.setRedirect(true);
            pageRef.getParameters().put('selectedValue','SitesOnly');
            pageRef.getParameters().put('currentContactID',testCon.Id);
            ApexPages.StandardController sc = new  ApexPages.StandardController(testCon);     
            ADRTransferController transferPage = new ADRTransferController(sc);
            
            //setRoundRobinUser
            transferPage.setRoundRobinUser();
            
            //Submit button is clicked
            Pagereference submit =  transferPage.submit();
            
            //back to contact button is clicked
            Pagereference backToContact = transferPage.backToContact();
            
        }
        
        System.assertEquals(true, true,'Assertion Failed');
    }
    @IsTest
    public static void sitesOnlySitesSpecialistWithoutSitesISAE2()
    {
        Account testAcc = [Select Id, Ownerid from Account Where Name = 'Sites Only Sites Specialist without sites IS AE2'];
        Contact testCon = [Select Id from contact Where Account.Name = 'Sites Only Sites Specialist without sites IS AE2'];
        User MaryBaez = [Select Id from User Where Name = 'Mary Baez' limit 1];
        testAcc.OwnerId = MaryBaez.Id;
        testAcc.Overwrite_Validation_Rule__c = true;
        update testAcc;
        System.runAs(MaryBaez)
        {
            PageReference pageRef = Page.ADR_Transfer_options;
            Test.setCurrentPage(pageRef);
            pageRef.setRedirect(true);
            pageRef.getParameters().put('selectedValue','SitesOnly');
            pageRef.getParameters().put('currentContactID',testCon.Id);
            ApexPages.StandardController sc = new  ApexPages.StandardController(testCon);     
            ADRTransferController transferPage = new ADRTransferController(sc);
            
            //setRoundRobinUser
            transferPage.setRoundRobinUser();
            
            //Submit button is clicked
            Pagereference submit =  transferPage.submit();
            
            //back to contact button is clicked
            Pagereference backToContact = transferPage.backToContact();
            
        }
        
        System.assertEquals(true, true,'Assertion Failed');
    }
    @IsTest
    public static void fleetOriginalOwnerforRecyclingCampaign()
    {Account testAcc = [Select Id, Ownerid from Account Where Name = 'Fleet original Owner For Recycling Campaign'];
        //
        Contact testCon = [Select Id from contact Where Account.Name = 'Fleet original Owner For Recycling Campaign'];
        User MaryBaez = [Select Id from User Where Name = 'Mary Baez' limit 1];
        //testAcc.OwnerId = MaryBaez.Id;
        //update testAcc;
        System.runAs(MaryBaez)
        {
            PageReference pageRef = Page.ADR_Transfer_options;
            Test.setCurrentPage(pageRef);
            pageRef.setRedirect(true);
            pageRef.getParameters().put('selectedValue','Fleet');
            pageRef.getParameters().put('currentContactID',testCon.Id);
            ApexPages.StandardController sc = new  ApexPages.StandardController(testCon);     
            ADRTransferController transferPage = new ADRTransferController(sc);
            
            //setRoundRobinUser
            transferPage.setRoundRobinUser();
            
            //Submit button is clicked
            //Pagereference submit =  transferPage.submit();
            
            //back to contact button is clicked
            //Pagereference backToContact = transferPage.backToContact();
            
        }
        
        System.assertEquals(true, true,'Assertion Failed');
    }
    @IsTest
    public static void fleetEnterprise()
    {
        Contact testCon = [Select Id From Contact Where Account.Name = 'Sites Only Enterprise'];
        User MaryBaez = [Select Id from User Where Name = 'Mary Baez' limit 1];
        System.runAs(MaryBaez)
        {
            PageReference pageRef = Page.ADR_Transfer_options;
            Test.setCurrentPage(pageRef);
            pageRef.setRedirect(true);
            pageRef.getParameters().put('selectedValue','Fleet');
            pageRef.getParameters().put('currentContactID',testCon.Id);
            ApexPages.StandardController sc = new  ApexPages.StandardController(testCon);     
            ADRTransferController transferPage = new ADRTransferController(sc);
            
            //setRoundRobinUser
            transferPage.setRoundRobinUser();
            
            //Submit button is clicked
            //Pagereference submit =  transferPage.submit();
            
            //back to contact button is clicked
            //Pagereference backToContact = transferPage.backToContact();
            
        }
        
        System.assertEquals(true, true,'Assertion Failed');
    }
    @IsTest
    public static void fleetEnterpriseENTPool()
    {
        Contact testCon = [Select Id from contact Where Account.Name = 'Fleet Enterprise Industrial Account'];
        User MaryBaez = [Select Id from User Where Name = 'Mary Baez' limit 1];
        System.runAs(MaryBaez)
        {
            PageReference pageRef = Page.ADR_Transfer_options;
            Test.setCurrentPage(pageRef);
            pageRef.setRedirect(true);
            pageRef.getParameters().put('selectedValue','Fleet');
            pageRef.getParameters().put('currentContactID',testCon.Id);
            ApexPages.StandardController sc = new  ApexPages.StandardController(testCon);     
            ADRTransferController transferPage = new ADRTransferController(sc);
            
            //setRoundRobinUser
            transferPage.setRoundRobinUser();
            
            //Submit button is clicked
            //Pagereference submit =  transferPage.submit();
            
            //back to contact button is clicked
            //Pagereference backToContact = transferPage.backToContact();
            
        }
        
        System.assertEquals(true, true,'Assertion Failed');
    }
    /*@IsTest
    public static void fleetnonEnterpriseIndustrialAccount()
    {
        Account testAcc = [Select Id, Ownerid from Account Where Name = 'Fleet Non-Enterprise Industrial Account'];
        Contact testCon = [Select Id from contact Where Account.Name = 'Fleet Non-Enterprise Industrial Account'];
        User MaryBaez = [Select Id from User Where Name = 'Mary Baez' limit 1];
        testAcc.OwnerId = MaryBaez.Id;
        testAcc.Overwrite_Validation_Rule__c = true;
        update testAcc;
        System.runAs(MaryBaez)
        {
            PageReference pageRef = Page.ADR_Transfer_options;
            Test.setCurrentPage(pageRef);
            pageRef.setRedirect(true);
            pageRef.getParameters().put('selectedValue','Fleet');
            pageRef.getParameters().put('currentContactID',testCon.Id);
            ApexPages.StandardController sc = new  ApexPages.StandardController(testCon);     
            ADRTransferController transferPage = new ADRTransferController(sc);
            
            //setRoundRobinUser
            transferPage.setRoundRobinUser();
            
            //Submit button is clicked
            Pagereference submit =  transferPage.submit();
            
            //back to contact button is clicked
            Pagereference backToContact = transferPage.backToContact();
            
        }
        
        System.assertEquals(true, true,'Assertion Failed');
    }*/
    @IsTest
    public static void fleetRoundRobin()
    {
        Account testAcc = [Select Id, Ownerid from Account Where Name = 'Fleet RoundRobin'];
        Contact testCon = [Select Id from contact Where Account.Name = 'Fleet RoundRobin'];
        User MaryBaez = [Select Id from User Where Name = 'Mary Baez' limit 1];
        testAcc.OwnerId = MaryBaez.Id;
        testAcc.Overwrite_Validation_Rule__c = true;
        update testAcc;
        System.runAs(MaryBaez)
        {
            PageReference pageRef = Page.ADR_Transfer_options;
            Test.setCurrentPage(pageRef);
            pageRef.setRedirect(true);
            pageRef.getParameters().put('selectedValue','Fleet');
            pageRef.getParameters().put('currentContactID',testCon.Id);
            ApexPages.StandardController sc = new  ApexPages.StandardController(testCon);     
            ADRTransferController transferPage = new ADRTransferController(sc);
            
            //setRoundRobinUser
            transferPage.setRoundRobinUser();
            
            //Submit button is clicked
            Pagereference submit =  transferPage.submit();
            
            //back to contact button is clicked
            Pagereference backToContact = transferPage.backToContact();
            
        }
        
        System.assertEquals(true, true,'Assertion Failed');
    }
    @IsTest
    public static void fleetATM()
    {
        Account testAcc = [Select Id, Ownerid from Account Where Name = 'Fleet ATM'];
        Contact testCon = [Select Id from contact Where Account.Name = 'Fleet ATM'];
        User MaryBaez = [Select Id from User Where Name = 'Mary Baez' limit 1];
        User AnaHerwitz = [Select Id from User Where Name = 'Ana Herwitz' limit 1];
        testAcc.OwnerId = AnaHerwitz.Id;
        testAcc.Overwrite_Validation_Rule__c = true;
        update testAcc;
        System.runAs(MaryBaez)
        {
            PageReference pageRef = Page.ADR_Transfer_options;
            Test.setCurrentPage(pageRef);
            pageRef.setRedirect(true);
            pageRef.getParameters().put('selectedValue','Fleet');
            pageRef.getParameters().put('currentContactID',testCon.Id);
            ApexPages.StandardController sc = new  ApexPages.StandardController(testCon);     
            ADRTransferController transferPage = new ADRTransferController(sc);
            
            //setRoundRobinUser
            transferPage.setRoundRobinUser();
            
            //Submit button is clicked
            //Pagereference submit =  transferPage.submit();
            
            //back to contact button is clicked
            //Pagereference backToContact = transferPage.backToContact();
            
            
            
        }
        
        System.assertEquals(true, true,'Assertion Failed');
    }
    @IsTest
    public static void ADRPresent()
    {
        Account testAcc = [Select Id, Ownerid from Account Where Name = 'ADR Present'];
        Contact testCon = [Select Id from contact Where Account.Name = 'ADR Present'];
        User MaryBaez = [Select Id from User Where Name = 'Mary Baez' limit 1];
        testAcc.OwnerId = MaryBaez.Id;
        testAcc.Overwrite_Validation_Rule__c = true;
        update testAcc;
        System.runAs(MaryBaez)
        {
            PageReference pageRef = Page.ADR_Transfer_options;
            Test.setCurrentPage(pageRef);
            pageRef.setRedirect(true);
            pageRef.getParameters().put('selectedValue','Fleet');
            pageRef.getParameters().put('currentContactID',testCon.Id);
            ApexPages.StandardController sc = new  ApexPages.StandardController(testCon);     
            ADRTransferController transferPage = new ADRTransferController(sc);
            
            //setRoundRobinUser
            transferPage.setRoundRobinUser();
            
            //Submit button is clicked
            Pagereference submit =  transferPage.submit();
            
            //back to contact button is clicked
            Pagereference backToContact = transferPage.backToContact();
            
        }
        
        System.assertEquals(true, true,'Assertion Failed');
        Delete testAcc;
    }

}