/**********************************************************************
Name: AsyncApexLoggerService
Test Class: AsyncApexLoggerService_Test
----------------------------------------------------------------------
Purpose: This class contains the method for creating Async Apex loggers
----------------------------------------------------------------------
History  

Ticket           AUTHOR              DATE               DETAIL                                      
GTMS-20016  `	Vijaychandra        4/3/24            Created as part of OVA full launch Hypercare ticket to creatin Async Apex loggers
**********************************************************************/
public Without Sharing class AsyncApexLoggerService {
    Async_Apex_Logging_Switch__mdt asyncLogSwitch = Async_Apex_Logging_Switch__mdt.getInstance('OVA_Log_Switch');
    public List<Id> createAsyncApexLogger(string jobId, string jobName, string jobType){
        List<Id> loggerIds = new List<Id>();
        Async_Apex_Logger__c asyncLogger = new Async_Apex_Logger__c();
        asyncLogger.Job_Name__c = jobName;
        asyncLogger.Job_Id__c = jobId;
        asyncLogger.Type__c = jobType;
        
        loggerIds.add(insertAsyncApexLogger(new List<Async_Apex_Logger__c>{asyncLogger})[0].Id);
        
        return loggerIds;
    }
    
    public Map<Id,Id> createAsyncApexLogger(string jobId, string jobName, string jobType, List<Opportunity> oppList){
        Map<Id,Id> oppIdLoogerIdMap = new Map<Id,Id>();
        List<Async_Apex_Logger__c> loggerList = new List<Async_Apex_Logger__c>();
        for(Opportunity opp: oppList){
            Async_Apex_Logger__c asyncLogger = new Async_Apex_Logger__c();
            asyncLogger.Job_Name__c = jobName;
            asyncLogger.Job_Id__c = jobId;
            asyncLogger.Type__c = jobType;
            asyncLogger.Opportunity_Id__c = opp.Id;
            asyncLogger.Opportunity_AVP_Name__c = opp.Owner_AVP_Name_Copy__c;
            //asyncLogger.Opportunity_Stage_Name__c = opp.StageName;
            //asyncLogger.Opportunity_Tracking__c = opp.Opportunity_Tracking__c;
            if(!asyncLogSwitch.Stop_OVA_Fields_Logging__c){
                string ovaEntryCriteria = 'Name: '+opp.Name+'; Stage Name: '+opp.StageName+'; Probability: '+opp.Probability+''
                                            +'; SBQQ__PrimaryQuote__c: '+opp.SBQQ__PrimaryQuote__c+'; Payment_Terms__c: '+opp.Payment_Terms__c+''
                                            +'; Initial_Payment_Terms__c: '+opp.Initial_Payment_Terms__c+'; Owner_Segment__c: '+opp.Owner_Segment__c+''
                                            +'; Custom_Schedule__c: '+opp.Custom_Schedule__c+'; Type: '+opp.Type+'; Owner_Role_Copy__c: '+opp.Owner_Role_Copy__c+''
                                            +'; Owner_Manager_Role_Copy__c: '+opp.Owner_Manager_Role_Copy__c+'; Finance_Segment__c: '+opp.Finance_Segment__c+''
                                            +'; Is_Webstore_Upsell_Opportunity__c: '+opp.Is_Webstore_Upsell_Opportunity__c+'; Payment_Type__c: '+opp.Payment_Type__c+''
                                            +'; Selected_Payment_Type__c: '+opp.Selected_Payment_Type__c+'; SBQQ__Renewal__c: '+opp.SBQQ__Renewal__c+''
                                            +'; Buyout_Opportunity__c: '+opp.Buyout_Opportunity__c+'; Subsidy_Opportunity__c: '+opp.Subsidy_Opportunity__c+''
                                            +'; Blended_Discount__c: '+opp.Blended_Discount__c+'; DCA_Enabled__c: '+opp.DCA_Enabled__c+'; OwnerId: '+opp.OwnerId+''
                                            +'; Owner_Manager_Name_Copy__c: '+opp.Owner_Manager_Name_Copy__c+'; Owner_Director_Name_Copy__c: '+opp.Owner_Director_Name_Copy__c+''
                                            +'; CurrencyIsoCode: '+opp.CurrencyIsoCode+'; Opportunity_Tracking__c: '+opp.Opportunity_Tracking__c;
                asyncLogger.OVA_Entry_Criteria__c = ovaEntryCriteria;
            }
            loggerList.add(asyncLogger);
        }
        
        if(!loggerList.isEmpty()){
            List<Async_Apex_Logger__c> loggerResultList = insertAsyncApexLogger(loggerList);
            if(!loggerResultList.isEmpty()){
                for(Async_Apex_Logger__c logRec:loggerResultList){
                	oppIdLoogerIdMap.put(logRec.Opportunity_Id__c,logRec.Id);
            	}
            }
            
        }
        
        return oppIdLoogerIdMap;
    }
    
    public List<Async_Apex_Logger__c> insertAsyncApexLogger(List<Async_Apex_Logger__c> loggerList){
        List<Id> loggerIds = new List<Id>();
        if(!loggerList.isEmpty()){
            insert loggerList;
        }
        return loggerList;
    }
    
    public void updateOVAFailuresInAsyncLogger(List<Id> loggerIds, Map<Id,String> errorMap){
        List<Async_Apex_Logger__c> aalList = new List<Async_Apex_Logger__c>();
        for(Async_Apex_Logger__c aal:[SELECT Id,Status__c, Failure_Reason__c, Opportunity_Id__c FROM Async_Apex_Logger__c 
                                      WHERE Opportunity_Id__c IN :errorMap.keySet() AND Id IN :loggerIds]){
          aal.Status__c = 'Failed';
          aal.Failure_Reason__c = errorMap.get(aal.Opportunity_Id__c) != null ? errorMap.get(aal.Opportunity_Id__c) : 'OVA Process Fialed. Reason didnt added in the batch';
          
         if(aal.Status__c == 'Failed'){
           	 aal.OVA_Final_Status__c = 'Failed';	
        	}
          aalList.add(aal);                                
       	}
        
        if(!aalList.isEmpty()){update aalList;}
    }
    
    public Async_Apex_Logger__c updateAsyncLogger(Async_Apex_Logger__c asyncLogger, Opportunity opp, List<String> kickbackReasons, List<String> kickbackResolutions, string creditAnalystNote){
        if(!asyncLogSwitch.Stop_OVA_Fields_Logging__c){
            List<string> ovaOppFields = String.valueOf(SYSTEM.LABEL.Opp_Fields_For_OVA_Logging).split(';');
            List<string> ovaOppRelatedFields = String.valueOf(SYSTEM.LABEL.Opp_Related_Fields_For_OVA_Logging).split(';');
            List<string> ovaOppRelatedFieldsSet2 = String.valueOf(SYSTEM.LABEL.Opp_Related_Fields_For_OVA_Logging_Set_2).split(';');
            List<String> docusignFields = string.valueOf(SYSTEM.LABEL.Docusign_Fields_for_OVA_Logging).split(';');
            string ovaFieldValue;
            for(string fieldName: ovaOppFields){
                ovaFieldValue+= fieldName+': '+ExtractFieldValues(opp,fieldName)+';';
            }
            for(string fieldName: ovaOppRelatedFields){
                ovaFieldValue+= fieldName+': '+ExtractFieldValues(opp,fieldName)+';';
            }
            for(string fieldName: ovaOppRelatedFieldsSet2){
                ovaFieldValue+= fieldName+': '+ExtractFieldValues(opp,fieldName)+';';
            }
            if(!opp.R00N80000002fD9vEAE__r.isEmpty()){
                for(dsfs__Docusign_Status__c docusign:opp.R00N80000002fD9vEAE__r){
                    for(string fieldName: docusignFields){
                         ovaFieldValue+= fieldName+': '+ExtractFieldValues(docusign,fieldName)+';';
                    }
                }
            }
            asyncLogger.Opportunity_Field_Values__c = ovaFieldValue;
        }
        asyncLogger.OVA_KB_Reasons__c = (!kickbackReasons.isEmpty()) ? string.join(kickbackReasons,';'):'No Reasons';
        asyncLogger.OVA_KB_Resolutions__c = (!kickbackResolutions.isEmpty()) ? string.join(kickbackResolutions,';'):'No Resolutions';
        asyncLogger.OVA_OM_Review_Validations__c = creditAnalystNote;
        asyncLogger.Opportunity_Stage_Name__c = opp.StageName;
        asyncLogger.Opportunity_Tracking__c = opp.Opportunity_Tracking__c;
        asyncLogger.Status__c = 'Went through OVA';
        if(asyncLogger.Status__c == 'Went through OVA' && asyncLogger.OVA_KB_Reasons__c == 'No Reasons' && asyncLogger.OVA_OM_Review_Validations__c == null){
            asyncLogger.OVA_Final_Status__c = 'Successfully E2E processed';
        }
        else if(asyncLogger.Status__c == 'Went through OVA' && asyncLogger.OVA_KB_Reasons__c != 'No Reasons' && asyncLogger.OVA_KB_Resolutions__c != 'No Resolutions'){
            asyncLogger.OVA_Final_Status__c = 'AE Kickback';
        }
        else if(asyncLogger.Status__c == 'Went through OVA' && asyncLogger.OVA_OM_Review_Validations__c != null){
            asyncLogger.OVA_Final_Status__c = 'OM Review';
        }
        return asyncLogger;
        
    }
    
    public static String ExtractFieldValues(sObject sb, string fieldAPIName){
        string fvalue='';
        if(fieldAPIName.contains('.')){
            List<string> splitedFields = fieldAPIName.split('\\.');
            try{
                for(integer i=0;i<splitedFields.size()-1;i++){
                    sb=sb.getSobject(splitedFields[i]);   
                }
                fvalue = string.valueof(sb.get(splitedFields[splitedFields.size()-1]));
            }catch(exception ex){
               fvalue='null';
            }
            
        }else if(sb.get(fieldAPIName)!=null){
            fvalue = string.valueOf(sb.get(fieldAPIName));
        }
        return fvalue;
    }
}