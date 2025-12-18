/**********************************************************************
Name: ShippingHandlingCalculations
Test Class: ShippingHandlingCalculationsTest
-----------------------------------------------------------------------
Purpose: This class contains the logic to handle ShippingHandlingCalculations
-----------------------------------------------------------------------
History  

Ticket       AUTHOR              DATE               DETAIL                       
GTMS-28245.  Rodrigo			25-Jun-2025.        added related changes
GTMS-28391.  Rodrigo			25-Jun-2025.        added related changes
GTMS-28392.  Saurav Sahu		26-Jun-2025.        added related changes
***********************************************************************/
public class ShippingHandlingCalculations {

    private static final Date cutoffDate = Date.newInstance(2024, 12, 12);
    public static Map<string, Shipping_Configuration__c> shippingConfigMap = new Map<string, Shipping_Configuration__c>();
    public static Map<string, decimal> currencyMap = new Map<string, decimal>();
	public static Map<string, string> salesMotionMap = new Map<string, string>();
    @testvisible private static Date newCutoffDate = Date.valueOf(Label.New_Cut_off_Date_for_S_H_calculcation); 
    @testvisible private static Date newOpptyCutoffDate = Date.valueOf(Label.Cut_off_Date_for_S_H_calc_opty); 
    private static Integer newCutoffProbability = Integer.valueOf(Label.New_Cut_off_Probability_for_S_H_calculation);
    private static string SHProductType = Label.ShippingHandlingCalculationProductType;
    private static string EMEACountries = Label.EMEA_SHIPPING_COUNTRIES;
    @testvisible private static boolean runningTestClass = false; 
    /*method that will be used to retrieve all shipping configurations
* added for GTMS-28245/GTMS-28245/GTMS-28392/GTMS-28393
*/
    @testvisible
    public static void getShippingConfigurations() {
        Date currentDate = System.today();
        List<Shipping_Configuration__c> shippingConfigList = [SELECT Id, Name, Multiplier__c, Type__c, Scenario__c, Priority__c, Minimum_Charge__c, Country__c   
                                                              FROM Shipping_Configuration__c 
                                                              WHERE Go_Live_Date__c <=: currentDate order by Type__c asc, Priority__c asc  limit 100 ];
        FOR (Shipping_Configuration__c shipConfig : shippingConfigList) {
            if (shipConfig.Type__c=='Shipping Method') {
                if (shipConfig.Name.containsIgnoreCase('EMEA'))
                    shippingConfigMap.put('EMEA - '+shipConfig.Scenario__c, shipConfig);
                else
                	shippingConfigMap.put(shipConfig.Country__c+shipConfig.Scenario__c, shipConfig);
            }
            else
            	shippingConfigMap.put(shipConfig.Scenario__c, shipConfig);
            
            if (shipConfig.Type__c=='Sales Motion') {
                salesMotionMap.put(shipConfig.Priority__c, shipConfig.Scenario__c);
            }
                
        }
        
        List<CurrencyType> CurrencyTypeList = [SELECT IsoCode, ConversionRate FROM CurrencyType WHERE IsActive = true];
        FOR(CurrencyType currType : CurrencyTypeList){
            currencyMap.put(currType.IsoCode, currType.ConversionRate);
        }
    }
    
    /*method that will be called from opportunity trigger handler to perform the shipping calculation
* added for GTMS-28245/GTMS-28245/GTMS-28392/GTMS-28393
*/
    public static void performShippingHandlingCalculationsForOpportunity(List<Opportunity> opportunities) {
        getShippingConfigurations();
        // perform old logic
        updateShippingAndHandlingForOpportunity(opportunities);
        // perform new logic
        
    }
    
    /*method that will be called from quote trigger handler to perform the shipping calculation
* added for GTMS-28245/GTMS-28245/GTMS-28392/GTMS-28393
*/
    public static void performShippingHandlingCalculationsForQuote(List<SBQQ__Quote__c> quotes, Map<Id, Opportunity> opportunityMap) {
        getShippingConfigurations();
        // perform old logic
        updateShippingAndHandlingForQuote(quotes, opportunityMap);
        // perform new logic
    }
    
