@ISTest
public class PartnerOpportunityHelper_TEST {
    
    @TestSetup
    static void setup(){
        Id partnerAccRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();
        Id fleetAccRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Fleet').getRecordTypeId();
        Id partnerConRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();
        Id fleetConRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Fleet').getRecordTypeId();
        
        Account partnerAccount = createAccount('Test Partner Account',partnerAccRecordTypeId);
        partnerAccount.Partner_Status__c = 'Transacting Partner';
        
        insert partnerAccount;
        
        
        Contact partnerContact = createContact(partnerAccount.Id, partnerConRecordTypeId);
        insert partnerContact;
        
        Account fleetAccount = createAccount('Test Fleet Contact', fleetAccRecordTypeId);
        insert fleetAccount;
        
        Contact fleetContact = createContact(fleetAccount.Id, fleetConRecordTypeId);
        insert fleetContact;
        
        Partner_Program__c partnerProgram = createPartnerProgram();
        insert partnerProgram;
        
        Partner_Program_Enrollment__c programEnrollment = createProgramEnrollment(partnerProgram.Id, partnerAccount.Id, partnerContact.Id);
        insert programEnrollment;
        
        Opportunity sourceOppty = createOpportunity('sourceOppty',fleetAccount.Id,'Net 30');
        insert sourceOppty;

		SBQQ__Quote__c quoteRec = createQuote(sourceOppty.Id,fleetAccount.Id,'USD');
        //insert quoteRec;
        
        Channel_Relationship__c crRec = createCRRecord(sourceOppty.Id, partnerAccount.id, fleetAccount.Id, partnerProgram.Id, programEnrollment.Id);
        insert crRec;
        
    } 
    
    public static User createUser(string firstName, string lastName, string roleId, string profileId, string alias){
        User activeUser = new User(
                LastName = firstName,
                FirstName = lastName,
                Email = firstName+'.'+lastname+'@samsara.com',
                Username = firstName+'.'+lastname+'@samsara.com.test',
                ManagerId = UserInfo.getUserId(),
                UserRoleId = roleId,
                CompanyName = 'TEST',
                Title = 'title',
                Alias = alias,
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = profileId,
                EmployeeNumber = 'abcdefg',
                IsActive = true   
        );
        return activeUser;
    }
    
    public static Account createAccount(String accountName, string recordTypeId){
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
        testAccount.RecordTypeId = recordTypeId;
        return testAccount;
    }

    public static Contact createContact(Id accountId,string recordTypeId) {
        Contact testContact = new Contact();
        testContact.FirstName = 'Test';
        testContact.LastName = 'Contact';
        testContact.AccountId = accountId;
        testContact.Source__c = 'Adwords';
        testContact.Email = 'test@test.com';
        testContact.recordTypeId = recordTypeId;
        return testContact;
    }
    
    public static Opportunity createOpportunity(string oppName, Id accId, string pTerms){
         Opportunity opp = new Opportunity(
             Name = oppName, 
             StageName = 'Purchase',
             CloseDate = Date.today(),
             Custom_Schedule__c = false,
             Type = 'Revenue Opportunity',
             Is_Webstore_Upsell_Opportunity__c = false,
             SBQQ__Renewal__c = false,
             Selected_Payment_Type__c = 'Upfront Payments',
             AccountId = accId,
             Payment_Terms__c = pTerms,
             Initial_Payment_Terms__c = pTerms
             
        );
        return Opp;
    }
    
     static SBQQ__Quote__c createQuote(string oppId, string accId,string currencyVal){
        
        SBQQ__Quote__c qte = new SBQQ__Quote__c();
        qte.Quote_Name__c = 'Test Quote';
        qte.SBQQ__Opportunity2__c = oppId;
        qte.SBQQ__Primary__c = true;
        qte.SBQQ__Status__c='Approved';
        qte.SBQQ__StartDate__c = Date.today();
        qte.SBQQ__EndDate__c = Date.today().addMonths(12);
        qte.CurrencyIsoCode = currencyVal;
        return qte;
    }
    
