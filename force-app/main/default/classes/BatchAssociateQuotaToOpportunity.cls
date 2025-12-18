/*
* 9/13/2022 Siddharth Kumar Mishra GTMS-9365:Adding null check to eliminate List index out of bounds error
* 9/28/2022 Siddharth Kumar Mishra GTMS-9641:moving the subquery to the execute method to eliminate CPU time limit exceeded error
*/
global class BatchAssociateQuotaToOpportunity implements Database.Batchable<sObject>, Database.Stateful, Schedulable  {
    Map<String, Map<Date, Double>> rateMap = new Map<String, Map<Date, Double>>();
    Map<Id, Quota__c> mapOfValidQuotas = new Map<Id, Quota__c>();
    Date validStartDate;
    Date validEndDate; 
    global Database.Querylocator start(Database.BatchableContext BC) 
    {
        System.debug('in Start');
        List<Date> sortedStartDates = new List<Date>();
        List<Date> sortedEndDates = new List<Date>();
        for(Quota__c quota: [Select User__c, User__r.Name, Role_at_Start_of_Fiscal_Period__c, Quota_Period_Start_Date__c, Quota_Period_End_Date__c, CurrencyIsoCode 
                             FROM Quota__c 
                             WHERE Valid_Quota__c = true 
                             AND Quota_Period_Start_Date__c != null 
                             AND Quota_Period_End_Date__c != null])
        {
            
            mapOfValidQuotas.put(quota.User__c,quota); 
            sortedStartDates.add(quota.Quota_Period_Start_Date__c);
            sortedEndDates.add(quota.Quota_Period_End_Date__c);
        }    
        try{
            sortedStartDates.sort();
            sortedEndDates.sort();
        }catch(Exception e){
            system.debug('There is no data in the respective lists ' +e.getMessage());
        }
        /* Have sorted the dates for valid quotas to get the valid start date and end date as quotas might be in months,
        quarters or years  */        
        String validStartDateString;  
        String validEndDateString; 

        validStartDate = sortedStartDates.get(0);
        validStartDateString = String.valueOf(sortedStartDates.get(0));
        validEndDate = sortedEndDates.get(sortedEndDates.size() - 1);
        validEndDateString = String.valueOf(sortedEndDates.get(sortedEndDates.size() - 1));

        //Utility class that calculates the rates for each date and currency        
        CalculateRates calculatedRates = new CalculateRates(validStartDate , validEndDate);
        rateMap = calculatedRates.getCaluculatedRates();
        //String Quota_query = 'SELECT Id , OwnerId, Owner.Name, StageName, Owner_Role_Copy__c, CloseDate , Amount, Commissionable_Dollars__c, ACV_Bookings_SOT__c, ACV_Commissionable_Dollars__c, CurrencyIsoCode,'+ '(SELECT Opportunity_Amount__c, Commissionable_Dollars__c, Opportunity_Close_Date__c, Opportunity_Owner__c, Opportunity__c, CurrencyIsoCode,'+'Converted_Opportunity_Amount__c, Converted_Commissionable_Dollars__c FROM Quota_Opportunities__r)'+ ' FROM Opportunity'+ ' WHERE IsWon = true'+' AND Amount NOT IN (null, 0)'+' AND ACV_Bookings_SOT__c NOT IN (null, 0)'+' AND Commissionable_Dollars__c NOT IN (null,0)'+ ' AND ACV_Commissionable_Dollars__c NOT IN (null,0)'+ ' AND CloseDate >= '+ validStartDateString +' AND CloseDate <= '+ validEndDateString;
        //String Quota_query1 = 'SELECT Id FROM Opportunity'+ ' WHERE IsWon = true'+' AND Amount NOT IN (null, 0)'+' AND ACV_Bookings_SOT__c NOT IN (null, 0)'+' AND Commissionable_Dollars__c NOT IN (null,0)'+ ' AND ACV_Commissionable_Dollars__c NOT IN (null,0)'+ ' AND CloseDate >= '+ validStartDateString +' AND CloseDate <= '+ validEndDateString;
        String query = System.Label.BatchAssociateQuotaOppQuery;
        query =  query + ' '+ 
            'AND CloseDate >= ' + validStartDateString + ' '+ 
            'AND CloseDate <= '+ validEndDateString;
        return Database.getQueryLocator(query);
    }    
    //GTMS-9641
    global void execute(Database.BatchableContext BC, List<Opportunity> scopeIds) 
    {
        //GTMS-9641
        List<id> oppIdList = new List<id>(); 
        for(Opportunity opportunity : scopeIds)
        {
            oppIdList.add(opportunity.Id);
        }
        //GTMS-9641
        List<Opportunity> scope = [Select OwnerId, Owner.Name, StageName, Owner_Role_Copy__c, CloseDate , Amount, Commissionable_Dollars__c, ACV_Bookings_SOT__c, ACV_Commissionable_Dollars__c, CurrencyIsoCode,(SELECT Opportunity_Amount__c, Commissionable_Dollars__c, Opportunity_Close_Date__c, Opportunity_Owner__c, Opportunity__c, CurrencyIsoCode,Converted_Opportunity_Amount__c, Converted_Commissionable_Dollars__c FROM Quota_Opportunities__r) FROM Opportunity WHERE id IN:oppIdList];
        //List<Opportunity> scope = [Select OwnerId, Owner.Name, StageName, Owner_Role_Copy__c, CloseDate , Amount, Commissionable_Dollars__c, ACV_Bookings_SOT__c, ACV_Commissionable_Dollars__c, CurrencyIsoCode,(SELECT Opportunity_Amount__c, Commissionable_Dollars__c, Opportunity_Close_Date__c, Opportunity_Owner__c, Opportunity__c, CurrencyIsoCode,Converted_Opportunity_Amount__c, Converted_Commissionable_Dollars__c FROM Quota_Opportunities__r) FROM Opportunity WHERE id IN:scopeIds];
		System.debug('scope'+scope.size());
        List<Quota_Opportunity__c> finalQuotaOpportunities = new List<Quota_Opportunity__c>();
        // SS-173 List to store the old Quota Opportunity before the owner was created and delete it after the new QO is created.
        List<Quota_Opportunity__c> deleteOldQuotaOpportunities = new List<Quota_Opportunity__c>(); 
        for(Opportunity opportunity : scope){  
            if(mapOfValidQuotas.containsKey(opportunity.OwnerId)){
                Quota__c relatedQuotaForTheOwner = mapOfValidQuotas.get(opportunity.OwnerId);
                Date closedDate = opportunity.CloseDate;
                Date quotaStartDate = relatedQuotaForTheOwner.Quota_Period_Start_Date__c;
                Date quotaEndDate = relatedQuotaForTheOwner.Quota_Period_End_Date__c;
                Boolean dateCheck = ((closedDate >= quotaStartDate) && (closedDate <= quotaEndDate) ? true : false );
                System.debug('dateCheck'+dateCheck);
                System.debug('relatedQuotaForTheOwner.Role_at_Start_of_Fiscal_Period__c'+relatedQuotaForTheOwner.Role_at_Start_of_Fiscal_Period__c); 
                //check to see if the closed opportunity falls under the valid quota start and end date and also check the owner role both on Quota and the Opportunity
                if((dateCheck) && 
                   (opportunity.Owner_Role_Copy__c == relatedQuotaForTheOwner.Role_at_Start_of_Fiscal_Period__c)){
                       System.debug('inside date check');
                       Quota_Opportunity__c quotaOpportunity = new Quota_Opportunity__c();
                       // Condition for the new Opportunities that are just closed won and there are no QO's associated
                       System.debug('opportunity.Quota_Opportunities__r.size()'+opportunity.Quota_Opportunities__r.size());
                       if(opportunity.Quota_Opportunities__r.size() == 0 ){
                           System.debug('inside Quota_Opportunities__r');
                           quotaOpportunity.Related_Quota__c = relatedQuotaForTheOwner.Id;
                           mapData(quotaOpportunity, opportunity, relatedQuotaForTheOwner);
                           finalQuotaOpportunities.add(quotaOpportunity);
                       }
                       //This part checks if there is a quota opportunity already present.
                       else{
                           quotaOpportunity = opportunity.Quota_Opportunities__r;
                           /* If the owner changes mid way after the inital Quota Opportunity has been created 
* since we can't update the exsisiting QO we create a new QO and delete the exsisting.
* Added the logic as part of SS-173
*/
                           if((quotaOpportunity.Opportunity_Owner__c != opportunity.Owner.Name) || (relatedQuotaForTheOwner.User__r.Name != quotaOpportunity.Opportunity_Owner__c)){
                               Quota_Opportunity__c newQuotaOpportunity = new Quota_Opportunity__c();
                               newQuotaOpportunity.Related_Quota__c = relatedQuotaForTheOwner.Id;
                               mapData(newQuotaOpportunity, opportunity, relatedQuotaForTheOwner);
                               finalQuotaOpportunities.add(newQuotaOpportunity);
                               deleteOldQuotaOpportunities.add(quotaOpportunity);
                           }
                           // If the owner remains same and any other field changes exsisting QO is updated.
                           else{
                               quotaOpportunity = opportunity.Quota_Opportunities__r;
                               mapData(quotaOpportunity, opportunity, relatedQuotaForTheOwner);
                               finalQuotaOpportunities.add(quotaOpportunity);
                           }
                       }
                   }
                /* If the role changes for some reason and it does not match it 
* deletes the exsisting QO and on the next run a new QO is created. 
* Added the logic as part of SS-173
*/
                else if((dateCheck) && (relatedQuotaForTheOwner.Role_at_Start_of_Fiscal_Period__c != opportunity.Owner_Role_Copy__c) && (opportunity.Quota_Opportunities__r.size() != 0 )){
                    deleteOldQuotaOpportunities.add(opportunity.Quota_Opportunities__r);
                }
            }       
        }
        System.debug('finalQuotaOpportunities size'+finalQuotaOpportunities);
        if(finalQuotaOpportunities.size() > 0){
            try{
                // insert Quota Opportunities if its a new one else update the exsisting ones
                system.debug('finalQuotaOpportunities'+finalQuotaOpportunities);
                upsert finalQuotaOpportunities;
            }catch(DmlException e){
                system.debug('The following exception has occured during the DML operation ' +e.getMessage());
            }   
        }
        //Added as part of SS-173
        if(deleteOldQuotaOpportunities.size() > 0){
            system.debug('deleteOldQuotaOpportunities'+deleteOldQuotaOpportunities);
            delete deleteOldQuotaOpportunities;
        }
    }
    
    
    global void finish(Database.BatchableContext BC) {
    }   
    
    global void execute(SchedulableContext sc){
        BatchAssociateQuotaToOpportunity b;
        b = new BatchAssociateQuotaToOpportunity();
        integer batchsize = 50;
        //GTMS-9365/9641
        integer quotaCount = [Select COUNT() FROM Quota__c WHERE Valid_Quota__c = true AND Quota_Period_Start_Date__c != null AND Quota_Period_End_Date__c != null];
        if(quotaCount!=0)
        {
            database.executebatch(b,batchsize);
        }        
    }
    
    /* Method to map data to the junction object from Opportunity and Quota */
    public void mapData(Quota_Opportunity__c mapQuotaOpportunity, Opportunity mapOpportunity, Quota__c mapRelatedQuotaForTheOwner){  
        try{
            mapQuotaOpportunity.Commissionable_Dollars__c = mapOpportunity.Commissionable_Dollars__c;
            mapQuotaOpportunity.ACV_Commissionable_Dollars__c = mapOpportunity.ACV_Commissionable_Dollars__c;
            mapQuotaOpportunity.Opportunity_Amount__c = mapOpportunity.Amount;
            mapQuotaOpportunity.Opportunity_ACV_Bookings__c = mapOpportunity.ACV_Bookings_SOT__c;
            mapQuotaOpportunity.Opportunity_Close_Date__c = mapOpportunity.CloseDate;
            mapQuotaOpportunity.Opportunity__c = mapOpportunity.Id;
            mapQuotaOpportunity.Opportunity_Owner__c = mapOpportunity.Owner.Name;
            mapQuotaOpportunity.CurrencyIsoCode = mapOpportunity.CurrencyIsoCode;
            // rate field stores the rate after calculation's from the method getRate according to convertTo and convertFrom currency
            Double rate = getRate(mapRelatedQuotaForTheOwner.CurrencyIsoCode, mapOpportunity.CurrencyIsoCode, mapOpportunity.CloseDate);
            //returned rate value is used in these fields to calculate the values as per dated currency
            mapQuotaOpportunity.Converted_Opportunity_Amount__c = mapOpportunity.Amount * rate;
            mapQuotaOpportunity.Converted_Opportunity_ACV_Bookings__c = mapOpportunity.ACV_Bookings_SOT__c * rate;
            mapQuotaOpportunity.Converted_Commissionable_Dollars__c = mapOpportunity.Commissionable_Dollars__c * rate;
            mapQuotaOpportunity.Converted_ACV_Commissionable_Dollars__c = mapOpportunity.ACV_Commissionable_Dollars__c * rate;
        }
        catch(Exception e){
            system.debug('Error while mapping the data ' +e.getMessage());
        }
    }
    
    /* Gets the rate to convert the currency on the opportunity to the currency in Quota so the amounts can be aggregated to the the related currency 
       of the quota */
    public Double getRate(String convertToCurrency,String convertFromCurrency, Date closeDate){
        Double convertedRate;
        convertedRate = ((rateMap.get(convertToCurrency).get(closeDate)/rateMap.get(convertFromCurrency).get(closeDate)));
        return convertedRate;
    }
}