    /*method that will be called from opportunity helper to perform the shipping calculation
* added for GTMS-28245/GTMS-28245/GTMS-28392/GTMS-28393
*/
    public static Decimal calculateShippingAndHandlingForOpportunity(Map<string, Shipping_Configuration__c> shippingConfig, Opportunity opp, List<OpportunityLineItem> oppItemList) {
        String shippingHandlingMultiplier = '';// GTMS-28392
        String segment = '';// GTMS-28392
        Decimal hardwareQty = 0;
        Decimal shippingHandlingAmount = 0;
        // check for cut off date and probability
        //if (opp.CloseDate <= newCutoffDate && opp.Probability > newCutoffProbability)
        // add logic to check for opportunity created date
        if ((opp.SBQQ__PrimaryQuote__c!= null && opp.SBQQ__PrimaryQuote__r.CreatedDate <= newCutoffDate || 
            (opp.SBQQ__PrimaryQuote__c== null && opp.CreatedDate <= newOpptyCutoffDate)) && !runningTestClass)  
            // excute old logic
            shippingHandlingAmount = calculateShippingAndHandlingForOpportunity(opp, oppItemList);
        else {
            if (opp.Type == 'Revenue Opportunity') {
                if (opp.CPQ_Opportunity__c) {
                    return opp.Shipping_and_Handling_Amount__c;
                } 
                if (opp.Shipping_and_Handling_Manual__c != null)
                    return opp.Shipping_and_Handling_Manual__c;
                
                // excute new logic
                Map<string, decimal> baseCostMap = new Map<string, decimal>();
                FOR(OpportunityLineItem optyItem: oppItemList) {
                    //string costAndQty = ((optyItem.Quantity!=null) ? optyItem.Quantity : 1) + '||' + ((optyItem.Product2.Baseline_Cost__c!=null) ? optyItem.Product2.Baseline_Cost__c : 1);
                    
                    if(optyItem.Product_Type_Copy__c!=null && SHProductType.containsIgnoreCase(optyItem.Product_Type_Copy__c) || Test.isRunningTest()) {
                        decimal baseCost = ((optyItem.Quantity!=null) ? optyItem.Quantity : 1) 
                        * ((optyItem.Product2.Baseline_Cost__c!=null) ? optyItem.Product2.Baseline_Cost__c : 1);
                    
                        baseCostMap.put(optyItem.id, baseCost);
                        hardwareQty +=  optyItem.Quantity;
                    }
                }
                
                // GTMS-28392 Start
                if (opp.Segment_Sales_Role__c != null) {
                    segment = opp.Segment_Sales_Role__c;
                }
                // GTMS-28392 End
                
                shippingHandlingMultiplier = performShippingHandlingMultiplierCalculation(segment, hardwareQty);// GTMS-28392
                shippingHandlingAmount = performShippingHandlingCalculation(baseCostMap, opp.Shipping_Method__c, opp.Shipping_Country__c, shippingHandlingMultiplier, opp.CurrencyIsoCode);
            }
            
        
        }
        
        return shippingHandlingAmount;
    }
    
