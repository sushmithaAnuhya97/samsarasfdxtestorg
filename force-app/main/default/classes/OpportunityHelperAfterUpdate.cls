/**********************************************************************
Name: OpportunityHelperAfterUpdate

Purpose: This class will contains method that will be called in the after update context                                                    

History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2025-Apr-18        INITIAL DEVELOPMENT 

***********************************************************************/

public class OpportunityHelperAfterUpdate extends OpportunityHelperContext {
  @TestVisible private static List<SFS_Promo_Product_Setting__mdt> testSettingsOverride;  
    /*
* @description - GTMS-25781 Sync Mechanism between the Replacement Opportunity and Cancellation Opportunities
* @param - newOppList, oldOppMap, newOppMap
*/
    public void flexSyncReturnOpportunities(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap) {
        Map<Id, Opportunity> upgradeOpportunityMap = new Map<Id, Opportunity>();   // Map to store upgraded opportunities 
        Map<String, String> upgradeToReturnStageMap = new Map<String, String>(); // Map to store stage name mappings from custom metadata
        
        // Fetching stage name mappings from custom metadata
        List<Flex_Opportunity_StageName_Mapping__mdt> stageNameMetadata = Flex_Opportunity_StageName_Mapping__mdt.getAll().values();
        for (Flex_Opportunity_StageName_Mapping__mdt metadataRecord : stageNameMetadata) {
            upgradeToReturnStageMap.put(metadataRecord.Upgrade_Opportunity_StageName__c, metadataRecord.Return_Opportunity_StageName__c);
        }
        
        // Process new opportunities
        for (Opportunity newOpp : newOppList) {
            Opportunity oldOpp = oldOppMap.get(newOpp.Id);
            // Determine if the opportunity is a contract replacement and if Closed date, stage name, owners have changed
            Boolean isContractReplacement = newOpp.Sub_Type__c == 'Contract Replacement';
            Boolean isCloseDateChanged = newOpp.CloseDate != oldOpp.CloseDate;
            Boolean isStageNameChanged = newOpp.StageName != oldOpp.StageName;
            Boolean isOwnerChanged = newOpp.OwnerId != oldOpp.OwnerId;        
            // Add to upgradeOpportunityMap if it is a contract replacement and closed date, stage name have changed
            if (isContractReplacement && isStageNameChanged) {
                upgradeOpportunityMap.put(newOpp.Id, newOpp);
            }
            // Add to upgradeOpportunityMap and opportunityIdSet if the owner has changed
            if (isContractReplacement && isCloseDateChanged) {
                upgradeOpportunityMap.put(newOpp.Id, newOpp);
            }
            if (isContractReplacement && isOwnerChanged) {
                upgradeOpportunityMap.put(newOpp.Id, newOpp);
            }
        }
        
        // Update return opportunities
        if (!upgradeOpportunityMap.isEmpty()) {
            List<Opportunity> returnOpportunityList = new List<Opportunity>();
            List<SBQQ__Quote__c> quotesList = new List<SBQQ__Quote__c>();
            for (Id key : upgradeOpportunityMap.keySet()) {
                Opportunity opp = oppFields.get(key);
                quotesList.addAll(opp.SBQQ__Quotes2__r);             // upgrade opportunity quotes
                /*returnOpportunityList.addAll(oppFields.get(key).Opportunities4__r); // Assuming oppFields is defined elsewhere              
for(Opportunity returnOpp : returnOpportunityList)
{
quotesList.addAll(returnOpp.SBQQ__Quotes2__r);              // return opportunity quotes
}*/
                for(Related_Opportunity__c ro:opp.Related_Opportunities__r){
                    if(ro.Cancelation_Opportunity__c!=null){
                        returnOpportunityList.add(ro.Cancelation_Opportunity__r);
                    }
                    if(ro.RelatedQuotes__r.size()>0){
                        quotesList.addAll(ro.RelatedQuotes__r);
                    }
                }            
            }
            
            if (!returnOpportunityList.isEmpty()) {
                OpportunityTriggerHandler.bypassForSyncMechanism = true; // bypassing sync opportunities mechanism
                Map<Id,Opportunity> returnOppUpdateMap = new Map<Id,Opportunity>();
                for (Opportunity returnOpp : returnOpportunityList) {
                    //Opportunity upgradedOpp = upgradeOpportunityMap.get(returnOpp.Upgraded_Opportunity_ID__c); 
                    Opportunity newOpp = newOppMap.get(returnOpp.Upgraded_Opportunity_ID__c);
                    Opportunity oldOpp = oldOppMap.get(returnOpp.Upgraded_Opportunity_ID__c);
                    
                    returnOpp.Bypass_Validation_Rule_DateTime__c = Datetime.now();
                    // Update return opportunity fields based on changes in the upgraded opportunity
                    if (oldOpp!=null && newOpp.CloseDate != oldOpp.CloseDate) {
                        returnOpp.CloseDate = newOpp.CloseDate;
                        returnOppUpdateMap.put(returnOpp.Id, returnOpp);
                        
                    }
                    if (oldOpp!=null && newOpp.StageName != oldOpp.StageName && upgradeToReturnStageMap.containsKey(newOpp.StageName)) {
                        returnOpp.StageName = upgradeToReturnStageMap.get(newOpp.StageName);
                        returnOppUpdateMap.put(returnOpp.Id, returnOpp);
                    } 
                    if (oldOpp!=null && newOpp.OwnerId != oldOpp.OwnerId) {
                        returnOpp.OwnerId = newOpp.OwnerId;         
                        returnOppUpdateMap.put(returnOpp.Id, returnOpp);
                    }                
                }
                if(!returnOppUpdateMap.keySet().isEmpty())
                {
                    update returnOppUpdateMap.values(); // Update the return opportunities
                }
            }
            
            // Update quote owners
            if(!quotesList.isEmpty()) {
                Map<Id,SBQQ__Quote__c> quoteMap= new Map<Id,SBQQ__Quote__c>();
                
                for (SBQQ__Quote__c quote : quotesList) {
                    String opportunityId = quote.SBQQ__Opportunity2__r.Upgraded_Opportunity_ID__c != null ? 
                        quote.SBQQ__Opportunity2__r.Upgraded_Opportunity_ID__c :
                    quote.SBQQ__Opportunity2__c;
                    
                    Opportunity newOpp = upgradeOpportunityMap.get(opportunityId);
                    Opportunity oldOpp = oldOppMap.get(opportunityId);
                    
                    if(oldOpp != null && newOpp.OwnerId != oldOpp.OwnerId) {
                        quote.OwnerId = newOpp.OwnerId;
                    }
                    
                    if(oldOpp != null && newOpp.CloseDate != oldOpp.CloseDate) {
                        Boolean isContractRebook = false;
                        
                        if (quote.SBQQ__Opportunity2__r.Upgraded_Opportunity_ID__c != null) {
                            isContractRebook = quote.SBQQ__Opportunity2__r.SBQQ__AmendedContract__r.Flex_Is_Rebook__c;
                        }
                        else if(quote.SBQQ__Opportunity2__r.Upgraded_Opportunity_ID__c == null && oppFields.containsKey(quote.SBQQ__Opportunity2__c) && !oppFields.get(quote.SBQQ__Opportunity2__c).ReplacementContracts__r.isEmpty()) {
                            isContractRebook = oppFields.get(quote.SBQQ__Opportunity2__c).ReplacementContracts__r[0].Flex_Is_Rebook__c;
                        }
                        
                        quote.SBQQ__StartDate__c = isContractRebook ? (newOpp.CloseDate + 15) : newOpp.CloseDate;
                    }
                    
                    if (oldOpp != null && (newOpp.OwnerId != oldOpp.OwnerId || newOpp.CloseDate != oldOpp.CloseDate)) {
                        quote.Flex_Bypass_Validation_Rule_Date_Time__c = DateTime.now(); //GTMS-25783
                        quoteMap.put(quote.Id, quote);
                    }
                }
                
                if(!quoteMap.keySet().isEmpty())
                {
                    update quoteMap.values(); // Update the return opportunities
                }
            }                               
        }
    }
    
