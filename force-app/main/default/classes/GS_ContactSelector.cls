/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 06, 2021
*
* @description : This class will be responsible for handling all the Contact Related Queries
* SFA-11
*
**/
public class GS_ContactSelector extends GS_SObjectBaseSelector{
        
    public GS_ContactSelector(boolean checkFatalError){
        super(checkFatalError);
    }
    
    public GS_ContactSelector checkFatalError(){
        return (GS_ContactSelector) super.validateFatalError();
    }
    
    
    public List<Contact> getContactsByIds(Set<Id> ids){
        List<Contact> contactList = new List<Contact>();
        contactList = [select Id, FirstName, LastName, Email, OwnerId, Owner_Name__c, Owner_Is_Signed_In__c, Owner_Role__c, Phone from Contact where Id IN : ids];
        return contactList;
    }
    
     public List<Contact> getContactsByAccountIds(Set<Id> ids){
        List<Contact> contactList = new List<Contact>();
        contactList = [select Id, OwnerId from Contact where AccountId IN : ids];
        return contactList;
    }
    
    
    public List<Contact> getContactsToStampLawfulBasisOnContactByAccountIds(List<Id> accIds){
        List<Contact> contactList = new List<Contact>();
        contactList = [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accIds AND Associated_Lawful_Basis__c != 'Contract'];
        
        return contactList; 
    }
    
    public List<Contact> getContactDetailsByIds(Set<Id> contactIds){
        List<Contact> contactList = new List<Contact>();
        contactList = [SELECT  Id,
                                            New_Inbound_Lead__c,
                      					    Converted_Contact__c,
                                            Channel_Source__c,
                                            Most_Recent_Source__c,
                                            Hashtag__c,
                                            Associated_Lawful_Basis__c,
                       						Account.Original_Owner_for_Recycling_Campaign__c,
                                            Account.Enterprise_Experiments__c,
                                            Owner.UserRole.Name,
                                            Account.Original_Owner_for_Recycling_Campaign__r.Name,
                                            ADR_Transfer__c,
                                            ADR_Transfer_By__c,
                       						Account.Owner_Role__c ,
                       						Account.OwnerId,
                                            OwnerId,
                       						Status__c,
                                            ADR_Transfer_Date__c,
                                            ADR_Demo_Date__c,
                                            ADR_Transfer_Status__c,
                                            Hot_Transfer_To__c,
                                            AccountId,
                                            (SELECT Id,
                                                    ADR_Transfer__c,
                                                    ADR_Transfer_By__c,
                                                    ADR_Transfer_Status__c
                                            FROM ADR_Transfer_Logs__r
                                            WHERE ADR_Transfer_Date__c = LAST_N_DAYS:30
                                            AND ADR_Transfer__c = false
                                            ORDER BY CreatedDate
                                            DESC limit 1)
                                    FROM Contact WHERE Id IN :contactIds];
                                         return contactList;
    }
    
         
    public List<Contact> getContactsToCheckDupesByIds(Set<String> phoneIds, Set<String> emailIds){
        List<Contact> contactList = new List<Contact>();
        contactList = [SELECT  Id,
                                      Opt_Out_Email_Copy__c,
                                      Opt_Out_Mobile_Phone__c,
                                      Opt_Out_Phone__c
                                      FROM Contact
                                      WHERE Opt_Out_Phone__c IN :phoneIds
                                      OR Opt_Out_Mobile_Phone__c IN :phoneIds
                                      OR Opt_Out_Email_Copy__c IN :emailIds];
        
        return contactList;
    }

    public List<Contact> getRelatedTaskContactsById(Set<Id> idSet){
        return [SELECT Id, Description, Number_of_Calls__c, Last_Call__c, Status__c,
                       AccountId, Account.First_Revenue_Oppty_Creation_Date__c, Account.Status__c, Account.Total_Expected_Revenue_Currency__c, Account.Lifetime_Purchases_Currency__c
                  FROM Contact
                 WHERE Id IN :idSet];
    }
    
    
    public class ContactSelectorException extends Exception{}
}