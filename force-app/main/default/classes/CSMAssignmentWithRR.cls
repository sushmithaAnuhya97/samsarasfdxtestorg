/*
 * Test Class   :   CSMAssignmentWithRRTest
 * Coverage     :   
 * Description  :   This batch apex assigns CSM to Accounts based on CS Tier and ARR 
 * Related Jira :   GTMS-23546
 * *************************************************************************************************************
*/

global class CSMAssignmentWithRR implements Database.Batchable<sObject>, Database.Stateful,Schedulable {
    
      global Database.Querylocator start (Database.BatchableContext BC) {
         // Fetching the Account records with conditions query added in the Custom Labels 
        return Database.getQueryLocator(System.Label.CA_Assignment_Accounts);
    } 
    
      global void execute (Database.BatchableContext BC, List<Account> accList) {
          Set<Id> accountIdSet=new Set<Id>();
         // system.debug('AccList==>'+accList);
          if(!accList.isEmpty()){
              for(Account accRecord:accList){
                  accountIdSet.add(accRecord.Id);
              }
          }
          if(!accountIdSet.isEmpty()){
              assignCSMFieldWithUser(accountIdSet);
          }
      }
 
/**
* Created By : Anil Kothapally
* @Date August 27th, 2024
* Created for GTMS-23456
* @description : this method will be responsible to perform on CSM criteria and assign CSM__c value
**/
    public static void assignCSMFieldWithUser(Set<Id> listOfIdToUpdated) {
      //  system.debug('listOfIdToUpdated Future ' + listOfIdToUpdated);
        List<Account> listAccountForUpdate = new List<Account>();
        List<Account> listAccount=[SELECT Id, Is_Owner_Pool_User__c, Assign_CSM__c,is_deal_reg_account__c,Record_Type_Stamp_for_Dupes__c, Organization_Size__c,Global_Geography__c,
                                   Most_Recent_Source__c,Industry,Business_Unit__c, Partner_Program_Tier__c, Partner_Persona__c, BillingCountry, BillingState,BillingCountryCode,
                                   Which_written_language__c, CS_Tier__c, Experimental_Group__c, Experimental_Group_Routing__c, Account_Size_Segment__c, Inside_Sales_Assignment__c,
                                   Number_of_Vehicles__c, Number_of_Powered_Assets__c, Number_of_Unpowered_Assets__c, website, Domain_Name__c, CSM__c, SLED_Account__c, Name,
                                   Customer_ARR__c, Number_of_Students__c, Number_of_Citizens__c, Account_Lifetime_ACV__c, Hashtag__c, SIC__c,
                                   Onboarding_Complete__c, Partner_Type__c, Owner_Profile_Id__c, Timezone__c, Owner_Role__c,Owner_Manager__c 
                                   FROM Account WHERE Id IN:listOfIdToUpdated];
        RoundRobinHandler rr = new RoundRobinHandler('Lane Four', 'Account', 'CSM__c'); 
        List<Account> forUpdateAccount = new List<Account>();
        For(Account accntRec : listAccount) {
            RoundRobinHandler.RoundRobinInfo rrInfo = new RoundRobinHandler.RoundRobinInfo();
            rrInfo = rr.getAssignedUser(accntRec);
            Account accInfo = new Account();
            system.debug('Rule==>'+rrInfo);
            if (rrInfo.fieldToUpdate != null && rrInfo.userId != null && rrInfo.fieldToUpdate=='CSM__c') 
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

      global void finish(Database.BatchableContext BC) {
            System.debug('CSMAssignmentWithRR Job Finish');
    }
  

     global void execute(SchedulableContext sc)
    {
        CSMAssignmentWithRR b = new CSMAssignmentWithRR();
        database.executebatch(b,200);
    }

}