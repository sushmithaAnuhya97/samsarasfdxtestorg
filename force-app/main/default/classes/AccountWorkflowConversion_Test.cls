@isTest  (SeeAllData=false)
public class AccountWorkflowConversion_Test {
     @isTest
    private static void testDataSetup() {
        //List<Account> newAccount = new List<Account>();
        //List<Account> oldAccount = new List<Account>();
        Account newAccount = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other',csm__c=userinfo.getUserId());
        newAccount.CSM_Sub_Status__c='Onboarding Complete';
        newAccount.Micro_Fleet_Support_Tier__c=true;
        newAccount.Number_of_Vehicles__c=150;
        newAccount.Current_Telematics_Provider__c='Fleetmatics';
        
        insert newAccount;
        Account oldAccount = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        
        
        insert oldAccount;
        Map<Id,Account> accountsWithCsmMap = new Map<Id,Account>();
        accountsWithCsmMap.put(newAccount.id,newAccount);
        Map<Id, User> accountCsmMap = new Map<Id, User>();
        user u = new user();
        u.id=newAccount.ownerid;
        accountCsmMap.put(newAccount.CSM__c,u);
        accountCsmMap.put(newAccount.Support_Escalation_Owner__c,u);
       // set<id> user = new set<id>();
       // user Us = [select id , name,ManagerId from User where isActive = true limit 1  ];
        
       // accountCsmMap.put(newAccount.ownerid,Us);
        Test.startTest(); 
        AccountWorkflowConversion.beforeInsertUpdateRules(newAccount,oldAccount);
        AccountWorkflowConversion.beforeInsertRules(newAccount);
        AccountWorkflowConversion.completeCsmOnboarding(accountsWithCsmMap,accountCsmMap);
        AccountWorkflowConversion.uncheckAssignCSM(accountsWithCsmMap,accountCsmMap);
        AccountWorkflowConversion.stampCSMManagerEmail(accountsWithCsmMap,accountCsmMap);
        AccountWorkflowConversion.stampCSMName(accountsWithCsmMap,accountCsmMap);
        AccountWorkflowConversion.stampEscalationOwnerName(accountsWithCsmMap,accountCsmMap);
        AccountWorkflowConversion.preApproveSamsaraStatus(accountsWithCsmMap,accountCsmMap);
        AccountWorkflowConversion.declinePreApproveSamsaraStatus(accountsWithCsmMap,accountCsmMap);
        Test.stopTest();
             
      
    }
    

}