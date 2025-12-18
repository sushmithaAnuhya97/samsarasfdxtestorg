/* 
 * Test Class : QuoteHelperTests
 * Class Created: 06/14/19 - @author: Harsha
 * ************************************************************************
 * 8/20/20 Ron - (GTMS-867) quoteBeforeUpdateOperations (Update to populate Shippinng_and_Handling_Tax__c for Tax Compliance)
 * 8/20/20 Ron - (GTMS-867) quoteBeforeUpdateOperations (Update to populate Shippinng_and_Handling_Tax__c for Tax Compliance)
 * 7/11/20 Harsha - (GTMS-1307) checkCalculateTax (Deleted out the method), quoteBeforeUpdateOperations (removed checkCalculateTax referencce)
 * 6/25/20 Harsha - (GTMS-1089) quoteBeforeInsertOperations (Added code to pull in Ship From Location when the quote is created)
 * 5/19/20 Tommy/Harsha - (GTMS-84,650) quoteBeforeUpdateOperations (Made changes to add logic for shipping fields)
 * 2/09/21 Groundswell - Tanuj - (GTMS-2870) CPQ Quote Workflow Conversion to Apex
 * 5/18/21 - Gaurav Sharma - (GTMS-3734) To sync License Term Fields on Opportunity from CPQ Quote's Custom License Term
 * 06/08/2022 Rodrigo - GTMS-7328 added subsidyFilteredQuotes and subsidy related logic, changes are stamped with GTMS number
 * Sep-2023 Zakeer GTMS-13035 - Direct Quarterly
*/   
public without sharing class SBQQQuoteHelper {

    Static Map<Id, Shipping_Address__c> shippingData;
    Static Set<Id> relatedShippingAddressIDs = new Set<Id>();

    Static Map<Id, Contract> contractData;
    Static Set<Id> relatedContractIDs = new Set<Id>();
    
    Static Map<Id, SBQQ__Quote__c> sourceQuoteData;
    Static Set<Id> relatedQuoteIds = new Set<Id>();
    
    Static Map<Id, Quote_Save__e > quoteSaveEvents = new Map<Id, Quote_Save__e >();
    public static boolean recursionCheck = false;
    
    // Operation's on quote creation.
    public void quoteBeforeInsertOperations(Map<Id, SBQQ__Quote__c> oldQuoteMap, Map<Id, SBQQ__Quote__c> newQuoteMap, List<SBQQ__Quote__c> newQuoteList) {

        Set<Id> relatedOpportunityIDs = new Set<Id>();
        Map<Id, Opportunity> opportunityData;
           List<String> cwRoboIds = System.Label.Corpweb_SFDC_Robot.split(',');

        for (SBQQ__Quote__c newQuote : newQuoteList) {
            relatedOpportunityIDs.add(newQuote.SBQQ__Opportunity2__c);
            if (newQuote.Shipping_Address_NEW__c != null) {
                relatedShippingAddressIDs.add(newQuote.Shipping_Address_NEW__c);
            }
            if(newQuote.SBQQ__Source__c != null){
                relatedQuoteIds.add(newQuote.SBQQ__Source__c);
            }
        }
        if ((relatedShippingAddressIDs.size() > 0) && (shippingData == null)) {
            getShippingData(relatedShippingAddressIDs);
        }
        if(relatedQuoteIds.size()>0){
            getSourceQuoteData(relatedQuoteIds);
        }
        
        if (relatedOpportunityIDs.size() > 0) {
            opportunityData = new Map<Id, Opportunity>([
                    SELECT Id, Configuration_Segment__c ,Shipping_Address_NEW__c, Shipping_Method__c, Shipping_Account_Type__c, Related_Contact__c,
                            Shipping_Carrier__c, Ship_From_Location__c, Shipping_Country__c, Shipping_State__c, Owner_Role_Copy__c,
                            Shipping_Address_NEW__r.Shipping_State__c, Renewal__c, SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Blended_Discount__c,
                            Shipping_Address_NEW__r.Shipping_Country__c,ContractId, CloseDate, Name, SBQQ__RenewedContract__r.SBQQ__Opportunity__r.License_Term__c,
                            Shipping_Address_NEW__r.Name, Shipping_Address_NEW__r.Shipping_Address_Line_1__c, SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Selected_Payment_Type__c,
                            Shipping_Address_NEW__r.Shipping_City__c, Shipping_Address_NEW__r.Shipping_Zip_Code__c,
                            Contract.EndDate, Reseller_Partner__c, Sub_Type__c, License_Term__c, Owner.Region__c,
                            Segment_Sales_Role__c,SBQQ__RenewedContract__r.Auto_Renewal__c, SBQQ__RenewedContract__c, Is_Webstore_Upsell_Opportunity__c,
                            Selected_Payment_Type__c, Renewal_ACV__c, FP_and_Upsell_ACV__c, SBQQ__AmendedContract__c,
                            (SELECT Id FROM SBQQ__Quotes2__r)
                    FROM Opportunity
                    WHERE ID IN :relatedOpportunityIDs
            ]);
            
            for(SBQQ__Quote__c newQuote : newQuoteList) {
                Opportunity relatedOpportunity = opportunityData.get(newQuote.SBQQ__Opportunity2__c);
                if(newQuote.isClone()){
                    cloneMappings(newQuote);
                }
                
                if (relatedOpportunity != null) {
                    newQuote.Configuration_Segment__c = relatedOpportunity.Configuration_Segment__c;
                    if (newQuote.Shipping_Address_NEW__c == null) {
                        newQuote.Shipping_Address_NEW__c = relatedOpportunity.Shipping_Address_NEW__c;
                        newQuote.Shipping_Country__c = relatedOpportunity.Shipping_Address_NEW__r.Shipping_Country__c;
                        newQuote.Shipping_State__c = relatedOpportunity.Shipping_Address_NEW__r.Shipping_State__c;
                        newQuote.SBQQ__ShippingName__c = relatedOpportunity.Shipping_Address_NEW__r.Name;
                        newQuote.SBQQ__ShippingStreet__c = relatedOpportunity.Shipping_Address_NEW__r.Shipping_Address_Line_1__c;  
                        newQuote.SBQQ__ShippingCity__c  = relatedOpportunity.Shipping_Address_NEW__r.Shipping_City__c; 
                        newQuote.SBQQ__ShippingState__c  = relatedOpportunity.Shipping_Address_NEW__r.Shipping_State__c;
                        newQuote.SBQQ__ShippingPostalCode__c = relatedOpportunity.Shipping_Address_NEW__r.Shipping_Zip_Code__c; 
                        newQuote.SBQQ__ShippingCountry__c  = relatedOpportunity.Shipping_Address_NEW__r.Shipping_Country__c; 
                        newQuote.Shipping_Carrier__c   = 'UPS';
                        newQuote.Shipping_Method__c    = '3 Day Select';
                        newQuote.Ship_From_Location__c = 'DCL';
                        //GTMS-27254 - Added ON-Logistics check for Canada location
                        if(relatedOpportunity.Shipping_Country__c == 'Canada') {
                            newQuote.Ship_From_Location__c = HelperClass.shippingCountryDefaults.get(relatedOpportunity.Shipping_Country__c).Ship_From_Location__c;
                            newQuote.Shipping_Method__c = HelperClass.shippingCountryDefaults.get(relatedOpportunity.Shipping_Country__c).Shipping_Method__c;
                            newQuote.Shipping_Carrier__c = HelperClass.shippingCountryDefaults.get(relatedOpportunity.Shipping_Country__c).Shipping_Carrier__c;
                        }
                        
                    }else{
                        newQuote.Shipping_Address_NEW__c = newQuote.Shipping_Address_NEW__c;
                        Shipping_Address__c relatedShippingAddress = shippingData.get(newQuote.Shipping_Address_NEW__c);
                        setShipToDetails(newQuote, relatedShippingAddress);
                    }

                    newQuote.Shipping_Account_Type__c = relatedOpportunity.Shipping_Account_Type__c;
                    newQuote.SBQQ__PrimaryContact__c = newQuote.SBQQ__PrimaryContact__c != null ? newQuote.SBQQ__PrimaryContact__c : relatedOpportunity.Related_Contact__c;
                    newQuote.Selected_Payment_Type__c = relatedOpportunity.Selected_Payment_Type__c;
                    if(newQuote.SBQQ__RenewalTerm__c != NULL){ 
                            Boolean renewedContract = relatedOpportunity.SBQQ__RenewedContract__c != null;
                            //newQuote.SBQQ__Primary__c = (relatedOpportunity.SBQQ__RenewedContract__r.Auto_Renewal__c || newQuote.OwnerId == '0051P000003KrI8')? TRUE : FALSE;
                            //newQuote.SBQQ__MasterContract__c = renewedContract ? relatedOpportunity.SBQQ__RenewedContract__c : newQuote.SBQQ__MasterContract__c;   
                            newQuote.SBQQ__MasterContract__c = newQuote.SBQQ__MasterContract__c == null && relatedOpportunity.ContractId != null ? relatedOpportunity.ContractId : newQuote.SBQQ__MasterContract__c; 
                            if(renewedContract && relatedOpportunity.SBQQ__RenewedContract__r.Auto_Renewal__c){
                                newQuote.ApprovalStatus__c = 'Approved';
                                newQuote.SBQQ__Status__c = 'Approved';
                                newQuote.SBQQ__Primary__c = True;
                        }
                    }
                    if(relatedOpportunity.SBQQ__AmendedContract__c != NULL && newQuote.OwnerId != label.Mulesoft_User_Id && !cwRoboIds.contains(newQuote.OwnerId)){
                        newQuote.SBQQ__Primary__c = FALSE;
                    }
                    //newQuote.SBQQ__StartDate__c = relatedOpportunity.ContractId != null || newQuote.SBQQ__RenewalTerm__c != null ? relatedOpportunity.CloseDate + 15 : relatedOpportunity.CloseDate;
                    //newQuote.SBQQ__MasterContract__c = relatedOpportunity.ContractId; 
                    System.debug('MasterContract : '+newQuote.SBQQ__MasterContract__c +newQuote.SBQQ__StartDate__c);
                    newQuote.Opportunity_Sub_Type__c = relatedOpportunity.Sub_Type__c;  
                    if(relatedOpportunity.Owner.Region__c != NULL && relatedOpportunity.Owner.Region__c != 'None'){
                        if(relatedOpportunity.Owner.Region__c == 'EMEA'){
                            newQuote.Geo_Availablity__c = 'EMEA';
                        }
                        else if(relatedOpportunity.Owner.Region__c == 'North America'){
                            newQuote.Geo_Availablity__c = 'USA'; 
                        }
                    }
                    else{
                        newQuote.Geo_Availablity__c = 'ALL';
                    }
                    
                    //Zakeer-GTMS-4531-Dec-6:Updated SegmentAvailability
                    if(relatedOpportunity.Segment_Sales_Role__c  != NULL){
                        if(relatedOpportunity.Segment_Sales_Role__c == 'Industrial'){
                            newQuote.Segment_Availability__c  = 'Fleet; Industrial; Connected Worker';
                        }
                        else if(relatedOpportunity.Segment_Sales_Role__c == 'Connected Worker'){
                            newQuote.Segment_Availability__c  = 'Fleet;Industrial;Connected Worker';
                        }
                        else if(relatedOpportunity.Segment_Sales_Role__c.contains('AE1')){
                            newQuote.Segment_Availability__c = 'Fleet';
                            newQuote.Sales_Segment__c = 'AE1';
                        }
                        else if(relatedOpportunity.Segment_Sales_Role__c.contains('AE2')){
                            newQuote.Sales_Segment__c = 'AE2';
                            newQuote.Segment_Availability__c = Label.Segment_Default;
                        }
                        else if(relatedOpportunity.Segment_Sales_Role__c.contains('AE3') || relatedOpportunity.Segment_Sales_Role__c.contains('ENT')){
                            newQuote.Sales_Segment__c = 'AE3';
                            newQuote.Segment_Availability__c = Label.Segment_Default;
                        }                       
                        else{
                            newQuote.Segment_Availability__c = Label.Segment_Default;
                            newQuote.Sales_Segment__c = 'ALL';
                        }   
                    }
                    List<String> botIds = system.Label.Bot_Users.split(',');
                    if (!botIds.contains(UserInfo.getUserId())) {
                        HelperClass.setShippingDefaults(Null, newQuote, newQuote.SBQQ__ShippingCountry__c);
                    }
                    /*if (relatedOpportunity.ContractId != null) {
                        newQuote.SBQQ__EndDate__c = relatedOpportunity.Contract.EndDate;
                    }*/
                    if (newQuote.SBQQ__EndDate__c != null) {
                        newQuote.License_Term__c = String.valueOf(newQuote.CalculatedSubscriptionTerm__c);
                    }
                    if (relatedOpportunity.Reseller_Partner__c != null) {
                        newQuote.SBQQ__Partner__c = relatedOpportunity.Reseller_Partner__c;
                    }
                    if(relatedOpportunity.Owner_Role_Copy__c != null && relatedOpportunity.Owner_Role_Copy__c.contains(System.Label.ExpressSegment)
                    || (newQuote.SBQQ__SalesRep__c != null && System.Label.ExpressSegmentOwnerID.contains(newQuote.SBQQ__SalesRep__c))
                    ){
                        newQuote.Configuration_Segment__c = 'Express';
                    }
                    else{
                        newQuote.Configuration_Segment__c = 'Non Express';
                    }
                    //[Non Express] Set Start Date on quote based on master contract
                    //coTermedStartDate(newQuote, relatedOpportunity);
                    
                    //GTMS 4092 copying the fields from NB opportunity
                    if(relatedOpportunity.Owner_Role_Copy__c != null && relatedOpportunity.Owner_Role_Copy__c.contains('Renewal') && relatedOpportunity.Renewal__c && 
                      relatedOpportunity.SBQQ__RenewedContract__c != null && relatedOpportunity.SBQQ__RenewedContract__r.SBQQ__Opportunity__c != null) {
                        newQuote.Original_Blended_Discount__c = relatedOpportunity.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Blended_Discount__c;
                        newQuote.Original_License_Term__c = relatedOpportunity.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.License_Term__c;
                        newQuote.Original_Selected_Payment_Type__c = relatedOpportunity.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.Selected_Payment_Type__c;
                    }
                    
                }
              setTaxData(newQuote);    
            }
        }        
        updateQuoteFields(oldQuoteMap, newQuoteMap, newQuoteList);
    }
    
    // Operations before the quote is updated.
    public void quoteBeforeUpdateOperations(Map<Id, SBQQ__Quote__c> oldQuoteMap, Map<Id, SBQQ__Quote__c> newQuoteMap, List<SBQQ__Quote__c> updatedQuoteList){
        String shippingAndHandlingTaxLocations = System.Label.Shipping_and_Handling_Tax;
        for(SBQQ__Quote__c newQuote : updatedQuoteList){
            Id newShippingAddressId = newQuoteMap.get(newQuote.Id).Shipping_Address_NEW__c;
            if((oldQuoteMap.get(newQuote.Id).Shipping_Address_NEW__c) != (newShippingAddressId)){
                relatedShippingAddressIDs.add(newShippingAddressId);
            }
            relatedContractIDs.add(newQuote.SBQQ__MasterContract__c);
        }
        getSourceQuoteData(newQuoteMap.KeySet());

        if((relatedContractIDs.size()>0) && (contractData == null)){
            getContractData(relatedContractIDs);            
        }
        // Logic to stamp shipping state and country from the shipping address.
        if((relatedShippingAddressIDs.size()>0) && (shippingData == null)){
            getShippingData(relatedShippingAddressIDs);
        }
        for(SBQQ__Quote__c updatedQuote : updatedQuoteList){
            /*if(sourceQuoteData != null && sourceQuoteData.containsKey(updatedQuote.Id) && sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r != null){
                    Opportunity relatedOpportunity = sourceQuoteData.get(updatedQuote.Id).SBQQ__Opportunity2__r;
                    if (relatedOpportunity != null) {
                        coTermedStartDate(updatedQuote, relatedOpportunity);
                    }
             }*/
            if(shippingData != null){
                Shipping_Address__c relatedShippingAddress = shippingData.get(updatedQuote.Shipping_Address_NEW__c);
                setShipToDetails(updatedQuote, relatedShippingAddress);
            }
            /*if(contractData != null){
                Contract relatedContract = contractData.get(updatedQuote.SBQQ__MasterContract__c);
                if(relatedContract != null){
                    updatedQuote.SBQQ__EndDate__c = relatedContract.EndDate;
                }
            }*/
            //Zakeer- GTMS5626-LicenseEndDate update
            /*if(updatedQuote.SBQQ__EndDate__c != null){
                updatedQuote.License_Term__c = String.valueOf(updatedQuote.CalculatedSubscriptionTerm__c);
            }*/
            
            if(updatedQuote.SBQQ__Type__c == 'Renewal' && (updatedQuote.SBQQ__MasterContract__c == NULL )){
                    updatedQuote.SBQQ__EndDate__c = Date.valueOf(updatedQuote.SBQQ__StartDate__c-1).addMonths(Integer.valueOf(updatedQuote.License_Term__c));
                    
            } else if(updatedQuote.SBQQ__EndDate__c != null){
                    updatedQuote.License_Term__c = String.valueOf(updatedQuote.CalculatedSubscriptionTerm__c);
            }

            if((updatedQuote.Shipping_Address_NEW__c != null && oldQuoteMap.get(updatedQuote.Id).Shipping_Address_NEW__c != updatedQuote.Shipping_Address_NEW__c && 
                ShippingData != null && (ShippingData.containsKey(updatedQuote.Shipping_Address_NEW__c)))) {
                String oldShippingAddressId = oldQuoteMap.get(updatedQuote.Id).Shipping_Address_NEW__c;
                String oldShippingCountry;
                if(oldShippingAddressId != null) {
                    relatedShippingAddressIDs.add(oldShippingAddressId);
                    getShippingData(relatedShippingAddressIDs);
                    oldShippingCountry = shippingData != null && ShippingData.containsKey(oldShippingAddressId) ?
                                          ShippingData.get(oldShippingAddressId).Shipping_Country__c : '';
                }
                String shippingCountry = ShippingData != null && ShippingData.containsKey(updatedQuote.Shipping_Address_NEW__c) ?
                       ShippingData.get(updatedQuote.Shipping_Address_NEW__c).Shipping_Country__c : '';
                if(oldShippingCountry != shippingCountry) {
                      HelperClass.setShippingDefaults(Null, updatedQuote, shippingCountry); 
                }
            } /*GTMS-2040 Teja*/

            //ONLY get shipping defaults if the shipping country in the address has changed
            
                        system.debug('Before S&H If');

            if(updatedQuote.Shipping_and_Handling__c != null && updatedQuote.Shipping_and_Handling__c > 0  && updatedQuote.Shipping_and_Handling__c != 99999.99 
               && updatedQuote.Sales_Tax_Rate__c != null && updatedQuote.Sales_Tax_Rate__c > 0 && updatedQuote.Sales_Tax_Rate__c < 100 
               && ((updatedQuote.Shipping_Country__c != null && !(shippingAndHandlingTaxLocations.contains(updatedQuote.Shipping_Country__c))))){
                updatedQuote.S_H_Tax__c = updatedQuote.Shipping_and_Handling__c*(updatedQuote.Sales_Tax_Rate__c/100);
            } else{
                updatedQuote.S_H_Tax__c = 0;
            } 
            // Method to clear the Approved Discount on Quote
            clearOutApprovedQuote(updatedQuote, oldQuoteMap.get(updatedQuote.Id));
            setTaxData(updatedQuote);
        }
        updateQuoteFields(oldQuoteMap, newQuoteMap, updatedQuoteList);
    }
    //* 2/09/21 Groundswell - Tanuj - [Non Express] Checks if there is an approved discount on a quote (i.e on a cloned draft quote) and
    // the selected payment type is changed from upfront or annual to monthly.
    public void clearOutApprovedQuote(SBQQ__Quote__c updatedQuote,  SBQQ__Quote__c oldQuote){
        if(updatedQuote.Configuration_Segment__c != null && updatedQuote.Configuration_Segment__c.equalsIgnoreCase(Label.Configuration_Segment_NonExpress) && isChanged(updatedQuote,oldQuote,Schema.SBQQ__Quote__c.Selected_Payment_Type__c) 
           && (String.isBlank(oldQuote.Selected_Payment_Type__c) || oldQuote.Selected_Payment_Type__c.equalsIgnoreCase(Label.Upfront_Payment_Type)
               || oldQuote.Selected_Payment_Type__c.equalsIgnoreCase(Label.Direct_Annual_Payment_Type)
               ) && updatedQuote.Selected_Payment_Type__c.equalsIgnoreCase(Label.Direct_Monthly_Payment_Type)
                 && updatedQuote.Approved_Discount__c != null)
                 {
                    if(updatedQuote.SBQQ__Source__c != null && sourceQuoteData != null && sourceQuoteData.containsKey(updatedQuote.SBQQ__Source__c)
                        && sourceQuoteData.get(updatedQuote.SBQQ__Source__c).SBQQ__Source__r.Selected_Payment_Type__c != null && !sourceQuoteData.get(updatedQuote.SBQQ__Source__c).SBQQ__Source__r.Selected_Payment_Type__c.equalsIgnoreCase(Label.Direct_Monthly_Payment_Type)){
                        updatedQuote.Approved_Discount__c = null;
                    } else if(updatedQuote.SBQQ__Source__c == null || (sourceQuoteData != null && sourceQuoteData.containsKey(updatedQuote.SBQQ__Source__c)
                        && sourceQuoteData.get(updatedQuote.SBQQ__Source__c).SBQQ__Source__r.Selected_Payment_Type__c == null)){
                            updatedQuote.Approved_Discount__c = null;
                    }
    }
}
    //* 2/09/21 Groundswell - Tanuj
    //[Non Express] Set Start Date on quote based on master contract
    /*public void coTermedStartDate(SBQQ__Quote__c updatedQuote, Opportunity relatedOpportunity){
        // Added by Apisero team to handle Null pointer Exception ticket No: GTMS 3067
        if(!updatedQuote.Is_Webstore_Upsell_Quote__c && updatedQuote.Configuration_Segment__c == 'Non Express')
        if(updatedQuote.Configuration_Segment__c != null){
            if(updatedQuote.Configuration_Segment__c.equalsIgnoreCase(Label.Configuration_Segment_NonExpress)){
                if(updatedQuote.SBQQ__StartDate__c == null &&  updatedQuote.SBQQ__MasterContract__c != null){
                    updatedQuote.SBQQ__StartDate__c = relatedOpportunity.CloseDate + 15;
                }        
            }
        }
    }*/
    //* 2/09/21 Groundswell - Tanuj
    // Helper method for comparing whether a certain field changed between an old Quote and new Quote
    private static Boolean isChanged(SBQQ__Quote__c newQuote, SBQQ__Quote__c oldQuote, Schema.SObjectField field){

        if(oldQuote == null){
            return true;
        }else if(newQuote.get(field) != oldQuote.get(field)){
            return true;
        }else{
            return false;
        }
    }

    //Operations after the quote is updated.
    //* 11/5/2020 Ron - (GTMS - 2064) Query build from Custom Metadata & waterfall approach to ternary operators to make checks based on declarative updates to custom metadata
    //* 06/08/2022 Rodrigo - GTMS-7328 added subsidyFilteredQuotes and subsidy related logic
    public void quoteAfterUpdateOperations(Map<Id, SBQQ__Quote__c> oldQuoteMap, Map<Id, SBQQ__Quote__c> newQuoteMap, List<SBQQ__Quote__c> editedQuoteList){

        Set<Id> relatedOpportunityIds = new Set<Id>();
        Map<Id, Opportunity> opportunityData;
        List<Opportunity> updatedOpportunities = new List<Opportunity>();
        Set<Id> addressFilteredQuotes = new Set<Id>();
        Map<Id, SBQQ__QuoteLine__c> relatedQuoteLines;
        Set<Id> processQuoteEventIds = new Set<Id>();
        List<Shipping_Calculation_Event__e> events = new List<Shipping_Calculation_Event__e>();
        Set<Id> subsidyFilteredQuotes = new Set<Id>(); // add for GTMS-7328
        for (SBQQ__Quote__c editedQuote : editedQuoteList) {
            SBQQ__Quote__c oldQuoteData = oldQuoteMap.get(editedQuote.Id);
            //Logic to retrigger CPQ calculation when Remorse Refund is processed via Mulesoft
            if((editedQuote.Mulesoft_Status__c != oldQuoteData.Mulesoft_Status__c || oldQuoteData.Mulesoft_Status__c == null) && editedQuote.Mulesoft_Status__c == 'Completed'){
                processQuoteEventIds.add(editedQuote.Id);
            }
            relatedOpportunityIds.add(editedQuote.SBQQ__Opportunity2__c);
        }
        
        //Logic to retrigger CPQ calculation when Remorse Refund is processed via Mulesoft
        if(processQuoteEventIds.size() > 0){
            publishQuoteEvent(processQuoteEventIds);
        }

        List<Quote_To_Opportunity_Mapping__mdt> mappings = [SELECT Id, Opportunity_Field__c, Quote_Field__c, Type__c, Null_Check__c, Bypass__c FROM Quote_To_Opportunity_Mapping__mdt];
        if (relatedOpportunityIds.size() > 0) {
            String queryStart = 'SELECT Id';
            String queriedFields = '';
            
            for(Integer i = 0; i < mappings.size(); i++){
                    queriedFields = queriedFields+', '+mappings[i].Opportunity_Field__c;
            }
            system.debug(LoggingLevel.INFO, 'Opp Query: '+queryStart+queriedFields+' FROM Opportunity WHERE Id IN :relatedOpportunityIds');
            opportunityData = new Map<Id, Opportunity>((List<Opportunity>)Database.query(queryStart+queriedFields+' ,Is_Webstore_Upsell_Opportunity__c FROM Opportunity WHERE Id IN :relatedOpportunityIds'));
        }

        Map<String, Quote_To_Opportunity_Mapping__mdt> fieldMappings = new Map<String, Quote_To_Opportunity_Mapping__mdt>();
        for (Quote_To_Opportunity_Mapping__mdt mapping : mappings) {
            fieldMappings.put(mapping.Quote_Field__c, mapping);
        }

        List<SobjectField> dirtyFields = new List<SObjectField>();
        for (SBQQ__Quote__c updatedQuote : editedQuoteList) {
            SBQQ__Quote__c oldQuoteData = oldQuoteMap.get(updatedQuote.Id);

            Boolean changeFlag = false;
            if (updatedQuote.SBQQ__Primary__c == true) {
                Opportunity relatedOpportunity = opportunityData.get(updatedQuote.SBQQ__Opportunity2__c);

                //* 11/5/2020 Ron - (GTMS - 2064) Waterfall approach to ternary operators to make checks based on declarative updates to custom metadata
                for(String quoteField : fieldMappings.keySet()) {
                    Quote_To_Opportunity_Mapping__mdt mappingMetadata = fieldMappings.get(quoteField);
                    String oppField = mappingMetadata.Opportunity_Field__c;
                    Boolean noBypass = mappingMetadata.Bypass__c? false: true;
                    Boolean isChanged = relatedOpportunity.get(oppField) != updatedQuote.get(quoteField)? true: false;
                    Boolean nullCheck = mappingMetadata.Null_Check__c = true && isChanged? updatedQuote.get(quoteField) != null: isChanged;
                    Boolean typeCheck = mappingMetadata.Type__c != null && isChanged? mappingMetadata.Type__c == updatedQuote.Configuration_Segment__c||relatedOpportunity.Is_Webstore_Upsell_Opportunity__c : nullCheck;
                
                    if(isChanged && nullCheck && typeCheck && noBypass){
                        relatedOpportunity.put(oppField, updatedQuote.get(quoteField));
                        changeFlag = true;
                        Schema.SobjectField theDirtyField = Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().get(oppField);
                        dirtyFields.add(theDirtyField);
                    }
                }
                
                if (updatedQuote.Upsell_Amount__c != NULL && (updatedQuote.License_Term__c != NULL || updatedQuote.Custom_License_Term__c != NULL)) {
                    Decimal term = updatedQuote.License_Term__c != NULL? Decimal.valueOf(updatedQuote.License_Term__c) : updatedQuote.Custom_License_Term__c;
                    relatedOpportunity.FP_and_Upsell_ACV__c = updatedQuote.Upsell_Amount__c / (term /12) ;
                    changeFlag = true;
                    dirtyFields.add(Opportunity.FP_and_Upsell_ACV__c);
                }
                
                if (updatedQuote.SBQQ__RenewalTerm__c != NULL && updatedQuote.Renewal_Amount__c != NULL) {
                    relatedOpportunity.Renewal_ACV__c = (updatedQuote.Renewal_Amount__c  + updatedQuote.Downsell_Amount__c) / (Decimal.valueOf(updatedQuote.License_Term__c) /12);
                    //relatedOpportunity.FP_and_Upsell_ACV__c = updatedQuote.Upsell_Amount__c / (Decimal.valueOf(updatedQuote.License_Term__c) /12) ;
                    changeFlag = true;
                    //dirtyFields.add(Opportunity.Upsell_ACV__c);
                    dirtyFields.add(Opportunity.Renewal_ACV__c);
                } 
                
                if ((updatedQuote.License_Term__c != null) &&
                        (relatedOpportunity.License_Term_CPQ__c != Decimal.valueOf(updatedQuote.License_Term__c))) {
                    relatedOpportunity.License_Term_CPQ__c = Decimal.valueOf(updatedQuote.License_Term__c);
                    changeFlag = true;
                    dirtyFields.add(Opportunity.License_Term_CPQ__c);
                }
                if (updatedQuote.License_Term__c != null) {
                    Decimal licenseTerm = Decimal.valueOf(updatedQuote.License_Term__c);
                    if ((relatedOpportunity.License_Term__c != licenseTerm) &&
                        (updatedQuote.SBQQ__MasterContract__c == null)) {
                        relatedOpportunity.License_Term__c = licenseTerm;
                        changeFlag = true;
                        dirtyFields.add(Opportunity.License_Term__c);
                    } 
                }
                /*To sync License Term Fields on Opportunity from CPQ Quote's Custom License Term - GTMS-3734 - @Gaurav Sharma Start*/
                if (updatedQuote.Custom_License_Term__c != null) {
                    if(relatedOpportunity.License_Term_CPQ__c != updatedQuote.Custom_License_Term__c){
                        relatedOpportunity.License_Term_CPQ__c = updatedQuote.Custom_License_Term__c;
                        changeFlag = true;
                        dirtyFields.add(Opportunity.License_Term_CPQ__c);
                    }
                    if(relatedOpportunity.License_Term__c != updatedQuote.Custom_License_Term__c){
                        relatedOpportunity.License_Term__c = updatedQuote.Custom_License_Term__c;
                        changeFlag = true;
                        dirtyFields.add(Opportunity.License_Term__c);
                    }
                }
                /*GTMS-3734 : End*/
                if((oldQuoteData.Blended_Discount__c != updatedQuote.Blended_Discount__c) || 
                   (oldQuoteData.Approved_Discount__c  != updatedQuote.Approved_Discount__c) ||
                   (oldQuoteData.SBQQ__Primary__c != updatedQuote.SBQQ__Primary__c)) {
                    String discountApprovedStatus = updatedQuote.Discount_Approval_Required__c;
                    if (discountApprovedStatus.contains('No Approval Needed')) {
                        relatedOpportunity.Discount_Approval_Status_from_Quote__c = false;
                    } else {
                        relatedOpportunity.Discount_Approval_Status_from_Quote__c = true;
                    }
                    changeFlag = true;
                    dirtyFields.add(Opportunity.Discount_Approval_Status_from_Quote__c);
                }
                // ProductApprovalNeeded__c is set by Price Rules
                if((oldQuoteData.ProductApprovalNeeded__c  != updatedQuote.ProductApprovalNeeded__c) || 
                    (oldQuoteData.SBQQ__Primary__c != updatedQuote.SBQQ__Primary__c)) {
                    String productApprovedStatus = updatedQuote.Product_Approval__c;
                    if (productApprovedStatus.contains('No Approval Needed')) {
                        relatedOpportunity.Product_Approval_Status_from_Quote__c = false;
                    } else {
                        relatedOpportunity.Product_Approval_Status_from_Quote__c = true;
                    }
                    changeFlag = true;
                    dirtyFields.add(Opportunity.Product_Approval_Status_from_Quote__c);
                }
                if((oldQuoteData.Approved_Discount__c != updatedQuote.Approved_Discount__c) ||
                   (relatedOpportunity.Approved_Discount__c != updatedQuote.Approved_Discount__c) ||
                   (oldQuoteData.SBQQ__Primary__c != updatedQuote.SBQQ__Primary__c)) {
                    relatedOpportunity.Approved_Discount__c = updatedQuote.Approved_Discount__c;
                    changeFlag = true;
                    dirtyFields.add(Opportunity.Approved_Discount__c);
                }
                
                if(changeFlag == true) {
                    DMLWrapper.doUpdate(relatedOpportunity, dirtyFields);
                }
            }
            
            /*if(System.Label.Zekraft_API_Enabled.toLowercase() == 'true' &&  updatedQuote.CreatedDate >= DateTime.parse(System.Label.Shipping_Quote_Start_Date) &&
                ((oldQuoteData.SBQQ__Status__c != updatedQuote.SBQQ__Status__c) || 
                (oldQuoteData.Recalculate_S_H_Cost__c != updatedQuote.Recalculate_S_H_Cost__c) && (updatedQuote.Recalculate_S_H_Cost__c == true) ||
                ((oldQuoteData.Shipping_Address_NEW__c != updatedQuote.Shipping_Address_NEW__c) && (updatedQuote.Shipping_Address_NEW__c != null)) ||
                ((oldQuoteData.Unique_Shipping_Addresses__c  != updatedQuote.Unique_Shipping_Addresses__c ) && (updatedQuote.Unique_Shipping_Addresses__c > 0)) ||
                ((oldQuoteData.Shipping_Method__c  != updatedQuote.Shipping_Method__c) && (updatedQuote.Shipping_Method__c != null)) ||
                ((oldQuoteData.Total_Weight_oz__c  != updatedQuote.Total_Weight_oz__c) && (updatedQuote.Total_Weight_oz__c >= 0))) && 
                (updatedQuote.Shipping_Method__c != 'Will Call') && (updatedQuote.SBQQ__Status__c == 'Approved')){
                    system.debug('In the Event');
                    events.add(new Shipping_Calculation_Event__e(Id__c = updatedQuote.Id));
            }*/
            
            if((oldQuoteData.Shipping_Address_NEW__c != updatedQuote.Shipping_Address_NEW__c) || 
               (oldQuoteData.Ship_From_Location__c  != updatedQuote.Ship_From_Location__c)){
                   addressFilteredQuotes.add(updatedQuote.Id);
            }
            
            // added for GTMS-7328 to check if there is changed in License_Term__c/Selected_Payment_Type__c
            // added for GTMS-7328 starts here
            if( (oldQuoteData.License_Term__c != updatedQuote.License_Term__c) ||
               (oldQuoteData.Selected_Payment_Type__c != updatedQuote.Selected_Payment_Type__c))
                subsidyFilteredQuotes.add(updatedQuote.Id);
            // added for GTMS-7328 end here
        }
        if(events.size()>0){
           //EventBus.publish(events);   
        }
        
        // GTMS-7328 changes the condition and SOQL where clause and fields
        if ((newQuoteMap.keyset().size() > 0) && ((addressFilteredQuotes.size() > 0) || (subsidyFilteredQuotes.size() > 0))) {
            relatedQuoteLines = new Map<Id, SBQQ__QuoteLine__c>([
                    SELECT Id, SBQQ__Quote__c, Ship_To__c, Ship_From_Location__c, Total_Subsidy__c, Total_Subsidy_Calc__c, 
                SBQQ__ProductCode__c,Subsidy_Method__c,Subsidy_Amount__c, One_Time__c   
                    FROM SBQQ__QuoteLine__c
                    WHERE (SBQQ__Quote__c IN :addressFilteredQuotes OR SBQQ__Quote__c IN :subsidyFilteredQuotes)
            ]);
        }

        dirtyFields = new List<SObjectField>();
        // Code to stamp the changed Ship TO on line items.
        List<SBQQ__QuoteLine__c> updatedQuoteLines = new List<SBQQ__QuoteLine__c>();
        if (relatedQuoteLines != null) {
            for (SBQQ__QuoteLine__c quoteLine : relatedQuoteLines.values()) {
                SBQQ__Quote__c newQuoteData = newQuoteMap.get(quoteLine.SBQQ__Quote__c);
                Boolean changeFlag = false;
                if (quoteLine.Ship_To__c != newQuoteData.Shipping_Address_NEW__c) {
                    quoteLine.Ship_To__c = newQuoteData.Shipping_Address_NEW__c;
                    changeFlag = true;
                    dirtyFields.add(SBQQ__QuoteLine__c.Ship_To__c);
                }
                if(quoteLine.Ship_From_Location__c  != newQuoteData.Ship_From_Location__c ){
                    quoteLine.Ship_From_Location__c = newQuoteData.Ship_From_Location__c ;
                    changeFlag = true;
                    dirtyFields.add(SBQQ__QuoteLine__c.Ship_From_Location__c);
                }
                
                // added for GTMS-7328 to check if product code is 'INS-SUBSIDY'
                // added for GTMS-7328 starts here
                
                if (quoteLine.SBQQ__ProductCode__c =='INS-SUBSIDY')
                {
                    if (quoteLine.Subsidy_Method__c=='Fixed $') {
                        if (quoteLine.One_Time__c==true){ // added for GTMS-9561
                            quoteLine.Total_Subsidy__c = quoteLine.Total_Subsidy_Calc__c;
                        }else {
                            if (newQuoteData.Selected_Payment_Type__c != null) {
                                if (newQuoteData.Selected_Payment_Type__c == 'Direct Monthly'){
                                    quoteLine.Total_Subsidy__c = quoteLine.Total_Subsidy_Calc__c;
                                }
                                // DirectQuarterly: GTMS-13035 - Sep20
                                if (newQuoteData.Selected_Payment_Type__c == 'Direct Quarterly'){
                                    quoteLine.Total_Subsidy__c = quoteLine.Total_Subsidy_Calc__c * 3;
                                }
                                if (newQuoteData.Selected_Payment_Type__c == 'Direct Annual'){
                                    quoteLine.Total_Subsidy__c = quoteLine.Total_Subsidy_Calc__c * 12;
                                }
                                if (newQuoteData.Selected_Payment_Type__c == 'Upfront Payments' && newQuoteData.License_Term__c != null) {
                                    if (newQuoteData.License_Term__c == '12')
                                        quoteLine.Total_Subsidy__c = quoteLine.Total_Subsidy_Calc__c * 12;
                                    if (newQuoteData.License_Term__c == '36')
                                        quoteLine.Total_Subsidy__c = quoteLine.Total_Subsidy_Calc__c * 36;
                                    if (newQuoteData.License_Term__c == '60')
                                        quoteLine.Total_Subsidy__c = quoteLine.Total_Subsidy_Calc__c * 60;
                                }
                                changeFlag = true;
                                dirtyFields.add(SBQQ__QuoteLine__c.Total_Subsidy__c);
                            }
                        }
                    }
                    if (quoteLine.Subsidy_Method__c=='Percentage') {
                        if (newQuoteData.Selected_Payment_Type__c != null) {
                            if (newQuoteData.Selected_Payment_Type__c == 'Direct Monthly')
                                quoteLine.Total_Subsidy__c = (quoteLine.Subsidy_Amount__c/100) * (-1) * newQuoteData.Monthly_License_with_Tax__c;
                            if (newQuoteData.Selected_Payment_Type__c == 'Direct Quarterly')
                                quoteLine.Total_Subsidy__c = (quoteLine.Subsidy_Amount__c/100) * (-1) * newQuoteData.Quarterly_License_with_Tax__c;    
                            if (newQuoteData.Selected_Payment_Type__c == 'Direct Annual')
                                quoteLine.Total_Subsidy__c = (quoteLine.Subsidy_Amount__c/100) * (-1) * newQuoteData.Annual_License_with_Tax__c;
                            if (newQuoteData.Selected_Payment_Type__c == 'Upfront Payments') {
                                quoteLine.Total_Subsidy__c = (quoteLine.Subsidy_Amount__c/100) * (-1) * newQuoteData.Total_License_Due__c;
                            }
                            changeFlag = true;
                            dirtyFields.add(SBQQ__QuoteLine__c.Total_Subsidy__c);
                        }
                    } 
                    
                }
                // added for GTMS-7328 ends here
                // 
                if(changeFlag == true) {
                    //updatedQuoteLines.add(quoteLine);
                    DMLWrapper.doUpdate(quoteLine, dirtyFields);
                }
            } 
        }
    }
    
    // Method to set the Shipping Fields
    public void setShipToDetails(SBQQ__Quote__c quote, Shipping_Address__c relatedShippingAddress){
        if(relatedShippingAddress != null){
           quote.Shipping_Country__c = relatedShippingAddress.Shipping_Country__c;
           quote.Shipping_State__c = relatedShippingAddress.Shipping_State__c;
           quote.SBQQ__ShippingName__c = relatedShippingAddress.Name;
           quote.SBQQ__ShippingStreet__c = relatedShippingAddress.Shipping_Address_Line_1__c;  
           quote.SBQQ__ShippingCity__c  = relatedShippingAddress.Shipping_City__c; 
           quote.SBQQ__ShippingState__c  = relatedShippingAddress.Shipping_State__c;
           quote.SBQQ__ShippingPostalCode__c = relatedShippingAddress.Shipping_Zip_Code__c; 
           quote.SBQQ__ShippingCountry__c  = relatedShippingAddress.Shipping_Country__c; 
         }
         else if(relatedShippingAddress == null){
           quote.Shipping_Country__c = null;
           quote.Shipping_State__c = null;
           quote.SBQQ__ShippingName__c = null;
           quote.SBQQ__ShippingStreet__c = null;  
           quote.SBQQ__ShippingCity__c  = null; 
           quote.SBQQ__ShippingState__c  = null;
           quote.SBQQ__ShippingPostalCode__c = null; 
           quote.SBQQ__ShippingCountry__c  = null;
         }
    }

    // Method to query the Shipping Data
    private void getShippingData(Set<Id> shippingIds){
         shippingData = new Map<Id, Shipping_Address__c>([SELECT Id, Name, Shipping_State__c, Shipping_City__c, Shipping_Country__c,
                        Shipping_Address_Line_1__c, Shipping_Zip_Code__c
                FROM Shipping_Address__c
                WHERE ID IN :shippingIds
        ]);
    }

    // Method to query the Source Quote
    //* 2/10/21 Groundswell - Tanuj
    // Updated the Helper method for fetching Parent data on Quote Object. Ex:Source Quote/Oppty
    private void getSourceQuoteData(Set<Id> quoteIds) {
        sourceQuoteData = new Map<Id, SBQQ__Quote__c>([
                SELECT Id, Approved_Discount__c, ApprovedProductsCount__c, Selected_Payment_Type__c,
                SBQQ__Source__c, SBQQ__Source__r.Selected_Payment_Type__c,SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.CloseDate
                FROM SBQQ__Quote__c
                WHERE ID IN :quoteIds
        ]);
}
    
    // Method to query the Contact Data
    private void getContractData(Set<Id> contractIds){
         contractData = new Map<Id, Contract>([SELECT Id, EndDate, Auto_Renewal__c 
                                               FROM Contract WHERE ID IN : contractIds]);      
    }

    // SBQQ__WatermarkShown__c can be deprecated from code
    // Should me modified to reduce the execution time/ Move the whole logic to PriceRules -Harsha
    public void updateQuoteFields(Map<Id, SBQQ__Quote__c> oldQuoteMap, Map<Id, SBQQ__Quote__c> newQuoteMap, List<SBQQ__Quote__c> quoteList) {
        SBAA_Enablement_IDs__c sbaaIds = SBAA_Enablement_IDs__c.getInstance();
        Set<Id> qtIds = new Set<Id>();
        for(SBQQ__Quote__c quote: quoteList) {
            if(Trigger.isInsert || oldQuoteMap.get(quote.Id).ApprovalStatus__c != quote.ApprovalStatus__c) {
                if(quote.ApprovalStatus__c == 'Approved') {
                    quote.RecordTypeId = sbaaIds.Approved_Quote_RT__c;
                    quote.SBQQ__Status__c = 'Approved';
                    quote.SBQQ__WatermarkShown__c = false;
                    quote.Approved_Discount__c = quote.Blended_Discount__c + Decimal.valueOf(System.Label.Approved_Discount_Increment);
                    quote.ApprovedProductsCount__c = quote.NumOfProductsNeedingApproval__c;
                }
                else if(quote.ApprovalStatus__c == 'Pending') {
                    quote.RecordTypeId = sbaaIds.In_Progress_Quote_RT__c;
                    quote.SBQQ__Status__c  = 'In Review';
                    quote.SBQQ__WatermarkShown__c  = true;
                }
                else if(quote.ApprovalStatus__c == 'Rejected') {
                    quote.RecordTypeId = sbaaIds.Draft_Quote_RT__c;
                    quote.SBQQ__Status__c = 'Denied';
                    quote.SBQQ__WatermarkShown__c = true;
                    if(quote.SBQQ__MasterContract__c != null){
                       quote.RejectedAddOn__c = true;
                    }
                }
                else {
                    quote.RecordTypeId = sbaaIds.Draft_Quote_RT__c;
                    quote.SBQQ__Status__c  = 'Draft';
                    quote.SBQQ__WatermarkShown__c  = true;
                }
            }
            if(!Trigger.isInsert){
                //GTMS-4872 Fix ReadTimeOut error by skipping for Bot Users
                List<String> botIds = system.Label.Bot_Users.split(',');
                if(oldQuoteMap.get(quote.Id).SBQQ__LastCalculatedOn__c == null && 
                   oldQuoteMap.get(quote.Id).SBQQ__LastCalculatedOn__c  != quote.SBQQ__LastCalculatedOn__c &&
                   !botIds.contains(quote.CreatedById) && quote.CreatedById != label.Mulesoft_User_Id) {
                    qtIds.add(quote.Id);
                }
            }
        }
        if(!qtIds.isempty() && !Test.isRunningTest())recalculateQuote(qtIds);
    }

    @future
    public static void recalculateQuote(Set<Id> quoteIds) {
        List<SBQQ__Quote__c> qts = new List <SBQQ__Quote__c>();
        for (Id qId : quoteIds) {
            SBQQ__Quote__c cpq = new SBQQ__Quote__c(Id = qId, Recalculate_Quote__c = true, First_Calculated__c = Date.today());
            qts.add(cpq);
        }
        if (!qts.isempty()) update qts;
    }
    
    private void cloneMappings(SBQQ__Quote__c quote){
        quote.ApprovalStatus__c = null;
        quote.SBQQ__Status__c = 'Draft';
        quote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Draft Quote').getRecordTypeId();
        quote.Selected_Payment_Type__c = null;
        if(sourceQuoteData != null && sourceQuoteData.containsKey(quote.SBQQ__Source__c)){
            SBQQ__Quote__c sourceRecord = sourceQuoteData.get(quote.SBQQ__Source__c);
            quote.Approved_Discount__c = sourceRecord.Approved_Discount__c;
            quote.ApprovedProductsCount__c = sourceRecord.ApprovedProductsCount__c;
        }
        if(quote.ClonedQuoteAppendName__c == FALSE) {
            quote.ClonedQuoteAppendName__c = True;
            String quoteName = String.isBlank(quote.Quote_Name__c) ? '' : quote.Quote_Name__c;
            quote.Quote_Name__c = quoteName + ' Cloned Copy';
        }
    }
    
    /**
     * Publish the QuoteEvent
     * @param lineIds
     */
    public static void publishQuoteEvent(set<Id> QuoteIds) {
        System.debug('====== publishQuoteEvent');
        //Set<Id> ids = new Set<Id>(QuoteIds);
        QuoteEvent__e event = new QuoteEvent__e(Event_Data__c = Json.serialize(QuoteIds));
        List<QuoteEvent__e> eventList = new List<QuoteEvent__e>();
        eventList.add(event);
        List<Database.SaveResult> results = EventBus.publish(eventList);
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('====== Successfully published QuoteEvent__e event');
                return;
            } else {
                System.debug('====== Failed to publish QuoteEvent__e event');
                //throw exception
            }
        }
    }
    public void createQuoteSavePE(List<SBQQ__Quote__c> quoteList) {
        for(SBQQ__Quote__c q : quoteList) {
            if(!recursionCheck && q.SBQQ__Primary__c && !quoteSaveEvents.containsKey(q.Id) && q.SBQQ__LineItemCount__c != null && q.SBQQ__LineItemCount__c > 0) {
                quoteSaveEvents.put(q.Id, new Quote_Save__e(Quote_Id__c = q.Id));
            }
        }
        system.debug('******quoteSaveEvents***** ' + quoteSaveEvents);
        if(!quoteSaveEvents.values().isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(quoteSaveEvents.values());
            recursionCheck = true;
        }
    }
    
    private void setTaxData(SBQQ__Quote__c quote){
      if(quote.Taxpayer_Code__c == NULL && quote.Shipping_Country__c == 'Mexico'){
          quote.Taxpayer_Code__c = System.Label.MX_Taxpayer_Code;
       }
    }
}