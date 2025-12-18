/* 
* Class Created: 10/19/18 - Epic SS-8 @author: Harsha
*/
/* Class to calculate the rates for every currency and Date form the valid start date to the valid end date of all the valid quotas */
public without sharing class CalculateRates {
    
    Date quotaValidStartDate;
    Date quotaValidEndDate;
    Map<String, Map<Date, Double>> currencyRateMap = new Map<String, Map<Date, Double>>(); 

    /*Constructor to get the start and the end dates for the available valid quotas which are used to get the
    rates for the valid date range */
    public CalculateRates(Date quotaValidStartDate, Date quotaValidEndDate){
        this.quotaValidStartDate = quotaValidStartDate;
        this.quotaValidEndDate = quotaValidEndDate;
    }

    /*
        private void getCurrencyConversionMap() {
            List<DatedConversionRate> convertedRates = new List<DatedConversionRate>([  SELECT      IsoCode, 
                                                                                                    Conversionrate,
                                                                                                    StartDate,
                                                                                                    NextStartDate
                                                                                        FROM        DatedConversionRate 
                                                                                        WHERE       StartDate <=: quotaValidStartDate
                                                                                        ORDER BY    StartDate                                                                                               
                                                                                    ]);
            Map<Date, Map<String, Double>> ratePerDatePerIso = new Map<Date, Map<String, Double>>();
            // Loop through all dates within range
            for(Date dateIterator = quotaValidStartDate; dateIterator <= quotaValidEndDate; dateIterator.addDays(1)) {
                // For each date, create a map of currency ISO code to conversion rate to USD
            for(DatedConversionRate rate : convertedRates) {
                
            }
        }
        }*/

    //Method to get the dates and rate for Euros
    public void getDateEuroRates(){
        List<DatedConversionRate> convertedRates = new List<DatedConversionRate>([  SELECT  IsoCode, 
                                                                                                Conversionrate,
                                                                                                StartDate,
                                                                                                NextStartDate
                                                                                        FROM    DatedConversionRate 
                                                                                        WHERE   IsoCode = 'EUR' AND StartDate <=: quotaValidEndDate
                                                                                        ORDER BY StartDate]);

        Map< Date, Double> ratePerDate = new Map<Date, Double>();  
        for(DatedConversionRate ratesAndDates: convertedRates){
            Date startDate = ratesAndDates.StartDate;
            Date endDate = ratesAndDates.NextStartDate; 
            //Condition to check the validity of the period ranges from the DatedConversionRate table
            while((startDate < endDate) && (startDate <= quotaValidEndDate)){
                if(quotaValidStartDate > startDate ){
                    startDate = (Date)quotaValidStartDate;
                }
                ratePerDate.put(startDate, ratesAndDates.Conversionrate);
                startDate = startDate.addDays(1);
            }
        }
    currencyRateMap.put('EUR', ratePerDate);
    }

    //Method to get the dates and rate for Pounds
    public void getDatePoundRates(){
        List<DatedConversionRate> convertedRates = new List<DatedConversionRate>([  SELECT  IsoCode, 
                                                                                                Conversionrate,
                                                                                                StartDate,
                                                                                                NextStartDate
                                                                                        FROM    DatedConversionRate 
                                                                                        WHERE   IsoCode = 'GBP'  AND StartDate <=: quotaValidEndDate
                                                                                        ORDER BY StartDate]);

        Map< Date, Double> ratePerDate = new Map<Date, Double>();  

        for(DatedConversionRate ratesAndDates: convertedRates){
            Date startDate = ratesAndDates.StartDate;
            Date endDate = ratesAndDates.NextStartDate; 
            
            while((startDate < endDate)  && (startDate <= quotaValidEndDate)){
                if(quotaValidStartDate > startDate ){
                    startDate = (Date)quotaValidStartDate;
                }
                ratePerDate.put(startDate, ratesAndDates.Conversionrate);
                startDate = startDate.addDays(1);
            }
        }
     currencyRateMap.put('GBP', ratePerDate);
    }

    //Method to get the dates and rate for USD
    public void getDateUSDollarRates(){
        List<DatedConversionRate> convertedRates = new List<DatedConversionRate>([  SELECT  IsoCode, 
                                                                                                Conversionrate,
                                                                                                StartDate,
                                                                                                NextStartDate
                                                                                        FROM    DatedConversionRate 
                                                                                        WHERE   IsoCode = 'USD' AND StartDate <=: quotaValidEndDate
                                                                                        ORDER BY StartDate]);

        Map< Date, Double> ratePerDate = new Map<Date, Double>();  

        for(DatedConversionRate ratesAndDates: convertedRates){
            Date startDate = ratesAndDates.StartDate;
            Date endDate = ratesAndDates.NextStartDate; 
            
            while((startDate < endDate) && (startDate <= quotaValidEndDate)){
                //system.debug('Start Date ' +startDate);
                //system.debug('End Date ' +endDate);

                if(quotaValidStartDate > startDate ){
                    startDate = (Date)quotaValidStartDate;
                }
                ratePerDate.put(startDate, ratesAndDates.Conversionrate);
                startDate = startDate.addDays(1);
            }
        }
    currencyRateMap.put('USD', ratePerDate);
    }

    //Method to get the dates and rate for Pesos
    public void getDatePesoRates(){
        List<DatedConversionRate> convertedRates = new List<DatedConversionRate>([  SELECT  IsoCode, 
                                                                                                Conversionrate,
                                                                                                StartDate,
                                                                                                NextStartDate
                                                                                        FROM    DatedConversionRate 
                                                                                        WHERE   IsoCode = 'MXN' AND StartDate <=: quotaValidEndDate
                                                                                        ORDER BY StartDate]);

        Map< Date, Double> ratePerDate = new Map<Date, Double>();  

        for(DatedConversionRate ratesAndDates: convertedRates){
            Date startDate = ratesAndDates.StartDate;
            Date endDate = ratesAndDates.NextStartDate; 
            
            while((startDate < endDate) && (startDate <= quotaValidEndDate)){
                //system.debug('Start Date ' +startDate);
                //system.debug('End Date ' +endDate);

                if(quotaValidStartDate > startDate ){
                    startDate = (Date)quotaValidStartDate;
                }
                ratePerDate.put(startDate, ratesAndDates.Conversionrate);
                startDate = startDate.addDays(1);
            }
        }
    currencyRateMap.put('MXN', ratePerDate);
    }

    //Method to get the dates and rate for Francs
    public void getDateSwissFrancRates(){
        List<DatedConversionRate> convertedRates = new List<DatedConversionRate>([  SELECT  IsoCode, 
                                                                                                Conversionrate,
                                                                                                StartDate,
                                                                                                NextStartDate
                                                                                        FROM    DatedConversionRate 
                                                                                        WHERE   IsoCode = 'CHF' AND StartDate <=: quotaValidEndDate
                                                                                        ORDER BY StartDate]);

        Map< Date, Double> ratePerDate = new Map<Date, Double>();  

        for(DatedConversionRate ratesAndDates: convertedRates){
            Date startDate = ratesAndDates.StartDate;
            Date endDate = ratesAndDates.NextStartDate; 
            
            while((startDate < endDate) && (startDate <= quotaValidEndDate)){
                //system.debug('Start Date ' +startDate);
                //system.debug('End Date ' +endDate);

                if(quotaValidStartDate > startDate ){
                    startDate = (Date)quotaValidStartDate;
                }
                ratePerDate.put(startDate, ratesAndDates.Conversionrate);
                startDate = startDate.addDays(1);
            }
        }
    currencyRateMap.put('CHF', ratePerDate);
    }

    //Method to get the dates and rate for Canadia Dollars
    public void getDateCanadianDollarRates(){
        List<DatedConversionRate> convertedRates = new List<DatedConversionRate>([  SELECT  IsoCode, 
                                                                                                Conversionrate,
                                                                                                StartDate,
                                                                                                NextStartDate
                                                                                        FROM    DatedConversionRate 
                                                                                        WHERE   IsoCode = 'CAD' AND StartDate <=: quotaValidEndDate
                                                                                        ORDER BY StartDate]);

        Map< Date, Double> ratePerDate = new Map<Date, Double>();  

        for(DatedConversionRate ratesAndDates: convertedRates){
            Date startDate = ratesAndDates.StartDate;
            Date endDate = ratesAndDates.NextStartDate; 
            
            while((startDate < endDate) && (startDate <= quotaValidEndDate)){
                //system.debug('Start Date ' +startDate);
                //system.debug('End Date ' +endDate);

                if(quotaValidStartDate > startDate ){
                    startDate = (Date)quotaValidStartDate;
                }
                ratePerDate.put(startDate, ratesAndDates.Conversionrate);
                startDate = startDate.addDays(1);
            }
        }
    currencyRateMap.put('CAD', ratePerDate);
    }

//Method used for consilidating all the methods into one - Harsha - Moved to next quarter
/*public void methodForTesting(){
        List<DatedConversionRate> convertedRates = new List<DatedConversionRate>([  SELECT  IsoCode, 
                                                                                                Conversionrate,
                                                                                                StartDate,
                                                                                                NextStartDate
                                                                                        FROM    DatedConversionRate 
                                                                                        ORDER BY IsoCode]);

        Map< Date, Double> ratePerDate = new Map<Date, Double>();  
        Boolean flag = false;
        String previousIsoCode;

        for(DatedConversionRate ratesAndDates: convertedRates){

            /*if(!(currencyRateMap.containsKey(ratesAndDates.IsoCode))){
                    system.debug('Current ISO Code ' +ratesAndDates.IsoCode);
                    currencyRateMap.put(ratesAndDates.IsoCode, new Map<Date, Double>());
                    system.debug('New Map ' +currencyRateMap);
                    if(ratePerDate.size() > 0){
                        system.debug('Size of inner Map ' +ratePerDate+ 'Currency is ' +previousIsoCode);
                        currencyRateMap.put(previousIsoCode, ratePerDate);
                        system.debug('Data in the Map ' +currencyRateMap);
                        ratePerDate.clear();
                        system.debug('Data in inner map after clearing ' +ratePerDate);
                        flag = false;
                    }
                    if(flag == false){
                    previousIsoCode = ratesAndDates.IsoCode;
                    system.debug('In IF loop update ISO COde to ' +previousIsoCode);
                    flag = true;
                    }
                system.debug('Data in the nested map ' +currencyRateMap);
            }

            Date startDate = ratesAndDates.StartDate;
            Date endDate = ratesAndDates.NextStartDate; 
            
            while((startDate < endDate) && !(startDate == quotaValidEndDate) && (quotaValidEndDate > startDate)){
                if(quotaValidStartDate > startDate ){
                    startDate = (Date)quotaValidStartDate;
                }
                ratePerDate.put(startDate, ratesAndDates.Conversionrate);
                startDate = startDate.addDays(1);
            }
                
                String key = (String)ratesAndDates.IsoCode;
                system.debug('Key is ' +key);
                system.debug('Before ' +ratePerDate);
                currencyRateMap.put(key, ratePerDate);
                system.debug('After insert ' +currencyRateMap+ 'Size is ' +currencyRateMap.get(key).size());

    }

   // system.debug('Size of inner Map '+ratePerDate.size());    
   // system.debug('Data in Final Map ' +currencyRateMap);
    //Test
//system.debug('Size of the List' +);
//system.debug('Final Data in the nested map ' +currencyRateMap);
}*/

    //returns a currency map with with Currency / Date / Rates - Can be used anywhere to to get the data
    public Map<String, Map<Date, Double>> getCaluculatedRates(){
        getDateEuroRates();
        getDatePoundRates();
        getDateUSDollarRates();
        getDatePesoRates();
        getDateSwissFrancRates();
        getDateCanadianDollarRates();
    return currencyRateMap;
    }   

}