    /*
* @description - GTMS-26285  Unset C&R flag from Account and Contract.
* @param - newOppList, oldOppMap, newOppMap
*/   
    public void flexUnsetCnRFlag(List<Opportunity> oppList, Map<Id, Opportunity> oldOppMap,Map<Id, Opportunity> newOppMap) {
        Set<Id> upgradeOppIdSet = new Set<Id>();
        List<Contract> cnrContractList = new List<Contract>();
        Set<Id> accountIdSet = new Set<Id>();  // To track account updates
        for (Opportunity opp : oppList)
        {
            if(opp.Upgraded_Opportunity_ID__c == null && opp.Sub_Type__c=='Contract Replacement')
            {
                upgradeOppIdSet.add(opp.Id);
            }
            Opportunity oldOpp = oldOppMap.get(opp.Id);        
            if(opp.AccountId != null && opp.StageName != oldOpp.StageName && oppAccounts.containsKey(opp.AccountId) && oppAccounts.get(opp.AccountId).Account_C_R_In_Progress__c)
            {           
                // Identifying the corrrect Opprtunity.
                if(opp.Upgraded_Opportunity_ID__c != null &&  opp.Sub_Type__c=='Contract Cancellation'&& (opp.StageName == 'Refunded - Closed' || opp.StageName == 'Return Cancelled'))
                {
                    // Stores AccountId retrieved from return opportunity
                    accountIdSet.add(opp.AccountId);
                    newOppIdSet.add(opp.Id);
                }
                if(opp.Sub_Type__c=='Contract Replacement'&& (opp.StageName =='Closed Won' || opp.StageName =='Closed Lost'))
                {
                    
                    // Stores AccountId retrieved from Upgrade opportunity
                    accountIdSet.add(opp.AccountId);
                    newOppIdSet.add(opp.Id);
                }
            }
        }
        
        if (!accountIdSet.isEmpty()) {
            Boolean allValidOpp = true;
            List<Account> accountsToProcessList = new List<Account>();
            for (Id accountId : accountIdSet) 
            {
                Boolean allValidOpportunities = true;
                Account acc = oppAccounts.get(accountId);
                for (Opportunity opp : acc.Opportunities) 
                {   
                    if (!newOppIdSet.contains(opp.Id) && ((opp.Sub_Type__c == 'Contract Cancellation' && opp.StageName != 'Refunded - Closed' && opp.StageName != 'Return Cancelled') || (opp.Sub_Type__c == 'Contract Replacement' && opp.StageName != 'Closed Won' && opp.StageName != 'Closed Lost'))) 
                    {
                        allValidOpportunities = false;
                        break; 
                    }
                    
                }
                if(allValidOpportunities)
                {
                    accountsToProcessList.add(new Account(Id = accountId, Account_C_R_In_Progress__c = false));
                }
            }
            if(!upgradeOppIdSet.isEmpty()) {
                
                for(Id opportunityId : upgradeOppIdSet){
                    List<Opportunity> returnOppty = new List<Opportunity>();
                    if(newOppMap.get(opportunityId).StageName=='Closed Lost') {
                        
                        //List<Opportunity> returnOppty= oppFields.get(opportunityId).Opportunities4__r;
                        Opportunity oppty = oppFields.get(opportunityId);
                        for(Related_Opportunity__c ro:oppty.Related_Opportunities__r){
                            if(ro.Cancelation_Opportunity__c!=null){
                                returnOppty.add(ro.Cancelation_Opportunity__r);
                            }
                        }
                        if(!returnOppty.isEmpty()) {
                            for(Opportunity opp : returnOppty)
                            {
                                if(opp.Upgraded_Opportunity_ID__c != null && opp.SBQQ__AmendedContract__c!=null)
                                {			
                                    Contract contract = new Contract(Id = opp.SBQQ__AmendedContract__c);                           
                                    contract.Contract_C_R_In_Progress__c = false;
                                    cnrContractList.add(contract);	                             
                                }
                            }
                        }
                    }
                }
            }
            // Update Account in bulk
            if(!accountsToProcessList.isEmpty()) {
                update accountsToProcessList;
            }
            // Update Contracts in bulk 
            if (!cnrContractList.isEmpty()) {
                update cnrContractList;
            }
        }
    }
    
    public void updateOrders(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList){
        Set<Id> oppIds = new Set<Id>();
        Map<Id, Opportunity> newOppMap = new Map<Id, Opportunity>(newOppList);
        for(Opportunity newOpportunityData: newOppList){
            Opportunity oldOpportunityData = oldOppMap.get(newOpportunityData.Id);
            if ((newOpportunityData.StageName == 'Refunded - Closed' || newOpportunityData.StageName == 'Return Cancelled') && oldOpportunityData.StageName != newOpportunityData.StageName &&
                (newOpportunityData.Type == 'Remorse Refund' || newOpportunityData.Type == 'Rebate' || newOpportunityData.Type == 'Exchange' || newOpportunityData.Type == 'Warrant Exchange')) {
                    oppIds.add(newOpportunityData.Id);
                }
        }
        List<Order> updatedOrders = new List<Order>();
        List<Order> orders = [SELECT Id, OpportunityId, Status FROM Order WHERE OpportunityId IN :oppIds];
        for(Order order : orders) {
            Opportunity opp = newOppMap.get(order.OpportunityId);
            if(opp != null) {
                order.Status = opp.StageName == 'Refunded - Closed' ? 'Return Completed' : 'RMA Canceled';
                updatedOrders.add(order);
            }
        }
        if(!updatedOrders.isEmpty()) {
            update updatedOrders;
        }
    }
    
