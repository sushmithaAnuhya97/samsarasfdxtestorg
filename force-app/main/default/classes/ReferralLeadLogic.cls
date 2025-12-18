/*
* April 16th, 2020 Ron Saavedra - (GTMS-71, GTMS-72) Optimize underlying referral check & calculation of referral match + include existing contact lookup mapping
*/
public with sharing class ReferralLeadLogic {

    static Map<String, Account> samToAccountMap = new Map<String, Account>();
    static Map<String, Contact> emailToContactMap = new Map<String, Contact>();
    static Boolean loadedStaticAccounts = false;
    static Boolean loadedStaticContacts = false;

    //* April 16th, 2020 Ron Saavedra - (GTMS-71, GTMS-72) Optimize underlying referral check & calculation of referral match + include existing contact lookup mapping
    public static void referralLeadLogicCheck(Map<Id, Contact> oldContactMap, Map<Id, Contact> newContactMap, Boolean async){

        Map<Id, Contact> filteredContactsMap = new Map<Id, Contact>();

        for(Contact c: newContactMap.values()){
            if(oldContactMap != null){
                Contact oldcontact = oldContactMap.get(c.Id);
                if(oldcontact.Referring_Customer_Id__c != c.Referring_Customer_Id__c && c.Referring_Customer_Id__c != null){
                    filteredContactsMap.put(c.Id, c);
                }
            }
            else{
                if(c.Referring_Customer_Id__c != null){
                    filteredContactsMap.put(c.Id, c);
                }
            }
        }

        if(filteredContactsMap.size() > 0){
            // Async update check to account for async "lead insertion"
            if(async){
                referralLeadLogicSync(oldContactMap, newContactMap);
            }
            else{
                String oldContactMapSerialized = JSON.serialize(oldContactMap);
                String newContactMapSerialized = JSON.serialize(newContactMap);
                referralLeadLogicFuture(oldContactMapSerialized, newContactMapSerialized);
            }
        }
    }

    @Future
    private static void referralLeadLogicFuture(String oldContactMapSerialized, String newContactMapSerialized){
        Map<Id, Contact> oldContactMapDeserialized = null;
        Map<Id, Contact> newContactMapDeserialized = null;
        if (oldContactMapSerialized != null) {
            oldContactMapDeserialized = (Map<Id, Contact>)JSON.deserialize(oldContactMapSerialized, Map<Id, Contact>.class);
        }
        newContactMapDeserialized = (Map<Id, Contact>)JSON.deserialize(newContactMapSerialized, Map<Id, Contact>.class);

        referralLeadLogicSync(oldContactMapDeserialized, newContactMapDeserialized);
    }

    //* April 16th, 2020 Ron Saavedra - (GTMS-71, GTMS-72) Optimize underlying referral check & calculation of referral match + include existing contact lookup mapping
    //* August 4, 2022 Rodrigo Carpio - (GTMS-6545) added null check on acct variable
    public static void referralLeadLogicSync(Map<Id, Contact> oldContactMap, Map<Id, Contact> newContactMap) {

        List<Referral__c> newreferrals = new List<Referral__c>();
        List<String> samNumbers = new List<String>();
        List<String> customerRefEmails = new List<String>();

        Map<Id, Contact> filteredContactsMap = new Map<Id, Contact>();

        for(Contact c: newContactMap.values()){
            //aggregate external contact Id list if either the value changes or upon insert a referring customer Id is inserted
            
            if(oldContactMap != null){
                Contact oldcontact = oldContactMap.get(c.Id);
                if(oldcontact.Referring_Customer_Id__c != c.Referring_Customer_Id__c && c.Referring_Customer_Id__c != null){
                    filteredContactsMap.put(c.Id, c);
                    samNumbers.add(c.Referring_Customer_Id__c);
                    customerRefEmails.add(c.Customer_Referral_Email__c);
                }
            }
            else{
                if(c.Referring_Customer_Id__c != null){
                    filteredContactsMap.put(c.Id, c);
                    samNumbers.add(c.Referring_Customer_Id__c);
                    customerRefEmails.add(c.Customer_Referral_Email__c);
                }
            }
        }

        // Only run this logic if the filter check has passed and contains values
        if(filteredContactsMap.size() > 0){

            // Only query if necessary!
            if(samNumbers.size() > 0) {
                loadSamToAccountsMap(samNumbers);
            }

            if(customerRefEmails.size() > 0){
                loadEmailToContactsMap(customerRefEmails);
            }

            for(Contact ctc: filteredContactsMap.values()){
                Account acct = samToAccountMap.get(ctc.Referring_Customer_Id__c);

                Contact contact = emailToContactMap.get(ctc.Customer_Referral_Email__c) != null? emailToContactMap.get(ctc.Customer_Referral_Email__c): null; 
                String customerType = oldContactMap != null ? 'Existing': 'New';

                if(contact != null){
                    if(acct != null && ctc.Referring_Customer_Id__c == acct.SAM_Number_Undecorated__c){ // added null check on acct for GTMS-6545
                        Referral__c ref = new Referral__c(  Referred_Customer__c = ctc.Id, 
                                                            Referring_Customer_Accountv2__c = acct.Id,
                                                            Referring_Customer__c = contact.Id,
                                                            Referring_Customer_First_Name__c = contact.FirstName,
                                                            Referring_Customer_Last_Name__c = contact.LastName,
                                                            Manual_Referring_Customer_Email__c = ctc.Customer_Referral_Email__c, 
                                                            Customer_Type__c = customerType);
                        newreferrals.add(ref);
                    }
                }
                else{
                    if(acct != null && ctc.Referring_Customer_Id__c == acct.SAM_Number_Undecorated__c){ // added null check on acct for GTMS-6545
                        Referral__c ref = new Referral__c(  Referred_Customer__c = ctc.Id, 
                                                            Referring_Customer_Accountv2__c = acct.Id,
                                                            Manual_Referring_Customer_Email__c = ctc.Customer_Referral_Email__c,
                                                            Customer_Type__c = customerType);
                        newreferrals.add(ref);
                    }
                }
            }
            insert newreferrals;
        }
    }

    // load map of SAM Number to Account for referral matching
    public static void loadSamToAccountsMap(List<String> samNumbers) {
		if(!loadedStaticAccounts && samNumbers.size() > 0) {
            for(Account acct : [SELECT  SAM_Number_Undecorated__c, 
                                        Id
                                FROM Account
                                WHERE SAM_Number_Undecorated__c IN :samNumbers]) {
                samToAccountMap.put(acct.SAM_Number_Undecorated__c, acct);
            }
			loadedStaticAccounts = true;
		}
    }
    
    // load map of Email to Contact for referral matching
    public static void loadEmailToContactsMap(List<String> customerRefEmails) {
		if(!loadedStaticContacts && customerRefEmails.size() > 0) {
            for(Contact ctc: [  SELECT  Email,
                                        FirstName, 
                                        LastName, 
                                        Id
                                FROM Contact
                                WHERE Email IN :customerRefEmails]){
                emailToContactMap.put(ctc.Email, ctc);
            }
			loadedStaticContacts = true;
		}
	}
}