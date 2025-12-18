public class TrackAccountFieldsToPublishPlatEvents {

    public static List<Account> trackAccountFields(Set<id> idSet,sObjectType objType){
        List<Account> accountstoUpdate = new List<Account>();
        
        String query = 'select id,Name,Current_Owner_Email__c, Which_Written_Language__c,BigCommerce_Id__c,Push_to_Webstore__c,CurrencyIsoCode,Segment__c ,Segment_Text_Stamped__c,SAM_Number_Undecorated__c,SAM_Number_Decorated__c,Billing_Email__c,Billing_First_Name__c ,Billing_Last_Name__c ,BillingCountry,BillingCountryCode, BillingState,BillingStateCode,Latest_Active_Contract__c from Account where ';
        query += (objType==Contract.sObjectType)?'Latest_Active_contract__c in:idSet':'Ownerid in:idSet';
        
        List<Account> accList = Database.query(query);
        
        if(!accList.isEmpty()){
            Toggle_Platform_Event__mdt accountEventToggle = Toggle_Platform_Event__mdt.getInstance('Account_Sync_Webstore_Event');
            Sync_Object_Field_WebStore__mdt [] accountNullCheckFields = [Select Id,Object_Api_Name__c,Field_Api_Name__c,Null_Check_Needed__c from Sync_Object_Field_WebStore__mdt Where Object_Api_Name__c = 'Account' and Null_Check_Needed__c = true];
            
            for(Account acc : accList){
                Boolean nullFlagCheck = verifyNullCheck(acc,accountNullCheckFields);
                if ((nullFlagCheck || acc.BigCommerce_Id__c != null) && acc.Push_to_Webstore__c == false && accountEventToggle.toggle__c){ 
                    accountstoUpdate.add(new Account(Id = acc.Id, Push_to_Webstore__c = true));
                }
            }
        }
        return accountstoUpdate;
    }
    
    public static Boolean verifyNullCheck(Account Acc,Sync_Object_Field_WebStore__mdt [] AccountNullCheckFields){
        for(Sync_Object_Field_WebStore__mdt EachMdtField: AccountNullCheckFields){
            if(Acc.get(EachMdtField.Field_Api_Name__c)==null){
                return false; 
            }
        }
        return true;
    }
}