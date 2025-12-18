/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 05, 2021
*
* @description : This class will be responsible for handling all the Account Related Queries
* SFA-11
*
**/
public with sharing class GS_AccountSelector extends GS_SObjectBaseSelector{

    public GS_AccountSelector(Boolean checkFatalError){
        super(checkFatalError);
    }
     
    public GS_AccountSelector checkFatalError(){
        return (GS_AccountSelector) super.validateFatalError();
    }
    
    public List<Account> getAccountsByIds(List<Id>ids){
        List<Account> newAccountList = new List<Account>();
        newAccountList = [SELECT  Id,							
                                                                Billing_Contact__c, 
                                                                Billing_First_Name__c, 
                                                                Billing_Last_Name__c, 
                                                                Billing_Phone__c, 
                                                                Billing_Email__c,
                                                                Type,
                                                                Status__c,
                                                                Organization_Size__c,
                                                                BillingCountry,
                         									    BillingCountryCode,
                                                                Owner.Name,
                                                                Owner.Level__c,
                                                                Owner.ADR_Segment_Alignment__c,
                                                                RecordType.Name,
                                                                Most_Recent_Source__c,
                                                                Owner_Role__c,
                                                                Initiate_Round_Robin__c ,
                                                                RR_Assign_Region_Owner__c,
                                                                Is_Owner_Pool_User__c,
                                                                Original_Owner_for_Recycling_Campaign__c,
                                                                Open_Opportunity__c,
                                                                Last_Contacted__c,
                                                                Last_Call__c,
                                                                Customer_ARR__c,
                                                                Quarantine_Enabled__c,
                                                                Account_Lifetime_ACV__c,
                                                                RecordType.DeveloperName,
                                                                Hashtag__c,
                                                                Name,
                                                                Number_of_Calls_by_Current_Owner__c,Account_Book_Owner__c,
                                                                Event_Lead__c,
                                                                (SELECT Id,
                                                                StageName,
                                                                Trial_Status__c,
                                                                Type
                                                                FROM Opportunities)
                                                        FROM Account
                                                        WHERE Id IN :ids];
        return newAccountList;
    }
    
    public List<Account> getAccountsWithCSMRecordsByAccIds(List<Id> recordIds){
        List<Account> accounts = [SELECT Key_Stakeholder_for_CSM__c, Key_Value_Points__c, Upsell_Opportunity_Products__c, 
										  AE_to_CSM_handoff_notes__c, Preparedness_Rating__c, Self_install_or_Vendor__c, SIC__c,
                                          Did_they_Trial__c, Feature_commits_CSM__c, Pain_Points_Objections_during_the_trial__c,
                                   			CS_POC_Email_Address__c, CS_POC_First_Name__c, SIC__r.Name,First_Purchase_Date__c,Pre_Sale_IC__r.Name,
                                   		  (SELECT Id, Key_Stakeholder_for_CSM__c, Key_Value_Points__c, Upsell_Opportunity_Products__c, 
										  	AE_to_CSM_handoff_notes__c, Preparedness_Rating__c, Self_install_or_Vendor__c, First_Purchase_Date__c,
                                          	Did_they_Trial__c, Feature_commits_CSM__c, Pain_Points_Objections_during_the_trial__c,SIC__c,Pre_Sale_IC__c,
                                          	CS_POC_Email_Address__c, CS_POC_First_Name__c FROM CS_Records__r)
                                         FROM Account 
                                         WHERE Id IN :recordIds AND SAM_Number_Undecorated__c != 'C4G5EZWGY6'];
        return accounts;
    }
    
    /**
     * Fetches the Accounts with the related Opportunities and Shipping Addresses by Id.
     * @param List<Id> idList
     */
    public List<Account> getAccountsWithOppAndShipAddrByIds(List<Id> idList){
        return [
            SELECT Id, Name, Free_Trial_Kit_Sent_Date__c, Segment__c,
            Welcome_Kit_Sent_Date__c, Segment_Text_stamped__c, Latest_Active_Contract__r.EndDate,
            Billing_Email__c, BillingStreet,BillingCity, BillingPostalCode, Latest_Active_Contract__c,
            BillingCountry, Internally_Financed__c, Churn_Update_CC_Link__c, Which_written_language__c,
            VAT_Validation_Status__c, BillingState, First_Purchase_Value__c, VATId__c, Status__c, First_Purchase_Date__c,
            Partner_Status__c, RecordType.Name, Business_Unit__c, Critically_Escalated_Hardware_Returns__c,
            Netsuite_Id__c, Push_to_Netsuite__c,Ownerid,
            (
                SELECT Id, Pricebook2.Name, Pricebook2Id,
                CloseDate, StageName, Type
                FROM Opportunities
                ORDER BY CloseDate DESC
            ),
            (
                SELECT id, Name, Shipping_Country__c
                FROM Shipping_Addresses__r
                ORDER BY LastModifiedDate desc
                LIMIT 1
            )
            FROM Account
           WHERE Id
              IN :idList
        ];
    }
    
    
    public List<Account> getAccountsWithOpptyAndContactRecordsByAccIds(List<Id> accountIds){
        return [SELECT  Id,
                                                Status__c,
                                                Owner.Name,
                                                First_Purchase_Date__c,
                                                First_Revenue_Oppty_Creation_Date__c,
                                                Closed_Lost_Account__c,
                                                (SELECT Id,
                                                 StageName,
                                                 Type,
                                                 Owner.Name
                                                 FROM Opportunities
                                                 WHERE Type='Revenue Opportunity'),
                                                (SELECT Id,
                                                 Status__c
                                                 FROM Contacts)
                                                FROM Account
                                                WHERE Id IN :accountIds];
    }
    
    
    public List<Account> getAccountsWithDemoDateByIds(Set<Id> idSet){
        return [SELECT  Id,
                             First_Demo_Date__c
                             FROM Account
                             WHERE Id IN :idSet
                             AND First_Demo_Date__c = null];
    }
    
    public class AccountSelectorException extends Exception { }
}