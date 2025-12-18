public class DedupeAccounts {
    
	@InvocableMethod(label='De-Dupe Accounts' description='When an account ID is added, this will return a list of duplicate accounts in Salesforce.')
    public static List<List<Account>> getDuplicateAccountsForProcessing(List<Account> accounts){
        List<List<Account>> result = new List<List<Account>>(); //create the final wrapper variable so that an empty list may be returned if there are no results
		List<DuplicateRecordItem> duplicate_set = new List<DuplicateRecordItem>(); //create a list variable for duplicate sets that we will search for
        //get the IDs of duplicate sets that this account is a part of 
        if(accounts.size() > 0){
           	duplicate_set = [SELECT  DuplicateRecordSetId
                       			FROM DuplicateRecordItem 
                       			WHERE RecordId = :accounts[0].Id
                            	AND DuplicateRecordSet.RecordCount<=8];      
        }
        if(duplicate_set != null ){
            List<String> duplicate_set_ids = new List<String>(); //create a string list to store the duplicate set IDs for the next query
            //use a loop to get all of the IDs
            for (DuplicateRecordItem dri :duplicate_set){
                duplicate_set_ids.add(dri.DuplicateRecordSetId);
            }
            List<DuplicateRecordItem> duplicate_records = new List<DuplicateRecordItem>(); //create a list for the duplicate set items that have record Ids

            //get the record ids of all account ids in the duplicate sets
            if(duplicate_set_ids.size() > 0){
              duplicate_records = [SELECT RecordId
                           FROM DuplicateRecordItem 
                           WHERE DuplicateRecordSetId IN :duplicate_set_ids];
            }
            Set <String> duplicate_record_ids = new Set<String>(); //create a list for the record IDs that will be used for the last query
            //check to see if any of the record Ids appear multiple times, if not push them to the list
            for(DuplicateRecordItem dr :duplicate_records){
                duplicate_record_ids.add(dr.RecordId);
            }
            List<Account> duplicate_accounts = new List<Account>(); //create a list for the account records that will be returned to the flow
            //run query to get all accounts
            if(duplicate_record_ids.size() > 0){
                duplicate_accounts = [SELECT Name, Phone, Website, BillingStreet, Domain_Name__c, BillingState, 
                                  	  	BillingPostalCode, BillingCity,Enterprise_Assignment__c, 
                                  	  	Inside_Sales_Assignment__c, Account_Assignment_Date__c, Original_Owner_for_Recycling_Campaign__c, 
                                  	  	Account_with_Owner__c, Number_of_Vehicles__c, Current_Owner_Email__c, Status__c, Master_Account_for_Dupe__c, Alternative_Domains__c 
                           			  FROM Account
                           			  WHERE Id IN :duplicate_record_ids
                          	 		  AND Id != :accounts[0].Id
                                      AND RecordTypeId = :accounts[0].RecordTypeId];
            }
            
            //add duplicate accounts to result wrapper
            result.add(duplicate_accounts);
        }
        return result;
    }
}