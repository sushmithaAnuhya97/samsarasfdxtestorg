/**********************************************************************
Name: OrderValidationServiceAutomation
Test Class: OrderValidationServiceAutomationTest
-----------------------------------------------------------------------
Purpose: This class contains the logic to check entry criteria for Order Validation
-----------------------------------------------------------------------
History  

Ticket       AUTHOR              DATE               DETAIL                       
          Sai Ganesh Repaka               
GTMS-13378  Vijaychandra      9/13/23      Exteded OV functionality to all user in NA by removing custom settings conditions
GTMS-16031  Vijaychandra      10/18/23    Extended OV logic to NA and EMEA by remvoing currency condtions
GTMS-16283  Vijaychandra      10/19/23    Removed payment terms conditions, added new conditions and added Subsidy product code condition.
GTMS-16320   Vijaychandra      10/27/23    Added Net Terms pilot roll out for US/CA/MX and condtion for DIA
GTMS-17891	Vijaychandra	  1/9/24	  Added an logic for entry criteria to exclude Promo, Reprocessing, Virtual Return Opportunites	
GTMS-17890	Vijaychandra	2/1/24		Commenting pilot logic to normalize the OVA logic of Net Payment terms
GTMS-16637	Vijaychandra			12/07/23		Added DCA pilot role out check in a saperate method.
GTMS-19053	Vijaychandra		02/28/24		updated DCA rollout logic as per CR by the business.
GTMS-20818	Vijaychandra		20/05/24	Added Mexico and First Purchase check in to OVA entry criteria
GTMS-27234. Rodrigo.            23/05/25 updated the condition

***********************************************************************/
public class OrderValidationServiceAutomation {
    
    public void runAfter(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap){        
        Set<Id> recordsToProcess = new Set<Id>();
        // added for GTMS-29126 starts here
        Set<Id> allOpptyId = new Set<Id>();
        Set<Id> allOpptyIdWithSubsidy = new Set<Id>();
        Map<Id, Opportunity> currOppMapLoc = new Map<Id, Opportunity>();
        for (Opportunity opp : newOppList){
            allOpptyId.add(opp.Id);
            currOppMapLoc.put(opp.Id, opp);
        }
        
        List<OpportunityLineItem> allOptyLine = [SELECT Id,OpportunityId,Opportunity.SBQQ__PrimaryQuote__r.Is_Promo__c,Opportunity.SBQQ__PrimaryQuote__r.SBQQ__BillingCountry__c,
                                         Opportunity.First_Purchase__c,Opportunity.Owner_Role_Copy__c, ProductCode,Opportunity.Balance_Due__c,
                                         Opportunity.SBQQ__AmendedContract__c, opportunity.CurrencyIsoCode FROM OpportunityLineItem 
                                         WHERE OpportunityId IN :allOpptyId ];
        for(OpportunityLineItem oli:allOptyLine)  {
            Opportunity oppOld = oldOppMap.get(oli.OpportunityId);
            Opportunity oppCurr = currOppMapLoc.get(oli.OpportunityId);
            // add the condition to check
            if(oli.ProductCode == SYSTEM.Label.Insurance_Subsidy_Product_Code && oppOld.StageName != 'Closing' 
               && oppCurr.StageName == 'Closing' && oppOld.Probability < oppCurr.Probability && 
                           oppCurr.SBQQ__PrimaryQuote__c != null)
                allOpptyIdWithSubsidy.add(oli.OpportunityId);
        }
        
        if (!allOpptyIdWithSubsidy.isEmpty()){
            FOR(Opportunity opp : newOppList) {
                if(allOpptyIdWithSubsidy.contains(opp.Id)) {
                    opp.CVS_Review__c = true;
                    opp.OM_Review_Reason_Code__c = 'Deal was routed to OM review because it has an Insurance Subsidy SKU.';
                }
            }
            //Database.executeBatch(new OrderValidationAutomation_Batch(allOpptyIdWithSubsidy, 'Subsidy Validation'), 1);
        }
        // added for GTMS-29126 ends here    
        
        for (Opportunity opp : newOppList){
            
            if (checkingmaincriteria1(opp, oldOppMap.get(opp.Id))) recordsToProcess.add(opp.Id);
        }

        
    //10/25/23 Vijaychandra --START-- (GTMS-16283): Adding INS-SUBSIDY Product code check in entry criteria
        if (!recordsToProcess.isEmpty()){
            //AND ProductCode =: SYSTEM.Label.Insurance_Subsidy_Product_Code
            For(OpportunityLineItem oli: allOptyLine){
                //20/05/24 Vijaychandra (GTMS-20818): Added Mexico and First Purchase check in to OVA entry criteria                            
                Boolean isMxCountry = oli.Opportunity.SBQQ__PrimaryQuote__r.SBQQ__BillingCountry__c == 'Mexico';
                Boolean isMXRole = oli.Opportunity.Owner_Role_Copy__c != null ? oli.Opportunity.Owner_Role_Copy__c.contains('MX') : false;                          
                //Changed from here GMTs = 23769
                Boolean isMxnOpp = (oli.opportunity.First_Purchase__c || (oli.opportunity.SBQQ__AmendedContract__c != null && oli.Opportunity.Balance_Due__c != null && oli.Opportunity.Balance_Due__c >= decimal.valueOf(System.Label.Balance_due_value_of_OVA) && string.valueOf(oli.opportunity.CurrencyIsoCode) == 'MXN')) ? ( isMXCountry || isMXRole) : false; 
                //Boolean isMxnOpp = oli.opportunity.First_Purchase__c ? (isMXCountry || isMXRole) : false;                             
                if(oli.ProductCode == SYSTEM.Label.Insurance_Subsidy_Product_Code || oli.Opportunity.SBQQ__PrimaryQuote__r.Is_Promo__c || isMxnOpp){
                    if(recordsToProcess.Contains(oli.OpportunityId)) recordsToProcess.remove(oli.OpportunityId);
                }
                
            }
        }
        //--END-- (GTMS-16283)
        
        if(!recordsToProcess.isEmpty()){
            
            Database.executeBatch(new OrderValidationAutomation_Batch(recordsToProcess), 1);}
            
            //removed for GTMS-13378 --- start
            //Queueable execution is error out because order validation logic updating the quote start date which triggers quote recalculation.
            /*
            DMLWrapper.doInsert(
                new OrderValidationServiceAutomationAsync().prepareAsyncRequests(
                    JSON.serialize(new OrderValidationServiceAutomationAsync.Options('Finance Validation')), recordsToProcess)
            );
            */
            //removed for GTMS-13378 --- end
    }

