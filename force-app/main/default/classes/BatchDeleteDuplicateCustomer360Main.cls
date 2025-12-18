//This batch is to take all discount and mup field null
public class BatchDeleteDuplicateCustomer360Main  implements Database.Batchable<sobject>{
    public Database.QueryLocator start(Database.BatchableContext BC){
        //create label or change query to take null records
        String dynamicQuery=null;
        if(System.label.customer360BatchUserId=='All'){
            dynamicQuery='select id,Credit_Limit__c,First_Purchase_Date__c,Lifetime_Purchases__c from account';
        }
        else{
            List<String>ownerId=new List<String>();
            String userId=System.label.customer360BatchUserId;
            ownerId=userId.split(',');
            List<User>teammember=[select id from user where  Manager.Manager_ID__c in:ownerId or Manager_ID__c in:ownerId or Manager.Manager.Manager_ID__c in:ownerId];
            for(user us:teammember){
                ownerId.add(us.id); 
                
            }
            
            System.debug('***Owners count***'+ownerId.size());
            dynamicQuery='select id from account where ownerId in :ownerId';
            
        }
        return Database.getQueryLocator(dynamicQuery);
    }
    public void execute(Database.BatchableContext BC, List<Account> Account)
    {
        try{
            System.debug('Accounts are'+Account);
            List<Customer_360__c> refreshHeader=new List<Customer_360__c>();
            List<String>accToBeQueriedInC360=new List<String>();
            Map<Id,Account> allAccounts=new Map<Id,Account>();
            Map<String,Integer> cus360DuplicateCount=new Map<String,Integer>();
            List<Id>queryInCus360=new List<id>();
            List<Account> accountsToUpdate=new List<Account>();
            for(Integer i=0;i<Account.size();i++){
                accToBeQueriedInC360.add(Account.get(i).Id);
                allAccounts.put(Account.get(i).Id,Account.get(i));
            }
            List<AggregateResult> agr=[select Account__c,count(id) cnt  from Customer_360__c  where account__c in :accToBeQueriedInC360 group by account__c having count(id)>1];
            for (AggregateResult agrResult:agr)
            {
                String accId=(String)agrResult.get('Account__c');
                queryInCus360.add(accId);
                cus360DuplicateCount.put(accId,(Integer)agrResult.get('cnt'));
                
            }
            //query the customer360 with null dis and mup rec having duplicate customer360;
            
            List<Customer_360__c> tobeDeletedCus360=new List<Customer_360__c>();
            List<Customer_360__c> customer360Data=[Select id,SOT__c,Account__c,Hide_Licenses_in_Webstore__c,CreatedDate from Customer_360__c where (Account__c in :queryInCus360 and (LIC_AG_PWR_REEFER_Discount__c=null or LIC_AG_PWR_REEFER_Discount__c=0) and (LIC_AG_PWR_REEFER_KIT_Discount__c=null or LIC_AG_PWR_REEFER_KIT_Discount__c=0) and (LIC_AG_PWR_REEFER_KIT_MUP__c=null or LIC_AG_PWR_REEFER_KIT_MUP__c=0) and (LIC_AG_PWR_REEFER_MUP__c=null or LIC_AG_PWR_REEFER_MUP__c=0) and (LIC_AG2_Discount__c=null or LIC_AG2_Discount__c=0) and (LIC_AG2_ENT_MUP__c=null or LIC_AG2_ENT_MUP__c=0) and (LIC_AG4_Discount__c=null or LIC_AG4_Discount__c=0) and (LIC_AG4_ENT_MUP__c=null or LIC_AG4_ENT_MUP__c=0) and (LIC_AG4P_Discount__c=null or LIC_AG4P_Discount__c=0) and (LIC_AG4P_ENT_MUP__c=null or LIC_AG4P_ENT_MUP__c=0) and (LIC_AT_Discount__c=null or LIC_AT_Discount__c=0) and (LIC_AT_TAG_MUP__c=null or LIC_AT_TAG_MUP__c=0) and (LIC_CM_AHD1_Discount__c=null or LIC_CM_AHD1_Discount__c=0) and (LIC_CM_AHD1_MUP__c=null or LIC_CM_AHD1_MUP__c=0) and (LIC_CM_ANLG_Discount__c=null or LIC_CM_ANLG_Discount__c=0) and (LIC_CM_ANLG_MUP__c=null or LIC_CM_ANLG_MUP__c=0) and (LIC_CM1_Discount__c=null or LIC_CM1_Discount__c=0) and (LIC_CM1_ENT_MUP__c=null or LIC_CM1_ENT_MUP__c=0)  and (LIC_CM1_PRO_Discount__c=null or LIC_CM1_PRO_Discount__c=0) and (LIC_CM1_PRO_MUP__c=null or LIC_CM1_PRO_MUP__c=0) and (LIC_CM2_Discount__c=null or LIC_CM2_Discount__c=0) and (LIC_CM2_ENT_MUP__c=null or LIC_CM2_ENT_MUP__c=0)  and (LIC_CM2_PRO_Discount__c=null or LIC_CM2_PRO_Discount__c=0) and (LIC_CM2_PRO_MUP__c=null or LIC_CM2_PRO_MUP__c=0) and (LIC_CRGO_Discount__c=null or LIC_CRGO_Discount__c=0) and (LIC_CRGO_ENT_MUP__c=null or LIC_CRGO_ENT_MUP__c=0) and (LIC_DM11_Discount__c=null or LIC_DM11_Discount__c=0) and (LIC_DM11_ENT_MUP__c=null or LIC_DM11_ENT_MUP__c=0) and (LIC_EI_A_Discount__c=null or LIC_EI_A_Discount__c=0) and (LIC_EI_A_MUP__c=null or LIC_EI_A_MUP__c=0) and (LIC_EI_EU_MUP__c=null or LIC_EI_EU_MUP__c=0) and (LIC_EI_SEC_Discount__c=null or LIC_EI_SEC_Discount__c=0) and (LIC_EI_SEC_MUP__c=null or LIC_EI_SEC_MUP__c=0) and (LIC_EM_Discount__c=null or LIC_EM_Discount__c=0) and (LIC_EM_ENT_MUP__c=null or LIC_EM_ENT_MUP__c=0) and (LIC_MEM_Discount__c=null or LIC_MEM_Discount__c=0) and (LIC_MEM_ENT_MUP__c=null or LIC_MEM_ENT_MUP__c=0)  and (LIC_PLTFM_PRO_Discount__c=null or LIC_PLTFM_PRO_Discount__c=0) and (LIC_PLTFM_PRO_MUP__c=null or LIC_PLTFM_PRO_MUP__c=0) and (LIC_SC1_Discount__c=null or LIC_SC1_Discount__c=0) and (LIC_SC11_Discount__c=null or LIC_SC11_Discount__c=0) and (LIC_SC21_Discount__c=null or LIC_SC21_Discount__c=0) and (LIC_SVC_CM_Review_ENT_MUP__c=null or LIC_SVC_CM_Review_ENT_MUP__c=0) and (LIC_TRLR_ESS_Discount__c=null or LIC_TRLR_ESS_Discount__c=0) and (LIC_TRLR_ESS_MUP__c=null or LIC_TRLR_ESS_MUP__c=0) and (LIC_TRLR_PREM_Discount__c=null or LIC_TRLR_PREM_Discount__c=0) and (LIC_TRLR_PREM_KIT_Discount__c=null or LIC_TRLR_PREM_KIT_Discount__c=0) and (LIC_TRLR_PREM_KIT_MUP__c=null or LIC_TRLR_PREM_KIT_MUP__c=0) and (LIC_TRLR_PREM_MUP__c=null or LIC_TRLR_PREM_MUP__c=0) and (LIC_VG_Discount__c=null or LIC_VG_Discount__c=0) and (LIC_VG_ENT_MUP__c=null or LIC_VG_ENT_MUP__c=0) and (LIC_VG_LD_Discount__c=null or LIC_VG_LD_Discount__c=0) and (LIC_VG_LD_MUP__c=null or LIC_VG_LD_MUP__c=0) and (LIC_Advanced_Support_MUP__c=null or LIC_Advanced_Support_MUP__c=0 ) and (LIC_Advanced_Support_Discount__c=null or LIC_Advanced_Support_Discount__c=0 ) and(LIC_AG_PWR_PLUS_Discount__c=null or LIC_AG_PWR_PLUS_Discount__c=0) and(LIC_AG_PWR_PLUS_MUP__c=null or LIC_AG_PWR_PLUS_MUP__c=0) and (LIC_VG_PRO_Discount__c=null or LIC_VG_PRO_Discount__c=0) and (LIC_VG_PRO_MUP__c=null or LIC_VG_PRO_MUP__c=0) and(LIC_VG_PS_MUP__c=0 or LIC_VG_PS_MUP__c=null))]; 

            Map<id,list<Customer_360__c>>customer360FullData=new Map<id,list<Customer_360__c>>();
            for(integer i=0;i<customer360Data.size();i++)
            {
                if(customer360FullData.containsKey(customer360Data.get(i).Account__c))
                {
                    customer360FullData.get(customer360Data.get(i).Account__c).add(customer360Data.get(i));
                }
                else
                { 
                    customer360FullData.put(customer360Data.get(i).Account__c,new List<Customer_360__c>{customer360Data.get(i)});
                    
                }
            }
            for(String accId:customer360FullData.keySet())
            {
                
                
                List<Customer_360__c>nullMupandDisc=new List<Customer_360__c>();
                nullMupandDisc=customer360FullData.get(accId);
                // if any account having duplicate customer 360 with same/different header with pricing
                // component then remove the null mup and dis record from customer 360.
                if(cus360DuplicateCount.get(accId)!=nullMupandDisc.size())
                {
                    tobeDeletedCus360.addall(nullMupandDisc);
                    
                }
                //duplicate in customer360 without pricing component with same or different headers
                else if(cus360DuplicateCount.get(accId)==nullMupandDisc.size()){
                    Map<String,Customer_360__c> customer360Map=new Map<String,Customer_360__c>();
                    boolean webstoreFlag=false;
                    for(integer i=0;i<nullMupandDisc.size();i++)
                    {
                        if(nullMupandDisc.get(i).Hide_Licenses_in_Webstore__c && !webstoreFlag){
                            webstoreFlag=true;
                        }
                        if(!customer360Map.isEmpty()){
                            Customer_360__c rec=new Customer_360__c();
                            rec=customer360Map.get(accId);
                            if(nullMupandDisc.get(i).CreatedDate<rec.CreatedDate){
                                System.debug('record to delete'+nullMupandDisc.get(i).id);
                                tobeDeletedCus360.add(nullMupandDisc.get(i));//added the record to list to delete which is not the recent record 
                            }
                            else{
                                System.debug('inside else '+nullMupandDisc.get(i).id);
                                tobeDeletedCus360.add(rec);
                                customer360Map.put(nullMupandDisc.get(i).Account__c,nullMupandDisc.get(i));//update the map for the existing iteration
                            }
                        }
                        else{
                            customer360Map.put(nullMupandDisc.get(i).Account__c,nullMupandDisc.get(i)); 
                        }                         
                    } 
                    //header value refresh from account for same header and different header without pricing component
                    if(customer360Map.size()==1)
                    {
                        Customer_360__c customer360allnullandMup=new Customer_360__c();
                        customer360allnullandMup=customer360Map.values().iterator().next(); 
                        System.debug('***customer360allnullandMup***'+customer360allnullandMup);
                        System.debug('***webstoreFlag***'+webstoreFlag);
                        if(webstoreFlag==true || customer360allnullandMup.SOT__c==false)
                        {
                            customer360allnullandMup.SOT__c=true;
                            if(webstoreFlag)
                            {
                                customer360allnullandMup.Hide_Licenses_in_Webstore__c=true;
                            }
                            refreshHeader.add(customer360allnullandMup);
                        }
                        
                    }
                    else
                    {
                        System.debug('issue in batch more than 1 record exist for null mup discount'+accId);
                    }
                }  
            }
            
            
            if(tobeDeletedCus360.size()>0)
            {
                delete tobeDeletedCus360;
            }
            if(refreshHeader.size()>0){
                update refreshHeader;
            }
        }
        
        catch(Exception ex)
        {
            System.debug('Exception in BatchDeleteDuplicateCustomer360Main ---' + ex.getLineNumber()+ ' ex message -- ' + ex); 
        }
    }
    public void finish(Database.BatchableContext BC){
    }
}