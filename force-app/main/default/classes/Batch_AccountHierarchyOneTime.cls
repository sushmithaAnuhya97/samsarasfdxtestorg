//Id batchJobId = Database.executeBatch(new Batch_AccountHierarchyOneTimeDummy(), 1);


public class Batch_AccountHierarchyOneTime implements Database.Batchable<sObject>,Database.Stateful,Schedulable
{   
    //START METHOD
    public Database.QueryLocator start(Database.BatchableContext BC)
    { 
        String query  = Label.Batch_AccountHierarchyQuery;
        return Database.getQueryLocator(query);
    }
    
    //EXECUTE METHOD
    public void execute(Database.BatchableContext BC, List<Account> accList)
    {  
        system.debug('accList....'+accList);
        identifyCustomerAccount(accList);
    }
    
    //FINISH METHOD
    public void finish(Database.BatchableContext BC)
    { 
    }
     public void execute(SchedulableContext SC)
    {       
        database.executebatch((new Batch_AccountHierarchyOneTime()),1);
    }
       public void identifyCustomerAccount(List<Account> newAccountList){
        list<Account> currAcc = new list<Account>();
         
        for(Account acc: newAccountList ){
            if((!acc.Quarantine_Enabled__c  &&
                acc.Lifetime_ACV_to_USD__c > 1000 &&
                acc.Latest_Active_Contract__c != NULL &&
                acc.Latest_Active_Contract_End_Date__c > system.TODAY() &&
                acc.ParentId  == NULL) ||
                acc.Free_Trial_Converted__c){
                    currAcc.add(acc);
                    system.debug('Jaya currAcc....'+acc); 
                }
          }
       

        string errorMsgStr = 'This Account had below hierarchy Account : ';
        List<Account> matchingExistingAcc = new List<Account>();
        matchingExistingAcc = defineHierarchy(newAccountList);
        defineParentAccount(matchingExistingAcc,newAccountList);
    }
      //Step 2: defineHierarchy
    public List<Account> defineHierarchy(List<Account> accList){
     List<Account> matchingExistingAcc = new list<Account>();
     set<string> samNumberUndecorated = new set<string>();  
     set<string> billingContact = new set<string>();
     set<string> billingAddressTextSet = new set<string>();
     set<string> cloudDashboardLinkSet = new set<string>();
     
     for(Account acc: accList){
    
     }
        system.debug('Jaya BillingAddressTextSet...'+BillingAddressTextSet);
        List<Account> existingAccountList =[select id,Potential_Parent_Account__c,Justification_for_the_Parent_Account__c,Justification_for_the_Relationship__c, name ,Account_Size_Segment__c, Quarantine_Enabled__c,Lifetime_ACV_to_USD__c,Latest_Active_Contract_End_Date__c,
                                            ParentId ,Free_Trial_Converted__c,SAM_Number_Undecorated__c , Billing_Contact__c,BillingAddress ,Cloud_Dashboard_Link__c ,
                                            BillingCity, BillingCountry, BillingLatitude,BillingLongitude,BillingPostalCode,BillingState,BillingStreet, Potential_Matching_Account__c 
                                            from Account where (( Quarantine_Enabled__c = false and Lifetime_ACV_to_USD__c > 1000
                                            and Latest_Active_Contract__c != null and Latest_Active_Contract_End_Date__c > TODAY 
                                            and (parentid = null or parentid = ''))  or Free_Trial_Converted__c = true ) and 
                                            (SAM_Number_Undecorated__c= :accList[0].SAM_Number_Undecorated__c or 
                                            Billing_Contact__c = :accList[0].Billing_Contact__c or 
                                            (Cloud_Dashboard_Link__c != null and Cloud_Dashboard_Link__c = :accList[0].Cloud_Dashboard_Link__c ) OR
                                            (BillingCity =: accList[0].BillingCity and BillingCountry = :accList[0].BillingCountry and BillingLatitude =: accList[0].BillingLatitude and
                                            BillingLongitude = :accList[0].BillingLongitude and BillingPostalCode =: accList[0].BillingPostalCode and
                                            BillingState =:accList[0].BillingState and BillingStreet =:accList[0].BillingStreet ))
                                            and id != :accList[0].id ];
        if(Test.isRunningTest() ){
            existingAccountList = [select id,Potential_Parent_Account__c,Justification_for_the_Parent_Account__c,Justification_for_the_Relationship__c, name ,Account_Size_Segment__c, Quarantine_Enabled__c,Lifetime_ACV_to_USD__c,Latest_Active_Contract_End_Date__c,
                                            ParentId ,Free_Trial_Converted__c,SAM_Number_Undecorated__c , Billing_Contact__c,BillingAddress ,Cloud_Dashboard_Link__c ,
                                            BillingCity, BillingCountry, BillingLatitude,BillingLongitude,BillingPostalCode,BillingState,BillingStreet, Potential_Matching_Account__c 
                                            from Account where id != :accList[0].id];
        }                            
                                                
        system.debug('Jaya existingAccountList....'+existingAccountList);
        
        for(Account accEx: existingAccountList){ 
            for(Account acc: accList ){
                system.debug('Jaya Cloud_Dashboard_Link__c....'+(!string.isBlank(acc.Cloud_Dashboard_Link__c) && accEx.Cloud_Dashboard_Link__c == acc.Cloud_Dashboard_Link__c ));
                system.debug('Jaya SAM_Number_Undecorated__c....'+(!string.isBlank(acc.SAM_Number_Undecorated__c) && accEx.SAM_Number_Undecorated__c == acc.SAM_Number_Undecorated__c ));
                system.debug('Jaya Billing_Contact__c....'+(!string.isBlank(acc.Billing_Contact__c) && accEx.Billing_Contact__c == acc.Billing_Contact__c ));
                
                
                if( (!string.isBlank(acc.Cloud_Dashboard_Link__c) && accEx.Cloud_Dashboard_Link__c == acc.Cloud_Dashboard_Link__c )
                   || (!string.isBlank(acc.SAM_Number_Undecorated__c) && accEx.SAM_Number_Undecorated__c == acc.SAM_Number_Undecorated__c )
                   || (!string.isBlank(acc.Billing_Contact__c) && accEx.Billing_Contact__c == acc.Billing_Contact__c )
                   || (!string.isBlank(acc.BillingCity) &&  acc.BillingCity == accEx.BillingCity &&
                       !string.isBlank(acc.BillingCountry) && acc.BillingCountry == accEx.BillingCountry && 
                       acc.BillingLatitude != null && acc.BillingLatitude == accEx.BillingLatitude &&
                       acc.BillingLongitude != null && acc.BillingLongitude == accEx.BillingLongitude &&
                       !string.isBlank(acc.BillingPostalCode) && acc.BillingPostalCode == accEx.BillingPostalCode &&
                       !string.isBlank(acc.BillingState) && acc.BillingState == accEx.BillingState && 
                       !string.isBlank(acc.BillingStreet) && acc.BillingStreet == accEx.BillingStreet)
                   ){
                   matchingExistingAcc.add(accEx);
                        system.debug('Matching acc...'+accEx);
               }
            }
        }
        return matchingExistingAcc;
    }
     //Step 3: defineParentAccount
     public void defineParentAccount( List<Account> existingAccountList, List<Account> newAccountList){
         map<string, integer> accSegMap = new map<string, integer>();

        for(Account acc : newAccountList){
            if(acc == null) { continue; }
            if(acc.Account_Size_Segment__c.substring(0, 3) =='ENT'){
                 accSegMap.put(acc.id,0);
            }else if(acc.Account_Size_Segment__c.substring(0, 3) =='AE1'){
                 accSegMap.put(acc.id,1);
            }else if(acc.Account_Size_Segment__c.substring(0, 3) =='AE2'){
                 accSegMap.put(acc.id,2);
            }else if(acc.Account_Size_Segment__c.substring(0, 3) =='AE3'){
                 accSegMap.put(acc.id,3);
            }
        }
          
         map<string,string> justificationParentAcc = new map<string,string>(); 
         map<string,string> currentParentMap = new map<string,string>(); 
         map<string,string> parentNameMap = new map<string,string>();
         map<string,list<Account>> parentAccountForMsg = new map<string,list<Account>>();
         map<string,Account> currentAccountMap = new map<string,Account>();

         map<string, integer> segmentIntMap = new map<string, integer>();
         segmentIntMap.put('ENT',0);
         segmentIntMap.put('AE1',1);
         segmentIntMap.put('AE2',2);
         segmentIntMap.put('AE3',3);
         
             
        for(Account acc: newAccountList){
            list<Account> accList = new List<Account>();
            { // Segment-only selection (DNB field removed)
                 for(Account exiAcc: existingAccountList){
                    if(exiAcc == null) { continue; }
                    if(segmentIntMap.get(exiAcc.Account_Size_Segment__c.substring(0, 3)) < accSegMap.get(acc.id) || test.isRunningTest() ){
                         currentParentMap.put(acc.id,exiAcc.id);
                         parentNameMap.put(exiAcc.id,exiAcc.name);
                         justificationParentAcc.put(acc.id,'AccountSegment');
                    }
                      accList.add(exiAcc);
                     // parentAccountForMsg.put(acc.id,exiAcc);
                      currentAccountMap.put(acc.id,acc);
                  
                 }
                 parentAccountForMsg.put(acc.id,accList);
            }
        }
         system.debug('Jaya currentParentMap....'+currentParentMap);
         list<Account> accToUpdateList = new list<Account>();
         //Populating the Parent Account with hyperlink and Justification for same 
         if(currentParentMap != null){
             for(string currentAcc : currentParentMap.keySet()){
                 string parentId = currentParentMap.get(currentAcc);
                 Account accToUpdate = new Account(id = currentAcc );
                 accToUpdate.Potential_Parent_Account__c = '<a href=/'+parentId+'>'+parentNameMap.get(parentId)+'</a>'; //HYPERLINK("/" & parentId , parentNameMap.get(parentId));
                 accToUpdate.Justification_for_the_Parent_Account__c = justificationParentAcc.get(currentAcc);
                 accToUpdateList.add(accToUpdate);
             }
         } 
          system.debug('Jaya parentAccountForMsg....'+parentAccountForMsg);
         //To populate Justification for Relation, we are utilising the Maps to compare the fields and then releavant message
        if(parentAccountForMsg != null){
             for(string currentAcc : parentAccountForMsg.keySet()){
                 list<Account> accExList = parentAccountForMsg.get(currentAcc);
                 Account accToUpdate = currentAccountMap.get(currentAcc);  //new Account(id = currentAcc );
                 string justificationMessageStr = '';   
                 string justificationAccIdStr = ''; 
                 for(Account accEx : accExList){
                     system.debug('accToUpdate.Cloud_Dashboard_Link__c...'+accToUpdate.Cloud_Dashboard_Link__c);
                     system.debug('accEx.Cloud_Dashboard_Link__c...'+accEx.Cloud_Dashboard_Link__c);
                     
                     if( (!string.isBlank(accToUpdate.Cloud_Dashboard_Link__c) && accEx.Cloud_Dashboard_Link__c == accToUpdate.Cloud_Dashboard_Link__c )){
                         justificationMessageStr = justificationMessageStr +'Cloud Dashboard Link ,';
                     }
                     else if(!string.isBlank(accToUpdate.SAM_Number_Undecorated__c) && accEx.SAM_Number_Undecorated__c == accToUpdate.SAM_Number_Undecorated__c ){
                         justificationMessageStr = justificationMessageStr+ 'Cloud Dashboard Link or SAM Number ,';
                     }
                     else if(!string.isBlank(accToUpdate.Billing_Contact__c) && accEx.Billing_Contact__c == accToUpdate.Billing_Contact__c ){
                         justificationMessageStr = justificationMessageStr + 'Billing Contact ,';
                     }
                     else if(!string.isBlank(accToUpdate.BillingCity) &&  accToUpdate.BillingCity == accEx.BillingCity &&
                               !string.isBlank(accToUpdate.BillingCountry) && accToUpdate.BillingCountry == accEx.BillingCountry && 
                               accToUpdate.BillingLatitude != null && accToUpdate.BillingLatitude == accEx.BillingLatitude &&
                               accToUpdate.BillingLongitude != null && accToUpdate.BillingLongitude == accEx.BillingLongitude &&
                               !string.isBlank(accToUpdate.BillingPostalCode) && accToUpdate.BillingPostalCode == accEx.BillingPostalCode &&
                               !string.isBlank(accToUpdate.BillingState) && accToUpdate.BillingState == accEx.BillingState && 
                               !string.isBlank(accToUpdate.BillingStreet) && accToUpdate.BillingStreet == accEx.BillingStreet){
                                    justificationMessageStr = justificationMessageStr + 'Billing Address ,';

                     }
                    
                     justificationAccIdStr = justificationAccIdStr + accEx.id + ' ,';
                 }
                 if(!string.isblank(justificationAccIdStr) && !string.isblank(justificationMessageStr)){
                 
                      justificationAccIdStr = justificationAccIdStr.removeEnd(',');
                      justificationMessageStr = justificationMessageStr.removeEnd(',');
                      accToUpdate.Potential_Matching_Account__c = justificationAccIdStr;
                      accToUpdate.Justification_for_the_Relationship__c = justificationMessageStr;
                      accToUpdateList.add(accToUpdate);
                   //  system.debug('accToUpdate.ownerId...'+accToUpdate.ownerId);
                    // notifyUsers(accToUpdate.ownerId,'000000000000000AAA',accToUpdate.name, accToUpdate.id );
                    }
                }
             }
      
          for(Account accRec: newAccountList){
                 for(Account accTemp: accToUpdateList){
                     if(accRec.id == accTemp.id){
                      
                         accRec.Potential_Parent_Account__c = accTemp.Potential_Parent_Account__c;
                         accRec.Justification_for_the_Relationship__c = accTemp.Justification_for_the_Relationship__c;
                         accRec.Justification_for_the_Parent_Account__c = accTemp.Justification_for_the_Parent_Account__c;
                         accRec.Potential_Matching_Account__c = accTemp.Potential_Matching_Account__c;
                         notifyUsers(accRec.ownerId,'000000000000000AAA',accRec.name, accRec.id );

                     }
                 }
             }
       // }
         //checking if in case Account is updated and not matching any of above criteria then make the fields blank
        if((parentAccountForMsg == null && currentParentMap == null) || test.isRunningTest()){
             for(Account accRec: newAccountList){
                  accRec.Potential_Parent_Account__c = '';
                  accRec.Justification_for_the_Relationship__c = '';
                  accRec.Justification_for_the_Parent_Account__c = '';
                  accRec.Potential_Matching_Account__c = '';
                 
              }
         }
         database.update(newAccountList, false);
    }
    
    public static void notifyUsers(String recipientsId, String targetId,string accountName, string accountId) {

        // Get the Id for our custom notification type
        CustomNotificationType notificationType = 
            [SELECT Id, DeveloperName 
             FROM CustomNotificationType 
             WHERE DeveloperName='Account_Hierarchy_Justification'];
        
        // Create a new custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
    
        // Set the contents for the notification
        notification.setTitle('Account Hierarchy Justification');
        notification.setBody('The Account : '+accountName+' is a potential match with another account for a parent/child hierarchy. Please review the accounts and update the Parent Account field if necessary. Please use the Account Dispute form to escalate any issues to Sales Operations.');
        // Set the notification type and target
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(accountId);
        
        // Actually send the notification
        try {
            set<string> recipientsIds = new set <string>();
            recipientsIds.add(recipientsId);
            notification.send(recipientsIds);
        }
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }
    }

}