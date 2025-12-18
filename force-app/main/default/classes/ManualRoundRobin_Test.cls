@isTest
public class ManualRoundRobin_Test {

    @TestSetup
    private static void testDataSetup() {
        String manualSource = 'true';
        DateTime now;
        List<User> userList = new List<User>();
        userList = [SELECT Id FROM USER WHERE Profile.Name = 'Samsara ADRs' and IsActive = true order by createddate LIMIT 5];
        system.debug('userList ' + userList);
        
        List<User> userListUpd = new List<User>();
        FOR(User loc : userList) {
            loc.Enable_ADR_Leads__c = true;
            userListUpd.add(Loc);
        }
        update userListUpd;
        List<Account> newAccount = new List<Account>(); 
        
        Account acc1 = new Account (Name = 'Test Account Country FR', Organization_Size__c = '5000+', BillingCountry = 'France', Industry = 'Other',
                                   Customer_ARR__c = 5000,Is_Deal_Reg_Account__c = true,CS_Tier__c = 'Starter');
        newAccount.add(acc1);
        
     
        insert newAccount; 
        
        List<RR_Assignment_Rule__c> listRule = new List<RR_Assignment_Rule__c>();
       
        
        RR_Assignment_Rule__c rule1 = new RR_Assignment_Rule__c (Category__c = 'Lane Four', Rule_Description__c = 'Digital Onboarding', SLED__c=false,
                                                               Type__c = 'Other', Object__c='Account', Order__c = 1, Active__c=true,
                                                               Min_Value__c=0,Max_Value__c = 150000,  Always_Use_Next_Assignment__c=true,
                                                                Billing_Country__c=null, Number_of_Vehicles__c=null, Number_of_Powered_Assets__c=null,
                                                                CS_Tier__c='Starter',Field_To_Assign_User__c = 'CSM__c',
                                                                No_Deal_Reg_Check__c=true, Deal_Reg_Account__c=true,
                                                                Next_Assignment__c = userList[0].Id);
        listRule.add(rule1);
        
        RR_Assignment_Rule__c rule2 = new RR_Assignment_Rule__c (Category__c = 'Lane Four', Rule_Description__c = 'Digital Onboarding1', SLED__c=false,
                                                               Type__c = 'Other', Object__c='Account', Order__c = 1, Active__c=true, Customer_ARR__c = '<=9999',
                                                                 Always_Use_Next_Assignment__c=true,
                                                                Billing_Country__c=null, Number_of_Vehicles__c=null, Number_of_Powered_Assets__c=null,
                                                                CS_Tier__c='Starter',Field_To_Assign_User__c = 'SIC__c',
                                                                No_Deal_Reg_Check__c=true, Deal_Reg_Account__c=true,
                                                                Next_Assignment__c = userList[0].Id);
        listRule.add(rule2);
        
        
        insert listRule;
    
        List<RR_Assignment_Mapping__c> arrMapList = new List<RR_Assignment_Mapping__c>();
        RR_Assignment_Mapping__c map0 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[0].Id, User__c=userList[3].Id, Order__c = 1, 
                                                                     Active__c=true, Type__c='Country', Value_Total__c=10000, Max_Value__c=2000000);
        
        arrMapList.add(map0);
        RR_Assignment_Mapping__c map01 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[0].Id, User__c=userList[4].Id, Order__c = 2, 
                                                                     Active__c=true, Type__c='Country', Value_Total__c=10000, Max_Value__c=2000000);
        
        arrMapList.add(map01);
        RR_Assignment_Mapping__c map1 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[1].Id, User__c=userList[0].Id, Order__c = 1, 
                                                                     Active__c=true, Type__c='Country', Value_Total__c=200000, Max_Value__c=200000);
        
        arrMapList.add(map1);
        
		RR_Assignment_Mapping__c map2 = new RR_Assignment_Mapping__c(Assignment_Rule__c=listRule[1].Id, User__c=userList[0].Id, Order__c = 1, 
                                                                     Active__c=true, Type__c='ARR', Value_Total__c=200000, Max_Value__c=200000);
        
        arrMapList.add(map2);
		
        insert arrMapList;
    }
    
    @isTest
    static void testAssignNextAssignment_LaneFourSLED21() {
        
        Account oldAccount = [SELECT Id, Is_Owner_Pool_User__c, Assign_CSM__c,is_deal_reg_account__c,Record_Type_Stamp_for_Dupes__c, Organization_Size__c,Global_Geography__c,
                              Most_Recent_Source__c,Industry,Business_Unit__c, Partner_Program_Tier__c, Partner_Persona__c, BillingCountry, BillingState,BillingCountryCode,
                              Which_written_language__c, CS_Tier__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c, Inside_Sales_Assignment__c,
                              Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c, website, Domain_Name__c, CSM__c, SLED_Account__c, 
                              Name, Number_of_Students__c, Number_of_Citizens__c, Account_Lifetime_ACV__c, Hashtag__c, Onboarding_Complete__c, Owner_Role__c, timezone__c    
                              ,Customer_ARR__c
                              FROM Account LIMIT 1];
        
        List<ManualRoundRobin.ManualRoundRobinRequest> lstRequests = new List<ManualRoundRobin.ManualRoundRobinRequest>();
        ManualRoundRobin.ManualRoundRobinRequest req = new ManualRoundRobin.ManualRoundRobinRequest(); 
        req.fieldToUpdate = 'IC';
        req.accountRecord = oldAccount;
        lstRequests.add(req);
        ManualRoundRobin.invokeRounRobin(lstRequests);
    }
        
}