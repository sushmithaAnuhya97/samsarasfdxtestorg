/*
 * April-10-2024 Manjusha Jammula GTMS:18358 - updated code to get sum of ARR from all Accounts in hierarchy
 * Test class Name: UpdateParentAccountDataTest
*/
public class UpdateParentAccountData {
    //GTMS:18358 - start
    @InvocableMethod(label='Update Parent Account Customer ARR')
    public static void updateAccountARR(List<inputVariables> inputVariables){
        List<Account> AccountsToUpdate = new List<Account>();  
        Decimal TotalArr = 0;
        Set<Id> accountIds = new Set<Id>();
        List<String> updatedFields = new List<String>();
		Map<Id, LIST<Id>> ultimateParentsMap = new Map<Id, LIST<Id>>();
        
        for(InputVariables inputVar : inputVariables) {
            updatedFields.add(inputVar.updatedField);
            
            if(inputVar.updatedAcc.Ultimate_Parent__c == null){
                List<Id> emptyIds = new List<Id>();
                ultimateParentsMap.put(inputVar.updatedAcc.Id,emptyIds);
            }
            else{
                if(ultimateParentsMap.containsKey(inputVar.updatedAcc.Ultimate_Parent__c)){
                    ultimateParentsMap.get(inputVar.updatedAcc.Ultimate_Parent__c).add(inputVar.updatedAcc.Id);
                    accountIds.add(inputVar.updatedAcc.Id);
                }
                else{
                    List<Id> childIds = new List<Id>();
                    childIds.add(inputVar.updatedAcc.Id);
                    ultimateParentsMap.put(inputVar.updatedAcc.Ultimate_Parent__c, childIds);
                    accountIds.add(inputVar.updatedAcc.Id);
                }
            }
        }

        // Retrieve aggregated ARR for child with ultimate parents
        Map<Id, AggregateResult> ChildArr = new Map<Id, AggregateResult>();
        List<AggregateResult> results1 = [SELECT Ultimate_Parent__c, SUM(Customer_ARR__c) sumARR 
                                           FROM Account 
                                           WHERE Ultimate_Parent__c IN :ultimateParentsMap.keySet() 
                                           GROUP BY Ultimate_Parent__c];
        if(results1 != null){
            for (AggregateResult ar : results1) {
                    Id parentId = (Id)ar.get('Ultimate_Parent__c');
                    ChildArr.put(parentId, ar);
            }
        }

        // Retrieve aggregated ARR for individual ultimate parents accounts
        Map<Id, AggregateResult> ParentArr = new Map<Id, AggregateResult>();
        List<AggregateResult> results2 = [SELECT Id, SUM(Customer_ARR__c) sumARR 
                                           FROM Account 
                                           WHERE Id IN :ultimateParentsMap.keySet() 
                                           GROUP BY Id];
        if(results2 != null){
            for (AggregateResult ar : results2) {            
                    Id accountId = (Id)ar.get('Id');
                    ParentArr.put(accountId, ar);
            }
        }
        
        Map<Id, List<Id>> childAccounts = new Map<Id, List<Id>>();   
        
        List<Account> childAccountList = [select id, Ultimate_Parent__c from Account where Ultimate_Parent__c IN :ultimateParentsMap.keySet()];
        if(childAccountList != null){
        for (Account childAccount : childAccountList) {
            if(childAccounts.containsKey(childAccount.Ultimate_Parent__c))
                childAccounts.get(childAccount.Ultimate_Parent__c).add(childAccount.Id);
            else{
                List<Id> childAccountIds = new List<Id>();
                childAccountIds.add(childAccount.Id);
             	childAccounts.put(childAccount.Ultimate_Parent__c, childAccountIds);
            }
        }
        }
        Map<Id,Account> accountTierIds = new Map<Id,Account>();
        for(Id parentId: ultimateParentsMap.keySet()){
            TotalArr = ((ChildArr.get(parentId) != null && ChildArr.get(parentId).get('sumARR') != null) ? (Decimal)ChildArr.get(parentId).get('sumARR') : 0) + ((ParentArr.get(parentId) != null && ParentArr.get(parentId).get('sumARR') != null) ? (Decimal)ParentArr.get(parentId).get('sumARR') : 0);
           
            Account acc = new Account(
                Id = parentId,
                Total_parent_child_ARR__c = TotalArr
            );
            AccountsToUpdate.add(acc);
            accountTierIds.put(parentId,acc);
            if(childAccounts.get(parentId) != null){
                for(Id childId: childAccounts.get(parentId)){
                    Account childAcc = new Account(
                        Id = childId,
                        Total_parent_child_ARR__c = TotalArr
                    );               
                    AccountsToUpdate.add(childAcc);
                    accountTierIds.put(childId,childAcc);
                }
            }
        }
       
        if (!AccountsToUpdate.isEmpty()) {
            Map<Id,String> AccountTierMap = updateTierDetails(accountTierIds);
            // Iterate through account and set CS Tier to Core/Select/Strategic role accounts
            for(Account acc : AccountsToUpdate){
                if(AccountTierMap.containsKey(acc.Id)){
                    acc.CS_Tier__c = AccountTierMap.get(acc.Id);
                }
            }
            system.debug('AccountsToUpdate: '+AccountsToUpdate);
            TriggerHandler.bypass('GS_AccountTriggerHandler');
            Database.SaveResult[] results = Database.update(AccountsToUpdate, false);

            // Log any errors encountered during update
            for (Database.SaveResult result : results) {
                if (!result.isSuccess()) {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Error updating Account in UpdateParentAccountData: ' + error.getMessage());
                    }
                }
            }
            RoundRobinHandler rr = new RoundRobinHandler('Lane Four', 'Account', 'SIC__c'); 
            List<Account> forUpdateAccount = new List<Account>();
            List<Account> listAccount = [SELECT Id, Is_Owner_Pool_User__c, Assign_CSM__c,is_deal_reg_account__c,Record_Type_Stamp_for_Dupes__c, Organization_Size__c,Global_Geography__c,
                                         Most_Recent_Source__c,Industry,Business_Unit__c, Partner_Program_Tier__c, Partner_Persona__c, BillingCountry, BillingState,BillingCountryCode,
                                         Which_written_language__c, CS_Tier__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c, Inside_Sales_Assignment__c,
                                         Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c, website, Domain_Name__c, CSM__c, SLED_Account__c, Name, 
                                         Customer_ARR__c, Number_of_Students__c, Number_of_Citizens__c, Account_Lifetime_ACV__c, Hashtag__c, SIC__c, Onboarding_Complete__c, Partner_Type__c,
                                         Owner_Profile_Id__c, Timezone__c, Owner_Role__c,Owner_Manager__c  
                                         FROM Account 
                                         WHERE Id IN : accountTierIds.keySet() AND SIC__c = null];
            if(Test.isRunningTest()){
                listAccount = [SELECT Id, Is_Owner_Pool_User__c, Assign_CSM__c,is_deal_reg_account__c,Record_Type_Stamp_for_Dupes__c, Organization_Size__c,Global_Geography__c,
                               Most_Recent_Source__c,Industry,Business_Unit__c, Partner_Program_Tier__c, Partner_Persona__c, BillingCountry, BillingState,BillingCountryCode,
                               Which_written_language__c, CS_Tier__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c, Inside_Sales_Assignment__c,
                               Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c, website, Domain_Name__c, CSM__c, SLED_Account__c, Name, 
                               Customer_ARR__c, Number_of_Students__c, Number_of_Citizens__c, Account_Lifetime_ACV__c, Hashtag__c, SIC__c, Onboarding_Complete__c, Partner_Type__c,
                               Owner_Profile_Id__c, Timezone__c, Owner_Role__c,Owner_Manager__c  
                               FROM Account 
                               WHERE Id IN : accountTierIds.keySet()];
            }
            For(Account accntRec : listAccount) {
                RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
                rrInfo = rr.getAssignedUser(accntRec);
                Account accInfo = new Account();
                system.debug('Rule==>'+rrInfo);
                if (rrInfo.fieldToUpdate != null && rrInfo.userId != null && rrInfo.fieldToUpdate=='SIC__c') 
                {
                    accInfo.put(rrInfo.fieldToUpdate, rrInfo.userId);
                    accInfo.Account_Assignment_Date__c = System.now();
                    accInfo.RR_Assignment_Rule__c = rrInfo.ruleId;
                    accInfo.RR_Assignment_Mapping__c = rrInfo.mappingId;
                }
                accInfo.Id = accntRec.Id;
                accInfo.Initiate_Round_Robin__c = false;
                forUpdateAccount.add(accInfo);
            }
            if (forUpdateAccount != null && forUpdateAccount.size()>0) {
                TriggerHandler.bypass('GS_AccountTriggerHandler');
                Database.update(forUpdateAccount,false);
                rr.updateRuleDetail();
            } 
        }
        
    }
    public class inputVariables{
        @InvocableVariable
        public Account updatedAcc;
        @InvocableVariable
        public String updatedField;       
    }
    
    //GTMS-26905 chnages added
    public static Map<Id,String> updateTierDetails(Map<Id,Account> accountMap){
        Set<Id> accountIds = accountMap.keySet();
        Map<Id,String> accountTierMap = new Map<Id,String>();       
        List<Account> newAccountList =[SELECT Id,CS_Tier_Override__c,Total_parent_child_ARR__c,Customer_Arr__c,Owner_Role__c,CS_Tier__c
                                       FROM Account WHERE Id IN : accountIds];
        for(Account acc : newAccountList){
            if(!acc.CS_Tier_Override__c){
                Account accTotalArr = accountMap.get(acc.Id);
                Boolean isTierUpdated = false;
                for(CS_Tier_Limit__mdt tier : listOfActiveTiers){
                    if(String.isNotBlank(tier.Field_API_Name__c)) {
                           String roleName =  acc.Owner_Role__c ;
                        	//System.debug('*** value ' + Double.valueOf(acc.get(tier.Field_API_Name__c)));
                        //System.debug('*** Min ' + tier.Min_Value__c + ' *** max ' + tier.Max_Value__c );
                        
                           if(String.isNotBlank(roleName) &&  tier.Owner_Role__c != null && tier.Active__c &&
                              roleName.contains(tier.Owner_Role__c) &&
                              (tier.Segment__c == '(ALL)' || roleName.contains(tier.Segment__c)) &&
                              accTotalArr.get(tier.Field_API_Name__c) != null &&
                              Double.valueOf(accTotalArr.get(tier.Field_API_Name__c)) >= tier.Min_Value__c &&
                              Double.valueOf(accTotalArr.get(tier.Field_API_Name__c)) <= tier.Max_Value__c){
                                  if(tier.Field_API_Name__c=='Total_parent_child_ARR__c' && roleName.contains('SLED')){
                                      acc.CS_Tier__c = acc.CS_Tier__c;
                                  }else{
                                      acc.CS_Tier__c=tier.Tier_Name__c;
                                  }
                                  accountTierMap.put(acc.Id,acc.CS_Tier__c);
                                  System.debug('*** Tier Name ' + acc.CS_Tier__c);
                                  isTierUpdated = true;
                                  break;
                              }
                       }
                }
                if(!isTierUpdated){
                    if((acc.Owner_Role__c != null && !acc.Owner_Role__c.contains('COR') && !acc.Owner_Role__c.contains('SEL') && !acc.Owner_Role__c.contains('STR')) && 
                            acc.Customer_ARR__c > 0 && acc.Customer_ARR__c < 50000){ //Updated acc.Customer_ARR__c < 30000 to acc.Customer_ARR__c < 50000 as part of GTMS-25914
                        acc.CS_Tier__c = 'Starter';
                                accountTierMap.put(acc.Id,acc.CS_Tier__c);
                    }
                }

                if((acc.Customer_ARR__c == NULL || acc.Customer_ARR__c <= 0) &&(acc.Total_parent_child_ARR__c == NULL || acc.Total_parent_child_ARR__c <= 0)){
                    acc.CS_Tier__c = '';
                    accountTierMap.put(acc.Id,acc.CS_Tier__c);
                }
            }
        }
        return accountTierMap;
    }

    static List<CS_Tier_Limit__mdt> listOfActiveTiers {get{
        if(listOfActiveTiers != null){
            if(!listOfActiveTiers.isEmpty())
                return listOfActiveTiers;
        }
        listOfActiveTiers = [SELECT id,Active__c, Field_API_Name__c,
                             Max_Value__c, Min_Value__c, Owner_Role__c,
                             Tier_Name__c,Segment__c
                             FROM CS_Tier_Limit__mdt
                             WHERE Active__c = TRUE AND Field_API_Name__c = 'Total_parent_child_ARR__c'
                             ORDER BY Segment__c, Owner_Role__c ASC];
        return listOfActiveTiers;
    }set;}
}