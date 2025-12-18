/*
*    05/16/21 Satya (GTMS-3260) - DET/CET Tool Addresses are not automatically syncing
*  08/03/22 Raghav - (GTMS-6072) Consolidated multiple unmanaged trigger, workflow field updates and process builder into one
*/
public class ShippingAddressHelper {
    public static boolean accSyncEventPublished = false;
    static Map<id, Account_Sync_Event__e> accountSyncEvents2 = new Map<id, Account_Sync_Event__e>();
    public static boolean shippingAddressSynch = false;
    // GTMS-6072 - Process builder logic incorporated into this trigger
    public static void syncShippingAddress(List<Shipping_Address__c> newShippingaddress, Map<Id, Shipping_Address__c> mapOldShippingaddress) {
        for(Shipping_Address__c sa : newShippingaddress) {
            if(Trigger.isInsert || (!sa.Push_to_NetSuite__c && checkIfAddressChanged(sa, mapOldShippingaddress.get(sa.Id)))){
                
                if (!accountSyncEvents2.containsKey(sa.Account__c))
                accountSyncEvents2.put(sa.Account__c, new Account_Sync_event__e(Id__c = sa.Account__c));
                sa.Push_to_NetSuite__c = true;
            }
        }
        /*if(accountSyncEvents2.size() > 0){
        //if(accountSyncEvents2.size() > 0 && !accSyncEventPublished && !shippingAddressSynch){
            system.debug('===publish event====1 ' + accountSyncEvents2);
            
            List<Database.SaveResult> results = EventBus.publish(accountSyncEvents2.values());
                system.debug('===publish event====  2 ' + results);
            
            if (System.Label.Logging_for_PlatformEvent == '1' ) 
            {
                Api_Logger__c aplog = new Api_Logger__c();
                apLog.Opportunity_Name__c =  'Address createPlatformEvent';
                apLog.Quote_Number__c =system.UserInfo.getName();
                apLog.DML__c= true;
                apLog.Request__c= string.valueOf(accountSyncEvents2);
                apLog.Exception_Message__c = 'Creating Platform Event to Sync Account - Account Sync Event';
                apLog.Response__c=string.valueOf(results);
                insert aplog;
            }
                
            //}
            
            //accSyncEventPublished = true;
            
        }*/
    }
    
    public static void createPlatformEvent(){
        if(accountSyncEvents2.size() > 0){
            Map<Id, Account> forUpdAccount = new Map<Id, Account>();
            FOR (Id accntId:accountSyncEvents2.keySet()) {
                Account objAccnt = new Account();
                objAccnt.id = accntId;
                objAccnt.Sync_in_Progress__c = true;
                objAccnt.Push_to_Netsuite__c = true;
                forUpdAccount.put(accntId, objAccnt);
            }
            
            if (forUpdAccount != null && forUpdAccount.size()>0) {
                TriggerHandler.bypass('GS_AccountTriggerHandler');
              database.update(forUpdAccount.values(), false);
            }
            
            if (system.UserInfo.getName() != 'Automated Process') // GTMS-7278
            {
                TrackPlatformEvents.enQueuePlatformEventJob(TrackPlatformEvents.Event.SHIPPING_ADDRESS,Trigger.New,Trigger.oldMap);
                List<Database.SaveResult> results = EventBus.publish(accountSyncEvents2.values());
                if (System.Label.Logging_for_PlatformEvent == '1' ) 
                {
                    Api_Logger__c aplog = new Api_Logger__c();
                    apLog.Opportunity_Name__c =  'Address createPlatformEvent';
                    apLog.Quote_Number__c =system.UserInfo.getName();
                    apLog.DML__c= true;
                    apLog.Request__c= string.valueOf(accountSyncEvents2);
                    apLog.Exception_Message__c = 'Creating Platform Event to Sync Account - Account Sync Event';
                    apLog.Response__c=string.valueOf(results);
                    insert aplog;
                }
                
            }
            
        }
    }
    
