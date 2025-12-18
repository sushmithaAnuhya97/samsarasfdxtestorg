/*********
 * GTMS-5654 (Lavanya) - Updated the values in "regionConstraintValueMap" for the following countries (Germany, NE, Austria and Belgium) from 50 to 20
 * GTMS-9426 (Siddharth) - Changed threshhold from 5600 to 6500
 * Nov-17-2022 Rajesh GTMS-8209: Added Mexico Freight cost
 * Jan-08-2023 Rajesh GTMS-10675: Updated Freight cost for West, East, Central and for NonCanadaFrance
 * Aug-23-2023 Rodrigo GTMS-10234 : //added logic change stamped with the ticket number
 * ***/
public inherited sharing class GS_SBQQQuoteWorkflowService {
    Map<Id, SBQQ__Quote__c> oldMap;
    Map<Id, SBQQ__Quote__c> newMap;
    List<SBQQ__Quote__c> newList;
    Boolean hasOldContext;
    Map<Id, SBQQ__Quote__c> sourceQuoteData;
    Map<Id, Opportunity> opptyMap;
    Map<Id, Pricebook2> priceBookMap;
    Map<Id, Shipping_Address__c> addressMap;

    public GS_SBQQQuoteWorkflowService(Map<Id, SBQQ__Quote__c> oldMap, Map<Id, SBQQ__Quote__c> newMap, List<SBQQ__Quote__c> newList) {
        this.oldMap = oldMap;
        this.newMap = newMap;
        this.newList = newList;
        this.hasOldContext = (oldMap != null);
    }

    // Below method performs all the workflow actions
    public void performWorkflowActions() {
        Set<Id> sourceQuoteIds = new Set<Id>();
        Set<Id> opptyIds = new Set<Id>();
        Set<Id> priceBookIds = new Set<Id>();
        Set<Id> addressIds = new Set<Id>();
        // Collecting associated record Ids
        for (SBQQ__Quote__c newQuote : newList) {
            if (newQuote.SBQQ__Source__c != null) {
                sourceQuoteIds.add(newQuote.SBQQ__Source__c);
            }
            if (newQuote.SBQQ__Opportunity2__c != null) {
                opptyIds.add(newQuote.SBQQ__Opportunity2__c);
            }
            if (newQuote.SBQQ__PriceBook__c != null) {
                priceBookIds.add(newQuote.SBQQ__PriceBook__c);
            }
            if (newQuote.Shipping_Address_NEW__c != null) {
                addressIds.add(newQuote.Shipping_Address_NEW__c);
            }
        }
        // Collecting related data for above Ids
        if (sourceQuoteIds.size() > 0) {
            sourceQuoteData = new GS_SBQQQuoteSelector(true).checkFatalError().getQuotesById(sourceQuoteIds);
        }
        if (opptyIds.size() > 0) {
            opptyMap = new GS_OpportunitySelector(true).checkFatalError().getOpptyWithQuotesById(opptyIds);
        }
        if (priceBookIds.size() > 0) {
            priceBookMap = new GS_PricebookSelector(true).checkFatalError().getPricebookById(priceBookIds);
       //     System.debug('**** priceBookMap> '+priceBookMap);
        }
        if (addressIds.size() > 0) {
            addressMap = new GS_ShippingAddressSelector(true).checkFatalError().getShippingAddressById(addressIds);
        }
        
        // This section calls each 
        for (SBQQ__Quote__c newQuote : newList) {
            SBQQ__Quote__c oldQuote;
            if (hasOldContext) {
                oldQuote = oldMap.get(newQuote.id);
            }
            clearApprovedDiscount(newQuote, oldQuote);
            setCoTermedStartDate(newQuote, oldQuote);
            setMaxFreightCost(newQuote, oldQuote);
            calculateFreightCost(newQuote, oldQuote);
            setQuoteRenewal(newQuote, oldQuote);
        }
    }

    // [Non-Express] Checks if there is an approved discount on a quote (i.e on a cloned draft quote) and 
    // the selected payment type is changed from upfront or annual to monthly.
    private void clearApprovedDiscount(SBQQ__Quote__c newQuote, SBQQ__Quote__c oldQuote) {
        if (newQuote.Configuration_Segment__c == 'Non Express' && 
            (!hasOldContext || 
             (newQuote.Selected_Payment_Type__c != oldQuote.Selected_Payment_Type__c &&
              (oldQuote.Selected_Payment_Type__c == null || 
               oldQuote.Selected_Payment_Type__c == 'Upfront Payments' ||
               oldQuote.Selected_Payment_Type__c == 'Direct Annual'
            ))) &&
            newQuote.Selected_Payment_Type__c == 'Direct Monthly' &&
            newQuote.Approved_Discount__c != null && (newQuote.SBQQ__Source__c == null || 
            (sourceQuoteData != null && sourceQuoteData.containsKey(newQuote.SBQQ__Source__c) &&
            sourceQuoteData.get(newQuote.SBQQ__Source__c).Selected_Payment_Type__c != 'Direct Monthly'))
        ) {
            newQuote.Approved_Discount__c = null;
        }
    }

    // [Non Express] Set Start Date on quote based on master contract
    private void setCoTermedStartDate(SBQQ__Quote__c newQuote, SBQQ__Quote__c oldQuote) {
        if (newQuote.Configuration_Segment__c == 'Non Express' && 
            newQuote.SBQQ__StartDate__c == null && newQuote.SBQQ__MasterContract__c != null &&
            newQuote.SBQQ__Opportunity2__c != null && opptyMap.containsKey(newQuote.SBQQ__Opportunity2__c)
        ) {
            newQuote.SBQQ__StartDate__c = opptyMap.get(newQuote.SBQQ__Opportunity2__c).CloseDate.addDays(15); 
        }
    }

    // Below method sets Quote's Max Freight Cost
    private void setMaxFreightCost(SBQQ__Quote__c newQuote, SBQQ__Quote__c oldQuote) {
      //  System.debug('****Price>>'+newQuote.SBQQ__PriceBook__c+' : ');
        if ((!hasOldContext || newQuote.Freight_Cost__c != oldQuote.Freight_Cost__c) &&
            priceBookMap != null && newQuote.SBQQ__PriceBook__c != null && priceBookMap.containsKey(newQuote.SBQQ__PriceBook__c) &&
            priceBookMap.get(newQuote.SBQQ__PriceBook__c).Name.containsIgnoreCase('Samsara Express')
        ) {
            newQuote.Freight_Cost__c = (
                newQuote.Shipping_Method__c != 'Next Day Air' ?
                (
                    (newQuote.SBQQ__NetAmount__c <= 3000 && newQuote.Freight_Cost__c > 12) ?
                    12 :
                    (
                        (newQuote.SBQQ__NetAmount__c <= 5000 && newQuote.Freight_Cost__c > 32) ?
                        32 :
                        (
                            (newQuote.SBQQ__NetAmount__c <= 10000 && newQuote.Freight_Cost__c > 47) ? 
                            47 :
                            (
                                (newQuote.SBQQ__NetAmount__c <= 20000 && newQuote.Freight_Cost__c > 57) ? 
                                57 :
                                (newQuote.Freight_Cost__c > 67 ? 67 : newQuote.Freight_Cost__c)
                            )
                        )
                    )
                ) :
                newQuote.Freight_Cost__c
            );
        }
    }

    
    // Below method calculates Quote's Freight Cost
    @TestVisible
    private void calculateFreightCost(SBQQ__Quote__c newQuote, SBQQ__Quote__c oldQuote) {
        
        Set<String> accountTypes = new Set<String> {
            'Cust/Partner Account - FedEx', 'Cust/Partner Account - UPS', 'Cust/Partner Account - DHL'
        };
        String state;
        String country;
        if (newQuote.Shipping_Address_NEW__c != null && addressMap != null && addressMap.containsKey(newQuote.Shipping_Address_NEW__c)) {
            state = addressMap.get(newQuote.Shipping_Address_NEW__c).Shipping_State__c; 
            country = addressMap.get(newQuote.Shipping_Address_NEW__c).Shipping_Country__c;
        }
       
        if (newQuote.SBQQ__Opportunity2__c == null || !opptyMap.containsKey(newQuote.SBQQ__Opportunity2__c)) {
            return;
        }
        Opportunity relatedOppty = opptyMap.get(newQuote.SBQQ__Opportunity2__c);
       
        String zone = (stateZoneMap.containsKey(state) ? stateZoneMap.get(state) : (country != null ? country : null));
        if (relatedOppty.Type == 'Revenue Opportunity' && 
            newQuote.Shipping_Method__c != null && newQuote.Shipping_Method__c != 'Will Call' && 
            !accountTypes.contains(newQuote.Shipping_Account_Type__c) && 
            newQuote.Total_Weight_oz__c != null && newQuote.Total_Product_Dimensions__c != null && 
            zone != null && relatedOppty.Probability < 99
        ) {
            Decimal val = Math.ceil(newQuote.Total_Product_Dimensions__c/22000);
            String key = zone + ';' + newQuote.Shipping_Method__c;
            
            // added for GTMS-10234
            if (newQuote.Shipping_Method__c == 'ECONOMY') {
                newQuote.Freight_Cost__c = 99999;
            }
            //GTMS-9426
            else if ((newQuote.Shipping_Country__c == 'Canada' || newQuote.Shipping_Country__c == 'France') &&
                newQuote.Total_Weight_oz__c < 6500 && newQuote.Shipping_and_Handling_Manual__c == null &&
                regionConstraintValueMap.get('CanadaFrance').containsKey(key)
            ) { 
                val = Math.ceil(newQuote.Total_Product_Dimensions__c/11000);
                newQuote.Freight_Cost__c = val * regionConstraintValueMap.get('CanadaFrance').get(key);
            } else if ((newQuote.Shipping_Country__c != 'Canada' && newQuote.Shipping_Country__c != 'France') &&
                newQuote.Total_Weight_oz__c < 6500 && newQuote.Shipping_and_Handling_Manual__c == null &&
                regionConstraintValueMap.get('NonCanadaFrance').containsKey(key)
            ){
                newQuote.Freight_Cost__c = val * regionConstraintValueMap.get('NonCanadaFrance').get(key);
            } 
            else if ( newQuote.Total_Weight_oz__c > 6500 && (newQuote.Shipping_Country__c == 'United States' || newQuote.Shipping_Country__c == 'Canada'))
            { //GTMS - 10234 starts here
              //system.debug('RODRIGO calculateFreightCost before setting cost ' + newQuote.Total_Weight_oz__c);
                newQuote.Freight_Cost__c = 99999.99;
              //system.debug('RODRIGO newQuote.Freight_Cost__c 1 ' + newQuote.Freight_Cost__c);
            } //GTMS - 10234 ends here
            else {
                //if (!(newQuote.Total_Weight_oz__c < 6500 && (newQuote.Shipping_Country__c == 'United States' || newQuote.Shipping_Country__c == 'Canada'))) // added for GTMS-10234
                //{
                    newQuote.Freight_Cost__c = 99999.99;
                    //system.debug('RODRIGO newQuote.Freight_Cost__c 2 ' + newQuote.Freight_Cost__c);
                //}
            }
        }
       
    }

    private void setQuoteRenewal(SBQQ__Quote__c newQuote, SBQQ__Quote__c oldQuote) {
        if (newQuote.SBQQ__Opportunity2__c != null && opptyMap.containsKey(newQuote.SBQQ__Opportunity2__c) && 
            opptyMap.get(newQuote.SBQQ__Opportunity2__c).Renewal__c
        ) {
            newQuote.Renewal__c = true;
        }
    }

    //GTMS-10675
    
    private Map<String, Map<String, Integer>> regionConstraintValueMap = new Map<String, Map<String, Integer>> {
        'CanadaFrance' => new Map<String, Integer>{
            'Spain;UK Standard' => 13,
            'France;UK Standard' => 13,
            'France;UK Express' => 28,
            'Mid-east;Ground' => 44,
            'Mid-east;3 Day Select' => 75,
            'Mid-east;Worldwide Expedited' => 75,
                'Mid-east;ECONOMY' => 99999,
            'Territory;Ground' => 46,
            'Territory;3 Day Select' => 75,
            'Territory;Worldwide Expedited' => 82,
             'East;Ground' => 40,
            'East;3 Day Select' => 114,
            'East;Worldwide Expedited' => 82,
            'East;ECONOMY' => 99999,
            'West;Ground' => 30,
            'West;3 Day Select' => 54,
            'West;Worldwide Expedited' => 52,
             'West;ECONOMY' => 99999,   
            'Mid-west;Ground' => 36,
            'Mid-west;3 Day Select' => 65,
            'Mid-west;Worldwide Expedited' => 60,
                'Mid-west;ECONOMY' => 99999
        },
            
        'NonCanadaFrance' => new Map<String, Integer>{ //GTMS-8209- Added MX
            'Luxembourg;UK Standard' => 13,
            'Luxembourg;UK Express' => 28,
            'United Kingdom;UK Standard' => 20,
            'United Kingdom;UK Express' => 35,
            'Ireland;UK Standard' => 45,
            'Ireland;UK Express' => 60,
            'Germany;UK Standard' => 20,
            'Germany;UK Express' => 75,
            'Netherlands;UK Standard' => 20,
            'Netherlands;UK Express' => 75,
            'Belgium;UK Standard' => 20,
            'Belgium;UK Express' => 75,
            'Austria;UK Standard' => 20,                
            'West;Ground' => 42,//30     //GTMS-21423 Updated US region values with +12$ START
            'West;3 Day Select' => 66	,//54
            'West;Next Day Air' => 248,//236
            'West;ECONOMY' => 99999,
            'Central;Ground' => 47,//35
            'Central;3 Day Select' => 114,//102
            'Central;Next Day Air' => 311,//299
            'Central;ECONOMY' => 99999,
            'East;Ground' => 52,//40
            'East;3 Day Select' => 126,//114
            'East;Next Day Air' => 318,//306
            'East;ECONOMY' => 99999, //GTMS-21423 Updated US region values with +12$ END
            'Mexico;MX Standard' => 150,
            'Mexico;MX Express' => 200   
        }
    };
    private Map<String, String> stateZoneMap = new Map<String, String> {
        'Arizona' => 'West',
        'California' => 'West',
        'Idaho' => 'West',
        'Nevada' => 'West',
        'Oregon' => 'West',
        'Utah' => 'West',
        'Washington' => 'West',
        'Arkansas' => 'Central',
        'Colorado' => 'Central',
        'Illinois' => 'Central',
        'Iowa' => 'Central',
        'Kansas' => 'Central',
        'Minnesota' => 'Central',
        'Missouri' => 'Central',
        'Montana' => 'Central',
        'Nebraska' => 'Central',
        'New Mexico' => 'Central',
        'North Dakota' => 'Central',
        'Oklahoma' => 'Central',
        'South Dakota' => 'Central',
        'Texas' => 'Central',
        'Wisconsin' => 'Central',
        'Wyoming' => 'Central',
        'Alabama' => 'East',
        'Alaska' => 'East',
        'Connecticut' => 'East',
        'Delaware' => 'East',
        'Florida' => 'East',
        'Georgia' => 'East',
        'Hawaii' => 'East',
        'Indiana' => 'East',
        'Kentucky' => 'East',
        'Louisiana' => 'East',
        'Maine' => 'East',
        'Maryland' => 'East',
        'Massachusetts' => 'East',
        'Michigan' => 'East',
        'Mississippi' => 'East',
        'New Hampshire' => 'East',
        'New Jersey' => 'East',
        'New York' => 'East',
        'North Carolina' => 'East',
        'Ohio' => 'East',
        'Tennessee' => 'East',
        'Pennsylvania' => 'East',
        'Rhode Island' => 'East',
        'Alabama' => 'East',
        'Alaska' => 'East',
        'Connecticut' => 'East',
        'Delaware' => 'East',
        'Florida' => 'East',
        'Virginia' => 'East',
        'West Virginia' => 'East',
        'Vermont' => 'East',
        'District of Columbia' => 'East',
        'Washington DC' => 'East',
        'South Carolina' => 'East',
        'Newfoundland' => 'Territory',
        'Nova Scotia' => 'Territory',
        'Prince Edward Island' => 'Territory',
        'New Brunswick' => 'Territory',
        'Yukon Territories' => 'Territory',
        'Quebec' => 'East',
        'Manitoba' => 'Mid-east',
        'Saskatchewan' => 'Mid-east',
        'Ontario' => 'Mid-east',
        'Alberta' => 'Mid-west',
        'British Columbia' => 'West'
    };
}