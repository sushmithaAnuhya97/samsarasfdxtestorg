public class Customer360StagingTriggerHandler{

    static gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    static gslib_ILogger thisLogger = thisModuleLogger.getLogger();
    // private static final list<String> fieldsToPopulate = new list<String>{
    //                                             //Discount Fields
    //                                             'LIC_AG2_Discount__c',
    //                                             'LIC_AG4P_Discount__c',
    //                                             'LIC_AG4_Discount__c',
    //                                             'LIC_AG_PWR_PLUS_Discount__c',
    //                                             'LIC_AG_PWR_REEFER_Discount__c',
    //                                             'LIC_AG_PWR_REEFER_KIT_Discount__c',
    //                                             'LIC_AT_Discount__c',
    //                                             'LIC_Advanced_Support_Discount__c',
    //                                             'LIC_CM1_Discount__c',
    //                                             'LIC_CM1_PRO_Discount__c',
    //                                             'LIC_CM2_Discount__c',
    //                                             'LIC_CM2_PRO_Discount__c',
    //                                             'LIC_CM_AHD1_Discount__c',
    //                                             'LIC_CM_ANLG_Discount__c',
    //                                             'LIC_CM_STRM_Discount__c',
    //                                             'LIC_CRGO_Discount__c',
    //                                             'LIC_DM11_Discount__c',
    //                                             'LIC_EI_A_Discount__c',
    //                                             'LIC_EI_SEC_Discount__c',
    //                                             'LIC_EM_Discount__c',
    //                                             'LIC_FORMS_Discount__c',
    //                                             'LIC_MEM_Discount__c',
    //                                             'LIC_PLTFM_PRO_Discount__c',
    //                                             'LIC_SC11_Discount__c',
    //                                             'LIC_SC1_Discount__c',
    //                                             'LIC_SC21_Discount__c',
    //                                             'LIC_SVC_CM_Review_ENT_Discount__c',
    //                                             'LIC_TRAINING_Discount__c',
    //                                             'LIC_TRLR_ESS_Discount__c',
    //                                             'LIC_TRLR_PREM_Discount__c',
    //                                             'LIC_TRLR_PREM_KIT_Discount__c',
    //                                             'LIC_VG_Discount__c',
    //                                             'LIC_VG_FN_ADDON_Discount__c',
    //                                             'LIC_VG_LD_Discount__c',
    //                                             'LIC_VG_PRO_Discount__c',
    //                                             'LIC_VG_PS_Discount__c',
    //                                             'LIC_CM_PRO_Discount__c',
    //                                             'LIC_VG_COMPLIANCE_Discount__c',

    //                                             //MUP Fields
    //                                             'LIC_AG2_ENT_MUP__c',
    //                                             'LIC_AG4P_ENT_MUP__c',
    //                                             'LIC_AG4_ENT_MUP__c',
    //                                             'LIC_AG_PWR_PLUS_MUP__c',
    //                                             'LIC_AG_PWR_REEFER_KIT_MUP__c',
    //                                             'LIC_AG_PWR_REEFER_MUP__c',
    //                                             'LIC_AT_TAG_MUP__c',
    //                                             'LIC_Advanced_Support_MUP__c',
    //                                             'LIC_CM1_ENT_MUP__c',
    //                                             'LIC_CM1_PRO_MUP__c',
    //                                             'LIC_CM2_ENT_MUP__c',
    //                                             'LIC_CM2_PRO_MUP__c',
    //                                             'LIC_CM_AHD1_MUP__c',
    //                                             'LIC_CM_ANLG_MUP__c',
    //                                             'LIC_CM_STRM_MUP__c',
    //                                             'LIC_CRGO_ENT_MUP__c',
    //                                             'LIC_DM11_ENT_MUP__c',
    //                                             'LIC_EI_A_MUP__c',
    //                                             'LIC_EI_EU_MUP__c',
    //                                             'LIC_EI_SEC_MUP__c',
    //                                             'LIC_EM_ENT_MUP__c',
    //                                             'LIC_FORMS_MUP__c',
    //                                             'LIC_MEM_ENT_MUP__c',
    //                                             'LIC_PLTFM_PRO_MUP__c',
    //                                             'LIC_SC1_MUP__c',
    //                                             'LIC_SVC_CM_Review_ENT_MUP__c',
    //                                             'LIC_TRAINING_MUP__c',
    //                                             'LIC_TRLR_ESS_MUP__c',
    //                                             'LIC_TRLR_PREM_KIT_MUP__c',
    //                                             'LIC_TRLR_PREM_MUP__c',
    //                                             'LIC_VG_ENT_MUP__c',
    //                                             'LIC_VG_FN_ADDON_MUP__c',
    //                                             'LIC_VG_LD_MUP__c',
    //                                             'LIC_VG_PRO_MUP__c',
    //                                             'LIC_VG_PS_MUP__c',
    //                                             'LIC_CM_PRO_MUP__c',
    //                                             'LIC_VG_COMPLIANCE_MUP__c',
    //                                             'Account__c',
    //                                             'CurrencyIsoCode',
    //                                             'CM_Tier__c',
    //                                             'LIC_AT_TAG__c',
    //                                             'LIC_CM1_PRO__c',
    //                                             'LIC_CM2_PRO__c',
    //                                             'LIC_PLTFM_PRO__c',
    //                                             'LIC_VG_PRO__c',
    //                                             'P_P_Pilot_Customer__c',
    //                                             'Platform_Type__c',
    //                                             'VG_Basic_Purchased__c',
    //                                             'VG_ENT_Purchased__c',
    //                                             'VG_Platform_Tier__c',
    //                                             'VG_Tier__c',
    //                                             'LIC_CM_PRO__c'
    //                                             //'Platform_Premium__c',
    //                                             //'Push_to_Webstore__c',
    //                                             //'VG54_purchased__c',
    //                                             //'Webstore_Eligibility_Limitation__c'
    //                                             //'Webstore_Sync_Error__c'
    //                                             //'BigCommerce_Id__c',
    //                                             //'Discount_Reviewed__c',
    //                                             //'Hide_Licenses_in_Webstore__c',
    //                                             //'AE_Notes__c',
    //                                             //'Payment_Terms__c'
    //                                             //'Latest_Active_Contract_Historical__c',
    //                                             // 'Opt_In__c',
    //                                             //'Contract_Vehicle__c',
    //                                             //'CM_Platform_Tier__c',
    //                                             //Header Fields
    //                                         };

    public static void afterUpdate(list<Customer_360_Staging__c> newC360StagingList, map<Id, Customer_360_Staging__c> oldC360StagingMap){

        copyDataToC360OnApproval(newC360StagingList, oldC360StagingMap);
    }

    private static void copyDataToC360OnApproval(list<Customer_360_Staging__c> newC360StagingList, map<Id, Customer_360_Staging__c> oldC360StagingMap){

        map<Id, Customer_360__c> accToc360RecsToInsert = new map<Id, Customer_360__c>();
        list<Account> accsToUpdate = new list<Account>();

        for(Customer_360_Staging__c c360StagingRec :newC360StagingList){

            if(!c360StagingRec.Approved__c || oldC360StagingMap.get(c360StagingRec.Id).Approved__c) {continue;}
            
            accToc360RecsToInsert.put(c360StagingRec.Account__c, populateNewC360Records(c360StagingRec));
            accsToUpdate.add(new Account(Id = c360StagingRec.Account__c, C360_Processed__c = true));
        }

        if(accToc360RecsToInsert.isEmpty()) return;

        List<Customer_360__c> c360ToDelete = new list<Customer_360__c>([SELECT Id, BigCommerce_Id__c,SOT__c, Account__c,Push_To_Webstore__c,  
                                            Discount_Reviewed__c, Hide_Licenses_in_Webstore__c, Platform_Premium__c,
                                            Opt_In__c, CM_Platform_Tier__c, Contract_Vehicle__c, 
                                            Latest_Active_Contract_Historical__c, Webstore_Eligibility_Limitation__c, 
                                            Webstore_Sync_Error__c, AE_Notes__c, LIC_CM_PRO__c 
                                            FROM Customer_360__c WHERE Account__c in :accToc360RecsToInsert.keySet()]);


        for(Customer_360__c c360Recs :c360ToDelete){

            if(!accToc360RecsToInsert.containsKey(c360Recs.Account__c) || !c360Recs.SOT__c){continue;}

            if(accToc360RecsToInsert.get(c360Recs.Account__c).BigCommerce_Id__c == null && c360Recs.BigCommerce_Id__c != null) accToc360RecsToInsert.get(c360Recs.Account__c).BigCommerce_Id__c = c360Recs.BigCommerce_Id__c;
            if(accToc360RecsToInsert.get(c360Recs.Account__c).AE_Notes__c == null && c360Recs.AE_Notes__c != null) accToc360RecsToInsert.get(c360Recs.Account__c).AE_Notes__c = c360Recs.AE_Notes__c;
            if(accToc360RecsToInsert.get(c360Recs.Account__c).Webstore_Sync_Error__c == null && c360Recs.Webstore_Sync_Error__c != null) accToc360RecsToInsert.get(c360Recs.Account__c).Webstore_Sync_Error__c = c360Recs.Webstore_Sync_Error__c;
            if(accToc360RecsToInsert.get(c360Recs.Account__c).Webstore_Eligibility_Limitation__c == null && c360Recs.Webstore_Eligibility_Limitation__c != null) accToc360RecsToInsert.get(c360Recs.Account__c).Webstore_Eligibility_Limitation__c = c360Recs.Webstore_Eligibility_Limitation__c;
            if(accToc360RecsToInsert.get(c360Recs.Account__c).Latest_Active_Contract_Historical__c == null && c360Recs.Latest_Active_Contract_Historical__c != null) accToc360RecsToInsert.get(c360Recs.Account__c).Latest_Active_Contract_Historical__c = c360Recs.Latest_Active_Contract_Historical__c;
            if(accToc360RecsToInsert.get(c360Recs.Account__c).Contract_Vehicle__c == null && c360Recs.Contract_Vehicle__c != null) accToc360RecsToInsert.get(c360Recs.Account__c).Contract_Vehicle__c = c360Recs.Contract_Vehicle__c;
            if(accToc360RecsToInsert.get(c360Recs.Account__c).CM_Platform_Tier__c == null && c360Recs.CM_Platform_Tier__c != null) accToc360RecsToInsert.get(c360Recs.Account__c).CM_Platform_Tier__c = c360Recs.CM_Platform_Tier__c;
            accToc360RecsToInsert.get(c360Recs.Account__c).Push_To_Webstore__c = c360Recs.Push_To_Webstore__c;
            accToc360RecsToInsert.get(c360Recs.Account__c).Opt_In__c = c360Recs.Opt_In__c;
            accToc360RecsToInsert.get(c360Recs.Account__c).Platform_Premium__c = c360Recs.Platform_Premium__c;
            accToc360RecsToInsert.get(c360Recs.Account__c).Discount_Reviewed__c = c360Recs.Discount_Reviewed__c;
            accToc360RecsToInsert.get(c360Recs.Account__c).Hide_Licenses_in_Webstore__c = c360Recs.Hide_Licenses_in_Webstore__c;
            accToc360RecsToInsert.get(c360Recs.Account__c).LIC_CM_PRO__c = c360Recs.LIC_CM_PRO__c;
        }
        
        Savepoint sp = Database.setSavepoint(); 

        try{

            delete c360ToDelete;

            insert accToc360RecsToInsert.values();

            TriggerHandler.bypass('GS_AccountTriggerHandler');
            
            update accsToUpdate;
            
            TriggerHandler.clearAllBypasses();

        }catch(Exception ex){
            Database.rollback(sp);
            thisLogger.logError('Failure in Customer360StagingTriggerHandler.copyDataToC360OnApproval', new SamsaraLoggerObjectMVP(ex,accToc360RecsToInsert.keySet()));
        }finally{
            thisLogger.dispatch();
        }
    }

    private static Customer_360__c populateNewC360Records(Customer_360_Staging__c c360Staging){

        Customer_360__c c360ToReturn = new Customer_360__c();

        for(Schema.FieldSetMember fm : Schema.SObjectType.Customer_360_Staging__c.fieldSets.getMap().get('Discount_MUP_Fields').getFields() )
        {
            c360ToReturn.put( fm.getFieldPath(), c360Staging.get(fm.getFieldPath() ) );
        }

        c360ToReturn.SOT__c = true;

        return c360ToReturn;
    }
}