public class LeadHelper {
    static Map<Id, Account> accountUpdates = new Map<Id, Account>();
    static Map<Id, Account> staticAccountsMap = new Map<Id, Account>();
    static Boolean loadedStaticAccounts = false;

    public static Id channelrt = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Channel Registration').getRecordTypeId();
    public static Id industrialAcctrt = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Industrial').getRecordTypeId();

    public static void loadStaticAccountsMap(Set<Id> accountIds) {
        if(!loadedStaticAccounts && accountIds.size() > 0) {
            staticAccountsMap = new Map<Id, Account>([  SELECT  Id,
                                                                Industry,
                                                                Owner.Name, 
                                                                Most_Recent_Source__c,
                                                                Owner_Role__c, 
                                                                Initiate_Round_Robin__c,
                                                                Is_Owner_Pool_User__c, 
                                                                Hashtag__c 
                                                        FROM Account 
                                                        WHERE Id IN :accountIds]);
            loadedStaticAccounts = true;
        }
    }

    public static void beforeInsertOnly(List<Lead> newLeadList) {
        Set<Id> leadOwnerIdSet = new Set<Id>();
        for(Lead l : newLeadList) {
            leadOwnerIdSet.add(l.OwnerId);
        }
        // Query owner roles
        Map<Id, User> ownerMap = new Map<Id, User>([SELECT Id, UserRole.Name, UserRole.PortalType FROM User WHERE Id IN: leadOwnerIdSet]);
        Map<String, Id> poolMap = new Map<String, Id>();
        for(Business_Unit_User__mdt userMapping : [SELECT Id, MasterLabel, User_Id__c FROM Business_Unit_User__mdt]) {
            poolMap.put(userMapping.MasterLabel, userMapping.User_Id__c);
        }

        //Deprecated Consolidated Lead Processes Builder Node: (Business Unit) - rsaavedra 
        for(Lead l : newLeadList) {
            if(ownerMap.get(l.OwnerId).UserRole.Name == 'Management' || (Test.isRunningTest() && ownerMap.get(l.OwnerId).UserRole.PortalType != 'Partner')) {
                if(poolMap.containsKey(l.Business_Unit__c)){
                    l.OwnerId = poolMap.get(l.Business_Unit__c);
                }
            }

            if(l.RecordTypeId == channelrt){
                l.Channel_Source__c = true;
            }

            if(l.Experimental_Group__c){
                l.Experimental_Group_Routing__c = 'True';
            }
            else{
                l.Experimental_Group_Routing__c = 'False';
            }
			//GTMS-3838 replacing BU value as Fleet from Connected Worker
            if(l.Product_Interest_Type__c == 'Onsite Security Cameras'){
                l.Business_Unit__c = 'Fleet';
                l.Campaign_to_Add__c = System.Label.SITES_Campaign_Id;
            }
        }
    }
    //Deprecated Consolidated Lead Processes Builder Node: (Description Changes or IsNew) - rsaavedra
    public static void beforeInsertandUpdate(Map<Id, Lead> oldLeadMap, List<Lead> newLeadList){

        Id ChannelReg_RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Channel Registration').getRecordTypeId();

 
        for(Lead ll :newLeadList){

            if(ll.Business_Unit__c == NULL){
                ll.Business_Unit__c = 'Fleet';
            }

            if(ll.Channel_Payment_Method_V2__c == 'Deal Registration Margin'){
                ll.CAE_Routing__c = true;
            }
            
            if(ll.Description != NULL){
                ll.Description_for_Conversion__c = ll.Description;
            }
            
            List<String> programTypeList = new List<String>();
            if(ll.Program_Type__c != NULL && ll.RecordTypeId == ChannelReg_RecordTypeId){
                programTypeList.addAll(ll.Program_Type__c.split(';'));
                if(programTypeList.size() > 1){
                    ll.addError('You can select only one program type on a deal registration');
                }
            }
        }
    }


