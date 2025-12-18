@IsTest
public class CRLeadToPRConversionOneTimeBatch_Test {
    
    @TestSetup
    public static void setup(){
        
        //Create Partner Account
        String orgId = UserInfo.getOrganizationId();
        RecordType accountPartnerRT = [Select Id from RecordType Where SObjectType = 'Account' and Name = 'Partner' LIMIT 1]; 
        Account partnerAccount = new Account(Name='Partner Account', Organization_Size__c='1 - 99', BillingCountry='Belgium', BillingCountryCode = 'BE', RecordTypeId = accountPartnerRT.Id);
        insert partnerAccount;
        
        //Emable as Partner
        partnerAccount.IsPartner = true;
        update partnerAccount;
        
        //Create Partner Contact
        RecordType contactPartnerRT = [Select Id from RecordType Where SObjectType = 'Contact' and Name = 'Partner' LIMIT 1]; 
        Contact partnerContact = new Contact(FirstName = 'Partner', LastName = 'Contact', AccountId = partnerAccount.Id, Email = 'partner@test.com'+orgId);
        insert partnerContact;
        
        //Create Partner User
        Profile partnerProfile = [SELECT Id FROM Profile WHERE Name = 'Samsara Partner Community Login License User'];
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User partnerUser = new User(lastName = partnerContact.LastName,
                                    email = partnerContact.Email,
                                    Username = partnerContact.Email,
                                    ContactId = partnerContact.Id,
                                    EmailEncodingKey = 'ISO-8859-1',
                                    Alias = uniqueName.substring(10, 15),
                                    TimeZoneSidKey = 'America/Los_Angeles',
                                    LocaleSidKey = 'en_US',
                                    LanguageLocaleKey = 'en_US',
                                    ProfileId = partnerProfile.Id,
                                    EmployeeNumber='123');
        insert partnerUser;
    }
    
    public static Account createAccount(String accountName, string paymentType, string userId, string currencyVal){
        Account testAccount = new Account();
        testAccount.Name = accountName;
        testAccount.Industry = 'Biotechnology';
        testAccount.Organization_Size__c = '500 - 999';
        testAccount.BillingStreet = '123 main';
        testAccount.BillingCity = 'Missoula';
        testAccount.BillingState = 'California';
        testAccount.BillingCountry = 'United States';
        testAccount.BillingPostalCode = '59801';
        testAccount.Billing_Email__c = 'foo@bar.com';
        testAccount.Approved_Payment_Type__c = 'Direct Monthly';
        testAccount.ownerid = userId;
        testAccount.CurrencyIsoCode = currencyVal;
        testAccount.Approved_Payment_Type__c = paymentType;
        return testAccount;
    }
    
    
    
    public static Contact createContact(Id accountId) {
        Contact testContact = new Contact();
        testContact.FirstName = 'Test';
        testContact.LastName = 'Contact';
        testContact.AccountId = accountId;
        testContact.Source__c = 'Adwords';
        testContact.Email = 'test@test.com';
        return testContact;
    }
    