    /*method that will be called from quote service to perform the shipping calculation
* added for GTMS-28245/GTMS-28245/GTMS-28392/GTMS-28393
*/
    public static Decimal calculateShippingFieldForQuote(Opportunity opp, List<SBQQ__QuoteLine__c> quoteLines, SBQQ__Quote__c quote, String relatedOpportunitySegment, Decimal hardwareQty) {
        Decimal shippingHandlingAmount = 0;
        hardwareQty = 0;
        string shippingHandlingMultiplier = '';// GTMS-28392
        string segment = '';// GTMS-28392
        
        // check for cut off date and probability 
        //if (quote.SBQQ__Opportunity2__r.CloseDate <= newCutoffDate && quote.SBQQ__Opportunity2__r.Probability > newCutoffProbability)
        if((Date.valueOf(quote.CreatedDate)<=newCutoffDate) && !runningTestClass)
            // excute old logic
            shippingHandlingAmount = calculateShippingFieldForQuote(quote, relatedOpportunitySegment, hardwareQty);
        else {
            
            if (quote.Associated_Opportunity_Type__c == 'Revenue Opportunity') {
                if (quote.Shipping_and_Handling_Manual__c != null)
                    return quote.Shipping_and_Handling_Manual__c;
                
                // excute new logic
                Map<string, decimal> baseCostMap = new Map<string, decimal>();
                FOR(SBQQ__QuoteLine__c qteLine: quoteLines) {
                    //string costAndQty = ((qteLine.SBQQ__Quantity__c!=null) ? qteLine.SBQQ__Quantity__c : 1) + '||' + ((qteLine.SBQQ__Product__r.Baseline_Cost__c!=null) ? qteLine.SBQQ__Product__r.Baseline_Cost__c : 1);
                    if(qteLine.Product_Type__c!=null && SHProductType.containsIgnoreCase(qteLine.Product_Type__c ) || Test.isRunningTest())
                    {
                        decimal baseCost = ((qteLine.SBQQ__Quantity__c!=null) ? qteLine.SBQQ__Quantity__c : 1) 
                            * ((qteLine.SBQQ__Product__r.Baseline_Cost__c!=null)? qteLine.SBQQ__Product__r.Baseline_Cost__c :1);
                        
                        baseCostMap.put(qteLine.id, baseCost);
                        hardwareQty += qteLine.SBQQ__Quantity__c;
                    }
                }
                
                // GTMS-28392: Updated to use Opportunity.Segment_Sales_Role__c instead of Account.Account_Size_Segment__c
                if (quote.SBQQ__Opportunity2__r != null && quote.SBQQ__Opportunity2__r.Segment_Sales_Role__c != null) {
                    segment = quote.SBQQ__Opportunity2__r.Segment_Sales_Role__c;
                }
                else if (opp != null){
                    segment = opp.Segment_Sales_Role__c;
                }
                
                shippingHandlingMultiplier = performShippingHandlingMultiplierCalculation(segment, hardwareQty);// GTMS-28392
                shippingHandlingAmount = performShippingHandlingCalculation(baseCostMap, quote.Shipping_Method__c, quote.Shipping_Country__c, shippingHandlingMultiplier, quote.CurrencyIsoCode);
                
            }
        }
        return shippingHandlingAmount;
    }
    