    static Channel_Relationship__c createCRRecord(string OppId, string partnerAccId, string customerAccId, string programId, string enrollmentId){
        Channel_Relationship__c crRec = new Channel_Relationship__c();
        crRec.Channel_Partner__c = partnerAccId;
        crRec.Customer_Account__c = customerAccId;
        crRec.Is_Deal_Registration__c = false;
        crRec.Opportunity__c = oppId;
        crRec.Partner_Program__c = programId;
        crRec.Partner_Enrollment__c = enrollmentId;
        crRec.Partner_Interaction_Type__c = 'Partner Influenced';
        return crRec;
    }
    
    static Partner_Program__c createPartnerProgram(){
        Partner_Program__c program = new Partner_Program__c();
        program.Name = 'Test Program';
        program.Allow_Enrollment__c = 'Yes';
        program.Approvals_Required__c = 'No';
        program.Program_Status__c = 'Active';
        program.Member_Review_Period__c = 'Evergreen';
        program.Sourced_Payout_Model__c = 'Percentage';
        program.Sourced_Payout_Percentage__c = 10;
        program.Sourced_Payout_Fee__c = 1000;
        program.Sourced_Payout_Cap__c = 75000;
        program.Influence_Payout_Model__c = 'Percentage';
        program.Influence_Payout_Percentage__c = 10;
        program.Influence_Payout_Fee__c = 500;
        program.Influence_Payout_Cap__c = 5000;
        program.Partner_Discount__c = 20;
        program.Paid_for_new_business__c = 'Yes';
        program.Program_Compensation_Model__c = 'Paid';
        return program;        
    }
    
    static Partner_Program_Enrollment__c createProgramEnrollment(string programId, string partnerAccId, string partnerConId){
        Partner_Program_Enrollment__c enrollment = new Partner_Program_Enrollment__c();
        enrollment.Partner_Program__c = programId;
        enrollment.Partner_Account__c = partnerAccId;
        enrollment.Partner_Contact__c = partnerConId;
        enrollment.Member_Status__c = 'Active';
        enrollment.Sourced_Payout_Model__c = 'Percentage';
        enrollment.Sourced_Payout_Percentage__c = 10;
        enrollment.Sourced_Payout_Fee__c = 1000;
        enrollment.Sourced_Payout_Cap__c = 75000;
        enrollment.Influence_Payout_Model__c = 'Percentage';
        enrollment.Influence_Payout_Percentage__c = 10;
        enrollment.Influence_Payout_Fee__c = 500;
        enrollment.Influence_Payout_Cap__c = 5000;
        enrollment.Program_Compensation_Model__c = 'Paid';
        return enrollment;
    }

    @IsTest
    static void rebateCreationTest(){
        

        Test.startTest();
            Opportunity opp = [SELECT Id FROM Opportunity WHERE Name ='SourceOppty' LIMIT 1];
            Opportunity OppToUpdate = new Opportunity();
            oppToUpdate.Id = opp.Id;
            oppToUpdate.StageName = 'Closing';
            oppToUpdate.Free_Trial_Purchase__c = 'Full Buy';
                
            update oppToUpdate;
            PartnersOpportunityHelper.createRebateOpportunities(new List<Id>{opp.Id});
        Test.stopTest();
    }

    @IsTest
    static void rebateCreationFtureTest(){
        

        Test.startTest();
            Opportunity opp = [SELECT Id,stageName,Type,OwnerId FROM Opportunity WHERE Name ='SourceOppty' LIMIT 1];
            Opportunity OppToUpdate = new Opportunity();
            oppToUpdate.Id = opp.Id;
            oppToUpdate.StageName = 'Closing';
            oppToUpdate.Free_Trial_Purchase__c = 'Full Buy';
                
            update oppToUpdate;

            Opportunity newOpp = new Opportunity();
            newOpp.Id = opp.Id;
            newOpp.Type = 'Revenue Opportunity';
            newOpp.Stagename = 'Closing';
            newOpp.OwnerId = opp.OwnerId;
            PartnersOpportunityHelper.opptyAfterClosing(new List<Opportunity>{newOpp} , new Map<Id,Opportunity>{opp.Id => opp});
        Test.stopTest();
    }

}