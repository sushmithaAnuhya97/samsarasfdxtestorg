/**********************************************************************
Name: OpptyLineitemDiscountBatch
Purpose: This batch job looks at Opp closed status and process the
Line Item discount values Into Customer 360 record.
History
VERSION     AUTHOR               DATE                 DETAIL
1.0        Anil Bogadi        03/22/2021        INITIAL DEVELOPMENT
2.0        Anil Bogadi        05/27/2021        GTMS-3877 OPTIMIZATION
3.0        Satya D            08/03/2021        GTMS-4210 Create a roll-up process from opportunity to C360 to turn off licenses
4.0.       Rodrigo C          08/18/2022.       GTMS-8223 added SOT related changes
5.0        Zakeer            09/12/2022.       GTMS-8420 #111
6.0        Siddharth         Mar-14-2023       GTMS-11706 VG Basic Phase 2
7.0        Govindaraju        06/29/2023       GTMS-13598 Sync the fields(VG Tier and CM Tier) values from customer 360 to Account object when Opty is Closed Won.
8.0        Mohamed          02/12/2024      GTMS-18165 - Bridge skus on customer 360, Account record
9.0        Mohamed            06/04/2024        GTMS-21331 - Asset Tag License- Identifier for Gainsight
10.0        Mohamed            06/14/2024        GTMS-21109 - Webstore fields for STCE SKUs
    ***************************************************************************************************************************************/