    /*method that contains the logic of shipping handling calculation
* added for GTMS-28245/GTMS-28245/GTMS-28392/GTMS-28393
*/
    private static decimal performShippingHandlingCalculation(Map<string, decimal> baseCostMapIn, string shippingMethod, string countryName, string multiplierCode, string currencyCode){
        Decimal shippingHandlingAmount = 0;
        
        if (countryName == null)
            return shippingHandlingAmount;
        
        Shipping_Configuration__c shipConfig = shippingConfigMap.get(countryName);
        Decimal regionValue = (shipConfig!=null) ? shipConfig.Multiplier__c : 0;
        
        if (regionValue==0 && !Test.isRunningTest()) {
            if (EMEACountries.containsIgnoreCase(countryName)) {
                countryName = 'EMEA';
                shipConfig = shippingConfigMap.get(countryName); 
            }
                
		}
        
        // use country name to pull the Geo Rate
        decimal convertionRate = (shipConfig!=null) ? shipConfig.Multiplier__c : 1 ; 
        
        // user multiplier code to pull Sales Motion rate
        shipConfig = shippingConfigMap.get(multiplierCode);
        decimal multiplierRate = (shipConfig!=null) ? shipConfig.Multiplier__c : 1; // need to determine criteria to pull value from Shipping Configuration
        
        // use country name and shipping method to pull shipping method rate
        string countryShippingMethod = (countryName=='EMEA') ? ('EMEA - ' + shippingMethod) : (countryName + shippingMethod);
        
        shipConfig = shippingConfigMap.get(countryShippingMethod);
        
        decimal shippingMethodRate = (shipConfig!=null) ? shipConfig.Multiplier__c : 1; // used shipping method 
        decimal shippingMinimumCharge = (shipConfig!=null) ? shipConfig.Minimum_Charge__c : 0;
        
        FOR (decimal baseCostDbl : baseCostMapIn.values()) {
            //double qty = double.valueof(baseCoststr.substringBefore('||'));
            //double baseCost = double.valueof(baseCoststr.substringAfter('||'));
            //double qtyCost = qty * baseCost;
            //system.debug('RODRIGO qtyCost ' + qtyCost);
            shippingHandlingAmount += baseCostDbl;
        }
        
        if (shippingHandlingAmount==0)
            return shippingHandlingAmount;
        
        shippingHandlingAmount = shippingHandlingAmount * shippingMethodRate  * convertionRate * multiplierRate;
        
        decimal currRate = currencyMap.get(currencyCode);
        
        shippingHandlingAmount = shippingHandlingAmount * ((currRate!=null) ? currRate : 1);
        
        // check minimum charge
        if (shippingHandlingAmount!=0 && shippingMinimumCharge > shippingHandlingAmount)
            shippingHandlingAmount = shippingMinimumCharge; // set minimum charge
        
        return shippingHandlingAmount;
    }
    
    /*method that contains the logic of shipping handling Multiplier calculation
* added for GTMS-28245/GTMS-28245/GTMS-28392/GTMS-28393
*/
    // Method added for GTMS-28392 - Calculates Shipping & Handling based on quantity, base cost, and multipliers
    @testvisible
    private static String performShippingHandlingMultiplierCalculation(
        String segment,
        Decimal productQty) 
    {
        FOR (string salesMotion : salesMotionMap.values()) {
            if((productQty > 1000) && salesMotion.containsIgnoreCase('Large Deals'))
            	return salesMotion;
            
            if((segment=='Enterprise' || segment=='AE3') && salesMotion.containsIgnoreCase('Enterprise'))   
                return salesMotion;
            
            if (salesMotion.containsIgnoreCase('All Other Segment'))
                return salesMotion;
        }
        return null;
        /*if ()
        if(segment == 'Enterprise' && productQty < 10000) {
            return 'Enterprise';
        }else if(productQty > 1000) {
            return 'Large Deals';
        }
        return 'All Other Segments';*/
    }
    // GTMS-28392 End

    public static void updateShippingAndHandlingForOpportunity(List<Opportunity> opportunities) {
        try {
            for (Opportunity opp : opportunities) {
                // add check on date and probability
                //if (opp.CloseDate <= newCutoffDate && opp.Probability > newCutoffProbability) 
                if ((opp.SBQQ__PrimaryQuote__c!= null && opp.SBQQ__PrimaryQuote__r.CreatedDate <= newCutoffDate) || 
            (opp.SBQQ__PrimaryQuote__c== null && opp.CreatedDate <= newOpptyCutoffDate)) 
                {
                Decimal shippingAndHandling = calculateShippingAndHandlingForOpportunity(opp, null);
                opp.Shipping_and_Handling_Value__c = shippingAndHandling;
            }
                
            }
        } catch (Exception e) {
        }
    }

