/* 
 * Class Created: 10/19/18 - Epic SS-8 @author: Harsha
 * 12/10/2018 - SS-173 @author: Harsha
 */ 
  
/* Class to associate quota's and oppoortunities so that reporting can be done on quota object */
public without sharing class AssociateQuotaOpportunity {

    //Map to get the mapped values from the method calculatedRates()
    Map<String, Map<Date, Double>> rateMap = new Map<String, Map<Date, Double>>();

    /* Method to find the related opportunities and valid quotas */
    public void mapQuotaAndOpportunities(){

        Map<Id, Quota__c> mapOfValidQuotas = new Map<Id, Quota__c>();
        List<Quota_Opportunity__c> finalQuotaOpportunities = new List<Quota_Opportunity__c>();
        // SS-173 List to store the old Quota Opportunity before the owner was created and delete it after the new QO is created.
        List<Quota_Opportunity__c> deleteOldQuotaOpportunities = new List<Quota_Opportunity__c>(); 
        List<Date> sortedStartDates = new List<Date>();
        List<Date> sortedEndDates = new List<Date>();
        Date validStartDate;
        Date validEndDate; 

        /* Query to get the valid quotas for the period - Done by using the formula field on the Quota object:
        Will set to true if today lies between the quota start date and end date */
        for(Quota__c quota: [Select User__c, User__r.Name, Role_at_Start_of_Fiscal_Period__c, Quota_Period_Start_Date__c, Quota_Period_End_Date__c, CurrencyIsoCode 
                                    FROM Quota__c 
                                    WHERE Valid_Quota__c = true 
                                    AND Quota_Period_Start_Date__c != null 
                                    AND Quota_Period_End_Date__c != null]){

            mapOfValidQuotas.put(quota.User__c,quota);
            sortedStartDates.add(quota.Quota_Period_Start_Date__c);
            sortedEndDates.add(quota.Quota_Period_End_Date__c);
        }
        
        try{
            sortedStartDates.sort();
            sortedEndDates.sort();
        }
        catch(NullPointerException e){
            system.debug('There is no data in the respective lists ' +e.getMessage());
        }


        /* Have sorted the dates for valid quotas to get the valid start date and end date as quotas might be in months,
        quarters or years  */
        validStartDate = sortedStartDates.get(0);
        validEndDate = sortedEndDates.get(sortedEndDates.size() - 1);

        //Utility class that calculates the rates for each date and currency
        CalculateRates calculatedRates = new CalculateRates(validStartDate , validEndDate);
        rateMap = calculatedRates.getCaluculatedRates();

        //Query to get all the opportunitites which are closed in the valid quota dates and whose amount and commissionable dollars is not null
        //for(Opportunity opportunity: [SELECT Id , OwnerId, Owner.Name, StageName, Map_Quotas__c, Owner_Role_Copy__c, CloseDate , Amount, Commissionable_Dollars__c, CurrencyIsoCode, (SELECT Id, Name, Opportunity_Amount__c, Commissionable_Dollars__c FROM Quota_Opportunities__r) FROM Opportunity WHERE StageName IN ('Closed Won','Refunded - Closed') and Amount NOT IN (null, 0) AND Commissionable_Dollars__c NOT IN (null,0) AND SystemModstamp >=: validStartDate AND SystemModstamp <=:validEndDate]){
            for(Opportunity opportunity : [SELECT Id , OwnerId, Owner.Name, StageName, Owner_Role_Copy__c, CloseDate , Amount, Commissionable_Dollars__c, ACV_Bookings_SOT__c, ACV_Commissionable_Dollars__c, CurrencyIsoCode, 
                                      (SELECT Opportunity_Amount__c, Commissionable_Dollars__c, Opportunity_Close_Date__c, Opportunity_Owner__c, Opportunity__c, CurrencyIsoCode, 
                                              Converted_Opportunity_Amount__c, Converted_Commissionable_Dollars__c FROM Quota_Opportunities__r) 
                                      FROM Opportunity 
                                      WHERE IsWon = true 
                                      AND Amount NOT IN (null, 0)
                                      AND ACV_Bookings_SOT__c NOT IN (null, 0)  
                                      AND Commissionable_Dollars__c NOT IN (null,0) 
                                      AND ACV_Commissionable_Dollars__c NOT IN (null,0) 
                                      AND CloseDate >=: validStartDate 
                                      AND CloseDate <=: validEndDate]){  
                if(mapOfValidQuotas.containsKey(opportunity.OwnerId)){
                    Quota__c relatedQuotaForTheOwner = mapOfValidQuotas.get(opportunity.OwnerId);
                    Date closedDate = opportunity.CloseDate;
                    Date quotaStartDate = relatedQuotaForTheOwner.Quota_Period_Start_Date__c;
                    Date quotaEndDate = relatedQuotaForTheOwner.Quota_Period_End_Date__c;
                    Boolean dateCheck = ((closedDate >= quotaStartDate) && (closedDate <= quotaEndDate) ? true : false );

                     //check to see if the closed opportunity falls under the valid quota start and end date and also check the owner role both on Quota and the Opportunity
                    if((dateCheck) && (opportunity.Owner_Role_Copy__c == relatedQuotaForTheOwner.Role_at_Start_of_Fiscal_Period__c)){
                        Quota_Opportunity__c quotaOpportunity = new Quota_Opportunity__c();
                        // Condition for the new Opportunities that are just closed won and there are no QO's associated
                        if(opportunity.Quota_Opportunities__r.size() == 0 ){
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
        
        if(finalQuotaOpportunities.size() > 0){
            try{
                // insert Quota Opportunities if its a new one else update the exsisting ones
                upsert finalQuotaOpportunities;
            }
            catch(DmlException e){
                system.debug('The following exception has occured during the DML operation ' +e.getMessage());
            }
        }
        //Added as part of SS-173
        if(deleteOldQuotaOpportunities.size() > 0){
                delete deleteOldQuotaOpportunities;
        }
    }

    /* Method to map data to the junction object from Opportunity and Quota */
    public void mapData(Quota_Opportunity__c mapQuotaOpportunity, Opportunity mapOpportunity, Quota__c mapRelatedQuotaForTheOwner){  
        try{
            // rate field stores the rate after calculation's from the method getRate according to convertTo and convertFrom currency
            Double rate = getRate(mapRelatedQuotaForTheOwner.CurrencyIsoCode, mapOpportunity.CurrencyIsoCode, mapOpportunity.CloseDate);
            mapQuotaOpportunity.Commissionable_Dollars__c = mapOpportunity.Commissionable_Dollars__c;
            mapQuotaOpportunity.ACV_Commissionable_Dollars__c = mapOpportunity.ACV_Commissionable_Dollars__c;
            mapQuotaOpportunity.Opportunity_Amount__c = mapOpportunity.Amount;
            mapQuotaOpportunity.Opportunity_ACV_Bookings__c = mapOpportunity.ACV_Bookings_SOT__c;
            mapQuotaOpportunity.Opportunity_Close_Date__c = mapOpportunity.CloseDate;
            mapQuotaOpportunity.Opportunity__c = mapOpportunity.Id;
            mapQuotaOpportunity.Opportunity_Owner__c = mapOpportunity.Owner.Name;
            mapQuotaOpportunity.CurrencyIsoCode = mapOpportunity.CurrencyIsoCode;
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