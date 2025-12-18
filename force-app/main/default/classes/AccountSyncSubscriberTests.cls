/* 
 * Class Created:  08/08/2022
 * 08/03/22 Raghav - (GTMS-6072) Test class for AccountSyncSubscriber
 */ 
@isTest
public class AccountSyncSubscriberTests {
	@isTest
    public static void createAccountSync(){
        List<Account> accounts = new List<Account>();
        for(Integer i=0;i<5;i++){
            Account newAccount = new Account(Name = 'Testers Inc'+i,
                                         BillingState='California',
                                         BillingCountry = 'United States',
                                         Organization_Size__c = '100 - 499',
                                         Approved_Payment_Type__c = 'Direct Monthly',
                                             Push_to_Netsuite__c = false,
                                             Sync_in_Progress__c = false, 
                                             Netsuite_Id__c = null,
                                         Industry = 'Other');
        	accounts.add(newAccount);
        }
        insert accounts;
        
        List<Account_Sync_Event__e> eventList = new List<Account_Sync_Event__e>();
        for(Integer i=0;i<5;i++) {
            Account_Sync_Event__e oneEvent = new Account_Sync_Event__e(Id__c=accounts[i].Id);
            eventList.add(oneEvent);
        }
        Database.SaveResult[] srs = EventBus.publish(eventList);
        Test.getEventBus().deliver(); 
        List<account> accToValidate = [Select Id, Push_to_Netsuite__c from account where Push_to_Netsuite__c = true];
        system.assert(accToValidate.size()>0, 'Invalid data');
    }
}