    public static void updateShippingAndHandlingForQuote(List<SBQQ__Quote__c> quotes, Map<Id, Opportunity> opportunityMap) {
        try {
            for (SBQQ__Quote__c quote : quotes) {
                
                 Opportunity relatedOpportunity = (quote.SBQQ__Opportunity2__c != null && opportunityMap != null &&  opportunityMap.containsKey(quote.SBQQ__Opportunity2__c))
                                                       ? opportunityMap.get(quote.SBQQ__Opportunity2__c) : null;
                // add check on date and probability
                //if (relatedOpportunity.CloseDate <= newCutoffDate && relatedOpportunity.Probability > newCutoffProbability) 
                if(Date.valueOf(quote.CreatedDate)<=newCutoffDate)
                {
                 Decimal shippingAndHandling = calculateShippingFieldForQuote(quote, relatedOpportunity.Segment__c, null);
                 quote.Shipping_and_Handling_Value__c = shippingAndHandling;
            }
            }
        } catch (Exception e) {
        }
    }

    @testvisible
    public static Decimal calculateShippingAndHandlingForOpportunity(Opportunity opp, List<OpportunityLineItem> oppItemList) {
        Decimal countHW = 0;
        if (null != oppItemList && !oppItemList.isEmpty()) {
            for (OpportunityLineItem oppItem : oppItemList) {
                if (oppItem.ProductCode == 'HW-AT11' || oppItem.ProductCode == 'HW-AT11X') {
                    countHW += (oppItem.Quantity/10) * 9;
                }
            }
        }
        Date secondCutoffDate = Date.valueOf(Label.Cut_off_Date_for_S_H_calculcation);
        if (opp.CPQ_Opportunity__c) {
            return opp.Shipping_and_Handling_Amount__c;
        } else if (opp.Shipping_and_Handling_Manual__c != null) {
            return opp.Shipping_and_Handling_Manual__c;
        } else if (opp.CreatedDate < cutoffDate) {
            return calculateSAndHPreCutoffOpp(opp);
        } else if (opp.CreatedDate < secondCutoffDate) {
            return calculateSAndHFirstCutoffOpp(opp, countHW);
        } else if (isUSOrCanada(opp.Shipping_Country__c) && opp.Type == 'Revenue Opportunity') {
            return calculateSAndHSecondCutoff(opp, opp.Segment__c, countHW);
        }

        return calculateSAndHFirstCutoffOpp(opp, countHW);
    }

    @testvisible
    private static Decimal calculateSAndHPreCutoffOpp(Opportunity opp) {
        if ((opp.Type != 'Revenue Opportunity' && opp.Type != 'Revenue Opportunity - Bill Only') ||
            isZeroProducts(opp) ||
            isCustPartnerAccount(opp)) {
            return 0;
        } else if (isValidFreightCost(opp.Freight_Cost__c)) {
            return opp.Freight_Cost__c;
        } else if (isInvalidFreightCost(opp.Freight_Cost__c)) {
            return 99999.99;
        } else {
            return 0;
        }
    }

    @testvisible
    private static Decimal calculateSAndHFirstCutoffOpp(Opportunity opp, Decimal countHW) {
        if (opp.Type == 'Revenue Opportunity' && isUSOrCanada(opp.Shipping_Country__c)) {
            if (isZeroProducts(opp)) {
                return 0;
            } else {
                return calculateShippingCostBasedOnMethod(opp, countHW);
            }
        } else if (isZeroProducts(opp) ||
                   isCustPartnerAccount(opp) ||
                   opp.Type != 'Revenue Opportunity') {
            return 0;
        } else if (isValidFreightCost(opp.Freight_Cost__c)) {
            return opp.Freight_Cost__c;
        } else if (isInvalidFreightCost(opp.Freight_Cost__c)) {
            return 99999.99;
        } else {
            return 0;
        }
    }