    /* private Boolean orderValidationExecutionCriteria(Opportunity opp, Opportunity oldOpp) {
        // Clause is reversed
        String format = 'ORDER VALIDATION SERVICE::: {0} {1} {2} {3}';
        System.debug(String.format(format, new List<String>{'StageName', '==', 'Purchase', String.valueOf(oldOpp.StageName == 'Purchase')}));
        System.debug(String.format(format, new List<String>{'StageName', '==', 'Closing', String.valueOf(opp.StageName == 'Closing')}));
        System.debug(String.format(format, new List<String>{'StageName', '==', 'Purchase OR Closing', String.valueOf(oldOpp.StageName == 'Purchase' && opp.StageName == 'Closing')}));
        System.debug(String.format(format, new List<String>{'Custom_Schedule__c', '==', 'true', String.valueOf(opp.Custom_Schedule__c == true)}));
        System.debug(String.format(format, new List<String>{'Type', '!=', 'Revenue Opportunity', String.valueOf(opp.Type != 'Revenue Opportunity')}));
        System.debug(String.format(format, new List<String>{'Owner_Role_Copy__c', 'CONTAINS', 'SLED', String.valueOf(opp.Owner_Role_Copy__c.contains('SLED'))}));
        System.debug(String.format(format, new List<String>{'Owner_Manager_Role_Copy__c', 'CONTAINS', 'SLED', String.valueOf(opp.Owner_Manager_Role_Copy__c.contains('SLED'))}));
        System.debug(String.format(format, new List<String>{'Finance_Segment__c', '==', 'Enterprise', String.valueOf(opp.Finance_Segment__c == 'Enterprise')}));
        System.debug(String.format(format, new List<String>{'Is_Webstore_Upsell_Opportunity__c', '==', 'false', String.valueOf(opp.Is_Webstore_Upsell_Opportunity__c == false)}));
        System.debug(String.format(format, new List<String>{'FinanceSegment and Is Webstore', '==', 'something', String.valueOf((opp.Finance_Segment__c == 'Enterprise' && opp.Is_Webstore_Upsell_Opportunity__c == false))}));
        System.debug(String.format(format, new List<String>{'Payment_Type__c', '==', 'Reseller', String.valueOf(opp.Payment_Type__c == 'Reseller')}));
        System.debug(String.format(format, new List<String>{'Payment_Type__c', '==', 'Finance Partner', String.valueOf(opp.Payment_Type__c == 'Finance Partner')}));
        System.debug(String.format(format, new List<String>{'SBQQ__Renewal__c', '==', 'true', String.valueOf(opp.SBQQ__Renewal__c == true)}));
        System.debug(String.format(format, new List<String>{'Name', '==', 'INVENTORYSPLIT', String.valueOf(opp.Name == 'INVENTORYSPLIT')}));
        System.debug('----- -> '+(
            !(oldOpp.StageName == 'Purchase' && opp.StageName == 'Closing')
          || opp.Custom_Schedule__c == true
          || opp.Type != 'Revenue Opportunity'
          || (opp.Owner_Role_Copy__c != null && opp.Owner_Role_Copy__c.contains('SLED'))
          || (opp.Owner_Manager_Role_Copy__c != null && opp.Owner_Manager_Role_Copy__c.contains('SLED'))
          || (opp.Finance_Segment__c == 'Enterprise' && opp.Is_Webstore_Upsell_Opportunity__c == false)
          || opp.Payment_Type__c == 'Reseller'
          || opp.Payment_Type__c == 'Finance Partner'
          || opp.SBQQ__Renewal__c == true
          || opp.Name == 'INVENTORYSPLIT'
      ));
        return !(
              !(oldOpp.StageName == 'Purchase' && opp.StageName == 'Closing')
            || opp.Custom_Schedule__c == true
            || opp.Type != 'Revenue Opportunity'
            || (opp.Owner_Role_Copy__c != null && opp.Owner_Role_Copy__c.contains('SLED'))
            || (opp.Owner_Manager_Role_Copy__c != null && opp.Owner_Manager_Role_Copy__c.contains('SLED'))
            || (opp.Finance_Segment__c == 'Enterprise' && opp.Is_Webstore_Upsell_Opportunity__c == false)
            || opp.Payment_Type__c == 'Reseller'
            || opp.Payment_Type__c == 'Finance Partner'
            || opp.SBQQ__Renewal__c == true
            || opp.Name == 'INVENTORYSPLIT'
        );
    } */