    @IsTest
    public static void batchTestMethod(){
        String orgId = UserInfo.getOrganizationId();
        String partnerUsername = 'partner@test.com'+orgId;
        
        //Before state - Assert that the running user(PSM) has no lead records visible to them
        List<Lead> myLeadsAtStart = (List<Lead>)Database.Query('Select Id from Lead');
        System.assert(myLeadsAtStart.size() == 0);
        
        Account partnerAccount = [SELECT Id FROM Account WHERE isPartner = true];
        Contact partnerContact = [SELECT Id FROM Contact WHERE AccountId=:partnerAccount.id];
        
        //Get partner user
        User partnerUser = [Select Id, Account.OwnerId from User where username =: partnerUsername];
        Account acc = createAccount('test Account','Direct Monthly',partnerUser.Id,'USD');
        insert acc;
        Contact con = createContact(acc.id);
        insert con;
        
        //Insert a Deal Reg Lead record to simulate the Partner community action
        string leadDealRegRT = sObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Channel_Registration').getRecordTypeId();//[Select Id from RecordType Where SObjectType = 'Lead' and Name = 'Channel Registration' LIMIT 1];
        
        Lead dealRegLead2 = new Lead (LastName = 'Test Client2',Is_Deal_Registration__c = true, Email = 'dealreglead2@test.com'+orgId,
                                      RecordTypeId = leadDealRegRT, phone = '+1234567890', Company = 'Test company2', Business_unit__c = 'Fleet',
                                      LeadSource = 'Deal Reg Form', Country='United States', State='Texas',Partner_Account__c = partnerAccount.Id, Partner_Contact__c = partnerContact.Id,
                                      Status = 'New');
       	
        //List<Lead> leadList = new List<Lead>{dealRegLead1,dealRegLead2};
        insert dealRegLead2;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SubmitLeadToNotreDameTest.NotreDameHTTPServiceTestMocks());
        CRLeadToPRConversionOnTime_Batch bcVar = new CRLeadToPRConversionOnTime_Batch();
        bcVar.dateValue = Date.today().addDays(3);
        bcVar.emailIdList.add('Vijaychandra.amaraneni@Samsara.com');
        bcVar.inProgressLeads = true;
        bcVar.leadSourceVal = 'Deal Reg Form';
        bcVar.partnerTypeVal = 'Channel_Registration';
        //bcVar.failedLeads.put(leadList[1].Id,'Test Message');
        Database.executebatch(bcVar);
        Test.stopTest();
    }
    
    @IsTest
    static void convertedLeadTest(){
        String orgId = UserInfo.getOrganizationId();
        String partnerUsername = 'partner@test.com'+orgId;
        
        //Before state - Assert that the running user(PSM) has no lead records visible to them
        List<Lead> myLeadsAtStart = (List<Lead>)Database.Query('Select Id from Lead');
        System.assert(myLeadsAtStart.size() == 0);
        
        Account partnerAccount = [SELECT Id FROM Account WHERE isPartner = true];
        Contact partnerContact = [SELECT Id FROM Contact WHERE AccountId=:partnerAccount.id];
        
        //Get partner user
        User partnerUser = [Select Id, Account.OwnerId from User where username =: partnerUsername];
        Account acc = createAccount('test Account','Direct Monthly',partnerUser.Id,'USD');
        insert acc;
        Contact con = createContact(acc.id);
        insert con;
        
        //Insert a Deal Reg Lead record to simulate the Partner community action
        string leadDealRegRT = sObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Channel_Registration').getRecordTypeId();//[Select Id from RecordType Where SObjectType = 'Lead' and Name = 'Channel Registration' LIMIT 1];
        Lead dealRegLead1 = new Lead (LastName = 'Test Client',Is_Deal_Registration__c = false, Email = 'dealreglead@test.com'+orgId,
                                      RecordTypeId = leadDealRegRT, phone = '+1234567890', Company = 'Test company', Business_unit__c = 'Fleet',
                                      LeadSource = 'Deal Reg Form', Country='United States', State='Texas',Partner_Account__c = partnerAccount.Id, Partner_Contact__c = partnerContact.Id,
                                      Status = 'New');
       	
        //List<Lead> leadList = new List<Lead>{dealRegLead1,dealRegLead2};
        insert dealRegLead1;
        
        Database.LeadConvert thisLC = new Database.LeadConvert();
        thisLC.setLeadId(dealRegLead1.Id);
        thisLC.setDoNotCreateOpportunity(true);
        thisLC.setConvertedStatus('Qualified');
        thisLC.setAccountId(acc.Id);
        thisLC.setContactId(con.Id);
        
        Database.convertLead(thisLC);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SubmitLeadToNotreDameTest.NotreDameHTTPServiceTestMocks());
        CRLeadToPRConversionOnTime_Batch bcVar = new CRLeadToPRConversionOnTime_Batch();
        bcVar.dateValue = Date.today().addDays(3);
        bcVar.emailIdList.add('Vijaychandra.amaraneni@Samsara.com');
        bcVar.convertedLeads = true;
        bcVar.leadSourceVal = 'Deal Reg Form';
        bcVar.partnerTypeVal = 'Channel_Registration';
        //bcVar.failedLeads.put(leadList[1].Id,'Test Message');
        Database.executebatch(bcVar);
        Test.stopTest();
        List<Partner_Registration__c> prList = new List<Partner_Registration__c>([SELECT Id,Name,Lead__c FROM Partner_Registration__c WHERE Lead__c =: dealRegLead1.Id]);
        //Assert.isTrue(prList.size()>0,'Partner Registration creation fails');
    }
    
    @IsTest
    static void deniedLeadTest(){
        String orgId = UserInfo.getOrganizationId();
        String partnerUsername = 'partner@test.com'+orgId;
        
        //Before state - Assert that the running user(PSM) has no lead records visible to them
        List<Lead> myLeadsAtStart = (List<Lead>)Database.Query('Select Id from Lead');
        System.assert(myLeadsAtStart.size() == 0);
        
        Account partnerAccount = [SELECT Id FROM Account WHERE isPartner = true];
        Contact partnerContact = [SELECT Id FROM Contact WHERE AccountId=:partnerAccount.id];
        
        //Get partner user
        User partnerUser = [Select Id, Account.OwnerId from User where username =: partnerUsername];
        Account acc = createAccount('test Account','Direct Monthly',partnerUser.Id,'USD');
        insert acc;
        Contact con = createContact(acc.id);
        insert con;
        
        //Insert a Deal Reg Lead record to simulate the Partner community action
        string leadDealRegRT = sObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Channel_Registration').getRecordTypeId();//[Select Id from RecordType Where SObjectType = 'Lead' and Name = 'Channel Registration' LIMIT 1];
        Lead dealRegLead1 = new Lead (LastName = 'Test Client',Is_Deal_Registration__c = true, Email = 'dealreglead@test.com'+orgId,
                                      RecordTypeId = leadDealRegRT, phone = '+1234567890', Company = 'Test company', Business_unit__c = 'Fleet',
                                      LeadSource = 'Deal Reg Form', Country='United States', State='Texas',Partner_Account__c = partnerAccount.Id, Partner_Contact__c = partnerContact.Id,
                                      Status = 'New');
       	
        //List<Lead> leadList = new List<Lead>{dealRegLead1,dealRegLead2};
        insert dealRegLead1;
        
        Lead leadToUpdte = new Lead();
        leadToUpdte.Id = dealRegLead1.Id;
        leadToUpdte.Deal_Registration_Denied__c = true;
        
        update leadToUpdte;
        
        //system.debug([SELECT Id,Name,rvpe__DealRegistrationDenied__c,status,rvpe__DealRegistrationStatus__c FROM Lead WHERE Id =: dealRegLead1.Id]);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SubmitLeadToNotreDameTest.NotreDameHTTPServiceTestMocks());
        CRLeadToPRConversionOnTime_Batch bcVar = new CRLeadToPRConversionOnTime_Batch();
        bcVar.dateValue = Date.today().addDays(3);
        bcVar.emailIdList.add('Vijaychandra.amaraneni@Samsara.com');
        bcVar.deniedLeads = true;
        bcVar.leadSourceVal = 'Deal Reg Form';
        bcVar.partnerTypeVal = 'Channel_Registration';
        //bcVar.failedLeads.put(leadList[1].Id,'Test Message');
        Database.executebatch(bcVar);
        Test.stopTest();
    }
    
    @IsTest
    static void failedLeadsTest(){
        String orgId = UserInfo.getOrganizationId();
        String partnerUsername = 'partner@test.com'+orgId;
        
        //Before state - Assert that the running user(PSM) has no lead records visible to them
        List<Lead> myLeadsAtStart = (List<Lead>)Database.Query('Select Id from Lead');
        System.assert(myLeadsAtStart.size() == 0);
        
        Account partnerAccount = [SELECT Id FROM Account WHERE isPartner = true];
        Contact partnerContact = [SELECT Id FROM Contact WHERE AccountId=:partnerAccount.id];
        
        //Get partner user
        User partnerUser = [Select Id, Account.OwnerId from User where username =: partnerUsername];
        Account acc = createAccount('test Account','Direct Monthly',partnerUser.Id,'USD');
        insert acc;
        Contact con = createContact(acc.id);
        insert con;
        
        //Insert a Deal Reg Lead record to simulate the Partner community action
        string leadDealRegRT = sObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Channel_Registration').getRecordTypeId();//[Select Id from RecordType Where SObjectType = 'Lead' and Name = 'Channel Registration' LIMIT 1];
        Lead dealRegLead1 = new Lead (LastName = 'Test Client',Is_Deal_Registration__c = true, Email = 'dealreglead@test.com'+orgId,
                                      RecordTypeId = leadDealRegRT, phone = '+1234567890', Company = 'Test company', Business_unit__c = 'Fleet',
                                      LeadSource = 'Deal Reg Form', Country='United States', State='Texas',Partner_Account__c = partnerAccount.Id, Partner_Contact__c = partnerContact.Id,
                                      Status = 'New');
       	
        //List<Lead> leadList = new List<Lead>{dealRegLead1,dealRegLead2};
        insert dealRegLead1;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SubmitLeadToNotreDameTest.NotreDameHTTPServiceTestMocks());
        CRLeadToPRConversionOnTime_Batch bcVar = new CRLeadToPRConversionOnTime_Batch();
        bcVar.dateValue = Date.today().addDays(3);
        bcVar.emailIdList.add('Vijaychandra.amaraneni@Samsara.com');
        bcVar.idList = new List<Id>{dealRegLead1.Id};
        bcVar.failedLeads.put(dealRegLead1.Id,'Test Message');
        bcVar.leadSourceVal = 'Deal Reg Form';
        bcVar.partnerTypeVal = 'Channel_Registration';
        Database.executebatch(bcVar);
        bcVar.mapPartnerPrFields(dealRegLead1,'AE Approved');
        Test.stopTest();
    }
    
    @IsTest
    static void directMethodCall(){
        String orgId = UserInfo.getOrganizationId();
        String partnerUsername = 'partner@test.com'+orgId;
        
        //Before state - Assert that the running user(PSM) has no lead records visible to them
        List<Lead> myLeadsAtStart = (List<Lead>)Database.Query('Select Id from Lead');
        System.assert(myLeadsAtStart.size() == 0);
        
        Account partnerAccount = [SELECT Id FROM Account WHERE isPartner = true];
        Contact partnerContact = [SELECT Id FROM Contact WHERE AccountId=:partnerAccount.id];
        
        //Get partner user
        User partnerUser = [Select Id, Account.OwnerId from User where username =: partnerUsername];
        Account acc = createAccount('test Account','Direct Monthly',partnerUser.Id,'USD');
        insert acc;
        Contact con = createContact(acc.id);
        insert con;
        
        //Insert a Deal Reg Lead record to simulate the Partner community action
        string leadDealRegRT = sObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Channel_Registration').getRecordTypeId();//[Select Id from RecordType Where SObjectType = 'Lead' and Name = 'Channel Registration' LIMIT 1];
        Lead dealRegLead1 = new Lead (LastName = 'Test Client',Is_Deal_Registration__c = true, Email = 'dealreglead@test.com'+orgId,
                                      RecordTypeId = leadDealRegRT, phone = '+1234567890', Company = 'Test company', Business_unit__c = 'Fleet',
                                      LeadSource = 'Deal Reg Form', Country='United States', State='Texas',Partner_Account__c = partnerAccount.Id, Partner_Contact__c = partnerContact.Id,
                                      Status = 'New');
       	
        //List<Lead> leadList = new List<Lead>{dealRegLead1,dealRegLead2};
        insert dealRegLead1;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SubmitLeadToNotreDameTest.NotreDameHTTPServiceTestMocks());
        CRLeadToPRConversionOnTime_Batch bcVar = new CRLeadToPRConversionOnTime_Batch();
        bcVar.dateValue = Date.today().addDays(3);
        bcVar.emailIdList.add('Vijaychandra.amaraneni@Samsara.com');
        bcVar.idList = new List<Id>{dealRegLead1.Id};
        bcVar.leadSourceVal = 'Deal Reg Form';
        bcVar.partnerTypeVal = 'Channel_Registration';    
        bcVar.failedLeads.put(dealRegLead1.Id,'Test Message');
        
        Id jobId = Database.executebatch(bcVar);
        
        bcVar.mapPrFeilds(dealRegLead1,'AE Approved','Create New Opportunity');
        bcVar.sendEmailMethod(jobId, bcVar.failedLeads);
        Test.stopTest();
    }
    
    @IsTest
    public static void partnerApplicationTest(){
        String orgId = UserInfo.getOrganizationId();
        String partnerUsername = 'partner@test.com'+orgId;
        
        //Before state - Assert that the running user(PSM) has no lead records visible to them
        List<Lead> myLeadsAtStart = (List<Lead>)Database.Query('Select Id from Lead');
        System.assert(myLeadsAtStart.size() == 0);
        
        Account partnerAccount = [SELECT Id FROM Account WHERE isPartner = true];
        Contact partnerContact = [SELECT Id FROM Contact WHERE AccountId=:partnerAccount.id];
        
        //Get partner user
        User partnerUser = [Select Id, Account.OwnerId from User where username =: partnerUsername];
        Account acc = createAccount('test Account','Direct Monthly',partnerUser.Id,'USD');
        insert acc;
        Contact con = createContact(acc.id);
        insert con;
        
        //Insert a Deal Reg Lead record to simulate the Partner community action
        string leadDealRegRT = sObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Channel_Registration').getRecordTypeId();//[Select Id from RecordType Where SObjectType = 'Lead' and Name = 'Channel Registration' LIMIT 1];
        string partnerRegRT = sObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Partner_Application').getRecordTypeId();
        Lead dealRegLead1 = new Lead (LastName = 'Test Client',Is_Deal_Registration__c = false, Email = 'dealreglead@test.com'+orgId,
                                      RecordTypeId = partnerRegRT, phone = '+1234567890', Company = 'Test company', Business_unit__c = 'Fleet',
                                      LeadSource = 'Partner Application Form', Country='United States', State='Texas',Partner_Account__c = partnerAccount.Id, Partner_Contact__c = partnerContact.Id,
                                      Status = 'New');
        Lead dealRegLead2 = new Lead (LastName = 'Test Client2',Is_Deal_Registration__c = true, Email = 'dealreglead2@test.com'+orgId,
                                      RecordTypeId = partnerRegRT, phone = '+1234567890', Company = 'Test company2', Business_unit__c = 'Fleet',
                                      LeadSource = 'Partner Application Form', Country='United States', State='Texas',Partner_Account__c = partnerAccount.Id, Partner_Contact__c = partnerContact.Id,
                                      Status = 'New');
       	
        Lead dealRegLead3 = new Lead (LastName = 'Test Partner',Is_Deal_Registration__c = false, Email = 'dealreglead@test.com'+orgId,
                                      RecordTypeId = partnerRegRT, phone = '+1234567890', Company = 'Test company', Business_unit__c = 'Fleet',
                                      LeadSource = 'Partner Application Form', Country='United States', State='Texas',Partner_Account__c = partnerAccount.Id, Partner_Contact__c = partnerContact.Id,
                                      Status = 'New');
        Lead dealRegLead4 = new Lead (LastName = 'Test Partner2',Is_Deal_Registration__c = true, Email = 'dealreglead2@test.com'+orgId,
                                      RecordTypeId = partnerRegRT, phone = '+1234567890', Company = 'Test company2', Business_unit__c = 'Fleet',
                                      LeadSource = 'Partner Application Form', Country='United States', State='Texas',Partner_Account__c = partnerAccount.Id, Partner_Contact__c = partnerContact.Id,
                                      Status = 'New');
        
        List<Lead> leadList = new List<Lead>{dealRegLead1,dealRegLead2, dealRegLead3, dealRegLead4};
        insert leadList;
        
        Database.LeadConvert thisLC = new Database.LeadConvert();
        thisLC.setLeadId(leadList[0].Id);
        thisLC.setDoNotCreateOpportunity(true);
        thisLC.setConvertedStatus('Qualified');
        thisLC.setAccountId(acc.Id);
        thisLC.setContactId(con.Id);
        
        Database.convertLead(thisLC);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SubmitLeadToNotreDameTest.NotreDameHTTPServiceTestMocks());
        CRLeadToPRConversionOnTime_Batch bcVar = new CRLeadToPRConversionOnTime_Batch();
        bcVar.dateValue = Date.today().addDays(3);
        bcVar.emailIdList.add('Vijaychandra.amaraneni@Samsara.com');
        bcVar.failedLeads.put(leadList[1].Id,'Test Message');
        bcVar.isPartner = true;
        bcVar.partnerTypeVal = 'Partner_Application';
        bcVar.leadSourceVal = 'Partner Application Form';
        Database.executebatch(bcVar);
        bcVar.mapPrFeilds(leadList[1],'AE Approved','Create New Opportunity');
        Test.stopTest();
    }
}