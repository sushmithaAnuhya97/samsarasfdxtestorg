/**********************************************************************
Name: NewDealRegLeadOwnerHandler
=======================================================================
Purpose: This class will contain methods that handles Free Trial Decision logic                                                        
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2023-May-15        INITIAL DEVELOPMENT FOR GTMS-11208
1.1        Rodrigo Carpio        2023-Aug-18        contact update logic
1.2        Rodrigo Carpio        2024-Jul-10        UATPILOT-91 -> added logic related to ownerValidationInput->accountId, assignAEAccountOwner 
***********************************************************************/
public class NewDealRegLeadOwnerHandler {
    public class ownerValidationInput { // UATPILOT-91
        @InvocableVariable public string opportunityId;
        @InvocableVariable public string accountId;
    }
    
	@InvocableMethod(label='Validate Assigned Owner') 
    public static void validateAssignedOwner(List<ownerValidationInput> validationInput) {
        Set<string> optyIdList = new Set<string>();
        Set<string> acctIdList = new Set<string>();//UATPILOT-91
        FOR(ownerValidationInput input: validationInput) {
            if(input.opportunityId != null)
                optyIdList.add(input.opportunityId);
            if(input.accountId != null)
                acctIdList.add(input.accountId);
        }
        if (optyIdList.size()>0) {
            String opportunityIdSerialized = JSON.serialize(optyIdList);
            validateAssignedOwnerFuture(opportunityIdSerialized);
        }
        if (acctIdList.size()>0) {//UATPILOT-91
            assignAEAccountOwner(acctIdList);
        }
    }
    
    /* this method handles the logic update the account owner if user is an ADR with Account Book AE UATPILOT-91*/
    private static void assignAEAccountOwner(Set<string> acctIdListIn) {
        List<Account> forUpdateAccount = new List<Account>();
        List<Account> oAccountList = [SELECT Id, Books_Of_Business__r.AE__c FROM Account WHERE Id IN: acctIdListIn];
        FOR(Account oAccount : oAccountList) {
            if (oAccount.Books_Of_Business__r.AE__c != null) {
                Account local = new Account();
                local.Id = oAccount.Id;
                local.OwnerId = oAccount.Books_Of_Business__r.AE__c;
                local.Overwrite_Validation_Rule__c = true;
                
                forUpdateAccount.add(local);
            }
        }
        if (forUpdateAccount.size() > 0) {
            TriggerHandler.bypass('GS_AccountTriggerHandler');
            update forUpdateAccount;
        }
        
    }
    