    public static boolean checkIfAddressChanged(Shipping_Address__c newShippingAddress, Shipping_Address__c oldShippingAddress) {
        if(newShippingaddress.Name != oldShippingaddress.Name || 
           newShippingaddress.Shipping_Zip_Code__c != oldShippingaddress.Shipping_Zip_Code__c ||
           newShippingaddress.Shipping_Address_Line_1__c != oldShippingaddress.Shipping_Address_Line_1__c || 
           newShippingaddress.Shipping_Address_Line_2__c != oldShippingaddress.Shipping_Address_Line_2__c ||
           newShippingaddress.Shipping_City__c != oldShippingaddress.Shipping_City__c || 
           newShippingaddress.Shipping_State__c != oldShippingaddress.Shipping_State__c ||
           newShippingaddress.Shipping_Email__c != oldShippingaddress.Shipping_Email__c || 
           newShippingaddress.Shipping_Country__c != oldShippingaddress.Shipping_Country__c /*|| //GTMS-7278
           (newShippingAddress.NS_Address_Internal_ID__c != NULL 
            && newShippingAddress.NS_Address_Internal_ID__c != oldShippingAddress.NS_Address_Internal_ID__c)*/
          ) 
        {
            return true;
        }
        else
            return false;
    }

    //GTMS-6072 - Consolidate workflow field updates into trigger logic
    /*
    *   1. In the case where Shipping Address Name, Email, and Phone are blank, but there is a shipping contact, 
            we want to automatically populate these fields with the shipping contact info
        2. If the shipping mobile phone in the shipping address object is blank, and there is a shipping contact associated with the shipping address, 
            populate this field with the shipping contact's phone number
        3. If the Shipping first and last name in the shipping address table are blank, and there is a shipping contact associated with the Shipping Address, 
            populate shipping name with shipping contact info
        4. If the shipping phone number in the shipping address object is blank, and there is a shipping contact associated with the shipping address, 
            populate this field with the shipping contact's phone number
        5. NetSuite Id clear
    */
    public static void processDefaultValues(List<Shipping_Address__c> newShippingAddress, Map<Id, Shipping_Address__c> mapOldShippingAddress, Boolean isBeforeInsert){
        Map<Id, Contact> contactByShippingAddrId = new Map<Id, Contact>();
        Map<Id, Id> shippingAddressIdByContactId = new Map<Id, Id>();
        for(Shipping_Address__c sa : newShippingaddress){
            if(sa.shipping_contact__c != null){
                shippingAddressIdByContactId.put(sa.Shipping_Contact__c, sa.Id);
            }
        }
        List<contact> contactList = [SELECT Id, FirstName, LastName, Email, MobilePhone, Phone 
                                      FROM Contact 
                                      WHERE Id in :shippingAddressIdByContactId.keySet()];
        for(Contact cont : contactList){
            if(shippingAddressIdByContactId.containsKey(cont.Id)){
                contactByShippingAddrId.put(shippingAddressIdByContactId.get(cont.Id), cont);
            }
        }
        for(Shipping_Address__c sa : newShippingaddress) {
            // get owner info -- skipAddressUpdate added for GTMS-12741 
            string skipForOwnerId = System.Label.SkipAddressUpdate;
            boolean skipAddressUpdate = (skipForOwnerId != null && skipForOwnerId.containsIgnoreCase(sa.OwnerId)) ? true : false;
            if(sa.shipping_contact__c != null && (!skipAddressUpdate || isBeforeInsert)){
                
                Shipping_Address__c oldAddr = (mapOldShippingAddress != null) ? mapOldShippingAddress.get(sa.Id) : null;
                
                if(contactByShippingAddrId.containsKey(sa.Id) && ((oldAddr != null && sa.shipping_contact__c != oldAddr.shipping_contact__c) || oldAddr==null)){
                    if(contactByShippingAddrId.get(sa.Id).Email !=null && 
                       (!skipAddressUpdate || (skipAddressUpdate && (sa.Shipping_Email__c == null || sa.Shipping_Email__c == '')))
                      )
                    {
                        sa.Shipping_Email__c = contactByShippingAddrId.get(sa.Id).Email;
                    } 
                    if(contactByShippingAddrId.get(sa.Id).MobilePhone!= null && 
                       (!skipAddressUpdate || (skipAddressUpdate && (sa.Shipping_Mobile_Phone__c == null || sa.Shipping_Mobile_Phone__c == '')))
                      )
                    {
                        sa.Shipping_Mobile_Phone__c = contactByShippingAddrId.get(sa.Id).MobilePhone;
                    }
                    if(contactByShippingAddrId.get(sa.Id).Phone != null && 
                       (!skipAddressUpdate || (skipAddressUpdate && (sa.Shipping_Phone__c == null || sa.Shipping_Phone__c == '')))
                      )
                    {
                        sa.Shipping_Phone__c = contactByShippingAddrId.get(sa.Id).Phone;
                    }                
                    if(contactByShippingAddrId.get(sa.Id).LastName != null &&
                       (!skipAddressUpdate || (skipAddressUpdate && ((sa.Shipping_FirstName__c == null || sa.Shipping_FirstName__c == '') &&
                         (sa.Shipping_LastName__c == null || sa.Shipping_LastName__c == ''))))
                      ) 
                    {
                        sa.Shipping_FirstName__c = contactByShippingAddrId.get(sa.Id).FirstName;
                        sa.Shipping_LastName__c = contactByShippingAddrId.get(sa.Id).LastName;
                    }
                    if(sa.NS_Address_Internal_ID__c != null && isBeforeInsert){
                        sa.NS_Address_Internal_ID__c = null;
                        sa.Netsuite_ID_Override__c = null;
                    }
                }
            }
        }
    }
    //GTMS-25842 - Auto update the Shipping state on return opportunity record 
    public static void updateOpportunityShippingAddress( List<Shipping_Address__c> newShippingAddresses, Map<Id, Shipping_Address__c> oldShippingAddresses) {
        String returnOpportunityRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
        Map<Id, Shipping_Address__c> idVSShippingMap = new Map<Id, Shipping_Address__c>();
        //List<opportunity> returnOppsList = New List<opportunity>();
        List<Opportunity> opportunityListToUpdate = new List<Opportunity>();
        List<String> includeStages = System.Label.Return_Opportunity_Stages_for_Shipping_Address_Change.split(',');
        List<String> shippingCountries = System.Label.Return_Opportunity_Shipping_Countries.split(',');
        List<String> oppTypes = System.Label.Return_Opportunity_Types_For_Shipping_Address_Change.split(',');
        // Collect updated shipping addresses
        for (Shipping_Address__c shippingRec : newShippingAddresses) {
                if (oldShippingAddresses.get(shippingRec.Id).Shipping_State__c != shippingRec.Shipping_State__c) {
                    idVSShippingMap.put(shippingRec.Id, shippingRec);
                }
        }        
        // Query for related opportunities
        if(!idVSShippingMap.isEmpty()){
            List<opportunity> returnOppsList = [SELECT Id, Shipping_State__c, Shipmate_Preference__c, Shipping_Address_NEW__c, Type 
             FROM Opportunity 
             WHERE RecordTypeId = :returnOpportunityRecordTypeId 
             AND Shipping_Address_NEW__c IN :idVSShippingMap.keySet() 
             AND StageName IN :includeStages];  

        // Get the Shipmate preferences based on countries and states
        if(!returnOppsList.isEmpty()){
           Map<String, String> countryShipmatePreferences = getCountryShipmatePreferences();
        // Process each opportunity
        for (Opportunity opp : returnOppsList ) {
            Shipping_Address__c shippingAddress = idVSShippingMap.get(opp.Shipping_Address_NEW__c);
            if (shippingAddress != null) {
                // Set Shipmate Preference based on conditions
                if (shippingAddress.Shipping_Country__c == 'Mexico' && oppTypes.contains(opp.Type)) {
                    opp.Shipmate_Preference__c = 'ShippingPreference-000030';
                } else if (!shippingCountries.contains(shippingAddress.Shipping_Country__c)) {
                    opp.Shipmate_Preference__c = 'ShippingPreference-000027';
                } else if (shippingCountries.contains(shippingAddress.Shipping_Country__c)) {
                    String stateKey = shippingAddress.Shipping_Country__c + shippingAddress.Shipping_State__c;
                    if(countryShipmatePreferences.containsKey(stateKey)){
                    opp.Shipmate_Preference__c = countryShipmatePreferences.get(stateKey);
                    }
                }
                opp.Shipping_State__c = shippingAddress.Shipping_State__c;  
            }
        }
        update returnOppsList;
       }
      }
    }
    // Helper method to get Shipmate preferences for countries and states
    private static Map<String, String> getCountryShipmatePreferences() {
        Map<string, string> shipmatePref = new Map<string, string> ();
        Map<string, Warehouse_Mapping__mdt> warehouseMdt = Warehouse_Mapping__mdt.getAll();
        for(String rec : warehouseMdt.keySet()){
            shipmatePref.put(warehouseMdt.get(rec).Country__c+warehouseMdt.get(rec).MasterLabel,warehouseMdt.get(rec).Shipmate_Preference__c);
        }
        return shipmatePref;
    }
}