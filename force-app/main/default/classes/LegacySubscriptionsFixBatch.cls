/*
* TestClass = LegacySubscriptionsFixBatchTest

* This Class must be processed with batch size 1, as we are hardcoding the index

* database.executebatch(new LegacySubscriptionsFixBatch(),1);

* Dec-21-2022 Rajesh :- GTMS-10518
*/
global class LegacySubscriptionsFixBatch 
implements Database.Batchable<sObject> {

    static gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    static gslib_ILogger thisLogger = thisModuleLogger.getLogger();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        if(Test.isRunningTest()){
            return Database.getQueryLocator('SELECT id, ContractTerm, SBQQ__RenewalTerm__c, CreatedDate, StartDate, EndDate FROM Contract');
         }
         else{
            return Database.getQueryLocator(Label.LegacySubscriptionsFixBatchQuery);
         }
    }

    global void execute(Database.BatchableContext bc, List<Contract> records){
        Set<Id> contractsSet = new Set<Id>();
        Map<Id,Contract> contracts = new Map<Id,Contract>();
        //List<SBQQ__Subscription__c> subscriptions = new List<SBQQ__Subscription__c>();

        for(Contract c : records){
            contractsSet.add(c.id);
        }
        List<SBQQ__Subscription__c> subscriptions = [SELECT Id, SBQQ__Contract__c, 
                                        SBQQ__Contract__r.ContractTerm, SBQQ__Contract__r.SBQQ__RenewalTerm__c, 
                                        SBQQ__Contract__r.CreatedDate, SBQQ__Contract__r.StartDate, SBQQ__Contract__r.EndDate,
                                        SBQQ__ListPrice__c,SBQQ__ProrateMultiplier__c,NS_Unit_Rate__c,
                                        SBQQ__QuoteLine__r.SBQQ__SubscriptionTerm__c,
                                        SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c,
                                        SBQQ__QuoteLine__r.SBQQ__ListPrice__c,
                                        SBQQ__QuoteLine__r.SBQQ__NetPrice__c,
                                        SBQQ__Contract__r.Sales_Ops_Notes__c,
                                        SBQQ__QuoteLine__c,Prior_OppId__c,Prior_OLI_Id__c
                                        FROM SBQQ__Subscription__c WHERE SBQQ__Contract__c IN : contractsSet];

        if(subscriptions.size() > 0){
            Set<Id> OppsSet = new Set<Id>();
            Set<Id> OLIsSet = new Set<Id>();
            for(SBQQ__Subscription__c s : subscriptions){
                if(s.SBQQ__QuoteLine__c == NULL){
                    if(s.Prior_OLI_Id__c <> NULL){
                        OLIsSet.add(s.Prior_OLI_Id__c);
                    }
                    else if(s.Prior_OppId__c <> NULL){
                        OppsSet.add(s.Prior_OppId__c);
                    }
                }
            }
            
            Map<Id,OpportunityLineItem> priorOLIs =new Map<Id,OpportunityLineItem>([SELECT ID,License_Term_Copy__c,ListPrice, NS_Unit_Rate__c
                                                    FROM OpportunityLineItem 
                                                    WHERE ID IN : OLIsSet]);
            Map<Id,Opportunity> priorOpps = new Map<Id,Opportunity>([SELECT ID,License_Term__c
                                            FROM Opportunity
                                            WHERE ID IN : OppsSet]);

            for(SBQQ__Subscription__c s : subscriptions){
                
                if(s.SBQQ__QuoteLine__c == NULL){
                    if(priorOLIs.containsKey(s.Prior_OLI_Id__c)){
                        s.SBQQ__ProrateMultiplier__c = priorOLIs.get(s.Prior_OLI_Id__c).License_Term_Copy__c / 12;
                        s.SBQQ__ListPrice__c = priorOLIs.get(s.Prior_OLI_Id__c).ListPrice * s.SBQQ__ProrateMultiplier__c;
                        s.SBQQ__SpecialPrice__c = priorOLIs.get(s.Prior_OLI_Id__c).ListPrice;
                    }
                    else if(priorOpps.containsKey(s.Prior_OppId__c)){
                        s.SBQQ__ProrateMultiplier__c = priorOpps.get(s.Prior_OppId__c).License_Term__c / 12;
                        s.SBQQ__SpecialPrice__c = s.SBQQ__ListPrice__c;
                        s.SBQQ__ListPrice__c = s.SBQQ__SpecialPrice__c * s.SBQQ__ProrateMultiplier__c;
                    }
                }
                else{
                    s.SBQQ__ProrateMultiplier__c = s.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c / 12;
                    s.SBQQ__ListPrice__c = s.SBQQ__QuoteLine__r.SBQQ__ListPrice__c * s.SBQQ__ProrateMultiplier__c;
                    s.SBQQ__SpecialPrice__c = s.SBQQ__QuoteLine__r.SBQQ__ListPrice__c;
                }
                    
                if(s.NS_Unit_Rate__c == NULL){
                    if(s.SBQQ__QuoteLine__c <> NULL){
                        s.NS_Unit_Rate__c = s.SBQQ__QuoteLine__r.SBQQ__NetPrice__c;
                    }
                    else if(priorOLIs.containsKey(s.Prior_OLI_Id__c)){
                        s.NS_Unit_Rate__c = priorOLIs.get(s.Prior_OLI_Id__c).NS_Unit_Rate__c;
                    }
                }

                s.SBQQ__NetPrice__c = s.NS_Unit_Rate__c;
                s.SBQQ__CustomerPrice__c = s.NS_Unit_Rate__c;
                s.SBQQ__RenewalPrice__c = s.NS_Unit_Rate__c / s.SBQQ__ProrateMultiplier__c;
                s.SBQQ__RegularPrice__c = s.SBQQ__ListPrice__c;
                s.SBQQ__Discount__c = (1 - (s.NS_Unit_Rate__c / s.SBQQ__ListPrice__c)) * 100;
                s.SBQQ__AdditionalDiscountAmount__c = NULL;
                
                if(contracts.containsKey(s.SBQQ__Contract__c) == false){
                    Contract c = new Contract();
                    
                    c.Id = s.SBQQ__Contract__c;
                    c.SBQQ__RenewalPricebookId__c = '01s4p000004cVodAAE';

                    if(string.isBlank(s.SBQQ__Contract__r.Sales_Ops_Notes__c)){
                        c.Sales_Ops_Notes__c ='Renewal Legacy Data Update';
                    }
                    else{
                        c.Sales_Ops_Notes__c = s.SBQQ__Contract__r.Sales_Ops_Notes__c +  ', Renewal Legacy Data Update';
                    }   
                    

                    if(s.SBQQ__Contract__r.ContractTerm <= 12)
                        c.SBQQ__RenewalTerm__c = 12;
                    if(s.SBQQ__Contract__r.ContractTerm > 12 && s.SBQQ__Contract__r.ContractTerm <= 36)
                        c.SBQQ__RenewalTerm__c = 36;
                    else if(s.SBQQ__Contract__r.ContractTerm > 36 && s.SBQQ__Contract__r.ContractTerm <= 60)
                        c.SBQQ__RenewalTerm__c = 60;
                    else if(s.SBQQ__Contract__r.ContractTerm > 60 && s.SBQQ__Contract__r.ContractTerm <= 72)
                        c.SBQQ__RenewalTerm__c = 72;
                    else if(s.SBQQ__Contract__r.ContractTerm > 72)
                        c.SBQQ__RenewalTerm__c = 84;
                    
                    contracts.put(s.SBQQ__Contract__c, c);
                }
            }

            Set<Id> contractsWithErrors = new Set<Id>();
            if(subscriptions.size() > 0){
                Database.SaveResult[] updatedSubscriptions = Database.update(subscriptions,false);
                for(Integer i = 0; i < updatedSubscriptions.size(); i++){
                    if(!updatedSubscriptions[i].isSuccess() ){
                        for(Database.Error err : updatedSubscriptions[i].getErrors())
                        {
                            thisLogger.logError(err.getStatusCode() + ': ' + err.getMessage() + ', Subscription fields that affected this error: ' + err.getFields());
                        }
                        if(contractsWithErrors.contains(subscriptions[i].SBQQ__Contract__c) == false){
                            contractsWithErrors.add(subscriptions[i].SBQQ__Contract__c);
                        }
                    }
                }
            }
            
            if(contracts.size() > 0){
                Database.SaveResult[] updatedContracts = Database.update(contracts.values(),false);
                for(Integer i = 0; i < updatedContracts.size(); i++){
                    if(!updatedContracts[i].isSuccess()){
                        for(Database.Error err : updatedContracts[i].getErrors())
                        {
                            thisLogger.logError(err.getStatusCode() + ': ' + err.getMessage() + ', Contract fields that affected this error: ' + err.getFields());
                        }
                        if(contractsWithErrors.contains(contracts.values()[i].Id) == false){
                            contractsWithErrors.add(contracts.values()[i].Id);
                        }
                    }
                }  
            }
            
            List<Contract> contractsCorrected = new List<Contract>();
            for(Contract c : contracts.values()){
                if(contractsWithErrors.contains(c.Id) == false){
                    contractsCorrected.add(new Contract(Id = c.Id,Renewal_Data_Clean__c = true));
                }
            }

            if(contractsCorrected.size() > 0){
                update contractsCorrected;
            } 

            if(contractsWithErrors.size() > 0){
                thisLogger.dispatch();
            }
        }
    }

    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
}