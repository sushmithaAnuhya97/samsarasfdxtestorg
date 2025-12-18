/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 22, 2021
*
* @description : This class will be responsible to Rollup Contact Fields on Account
* SFA-22
*
* @author Groundswell - Vikasm - vikas@gscloudsolutions.com
* @date 2020-09-08
* Not yet deployed for Production
* GTMS-1471
*/

public class GS_ContactRollupsToAccount implements Callable{
    public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();
    public List<Contact> contactList;
    public Map<Id, Contact> OldContactMap;
    public Map<Id,Account> accountUpdates = new Map<Id,Account>();
    
    public Map<String,Rollup_Switch__mdt> mapOFRollupFieldVsMetadata = new Map<String,Rollup_Switch__mdt> ();
    public Set<String> targetRollupAccountSet = new Set<String> ();
    public List<Contact> targetContacts = new List<Contact>();
    
    public GS_ContactRollupsToAccount(){}
    public GS_ContactRollupsToAccount(List<Contact> contactList, Map<Id, Contact> OldContactMap){
        this.contactList = contactList;
        this.OldContactMap = OldContactMap;
        mapOFRollupFieldVsMetadata = RollUpSwitchService.getRollupSwitchMetadata('Account', 'Contact');
        loadContactTargetRollupAccountSet(contactList, OldContactMap);
        loadTargetContacts();
    }
    
    

/**
* @author Groundswell - Vikasm - vikas@gscloudsolutions.com
* @date 2020-09-09
* GTMS-1471 
*/
    public void calculateRollUpsToAccount() {
        calculateAllRollUpsToAccount();
        updateAccounts();
    }
    
    
    public void updateAccounts() {
        if (!accountUpdates.isEmpty()) {
            thisSamsaraLoggerService.logger.logInfo('Roll up to Account ::',accountUpdates.values());
            List<Account> accounts = new List<Account>();
            accounts.addAll(accountUpdates.values());
            accountUpdates.clear();
            //update accounts;
            DMLWrapper.doUpdate(accounts);
        }
    }
    