    // GTMS-11894 - OrderTransformation : Extension Scenario
    public void submitForTrialExtensionApproval(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
        List<Approval.ProcessSubmitRequest> submitRequests = new List<Approval.ProcessSubmitRequest>();
        system.debug('Reached here');
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : newOppList) {
            if (opp.Free_Trial_Approval__c && !oldOppMap.get(opp.Id).Free_Trial_Approval__c) {
                oppIds.add(opp.Id);
                system.debug('line 622');
            }
        }
        if (!oppIds.isEmpty()) {
            for (Id oppId : oppIds) {
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                system.debug('submitted for approval');
                Id submitterId = UserInfo.getUserId();
                system.debug('User Id'+submitterId);
                req.setObjectId(oppId);
                req.setSubmitterId(submitterId);
                submitRequests.add(req);
            }
            if(submitRequests.size()>0 && !Test.isRunningTest()){
                List<Approval.ProcessResult> results = Approval.process(submitRequests);
            } else {
                ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, 'No Approval process related to this Opportunity');
                ApexPages.addMessage(msg);
            }
        }
    }
    
    // added for GTMS-16003 starts here
    public void performUpdateOnFPQ(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
        Set<Id> opptyIdSet = new Set<Id>();
        Set<Id> opptyIdForContractSet = new Set<Id>();
        for (Opportunity o : newOppList) {
            if (oldOppMap.get(o.Id) != null && (o.StageName == 'Closed Won' || o.StageName == 'Closed Lost')) {
                opptyIdSet.add(o.Id);
                if (o.StageName == 'Closed Won' && o.Finance_Partner__c != null)
                    opptyIdForContractSet.add(o.Id);
            }
        }
        List<Finance_Partner_Quote__c> listFPQ = [SELECT Id FROM Finance_Partner_Quote__c
                                                  WHERE Financing_Decision__c = 'Pending' AND Opportunity__c IN: opptyIdSet];
        List<Finance_Partner_Quote__c> listFPQForUpdate = new List<Finance_Partner_Quote__c>();
        FOR(Finance_Partner_Quote__c recFPQ : listFPQ) {
            recFPQ.Financing_Decision__c = 'Withdrawn ';
            listFPQForUpdate.add(recFPQ);
        }
        List<Contract> listContractForUpdate = new List<Contract>();
        FOR(Contract recCon : [SELECT Id, Finance_Partner_Account__c, SBQQ__Opportunity__r.Finance_Partner__c  FROM Contract
                               WHERE SBQQ__Opportunity__c IN: opptyIdForContractSet AND SBQQ__Opportunity__r.Finance_Partner__c != null
                               AND SBQQ__Opportunity__r.StageName = 'Closed Won' AND SBQQ__Opportunity__r.Finance_Partner__r.Is_Finance_Partner_Active__c = true]) {
                                   recCon.Finance_Partner_Account__c = recCon.SBQQ__Opportunity__r.Finance_Partner__c;
                                   listContractForUpdate.add(recCon);
                               }
        if(listFPQForUpdate.size()>0) {
            update listFPQForUpdate;
        }
        if(listContractForUpdate.size()>0) {
            update listContractForUpdate;
        }
    }
    // added for GTMS-16003 ends here
    
    public void deleteQuotaOpportunityRecords(Map<Id, Opportunity> oldOppMap,
                                              Map<Id, Opportunity> newOppMap,
                                              List<Opportunity> newOppList) 
    {
        Set<Id> filteredOpportunityIds = new Set<Id>();
        List<Quota_Opportunity__c> relatedQuotaOpportunities = new List<Quota_Opportunity__c>();
        for (Opportunity updatedOpportunity : newOppList) {
            if ((oldOppMap.get(updatedOpportunity.Id).IsWon == true) && (newOppMap.get(updatedOpportunity.Id).IsWon == false)) {
                filteredOpportunityIds.add(updatedOpportunity.Id);
            }
        }
        if ((Schema.sObjectType.Quota_Opportunity__c.isAccessible()) && (filteredOpportunityIds.size() > 0)) {
            relatedQuotaOpportunities = [SELECT Id FROM Quota_Opportunity__c WHERE Opportunity__r.Id IN :filteredOpportunityIds];
            if (relatedQuotaOpportunities.size() > 0) {
                try {
                    delete relatedQuotaOpportunities;
                } catch (DMLException e) {
                    system.debug('Unable to delete the QO records because of the following exception: ' + e.getMessage());
                }
            }
        }
    }
    public void freeTrialQuoteCreator(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap, List<Opportunity> newOppList) {
        Id freeTrailTemplateId;
        if (checkRecursive.runOnce('FreeTrialInvoice', 'FreeTrialInvoiceTrigger') && !System.isFuture()) {
            boolean free_trial_invoice = false;
            for (Opportunity o : newOppList) {
                if ((newOppMap.get(o.Id).Type == 'Free Trial Opportunity' && newOppMap.get(o.Id).Send_Invoice__c == True 
                    && oldOppMap.get(o.Id).Send_Invoice__c != newOppMap.get(o.Id).Send_Invoice__c) || Test.IsRunningTest()) {
                    free_trial_invoice = true;
                }
            }
            //EmailTemplate et;
            OrgWideEmailAddress owa;
            List<Opportunity> opps;
            List<OpportunityLineItem> line_items;
            if (free_trial_invoice) {
                // code was move to freeTrialQuoteCreatorMain
                freeTrialQuoteCreatorMain(oldOppMap, newOppMap, newOppList);
            }
        }
    }
    
    @testVisible
    private void freeTrialQuoteCreatorMain(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap, List<Opportunity> newOppList) {
        Id freeTrailTemplateId;
        OrgWideEmailAddress owa;
        List<Opportunity> opps;
        List<OpportunityLineItem> line_items;
        //et = [Select Id, Subject, HtmlValue, Body from EmailTemplate where Name = 'FT Invoice Email'];
        if (!(trailLangugeTemplateIdMap.size() > 0)) {
            trailLangugeTemplateIdMap = TemplateSelectionHelper.getTemplates('Free Trail');
        }
        owa = (!Test.IsRunningTest()) ? [select Id from OrgWideEmailAddress Where Address = 'trials@samsara.com'] : null;
        opps = [
            Select Id, Name, PriceBook2Id, Trial_Primary_Contact__c, Trial_Primary_Contact__r.Id, Trial_Primary_Contact__r.Email,
            Account.Billing_Email__c, Account.Name, Account.Which_written_language__c, Account.Owner.Email,
            Trial_primary_contact__r.isEmailBounced , Shipping_Contact_Email__c //GTMS-8575
            from Opportunity
            where Id in :newOppMap.keySet()
        ];
        line_items = [
            SELECT Description,Id,Discount,ListPrice,Name,OpportunityId,Product2Id,PriceBookEntryId,ProductCode,Quantity,TotalPrice,UnitPrice
            FROM OpportunityLineItem
            where OpportunityId in :newOppMap.keySet()
        ];
        for (Opportunity o : opps) {
            String language;
            if ((newOppMap.get(o.Id).Type == 'Free Trial Opportunity' && newOppMap.get(o.Id).Send_Invoice__c == True 
                && oldOppMap.get(o.Id).Send_Invoice__c != newOppMap.get(o.Id).Send_Invoice__c) || Test.isRunningTest()) {
                Quote q = new Quote();
                q.Name = 'FT Quote-' + o.name;
                q.OpportunityId = o.Id;
                q.PriceBook2Id = o.PriceBook2Id;
                q.ContactId = o.Trial_Primary_Contact__c;
                q.BillingName = o.Account.Name;
                q.Email = o.Account.Billing_Email__c;
                insert q;
                for (OpportunityLineItem oli : line_items) {
                    if (oli.OpportunityId == o.Id) {
                        QuoteLineItem qLine = new QuoteLineItem();
                        qLine.QuoteId = q.Id;
                        qLine.Quantity = oli.Quantity;
                        qLine.UnitPrice = oli.UnitPrice;
                        qLine.Discount = oli.Discount;
                        qLine.PriceBookEntryId = oli.PriceBookEntryId;
                        insert qLine;
                    }
                }
                language = o.Account.Which_written_language__c;
                if ((!String.isBlank(language)) && (trailLangugeTemplateIdMap.containsKey(language))) {
                    freeTrailTemplateId = trailLangugeTemplateIdMap.get(language);
                } else {
                    freeTrailTemplateId = trailLangugeTemplateIdMap.get('English');
                }
                //GTMS-8575
                String validEmail = '';
                validEmail = o.Trial_primary_contact__r.isEmailBounced ? (o.Account.Billing_Email__c != null ? o.Account.Billing_Email__c : o.Shipping_Contact_Email__c) : o.Trial_Primary_Contact__r.Email;
                     if(validEmail != null && validEmail != '' && !Test.isRunningTest()){
                    //GTMS-8575
                    FreeTrialInvoicing.sendEmail(q.Id, o.Id, o.Trial_Primary_Contact__r.Id, o.Account.Owner.Email, validEmail, owa.Id, freeTrailTemplateId);
                }
            }
        }
    }
    
    public void rebateBuyoutSubsidyToNetsuite(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap, List<Opportunity> newOppList) {
        if (HelperClass.firstRun) {
            for (Opportunity o : newOppMap.values()) {
                if (!(Test.isRunningTest()) && o.Type == 'Rebate' && newOppMap.get(o.Id).StageName.equals('Finance Processing') && o.Returning_Opportunity_Closed_Won__c == true && oldOppMap.get(o.Id).Push_Return_to_Netsuite__c != true &&
                    newOppMap.get(o.Id).Push_Return_to_Netsuite__c == true && String.isBlank(o.Corresponding_Netsuite_ID__c)) {
                        if (o.Rebate_Type__c == 'Renewal Credit') {
                            integrator_da__.RealTimeExporter.run('rebate-renewal-credit-sync');
                        }
                        HelperClass.firstRun = false;
                    }
            }
        }
    }
    public Integer getQtyLimitPerProduct(String oppType){
        if(oppType == 'Free Trial Opportunity' || oppType == 'Promo Opportunity')
            return 10;
        else if(oppType == 'Revenue Opportunity')
            return 20;
        return null;
    }
    
    //* Dec 17th, 2020 Ron (GTMS-2033) expressSetAnnualDiscountLineItem (pull back in for Webstore Deals + legacy AE1 deals)
    // After the Annual Discount logic is deprecated, this method can be given a generic name -@Harsha
    public void expressSetAnnualDiscountLineItem(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap) {
        if (OpportunityHelperContext.expressSetDiscountRun) {
            return;
        }
        loadOppFields(newOppMap);
        Map<String, String> prodCodesToDispatchMap = new Map<String, String>();
        List<OpportunityLineItem> opptyLToUpdate = new List<OpportunityLineItem>();
        List<String> lstDCLProdCodes = new List<String>();
        List<String> byPassShipFromLocation = System.Label.GTMS_ShipFromLocationProducts.split(',');
        for (Opportunity newOpp : newOppMap.values()) {
            Opportunity oldOpp = oldOppMap.get(newOpp.Id);
            String prodCodesToDispatch = '';
            Decimal productCount = newOpp.of_HW_Products__c + newOpp.of_Accessories__c;
            Decimal expressSelectedDiscount = newOpp.Express_Selected_Discount__c != null ? newOpp.Express_Selected_Discount__c : 0;
            
            if(oldOpp.StageName != 'Orders Processing' && newOpp.StageName == 'Orders Processing' 
               && (newOpp.Shipping_Country__c == 'United States' || newOpp.Shipping_Country__c == 'Canada' || newOpp.Shipping_Country__c == 'Mexico')) {
                   if((((((newOpp.Type == 'Promo Opportunity' && satisfyPromoOpp(newOpp))
                          || (newOpp.Type == 'Revenue Opportunity' && satisfyRevenueOpp(newOpp))
                          || (newOpp.Type == 'Free Trial Opportunity' && satisfyFreeTrailOpp(newOpp)))
                         && satisfyMatchingconditions(newOpp))) 
                       || Test.IsRunningTest()))
            {
                lstDCLProdCodes = OrderAutomationService.getProductCodesByCountryAndType(newOpp.Shipping_Country__c, newOpp.Type);
                Boolean productFlag = true;
                for (OpportunityLineItem oli : oppFields.get(newOpp.Id).OpportunityLineItems) {
                    // modified below condition to cater condition for canada GTMS-10997
                    // commented the oli.Quantity for GTMS-18017 and GTMS-10999
                    if (lstDCLProdCodes.contains(oli.ProductCode) && oli.Quantity >= 1 
                        && (oli.Ship_To_Country__c == 'United States' || oli.Ship_To_Country__c == 'Canada' || oli.Ship_To_Country__c == 'Mexico')) 
                    {
                        prodCodesToDispatch = prodCodesToDispatch + ',' + oli.ProductCode;
                    } else {
                        productFlag = false;
                    }
                }
                if (prodCodesToDispatch != '' && productFlag == true) {
                    prodCodesToDispatchMap.put(newOpp.Id, prodCodesToDispatch);
                    }
                }
            }
            if (((newOpp.Selected_Payment_Type__c != null && oldOpp.Selected_Payment_Type__c != newOpp.Selected_Payment_Type__c) 
                 || newOpp.Name.contains('Webstore')) && newOpp.Configuration_Segment__c != null && newOpp.Configuration_Segment__c == 'Express' 
                && newOpp.Probability < 95 && newOpp.Total_License_Due__c > 0 && newOpp.SBQQ__PrimaryQuote__c == null) 
            {
                // logic has been moved to sub method
                expressSetAnnualDiscountLineItemSub(newOpp, oppFields.get(newOpp.Id).OpportunityLineItems);
                
            }
            //Zakeer-GTMS-5183-Feb17 //GTMS-13653
            if(newOpp.Ship_From_Location__c != oldOppMap.get(newOpp.Id).Ship_From_Location__c
               && oppFields <> NULL && oppFields.get(newOpp.Id) <> NULL && oppFields.get(newOpp.Id).OpportunityLineItems <> NULL
               && !((oppFields.get(newOpp.Id).OpportunityLineItems).isEmpty())){
                   //System.debug('Updating Ship_From_Location for Opportunity: ' + newOpp.Id);
                   for(OpportunityLineItem l : oppFields.get(newOpp.Id).OpportunityLineItems){
                       if( !byPassShipFromLocation.contains(l.Ship_From_Location__c) && newOpp.Ship_From_Location__c != l.Ship_From_Location__c){
                           l.Ship_From_Location__c = newOpp.Ship_From_Location__c;
                           opptyLToUpdate.add(l);
                       }
                   }
               }
        }
        
        /**
* @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
* @date 2020-10-06
* @deprecated per request of Ron. This logic is no longer needed with the launch of CPQ
*/
        if (opptyLToUpdate.size() > 0) {
            //System.debug('Updating OpportunityLineItems: ' + opptyLToUpdate.size());        
            OpportunityHelperContext.expressSetDiscountRun = true;
            //update opptyLToUpdate;
            DMLWrapper.doUpdate(opptyLToUpdate);
        }
        
        // DLC Warehouse Quantity future class changed to Queueable class as part of GTMS-22357
        if(!prodCodesToDispatchMap.isEmpty() && !Test.isRunningTest() ){
            System.debug('expressSetAnnualDiscountLineItem ----> 2');
            ValidateProductQuantityQueueable que = new ValidateProductQuantityQueueable(prodCodesToDispatchMap);
            System.enqueueJob(que);
        }
          
    }
    
    // sub method for expressSetAnnualDiscountLineItem to handle processing opportunity line item
    @testvisible private List<OpportunityLineItem> expressSetAnnualDiscountLineItemSub(Opportunity newOpp, List<OpportunityLineItem> optyLineItems) 
    {
        Decimal expressSelectedDiscount = newOpp.Express_Selected_Discount__c != null ? newOpp.Express_Selected_Discount__c : 0;
        List<OpportunityLineItem> opptyLToUpdate = new List<OpportunityLineItem>();
        for (OpportunityLineItem oli : optyLineItems) {
            OpportunityLineItem triggerHandlerOli;
            if(OpportunityTriggerHandler.opportunityLineItems != null && OpportunityTriggerHandler.opportunityLineItems.get(oli.Id) != null){
                triggerHandlerOli = OpportunityTriggerHandler.opportunityLineItems.get(oli.Id);
            } else{
                triggerHandlerOli = new OpportunityLineItem(Id = oli.Id, Express_Selected_Discount__c = oli.Express_Selected_Discount__c, 
                                                            Discount = oli.Discount, Express_Annual_Discount__c = oli.Express_Annual_Discount__c, Selected_Sales_Price__c = oli.Selected_Sales_Price__c, 
                                                            UnitPrice = oli.UnitPrice);
            }
            if (oli.ProductCode.contains('LIC')) {
                if (newOpp.Selected_Payment_Type__c == 'Direct Annual') {
                    triggerHandlerOli.Express_Annual_Discount__c = (((newOpp.Total_License_Due__c - (newOpp.Total_License_Due__c * (1 - (newOpp.Express_Annual_Discount__c / 100)))) / (newOpp.Total_License_Due__c / (1 - (expressSelectedDiscount / 100)))) * 100);
                    if (newOpp.Express_Selected_Discount__c != null) {
                        triggerHandlerOli.Discount = newOpp.Express_Selected_Discount__c + triggerHandlerOli.Express_Annual_Discount__c;
                    } else if (triggerHandlerOli.Discount != null) {
                        triggerHandlerOli.Discount = triggerHandlerOli.Discount + triggerHandlerOli.Express_Annual_Discount__c;
                    } else {
                        triggerHandlerOli.Discount = triggerHandlerOli.Express_Annual_Discount__c;
                    }
                    if (newOpp.License_Term__c != null) {
                        triggerHandlerOli.Selected_Sales_Price__c = triggerHandlerOli.UnitPrice * (100 - triggerHandlerOli.Discount) / (newOpp.License_Term__c * 100);
                    } else {
                        triggerHandlerOli.Selected_Sales_Price__c = triggerHandlerOli.UnitPrice * (100 - triggerHandlerOli.Discount) / (36 * 100);
                    }
                } else if (newOpp.Selected_Payment_Type__c == 'Upfront Payments') {
                    triggerHandlerOli.Express_Upfront_Discount__c = (((newOpp.Total_License_Due__c - (newOpp.Total_License_Due__c * (1 - (newOpp.Express_Upfront_Discount__c / 100)))) / (newOpp.Total_License_Due__c / (1 - (expressSelectedDiscount / 100)))) * 100);
                    if (newOpp.Express_Selected_Discount__c != null) {
                        triggerHandlerOli.Discount = newOpp.Express_Selected_Discount__c + triggerHandlerOli.Express_Upfront_Discount__c;
                    } else if (triggerHandlerOli.Discount != null) {
                        triggerHandlerOli.Discount = triggerHandlerOli.Discount + triggerHandlerOli.Express_Upfront_Discount__c;
                    } else {
                        triggerHandlerOli.Discount = triggerHandlerOli.Express_Upfront_Discount__c;
                    }
                    if (newOpp.License_Term__c != null) {
                        triggerHandlerOli.Selected_Sales_Price__c = triggerHandlerOli.UnitPrice * (100 - triggerHandlerOli.Discount) / (newOpp.License_Term__c * 100);
                    } else {
                        triggerHandlerOli.Selected_Sales_Price__c = triggerHandlerOli.UnitPrice * (100 - triggerHandlerOli.Discount) / (36 * 100);
                    }
                } else {
                    triggerHandlerOli.Express_Annual_Discount__c = 0;
                    if (newOpp.Express_Selected_Discount__c != null) {
                        triggerHandlerOli.Discount = newOpp.Express_Selected_Discount__c + triggerHandlerOli.Express_Annual_Discount__c;
                    } else if (triggerHandlerOli.Discount != null) {
                        triggerHandlerOli.Discount = triggerHandlerOli.Discount + triggerHandlerOli.Express_Annual_Discount__c;
                    } else {
                        triggerHandlerOli.Discount = triggerHandlerOli.Express_Annual_Discount__c;
                    }
                    if (newOpp.License_Term__c != null) {
                        triggerHandlerOli.Selected_Sales_Price__c = triggerHandlerOli.UnitPrice * (100 - triggerHandlerOli.Discount) / (newOpp.License_Term__c * 100);
                    } else {
                        triggerHandlerOli.Selected_Sales_Price__c = triggerHandlerOli.UnitPrice * (100 - triggerHandlerOli.Discount) / (36 * 100);
                    }
                }
                //System.debug('Adding OpportunityLineItem to update: ' + triggerHandlerOli.Id);
                opptyLToUpdate.add(triggerHandlerOli);
                OpportunityTriggerHandler.opportunityLineItems.put(oli.Id, triggerHandlerOli);
            }
        }
        return opptyLToUpdate;
    }
    
    // Promo opp criteria for automation
    public boolean satisfyPromoOpp(Opportunity opp){
        if(!opp.Multi_Line_Shipping__c 
           && (opp.Sales_Tax__c == 0 || opp.Sales_Tax__c == null) 
           && (opp.Balance_Due__c == 0 || opp.Balance_Due__c == null) 
           && (opp.Shipping_and_Handling__c == 0 || opp.Shipping_and_Handling__c == null)
           && (opp.Shipping_and_Handling_Manual__c == 0 || opp.Shipping_and_Handling_Manual__c == null) 
           && (opp.Shipping_and_Handling_Amount__c == 0 || opp.Shipping_and_Handling_Amount__c == null)){
               return true;
           }

        return false;
    }
    
    // Free-Trail opp criteria for automation
    // Canada, EMEA and Mexico Free Trial automation will be executed from freeTrialOpptyUScadEmeaMexicoLogic.OpportunityHelperBeforeUpdate
    // Because they do not require api callout to check warehouse availability
    public boolean satisfyFreeTrailOpp(Opportunity opp){
        if((opp.Shipping_Country__c == 'United States' || opp.Shipping_Country__c == 'Canada') 
           && opp.Shipping_Address_NEW__c != null
           && (opp.Segment_Sales_Role__c == 'AE2' || opp.Segment_Sales_Role__c == 'AE3' || opp.Segment_Sales_Role__c == 'ENT' || opp.Segment_Sales_Role__c == 'Enterprise' || Test.isRunningTest())
           && String.isBlank(opp.Order_Ops_Notes__c))
        {
            return true;
        }
        return false;
    }
    //Revenue opp criteria for automation
    // Modified the satisfyRevenueOpp filter conditions for GTMS-18017 and GTMS-10999
    public boolean satisfyRevenueOpp(Opportunity opp){
        if(opp.Shipping_and_Handling__c != null && opp.Shipping_and_Handling__c < 99999
           && String.isBlank(opp.Order_Ops_Notes__c)
           && opp.Sub_Type__c != 'Virtual Return'
           && (((opp.Shipping_Country__c == 'United States' || opp.Shipping_Country__c == 'Canada')
                && ((opp.Owner_Segment__c == 'SMB' || opp.Owner_Segment__c == 'Small business') 
                    || (opp.Segment_Sales_Role__c == 'AE1' 
                        && opp.Free_Trial_Purchase__c == null) 
                    || ((opp.Segment_Sales_Role__c == 'AE2' || opp.Segment_Sales_Role__c == 'AE3' || opp.Segment_Sales_Role__c == 'Enterprise') 
                        && (opp.name.contains('Webstore') ? (opp.Free_Trial_Purchase__c == null) : (opp.Free_Trial_Purchase__c == 'No Purchase')) 
                        && ((opp.CurrencyIsoCode == 'USD' || opp.CurrencyIsoCode == 'CAD') 
                            && opp.Amount < Decimal.valueOf(System.Label.US_Canada_EMEA_Amount_Threshold)))))
               
               || (opp.Shipping_Country__c == 'Mexico' 
                   && (opp.Segment_Sales_Role__c == 'AE2' || opp.Segment_Sales_Role__c == 'Enterprise') 
                   && (opp.name.contains('Webstore') ? (opp.Free_Trial_Purchase__c == null) : (opp.Free_Trial_Purchase__c == 'No Purchase')) 
                   && opp.CurrencyIsoCode == 'MXN'
                   && opp.Amount < Decimal.valueOf(System.Label.Mexico_Amount_Threshold)))) 
        {
                   return true;
               }

        return false;
    }
    
    // Modified the satisfyMatchingconditions filter conditions for GTMS-18017 and GTMS-10999
    public boolean satisfyMatchingconditions(Opportunity opp){
        Boolean validatedShipFromLoc = OrderAutomationService.satisfyShipFromLocation(opp);
        Boolean validatedPOBox = !OrderAutomationService.validatePoBox(opp);
        if(String.isBlank(opp.Shipping_Instructions__c) 
           && String.isBlank(opp.Internal_RFO_Notes__c) 
           && opp.Hold_Reason__c == null 
           && (opp.Price_Book_Name__c != null && opp.Price_Book_Name__c == 'Samsara FY22')
           && validatedPOBox
           && validatedShipFromLoc)
        {
               return true;
           }
    
        return false;
    }
    
    public void accountFieldUpdate(List<Opportunity> lstOpportunityNew, Map<Id, Opportunity> mapOpportunityOld) {
        loadOppAccounts(lstOpportunityNew);
        Map<Id, Account> mapAccount = new Map<Id, Account>();
        Set<Id> closedWonOpportunityIdSet = new Set<Id>();
        for(Opportunity opp : lstOpportunityNew){
            if(opp.StageName == 'Closed Won' && mapOpportunityOld.get(opp.Id).StageName != 'Closed Won'){
                closedWonOpportunityIdSet.add(opp.Id);
            }
        }
        Map<Id, Channel_Relationship__c> opptyIdToChannelRelMap = new Map<Id, Channel_Relationship__c>();
        if(!closedWonOpportunityIdSet.isEmpty()){
            for(Channel_Relationship__c chnl : [Select Id, Opportunity__c, Channel_Partner__c, Program_Type__c, CreatedDate from Channel_Relationship__c where Opportunity__c IN :closedWonOpportunityIdSet]){
                if((opptyIdToChannelRelMap.containsKey(chnl.Opportunity__c) && opptyIdToChannelRelMap.get(chnl.Opportunity__c).CreatedDate < chnl.CreatedDate) || !opptyIdToChannelRelMap.containsKey(chnl.Opportunity__c)){
                    opptyIdToChannelRelMap.put(chnl.Opportunity__c, chnl);
                }
            }
        }
        for (Opportunity opp : lstOpportunityNew) {
            Account a = oppAccountsRev.get(opp.AccountId);
            String accountStatus;
            if(opptyIdToChannelRelMap.containsKey(opp.Id)){
                if(a.Id <> opptyIdToChannelRelMap.get(opp.Id).Channel_Partner__c){ //GTMS-13629
                    a.Latest_Partner_Account_Interaction__c = opptyIdToChannelRelMap.get(opp.Id).Channel_Partner__c;
                }
                a.Latest_Partner_Program_Interaction__c = opptyIdToChannelRelMap.get(opp.Id).Program_Type__c;
            }
            Opportunity oldOpp = new Opportunity();
            Boolean oldOppNull = true;
            if (mapOpportunityOld != null) {
                oldOpp = mapOpportunityOld.get(opp.Id);
                oldOppNull = false;
            }
            if (a != null) {
                if (a.Status__c != 'Open Opportunity' && opp.StageName != 'Closed Lost' && opp.StageName != 'Closed Won'
                    && ((opp.StageName != oldOpp.StageName && !oldOppNull) || oldOppNull) && opp.Type == 'Revenue Opportunity') {
                        accountStatus = 'Open Opportunity';
                    } else if (opp.StageName == 'Closed Won' && opp.StageName != oldOpp.StageName && opp.Type == 'Revenue Opportunity') {
                        accountStatus = 'Existing Customer';
                    }
                //Sri Global - Anil Bogadi: Last order opportunity link in Account Object - GTMS-3913.
                if( opp.StageName == 'Closed Won' && opp.StageName != oldOpp.StageName && opp.Type == 'Revenue Opportunity'){
                    a.Link_to_Last_Order__c  = URL.getOrgDomainUrl().toExternalForm() + '/' + opp.Id;
                }
                if (accountStatus != null) {
                    a.Status__c = accountStatus;
                    DMLWrapper.doUpdate(a, new List<SObjectField>{
                        Account.Status__c
                            });
                }
            }
            // Groundswell : Tanuj - WFlow Rule - Update Account for NS Sync
            Account thisOppAccount = new Account();
            if (opp.AccountId != NULL && oppAccounts.containsKey(opp.AccountId)) {
                thisOppAccount = oppAccounts.get(opp.AccountId);
                OpportunityWorkflowConversion.afterUpdateMethod(opp, oldOpp, thisOppAccount);
                OpportunityWorkflowConversion.afterInsertUpdateMethod(opp, oldOpp, thisOppAccount);
            }
        }
    }
    
    public void updateContractDate(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
        Set<Id> oppIdsToUpdate = new Set<Id>();
        Map<Id, Integer> amendedContractTrialDiffs = new Map<Id, Integer>();
        
        for (Opportunity opp : newOppList) {
            Opportunity oldOpp = oldOppMap.get(opp.Id);
            Boolean isTrialPeriodChanged = opp.Trial_Period__c != oldOpp.Trial_Period__c;
            Boolean isFreeTrialApproved = opp.Free_Trial_Extension_Status__c != oldOpp.Free_Trial_Extension_Status__c && opp.Free_Trial_Extension_Status__c == 'Approved';
            
            if (isFreeTrialApproved || isTrialPeriodChanged) {
                oppIdsToUpdate.add(opp.Id);
            }
            
            if (isTrialPeriodChanged && opp.SBQQ__AmendedContract__c != null) {
                Integer trialPeriodDiff = Integer.valueOf(opp.Trial_Period__c - oldOpp.Trial_Period__c);
                amendedContractTrialDiffs.put(opp.SBQQ__AmendedContract__c, trialPeriodDiff);
            }
        }
        
        if (!oppIdsToUpdate.isEmpty() || !amendedContractTrialDiffs.isEmpty()) {
            System.enqueueJob(new OpportunityAmendmentQueueable(JSON.serialize(amendedContractTrialDiffs), oppIdsToUpdate));
        }
    }
    
    public void sendReturnLabelEmail(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap) {
        // Could be modified to a process builder
        Map<Id, Opportunity> returnOpptysToEmail = new Map<Id, Opportunity>();
        Map<Id, Opportunity> holdReasonOpptysToEmail = new Map<Id, Opportunity>();
        String returnRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
        Set<String> finalStages = new Set<String>{'Return Cancelled', 'Partially Received'};

        for (Opportunity o : newOppMap.values()) {
            if (o.type == 'Free Trial Return' || o.type == 'Exchange' || o.type == 'Remorse Refund' || o.type == 'Warranty Exchange') {
                if (o.Return_Label_Attachment__c != null && !o.Bypass_return_Email__c &&
                    ((!System.Label.Commercial_Invoice_Inernational_Shipment.contains(o.Shipping_Country__c) && ((o.StageName != oldOppMap.get(o.Id).StageName && o.StageName == 'Return Label Sent') || (o.StageName != oldOppMap.get(o.Id).StageName && o.StageName == 'Finance Processing'
                                                                                                                                                                                                          && o.Sub_Type__c == 'Upgrade' && o.type == 'Remorse Refund'))) //20484
                     || (System.Label.Commercial_Invoice_Inernational_Shipment.contains(o.Shipping_Country__c) && o.Return_Label_Attachment__c != oldOppMap.get(o.Id).Return_Label_Attachment__c && o.Return_Label_Attachment__c.contains(',') && o.StageName == 'Return Label Sent')
                     || (o.Resend_Return_Email__c != oldOppMap.get(o.Id).Resend_Return_Email__c && o.Resend_Return_Email__c))) {
                         if (o.Tracking_Number__c != NULL && o.Shipping_Address_NEW__c != NULL) {
                             returnOpptysToEmail.put(o.Id, o);
                         }
                     }
            }
            // GTMS-25173 Start           
            Opportunity oldOpp = oldOppMap.get(o.Id);            
            if (o.RecordTypeId == returnRecordTypeID && o.Hold_Reason__c != oldOpp.Hold_Reason__c && String.isNotBlank(o.Hold_Reason__c) && !finalStages.contains(o.StageName)){                    
                holdReasonOpptysToEmail.put(o.Id, o);
            }// GTMS-25173 end
        }
        if (returnOpptysToEmail.size() > 0) {
            ReturnLabelEmailer.sendReturnEmails(returnOpptysToEmail);
        }
        // GTMS-25173 Start        
        if (holdReasonOpptysToEmail.size() > 0) {            
            ReturnLabelEmailer.sendHoldReasonNotifications(holdReasonOpptysToEmail,oppFields);            
        }// GTMS-25173 end
    }
    
    //GTMS-14163
    public void afterUpdateAccount(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList)
    {
        List<dsfs__DocuSign_Status__c> docuSignListToUpdate = new List<dsfs__DocuSign_Status__c> ();
        for(Opportunity opp: newOppList)
        {
            // GTMS-28088: Update BAD on Account with primary quote BAD -->Start
             B360LogicHandler.updateBilling360Account(opp, oldOppMap.get(opp.Id), accountUpdateMap);
            // GTMS-28088: Update BAD on Account with primary quote BAD -->End
            
            if(opp.Type == 'Revenue Opportunity' && opp.RecordTypeId == opportunityRevRecordTypeId && opp.StageName == 'Ready to Ship'
               && opp.Payment_Type_Opportunity_only_Exception__c == false && String.isNotBlank(opp.Selected_Payment_Type__c)
               && opp.of_LIC_Products__c > 0 && opp.Is_Webstore_Upsell_Opportunity__c == false
               && opp.Small_Fleet_Opportunity__c == false) {
                   if(!accountUpdateMap.containsKey(opp.AccountId)) {
                       accountUpdateMap.put(Opp.AccountId, new Account(Id = opp.AccountId));
                   }
                   accountUpdateMap.get(Opp.AccountId).Approved_Payment_Type__c = opp.Selected_Payment_Type__c;
               }
            Opportunity oldopp = (oldOppMap != null && oldOppMap.containsKey(opp.Id))?   oldOppMap.get(opp.Id):null;
            Opportunity oppo = (oppFields != null )? oppFields.get(opp.Id):null;
            if(oppo != null && oppo.SBQQ__PrimaryQuote__c != null && oppo.SBQQ__PrimaryQuote__r.DCA_Validation__c == 'DCA' 
               && opp.StageName == 'Closing' && opp.StageName != oldopp?.StageName){
                   String accountPOException = oppo.Account.Customer_require_PO_for_invoicing__c;
                   if(opp.Customer_require_PO_for_invoicing__c =='Yes' && (String.isBlank(accountPOException) || accountPOException == 'No')){
                       if(!accountUpdateMap.containsKey(opp.AccountId)) {
                           accountUpdateMap.put(Opp.AccountId, new Account(Id = opp.AccountId));
                       }
                       accountUpdateMap.get(Opp.AccountId).Customer_require_PO_for_invoicing__c = 'Yes';
                   }else if(opp.Customer_require_PO_for_invoicing__c =='No' &&  (String.isBlank(accountPOException))){
                       if(!accountUpdateMap.containsKey(opp.AccountId)) {
                           accountUpdateMap.put(Opp.AccountId, new Account(Id = opp.AccountId));
                       }
                       accountUpdateMap.get(Opp.AccountId).Customer_require_PO_for_invoicing__c = 'No';
                   }
               }
            if( oppo != null && ! string.isBlank(opp.Customer_require_PO_for_invoicing__c) && opp.Customer_require_PO_for_invoicing__c != oldopp?.Customer_require_PO_for_invoicing__c && opp.isClosed == false){
                List<dsfs__DocuSign_Status__c> docuSignStatus = oppo?.R00N80000002fD9vEAE;
                for(dsfs__DocuSign_Status__c docu:docuSignStatus){
                    if( string.isBlank( docu.Customer_require_PO_for_invoicing__c)){
                        docu.Customer_require_PO_for_invoicing__c = opp.Customer_require_PO_for_invoicing__c;
                        docu.PO_Number__c = opp.PO_Number__c;
                        docuSignListToUpdate.add(docu);
                        break ;
                    }
                }
            }
        }
        if(docuSignListToUpdate.size() >0){
            update docuSignListToUpdate;
        }
        updateAccountRecords();
        /*
TriggerHandler.bypass('GS_OpportunityTriggerHandler');
TriggerHandler.bypass('OpportunityTriggerHandler');
TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
TriggerHandler.bypass('AccountTriggerHandler');
TriggerHandler.bypass('GS_AccountTriggerHandler');
TriggerHandler.bypass('ContractTriggerHandler');
TriggerHandler.bypass('GS_ContactTriggerHandler');
TriggerHandler.bypass('ContactTriggerHandler');
SBQQ.TriggerControl.disable();
update accounts.Values();
SBQQ.TriggerControl.enable();
TriggerHandler.clearAllBypasses();
*/
    }
    
    public void updateChildTrialOptyTrialStatus(Map<Id, Opportunity> oldOppMap, list<Opportunity> newOppList){
        
        loadOppFields(newOppList);
        
        for(Opportunity opty :newOppList){
            
            if(opty.stageName != 'Ready to Ship' || oldOppMap.get(opty.Id).stageName == 'Ready to Ship' || (oppFields.containsKey(opty.Id) && oppFields.get(opty.Id) != null && (oppFields.get(opty.Id).Type != 'Revenue Opportunity' || oppFields.get(opty.Id).Opportunities__r == null)))
                continue;
            
            if(oppFields.containsKey(opty.Id) && oppFields.get(opty.Id) != null && oppFields.get(opty.Id).Opportunities__r != null) {
            for(Opportunity trialOpty : oppFields.get(opty.Id).Opportunities__r){
                
                if(trialOpty.Type != 'Free Trial Opportunity') continue;
                
                if(opty.Free_Trial_Purchase__c == 'Full Buy') trialOpty.Trial_Status__c = 'Purchased';
                if(opty.Free_Trial_Purchase__c == 'Partial Buy') trialOpty.Trial_Status__c = 'Partial Purchase';
                
                if(trialOpty.Trial_Status__c == 'Purchased' || trialOpty.Trial_Status__c == 'Partial Purchase') DMLWrapper.doUpdate(trialOpty, new List<SObjectField>{Opportunity.Trial_Status__c});
            }
        }
    } 
    } 
    
    //GTMS-27166
    public void sendWarrantyExchangeEOLEmail(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap) {
        
        ReturnLabelEmailer.sendWarrantyExchangeEmailAlert(oldOppMap, newOppMap);
        
    }

        //Frame your Logger message 
        public static String getLoggerMessage(String message) {
            return message.length() > 130072 ? message.substring(0, 130072) : message;
        }
    //GTMS-16221 -- Created method to check for closed won opps and pass to Future method
    /*public void populateFinacePartneronAccount(Map<Id,Opportunity> mapOldOpp, List<opportunity> newOppList){
Set<Id> closedWonOpportunityAccIdSet = new Set<Id>();
Set<Id> closedWonOpportunityIdSet = new Set<Id>();
for(Opportunity opp : newOppList){
if(mapOldOpp == null && opp.StageName == 'Closed Won' &&  opp.Finance_Partner__c != null && opp.Type == 'Revenue Opportunity'){
closedWonOpportunityAccIdSet.add(opp.AccountId);
closedWonOpportunityIdSet.add(opp.Id);
}
else if(mapOldOpp !=null && opp.StageName == 'Closed Won' && mapOldOpp.get(opp.Id).StageName != 'Closed Won' &&  opp.Finance_Partner__c != null && opp.Type == 'Revenue Opportunity'){
system.debug('***populateFinacePartneronAccountCheckPASSED');
closedWonOpportunityAccIdSet.add(opp.AccountId);
closedWonOpportunityIdSet.add(opp.Id);
}
}
if(!closedWonOpportunityAccIdSet.isEmpty()){
String JsonoppAccIds = JSON.serialize(closedWonOpportunityAccIdSet);
String JsonoppIds = JSON.serialize(closedWonOpportunityIdSet);
//GTMS-16221 -- Invoking below future method to process the required logic as update is on Account object
if(!System.isFuture() && !System.isScheduled() && !System.isQueueable() && !System.isBatch()){
populateFinacePartneronAccountFuture(JsonoppAccIds,JsonoppIds);
}
}
}

@Future
public static void populateFinacePartneronAccountFuture(String jsonOppAccIds, String jsonOppIds){
Set<Id> oppAccIds = (Set<Id>)JSON.deserialize(jsonOppAccIds,Set<Id>.class);
Set<Id> oppIds = (Set<Id>)JSON.deserialize(jsonOppIds,Set<Id>.class);
Map<Id, Opportunity> oldestOpportunityMap = new Map<Id, Opportunity>();
List<Account> listAccountstoUpdate = new List<Account>();
List<Finance_Partner_Quote__c> listFPQstoUpdate = new List<Finance_Partner_Quote__c>();
List<Opportunity> listOpportunities = new List<Opportunity>([SELECT Id, Name, AccountId, CloseDate,Finance_Partner__c FROM Opportunity WHERE AccountId In:oppAccIds and StageName = 'Closed Won' and Finance_Partner__c != '' and Type = 'Revenue Opportunity' ORDER BY CloseDate ASC]);
List<Finance_Partner_Quote__c> listfpqValues = new List<Finance_Partner_Quote__c>([Select Id,Name,Opportunity__c,Finance_Partner__c,Opportunity__r.AccountId,Opportunity__r.Type,Opportunity__r.StageName,Opportunity__r.contractId,Opportunity__r.Finance_Partner__c,Opportunity__r.contract.EndDate from Finance_Partner_Quote__c where Opportunity__c In:oppIds]);
system.debug('***populateFinacePartneronAccountFuture'+listOpportunities);
for (Opportunity opp : listOpportunities) {
if (!oldestOpportunityMap.containsKey(opp.AccountId)) {
// If account is not already in the map, add the opportunity
oldestOpportunityMap.put(opp.AccountId, opp);
} else {
// Check if the current opportunity's close date is earlier than the one in the map
Opportunity existingOldestOpportunity = oldestOpportunityMap.get(opp.AccountId);
if (opp.CloseDate < existingOldestOpportunity.CloseDate) {
// Update the map if the current opportunity is older
oldestOpportunityMap.put(opp.AccountId, opp);
}
}
system.debug('***populateFinacePartneronAccountFutureMAP'+oldestOpportunityMap);
}
//To set Finance Partner and 3PF customer Fields on Account
for (Opportunity opp : oldestOpportunityMap.values()) {
Account acc = new Account();
acc.Id = opp.AccountId;
acc.Finance_Partner__c = opp.Finance_Partner__c;
acc.X3PF_Customer__c = true;
listAccountstoUpdate.add(acc);
}
//Update accounts with Finance Partner
if(listAccountstoUpdate.size() > 0){
update listAccountstoUpdate;
}
//To set Contract EndDate on FPQ records
if(listfpqValues.size() > 0){
for(Finance_Partner_Quote__c fpquote:listfpqValues){
Finance_Partner_Quote__c fpq = new Finance_Partner_Quote__c();
fpq.Id = fpquote.Id;
fpq.Contract_End_Date__c = fpquote.Opportunity__r.contract.EndDate;
listFPQstoUpdate.add(fpq);
}
}
//Update Contract EndDate on FPQ records
if(listFPQstoUpdate.size() >0){
update listFPQstoUpdate;
}
}*/

       
 // GTMS 28514
 
