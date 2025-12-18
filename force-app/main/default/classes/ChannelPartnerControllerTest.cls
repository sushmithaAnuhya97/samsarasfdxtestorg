@isTest
public class ChannelPartnerControllerTest {
	
    @TestSetup
    static void createChannelRelationshipTestData(){
        

        List<Account> newAccounts = new List<Account>();

        Account account = new Account(  Name = 'Testers 1 Inc',
                                        BillingCountry = 'United States',
                                        BillingState = 'California',
                                        Organization_Size__c = '100 - 499',
                                        Industry = 'Other');
        newAccounts.add(account);

        Account partnerAccount = new Account(   Name = 'Partner Testers',
                                                BillingCountry = 'United Kingdom',
                                                Organization_Size__c = '100 - 499',
                                             	Partner_Status__c = 'Transacting Partner',
                                             	Partner_Type__c = 'Insurance',
                                                Industry = 'Other', 
                                                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId());
        newAccounts.add(partnerAccount);
        insert newAccounts;

        //Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();

        // Create Contact
        List<Contact> newContacts = new List<Contact>();
        Contact contact = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'test@test.com', AccountId=partnerAccount.Id);
        newContacts.add(contact);
        insert newContacts;

        //Create Opportunity
        Opportunity revenueOpportunity = new Opportunity( Name = 'Channel Opportunity Test', AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Closed Won');            
        insert revenueOpportunity;
        
    }
    
    @isTest
    static void ChannelPartnerTests() {
		Account customerAccount = [SELECT Id, Name FROM Account WHERE Name = 'Testers 1 Inc'];
        Account partnerAccount = [SELECT Id, Name FROM Account WHERE Name = 'Partner Testers'];
        Opportunity channelOpportunity = [SELECT Id, Name FROM Opportunity WHERE Name = 'Channel Opportunity Test'];
		Contact partnerContact = [SELECT Id, Name FROM Contact WHERE Name = 'User Tester'];
        Partner_Program__c partnerProgram = createPartnerProgram();
        insert partnerProgram;
        
        Partner_Program_Enrollment__c programEnrollment = createProgramEnrollment(partnerProgram.Id, partnerAccount.Id, partnerContact.Id);
        insert programEnrollment;
        
        Test.startTest();
        ChannelPartnerController.getActivePartnerAccountIds();
        ChannelPartnerController.getActivePartners(channelOpportunity.Id);
        ChannelPartnerController.getPartnerPrograms(partnerAccount.Id);
        ChannelPartnerController.getPartnerContacts(partnerAccount.Id);
        ChannelPartnerController.createChannelRelationship(channelOpportunity.Id, partnerAccount.Id, partnerProgram.Id, partnerContact.Id, 'Partner Influenced', 'Subsidy', 'CM33', 5, customerAccount.Id, 50.00, true);
        Test.stopTest();

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
        program.SalesProgramType__c = 'Paid Referral';
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
        enrollment.SalesProgramType__c = 'Paid Referral';
        enrollment.Approved_for_Add_a_Partner_workflow__c = true;
        return enrollment;
    }
}