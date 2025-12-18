global class BatchLinkQuotaForReturnOpp implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
    Map<String, Map<Date, Double>> rateMap = new Map<String, Map<Date, Double>>();
    Date validStartDate;
    Date validEndDate; 
    global Database.QueryLocator start(Database.BatchableContext bc) {
        system.debug('$$$$$$$ Batch Started $$$$$');
        return Database.getQueryLocator(System.Label.Query_ReturnOppsToAddQuotas);
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        system.debug('$$$$$$$records$$$$$' + scope);
        List<Date> sortedStartDates = new List<Date>();
        List<Date> sortedEndDates = new List<Date>();
        Map<Id, Opportunity> returningOppIds = new Map<Id, Opportunity>();
        List<Id> returnOppId = new List<Id>();
        List<Quota_Opportunity__c> quotaOpptyList = new List<Quota_Opportunity__c>();
        for(Opportunity opp : scope) {
            returningOppIds.put(opp.Returning_Opportunity__c, opp);
            returnOppId.add(opp.Returning_Opportunity__c);
        }
        List<Quota_Opportunity__c> lstQO = [SELECT Id, Related_Quota__c, Opportunity_Amount__c, Opportunity__c, Related_Quota__r.Quota_Period_Start_Date__c, 
                                            Related_Quota__r.Quota_Period_End_Date__c, Related_Quota__r.CurrencyIsoCode, Opportunity__r.CloseDate 
                                            FROM Quota_Opportunity__c WHERE Opportunity__c IN: returnOppId];
        if(!returningOppIds.isEmpty()) {
            for(Quota_Opportunity__c qo : lstQO) {
                sortedStartDates.add(qo.Related_Quota__r.Quota_Period_Start_Date__c);
                sortedEndDates.add(qo.Related_Quota__r.Quota_Period_End_Date__c);
            }
        }
        try{
            sortedStartDates.sort();
            sortedEndDates.sort();
        }catch(NullPointerException e){
            system.debug('There is no data in the respective lists ' +e.getMessage());
        }
        if(!sortedStartDates.isEmpty() && !sortedEndDates.isEmpty()) {
            validStartDate = sortedStartDates.get(0);
            validEndDate = sortedEndDates.get(sortedEndDates.size() - 1);
            //Utility class that calculates the rates for each date and currency
            CalculateRates calculatedRates = new CalculateRates(validStartDate , validEndDate);
            rateMap = calculatedRates.getCaluculatedRates();
        }
        
        system.debug('$$$$$$$quotaOpptyList$$$$$' + quotaOpptyList);
        
        if(!returningOppIds.isEmpty()) {
            for(Quota_Opportunity__c qo : lstQO) {
                Quota_Opportunity__c newQuotaOpp = new Quota_Opportunity__c(Related_Quota__c = qo.Related_Quota__c);
                
                mapData(newQuotaOpp, returningOppIds.get(qo.Opportunity__c), qo);
                quotaOpptyList.add(newQuotaOpp);
            }
        }
        if(!quotaOpptyList.isEmpty()) {
            insert quotaOpptyList;
        }
    }
    
    public void mapData(Quota_Opportunity__c mapQuotaOpportunity, Opportunity mapOpportunity, Quota_Opportunity__c oldQOpp){  
        
        //mapQuotaOpportunity.Related_Quota__c = oldQOpp.Related_Quota__c;
        mapQuotaOpportunity.Commissionable_Dollars__c = mapOpportunity.Commissionable_Dollars__c;
        mapQuotaOpportunity.ACV_Commissionable_Dollars__c = mapOpportunity.ACV_Commissionable_Dollars__c;
        mapQuotaOpportunity.Opportunity_Amount__c = mapOpportunity.Amount;
        mapQuotaOpportunity.Opportunity_ACV_Bookings__c = mapOpportunity.ACV_Bookings_SOT__c;
        mapQuotaOpportunity.Opportunity_Close_Date__c = mapOpportunity.CloseDate;
        mapQuotaOpportunity.Opportunity__c = mapOpportunity.Id;
        mapQuotaOpportunity.Opportunity_Owner__c = mapOpportunity.Owner.Name;
        mapQuotaOpportunity.CurrencyIsoCode = mapOpportunity.CurrencyIsoCode;
        // rate field stores the rate after calculation's from the method getRate according to convertTo and convertFrom currency
        Double rate = getRate(oldQOpp.Related_Quota__r.CurrencyIsoCode, mapOpportunity.CurrencyIsoCode, oldQOpp.Opportunity__r.CloseDate);
        system.debug('========Rate======= ' + rate);
        //returned rate value is used in these fields to calculate the values as per dated currency
        if(rate != null) {
            mapQuotaOpportunity.Converted_Opportunity_Amount__c = mapOpportunity.Amount * rate;
            mapQuotaOpportunity.Converted_Opportunity_ACV_Bookings__c = mapOpportunity.ACV_Bookings_SOT__c * rate;
            mapQuotaOpportunity.Converted_Commissionable_Dollars__c = mapOpportunity.Commissionable_Dollars__c * rate;
            mapQuotaOpportunity.Converted_ACV_Commissionable_Dollars__c = mapOpportunity.ACV_Commissionable_Dollars__c * rate;
        }
        
    }
    
    public Double getRate(String convertToCurrency,String convertFromCurrency, Date closeDate){
        
        Double convertedRate;
        if(rateMap.get(convertToCurrency) != null && rateMap.get(convertToCurrency).get(closeDate) != null) {
            convertedRate = ((rateMap.get(convertToCurrency).get(closeDate)/rateMap.get(convertFromCurrency).get(closeDate)));
        }
        return convertedRate;
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
    
    global void execute(SchedulableContext sc){
        BatchLinkQuotaForReturnOpp b;
        b = new BatchLinkQuotaForReturnOpp();
        integer batchsize = 100;
        database.executebatch(b,batchsize);
    }
}