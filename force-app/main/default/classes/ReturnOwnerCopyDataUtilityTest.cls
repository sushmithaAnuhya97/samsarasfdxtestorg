@isTest
public class ReturnOwnerCopyDataUtilityTest {
    
    @testSetup
    public static void createData() {
        
        insert new Global_Automation_Settings__c(Name = 'Automation_Settings',Allow_Handler_Selection__c = true);
        List<Opportunity> newOpportunities = new List<Opportunity>();
        List<Account> newAccounts = new List<Account>();
        List<Contact> newContacts = new List<Contact>();

        Account accountOne = new Account(Name = 'Testers 1 Inc',
                                         BillingStreet = '26 Napier Street',
                                         BillingCity = 'London',
                                         BillingPostalCode  = '1030',
                                         BillingCountry = 'United Kingdom',
                                         Billing_Email__c  = 'qdasdas@gmail.com',
                                         Organization_Size__c = '100 - 499',
                                         Industry = 'Other');
        
        insert accountOne;
        
        Contact contactOne = (Contact) TestFactory.createSObject(new Contact(AccountId = accountOne.Id));
        insert contactOne;
        
        Opportunity revOpp = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Revenue Opportunity',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Monthly',
                                                      Probability = 0.95));
        insert revOpp;
        
        Opportunity returnOpp = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Name = 'Return Opportunity Test',
                                                      StageName = 'Return Created',
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      type = 'Remorse Refund',
                                                      Price_Book_Name__c = 'Standard',
                                                      Returning_Opportunity__c = revOpp.Id,
                                                      Send_Invoice__c = false));
        newOpportunities.add(returnOpp);
        
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        insert newOpportunities;
    }
    
    @isTest
    public static void testOwnerChange() {
        
        test.startTest();
        
        Opportunity oppReturnRec = [Select Id, ownerId From Opportunity Where Type = 'Remorse Refund' limit 1];
        
        Id pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        UserRole urMgmt = new UserRole();
        User endUser = new User();
        
        List<User> userList = new List<User>();
        system.runAs(thisUser){
            urMgmt = new UserRole(Name = 'Management');
            insert urMgmt;
             
            endUser = (User)
                TestFactory.createSObject(new User(ProfileId = pId,
                                                   EmployeeNumber = '123',
                                                   LastName = 'last',
                                                   Email = 'puser000@amamama.com',
                                                   Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
                                                   CompanyName = 'TEST',
                                                   Title = 'title',
                                                   Alias = 'alias',
                                                   TimeZoneSidKey = 'America/Los_Angeles',
                                                   EmailEncodingKey = 'UTF-8',
                                                   LanguageLocaleKey = 'en_US',
                                                   LocaleSidKey = 'en_US',
                                                   Order_Admin_Fallback_User__c = TRUE,
                                                   isActive = TRUE,
                                                   UserRoleId = urMgmt.Id ));

            insert endUser;
            
        }
        
        test.stopTest();
        
        oppReturnRec.ownerId = endUser.Id;
        update oppReturnRec;
        
        User userRec = [SELECT Id, userrole.name, managerId, manager.userrole.name, manager.email,
                        manager.managerId, manager.manager.userrole.name, manager.manager.email,
                        manager.manager.manager.name, manager.manager.manager.userrole.name 
                        FROM User WHERE Id = :UserInfo.getUserId()];
        
        ReturnOwnerCopyDataUtility.updateReturnCopyFieldsFromUser(userRec, 'Owner Role');
        ReturnOwnerCopyDataUtility.updateReturnCopyFieldsFromUser(userRec, 'Manager Name');
        ReturnOwnerCopyDataUtility.updateReturnCopyFieldsFromUser(userRec, 'Manager Role');
        ReturnOwnerCopyDataUtility.updateReturnCopyFieldsFromUser(userRec, 'Manager Email');
        ReturnOwnerCopyDataUtility.updateReturnCopyFieldsFromUser(userRec, 'Director Name');
        ReturnOwnerCopyDataUtility.updateReturnCopyFieldsFromUser(userRec, 'Director Role');
        ReturnOwnerCopyDataUtility.updateReturnCopyFieldsFromUser(userRec, 'Director Email');
        ReturnOwnerCopyDataUtility.updateReturnCopyFieldsFromUser(userRec, 'AVP Name');
        ReturnOwnerCopyDataUtility.updateReturnCopyFieldsFromUser(userRec, 'AVP Role');
        
    }
    
    @isTest
    public static void testReturningOpportunityChange() {
        
        Id revId;
        Id returnId;
        
        Opportunity returnOppRec = [Select Id, type, Returning_Opportunity__c From Opportunity WHERE type = 'Remorse Refund' LIMIT 1];
        Account accRec = [Select Id From Account Limit 1];
        Contact conRec = [Select Id From Contact Limit 1];
        
        test.startTest();
        
        Opportunity revOpp = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accRec.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Revenue Opportunity',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = conRec.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Monthly',
                                                      Probability = 0.95));
        insert revOpp;
        
        returnOppRec.Returning_Opportunity__c = revOpp.Id;
        update returnOppRec;
        
        test.stopTest();
         
    }
    
    @isTest
    public static void testReturningOpportunityLinkProcess() {
        
        List<Opportunity> oppList = [Select Id, type From Opportunity];
        Id returnId;
        Id revenueId;
        
        for(Opportunity oppRec: oppList) {
            If(oppRec.type == 'Remorse Refund') {
                returnId = oppRec.Id;
            }
            If(oppRec.type == 'Revenue Opportunity') {
                revenueId = oppRec.Id;
            }
        }
        
        List<String> oppIdSet = new List<String>();
        oppIdSet.add(returnId);
        oppIdSet.add(revenueId);
        
        RelatedReturnOpportunityController.RelatedReturnWrapper rec1 = new RelatedReturnOpportunityController.RelatedReturnWrapper();
        rec1.oppIds = oppIdSet;
        
        
        List<RelatedReturnOpportunityController.RelatedReturnWrapper> recList = new List<RelatedReturnOpportunityController.RelatedReturnWrapper>();
        recList.add(rec1);
        
        RelatedReturnOpportunityController.updateCopyFieldsOnReturn(recList);
    }

}