    private void calculateAllRollUpsToAccount()
    {
        Map<string, Map<String,List<Contact>>> mapOfRollupFiledVsRecordList = new   Map<string, Map<String,List<Contact>>> ();

        Map<String,List<Contact>> mapOfAccountIdVsContactList = new Map<String,List<Contact>>();

        for(String accountId : targetRollupAccountSet)
        {
            if(! mapOfAccountIdVsContactList.ContainsKey(accountId)) mapOfAccountIdVsContactList.put(accountId, new List<Contact>());

        }
        for (String rollUpField : mapOFRollupFieldVsMetadata.KeySet())
        {

            if(!mapOfRollupFiledVsRecordList.containsKey(rollUpField))
                mapOfRollupFiledVsRecordList.put(rollUpField, mapOfAccountIdVsContactList);
        }

        for(integer i = 0 ; i < targetContacts.size() ; i++ )
        {
            for(String rollUpField : mapOFRollupFieldVsMetadata.KeySet())
            {
                Callable callInstance = (Callable)Type.forName('GS_ContactRollupsToAccount').newInstance();


                if((Boolean)callInstance.call(rollUpField, new map<String,Object>{'newRecord' => targetContacts[i]}))
                {
                    if(! mapOfRollupFiledVsRecordList.ContainsKey(rollUpField)) mapOfRollupFiledVsRecordList.put(rollUpField, new Map<String,List<Contact>>());

                    if(!mapOfRollupFiledVsRecordList.get(rollUpField).containsKey(targetContacts[i].AccountId))
                        mapOfRollupFiledVsRecordList.get(rollUpField).put(targetContacts[i].AccountId, new List<Contact>());

                    mapOfRollupFiledVsRecordList.get(rollUpField).get(targetContacts[i].AccountId).add(targetContacts[i]);

                }
            }

        }

        for (String rollupField : mapOfRollupFiledVsRecordList.keySet()) {
            if (!mapOfRollupFiledVsRecordList.containsKey(rollupField)) {
                continue;
            }
            for(String accountId : mapOfRollupFiledVsRecordList.get(rollupField).keySet())
            {
                if(!accountUpdates.ContainsKey(accountId))
                {
                    accountUpdates.put(accountId, new Account(Id = accountId));
                }

                if (mapOfRollupFiledVsRecordList.get(rollupField).get(accountId).isEmpty()) {
                    accountUpdates.get(accountId).put(rollupField, null);
                    continue;
                }

                //Todo handling the count first last and average using Callable
                Callable callInstance = (Callable) Type.forName('GS_ContactRollupsToAccount').newInstance();
                if (mapOFRollupFieldVsMetadata.get(rollupField).Type__c == 'SUM') {
                    object result = callInstance.call('SUM', new map<String, Object>{
                            'recordList' => mapOfRollupFiledVsRecordList.get(rollupField).get(accountId), 'field' => mapOFRollupFieldVsMetadata.get(rollupField).Rollup_Field__c
                    });
                    if (result != null)
                        accountUpdates.get(accountId).put(rollupField, (Decimal) result);
                } /*else if (mapOFRollupFieldVsMetadata.get(rollupField).Type__c == 'FIRST') {
                    Contact firstContact = new Contact();
                    object result = callInstance.call('FIRST', new map<String, Object>{
                            'recordList' => mapOfRollupFiledVsRecordList.get(rollupField).get(accountId), 'field' => mapOFRollupFieldVsMetadata.get(rollupField).Rollup_Field__c
                    });
                    if (result == null) continue;
                    firstContact = (Contact) result;
                    if(firstContact == null ) continue;
                    accountUpdates.get(accountId).put(rollupField, firstContact.Id);
                }*/ else if (mapOFRollupFieldVsMetadata.get(rollupField).Type__c == 'LAST') {
                    Contact lastContact = new Contact();
                    object result = callInstance.call('LAST', new map<String, Object>{
                            'recordList' => mapOfRollupFiledVsRecordList.get(rollupField).get(accountId), 'field' => mapOFRollupFieldVsMetadata.get(rollupField).Rollup_Field__c
                    });
                    if (result == null) continue;
                    lastContact = (Contact) result;
                    if (lastContact == null) continue;
                    if (rollupField == 'Last_Call__c') {
                        accountUpdates.get(accountId).put(rollupField, lastContact.Last_Call__c);
                        continue;
                    }
                    if (rollupField == 'Last_Marketing_Engagement_Date__c') {
                        accountUpdates.get(accountId).put(rollupField, lastContact.Last_Marketing_Engagement_Date__c);
                        continue;
                    }
                    accountUpdates.get(accountId).put(rollupField, lastContact.Id);
                }
            }
        }


    }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-09-09
    * Not yet deployed for Production
    * GTMS-1471
    */
    public  void loadContactTargetRollupAccountSet(List<Contact> contactList, Map<Id,Contact> OldContactMap)
    {
        if(OldContactMap == null)
        {
            Callable callInstance = (Callable)Type.forName('GS_ContactRollupsToAccount').newInstance();
            for(integer i = 0 ; i < contactList.size() ; i++) {

                for (String rollUpField : mapOFRollupFieldVsMetadata.KeySet()) {
                    Object result = callInstance.call(rollUpField, new map<String, Object>{
                            'newRecord' => contactList[i]
                    });
                    if (result == null) continue;
                    if ((Boolean) result) {
                        if (contactList[i].AccountId != null)
                            targetRollupAccountSet.add(contactList[i].AccountId);
                        break;
                    }
                }
            }
        }
        else
        {
            for(integer i = 0 ; i < contactList.size() ; i++)
            {
                
                for(String rollUpField : mapOFRollupFieldVsMetadata.KeySet())
                {
                    if(accountReparenting(contactList[i], OldContactMap.get(contactList[i].id)))
                    {
                        if(OldContactMap.get(contactList[i].id).AccountId != null)
                        targetRollupAccountSet.add(OldContactMap.get(contactList[i].id).AccountId);
                        if(contactList[i].AccountId != null)
                        targetRollupAccountSet.add(contactList[i].AccountId);
                    }
                    else {
                        Callable callInstance = (Callable) Type.forName('GS_ContactRollupsToAccount').newInstance();

                        object result = callInstance.call(rollUpField + 'PreCheck', new map<String, Object>{
                                'newRecord' => contactList[i], 'oldRecord' => OldContactMap.get(contactList[i].id)
                        });
                        if (result == null) continue;

                        if ((Boolean) result) {
                            if (contactList[i].AccountId != null)
                            targetRollupAccountSet.add(contactList[i].AccountId);
                            break;
                        }
                    }
                    
                }
            }

        }
    }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-09-09
    * Not yet deployed for Production
    * GTMS-1471
    */
    public Object call(String action, Map<String, Object> args)
    {
        switch on action {
            when 'Active_Growth_Campaigns_on_Account__c' {
                return this.rollup_Active_Growth_Campaigns_CountCondition((Contact) args.get('newRecord'));
            }
            when 'Last_Call__c' {
                return this.Last_CallCondition((Contact) args.get('newRecord'));
            }
            when 'Last_Marketing_Engagement_Date__c' {
                return this.Last_Marketing_Engagement_DateCondition((Contact) args.get('newRecord'));
            }
            when 'Active_Growth_Campaigns_on_Account__cPreCheck' {
                return this.rollup_Active_Growth_Campaigns_CountPreCheck((Contact) args.get('newRecord'), (Contact) args.get('oldRecord'));
            }
            when 'Last_Call__cPreCheck' {
                return this.Last_CallPreCheck((Contact) args.get('newRecord'), (Contact) args.get('oldRecord'));
            }
            when 'Last_Marketing_Engagement_Date__cPreCheck' {
                return this.Last_Marketing_Engagement_DatePreCheck((Contact) args.get('newRecord'), (Contact) args.get('oldRecord'));
            }
            when 'SUM' {
                return this.Sum((List<Sobject>) args.get('recordList'), (String) args.get('field'));
            }
            when 'LAST' {
                return this.last((List<Sobject>) args.get('recordList'), (String) args.get('field'));
            }
            /* when 'FIRST'
            {
                return this.first((List<Sobject>)args.get('recordList'), (String)args.get('field'));
            } */
          when else
          {
           System.debug('Method not implemented');
           return null;
          }
        }
    }
    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-09-09
    * Not yet deployed for Production
    * GTMS-1471
    */
    public Boolean rollup_Active_Growth_Campaigns_CountPreCheck (Contact thisContact, Contact oldContact) {
        return (thisContact.Active_Growth_Campaigns_Count__c != oldContact.Active_Growth_Campaigns_Count__c
                && (rollup_Active_Growth_Campaigns_CountCondition(thisContact) || rollup_Active_Growth_Campaigns_CountCondition(oldContact)));
    }

