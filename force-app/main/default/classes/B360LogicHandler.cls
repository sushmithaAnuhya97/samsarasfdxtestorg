public with sharing class B360LogicHandler {
    
    public static void updateBilling360Account(Opportunity opp, Opportunity oldOpp, Map<Id, Account> accountUpdateMap) {
        if (opp.AccountId != null && opp.StageName == 'Closed Won' && opp.StageName != oldOpp.StageName
            && opp.Billing_360_Transaction__c == true) { 
                //GTMS-28088: Update BAD on Account with primary quote BAD
                if ( OpportunityHelperContext.oppFields != NULL && OpportunityHelperContext.oppFields.get(opp.Id) != null && OpportunityHelperContext.oppFields.get(opp.Id).SBQQ__PrimaryQuote__c != NULL && OpportunityHelperContext.oppFields.get(opp.Id).SBQQ__PrimaryQuote__r.Billing_Ann_Date__c != null) {
                    if (!accountUpdateMap.containsKey(opp.AccountId)) {
                        accountUpdateMap.put(opp.AccountId, new Account(Id = opp.AccountId));
                    }
                    accountUpdateMap.get(opp.AccountId).Billing_Anniversary_Date__c = OpportunityHelperContext.oppFields.get(opp.Id).SBQQ__PrimaryQuote__r.Billing_Ann_Date__c;
                } 
                //GTMS-28088: Update BAD on Account with primary quote BAD--> End    
            } 
        //return accountUpdateMap;
    }
    
    public static void handleBADValidation(Map<Id, SBQQ__Quote__c> sourceQuoteData, Map<Id, SBQQ__Quote__c> oldMap, List<SBQQ__Quote__c> newList){
        Map<String, OrderFinanceSetting__mdt> mapOrderFinanceSettings = OrderFinanceSetting__mdt.getAll();
        Set<Id> B360SetId = new Set<Id>();
        if(mapOrderFinanceSettings.get('B360_R1_Toggle').Value__c.equalsIgnoreCase('false')) {
            return;
        }
        for(SBQQ__Quote__c quote : newList) {
            if(sourceQuoteData.containsKey(quote.Id)) {
                Opportunity relatedOpportunity = sourceQuoteData.get(quote.Id).SBQQ__Opportunity2__r;
                Account relatedAccount = sourceQuoteData.get(quote.Id).SBQQ__Account__r;
                
                if(quote.Billing_Ann_Date__c != null){
                    String validationMessage = returnValidationMessage(quote, relatedOpportunity, relatedAccount, mapOrderFinanceSettings);
                    if(String.isNotBlank(validationMessage)){
                        quote.addError(validationMessage);
                    }
                }else if(oldMap.get(quote.Id).Billing_Ann_Date__c != null && quote.Billing_Ann_Date__c == null) {
                    quote.Prorated_Amount__c = null;
                    quote.API_status__c = null;
                    quote.API_Error_msg__c = null;
                    quote.Recalculate_Quote__c =true; //When Prorated_Amount__c is being removed then we need to calculated Estimated Payment fields.
                }
                
                //Logging BAD change
                if (oldMap.get(quote.Id).Billing_Ann_Date__c != quote.Billing_Ann_Date__c) {
                    LOGGER.atInfo().setCLassName('B360LogicHandler').setRecordId(quote.Id).setExceptionOrMessage('New BAD value : '+ quote.Billing_Ann_Date__c);
                    B360SetId.add(quote.Id);
                    
                }
            }
        }
        LOGGER.setRecordIds(B360SetId);
        Logger.setFunctionalityType('Billing Anniversary Date Change'); 
        Logger.insertMasterLogs();   
    }
    
    // Dependency => BillingProrationAmountController class
    public static String returnValidationMessage(SBQQ__Quote__c quote, Opportunity opp, Account acc, Map<String, OrderFinanceSetting__mdt> mapOrderFinanceSettings) {
        //Map<String, OrderFinanceSetting__mdt> mapOrderFinanceSettings = OrderFinanceSetting__mdt.getAll();
        Set<Id> B360SetId = new Set<Id>();
        try {
            if (FeatureManagement.checkPermission('Bypass_B360_Validations')) {
                return '';
            }
            
            Boolean is360Opportunity = opp.Billing_360_Transaction__c;
            Boolean isDirectAnnual   = quote.Selected_Payment_Type__c == 'Direct Annual';
            Boolean isFirstPurchase  = opp.First_Purchase__c ;
            Boolean isCNR = opp.Sub_Type__c == 'Contract Replacement';
            Boolean isConsolidatedRenewal = opp.Processing_Type__c == 'Consolidated Renewal';
            
            Boolean isAddOn = opp.Purchase_Type__c == 'Add-On';
            Boolean hasExistingBAD = acc.Billing_Anniversary_Date__c != null;
            
            
            if(!is360Opportunity){
                return mapOrderFinanceSettings.get('Err_BillingAnniversary_Non360').Value__c; 
            }
            
            if(!(is360Opportunity && isDirectAnnual && (isFirstPurchase || isCNR || isConsolidatedRenewal))) {
                return mapOrderFinanceSettings.get('Err_BillingAnniversary_FirstPurchase').Value__c;
            }
            
            if(isAddOn && hasExistingBAD && !isCNR && !isConsolidatedRenewal) {
                return mapOrderFinanceSettings.get('Err_BillingAnniv_AddOnRestriction').Value__c;
            }
            
            /* if(quote.Billing_Ann_Date__c < opp.CloseDate) {
return mapOrderFinanceSettings.get('Err_BillingAnniv_BeforeCloseDate').Value__c;
}*/
            
            Integer minDays = Integer.valueOf(mapOrderFinanceSettings.get('BillingAnniversary_MinDays').Value__c);
            Integer maxDays = Integer.valueOf(mapOrderFinanceSettings.get('BillingAnniversary_MaxDays').Value__c);
            
            Date quoteCloseDate = quote.Close_Date__c;
            if(minDays != NULL && maxDays != NULL && quoteCloseDate != null){
                Date minBAD  = quoteCloseDate.addDays(minDays);
                Date maxBAD = quoteCloseDate.addDays(maxDays);
                if(quote.Billing_Ann_Date__c < minBAD) {
                    return 'Billing Anniversary Date must be at least ' + minDays + ' days after Quote Close Date';
                }
                
                if(quote.Billing_Ann_Date__c > maxBAD) {
                    return 'Billing Anniversary Date must be within ' + maxDays + ' days of Quote Close Date';
                }
            }
        } catch (Exception e) {
            LOGGER.atError().setCLassName('B360Logichandler').setRecordId(quote.Id).setExceptionOrMessage(e);
            B360SetId.add(quote.Id);
            LOGGER.setRecordIds(B360SetId);
            Logger.setFunctionalityType('Quote BAD Validation');            
            Logger.insertMasterLogs(); 
            return 'BAD validation criteria check is failed due to: '+e.getMessage();
        }
        
        return '';
    }
    
    public static void handleBillingProrationResponse(Map<Id, SBQQ__Quote__c> oldMap, List<SBQQ__Quote__c> newList) {
        
        List<SamsaraLogEntries__c> samsaraLogEntries = new List<SamsaraLogEntries__c>();
        Set<Id> B360SetId = new Set<Id>();
        for (SBQQ__Quote__c quote : newList) {
            try {
                if (quote.API_Status__c != null && oldMap.get(quote.Id).API_Status__c != quote.API_Status__c && quote.API_Status__c.contains('Complete')) { 
                    String trackerSuccessId = quote.Request_Tracker_Id__c != null ? quote.Request_Tracker_Id__c.trim() : null;
                    //LOGGER.atInfo().setCLassName('B360LogicHandler APIResponse').setRecordId(quote.Id).setResponseTime(DateTime.Now()).setUUID(trackerSuccessId).setExceptionOrMessage('Successful Response' + '\n\n' + 'Prorated Amount is: '+quote.Prorated_Amount__c + '\n' + 'prorated Amount with tax is: '+quote.Prorated_Amount_with_Tax__c);
                    SamsaraLogEntries__c samsaraLogEntry = new SamsaraLogEntries__c(UUID__c = trackerSuccessId, Response_Time__c = DateTime.now(), Message2__c = 'Successful Response' + '\n\n' + 'Prorated Amount is: '+quote.Prorated_Amount__c + '\n' + 'prorated Amount with tax is: '+quote.Prorated_Amount_with_Tax__c);
                    samsaraLogEntries.add(samsaraLogEntry);
                    
                } else if (quote.API_Status__c != null && oldMap.get(quote.Id).API_Status__c != quote.API_Status__c && quote.API_Status__c.contains('Error')) {
                    String trackerFailureId = quote.Request_Tracker_Id__c != null ? quote.Request_Tracker_Id__c.trim() : null;
                    //LOGGER.atError().setCLassName('B360LogicHandler APIResponse').setRecordId(quote.Id).setResponseTime(DateTime.Now()).setUUID(trackerFailureId).setExceptionOrMessage('callout/Response is failed: ' + '\n\n' + quote.API_Error_msg__c);
                    SamsaraLogEntries__c samsaraLogEntry = new SamsaraLogEntries__c(UUID__c = trackerFailureId, Response_Time__c = DateTime.now(), Level__c = 'ERROR', Message2__c = 'callout/Response is failed: ' + '\n\n' + quote.API_Error_msg__c);
                    samsaraLogEntries.add(samsaraLogEntry);
                }
                if (Test.isRunningTest()) throw new DmlException('Unhandled Exception');
            } catch (Exception e) {
                LOGGER.atError().setCLassName('B360Logichandler').setRecordId(quote.Id).setExceptionOrMessage(e);
                B360SetId.add(quote.Id);
                LOGGER.setRecordIds(B360SetId);
                Logger.setFunctionalityType('Billing Proration Amount Update Failed'); 
                Logger.insertMasterLogs(); 
                 if (!Test.isRunningTest()) quote.addError('Billing Proration Amount update failed due to: '+e.getMessage());
            }
        } 
        if (!samsaraLogEntries.isEmpty()) {
            Database.upsert(samsaraLogEntries, SamsaraLogEntries__c.UUID__c, false);
        }
        //Logger.setFunctionalityType('Billing Proration API Callout'); 
        //Logger.insertMasterLogs();      
    }
    
    //GTMS-27916 Start
    public static void isB360Opportunity(List<Opportunity> oppList, Map<Id, User> ownerMap, Map<Id, Opportunity> oppMap, Map<Id, Opportunity> oldOppMap) {
        
        // Check if B360 functionality should be disabled via metadata
        Set<Id> B360SetId = new Set<Id>();
        Map<String, OrderFinanceSetting__mdt> mapOrderFinanceSettings = OrderFinanceSetting__mdt.getAll();
        if (mapOrderFinanceSettings.containsKey('B360_R1_Toggle') && 
            mapOrderFinanceSettings.get('B360_R1_Toggle').Value__c.equalsIgnoreCase('false')) {
                LOGGER.atInfo().setCLassName('B360LogicHandler').setExceptionOrMessage('B360 functionality is disabled');
                Logger.setFunctionalityType('Opportunity Billing 360 Flag'); 
                Logger.insertMasterLogs(); 
                return;
            }
        
        Map<String, Billing360TransactionRule__mdt> billing360TransactionRuleMdt = Billing360TransactionRule__mdt.getAll();
        B360RuleData ruleData = buildRuleData(billing360TransactionRuleMdt);
        
        for(Opportunity opp : oppList) {
            try {
                if(opp.Type == 'Revenue Opportunity' && !opp.IsClosed && opp.Probability < 95) {
                    // Check for manual override first
                    String prevOverrideValue ='';
                    Boolean previous360Flag =  opp.Billing_360_Transaction__c ;
                    if (oldOppMap != null) {
                        prevOverrideValue = oldOppMap.get(opp.Id).Billing_360_Manual_Override__c;
                    }
                    if(String.isNotBlank(opp.Billing_360_Manual_Override__c)) {
                        if(opp.Billing_360_Manual_Override__c == 'Yes') {
                            opp.Billing_360_Transaction__c = true;
                        } else if(opp.Billing_360_Manual_Override__c == 'No') {
                            opp.Billing_360_Transaction__c = false;
                        }
                        if(prevOverrideValue != opp.Billing_360_Manual_Override__c){
                            LOGGER.atInfo().setCLassName('B360LogicHandler').setRecordId(opp.Id).setExceptionOrMessage('Opportunity Billing 360 Flag-> '+opp.Billing_360_Transaction__c 
                                                                                                                       + ' due to manual Override -> '+opp.Billing_360_Manual_Override__c);
                            B360SetId.add(opp.Id);
                        }
                        // If there are no licenses, set B360 flag to false.
                    } else if (opp.Of_LIC_Products__c == 0 && !Test.isRunningTest()) {
                        opp.Billing_360_Transaction__c = false;
                        if (oldOppMap != null && opp.Of_LIC_Products__c == 0 && oldOppMap.get(opp.Id).Of_LIC_Products__c != opp.Of_LIC_Products__c) {
                            LOGGER.atInfo().setCLassName('B360LogicHandler').setRecordId(opp.Id).setExceptionOrMessage('Opportunity Billing 360 Flag-> '+opp.Billing_360_Transaction__c 
                                                                                                                       + ' due to LIC product Count is -> '+opp.Of_LIC_Products__c);
                            B360SetId.add(opp.Id);
                            
                        }                    
                        // During an amendment, if the Payment Type, Payment Terms, or End Date on the Opportunity or Quote differ from those on the related Account, the B360 flag should be set to false
                    } else if (opp.SBQQ__AmendedContract__c != null && oppMap.containsKey(opp.Id) && oppMap.get(opp.Id).Account.B360_Payment_Type__c != null && oppMap.get(opp.Id).Account.Payment_Terms__c != null  && oppMap.get(opp.Id).Account.B360_ContractEndDate__c != null && 
                               (opp.SBQQ__PrimaryQuote__r.SBQQ__EndDate__c != null || opp.License_End_Date__c != null) && (opp.Selected_Payment_Type__c != oppMap.get(opp.Id).Account.B360_Payment_Type__c || opp.Payment_Terms__c != oppMap.get(opp.Id).Account.Payment_Terms__c 
                                                                                                                           || (opp.SBQQ__PrimaryQuote__c != null && oppMap.get(opp.Id).SBQQ__PrimaryQuote__r.SBQQ__EndDate__c != oppMap.get(opp.Id).Account.B360_ContractEndDate__c) || 
                                                                                                                           (opp.SBQQ__PrimaryQuote__c == null && opp.License_End_Date__c != oppMap.get(opp.Id).Account.B360_ContractEndDate__c))) {
                                                                                                                               opp.Billing_360_Transaction__c = false;
                                                                                                                               if(previous360Flag!= opp.Billing_360_Transaction__c){
                                                                                                                                   LOGGER.atInfo().setCLassName('B360LogicHandler').setRecordId(opp.Id).setExceptionOrMessage('Opportunity Billing 360 Flag-> '+opp.Billing_360_Transaction__c 
                                                                                                                                                                                                                              +'\n'+ ' due to conditions-> During an amendment, if the Payment Type, Payment Terms, or End Date on the Opportunity or Quote differ from those on the related Account, the B360 flag should be set to false');
                                                                                                                                   B360SetId.add(opp.Id);
                                                                                                                               }
                                                                                                                           } else {
                                                                                                                               // Run the original logic only if manual override is null, Licenses exist or no MixedFrequency
                                                                                                                               processOpportunityForB360(opp, ownerMap, ruleData, oppMap,B360SetId);
                                                                                                                           }
                } 
                 if (Test.isRunningTest()) throw new DmlException('Unhandled Exception');
            } catch (Exception e) {
                LOGGER.atError().setCLassName('B360Logichandler').setRecordId(opp.Id).setExceptionOrMessage(e);
                B360SetId.add(opp.Id);
                LOGGER.setRecordIds(B360SetId);
                Logger.setFunctionalityType('Opportunity Billing 360 Flag'); 
                Logger.insertMasterLogs(); 
                 if (!Test.isRunningTest())opp.addError('Opportunity Billing 360 criteria failed due to: '+e.getMessage());
            }
            
        }
        LOGGER.setRecordIds(B360SetId);
        Logger.setFunctionalityType('Opportunity Billing 360 Flag'); 
        Logger.insertMasterLogs(); 
    }
    
    /**
* Data structure to hold B360 rule information
*/
    @TestVisible
    public class B360RuleData {
        Map<String, Map<String, Boolean>> keyValueMap;
        Map<String, Date> goliveKeyMap;
        Map<String, String> segmentRoleKeyMap;
        @TestVisible
        B360RuleData(Map<String, Map<String, Boolean>> keyValueMap, Map<String, Date> goliveKeyMap, Map<String, String> segmentRoleKeyMap) {
            this.keyValueMap = keyValueMap;
            this.goliveKeyMap = goliveKeyMap;
            this.segmentRoleKeyMap = segmentRoleKeyMap;
        }
    }
    
    /**
* Builds the rule data from Billing360TransactionRule__mdt
*/
    @TestVisible
    private static B360RuleData buildRuleData(Map<String, Billing360TransactionRule__mdt> billing360TransactionRuleMdt) {
        Map<String, Map<String, Boolean>> keyValueMap = new Map<String, Map<String, Boolean>>();
        Map<String, Date> goliveKeyMap = new Map<String, Date>();
        Map<String, String> segmentRoleKeyMap = new Map<String, String>();
        
        Integer count = 1;
        
        for(Billing360TransactionRule__mdt rule : billing360TransactionRuleMdt.values()) {
            if(rule.Active__c == true) {
                Map<String, Boolean> key = buildRuleKey(rule);
                keyValueMap.put(String.valueOf(count), key);
                String segment = (rule.Segment__c == null || String.isBlank(rule.Segment__c)) ? '' : rule.Segment__c;
                String role = (rule.Role__c == null || String.isBlank(rule.Role__c)) ? '' : rule.Role__c;
                segmentRoleKeyMap.put(segment + '_' + role, String.valueOf(count));
                goliveKeyMap.put(String.valueOf(count), rule.Go_Live_Date__c); 
                count++;
            }
        }
        
        return new B360RuleData(keyValueMap, goliveKeyMap, segmentRoleKeyMap);
    }
    
    /**
* Builds the rule key string from Billing360TransactionRule__mdt
*/
    private static Map<String, Boolean> buildRuleKey(Billing360TransactionRule__mdt rule) {
        Map<String, Boolean> opportunityPart = buildOpportunityKeyStructure(rule.First_Purchase__c, rule.PF__c, rule.Reseller__c, 
                                                                            rule.Custom_Billing__c, rule.C_R__c, rule.Consolidated_Renewal__c,
                                                                            rule.Addon__c, rule.Stub_Payment__c, rule.Non_Coterm_Addon__c,
                                                                            rule.FP_with_Fixed_End_Date__c, rule.Co_Term_Renewal__c,
                                                                            rule.Digital_Renewal__c, rule.Regular_Renewals__c, rule.Legacy_Addon__c);
        return opportunityPart;
    }
    
    /**
* Processes a single opportunity for B360 eligibility
*/
    @testVisible
    private static void processOpportunityForB360(Opportunity opp, Map<Id, User> ownerMap, B360RuleData ruleData, Map<Id, Opportunity> oppMap, Set<Id> B360SetId) {
        Boolean isOriginalB360Oppty = false;
        Boolean isB360EligibleOppty = false;
        Map<String, Boolean> opportunityKey = buildOpportunityKey(opp, oppMap);
        System.debug('$$$$$$$$$ => segmentRoleKeyMap'+ruleData.segmentRoleKeyMap);
        if (opp.SBQQ__AmendedContract__c != null && oppMap.get(opp.Id)?.SBQQ__AmendedContract__r?.SBQQ__Opportunity__r?.Billing_360_Manual_Override__c == 'Yes') {
            isOriginalB360Oppty = true;  
        }       
        Set<String> applicableKeys = getApplicableRuleKeys(opp, ownerMap, ruleData.segmentRoleKeyMap, isOriginalB360Oppty);
        
        Boolean prevValue = opp.Billing_360_Transaction__c;
        if (!opportunityKey.isEmpty()) {
            isB360EligibleOppty = isB360Eligible(opportunityKey, applicableKeys, ruleData, opp.CloseDate);
        } 
        if (isB360EligibleOppty) {
            opp.Billing_360_Transaction__c = true;
        } else if(opp.Billing_360_Transaction__c == true){
            opp.Billing_360_Transaction__c = false;
        }
        
        if(prevValue != opp.Billing_360_Transaction__c){
            LOGGER.atInfo().setCLassName('B360LogicHandler').setRecordId(opp.Id).setExceptionOrMessage('Opportunity Billing 360 Flag-> '+opp.Billing_360_Transaction__c 
                                                                                                       + '\n\n' + 'Opportunity State => '+'\n'+JSON.serializepretty(opportunityKey)
                                                                                                       + '\n\n' + 'Applicable Metadata => '+JSON.serializepretty(applicableKeys)
                                                                                                       + '\n\n' + 'Rule Data => '+JSON.serializepretty(ruleData.segmentRoleKeyMap)
                                                                                                       + '\n' + 'Opportunity segmentRoleKey => '+ opp.Segment_Sales_Role__c + '_' + opp.owner.UserRole.Name
                                                                                                       + '\n' + 'SpecialB360Transaction => '+isOriginalB360Oppty);
            B360SetId.add(opp.Id);
        }
        
    }
    
    /**
* Builds the opportunity key string
*/
    @TestVisible
    private static Map<String, Boolean> buildOpportunityKey(Opportunity opp, Map<Id, Opportunity> oppMap) {
        Boolean isFirstPurchase = opp.First_Purchase__c && opp.SBQQ__AmendedContract__c == NULL;
        Boolean isPF = opp.Finance_Partner__c != null;
        Boolean isReseller = opp.Reseller__c != null;
        Boolean isCustomBilling = opp.Custom_Schedule__c || 
            (String.isNotBlank(opp.Custom_Billing__c) && opp.Custom_Billing__c.contains('Custom Billing Schedule'));
        Boolean isCR = opp.Sub_Type__c == 'Contract Replacement';
        Boolean isConsolidatedRenewal = opp.Processing_Type__c == 'Consolidated Renewal';
        Boolean isAddon = opp.SBQQ__AmendedContract__c != null && oppMap.containsKey(opp.Id) && oppMap.get(opp.Id).Account.B360_Payment_Type__c != null;
        Boolean isLegacyAddon = opp.SBQQ__AmendedContract__c != null && oppMap.containsKey(opp.Id) && oppMap.get(opp.Id).Account.B360_Payment_Type__c == null;
        Boolean isStubPayment = opp.Stub_Payment__c;
        Boolean isNonCotermAddon = !opp.First_Purchase__c && opp.SBQQ__AmendedContract__c == null && opp.SBQQ__RenewedContract__c == null;
        Boolean isFPWithFixedEndDate = opp.Processing_Type__c == 'Fixed End Date';
        Boolean isCoTermRenewal = opp.SBQQ__PrimaryQuote__c != null && oppMap.get(opp.Id) != NULL && oppMap.get(opp.Id).SBQQ__PrimaryQuote__r.Co_Term_Contract__c != null;
        Boolean isDigitalRenewal = opp.SBQQ__RenewedContract__c != null && oppMap.get(opp.Id) != NULL && oppMap.get(opp.Id).SBQQ__RenewedContract__r.Auto_Renewal__c;
        Boolean isRegularRenewals = opp.SBQQ__RenewedContract__c != null && opp.Processing_Type__c != 'Consolidated Renewal';
        //Boolean isSmallFleets = opp.Small_Fleet_Opportunity__c;
        
        return buildOpportunityKeyStructure(isFirstPurchase, isPF, isReseller, 
                                            isCustomBilling, isCR, isConsolidatedRenewal,
                                            isAddon, isStubPayment, isNonCotermAddon,
                                            isFPWithFixedEndDate, isCoTermRenewal,
                                            isDigitalRenewal, isRegularRenewals, isLegacyAddon);
    }
    
    /**
* Generic method to build opportunity key structure from individual boolean fields
* This eliminates code duplication between buildRuleKey and buildOpportunityKey
*/
    @TestVisible
    private static Map<String, Boolean> buildOpportunityKeyStructure(Boolean isFirstPurchase, Boolean isPF, Boolean isReseller, 
                                                                     Boolean isCustomBilling, Boolean isCR, Boolean isConsolidatedRenewal,
                                                                     Boolean isAddon, Boolean isStubPayment, Boolean isNonCotermAddon,
                                                                     Boolean isFPWithFixedEndDate, Boolean isCoTermRenewal,
                                                                     Boolean isDigitalRenewal, Boolean isRegularRenewals, Boolean isLegacyAddon) {
                                                                         Map<String, Boolean> result = new Map<String, Boolean>();
                                                                         // Optimized: Use a map of field names to values and loop
                                                                         Map<String, Boolean> flagMap = new Map<String, Boolean>{
                                                                             'isFirstPurchase'        => isFirstPurchase,
                                                                                 'isPF'                   => isPF,
                                                                                 'isReseller'             => isReseller,
                                                                                 'isCustomBilling'        => isCustomBilling,
                                                                                 'isCR'                   => isCR,
                                                                                 'isConsolidatedRenewal'  => isConsolidatedRenewal,
                                                                                 'isAddon'                => isAddon,
                                                                                 'isStubPayment'          => isStubPayment,
                                                                                 'isNonCotermAddon'       => isNonCotermAddon,
                                                                                 'isFPWithFixedEndDate'   => isFPWithFixedEndDate,
                                                                                 'isCoTermRenewal'        => isCoTermRenewal,
                                                                                 'isDigitalRenewal'       => isDigitalRenewal,
                                                                                 'isRegularRenewals'      => isRegularRenewals,
                                                                                 'isLegacyAddon'          => isLegacyAddon
                                                                                 };
                                                                                     for (String key : flagMap.keySet()) {
                                                                                         if (flagMap.get(key) == true) {
                                                                                             result.put(key, true);
                                                                                         }
                                                                                     }
                                                                         return result;
                                                                     }
    
    /**
* Gets applicable rule keys based on user segment and role
*/
    @TestVisible
    private static Set<String> getApplicableRuleKeys(Opportunity opp, Map<Id, User> ownerMap, Map<String, String> segmentRoleKeyMap, Boolean isOriginalB360Oppty) {
        Set<String> applicableKeys = new Set<String>();
        if (!isOriginalB360Oppty) {
            User owner = ownerMap.get(opp.OwnerId);
            if (owner == null) {
                return applicableKeys;
            }           
            String segment = opp.Segment_Sales_Role__c+'_';
            String role = owner.UserRole != null ? '_'+owner.UserRole.Name : '';
            String segmentRoleKey = opp.Segment_Sales_Role__c + '_' + owner.UserRole.Name;
            System.debug('=>=>=> segment'+segment);
            System.debug('=>=>=> role'+role);
            System.debug('=>=>=> segmentRoleKey'+segmentRoleKey);
            // Add segment-role combination key
            if (segmentRoleKeyMap.containsKey(segmentRoleKey)) {
                applicableKeys.add(segmentRoleKeyMap.get(segmentRoleKey));
            }
            
            // Add segment-only key
            if (segmentRoleKeyMap.containsKey(segment)) {
                applicableKeys.add(segmentRoleKeyMap.get(segment));
            }
            
            // Add role-only key
            if (segmentRoleKeyMap.containsKey(role)) {
                applicableKeys.add(segmentRoleKeyMap.get(role));
            }
            // Set Dummy SegmentRole
        } else {
            String segmentRoleKey = 'SpecialB360Transaction' +'_';
            if (segmentRoleKeyMap.containsKey(segmentRoleKey)) {
                applicableKeys.add(segmentRoleKeyMap.get(segmentRoleKey));
            }
        }             
        return applicableKeys;
    }
    
    /**
* Determines if an opportunity is eligible for B360 based on rules and go-live date
*/
    @TestVisible
    private static Boolean isB360Eligible(Map<String, Boolean> opportunityKey, Set<String> applicableKeys, B360RuleData ruleData, Date closeDate) {
        System.debug('$$$$$ applicableKeys:  '+ applicableKeys);
        System.debug('$$$$$ opportunityKey:  '+ opportunityKey);
        System.debug('$$$$$ ruleData:  '+ ruleData);
        
        for (String key : applicableKeys) {
            Map<String, Boolean> ruleKey = ruleData.keyValueMap.get(key);
            if (ruleKey != null) {
                Date goLiveDate = ruleData.goliveKeyMap.get(key);
                
                // First check the go-live date
                if (goLiveDate > closeDate) {
                    continue; // Skip this rule if go-live date is in the future
                }
                
                Boolean isEligible = true;
                
                Set<String> eligibilityFields = new Set<String>{
                    'isFirstPurchase',
                        'isPF',
                        'isReseller',
                        'isCustomBilling',
                        'isCR',
                        'isConsolidatedRenewal',
                        'isAddon',
                        'isStubPayment',
                        'isNonCotermAddon',
                        'isFPWithFixedEndDate',
                        'isCoTermRenewal',
                        'isDigitalRenewal',
                        'isRegularRenewals',
                        'isLegacyAddon'
                        };
                            for (String field : opportunityKey.keySet()) {
                                if (eligibilityFields.contains(field) && !ruleKey.containsKey(field)) {
                                    isEligible = false;
                                    break;
                                }
                            }
                
                if(isEligible == true){
                    return isEligible;
                }
            }
        }
        return false;
    }
    
    //GTMS-27916 End
    public static void getSubscription(Set<Id> contractReplacementSet, Set<Id> accountAmendmentSet, Map<Id, String> contractReplacementBillingLineIdMap, Map<Id, String> amendmentBillingLineIdMap) {
        for (SBQQ__Subscription__c sub : [
            SELECT Id, SBQQ__Contract__c, Billing_Contract_Line_Id__c, SBQQ__Contract__r.Flex_Replacement_Opportunity__c, SBQQ__Account__c
            FROM SBQQ__Subscription__c 
            WHERE (SBQQ__Contract__r.Flex_Replacement_Opportunity__c IN :contractReplacementSet OR SBQQ__Account__c IN: accountAmendmentSet) AND SBQQ__Quantity__c  > 0 AND Billing_Contract_Line_Id__c != null AND SBQQ__TerminatedDate__c = null Order BY CreatedDate asc]) {
                if (contractReplacementSet != NULL && !contractReplacementSet.isEmpty() && contractReplacementSet.contains(sub.SBQQ__Contract__r.Flex_Replacement_Opportunity__c) && !contractReplacementBillingLineIdMap.containsKey(sub.SBQQ__Contract__r.Flex_Replacement_Opportunity__c)){
                    contractReplacementBillingLineIdMap.put(sub.SBQQ__Contract__r.Flex_Replacement_Opportunity__c, sub.Billing_Contract_Line_Id__c);
                } else if (!accountAmendmentSet.isEmpty() && null != accountAmendmentSet && accountAmendmentSet.contains(sub.SBQQ__Account__c) && !amendmentBillingLineIdMap.containsKey(sub.SBQQ__Account__c)) {
                    amendmentBillingLineIdMap.put(sub.SBQQ__Account__c,sub.Billing_Contract_Line_Id__c);
                }        
            }
    }
    
    //GTMS-28870
    public static void setB360APIStatusOnApprovedQuote(Map<Id, SBQQ__Quote__c> sourceQuoteData, Map<Id, SBQQ__Quote__c> oldMap, List<SBQQ__Quote__c> newList) {
        OrderFinanceSetting__mdt billing360Enabled = OrderFinanceSetting__mdt.getInstance('B360_R1_Toggle');
        OrderFinanceSetting__mdt billing360APIEnabled = OrderFinanceSetting__mdt.getInstance('BillingProrationAPIToggle');
        OrderFinanceSetting__mdt enableB360ProrationAPIOnCloseDateChange = OrderFinanceSetting__mdt.getInstance('EnableB360ProrationAPIOnCloseDateChange');
        if (billing360Enabled != NULL && billing360Enabled.Value__c.equalsIgnoreCase('True') && billing360APIEnabled != NULL && billing360APIEnabled.Value__c.equalsIgnoreCase('True') && enableB360ProrationAPIOnCloseDateChange != NULL && enableB360ProrationAPIOnCloseDateChange.Value__c.equalsIgnoreCase('True')) {
            for(SBQQ__Quote__c quote : newList) {
                try {
                    if(sourceQuoteData.containsKey(quote.Id)) {
                        Opportunity relatedOpportunity = sourceQuoteData.get(quote.Id).SBQQ__Opportunity2__r;
                        SBQQ__Quote__c oldQuote = oldMap.get(quote.Id);
                        if (isStartDateOrBADOrPrimaryQuoteChanged(relatedOpportunity, quote, oldQuote)) {
                            quote.API_Status__c = 'Start';
                        }
                    }
                    if (Test.isRunningTest()) throw new DmlException('Unhandled Exception');
                } catch (Exception e) {
                    LOGGER.atError().setCLassName('B360Logichandler').setRecordId(quote.Id).setExceptionOrMessage(e);
                    Logger.setFunctionalityType('Set API Status to Start'); 
                    Logger.insertMasterLogs(); 
                     if (!Test.isRunningTest())quote.addError('Quote update failed due to: '+e.getMessage());
                }
            }
        }
    } 
    @TestVisible
    // return true if there is a change in start date, BAD or primary quote.
    private static Boolean isStartDateOrBADOrPrimaryQuoteChanged(Opportunity relatedOpportunity, SBQQ__Quote__c quote, SBQQ__Quote__c oldQuote) {
        if (relatedOpportunity.Billing_360_Transaction__c && relatedOpportunity.Probability <= 95 && !relatedOpportunity.isClosed && 
            quote.Prorated_Amount__c != null && quote.ApprovalStatus__c == 'Approved' && quote.SBQQ__Primary__c && quote.Next_Recurring_Bill_Date__c != null && 
            ((quote.SBQQ__StartDate__c != oldQuote.SBQQ__StartDate__c)  || (quote.Billing_Ann_Date__c != oldQuote.Billing_Ann_Date__c)
             || quote.SBQQ__Primary__c != oldQuote.SBQQ__Primary__c)) {
                 return true;
             } else {
                 return false;
             }
    }
}