    //method is assuming that we remain on the Account based model and updates the Most Recent source on both update & insert
    public static void leadToAccount(Map<Id, Lead> oldLeadMap, List<Lead> newLeadList, Boolean isUpdate){

        Set<Id> acctIds = new Set<Id>(); 
        Map<Id, Account> accts = new Map<Id, Account>();

        for(Lead l: newLeadList){
            if(l.RR_Duplicate_Account__c != NULL){
                acctIds.add(l.RR_Duplicate_Account__c);
            }
        }

        loadStaticAccountsMap(acctIds);

        for(Lead lead: newLeadList){
            if(lead.RR_Duplicate_Account__c != null && (isUpdate && lead.Channel_Source__c || !isUpdate && !lead.Channel_Source__c)){
                if(staticAccountsMap.containsKey(lead.RR_Duplicate_Account__c)){
                    Account account = accountUpdates.get(lead.RR_Duplicate_Account__c);

                    if(accountUpdates.containsKey(lead.RR_Duplicate_Account__c)){
                        account.Most_Recent_Source__c = lead.LeadSource;
                        account.Experimental_Group_Routing__c = lead.Experimental_Group_Routing__c;
                        accountUpdates.put(account.Id, account);
                    } 
                    else{
                        accountUpdates.put(lead.RR_Duplicate_Account__c, new Account(Id = lead.RR_Duplicate_Account__c,
                                                                                        Most_Recent_Source__c = lead.LeadSource,
                                                                                        Experimental_Group_Routing__c = lead.Experimental_Group_Routing__c));
                    }
                }
            }
        }
        // Update called in the trigger handler.
    }

    //Deprecated Consolidated Lead Processes Builder Node: (Matched Account Hashtag) - rsaavedra 
    public static void acctHashtag(Map<Id, Lead> oldLeadMap, List<Lead> newLeadList){
        Set<Id> acctIds = new Set<Id>(); 

        for(Lead l: newLeadList){
            if(l.RR_Duplicate_Account__c != NULL){
                acctIds.add(l.RR_Duplicate_Account__c);
            }
        }

        loadStaticAccountsMap(acctIds);    
        if(acctIds.size() > 0 ){
            for(Lead ll :newLeadList){

                Lead oldLead = new Lead();

                //evaluate if the duplicate has changed
                if (oldLeadMap != NULL){
                    oldLead = oldLeadMap.get(ll.Id);
                }

                //protect from null pointer error if matched account field hasn't been populated
                if(ll.RR_Duplicate_Account__c != NULL){
                    if(ll.RR_Duplicate_Account__c != oldLead.RR_Duplicate_Account__c){
                        if(staticAccountsMap.containsKey(ll.RR_Duplicate_Account__c)){
                            Account a = staticAccountsMap.get(ll.RR_Duplicate_Account__c);
                            if(ll.Hashtag__c != NULL){
                            //protect from NULL hashtag on the matched Account
                                if(a.Hashtag__c != NULL){
                                    if(!a.Hashtag__c.contains(ll.Hashtag__c)){
                                        //protect from duplicate ids in list
                                        if(accountUpdates.containsKey(ll.RR_Duplicate_Account__c)){
                                            accountUpdates.get(ll.RR_Duplicate_Account__c).Hashtag__c = ll.Hashtag__c+' '+a.Hashtag__c;
                                        } 
                                        else{
                                            accountUpdates.put(a.Id, new Account(Id = a.Id, Hashtag__c = ll.Hashtag__c+' '+a.Hashtag__c));
                                        }
                                    }
                                }
                                else{
                                    //protect from duplicate ids in list
                                    if(accountUpdates.containsKey(ll.RR_Duplicate_Account__c)){
                                        accountUpdates.get(ll.RR_Duplicate_Account__c).Hashtag__c = ll.Hashtag__c;
                                    } 
                                    else{
                                        accountUpdates.put(a.Id, new Account(Id = a.Id, Hashtag__c = ll.Hashtag__c));
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Update called in the trigger handler.
    }

    public static void updateAccounts() {
        if (accountUpdates.size() > 0) {
            //update accountUpdates.values();
            DMLWrapper.doUpdate(accountUpdates.values());
        }
    }
}