Public class OpptyLineitemDiscountBatch  implements Database.Batchable<sobject>{
    public String query;
    static string c360DiscountNMUPFields = '';
    public String closedstatus = 'Closed Won';
    public Opportunity_Product_Code__mdt OPC_MetaData_Values ;
    public static Map<String,String> ProdCodeValues = new Map<String,String>();
    public static Map<String,Boolean> SkipProdCodeValues = new Map<String,Boolean>();
    public static Map<String,String> oemProductCodeValues = new Map<String,String>();
    public static Set<String> setVGBasicProductCodes = new Set<String>{'LIC-VG-BASIC'};
    //GTMS-11706
    public static Set<String> setVGENTProductCodes = new Set<String>{'LIC-VG-ENT'};
    //Zakeer
    //Edit by: Govindaraju Boddu
    //Edit on: 29th, June 2023
    public static String vgCmTierRegex = System.Label.OLIDiscBatch_Regex;
    //Edit on: 14th, March 2024 - Mohamed - GTMS-18165
    public static Map<String,String> ProProdMap = new Map<String,String>{
        'LIC-CM1-PRO'=>'LIC_CM1_PRO__c',
        'LIC-CM2-PRO'=>'LIC_CM2_PRO__c',
        'LIC-VG-PRO'=>'LIC_VG_PRO__c',
        'LIC-PLTFM-PRO'=>'LIC_PLTFM_PRO__c'
        //'LIC-CM-PRO'=>'LIC_CM_PRO__c' //GTMS-25530
    };
    public static Map<String,String> vgCmTierMap = (Map<String,String>) JSON.deserialize(System.Label.OLIDiscBatch_Tier_Map, Map<String,String>.class);
    public String OpptyLineItemDiscountBatchEmailAddress = System.Label.OpptyLineItemDiscountBatchEmailAddress;
    //Edit end: 14th, March 2024 - Mohamed - GTMS-18165
    //Edit end: 29th, June 2023
    //Edit on: 14th, March 2024 - Mohamed - GTMS-18165
    private List <Database.UpsertResult> saveResults;
    public List<Id> successfulAccRecords = new List<Id>();
    public List<Account> accountfailedRecords = new List<Account>();
    public List<String> failedAccRecordsErrors = new List<String>();
    public List<Id> successfulCustRecords = new List<Id>();
    public List<Id> customer360failedRecords = new List<Id>();
    public List<String> failedCust360RecordsErrors = new List<String>();
    public List<String> CustomExceptionError = new List<String>();
    public static string currentAccount; // Added Exclusively to track the account at which failure occured.
    public static string currentOppLine; // Added Exclusively to track the OpportunityLineItem at which failure occured.
    //Edit end: 14th, March 2024 - Mohamed - GTMS-18165
    public OpptyLineitemDiscountBatch (String q )
    {
        query=q;
        //getMetadataValues();
    }
    public OpptyLineitemDiscountBatch ()
    {
    }
    public Database.QueryLocator start(Database.BatchableContext BC){

        query = String.isBlank(query) ? System.Label.OppLineItemDiscount : query;

        return Database.getQueryLocator( query );
    }
    
    public void execute(Database.BatchableContext BC, List<OpportunityLineItem> Closed_Lineitems_Optys){
        Map<Id,List<OpportunityLineItem>> Acct_LineItem_Combo = new Map<Id, List<OpportunityLineItem>> ();
        Map<Id,List<OpportunityLineItem>> ContractSubscriptionMap = new Map<Id, List<OpportunityLineItem>> ();
        Map<String,Decimal> SubProdQtyMap = new Map<String,Decimal>();
        Map<String,Decimal> OppProdQtyMap = new Map<String,Decimal>();
        List<SBQQ__Subscription__c> subRecLst = new List<SBQQ__Subscription__c>();
        Map<Id,Customer_360__c> acct_360Combo = new Map<Id,Customer_360__c>();
        Map<Id,Customer_360__c> Update_acct_360Combo = new Map<Id,Customer_360__c> ();
        Map<Id,List<OpportunityLineItem>> insert_C360_Acct_LineItem_Combo = new Map<Id, List<OpportunityLineItem>> ();
        getMetadataValues();
        List<Customer_360__c> upsertlst = new List<Customer_360__c> ();
        //Edit by: Govindaraju Boddu
        //Edit on: 29th, June 2023
        List<Account> updateAccountList = new List<Account>();
        //Edit end: 29th, June 2023
        List<Id> accountIdsWithNewC360 = new List<Id>();
        // GTMS-28054 : Track accounts that have Revenue Opportunities
        Set<Id> accountsWithRevenueOpps = new Set<Id>();
        List<Log__c> logList = new List<Log__c>();
        try{
            //Looping through the List of Opp Line items to create the Unique set of Account and Line Items.
            for(OpportunityLineItem oi :  Closed_Lineitems_Optys){
                // GTMS-28054 : Track accounts with Revenue OpportunitiesAdd commentMore actions
                if(oi.Opportunity_Type__c == 'Revenue Opportunity') {
                    accountsWithRevenueOpps.add(oi.Account__c);
                }
                if(Acct_LineItem_Combo.containskey(oi.Account__c)){
                    Acct_LineItem_Combo.get(oi.Account__c).add(oi);
                }else{
                    Acct_LineItem_Combo.put(oi.Account__c,new List<OpportunityLineItem> {oi});
                }
                //Edit on: 14th, March 2024 - Mohamed - GTMS-18165
                //Edit on: 11th, Dec 2024 - Abu - GTMS-23015
                if(oi.ProductCode.contains('PRO')){
                    if(OppProdQtyMap.containsKey(oi.Account__c+'-'+oi.ProductCode)){
                        decimal keyQuantity = OppProdQtyMap.get(oi.Account__c+'-'+oi.ProductCode) +oi.Quantity ;
                        OppProdQtyMap.put(oi.Account__c+'-'+oi.ProductCode,keyQuantity);
                    }
                    else{
                        OppProdQtyMap.put(oi.Account__c+'-'+oi.ProductCode,oi.Quantity);
                    }
                }
                //Edit end: 14th, March 2024 - Mohamed - GTMS-18165
            }//end of For loop.
            system.debug('OppProdQtyMap:'+OppProdQtyMap);
            //Edit on: 14th, March 2024 - Mohamed - GTMS-18165
            //Query for subscription record where contract is active and contract recordtype is not equal to free trail
            //and contract end date is greater than or equal to today
            if(!Acct_LineItem_Combo.isEmpty()){
                for(SBQQ__Subscription__c sub: [SELECT ID,SBQQ__Account__c,SBQQ__Quantity__c,SBQQ__Product__r.ProductCode, SBQQ__RenewalQuantity__c,SBQQ__Product__c 
                                                FROM SBQQ__Subscription__c 
                                                WHERE SBQQ__Contract__r.Is_Active__c = true 
                                                AND SBQQ__Contract__r.recordtype.name <> 'Free Trial' 
                                                AND SBQQ__Account__c =:Acct_LineItem_Combo.keyset() 
                                                AND SBQQ__Contract__r.EndDate >= Today ]){
                    if(sub.SBQQ__Product__r.ProductCode.contains('PRO')){
                        if(SubProdQtyMap.containsKey(sub.SBQQ__Account__c+'-'+sub.SBQQ__Product__r.ProductCode)){
                            decimal keyQuantity = SubProdQtyMap.get(sub.SBQQ__Account__c+'-'+sub.SBQQ__Product__r.ProductCode) +sub.SBQQ__Quantity__c ;
                            SubProdQtyMap.put(sub.SBQQ__Account__c+'-'+sub.SBQQ__Product__r.ProductCode,keyQuantity);
                        }
                        else{
                            SubProdQtyMap.put(sub.SBQQ__Account__c+'-'+sub.SBQQ__Product__r.ProductCode,sub.SBQQ__Quantity__c);
                        }
                    }
                }
            }
            //Edit end: 14th, March 2024 - Mohamed - GTMS-18165
            system.debug('SubProdQtyMap:'+SubProdQtyMap);
            //Get the Customer 360 records based on Account Id in this Acct_LineItem_Combo.
            //This is to check if the Customer 360 record got created for the account.
            // added SOT__c check in the where clause for GTMS-8223 --SOT__c = true AND

            list<Id> accIds = new list<Id>(Acct_LineItem_Combo.keyset());

            String c360Query = 'SELECT Id, Account__c, Hide_Licenses_in_Webstore__c, SOT__c, Latest_Active_Contract_Historical__c, ';
            c360Query+= 'First_Purchase_Date__c, ' + c360DiscountNMUPFields.removeEnd(', ') + ' FROM  Customer_360__c WHERE SOT__c = true AND Account__c IN :accIds';

            if(!Acct_LineItem_Combo.isEmpty()){
                // Execute the query
                for(Customer_360__c cs : Database.query( c360Query ) ){
                    acct_360Combo.put(cs.Account__c,cs);
                }
            }
            system.debug('acct_360Combo:'+acct_360Combo);
            system.debug('acct_360Combo.keyset:'+acct_360Combo.keyset());
            system.debug('acct_360Combo.size:'+acct_360Combo.keyset().size());
            //Loop through Account Ids and create the UPSERT records.
            if(!Acct_LineItem_Combo.isEmpty()){
                for(Id d : Acct_LineItem_Combo.keyset()){
                    currentAccount = String.valueOf(d);
                    currentOppLine = null;
                    SObject Customer360_record;
                    //Edit by: Govindaraju Boddu
                    //Edit on: 29th, June 2023
                    SObject accountRecord;
                    //Edit end: 29th, June 2023
                    if(acct_360Combo.containsKey(d)){
                        system.debug('contains');
                        Customer_360__c cust360 = new Customer_360__c();
                        cust360 = acct_360Combo.get(d);
                        Customer360_record = (SObject)cust360;
                        Customer360_record.put('Account__c',d);
                    }
                    else{
                        Customer360_record = new Customer_360__c();
                        Customer360_record.put('Account__c',d);
                        Customer360_record.put('SOT__c',true); // added for GTMS-8223
                        accountIdsWithNewC360.add(d);
                    }
                    //Edit by: Govindaraju Boddu
                    //Edit on: 29th, June 2023
                    System.debug('@@@ Id::'+d);
                    //SObject accountRecord;
                    accountRecord = new Account();
                    accountRecord.put('Id',d);
                    //Edit end: 29th, June 2023
                    
                    for(OpportunityLineItem oi : Acct_LineItem_Combo.get(d)){

                        currentOppLine = String.valueOf(oi.Id);
                        
                        //Zakeer-GTMS8420-Sep-6
                        if(oi.Opportunity.First_Purchase__c && oi.Opportunity.Account.Book_Of_Business__c != NULL){
                            Customer360_record.put('Hide_Licenses_in_Webstore__c' , True);
                        }
                        
                        //Zakeer-GTMSTycoon
                        if(oi.Opportunity.First_Purchase__c || oi.Opportunity.Renewal__c ){
                            Customer360_record.put('Latest_Active_Contract_Historical__c', NULL);
                        }
                        
                        // Process header fields
                        processHeaderFields(oi, Customer360_record, accountRecord, SubProdQtyMap, OppProdQtyMap);
                        
                        if( (!oi.Opportunity.SBQQ__Renewal__c && oi.Opportunity.SBQQ__RenewedContract__c == null && oi.Opportunity.SBQQ__AmendedContract__c == null) ||
                            (oi.Opportunity.SBQQ__Renewal__c || oi.Opportunity.SBQQ__RenewedContract__c != null) ){
                            //logic for calculating discount for Non-Pro Products
                            if(String.isNotBlank(oi.ProductCode)){
                                if (ProdCodeValues.containsKey(oi.ProductCode)) {
                                    Customer360_record.put(ProdCodeValues.get(oi.ProductCode), oi.SBQQ__QuoteLine__r.SBQQ__TotalDiscountRate__c);
                                }
                                
                                String prodCodeWithMUP = oi.ProductCode + '-MUP';
                                if (ProdCodeValues.containsKey(prodCodeWithMUP)) {
                                    Customer360_record.put(ProdCodeValues.get(prodCodeWithMUP), oi.Monthly_Unit_Price__c);
                                }
                            }
                        } else if ( oi.Opportunity.SBQQ__AmendedContract__c != null){
                            String productCode = oi.ProductCode;
                            // Get mapped field API names correctly
                            String discountFieldAPIName = ProdCodeValues.get(productCode); // Discount field is directly mapped
                            String mupFieldAPIName = ProdCodeValues.get(productCode + '-MUP'); // MUP field uses "-MUP" in the key
                            // Get new values from OLI
                            Decimal discountValue = oi.SBQQ__QuoteLine__r?.SBQQ__TotalDiscountRate__c;
                            Decimal mupValue = oi.Monthly_Unit_Price__c;
                            
                            // Update Discount field if mapped and necessary
                            if (discountFieldAPIName != null && discountValue != null) {
                                Decimal existingDiscount = (Customer360_record.get(discountFieldAPIName) != null) ? (Decimal) Customer360_record.get(discountFieldAPIName) : null;
                                if (existingDiscount == null || existingDiscount == 0) {
                                    Customer360_record.put(discountFieldAPIName, discountValue);
                                }
                            }
                            
                            // Update MUP field if mapped and necessary
                            if (mupFieldAPIName != null && mupValue != null) {
                                Decimal existingMUP = (Customer360_record.get(mupFieldAPIName) != null) ? (Decimal) Customer360_record.get(mupFieldAPIName) : null;
                                if (existingMUP == null || existingMUP == 0) {
                                    Customer360_record.put(mupFieldAPIName, mupValue);
                                }
                            }//changes of GTMS-26874 end
                        }
                    }//end of inside for.
                    
                    // GTMS-28054 : Only add to Customer_360__c upsert list if account has Revenue OpportunitiesAdd commentMore actions
                    if(accountsWithRevenueOpps.contains(d)){
                        upsertlst.add((Customer_360__c) Customer360_record);
                    }
                    
                    //Edit by: Govindaraju Boddu
                    //Edit on: 29th, June 2023
                    System.debug('accountRecord::'+accountRecord);
                    if(accountRecord.get('CM_Tier__c') != null || accountRecord.get('VG_Tier__c') != null || accountRecord.get('LIC_CM1_PRO__c') != null ||   accountRecord.get('LIC_CM2_PRO__c') != null || accountRecord.get('LIC_VG_PRO__c') != null || accountRecord.get('LIC_PLTFM_PRO__c') != null || accountRecord.get('LIC_AT_TAG__c') != null ||  accountRecord.get('Platform_Type__c') != null || accountRecord.get('P_P_Pilot_Customer__c') != null || accountRecord.get('P_P_Customer_Type__c') != null)
                    {
                        /* Edit End OEM Related changes commented  21st, August 2024 - Abu - GTMS-22195 */
                        System.debug('accountRecord: inside if:'+accountRecord);
                        updateAccountList.add((Account) accountRecord);
                    }
                    //Edit end: 29th, June 2023
                }//end of outside for.
                currentAccount = null;
                currentOppLine = null;
            }
            System.debug('upsertlst::'+upsertlst);
            System.debug('upsertlst.size()::'+upsertlst.size());
            System.debug('updateAccountList::'+updateAccountList);
            System.debug('updateAccountList.size()::'+updateAccountList.size());
            //If check for Acct_LineItem_Combo.
            //Edit on: 14th, March 2024 - Mohamed - GTMS-18165
            if(!upsertlst.isEmpty()){
                List<Database.upsertResult> uResults = Database.upsert(upsertlst, Customer_360__c.Id,false);
                system.debug('uResults:'+uResults);
                // Iterate over the save results
                for (Database.upsertResult uRes  : uResults) {
                    system.debug('uRes.isSuccess():'+uRes.isSuccess());
                    if (uRes.isSuccess()) {
                        System.debug('Record Succesffully created '+uRes.getId());
                        successfulCustRecords.add(uRes.getId());
                    } else {
                        customer360failedRecords.add(uRes.getId());
                        // Record failed to insert/update
                        for (Database.Error error : uRes.getErrors()) {
                            failedCust360RecordsErrors.add(error+'-'+failedCust360RecordsErrors);
                            logList.add( getLog ('C360 batch Failure ', 'C360 Upsert', error.getMessage(), error.getFields().toString(), null, null) );
                        }
                    }
                }
            }
            system.debug('successfulCustRecords:'+successfulCustRecords);
            //Edit by: Govindaraju Boddu
            //Edit on: 29th, June 2023
            if(!updateAccountList.isEmpty()){
                Database.SaveResult[] updateResults = Database.update(updateAccountList,false);
                // Separate successful and failed records
                system.debug('updateResults:'+updateResults);
                for(Integer i=0;i<updateResults.size();i++){
                    system.debug('updateResults[i].isSuccess():'+updateResults[i].isSuccess());
                    if(!updateResults[i].isSuccess())
                    {
                        for(Database.Error err : updateResults[i].getErrors()){
                            accountfailedRecords.add(updateAccountList[i]);
                            failedAccRecordsErrors.add(updateAccountList[i] +'-'+ err);
                            logList.add( getLog ('C360 batch Failure ', 'Account Upsert', err.getMessage(), err.getFields().toString()+'\nAccountId: '+updateResults[i].getId(), null, null) );
                        }
                    }
                    else{
                        successfulAccRecords.add(updateAccountList[i].Id);
                    }
                }
            }
            //Edit end: 14th, March 2024 - Mohamed - GTMS-18165
            //Edit end: 29th, June 2023
            //for log
            
            List<AggregateResult> agr = [SELECT Account__c,count(id) cnt  
                                         FROM Customer_360__c
                                         WHERE account__c in :accountIdsWithNewC360 group by account__c having count(id)>1];
            for (AggregateResult agrResult : agr)
            {
                String accId =(String)agrResult.get('Account__c');
                string exceptionMsg = Acct_LineItem_Combo.get(accId)+'#ExistingC360#'+acct_360Combo.get(accId)+'#upsertListOfC360#'+upsertlst;
                logList.add( getLog ('Customer360 already Exists for this account', 'Log', accId, exceptionMsg, null, null ));       
            }
        }
        catch(Exception ex){
            logList.add( getLog ('C360 batch Failure ', 'Error', ex.getMessage(), null, ex.getStackTraceString(), ex.getTypeName()) );
                
        } 
        finally 
        {
            if(logList.size()>0){
                insert logList;
            }
        }
        system.debug('successfulAccRecords:'+successfulAccRecords);
    }//end of execute method.
    //Edit on: 14th, March 2024 - Mohamed - GTMS-18165
    //Finish method to send failed records to the end users in custom label
    public void finish(Database.BatchableContext BC){
    }
    //Edit end: 14th, March 2024 - Mohamed - GTMS-18165
    public String ProcessProdCode (String ProCode){
        String FinalStr = '';
        String Prodcode = ProCode;
        String s1 = Prodcode.substringBefore ('-');
        system.debug('S1---> ' + s1);
        String s2 =  Prodcode.substringAfter ('-');
        system.debug('S2---> ' + s2);
        String s3 = s2.substringBefore ('-');
        system.debug('S3---> ' + s3);
        FinalStr = s1 + '-' + s3;
        system.debug('FinalS --->' + FinalStr);
        return FinalStr;
    }
    //Edit by: Govindaraju Boddu
    //Edit on: 5th, July 2023
    // GTMS-27500 : Added support for contains and endsWith methods in the mappings dynamically
    public String cmVgTierRegexMatcher(String productCode)
    {
        String tierVar = null;
        productCode = productCode.toLowerCase();
        
        for(String key : vgCmTierMap.keySet())
        {
                String methodName = key.split(',')[0];
                String argument = key.split(',')[1];
                
            if(methodName == 'contains')
            {
                if(productCode.contains(argument))
                {
                        tierVar = vgCmTierMap.get(key);
                        break;
                    }
        }
            else if(methodName == 'endsWith')
            {
                if(productCode.endsWith(argument))
                {
                        tierVar = vgCmTierMap.get(key);
                        break;
                    }
                }
        }
        return tierVar;
    }
    public static String pltfmPatternMatcher(String productCode)
    {
        if(Pattern.matches('.*PLTFM-PREM$',productCode))
        {
            return 'Premier';
        }
        if(Pattern.matches('.*PLTFM-ESS$',productCode))
        {
            return 'Essential';
        }
        return null;
    }
    //Edit end: 5th, July 2023
    public static Void getMetadataValues(){
        //Getting the Custom meta Values without SOQL using Getall.
        //This is introduced in Spring 21.
        Map<String,Opportunity_Product_Code__mdt> val =  Opportunity_Product_Code__mdt.getall();
        // Edit on Aug 21 2024 - Abu - GTMS-22195
        Map<String,OpptyProductCodeValueMap__mdt > oemVal = OpptyProductCodeValueMap__mdt.getAll();
        Set<String> c360UniqueFields = new Set<String>();
        // End: Edit on Aug 21 2024 - Abu - GTMS-22195
        system.debug('val--> ' + val);
        //Getting Values from Custom metadata.
        for(Opportunity_Product_Code__mdt OPC : val.values()){
            c360UniqueFields.add( OPC.Value__c );
            if(OPC.Is_Active__c){
                if(OPC.Is_Checked__c){
                    SkipProdCodeValues.put(OPC.Label, OPC.Is_Checked__c);
                }
                else{
                    ProdCodeValues.put(OPC.Name__c, OPC.Value__c);
                }
            }
        }
        // Edit on Aug 21 2024 - Abu - GTMS-22195
        for(OpptyProductCodeValueMap__mdt oemv: oemVal.values()){
            oemProductCodeValues.put(oemv.Label,oemv.Value__c);
        }
        // End: Edit on Aug 21 2024 - Abu - GTMS-22195

        for(String c360Field :c360UniqueFields )
        {
            if( c360Field.endsWith( '__c' ) )
            {
                c360DiscountNMUPFields += c360Field+', ';
            }
        }
    }//end of method.
    
    public void processHeaderFields(OpportunityLineItem oi, SObject Customer360_record, SObject accountRecord, Map<String,Decimal> SubProdQtyMap, Map<String,Decimal> OppProdQtyMap) {
        
        if(oi.ProductCode != null && (oi.ProductCode.contains('LIC-VG-') || oi.ProductCode.contains('LIC-CM-') )) {
            String cmVgTier = cmVgTierRegexMatcher(oi.ProductCode);
            System.debug('cmVgTier::'+cmVgTier);
            if(oi.ProductCode.contains('LIC-VG-') && (oi.product2.License_Type__c == 'Tier' || oi.product2.License_Type__c == 'FY26 Tier') && cmVgTier != null) {
                Customer360_record.put('VG_Tier__c',cmVgTier);
                accountRecord.put('VG_Tier__c',cmVgTier);
            }
            if((oi.ProductCode.contains('LIC-CM-S-') || oi.ProductCode.contains('LIC-CM-D-')) && (oi.product2.License_Type__c == 'Tier' || oi.product2.License_Type__c == 'FY26 Tier') && cmVgTier != null) {
                Customer360_record.put('CM_Tier__c',cmVgTier);
                accountRecord.put('CM_Tier__c',cmVgTier);
            }
            String platformTier = pltfmPatternMatcher(oi.ProductCode);
            if(platformTier != null) {
                Customer360_record.put('Platform_Type__c',platformTier);
                accountRecord.put('Platform_Type__c',platformTier);
            }
        }
        
        // GTMS-27500 : For First Purchase and Small Fleet Opportunity, populate P_P_Customer_Type__c as FY26 P&P
        if(oi.Opportunity.First_Purchase__c && oi.Opportunity.Small_Fleet_Opportunity__c && oi.Opportunity.CloseDate >= Date.valueOf(System.label.SmallFleetOppsFY26RolloutDate))
        {
          accountRecord.put('P_P_Customer_Type__c','FY26 P&P');
        }
    
        // GTMS-27500 : Populate P_P_Customer_Type__c based on License_Type__c from the Product
        if(String.isNotBlank(oi.product2.License_Type__c) && (oi.product2.License_Type__c == 'Tier' || oi.product2.License_Type__c == 'FY26 Tier')) {
            Customer360_record.put('P_P_Pilot_Customer__c',true);
            accountRecord.put('P_P_Pilot_Customer__c',true);
            accountRecord.put('P_P_Customer_Type__c',oi.product2.License_Type__c == 'Tier' ? 'FY25 P&P' : 'FY26 P&P');
        }
        
        //Edit on: 4th, June 2024 - Mohamed - GTMS-21331
        if(oi.ProductCode != null && oi.ProductCode.contains(System.label.LIC_AT_TAG) ){
            accountRecord.put('LIC_AT_TAG__c',true);
            Customer360_record.put('LIC_AT_TAG__c',true);
        }
        // Edit on Aug 21 2024 - Abu - GTMS-22195

        System.debug('******oi.ProductCode******: '+oi.ProductCode);
        if(oi.ProductCode != null && oemProductCodeValues.containsKey(oi.ProductCode))
        {
            accountRecord.put(oemProductCodeValues.get(oi.ProductCode),true);
        }
        //Edit end: 1st, July 2024 - Mohamed - GTMS-22195
        
        //Edit on: 11th, Dec 2024 - Abu - GTMS-23015
        if(ProProdMap.containsKey(oi.ProductCode) && ProProdMap.get(oi.ProductCode)!=null){
            if(SubProdQtyMap.containsKey(oi.Account__c+'-'+oi.ProductCode) && SubProdQtyMap.get(oi.Account__c+'-'+oi.ProductCode)!= null){
                decimal Subqty = SubProdQtyMap.get(oi.Account__c+'-'+oi.ProductCode);
                accountRecord.put(ProProdMap.get(oi.ProductCode), Subqty >0 ? true : false);
                Customer360_record.put(ProProdMap.get(oi.ProductCode), Subqty >0 ? true : false);
            }
            else{
                decimal Oppqty = OppProdQtyMap.get(oi.Account__c+'-'+oi.ProductCode);
                accountRecord.put(ProProdMap.get(oi.ProductCode), Oppqty>0 ? true : false);
                Customer360_record.put(ProProdMap.get(oi.ProductCode),Oppqty >0 ? true : false);
            }
        }
        //Edit end: Govindaraju Boddu (1st, February 2024)
        //Edit end: 14th, March 2024 - Mohamed - GTMS-18165
        if(SkipProdCodeValues.containsKey(oi.ProductCode)){
            Customer360_record.put('VG54_purchased__c' , True);
        }
        //Added on: 09th, Jun 2025 - Venkatesh - GTMS-25530
        if(oi.ProductCode != null && oi.ProductCode.contains(System.label.HW_SP11) ){
            Customer360_record.put('HW_SP11__c',true);
        }
        if(setVGBasicProductCodes != null && setVGBasicProductCodes.contains(oi.ProductCode))
            Customer360_record.put('VG_Basic_Purchased__c' , True);
        //GTMS-11706
        if(setVGENTProductCodes != null && setVGENTProductCodes.contains(oi.ProductCode))
            Customer360_record.put('VG_ENT_Purchased__c' , True);
    }

    @testVisible private Log__c getLog(String msg, String logLevel, String errorMsg, String exceptionMsg, string stackTrace, string type)
    {

        string defaultException = '\nAccount: '+currentAccount+'\nOpportunityLineItem: '+currentOppLine;

        Log__c logRec = new Log__c();

        logRec.Message__c = msg;
        logRec.ClassName__c = 'OpptyLineitemDiscountBatch';
        logRec.LogLevel__c = logLevel;
        logRec.Error_Message__c = ( errorMsg + defaultException ).length() > 255 ? ( errorMsg + defaultException ).substring( 0, 255 ) : ( errorMsg + defaultException );
        logRec.ExceptionMessage__c = exceptionMsg;
        logRec.StackTrace__c = stackTrace.length() > 255 ? stackTrace.substring( 0, 255 ) : stackTrace;
        logRec.Type__c = type;

        return logRec;
    }
}//end of class.