    public boolean Last_CallPreCheck(Contact thisContact, Contact oldContact) {
        return (thisContact.Last_Call__c != oldContact.Last_Call__c) && (Last_CallCondition(thisContact) || Last_CallCondition(oldContact));
    }

    public Boolean Last_Marketing_Engagement_DatePreCheck(Contact thisContact, Contact oldContact) {
        return (thisContact.Last_Marketing_Engagement_Date__c != oldContact.Last_Marketing_Engagement_Date__c)
                && (Last_Marketing_Engagement_DateCondition(thisContact) || Last_Marketing_Engagement_DateCondition(oldContact));
    }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-09-09
    * Not yet deployed for Production
    * GTMS-1471
    */
    public Boolean rollup_Active_Growth_Campaigns_CountCondition(Contact thisContact) {
        return (thisContact.Active_Growth_Campaigns_Count__c > 0);
    }

    public boolean Last_CallCondition(Contact thisContact) {
        return thisContact.Last_Call__c != null;
    }

    public Boolean Last_Marketing_Engagement_DateCondition(Contact thisContact) {
        return thisContact.Last_Marketing_Engagement_Date__c != null;
    }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-09-09
    * Not yet deployed for Production
    * GTMS-1471
    */
    public void loadTargetContacts() {
        targetContacts = [
                SELECT Id, AccountId,
                        Active_Growth_Campaigns_Count__c,
                        Last_Call__c,Last_Marketing_Engagement_Date__c
                            FROM Contact
                            WHERE AccountId IN :targetRollupAccountSet];
    }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-09-09
    * Not yet deployed for Production
    * GTMS-1471
    */
    private Boolean accountReparenting (Contact thisRecord, Contact oldrecord)
    {
        return (thisRecord.AccountId != oldrecord.AccountId);
    }
    
    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-09-09
    * Not yet deployed for Production
    * GTMS-1471
    */
    private Decimal Sum (List<Sobject>recordList, String field)
    {
    return RollupService.Sum(recordList, field);
    }
    
    /* private Sobject first (List<Sobject>recordList, String field)
    {
        return RollupService.first(recordList, field);
    } */

    private Sobject last (List<Sobject>recordList, String field)
    {
        return RollupService.last(recordList, field);
    }
    
    
}