    public Boolean checkingmaincriteria1(Opportunity opp, Opportunity oppOldMap) {
        Boolean isTrue = True;
        
    /*
        Order_Validation_Setting__c serviceSettings = Order_Validation_Setting__c.getInstance(opp.OwnerId);
        if (serviceSettings == null) serviceSettings = new Order_Validation_Setting__c(Owner_Exception__c = false,Disable_Service__c = false);

        System.debug('//|| StageName ->                  '+!(oppOldMap.StageName == 'Purchase' && opp.StageName == 'Closing'));
        System.debug('//|| Owner_Segment__c ->           '+(opp.Owner_Segment__c == 'AE1'));
        System.debug('//|| Custom_Schedule__c ->         '+(opp.Custom_Schedule__c == True));
        System.debug('//|| Type ->                       '+(opp.Type != 'Revenue Opportunity'));
        System.debug('//|| Owner_Role_Copy__c ->         '+(opp.Owner_Role_Copy__c != NULL && opp.Owner_Role_Copy__c.contains('SLED')));
        System.debug('//|| Owner_Manager_Role_Copy__c -> '+(opp.Owner_Manager_Role_Copy__c != NULL && opp.Owner_Manager_Role_Copy__c.contains('SLED')));
        System.debug('//|| Finance_Segment__c ->         '+(opp.Finance_Segment__c == 'Enterprise' && opp.Is_Webstore_Upsell_Opportunity__c == FALSE) );
        System.debug('//|| Payment_Type__c ->            '+(opp.Payment_Type__c == 'Reseller'));
        System.debug('//|| Payment_Type__c ->            '+(opp.Payment_Type__c == 'Finance Partner'));
        System.debug('//|| SBQQ__Renewal__c ->           '+(opp.SBQQ__Renewal__c == True));
        System.debug('//|| Name ->                       '+(opp.Name == 'INVENTORYSPLIT'));
        System.debug('//|| Dismiss Full Criteria ---->   '+this.orderValidationDismissCriteria(opp, oppOldMap));
        System.debug('//|| SETTINGS Owner  ->            '+this.settingsOwnerExceptionCriteria(opp));
        System.debug('//|| Result -> '+(this.orderValidationDismissCriteria(opp, oppOldMap)  || this.settingsOwnerExceptionCriteria(opp)));

        if (serviceSettings.Disable_Service__c) return false;
        // This exception has been causing LOOPS. It needs to be debugged with more time.
        else*/
        //10/27/23 Vijaychanadra (GTMS-16320):to remove OV functionlaity quickly for EMEA or for any other currencies 
        Boolean ovSwitch = !(OV_Region_Switch__mdt.getInstance(opp.CurrencyIsoCode) != null ? OV_Region_Switch__mdt.getInstance(opp.CurrencyIsoCode).OV_Switch__c == true : true);
        
        if ((this.settingsOwnerExceptionCriteria(opp) && this.dcaOwnerExceptionCriteria(opp)) || this.orderValidationDismissCriteria(opp, oppOldMap) 
            ||  opp.createdDate < DateTime.valueOf(System.Label.Enable_Order_Automation_Validation) 
            || ovSwitch ) { 
            isTrue = False;
        }
        return isTrue;
    }
  // Made changes as per ticket GTMS-13203(Order validation automation pilot phase 3).
    private Boolean orderValidationDismissCriteria(Opportunity opp, Opportunity oppOldMap){
       
        Boolean check = (!(oppOldMap.StageName != 'Closing' && opp.StageName == 'Closing' && oppOldMap.Probability < opp.Probability && opp.SBQQ__PrimaryQuote__c != null)
                        || outOfScopeCheck(opp));
                        //10/23/23 Vijaychandra--START-- (GTMS-16283): commented in OV phase 2 for code reuse.
                        /**
                         *  
                        opp.Owner_Segment__c == 'AE1'|| opp.Custom_Schedule__c == True || opp.Type != 'Revenue Opportunity'|| (opp.Owner_Role_Copy__c != Null && opp.Owner_Role_Copy__c.contains('SLED'))
                        || (opp.Owner_Manager_Role_Copy__c != Null && opp.Owner_Manager_Role_Copy__c.contains('SLED'))|| !((opp.Finance_Segment__c == 'Enterprise' && opp.Is_Webstore_Upsell_Opportunity__c == TRUE)|| opp.Finance_Segment__c == 'Mid Market') || opp.Payment_Type__c == 'Reseller' || opp.Payment_Type__c == 'Finance Partner'
                        || opp.SBQQ__Renewal__c == True|| String.valueOf(opp.Name).Contains('INVENTORYSPLIT') || opp.Selected_Payment_Type__c == 'Direct Quarterly'
                        //10/19/23 Vijaychandra --START-- (GTMS-16283) :Added new conditions for the out of scope functionality and commented payment terms condition
                        ||opp.Buyout_Opportunity__c != null || opp.Subsidy_Opportunity__c != null || ((opp.CurrencyIsoCode == 'GBP'||opp.CurrencyIsoCode == 'EUR') && opp.VAT_Validation_Status__c != 'Confirmed'));
                //(opp.Payment_Terms__c != 'Due in advance' || opp.Initial_Payment_Terms__c != 'Due in advance')
                        //--END-- (GTMS-16283)
                        */
                        //--END-- (GTMS-16283)
        
        return check;
    }
    //10/23/23 Vijaychandra --START-- (GTMS-16283)(GTMS-16286): Created for Order Validation out of scope entry criteria check.
    /***********
     * Description : out of scope criteria check for Order Validation.
     * @Param: opp (Opportunity record)
  *************/
    public Boolean outOfScopeCheck(Opportunity opp){
        string pTerms = opp.Payment_Terms__c != null ? opp.Payment_Terms__c : '';//GTMS-16320
        string ipTerms = opp.initial_Payment_Terms__c != null ? opp.Initial_Payment_Terms__c : '';//GTMS-16320
        Opportunity oppFromHelper = OpportunityHelperContext.oppFields != null && !OpportunityHelperContext.oppFields.isempty() && OpportunityHelperContext.oppFields.containskey(opp.Id) ? OpportunityHelperContext.oppFields.get(opp.Id) : null;
        Automation_Settings__c mexicoWebStoreCheck = Automation_Settings__c.getInstance('Mexico Web Store Checks');
    	Boolean isMexicoWebStoreChecksDisabled = mexicoWebStoreCheck != null && mexicoWebStoreCheck.Disabled__c == true;
        Boolean isMexicoCurrency = opp.CurrencyIsoCode == 'MXN';


        Boolean isExcludedByNewRule = ((opp.Finance_Segment_Stamp__c != null && opp.Finance_Segment_Stamp__c == 'SMB') || 
                                      (oppFromHelper?.Owner?.UserRole?.Name?.contains('AE1') == true || oppFromHelper?.Owner?.UserRole?.Name?.contains('CML') == true) || 
                                     (opp.Segment_Sales_Role__c != null && (opp.Segment_Sales_Role__c == 'AE1' || opp.Segment_Sales_Role__c == 'Renewals' || opp.Segment_Sales_Role__c == 'Management')));

        //Due to compliance requirements in Mexico, opportunities that do not require KYC validation are revenue opportunities that are paid via credit card and they can be excluded from OVA 
        if(isMexicoComplianceRequirementOpty(opp, oppFromHelper)) {return false;}

         Boolean isOOS = (isMexicoWebStoreChecksDisabled && isMexicoCurrency && opp.Is_Webstore_Upsell_Opportunity__c) || ( opp.Owner_Segment__c == 'AE1'|| oppFromHelper?.Owner?.UserRole?.Name?.contains('AE1') == true || opp.Custom_Billing__c == 'Custom Credit Application' || opp.Custom_Billing_Schedule_Details__c != null || opp.Custom_Schedule__c == true|| opp.Type != 'Revenue Opportunity'||
               	// GTMS-28876 Modified SLED logic: Include SLED opportunities with reseller in OVA, exclude SLED opportunities without reseller
                  (opp.Owner_Role_Copy__c != null && opp.Owner_Role_Copy__c.contains('SLED') && opp.Reseller__c == null) || (opp.Owner_Manager_Role_Copy__c != null && opp.Owner_Manager_Role_Copy__c.contains('SLED') && opp.Reseller__c == null)
              || !((opp.Finance_Segment__c == 'Enterprise' && opp.Is_Webstore_Upsell_Opportunity__c == TRUE)|| opp.Finance_Segment__c == 'Mid Market')
                 || opp.Payment_Type__c == 'Finance Partner'|| opp.SBQQ__Renewal__c == True|| (oppFromHelper != null && (oppFromHelper.Renewal__c == True || oppFromHelper.Owner.Profile.Name == System.Label.Samsara_Sales_Renewal_for_OVA)) ||String.valueOf(opp.Name).containsIgnoreCase('INVENTORYSPLIT')
                 // || opp.Buyout_Opportunity__c != null || opp.Subsidy_Opportunity__c != null // commented for GTMS-27234 for rebate project
                 || opp.Buyout_Amount__c != 0 || (opp.Subsidy_Amount__c != 0 && (opp.Deal_Components__c != null && opp.Deal_Components__c != 'Future Free Months'))// added for for GTMS-272341 for rebate project               //|| ((opp.CurrencyIsoCode == 'GBP'||opp.CurrencyIsoCode == 'EUR') && opp.VAT_Validation_Status__c != 'Confirmed')(removed as this is not required as part of Out of scope)
                  || !(((pTerms == 'Due in Advance' && ipTerms == 'Due In Advance')||(pTerms.contains('Net') && ipTerms.contains('Net'))) && pTerms == ipTerms)
            //1/9/24 Vijaychandra --START-- (GTMS-17891): Added below line in logic to exclude Promo, Reprocessing, Virtual Return Opportunites
            //4/12/24 Vijaychandra (GTMS-20297)|| (opp.Type == 'Revenue Opportunity' && opp.Blended_Discount__c == 100) commented this code as part of GTMS-20297
            	|| String.valueOf(opp.Name).containsIgnoreCase('Reprocessing') || String.valueOf(opp.Name).containsIgnoreCase('Virtual Return')) || isExcludedByNewRule;
        	//1/9/24 --END-- (GTMS-17891)
        return isOOS;
    }
    //--END-- (GTMS-16283)