    //@future
    public static void validateAssignedOwnerFuture(string opportunityIdSerializedIn) {
        List<string> opportunityId = (List<string>) JSON.deserialize(opportunityIdSerializedIn, List<string>.class);
        List<Opportunity> forUpdateOppty = new List<Opportunity>();
        List<Account> forUpdateAccount = new List<Account>();
        List<Account> forAssignAccount = new List<Account>();
        List<Opportunity> listOfOppty = [SELECT Id, AccountId, Account.Owner.UserRole.Name, Account.Books_Of_Business__r.AE__c FROM Opportunity 
                                         WHERE Id IN: opportunityId];
        Map<Id, String> ownerMapStr = new Map<Id, String>();
        Map<Id, String> opptyMapStr = new Map<Id, String>();
        Set<String> userNameSet = new Set<string>();
		Map<Id, Id> opptyAccountIdMap = new Map<Id, Id>();
        FOR (Opportunity rec : listOfOppty) {
            opptyAccountIdMap.put(rec.Id, rec.AccountId);
            string strRole = rec.Account.Owner.UserRole.Name;
            //GTMS-25319 start - Manjusha Jammula
            if(rec.Account.Books_Of_Business__r.AE__c != null){
                ownerMapStr.put(rec.AccountId, rec.Account.Books_Of_Business__r.AE__c);
                opptyMapStr.put(rec.Id, rec.Account.Books_Of_Business__r.AE__c);
                userNameSet.add(rec.Account.Books_Of_Business__r.AE__c);
            }
            //GTMS-25319 end
            //if (strRole != null && strRole.contains('ADR')) {
                /*if (rec.Account.Enterprise_Assignment__c != null) {
                    ownerMapStr.put(rec.AccountId, rec.Account.Enterprise_Assignment__c);
                    opptyMapStr.put(rec.Id, rec.Account.Enterprise_Assignment__c);
                    userNameSet.add(rec.Account.Enterprise_Assignment__c);
                }
                else if (rec.Account.Inside_Sales_Assignment__c != null) {
                    ownerMapStr.put(rec.AccountId, rec.Account.Inside_Sales_Assignment__c);
                    opptyMapStr.put(rec.Id, rec.Account.Inside_Sales_Assignment__c);
                    userNameSet.add(rec.Account.Inside_Sales_Assignment__c);
                }*/
                /*else {
                    Account local0 = new Account();
            		local0.Id = rec.AccountId;
                    local0.LFBN__Assign_Account__c = true;
                    forAssignAccount.add(local0);
                }*/
            //}
            
        }
        
        
        /*
        //system.debug('userNameSet ' + userNameSet);
        List<user> listUser = new List<User>();
        listUser = [SELECT Id, Name from User WHERE Name IN: userNameSet];
        //system.debug('listUser ' + listUser);
        Map<string, Id> userMapStr = new Map<string, id>();
        
        // assign user details in maps
        FOR (User rec2 : listUser) {
            userMapStr.put(rec2.name, rec2.id);
        }
        */
        
        // read account owner map
        for (Id mapKey : ownerMapStr.keySet()) {
            //string mapValue = ownerMapStr.get(mapKey);
            //system.debug('mapValue ' + mapValue);
            //system.debug('userMapStr ' + userMapStr.get(mapValue));
            Account local = new Account();
            local.Id = mapKey;
            local.OwnerId = ownerMapStr.get(mapKey);
            local.Overwrite_Validation_Rule__c = true;
            //local.Is_Deal_Reg_Account__c = false;
            forUpdateAccount.add(local);
        }
        
        Map<Id, Id> accountOwnerMap = new Map<Id, Id>();
        // read opportunity owner map
        for (Id mapKey2 : opptyMapStr.keySet()) {
            //string mapValue2 = opptyMapStr.get(mapKey2);
            //system.debug('mapValue2 ' + mapValue2);
            //system.debug('userMapStr2 ' + userMapStr.get(mapValue2));
            Opportunity local2 = new Opportunity();
            local2.Id = mapKey2;
            local2.OwnerId = opptyMapStr.get(mapKey2);
            forUpdateOppty.add(local2);
            accountOwnerMap.put(opptyAccountIdMap.get(local2.Id), local2.OwnerId);
            //system.debug('accountOwnerMap ' + accountOwnerMap);
        }
        
        List<Contact> forUpdateContact = new List<Contact>();
        
        for(Contact myRec : [SELECT Id, AccountId, OwnerId FROM Contact WHERE AccountId IN: ownerMapStr.keySet()]){
            //system.debug('myRec.AccountId ' + myRec.AccountId);
            myRec.OwnerId = accountOwnerMap.get(myRec.AccountId);
            //system.debug('myRec.OwnerId ' + myRec.OwnerId);
            forUpdateContact.add(myRec);
        }
        
        if(forUpdateContact != null && forUpdateContact.size()>0) {
            TriggerHandler.bypass('ContactTriggerHandler');
            update forUpdateContact;
        }
        
        if (forUpdateOppty != null && forUpdateOppty.size()>0) {
            TriggerHandler.bypass('OpportunityTriggerHandlerContext');
            update forUpdateOppty;
            //system.debug('forUpdateOppty ' + forUpdateOppty);
        }
        
        if (forUpdateAccount != null && forUpdateAccount.size()>0) {
            TriggerHandler.bypass('GS_AccountTriggerHandler');
            update forUpdateAccount;
            //system.debug('forUpdateAccount ' + forUpdateAccount);
        }
        
        /*if (forAssignAccount != null && forAssignAccount.size()>0) {
            TriggerHandler.bypass('GS_AccountTriggerHandler');
            update forAssignAccount;
        }*/
        
        
        
        //sendMail();
    }
    
    /*public static void sendMail(){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        string[] to = new string[] {'rodrigo.carpio@samsara.com'};
        
        email.setToAddresses(to);
        
        email.setSubject('Test Mail');
        
        email.setHtmlBody('Hello, <br/><br/>This is the test mail that you generated. <br/>The Email Id for which this mail was generated by '
                          +'rodrigo.carpio@samsara.com'+'<br/><br/>Regards<br/> Developer');
        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }catch(exception e){
            apexpages.addmessage(new apexpages.message(apexpages.severity.error,e.getMessage()));
        }
       
    }*/
}