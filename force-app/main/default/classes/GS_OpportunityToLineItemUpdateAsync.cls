public with sharing class GS_OpportunityToLineItemUpdateAsync extends BaseAsyncHandler{
    public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();
    public override String getRequestType(){
        return 'OpportunityToLineItemUpdate Async Job';
    }
    
    List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        OpportunityLineItem.SObjectType
    };

    List<Id> recordsIds;
    List<Opportunity> opptyList;
    public GS_OpportunityCacheService oppCache = new GS_OpportunityCacheService();
    public override void execute(Async_Request__c ar){

        recordsIds = ar.Params__c.split(PARAMETERS_SPLITTER);
        if(recordsIds.isEmpty()) return;
    
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        
        try{
        thisSamsaraLoggerService.logger.logTrace('Entering in GS_OpportunityToLineItemUpdateAsync');
        this.loadOpportunities(recordsIds);

        this.setAnnualDiscountLineItemeUpdateOperations();

        this.publishDMLs();
        }catch(Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in GS_OpportunityToLineItemUpdateAsync::', new SamsaraLoggerObjectMVP(
                ex, recordsIds
        ));
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.logTrace('Exiting in GS_OpportunityToLineItemUpdateAsync');
            thisSamsaraLoggerService.logger.dispatch();
        }
    }

    private void loadOpportunities(List<Id> idList){
        if (opptyList == null){
            this.opptyList = (new GS_OpportunitySelector(false)).loadOpportunityWithItems(new Set<Id>(idList));
            oppCache.cacheRelatedIdsFromOpps(this.opptyList);
            oppCache.loadOpportunityWithOpptyLineItems(oppCache.cachedOpportunityIds);
        }
    }

    public void setAnnualDiscountLineItemeUpdateOperations(){
        
        List<OpportunityLineItem> opptyLToUpdate = new List<OpportunityLineItem>();

        for (Opportunity newOpp : this.opptyList) {
            Decimal expressSelectedDiscount = newOpp.Express_Selected_Discount__c != null ? newOpp.Express_Selected_Discount__c : 0;
            for (OpportunityLineItem oli : oppCache.loadedOpportunityWithOpptyLineItemsMap.get(newOpp.Id).OpportunityLineItems) {
                        
                OpportunityLineItem triggerHandlerOli;
                
                    triggerHandlerOli = new OpportunityLineItem(Id = oli.Id, Express_Selected_Discount__c = oli.Express_Selected_Discount__c, Discount = oli.Discount, Express_Annual_Discount__c = oli.Express_Annual_Discount__c, Selected_Sales_Price__c = oli.Selected_Sales_Price__c, UnitPrice = oli.UnitPrice);

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
                    opptyLToUpdate.add(triggerHandlerOli);
                }
            }
        }

        /**
        * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
        * @date 2020-10-06
        * @deprecated per request of Ron. This logic is no longer needed with the launch of CPQ
        */
        if (opptyLToUpdate.size() > 0) {
            //update opptyLToUpdate;
            DMLWrapper.doUpdate(opptyLToUpdate);
        }
    
    }


    private void publishDMLs() {
        DMLWrapper.publishDML();
    }

    //* Dec 17th, 2020 Ron (GTMS-2033) expressSetAnnualDiscountLineItem (pull back in for Webstore Deals + legacy AE1 deals)
    // After the Annual Discount logic is deprecated, this method can be given a generic name -@Harsha
    public void expressSetAnnualDiscountLineItem(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOpportunityList, GS_OpportunityCacheService oppCache) {
        Map<String, String> prodCodesToDispatchMap = new Map<String, String>();
        List<String> lstDCLProdCodes = new List<String>();
        Set<Id> opptyIdsSet = new Set<Id>();
        oppCache.loadOpportunityWithOpptyLineItems(oppCache.cachedOpportunityIds);

        for (Opportunity newOpp : newOpportunityList) { 
            Opportunity oldOpp = oldOppMap.get(newOpp.Id);
            String prodCodesToDispatch = '';
            Decimal productCount = newOpp.of_HW_Products__c + newOpp.of_Accessories__c;
        
                if (oldOpp.StageName != 'Orders Processing' 
                    && newOpp.StageName == 'Orders Processing' 
                    &&(newOpp.Type == 'Free Trial Opportunity' 
                       || newOpp.Type == 'Promo Opportunity')
                    && (newOpp.Ship_From_Location__c == 'DCL' 
                        || newOpp.Ship_From_Location__c == 'DCL-KY')
                    && oldOpp.Probability < 98 
                    && newOpp.CurrencyIsoCode == 'USD' 
                    && newOpp.Hold_Reason__c == null 
                    && newOpp.Order_Ops_Notes__c == null 
                    && newOpp.Shipping_Address_NEW__c != null 
                    && newOpp.Unique_Shipping_Addresses__c == 1 
                    && productCount <= 50 
                    && (newOpp.Shipping_Method__c == '3 Day Select' 
                        || newOpp.Shipping_Method__c == 'Ground' 
                        || newOpp.Shipping_Method__c == 'Next Day Air') 
                    && new GS_OpportunityService().checkDCLQualified(newOpp, oldOpp)) {
                    lstDCLProdCodes = System.Label.DCL_Product_SKU_List.split(',');
                    Boolean productFlag = true;
                    for (OpportunityLineItem oli : oppCache.loadedOpportunityWithOpptyLineItemsMap.get(newOpp.Id).OpportunityLineItems) {
                        system.debug('lstDCLProdCodes :'+lstDCLProdCodes);
                        system.debug('oli.ProductCode :'+oli.ProductCode);
                        if (lstDCLProdCodes.contains(oli.ProductCode) 
                            && oli.Quantity <= 10 
                            && oli.Quantity >= 1 
                            && oli.Ship_To_Country__c == 'United States') {
                            prodCodesToDispatch = prodCodesToDispatch + ',' + oli.ProductCode;
                        } else {
                            productFlag = false;
                        }
                    }
                        system.debug('prodCodesToDispatch :'+prodCodesToDispatch);
                        system.debug('productFlag :'+productFlag);  
                    if (prodCodesToDispatch != '' 
                        && productFlag == true) {
                        prodCodesToDispatchMap.put(newOpp.Id, prodCodesToDispatch);
                    }
                }

					system.debug('newOpp.Configuration_Segment__c :'+newOpp.Configuration_Segment__c);
                    system.debug('newOpp.Probability :'+newOpp.Probability);
                   system.debug('newOpp.Total_License_Due__c :'+newOpp.Total_License_Due__c);
            
                if (((newOpp.Selected_Payment_Type__c != null 
                            && oldOpp.Selected_Payment_Type__c != newOpp.Selected_Payment_Type__c)
                            || newOpp.Name.contains('Webstore'))
                        && newOpp.Configuration_Segment__c != null 
                        && newOpp.Configuration_Segment__c == 'Express' 
                        && newOpp.Probability < 95 
                        && newOpp.Total_License_Due__c > 0 
                        && newOpp.SBQQ__PrimaryQuote__c == null) {
                            opptyIdsSet.add(newOpp.Id);
                    }   

                if(!opptyIdsSet.isEmpty()){
                    DMLWrapper.doInsert(new GS_OpportunityToLineItemUpdateAsync().prepareAsyncRequests(
                        opptyIdsSet
                    ));
                }        

            if (!prodCodesToDispatchMap.isEmpty()) {
                System.debug('About to call ValidateProductQuantityFeature');
                ValidateProductQuantityFuture.fetchProductQuantity(prodCodesToDispatchMap);
            }
        }
    }

    public void updateLicenseTermToMatchParentOpportunity(Opportunity oppty){
        /* Replaces Node 'License Term Changes' */
        for(OpportunityLineItem oli : oppty.OpportunityLineItems){
            oli.License_Term_Copy__c = oppty.License_Term__c;
            DMLWrapper.doUpdate(oli, new List<SObjectField>{OpportunityLineItem.License_Term_Copy__c});
            //System.debug('OpportunityProcessBuilderConversion - Running Node: License Term Changes');
        }
    }
 
    public void updateShipToToMatchAddressFromOpportunity(Opportunity oppty){
        System.debug(LoggingLevel.INFO, 'Shipping Address Change');
        /* Replaces Node 'Product Added or Opp's Shipping Address Changes' */
        for(OpportunityLineItem oli : oppty.OpportunityLineItems){
            oli.Ship_To__c = oppty.Shipping_Address_NEW__c;
            DMLWrapper.doUpdate(oli, new List<SObjectField>{OpportunityLineItem.Ship_To__c});
            //System.debug('OpportunityProcessBuilderConversion - Running Node: Product Added or Opp\'s Shipping Address Changes');
        }
    }

}