    public Boolean settingsOwnerExceptionCriteria(Opportunity opp){
        //removed to normalize order valication logic based on GTMS-13378
        /*
        return !(Order_Validation_Setting__c.getInstance(opp.OwnerId)?.Owner_Exception__c == true
                || Order_Validation_Setting__c.getInstance(opp.Owner_Manager_Name_Copy__c)?.Owner_Exception__c == true
                || Order_Validation_Setting__c.getInstance(opp.Owner_Director_Name_Copy__c)?.Owner_Exception__c == true);
    */
        //removing completed
        
        //Added to normalize order valication logic based on GTMS-13378
        //10/18/23 Vijaychadndra (OV PHASE2 Project)(GTMS-16031) Commented below code for OV PAHSE2 Project
        //return !(opp.CurrencyIsoCode != 'EUR' && opp.CurrencyIsoCode != 'GBP');
        //GTMS-16031
        /***2/1/24 Vijaychadnra --START-- (GTMS-17890): Commenting below pilot logic to normalize the OVA logic of Net Payment terms
        //10/27/23 Vijaychandra --START-- (GTMS-16320) : Net Terms pilot roll out for US/CA/MX
          Boolean rollOutCheck = false;
          string pTerms = opp.Payment_Terms__c != null ? opp.Payment_Terms__c : '';//GTMS-16320
          string ipTerms = opp.initial_Payment_Terms__c != null ? opp.Initial_Payment_Terms__c : '';//GTMS-16320
        //pilot roll out check for Net terms deal
          Boolean netTermsCheck = ((Order_Validation_Setting__c.getInstance(opp.OwnerId)?.Owner_Exception__c == true
                || Order_Validation_Setting__c.getInstance(opp.Owner_Manager_Name_Copy__c)?.Owner_Exception__c == true
                || Order_Validation_Setting__c.getInstance(opp.Owner_Director_Name_Copy__c)?.Owner_Exception__c == true)
                && pTerms.contains('Net') && ipTerms.contains('Net') && opp.CurrencyIsoCode != 'EUR' && opp.CurrencyIsoCode != 'GBP');
        //DIA deal or emea check if it is net terms deal
        Boolean emeaCheck = (pTerms == 'Due in Advance' && ipTerms == 'Due in Advance')||(pTerms.contains('Net') && ipTerms.contains('Net') 
                                                                                          && (opp.CurrencyIsoCode == 'EUR' || opp.CurrencyIsoCode == 'GBP'));
        
        rollOutCheck = !(netTermsCheck || emeaCheck);
        
        //--END-- (GTMS-16320)
        
        return rollOutCheck;
		2/1/24 Vijaychadnra --END-- (GTMS-17890)*/
        return false;
    }
    //12/07/23 Vijaychandra --START-- (GTMS-16637): Created for DCA pilot roleout criteria check.
    /***********
     * Description : pilot role out criteria check for DCA.
     * @Param: opp (Opportunity record)
	*************/
    private Boolean dcaOwnerExceptionCriteria(Opportunity opp){
        //Datetime createdDate = opp.CreatedDate;
        //02/29/24 Vijaychandra --START-- (GTMS-19053)updated DCA rollout logic as per CR by the business.
        /*
        Boolean roleoutCheck = (((Order_Validation_Setting__c.getInstance(opp.OwnerId)?.DCA_Owner_Exception__c == true || Order_Validation_Setting__c.getInstance(opp.Owner_Director_Name_Copy__c)?.DCA_Owner_Exception__c == true)
            					|| opp.Owner_AVP_Name_Copy__c == SYSTEM.Label.Opp_Owner_AVP_Name) && createdDate.date() >= Date.valueOf(SYSTEM.Label.DCA_Cutoff_Date));
		*/
        Boolean roleoutCheck =  (string.isNotBlank(opp.DCA_Enabled__c) && opp.DCA_Enabled__c.startsWith('DCA')) ;//(opp.DCA_Enabled__c == 'DCA' || opp.DCA_Enabled__c == 'DCA Phase Two');
        return !(roleoutCheck);
    }
    
    @testvisible boolean isMexicoComplianceRequirementOpty(Opportunity opp, Opportunity oppFromHelper){
        return (opp.Type == 'Revenue Opportunity' 
            && opp.Payment_Terms__c == 'Due in advance' 
            && opp.Payment_Method__c == 'Credit Card' 
            && opp.Amount_Received__c > 0
            && (    
                    (
                        opp.Owner_Role_Copy__c != null && opp.Owner_Role_Copy__c.contains('MX')
                    ) 
                    || oppFromHelper?.SBQQ__PrimaryQuote__r?.SBQQ__BillingCountry__c == 'Mexico'
                )
            && !opp.First_Purchase__c); 
    }
}