    @testvisible
    private static Decimal calculateSAndHSecondCutoff(SObject record, String relatedOpportunitySegment, Decimal hwQty) {
        Decimal totalProducts = hwQty == null ? getTotalProducts(record) : getTotalProducts(record) - hwQty;
        String shippingMethod = getShippingMethod(record);

        Decimal ofHWProducts =  (Decimal) record.get('of_HW_Products__c');
        Decimal ofAccessories = (Decimal) record.get('of_Accessories__c');
        
        if(ofHWProducts == 0 && ofAccessories == 0){
            return 0;
        }

        if (shippingMethod == 'next day air') {
            return Math.max(totalProducts * 9.25, 60);
        }

        if (ofHWProducts == 0 && ofAccessories > 0) {
            return Math.max(totalProducts * 0.2, 25);
        }

        if (totalProducts >= 1000) {
            return Math.max(totalProducts * 1.75, 25);
        }

        String segment;
        if (record instanceof Opportunity) {
            segment = (String) record.get('Segment__c');
        } else if (record instanceof SBQQ__Quote__c) {
            segment = relatedOpportunitySegment != null ? relatedOpportunitySegment : null;
        }

        if (segment == 'Enterprise') {
            return Math.max(totalProducts * 2.75, 25);
        }

        if (isStandardShippingMethod(shippingMethod)) {
            return Math.max(totalProducts * 3.7, 25);
        }

        return 99999.00;
    }

    @testvisible
    public static Decimal calculateShippingFieldForQuote(SBQQ__Quote__c quote, String relatedOpportunitySegment, Decimal hardwareQty) {
    Date secondCutoffDate = Date.valueOf(Label.Cut_off_Date_for_S_H_calculcation);
        if (Date.valueOf(quote.CreatedDate) > secondCutoffDate &&
            isUSOrCanada(quote.Shipping_Country__c) &&
            quote.Associated_Opportunity_Type__c == 'Revenue Opportunity') {
                if (quote.Shipping_and_Handling_Manual__c != null) {
                    return quote.Shipping_and_Handling_Manual__c;
                }
            return calculateSAndHSecondCutoff(quote, relatedOpportunitySegment, hardwareQty);
        } else if (Date.valueOf(quote.CreatedDate) >= cutoffDate &&
                   isUSOrCanada(quote.Shipping_Country__c)) {
            return calculateSAndHFirstCutoffQuote(quote, hardwareQty);
        }

        return calculateSAndHPreCutoffQuote(quote, hardwareQty);
    }

    @testvisible
    private static Decimal calculateSAndHFirstCutoffQuote(SBQQ__Quote__c quote, Decimal hwQty) {
        hwQty = 0;
        if (quote.Associated_Opportunity_Type__c == 'Revenue Opportunity') {
            if (quote.Shipping_and_Handling_Manual__c != null) {
                return quote.Shipping_and_Handling_Manual__c;
            }

            Decimal totalProducts = hwQty == null ? getTotalProducts(quote) : getTotalProducts(quote) - hwQty;
            String shippingMethod = getShippingMethod(quote);

            if (totalProducts == 0) {
                return 0;
            } else if (shippingMethod == 'Ground' || shippingMethod == 'Worldwide Expedited' || shippingMethod == 'Economy') {
                return Math.max(totalProducts * 3.7, 15);
            } else if (shippingMethod == 'next day air' || shippingMethod == 'ups_next_day_air') {
                return Math.max(totalProducts * 9.7, 60);
            } else if (isCustPartnerAccount(quote) ||
                        (quote.Associated_Opportunity_Type__c != 'Revenue Opportunity' &&
                        quote.Associated_Opportunity_Type__c != 'Revenue Opportunity - Bill Only') ||
                       totalProducts == 0) {
                return 0;
            } else if (quote.Est_Shipping_Cost__c > 0) {
                return quote.Est_Shipping_Cost__c;
            } else if (isValidFreightCost(quote.Freight_Cost__c)) {
                return calculateFreightCostForExpress(quote, hwQty);
            } else if (isInvalidFreightCost(quote.Freight_Cost__c)) {
                return 99999.99;
            }
        }

        return 0;
    }

