public with sharing class GS_TrialOpportunityServiceAsync extends BaseAsyncHandler {
    public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();
 
    public override String getRequestType(){
        return 'Trial Opportunity Async Job';
    } 
    
    List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        Opportunity.SObjectType,
        Account.SOBjectType
    };
    
    /* UnitOfWork uow = new UnitOfWork(MY_SOBJECTS); */
    List<Id> recordsIds = new List<Id>();
    List<Opportunity> oppList;

    private UnitOfWork uow;
    private Options option;
    
    private final Set<String> PRODUCTS_ON_CLOSING_TRIAL_KIT_TYPE = new Set<String> {
        'Transport & Warehousing',
        'Food & Beverage',
        'Standard',
        'FREE-TRIAL-KIT-EU'
    };

    private final Set<String> PRODUCTS_ON_CLOSING_WELCOME_KIT_TYPE = new Set<String> {
        'Standard Welcome Kit'
    };

    public override void execute(Async_Request__c ar){

        recordsIds = ar.Params__c.split(PARAMETERS_SPLITTER);
        if(recordsIds.isEmpty()) return;
        option = (Options) JSON.deserialize(ar.Options__c, Options.class);

        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        
        try{
            thisSamsaraLoggerService.logger.logTrace('Entering in GS_TrialOpportunityServiceAsync');
            switch on option.Operation {
                when 'AFTER_INSERT' {
                    this.loadRecords(recordsIds);

                    this.handleReturnCreation();
                    this.welcomeTrialKitProductsOnClosing();
                }
                when 'BEFORE_UPDATE_OPERATIONS'{
                    this.loadopptyRecordsWithItems(recordsIds);
                    this.handleRevenueUpdate();
                }
                when 'AFTER_UPDATE_OPERATIONS'{
                    this.loadRecords(recordsIds);
                    this.handleReturnUpdate();
                    this.welcomeTrialKitProductsOnClosing();
                }
            }

            this.publishDMLs();
        }catch(Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in GS_TrialOpportunityServiceAsync::', new SamsaraLoggerObjectMVP(
                ex, recordsIds
        ));
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.logTrace('Exiting in GS_TrialOpportunityServiceAsync');
            thisSamsaraLoggerService.logger.dispatch();
        }
    }

    private void loadRecords(List<Id> idList){
        if (this.oppList == null || this.oppList.size() <= 0){
            this.oppList = (new GS_OpportunitySelector(false)).getOppForTrialServiceById(idList);
        }
    }


    private void loadopptyRecordsWithItems(List<Id> idList){
           this.oppList = (new GS_OpportunitySelector(false)).loadOpportunityWithItems(new Set<Id> (idList));
    }

    private void handleRevenueUpdate(){
        
        // Takes a list of Revenue oppties with Stage changes, and updates any trial oppties that point to them
        List<Opportunity> trials = new List<Opportunity>();
        Map<Id, List<Opportunity>> revToTrialOppsMap = new Map<Id, List<Opportunity>>();
        Set<Id> opptyRecordsIds = (new Map<Id,Opportunity>(this.oppList)).keySet();
        Set<Id> opptyIds = new Set<Id>();

        // Map rev opps to associated trials   
        revToTrialOppsMap =  this.mapRevenueOpptyToTrial(opptyRecordsIds);


        // Now we do the work
            // Loop through all rev opps
            for (Opportunity oppty : this.oppList) {
                    if(revToTrialOppsMap.containsKey(oppty.Id)) {
                        for(Opportunity trialOppty : revToTrialOppsMap.get(oppty.Id)) {
                            if(trialOppty.Trial_Status__c == 'Open') {
                                if(!option.conditionMap.isEmpty() 
                                   && option.conditionMap.containsKey(oppty.Id) 
                                   && option.conditionMap.get(oppty.Id)){
                                    
                                    throw new GS_TrialOpportunityServiceAsyncException('You are trying to close a revenue opportunity that already contains one or more unclosed trials. Please close them by ensuring the return of the products.');
                                }
                            }
                            // Loop through all associated trial opps with this rev opp
                            if(trialOppty.Trial_Status__c != 'Returned' 
                               && trialOppty.Trial_Status__c != 'Purchased') {
                                String newStatus = new GS_TrialOpportunityService().getStatusFromResolution(oppty);                            
                                if(String.isBlank(newStatus)){
                                    newStatus=trialOppty.Trial_Status__c;
                                }                    
                                if (newStatus != trialOppty.Trial_Status__c) {
                                    trialOppty.Trial_Status__c = newStatus;
                                    system.debug('trialOppty.Trial_Status__c : '+trialOppty.Trial_Status__c);
                                    DMLWrapper.doUpdate(trialOppty, new List<SobjectField>{
                                            Opportunity.Trial_Status__c
                                    });
                                }
                            }
                        }
                    }
            }
    }

    private void handleReturnUpdate(){
        
        Set<Id> freeTrialOpptyIdsSet = new Set<Id>();
        List<Opportunity> returnUpdates = new List<Opportunity>();
        List<Opportunity> trials = new List<Opportunity>();
        
        if(!option.conditionMap.isEmpty()){
            freeTrialOpptyIdsSet.addAll(option.conditionMap.keySet());
        }

        returnUpdates = (new GS_OpportunitySelector(false)).loadOpportunityWithItems(freeTrialOpptyIdsSet);
        if(returnUpdates.size() > 0) {
            trials = new List<Opportunity>([SELECT Id, Returning_Opportunity__c, Trial_Status__c, StageName  
                                            FROM Opportunity 
                                            WHERE Type = 'Free Trial Opportunity' 
                                            AND Trial_Status__c NOT IN ('Returned','Purchased') 
                                            AND FT_Return__c IN :returnUpdates]);
        }                                               

        for (Opportunity o : returnUpdates) {
            for (Opportunity t : trials) {
                if (o.Returning_Opportunity__c == t.Id) {
                    String newStatus = new GS_TrialOpportunityService().getStatusFromResolution(o);
                    // System.debug(newStatus);
                    
                    if(String.isBlank(newStatus)){
                        newStatus=t.Trial_Status__c;
                    }
                    
                    
                    if (newStatus != t.Trial_Status__c) {
                        t.Trial_Status__c = newStatus;
                        system.debug('In handleReturnUpdate : '+t.Trial_Status__c);
                        system.debug('In handleReturnUpdate Id: '+t.Id);
                        DMLWrapper.doUpdate(t, new List<SobjectField>{
                                Opportunity.Trial_Status__c
                        });
                    }
                }
            }
        }
    }

    private Map<Id, List<Opportunity>> mapRevenueOpptyToTrial(Set<Id> opptyRecordsIds){
        
        // Query all associated trials
        Map<Id, Opportunity> trialOppMap = new Map<Id, Opportunity>();
        trialOppMap = new Map<Id, Opportunity>(new GS_OpportunitySelector(true).checkFatalError().loadFreeTrialOpportunity(opptyRecordsIds));

        // Map rev opps to associated trials
        Map<Id, List<Opportunity>> revToTrialOppsMap = new Map<Id, List<Opportunity>>();
        for(Opportunity t : trialOppMap.values()) {
            // If this trial hasn't been mapped to any rev opps yet, we create a new list with this rev opp and map it to the trial
            if(!revToTrialOppsMap.containsKey(t.TrialResolutionOppty__c) 
               && t.TrialResolutionOppty__c != NULL) {
                List<Opportunity> trialOpps = new List<Opportunity>();
                trialOpps.add(t);
                revToTrialOppsMap.put(t.TrialResolutionOppty__c, trialOpps);
            // If this trial has been mapp to a rev opp already, add this rev opp to the list of mapped opps on this trial
            } else if(revToTrialOppsMap.containsKey(t.TrialResolutionOppty__c)) {
                List<Opportunity> trialOpps = revToTrialOppsMap.get(t.TrialResolutionOppty__c);
                trialOpps.add(t);
                revToTrialOppsMap.put(t.TrialResolutionOppty__c, trialOpps);
            }
        }

        return revToTrialOppsMap;

    }

    /**
     * @description : Determines the status from Type, Probability and StageName.
     */
    private void handleReturnCreation() {

        // Takes a list of return oppties being created and assign its object as a pointer for the trials
        List<Opportunity> trialUpdates = new List<Opportunity>();

        // Create a set of all connected returning opp Ids
        for (Opportunity o : this.oppList) {
            if (this.shouldUpdateReturnOpportunity(o)) {
                Opportunity returningOpportunity = new Opportunity(
                    Id = o.Returning_Opportunity__c,
                    FT_Return__c = o.Id
                );
                DMLWrapper.doUpdate(returningOpportunity, new List<SobjectField>{
                    Opportunity.FT_Return__c
                });
            }
        }
    }

    private Boolean shouldUpdateReturnOpportunity(Opportunity opp){
        return (opp.Type == 'Free Trial Return' && opp.Returning_Opportunity__c != NULL);
    }
    
    private Boolean shouldFireWelcomeTrialKitFlow(Opportunity opp){
        // Validate entry conditions
        Boolean shouldFire = !(opp.AccountId == null || opp.IsClosed || (opp.CurrencyIsoCode == 'MXN'));

        // Also check internal switch conditions that exists on async to avoid unnecessary async records
        return shouldFire
            && (PRODUCTS_ON_CLOSING_TRIAL_KIT_TYPE.contains(opp.Free_Trial_Kit_Type__c)
                || PRODUCTS_ON_CLOSING_WELCOME_KIT_TYPE.contains(opp.Welcome_Kit_Type__c));
    }

    //Replaces: Add Welcome/Trial Kit Products on Closing
    public void welcomeTrialKitProductsOnClosing(){
        List<SObjectField> accountDirtyFields = new List<SObjectField>();
        for(Opportunity opp : this.oppList) {
            
            // Switch statment on the Free Trial Kit Type
            // Depending on the kit type, the Trial Sent Date will be populated on the Account
            // and the "Insert Product" flow will be executed with specific parameters
            Account thisAccount = new Account(Id = opp.AccountId);

            switch on opp.Free_Trial_Kit_Type__c {
                /* Replaces Node 'Free Trial Kit - Transport/Warehousing' */
                when 'Transport & Warehousing' {
                    thisAccount.Free_Trial_Kit_Sent_Date__c = System.today();
                    if (!accountDirtyFields.contains(Account.Free_Trial_Kit_Sent_Date__c)) accountDirtyFields.add(Account.Free_Trial_Kit_Sent_Date__c);
                    this.executeFlow(opp.CurrencyISOCode, 100, opp.Id, opp.Pricebook2Id, welcomeTrialKitProducts.Transport_Warehousing__c, 1, 0, 'DCL', 1);
                }
                /* Replaces Node 'Free Trial Kit - Food/Bev' */
                when 'Food & Beverage' {
                    thisAccount.Free_Trial_Kit_Sent_Date__c = System.today();
                    if (!accountDirtyFields.contains(Account.Free_Trial_Kit_Sent_Date__c)) accountDirtyFields.add(Account.Free_Trial_Kit_Sent_Date__c);
                    this.executeFlow(opp.CurrencyISOCode, 100, opp.Id, opp.Pricebook2Id, welcomeTrialKitProducts.Food_Beverage__c, 1, 0, 'DCL', 1);
                }
                /* Replaces Node 'Insert Free Trial Kit' */
                when 'Standard' {
                    thisAccount.Free_Trial_Kit_Sent_Date__c = System.today();
                    if (!accountDirtyFields.contains(Account.Free_Trial_Kit_Sent_Date__c)) accountDirtyFields.add(Account.Free_Trial_Kit_Sent_Date__c);
                    this.executeFlow(opp.CurrencyISOCode, 100, opp.Id, opp.Pricebook2Id, welcomeTrialKitProducts.Standard__c, 1, 0, 'DCL', 1);
                }
                /* Replaces Node 'Uk Trial Kits' */
                when 'FREE-TRIAL-KIT-EU' {
                    thisAccount.Free_Trial_Kit_Sent_Date__c = System.today();
                    if (!accountDirtyFields.contains(Account.Free_Trial_Kit_Sent_Date__c)) accountDirtyFields.add(Account.Free_Trial_Kit_Sent_Date__c);
                    this.executeFlow(opp.CurrencyISOCode, 100, opp.Id, opp.Pricebook2Id, welcomeTrialKitProducts.UK_Trial_Kits__c, 1, 0, 'VCK', 1);
                }
            }

            switch on opp.Welcome_Kit_Type__c {
                // Commented this as per the request from Marketing team -@Harsha
                // Replaces Node 'Welcome Kit - FS CML
                /*when 'Commercial - Field Services' {
                    accountMap.get(opp.AccountId).Welcome_Kit_Sent_Date__c = System.today();
                    accountsToUpdate.add(accountMap.get(opp.AccountId));
                    this.executeFlow(opp.CurrencyISOCode, 100, opp.Id, opp.Pricebook2Id, welcomeTrialKitProducts.Commercial_Field_Services__c, 1, 0, 'DCL', 1);
                }
                // Replaces Node 'Welcome Kit - FB CML' 
                when 'Commercial - Food & Beverage' {
                    accountMap.get(opp.AccountId).Welcome_Kit_Sent_Date__c = System.today();
                    accountsToUpdate.add(accountMap.get(opp.AccountId));
                    this.executeFlow(opp.CurrencyISOCode, 100, opp.Id, opp.Pricebook2Id, welcomeTrialKitProducts.Commercial_Food_Beverage__c, 1, 0, 'DCL', 1);
                }
                // Replaces Node 'Insert Express Welcome Kit'
                when 'Express Welcome Kit' {
                    accountMap.get(opp.AccountId).Welcome_Kit_Sent_Date__c = System.today();
                    accountsToUpdate.add(accountMap.get(opp.AccountId));
                    this.executeFlow(opp.CurrencyISOCode, 100, opp.Id, opp.Pricebook2Id, welcomeTrialKitProducts.Express_Welcome_Kit__c, 1, 0, 'DCL', 1);
                }*/
                // Replaces Node 'Insert Standard Welcome Kit
                when 'Standard Welcome Kit' {
                    //accountMap.get(opp.AccountId).Welcome_Kit_Sent_Date__c = System.today();
                    //accountsToUpdate.add(accountMap.get(opp.AccountId));
                    thisAccount.Welcome_Kit_Sent_Date__c = System.today();
                    if (!accountDirtyFields.contains(Account.Welcome_Kit_Sent_Date__c)) accountDirtyFields.add(Account.Welcome_Kit_Sent_Date__c);
                    this.executeFlow(opp.CurrencyISOCode, 100, opp.Id, opp.Pricebook2Id, welcomeTrialKitProducts.Standard_Welcome_Kit__c, 1, 0, 'DCL', 1);
                }

            }
            /*switch on opp.Renewal_Kit_Type__c {

                when 'Renewal Kit' {
                    //accountMap.get(opp.AccountId).Renewal_Kit_Sent_Date__c = System.today();
                    //accountsToUpdate.add(accountMap.get(opp.AccountId));
                    thisAccount.Renewal_Kit_Sent_Date__c = System.today();
                    if (!accountDirtyFields.contains(Account.Renewal_Kit_Sent_Date__c)) accountDirtyFields.add(Account.Renewal_Kit_Sent_Date__c);
                    this.executeFlow(opp.CurrencyISOCode, 100, opp.Id, opp.Pricebook2Id, welcomeTrialKitProducts.Renewal_Kits__c, 1, 0, 'DCL', 1);
                }
            }*/
            if (!accountDirtyFields.isEmpty())
                DMLWrapper.doUpdate(thisAccount, accountDirtyFields);
        }
    }

    // Executes the Insert Product Flow with the provided parameters
    private void executeFlow(String currencyCode, Integer discountAmount, Id oppId, Id pbId, Id productId, Integer quantity, Double salesPrice, String shipFrom, Integer shippedQuantity){
        Map<String, Object> params = new Map<String, Object>();
        params.put('inputCurrencyCode', currencyCode);
        params.put('inputDiscountAmount', discountAmount);
        params.put('inputOpportunityId', oppId);
        params.put('inputPricebook2Id', pbId);
        params.put('inputProduct2Id', productId);
        params.put('inputQuantity', quantity);
        params.put('inputSalesPrice', salesPrice);
        params.put('inputShipFromLocation', shipFrom);
        params.put('inputShippedQuantity', shippedQuantity);

        Flow.Interview.Insert_Product insertProductFlow = new Flow.Interview.Insert_Product(params);
        insertProductFlow.start();

        String oppLineItemID = (String) insertProductFlow.getVariableValue('OpportunityLineItemId');
    }
    
    private void publishDMLs() {
        uow = DMLWrapper.uow;
        DMLWrapper.publishDML(uow);
    }
    
    public class Options {
        public String Operation {get; set;}
        public Map<Id, Boolean> conditionMap {get; set;}

        public Options(String operation){
            this.Operation = operation;
        }

        public Options(String operation, Map<Id, Boolean> conditionMap){
            this.Operation = operation;
            this.conditionMap = conditionMap;
        }
    }
    
    private static Welcome_Trial_Kit_Product__mdt welcomeTrialKitProducts {
        get {
            if(welcomeTrialKitProducts == null){
                welcomeTrialKitProducts = [
                    SELECT  Food_Beverage__c, Standard__c, Standard_Welcome_Kit__c, Transport_Warehousing__c, 
                            UK_Trial_Kits__c
                    FROM Welcome_Trial_Kit_Product__mdt
                    WHERE Label = 'Default Product List'
                    LIMIT 1
                ];
                return welcomeTrialKitProducts;
            }else{
                return welcomeTrialKitProducts;
            }
        }
        set;
    }

    /**
     * @description : This functions allows for other services to validate if this async service should be executed
     */
    public Boolean shouldRunAsyncMethodsForRecord(Opportunity opp){
        return (this.shouldFireWelcomeTrialKitFlow(opp) || this.shouldUpdateReturnOpportunity(opp));
    }

    public class GS_TrialOpportunityServiceAsyncException extends Exception {
    }
}