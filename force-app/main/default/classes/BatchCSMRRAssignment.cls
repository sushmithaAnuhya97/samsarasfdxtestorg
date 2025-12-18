/*
 * Test Class   :   BatchCSMRRAssignmentTest
 * Coverage     :   98%
 * Description  :   This batch apex assigns CSM to Accounts based on CS Tier, Billing Country and CS Tier
 * Related Jira :   GTMS-1015
 * *************************************************************************************************************
 * 08/17/21 Lavanya - (GTMS-4397) Added logic to send an email after job completion with all the details
 * 05/03/21 Sai - (GTMS-3328) Handled Started touch touch limits in MDT also assign to RR when min touchtouch limits are tirggered
 * 02/04/21 Harsha -(GTMS-2594) Addded the logic to update associated Cs Records
 * 01/21/20 Satya - (GTMS-2707): updated logic to update CS Tier based on Lifetime ACV if Customer ARR is blank
 * 10/12/20 Satya - (GTMS-1790): updated logic to handle low tech touch users
 * 9/3/20   Teja  - (GTMS-1346): icPlusRRAssignment, getCSMWithLeastAmount (Added logic for Plus tier to add Accounts on the basis of Account LifeTime AcV)
 * 7/12/20  Satya - (GTMS-1015): Created
 * 8/25/2022 - Siddharth Kumar Mishra - (GTMS-7408) :added new logic for less than $5k Lifetime_ACV_to_USD__c
 * 8/01/2024- Anil (GTMS-22645) : Updated criteria for US and Canada pool users based on the requirements mentioned in the ticket
*/
global class BatchCSMRRAssignment implements Database.Batchable<sObject>, Database.Stateful,Schedulable {
    
    public String emailBody = '';
    List<Account> lstStarterAccEast = new List<Account>();
    List<Account> lstPlusAccEast = new List<Account>();
    List<Account> lstStarterAccCW = new List<Account>();
    List<Account> lstPlusAccCW = new List<Account>();
    List<Account> lstStarterAccEastCan = new List<Account>();
    List<Account> lstPlusAccEastCan = new List<Account>();
    List<Account> lstStarterCWAccCan = new List<Account>();
    List<Account> lstPlusAccCWCan = new List<Account>();
    List<Account> lstStarterAccInThereshold = new List<Account>();
    List<Account> lstStarterAccBelow5k = new List<Account>();
    List<Account> lstStarterAccBelowThereshold = new List<Account>();
    //List<Account> lstSpanishAcc = new List<Account>(); //GTMS-18632, No longer needed, all the types are handled in a single map
    
    Map<Id, Integer> starterUsersBelow5k = new Map<Id, Integer>();
    Map<Id, Integer> starterUsersInThreshold = new Map<Id, Integer>();
    //Map<Id, Integer> starterUsersBelowThreshold = new Map<Id, Integer>(); //GTMS-18632, No longer needed, all the types are handled in a single map
    Map<Id, Integer> userRecordCount = new Map<Id, Integer>();
    Map<Id, Double> userPlusAcvAmount = new Map<Id, Double>();
    //Map<Id, Integer> starterEast = new Map<Id, Integer>(); //GTMS-18632, No longer needed, all the types are handled in a single map
    //Map<Id, Integer> starterCentralWest = new Map<Id, Integer>(); //GTMS-18632, No longer needed, all the types are handled in a single map
    //Map<Id, Double> plusEast = new Map<Id, Double>(); //GTMS-18632, No longer needed, all the types are handled in a single map
    //Map<Id, Double> plusCentralWest = new Map<Id, Double>(); //GTMS-18632, No longer needed, all the types are handled in a single map
    Map<Id, Double> plusEastCanada = new Map<Id, Double>();
    Map<Id, Integer> starterEastCanada = new Map<Id, Integer>();
    Map<Id, Double> plusCWCanada = new Map<Id, Double>();
    Map<Id, Integer> starterCWCanada = new Map<Id, Integer>();
    Map<Id, Integer> spanishUsers = new Map<Id, Integer>();
    Map<Id, String> csm_Map = new Map<Id,String>();
    
    //Updated above types as part of GTMS-22645
    List<String> types=new List<String>{'US Private Starter Spanish IC','US Private Plus Spanish IC','US Private Starter IC',
        'US Private Plus IC','Canada French IC','Canada Starter IC','Canada Plus IC','PubSec Starter IC','PubSec Plus IC',
        'ENT Basic IC','Digital Onboarding','Mexico Plus IC','Mexico Starter IC','Mexico Plus IC JN','Mexico Starter IC JN'};
                                
    Map<String,List<Account>> typeToAccounts = new Map<String,List<Account>>();
    
    Map<String,Map<Id,Integer>> typeToUserConfigAndCount = new Map<String,Map<Id,Integer>>();
    Map<String,Map<Id,Double>> typeToUserConfigAndARR = new Map<String,Map<Id,Double>>();

    List<Account> accListToUpdate = new List<Account>();
    List<CS_Record__c> csRecsToUpdate = new List<CS_Record__c>();

    @testVisible static List<CSM_RR_User_Config__mdt> lstUserConfig {get{

        if(lstUserConfig != null){
            if(!lstUserConfig.isEmpty())
                return lstUserConfig;
        }

        lstUserConfig = [SELECT Id, type__c, Starter_Tech_Touch__c, MasterLabel, Billing_Country__c, Account_CS_Tier__c, Account_Global_Geography__c, User_Id__c,Starter_Tech_Touch_min_Assignment__c,Is_Spanish_Assignee__c FROM CSM_RR_User_Config__mdt WHERE Bypass_Assignments__c = false];

        return lstUserConfig;
    }set;}

    //Added conditions for Mexico
    Map<Id, Integer> mexicoStarter = new Map<Id, Integer>();
    Map<Id, Double> mexicoPlus = new Map<Id, Double>();
    List<Account> lstStarterMexico = new List<Account>();
    List<Account> lstPlusMexico = new List<Account>();
    
    Integer currYear = Date.today().year();

    global Database.Querylocator start (Database.BatchableContext BC) {
        return Database.getQueryLocator(System.Label.CA_Assignment_Accounts);
    } 
    
    global void execute (Database.BatchableContext BC, List<Account> scope) {

        for(string type :this.types){
            this.typeToAccounts.put(type,new list<Account>());
            this.typeToUserConfigAndCount.put(type,new Map<Id,Integer>());
            this.typeToUserConfigAndARR.put(type,new Map<Id,Double>());
        }
        
        List<Id> lstCSMUsers = new List<Id>();
        Map<String, CS_Tier_Limit__mdt> csTierMap = CS_Tier_Limit__mdt.getAll();
       
        for(CSM_RR_User_Config__mdt csConfig : lstUserConfig) {
            lstCSMUsers.add(csConfig.User_Id__c);
            csm_Map.put(csConfig.User_Id__c,csConfig.MasterLabel);
        }
          
        List<AggregateResult> aggResult = [SELECT count(Id) cnt, CSM__c, sum(Customer_ARR__c) acv FROM Account WHERE CSM_Status__c  = 'Onboarding' AND CSM_Sub_Status__c NOT IN ('Onboarding Complete','On Hold','Unresponsive','Opt Out') AND CSM__c IN :lstCSMUsers GROUP BY CSM__c];
        emailBody = '<b>CSM RR Assignment Batch Job processing completed</b><br><br> <b>CSM Details before the batch process execution</b><br><br>'+'<table border="1"> <tbody> <tr> <td><b>CSM Name</b></td> <td><b>Account Count</b></td> <td><b>Total ARR</b></td> </tr>';
        System.debug(emailBody);
        for(AggregateResult ar : aggResult) {
            userRecordCount.put((Id)ar.get('CSM__c'), Integer.valueOf(ar.get('cnt')));
            userPlusAcvAmount.put((Id)ar.get('CSM__c'), Double.valueOf(ar.get('acv')));
            emailBody += '<tr><td>'+csm_Map.get((Id)ar.get('CSM__c'))+'</td><td>'+Integer.valueOf(ar.get('cnt'))+'</td><td>'+Double.valueOf(ar.get('acv'))+'</td></tr>';         
        }
        emailBody +='</tbody> </table> <br><br>';
        for(CSM_RR_User_Config__mdt csConfig : lstUserConfig) {
            Integer recCount = userRecordCount.get(csConfig.User_Id__c) == null ? 0 : userRecordCount.get(csConfig.User_Id__c);
            Double acvAmountSum = (userPlusAcvAmount.get(csConfig.User_Id__c) == null) ? 0 : userPlusAcvAmount.get(csConfig.User_Id__c);

            // Mapping User to Type to its Count and acvAmount
            if(String.isNotBlank(csConfig.Type__c) && String.isNotBlank(csConfig.User_Id__c)){
                for(String type :csConfig.Type__c.split(';')){
                    typeToUserConfigAndCount.get(type).put(csConfig.User_Id__c, recCount);
                    typeToUserConfigAndARR.get(type).put(csConfig.User_Id__c, acvAmountSum);
                }
            }
		
            if(!csConfig.Is_Spanish_Assignee__c){
              if(!csConfig.Starter_Tech_Touch__c) {
                    //added condition for Mexico GTMS-10092
                   if(csConfig.Billing_Country__c == 'Mexico') { 
                        if(csConfig.Account_CS_Tier__c == 'Starter') {
                            mexicoStarter.put(csConfig.User_Id__c, recCount);
                        }
                        if(csConfig.Account_CS_Tier__c == 'Plus') {
                            mexicoPlus.put(csConfig.User_Id__c, acvAmountSum);
                        }
                    }
                    system.debug(mexicoStarter+'@@@@mexicoStarter');
                }
                else {
                    if(csConfig.Starter_Tech_Touch_min_Assignment__c) {
                        //starterUsersBelowThreshold.put(csConfig.User_Id__c, recCount);
                        typeToUserConfigAndCount.get('Digital Onboarding').put(csConfig.User_Id__c, recCount); //GTMS-18632, No User list provided, utilizing the existing user population logic.
                    }else{
                        starterUsersInThreshold.put(csConfig.User_Id__c, recCount);
                        system.debug('=======starterUsersInThreshold=====' + starterUsersInThreshold);
                    }
                }
            }  
        }
        
     for(Account acc : scope) {

            // As part of GTMS-18632, the below rules apply to Accounts whose user role does not contain 'SER','COL' or 'STR'.
            if(isAccInNewRoles(acc)){
				
              //Mexico Starter Owner Manager Not Julia Monroy-Gnaedig
                if(acc.CS_Tier__c == 'Starter' && acc.BillingCountry== 'Mexico' && acc.Owner_Manager__c!='Julia Monroy-Gnaedig' && acc.CSM__c == null){
                    typeToAccounts.get('Mexico Starter IC').add(acc);
                    continue;
                }
                
                //Mexico Starter Owner Manager Not Julia Monroy-Gnaedig
                if(acc.CS_Tier__c == 'Plus' && acc.BillingCountry== 'Mexico' && acc.Owner_Manager__c!='Julia Monroy-Gnaedig' && acc.CSM__c == null){
                    typeToAccounts.get('Mexico Plus IC').add(acc);
                    continue;
                }
                
                //Mexico Plus and Owner manager Julia Monroy
                if(acc.CS_Tier__c == 'Starter' && acc.BillingCountry== 'Mexico' && acc.Owner_Manager__c=='Julia Monroy-Gnaedig' && acc.CSM__c == null){
                    typeToAccounts.get('Mexico Starter IC JN').add(acc);
                    continue;
                }
                
                if(acc.CS_Tier__c == 'Plus' && acc.BillingCountry== 'Mexico' && acc.Owner_Manager__c=='Julia Monroy-Gnaedig' && acc.CSM__c == null){
                    typeToAccounts.get('Mexico Plus IC JN').add(acc);
                    continue;
                }
                
                if(acc.CS_Tier__c == 'Starter' && acc.Customer_ARR__c>=10000 && acc.Which_written_language__c == 'Spanish' && acc.Owner_Role__c.contains('NA US') && !acc.Owner_Role__c.contains('SLED') && acc.CSM__c == null){
					typeToAccounts.get('US Private Starter Spanish IC').add(acc);
                    //typeToAccounts.get('Plus Spanish IC').add(acc);
                    continue;
                }
                
                if(acc.CS_Tier__c == 'Plus' && acc.Which_written_language__c == 'Spanish' && acc.Owner_Role__c.contains('NA US') && !acc.Owner_Role__c.contains('SLED') && acc.CSM__c == null){
					typeToAccounts.get('US Private Plus Spanish IC').add(acc);
                    //typeToAccounts.get('Plus Spanish IC').add(acc);
                    continue;
                }
                
                if(acc.CS_Tier__c == 'Starter' && acc.Customer_ARR__c>=10000 && acc.Which_written_language__c != 'Spanish' && acc.Owner_Role__c.contains('NA US') && !acc.Owner_Role__c.contains('SLED') && acc.CSM__c == null){
					typeToAccounts.get('US Private Starter IC').add(acc);
                    //typeToAccounts.get('Plus Spanish IC').add(acc);
                    continue;
                }
                
                if(acc.CS_Tier__c == 'Plus' && acc.Which_written_language__c != 'Spanish' && acc.Owner_Role__c.contains('NA US') && !acc.Owner_Role__c.contains('SLED') && acc.CSM__c == null){
					typeToAccounts.get('US Private Plus IC').add(acc);
                    //typeToAccounts.get('Plus Spanish IC').add(acc);
                    continue;
                }
                
               if(acc.CS_Tier__c == 'Starter' && acc.Customer_ARR__c>=10000 && acc.Owner_Role__c.contains('SLED') && acc.CSM__c == null){

                    typeToAccounts.get('PubSec Starter IC').add(acc);
                    continue;
                }
                
                if(acc.CS_Tier__c == 'Plus' && acc.Owner_Role__c.contains('SLED') && acc.CSM__c == null){

                    typeToAccounts.get('PubSec Plus IC').add(acc);
                    continue;
                }
                
                if(acc.Which_written_language__c == 'French' && acc.Owner_Role__c.contains('NA CA') && acc.CSM__c == null){
                    typeToAccounts.get('Canada French IC').add(acc);
                    continue;
                }
                
                if(acc.CS_Tier__c == 'Starter' && acc.Customer_ARR__c>=10000 && acc.Which_written_language__c != 'French' && acc.Owner_Role__c.contains('NA CA') 
                    && acc.CSM__c == null){
                    typeToAccounts.get('Canada Starter IC').add(acc);
                    continue;
                }
                
                if(acc.CS_Tier__c == 'Plus' && acc.Which_written_language__c != 'French' && acc.Owner_Role__c.contains('NA CA') 
                    && acc.CSM__c == null){
                    typeToAccounts.get('Canada Plus IC').add(acc);
                    continue;
                }
                
                if(acc.CS_Tier__c == 'Starter' && acc.Customer_ARR__c<10000 && acc.CSM__c == null){
					typeToAccounts.get('Digital Onboarding').add(acc);
                    //typeToAccounts.get('Plus Spanish IC').add(acc);
                    continue;
                }
           }

         // Updated the conditions as part of GTMS-22645
            if((acc.CS_Tier__c == 'Core Basic' || acc.CS_Tier__c == 'Strategic Basic' || acc.CS_Tier__c == 'Select Basic') && acc.Which_written_language__c != 'Spanish' && acc.Owner_Role__c.contains('NA US') && acc.CSM__c == null){
                    typeToAccounts.get('ENT Basic IC').add(acc);
                    continue;
                }
         
            //As part of GTMS-18632, Existing Logic - If the Accounts' owner role belong to 'EMEA','Experimental' or 'ENT' skip
           if(!isAccInOldRoles(acc)) continue;

            if(acc.Total_Purchased_VG_Count__c >= 3 || acc.Total_Purchased_CM_Count__c >= 3 || acc.Total_Purchased_AG_Count__c >= 10)//GTMS-7408
            {
                Decimal arr = (acc.Customer_ARR__c == 0 || acc.Customer_ARR__c == null) ? acc.Account_Lifetime_ACV__c : acc.Customer_ARR__c;

                if((acc.Which_written_language__c == 'Spanish' && acc.BillingCountry == 'United States') || (acc.Account_Lifetime_ACV__c <= 75000 && acc.Owner_Role__c.contains('MX')))
                    continue; //As part of GTMS-18632, This continue statement is put in place to exhibit similar behavior as Previously existing lstSpanishAcc has been removed as it is moved to Starter Spanish IC
                //added condition for GTMS-10092
                if(acc.BillingCountry == 'United States' || acc.BillingCountry == 'Canada' || acc.BillingCountry == 'Mexico'){
                    system.debug('####'+csTierMap.get('Techtouch_limits').Max_Value__c);
                    if(arr > csTierMap.get('Techtouch_limits').Max_Value__c) { 
                        //added condition for GTMS-10092
                        if(acc.BillingCountry == 'Mexico') {
                            if(acc.CS_Tier__c == 'Starter') {
                                lstStarterMexico.add(acc);
                            }
                            else if(acc.CS_Tier__c == 'Plus') {
                                lstPlusMexico.add(acc);
                            }
                        }

                    }
                    else if(arr >= csTierMap.get('Techtouch_limits').Min_Value__c && arr <= csTierMap.get('Techtouch_limits').Max_Value__c) {
                        //Added as part of GTMS-13875
                        //Start
                        if(acc.BillingCountry =='Mexico'){
                            if(acc.CS_Tier__c=='Starter'){
                            lstStarterMexico.add(acc);
                            } else if(acc.CS_Tier__c == 'Plus'){
                                lstPlusMexico.add(acc);  
                            }
                            
                        }else{
                            lstStarterAccInThereshold.add(acc);  
                            system.debug('lstStarterAccInThereshold'+lstStarterAccInThereshold);
                        }
                        // End Added as part of GTMS-13875 
                    }else{
                        //Added as part of GTMS-13875
                        //Start
                        if(acc.BillingCountry =='Mexico'){
                            if(acc.CS_Tier__c=='Starter'){
                            lstStarterMexico.add(acc);
                            } else if(acc.CS_Tier__c == 'Plus'){
                                lstPlusMexico.add(acc);  
                            }
                        }else{
                        lstStarterAccBelowThereshold.add(acc);
                        }
                        //End GTMS-13875
                    }
                } 
            }
            else //GTMS-7408
            {
                //added condition for GTMS-10092
                if((acc.BillingCountry == 'United States' || acc.BillingCountry == 'Canada' || acc.BillingCountry == 'Mexico')){                    
                    if(acc.Lifetime_ACV_to_USD__c >= csTierMap.get('Techtouch_limits').Min_Value__c && acc.Lifetime_ACV_to_USD__c < csTierMap.get('Techtouch_limits').Max_Value__c) {
                        if(acc.BillingCountry=='Mexico'){
                            if(acc.CS_Tier__c=='Starter'){
                                lstStarterMexico.add(acc);
                                } else if(acc.CS_Tier__c == 'Plus'){
                                lstPlusMexico.add(acc);  
                                }
                        }else{
                        lstStarterAccInThereshold.add(acc);   
                        }
                    
                    //   lstStarterAccInThereshold.add(acc);
                    }else if(acc.Lifetime_ACV_to_USD__c < csTierMap.get('Techtouch_limits').Min_Value__c)
                    {
                        if(acc.BillingCountry=='Mexico'){
                            if(acc.CS_Tier__c=='Starter'){
                                lstStarterMexico.add(acc);
                                } else if(acc.CS_Tier__c == 'Plus'){
                                lstPlusMexico.add(acc);  
                                }
                        }else{
                        lstStarterAccBelowThereshold.add(acc);  
                        }
                    }
                }  
            }  
        }
        
   	// Adding logic as part of GTMS-22645 
		
         if(!typeToAccounts.get('US Private Starter Spanish IC').isEmpty() && !typeToUserConfigAndCount.get('US Private Starter Spanish IC').isEmpty())
            csmRRAssignment(typeToAccounts.get('US Private Starter Spanish IC'),typeToUserConfigAndCount.get('US Private Starter Spanish IC'),'US Private Starter Spanish IC');
		
		if(!typeToAccounts.get('US Private Plus Spanish IC').isEmpty() && !typeToUserConfigAndARR.get('US Private Plus Spanish IC').isEmpty())
            icPlusRRAssignment(typeToAccounts.get('US Private Plus Spanish IC'),typeToUserConfigAndARR.get('US Private Plus Spanish IC'),'US Private Plus Spanish IC');
        
         if(!typeToAccounts.get('US Private Starter IC').isEmpty() && !typeToUserConfigAndCount.get('US Private Starter IC').isEmpty())
            csmRRAssignment(typeToAccounts.get('US Private Starter IC'),typeToUserConfigAndCount.get('US Private Starter IC'),'US Private Starter IC');
		
		if(!typeToAccounts.get('US Private Plus IC').isEmpty() && !typeToUserConfigAndARR.get('US Private Plus IC').isEmpty())
            icPlusRRAssignment(typeToAccounts.get('US Private Plus IC'),typeToUserConfigAndARR.get('US Private Plus IC'),'US Private Plus IC');
        
        if(!typeToAccounts.get('Canada French IC').isEmpty() && !typeToUserConfigAndCount.get('Canada French IC').isEmpty())
            csmRRAssignment(typeToAccounts.get('Canada French IC'),typeToUserConfigAndCount.get('Canada French IC'),'Canada French IC');
        
        if(!typeToAccounts.get('Canada Starter IC').isEmpty() && !typeToUserConfigAndCount.get('Canada Starter IC').isEmpty())
            csmRRAssignment(typeToAccounts.get('Canada Starter IC'),typeToUserConfigAndCount.get('Canada Starter IC'),'Canada Starter IC');
        
        if(!typeToAccounts.get('Canada Plus IC').isEmpty() && !typeToUserConfigAndARR.get('Canada Plus IC').isEmpty())
            icPlusRRAssignment(typeToAccounts.get('Canada Plus IC'),typeToUserConfigAndARR.get('Canada Plus IC'),'Canada Plus IC');

        if(!typeToAccounts.get('PubSec Starter IC').isEmpty() && !typeToUserConfigAndCount.get('PubSec Starter IC').isEmpty())
            csmRRAssignment(typeToAccounts.get('PubSec Starter IC'),typeToUserConfigAndCount.get('PubSec Starter IC'),'PubSec Starter IC');

        if(!typeToAccounts.get('PubSec Plus IC').isEmpty() && !typeToUserConfigAndARR.get('PubSec Plus IC').isEmpty())
            icPlusRRAssignment(typeToAccounts.get('PubSec Plus IC'),typeToUserConfigAndARR.get('PubSec Plus IC'),'PubSec Plus IC');

        if(!typeToAccounts.get('ENT Basic IC').isEmpty() && !typeToUserConfigAndCount.get('ENT Basic IC').isEmpty())
            csmRRAssignment(typeToAccounts.get('ENT Basic IC'),typeToUserConfigAndCount.get('ENT Basic IC'),'ENT Basic IC');
        
        if(!typeToAccounts.get('Digital Onboarding').isEmpty() && !typeToUserConfigAndCount.get('Digital Onboarding').isEmpty()) 
            csmRRAssignment(typeToAccounts.get('Digital Onboarding'), typeToUserConfigAndCount.get('Digital Onboarding'), 'Digital Onboarding');
         
        if(!typeToAccounts.get('Mexico Starter IC').isEmpty() && !typeToUserConfigAndCount.get('Mexico Starter IC').isEmpty()) 
            csmRRAssignment(typeToAccounts.get('Mexico Starter IC'), typeToUserConfigAndCount.get('Mexico Starter IC'), 'Mexico Starter IC');
   
        if(!typeToAccounts.get('Mexico Starter IC JN').isEmpty() && !typeToUserConfigAndCount.get('Mexico Starter IC JN').isEmpty()) 
            csmRRAssignment(typeToAccounts.get('Mexico Starter IC JN'), typeToUserConfigAndCount.get('Mexico Starter IC JN'), 'Mexico Starter IC JN');
   
         if(!typeToAccounts.get('Mexico Plus IC').isEmpty() && !typeToUserConfigAndARR.get('Mexico Plus IC').isEmpty())
            icPlusRRAssignment(typeToAccounts.get('Mexico Plus IC'),typeToUserConfigAndARR.get('Mexico Plus IC'),'Mexico Plus IC');
        
         if(!typeToAccounts.get('Mexico Plus IC JN').isEmpty() && !typeToUserConfigAndARR.get('Mexico Plus IC JN').isEmpty())
            icPlusRRAssignment(typeToAccounts.get('Mexico Plus IC JN'),typeToUserConfigAndARR.get('Mexico Plus IC JN'),'Mexico Plus IC JN');
    /*    
        if(!lstStarterAccEastCan.isEmpty() && !starterEastCanada.isEmpty())csmRRAssignment(lstStarterAccEastCan, starterEastCanada,'Starter East Canada Accounts');
        if(!lstPlusAccEastCan.isEmpty() && !plusEastCanada.isEmpty())icPlusRRAssignment(lstPlusAccEastCan, plusEastCanada,'Plus East Canada Accounts');
        if(!lstStarterCWAccCan.isEmpty() && !starterCWCanada.isEmpty())csmRRAssignment(lstStarterCWAccCan, starterCWCanada,'Starter CentralWest Canada Accounts');
        if(!lstPlusAccCWCan.isEmpty() && !plusCWCanada.isEmpty())icPlusRRAssignment(lstPlusAccCWCan, plusCWCanada,'Plus CentralWest Canada Accounts');
        
        if(!lstStarterAccInThereshold.isEmpty() && !starterUsersInThreshold.isEmpty())csmRRAssignment(lstStarterAccInThereshold, starterUsersInThreshold, 'Starter In Threshold Accounts');        
        //if(!lstStarterAccBelowThereshold.isEmpty() && !starterUsersBelowThreshold.isEmpty())csmRRAssignment(lstStarterAccBelowThereshold, starterUsersBelowThreshold, 'Digital Onboarding'); //As part of GTMS-18632, Commented and moved the logic        

        //added condition for GTMS-10092
        if(!lstStarterMexico.isEmpty() && !mexicoStarter.isEmpty())csmRRAssignment(lstStarterMexico, mexicoStarter,'Starter Mexico');
        if(!lstPlusMexico.isEmpty() && !mexicoPlus.isEmpty())icPlusRRAssignment(lstPlusMexico, mexicoPlus,'Plus Mexico');
        //if(!lstStarterAccBelow5k.isEmpty())csmRRAssignment(lstStarterAccBelow5k, starterUsersBelowThreshold, 'Below 5000');
*/
      //GTMS-22645 changed update statements to Database DML statements
        if(!accListToUpdate.isEmpty()) Database.UPDATE(accListToUpdate,false);
        if(!csRecsToUpdate.isEmpty()) Database.UPDATE(csRecsToUpdate,false);

        clearData();
    }

    private boolean isAccInNewRoles(Account acc){

        if(String.isBlank(acc.Owner_Role__c)) return false;

        return !acc.Owner_Role__c.contains('SEL') && !acc.Owner_Role__c.contains('COR') && !acc.Owner_Role__c.contains('STR');
    }

    private boolean isAccInOldRoles(Account acc){

        if(String.isBlank(acc.Owner_Role__c)) return false;

        return !acc.Owner_Role__c.contains('EMEA') && !acc.Owner_Role__c.contains('Experimental');
    }

    //As the batch is stateful, avoid reprocessing the processed records.
    private void clearData(){

        for(string key :typeToAccounts.keyset()){

            if(!typeToAccounts.get(key).isEmpty())typeToAccounts.get(key).clear();
            if(!typeToUserConfigAndCount.get(key).isEmpty())typeToAccounts.get(key).clear();
            if(!typeToUserConfigAndARR.get(key).isEmpty())typeToAccounts.get(key).clear();
            if(!accListToUpdate.isEmpty()) accListToUpdate.clear();
            if(!csRecsToUpdate.isEmpty()) csRecsToUpdate.clear();
        }
    }
    
    public void csmRRAssignment(List<Account> accList, Map<Id, Integer> usersMap, String type) {
        system.debug('accList ---->'+accList);
        system.debug('usersMap ---->'+usersMap);
        Map<Id, Integer> counterMap = usersMap;
        List<CS_Record__c> csRecordIds = new List<CS_Record__c>(); 
        emailBody += '<b>CSM Round Robin Assignment :'+type +'</b><br><br>'+'<table border="1"> <tbody> <tr> <td><b>CSM Name</b></td> <td><b>Account Count</b></td> </tr>';
        for(Account a : accList) { 
            if(a.CS_Records__r.size()>0 ){ //As part of GTMS-1862, removed the condititon where owner profile must not have the phrase 'ENT'
                CS_Record__c csRecordID = a.CS_Records__r;
                csRecordIds.add(csRecordID);                
            }                      
            Id csm = getCSMWithLeastAcc(counterMap);
            a.CSM__c = csm;
            counterMap.put(csm, counterMap.get(csm)+1);
            system.debug('In csmRRAssignment');
        }
        for(Id csmId: usersMap.Keyset()){
            emailBody += '<tr><td>'+csm_Map.get(csmId)+'</td><td>'+usersMap.get(csmId)+'</td></tr>';
        }
        emailBody +='</tbody> </table> <br><br>';
        
        system.debug('minSize======'+ accList);
        accListToUpdate.addAll(accList);
        if(csRecordIds.size()>0){
          system.debug('In Update');
          csRecsToUpdate.addAll(csRecordIds);
        }
    }
    
    public Id getCSMWithLeastAcc(Map<Id, Integer> csmMap) {
       
        Id minSize = null;
        for(String key : csmMap.keyset())
            if(minSize==null||csmMap.get(key) < csmMap.get(minSize))
            minSize=key;
        system.debug('==getCSMWithLeastAcc==minSize======'+ minSize);
        return minSize;
        
    }
    
    public void icPlusRRAssignment(List<Account> accList, Map<Id, Double> usersMap, string type) {
        Map<Id, Double> counterMap = usersMap;
        List<CS_Record__c> csRecordIds = new List<CS_Record__c>();     
        for(Account a : accList) {
            if(a.CS_Records__r.size()>0){
                CS_Record__c csRecordID = a.CS_Records__r;
                csRecordIds.add(csRecordID);                
            }    
            Id csm = getCSMWithLeastAmount(counterMap);
            a.CSM__c = csm;
            Double newAmount = counterMap.get(csm);
            newAmount =+ a.Customer_ARR__c != null ? a.Customer_ARR__c : a.Account_Lifetime_ACV__c;
            //counterMap.remove(csm);
            counterMap.put(csm, newAmount);
        }
        emailBody += '<b>CSM PLUS Round Robin Assignment :'+type +'</b><br><br>'+'<table border="1"> <tbody> <tr> <td><b>CSM Name</b></td> <td><b>Total ARR</b></td> </tr>';
        for(Id csmId: usersMap.Keyset()){
            emailBody += '<tr><td>'+csm_Map.get(csmId)+'</td><td>'+usersMap.get(csmId)+'</td></tr>';
        }
        emailBody +='</tbody> </table> <br><br>';
        system.debug('icPlusRRAssignment======'+ accList);
        accListToUpdate.addAll(accList);
        if(csRecordIds.size()>0){
          csRecsToUpdate.addAll(csRecordIds);
        }
    }
    
    
    public Id getCSMWithLeastAmount(Map<Id, Double> csmMap) {
       
        Id minSize = null;
        for(String key : csmMap.keyset())
            if(minSize == null||csmMap.get(key) < csmMap.get(minSize))
            minSize=key;
        system.debug('==getCSMWithLeastAmount==minSize====== '+ minSize);
        return minSize;
    }
    
    global void finish(Database.BatchableContext BC) {
        System.debug('emailBody'+emailBody);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> listOfAddresses = new List<String>();
        listOfAddresses.addAll(System.Label.BatchCreateCSMRREmails.split(';'));
        mail.setToAddresses(listOfAddresses);
        mail.setSubject('CSM RR Batch Status');
        String body = emailBody;
        mail.setHtmlBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
    }
    
    global void execute(SchedulableContext sc)
    {
        BatchCSMRRAssignment b = new BatchCSMRRAssignment();
        database.executebatch(b,200);
    }
}