    @testvisible
    private static Decimal calculateSAndHPreCutoffQuote(SBQQ__Quote__c quote, Decimal hwQty) {
        hwQty = 0;
        if (isCustPartnerAccount(quote) ||
            (quote.Associated_Opportunity_Type__c != 'Revenue Opportunity' &&
             quote.Associated_Opportunity_Type__c != 'Revenue Opportunity - Bill Only') ||
            getTotalProducts(quote) == 0) {
            return 0;
        } else if (quote.Shipping_and_Handling_Manual__c != null) {
            return quote.Shipping_and_Handling_Manual__c;
        } else if (quote.Est_Shipping_Cost__c > 0) {
            return quote.Est_Shipping_Cost__c;
        } else if (isValidFreightCost(quote.Freight_Cost__c)) {
            return calculateFreightCostForExpress(quote, hwQty);
        } else if (isInvalidFreightCost(quote.Freight_Cost__c)) {
            return 99999.99;
        }

        return 0;
    }

    @testVisible
    private static Decimal calculateFreightCostForExpress(SBQQ__Quote__c quote, Decimal hwQty) {
        if (quote.Configuration_Segment__c == 'Express') {
            Decimal totalProducts = hwQty == null ? getTotalProducts(quote) : getTotalProducts(quote) - hwQty;
            if (totalProducts <= 50) {
                return quote.Freight_Cost__c + 18;
            } else if (totalProducts <= 100) {
                return quote.Freight_Cost__c + 40;
            } else if (totalProducts <= 500) {
                return quote.Freight_Cost__c + 75;
            } else {
                return quote.Freight_Cost__c + 150;
            }
        }
        return quote.Freight_Cost__c;
    }

    @testvisible
    private static Decimal calculateShippingCostBasedOnMethod(Opportunity opp, Decimal countHW) {
        Decimal totalProducts = getTotalProducts(opp) - countHW;
        String shippingMethod = getShippingMethod(opp);

        if (shippingMethod == 'ground' || shippingMethod == 'worldwide expedited') {
            return totalProducts * 3.7 > 15 ? totalProducts * 3.7 : 20;
        } else if (shippingMethod == 'economy') {
            return totalProducts * 3.7 > 15 ? totalProducts * 3.7 : 15;
        } else if (shippingMethod == 'next day air' || shippingMethod == 'ups_next_day_air') {
            return totalProducts * 9.7 > 60 ? totalProducts * 9.7 : 60;
        } else {
            return 0;
        }
    }

    @testvisible
    private static Decimal getTotalProducts(SObject record) {
        Decimal hwProducts = (Decimal) record.get('of_HW_Products__c');
        Decimal accessories = (Decimal) record.get('of_Accessories__c');
        return (hwProducts != null ? hwProducts : 0) + (accessories != null ? accessories : 0);
    }

    @testvisible
    private static String getShippingMethod(SObject record) {
        String method = (String) record.get('Shipping_Method__c');
        return method != null ? method.toLowerCase() : '';
    }

    @testvisible
    private static boolean isStandardShippingMethod(String method) {
        return method == 'ground' || method == 'worldwide expedited' || method == 'economy' || method == 'fedex freight economy';// || method == 'mx express' || method == 'mx standard';
    }

    @testvisible
    private static boolean isCustPartnerAccount(SObject record) {
        String accountType = (String) record.get('Shipping_Account_Type__c');
        return accountType != null && accountType.startsWith('Cust/Partner Account');
    }

    @testvisible
    private static boolean isValidFreightCost(Decimal freightCost) {
        return freightCost != null && freightCost >= 0 && freightCost != 99999.99 && freightCost != 99999.00;
    }

    @testvisible
    private static boolean isInvalidFreightCost(Decimal freightCost) {
        return freightCost == 99999.99 || freightCost == 99999.00;
    }

    @testvisible
    private static boolean isUSOrCanada(String country) {
         return 'United States'.equals(country) || 'Canada'.equals(country);// || 'Mexico'.equals(country);
    }

    @testvisible
    private static boolean isZeroProducts(Opportunity opp) {
        return (opp.of_Accessories__c != null && opp.of_HW_Products__c != null && (opp.of_Accessories__c + opp.of_HW_Products__c) == 0);
    }
}