public String createOLIForPromo(Map<Id, Opportunity> oldMap, List<Opportunity> newList, Boolean isFromButton) {
	Set<Id> closingOppIds = new Set<Id>();
	List<OpportunityLineItem> toInsert = new List<OpportunityLineItem>();

	try {
		if (isFromButton) {
			for (Opportunity o : newList) closingOppIds.add(o.Id);
		} else {
			for (Opportunity o : newList) {
				Opportunity oldO = oldMap != null ? oldMap.get(o.Id) : null;
				if (oldO != null
					&& oldO.StageName != o.StageName
					&& (o.StageName == 'Closing' || o.StageName == 'Orders Processing' || o.StageName == 'Ready to Ship')
					&& (o.of_Accessories__c > 0 || o.of_HW_Products__c > 0)) {
					closingOppIds.add(o.Id);
				}
			}
		}

		List<SFS_Promo_Product_Setting__mdt> settings = [
			SELECT Active__c, Deal_Type__c, Product_Id__c, Quantity__c, Segment__c, Opportunity_Type__c,
			       Allowed_Profiles_for_Button__c, Shipping_Country__c, Owner_Roles__c, Min_ACV_USD__c, Evaluation_Order__c
			FROM SFS_Promo_Product_Setting__mdt
			WHERE Active__c = true
			ORDER BY Evaluation_Order__c ASC NULLS LAST, DeveloperName ASC
		];  
        //For test class coverage
        if (Test.isRunningTest() && OpportunityHelperAfterUpdate.testSettingsOverride != null) {
          settings = testSettingsOverride;
}

		if (settings.isEmpty()) return '';
		Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
			SELECT Id, Pricebook2Id, StageName, Segment_Sales_Role__c, Type, ACV_Bookings_USD__c, Owner_Role_Copy__c,
			       First_Purchase__c, Purchase_Type__c, Renewal__c, Shipping_Country__c
			FROM Opportunity
			WHERE Id IN :closingOppIds
		]);
		if (oppMap.isEmpty()) return '';
        
		for (SFS_Promo_Product_Setting__mdt s : settings) {
			// Per-rule criteria
			Set<String> ruleTypes      = String.isBlank(s.Opportunity_Type__c) ? new Set<String>() : new Set<String>(s.Opportunity_Type__c.split(','));
			Set<String> ruleOwnerRoles = String.isBlank(s.Owner_Roles__c)      ? new Set<String>() : new Set<String>(s.Owner_Roles__c.split(','));
			Set<String> ruleSegments   = String.isBlank(s.Segment__c)          ? new Set<String>() : new Set<String>(s.Segment__c.split(','));
			Set<String> ruleDealTypes  = String.isBlank(s.Deal_Type__c)        ? new Set<String>() : new Set<String>(s.Deal_Type__c.split(','));
			Set<String> ruleCountries  = String.isBlank(s.Shipping_Country__c) ? new Set<String>() : new Set<String>(s.Shipping_Country__c.split(','));

			if (String.isBlank(s.Product_Id__c)) continue;
			Id ruleProductId;
			try { ruleProductId = (Id)s.Product_Id__c.trim(); } catch (Exception e) { continue; }

			for (Opportunity o : oppMap.values()) {
				Boolean oppTypeOk = ruleTypes.isEmpty()      || ruleTypes.contains(o.Type);
				Boolean ownerOk   = ruleOwnerRoles.isEmpty() || ruleOwnerRoles.contains(o.Owner_Role_Copy__c);
				Boolean segOk     = ruleSegments.isEmpty()   || ruleSegments.contains(o.Segment_Sales_Role__c);
				Boolean roleMatch = !ruleOwnerRoles.isEmpty() ? ownerOk : segOk;
				Boolean dealOk = ruleDealTypes.isEmpty() || ruleDealTypes.contains(o.Purchase_Type__c) || o.First_Purchase__c == true;
				Boolean ctryOk = ruleCountries.isEmpty() || ruleCountries.contains(o.Shipping_Country__c);
				Decimal oppAcv = (o.ACV_Bookings_USD__c == null) ? 0 : o.ACV_Bookings_USD__c;
				Decimal minAcv = (s.Min_ACV_USD__c     == null) ? 0 : s.Min_ACV_USD__c;
				Boolean acvOk  = oppAcv >= minAcv;

				if (!(roleMatch && dealOk && ctryOk && acvOk && oppTypeOk)) continue;
				// Existing OLI for THIS rule's product
				Integer existsCnt = [
					SELECT COUNT()
					FROM OpportunityLineItem
					WHERE OpportunityId = :o.Id
					  AND PricebookEntry.Product2Id = :ruleProductId
				];
				if (existsCnt > 0) continue;

				// Build OLI for this single product
				List<OpportunityLineItem> built =
					createOLIForProducts(o, new Set<String>{ String.valueOf(ruleProductId) }, s.Quantity__c);
				if (!built.isEmpty()) toInsert.addAll(built);
			}
		}

		if (!toInsert.isEmpty()) {
			insert toInsert;
			Logger.atInfo().setClassName('OpportunityHelperAfterUpdate')
				.setMethod('createOLIForPromo')
				.setExceptionOrMessage('Inserted OLIs: ' + toInsert.size());
			if (isFromButton) return 'OpportunityLineItem for Promo Product is created';
		}
	} catch (Exception e) {
		Logger.atError().setClassName('OpportunityHelperAfterUpdate')
			.setMethod('createOLIForPromo')
			.setExceptionOrMessage(e);
		if (isFromButton) return 'Error: ' + e.getMessage();
	} finally {
		Logger.setPrimaryObjectName('Opportunity');
		Logger.setFunctionalityType('Promo OLI Creation');
		Logger.setFunctionalitySubType(isFromButton ? 'Quick Action' : 'CMDT Driven');
		Logger.insertMasterLogs();
	}
	return '';
}
    
    public  List<OpportunityLineItem> createOLIForProducts(Opportunity opp, Set<String> productIds, Decimal quantity) {
	System.debug('insidecreateoli');
	List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
	if (opp == null || opp.Id == null || opp.Pricebook2Id == null || productIds == null || productIds.isEmpty()) return oliList;

	Set<Id> productIdSet = new Set<Id>();
	for (String pidStr : productIds) if (String.isNotBlank(pidStr)) productIdSet.add((Id)pidStr.trim());
	if (productIdSet.isEmpty()) return oliList;

	
	// Find a matching PBE in the Opp's pricebook
	PricebookEntry pbe = [
		SELECT Id, UnitPrice
		FROM PricebookEntry
		WHERE Product2Id IN :productIdSet
		  AND Pricebook2Id = :opp.Pricebook2Id
		  AND IsActive = true
		LIMIT 1
	];
          System.debug('pbe' + pbe);

	if (pbe != null) {
		oliList.add(new OpportunityLineItem(
			OpportunityId   = opp.Id,
			PricebookEntryId= pbe.Id,
			Quantity        = (quantity == null ? 1 : quantity),
			UnitPrice       = 0
		));
	}
	return oliList;
}

}