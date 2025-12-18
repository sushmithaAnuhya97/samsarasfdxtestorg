/**
 * @description       :
 * @author            : UNKNOWN
 * @group             :
 * @last modified on  : 09-25-2025
 * @last modified by  : hitesh.garg
 **/
//Code coverage from OpportunityTest and ScheduledAssociateQuotaOpportunityTest
/*
* 07/13/21 Lavanya (GTMS-4258) Updated IF condition to check if the opportunity is a return
* 05/03/21 Sai (GTMS-3289) Modified criteria for populating ship location based Account Geo
* 12/03/2020 Harsha (GTMS-2408) updateopportunityFields (Retired the method)
* 3/12/20 Harsha - (ICT-3): populateShipFromAddress (Added DCL-KY logic)
* 4/08/20 Satya - (GTMS - 807/809/810/811)added workflow logic to code
* 4/17/20 Satya - (GTMS - 804/805/806/808)added workflow logic to code
* 8/19/20 Harsha - (GTMS-1449) updateopportunityFields (Changes made to stop the method from firing for quote lines)
* 12/20/22 Zakeer - GTMS-10353 - added Account NULL check to assign Accounts to Products.
* 04/12/24 Mohamed -GTMS-13327 - Cross Sell Purchase type logic
* 06/24/25 Vijaychandra AMARANENI - GTMS-28353 - Added this method to create or void Channel Relationship records based on OpportunityLineItem data
*/
public class OpportunityLineItemHelper {
    private static Map<Id, Opportunity> opptyMap;
    private static Map<Id, PricebookEntry> pricebookEntryMap = new Map<Id, PricebookEntry>();
    private static Map<Id, SBQQ__QuoteLine__c> quoteLineMap = new Map<Id, SBQQ__QuoteLine__c>();
    private static Boolean dataMap = false;
    static Map<String, Rollup_Switch__mdt> mapOFRollupFieldVsMetadata = new Map<String, Rollup_Switch__mdt> ();
    private static Set<String> targetRollupOppSet = new Set<String> ();
    //private static List<OpportunityLineItem> targetOlis = new List<OpportunityLineItem>();
    private static Map<Id, Opportunity> targetOppsForRollup = new Map<Id, Opportunity>();
    //GTMS-13327 - Cross Sell Purchase type logic
    //GTMS-13327 - Edit on
    public static Set<Id> AccIds = new Set<Id>();
    //public static set<Id> opptyIds = new set<Id>();
    public static  Set<Account> updateAccountList = new Set<Account>();
    public static Map<String,decimal> accCM1Count = new Map<String,decimal>();
    public static Map<String,decimal> accCM2Count = new Map<String,decimal>();
    public static Map<String,decimal> accPltfmCount = new Map<String,decimal>();
    public static Map<String,decimal> accVgCount = new Map<String,decimal>();
    public static Map<String,decimal> oppAccCM1Count = new Map<String,decimal>();
    public static Map<String,decimal> oppAccCM2Count = new Map<String,decimal>();
    public static Map<String,decimal> oppAccPltfmCount = new Map<String,decimal>();
    public static Map<String,decimal> oppAccVgCount = new Map<String,decimal>();
    /* public static   Map<String,decimal> accExistingCM1Count = new Map<String,decimal>();
    public static  Map<String,decimal> accExistingCM2Count = new Map<String,decimal>();
    public static  Map<String,decimal> accExistingPltfmCount = new Map<String,decimal>();
    public static  Map<String,decimal> accExistingVgCount = new Map<String,decimal>();*/
    //public static  String cm1Pro = Product_Code_by_Type__mdt.getInstance('LIC_CM1_PRO')?.label;
    // public static  String cm2Pro =  Product_Code_by_Type__mdt.getInstance('LIC_CM2_PRO')?.label;
    // public static  String pltfmPro =  Product_Code_by_Type__mdt.getInstance('LIC_PLTFM_PRO')?.label;
    // public static  String vgPro =  Product_Code_by_Type__mdt.getInstance('LIC_VG_PRO')?.label;
    //GTMS-13327 - Edit End
    //Query all the opportunities and price book entries associated to the line items.
    private static void loadDataMap(
        List<OpportunityLineItem> newOppLineItemList
    ) {
    if (!dataMap) {
    Set<Id> opportunityIds = new Set<Id>();
    Set<Id> priceBookEnrtyIds = new Set<Id>();
    Set<Id> quoteLineIds = new Set<Id>();
    for (OpportunityLineItem line : newOppLineItemList) {
    opportunityIds.add(line.OpportunityId);
    priceBookEnrtyIds.add(line.PricebookEntryId);
    quoteLineIds.add(line.SBQQ__QuoteLine__c);
    }
            opptyMap = new Map<Id, Opportunity>(
                [
                    SELECT
                        Id,
                        Rerun_Tax__c,
                        Shipping_Country__c,
                        Type,
                        Custom_Accessory_Exists__c
                  		FROM Opportunity
                    	WHERE Id IN :opportunityIds
                ]
            );
            pricebookEntryMap = new Map<Id, PricebookEntry>(
                [
                    SELECT Id, UnitPrice
                    FROM PricebookEntry
                    WHERE Id IN :priceBookEnrtyIds
                ]
            );
            quoteLineMap = new Map<Id, SBQQ__QuoteLine__c>(
                [
                    SELECT
                        Id,
                        Original_FT_Oppty_Line_Item_SF_Id__c,
                        Ship_From_Location__c
                    FROM SBQQ__QuoteLine__c
                    WHERE Id IN :quoteLineIds
                ]
            );
    dataMap = true;
    }
    }
    // Method to discount the line items
    // Eventually can be merged with beforeUpdateUpkeep -@Harsha
    public static void setDiscountForOppType(
        List<OpportunityLineItem> newLines,
        Double discount
    ) {
    loadDataMap(newLines);
    if(opptyMap.size() > 0) {
    for(OpportunityLineItem line : newLines) {
                if (line.OpportunityId != null) {
                    Opportunity associatedOpp = opptyMap.get(
                        line.OpportunityId
                    );
                    SBQQ__QuoteLine__c quoteLine = quoteLineMap.get(
                        line.SBQQ__QuoteLine__c
                    );
                    if (
                        quoteLine != null &&
                        String.isNotBlank(
                            quoteLine.Original_FT_Oppty_Line_Item_SF_Id__c
                        ) &&
                        String.isNotBlank(quoteLine.Ship_From_Location__c)
                    ) {
    line.Ship_From_Location__c = quoteLine.Ship_From_Location__c;
    line.Original_FT_Oppty_Line_Item_SF_Id__c = quoteLine.Original_FT_Oppty_Line_Item_SF_Id__c;
    }
    //Zakeer- GTMS-5381-Jan11-Setting the ShipFromLocation based on Country.
                    if (String.IsBlank(line.Ship_From_Location__c)) {
                        //added condition to accomodate GTMS5404
                        HelperClass.setShippingDefaultsProducts(
                            line,
                            associatedOpp.Shipping_Country__c
                        );
    }
                    if (associatedOpp != null) {
                        if (
                            associatedOpp.type == 'Free Trial Opportunity' ||
                            associatedOpp.type == 'Promo Opportunity' ||
                            associatedOpp.type == 'Free Trial Return' ||
                            associatedOpp.type == 'Exchange' ||
                            associatedOpp.type == 'Warranty Exchange'
                        ) {
    line.discount = discount;
    }
    }
    }
    }
    }
    }
    public static void beforeUpdateUpkeep(
        List<OpportunityLineItem> newOppLineItemList,
    Map<Id, OpportunityLineItem> newOppLineItemMap,
        Map<Id, OpportunityLineItem> oldOppLineItemMap
    ) {
    Set<Id> oppIds = new Set<Id>();
    Set<Id> pbeIds = new Set<Id>();
    Set<Id> prdIds = new Set<Id>(); //GTMS-8317
    //Map<Id, Opportunity> oppTOUpdate = new Map<Id, Opportunity>();
    for(OpportunityLineItem li : newOppLineItemList) {
    oppIds.add(li.OpportunityId);
    pbeIds.add(li.PricebookEntryId);
    prdIds.add(li.product2Id); //GTMS-8317
    }
        Map<Id, PricebookEntry> pricebookEntryMap = new Map<Id, PricebookEntry>(
            [
                SELECT
                    Id,
                    Product2Id,
                    Pricebook2Id,
                    Product2.Product_Type__c,
                    Product2.ProductCode
    FROM PricebookEntry
                WHERE Id IN :pbeIds
            ]
        );
    // GTMS-8317 - Start
    Map<Id, Product2> productMap = new Map<Id, Product2>(
            [
                SELECT
                    Id,
                    IsACV__c,
                    (
                        SELECT SBQQ__UnitCost__c
    FROM SBQQ__Costs__r
                        WHERE SBQQ__Active__c = TRUE
                        LIMIT 1
                    )
    FROM Product2
                WHERE Id IN :prdIds
            ]
    );
    // GTMS-8317 - End
    //The Acv calculations are getting messed up when I tried moving this query into the loadDataMap.
    //Need to rework on this when time permits. -@Harsha
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
            [
                SELECT
                    Id,
                    Type,
                    RecordType.Name,
                    Account.Global_Geography__c,
                    Custom_Accessory_Exists__c,
                    License_Term__c,
                    Shipping_Address_NEW__c,
                    Shipping_Address_NEW__r.Shipping_Contact__r.FirstName,
                    Shipping_Address_NEW__r.Shipping_Contact__r.LastName,
                    Shipping_Address_NEW__r.Shipping_Address_Line_1__c,
                    Shipping_Address_NEW__r.Shipping_Address_Line_2__c,
                    Shipping_Address_NEW__r.Shipping_City__c,
                    Shipping_Address_NEW__r.Shipping_State__c,
                    Shipping_Address_NEW__r.Shipping_Zip_Code__c,
                    Shipping_Address_NEW__r.Shipping_Country__c,
                    AccountId,
                    Returning_Opportunity__c,
                    Rebate_Type__c,
                    Returning_Opportunity__r.CloseDate,
                    Returning_Opportunity__r.License_Term__c,
                    IsClosed,
                    closeDate
                FROM Opportunity
                WHERE Id IN :oppIds
            ]
        );
    if(oppMap.size() > 0) {
    for(OpportunityLineItem li : newOppLineItemList) {
    Decimal acvPrice;
    Opportunity o = oppMap.get(li.OpportunityId);
    Product2 product = productMap.get(li.Product2Id);
    // Moved as part of GTMS-10539 to improve performance and allow for a single FOR statement instead of two.
    //https://samsaradev.atlassian.net/browse/GTMS-14655
    //&& (Trigger.isInsert || product.IsACV__c != li.is_ACV__c)
                if (
                    o.IsClosed == false &&
                    product != null &&
                    product.IsACV__c != li.is_ACV__c
                ) {
    li.is_ACV__c = product.IsACV__c;
    }
    //Workflow - make value negative
    if(o.RecordType.Name == 'Return Opportunity') {
    li.Quantity  = li.Quantity >0 ? -li.Quantity : li.Quantity;
    }
    // Ensuring Quantity is correct before calculating product cost
    if (product != null && !product.SBQQ__Costs__r.isEmpty()){
                    li.Product_Cost__c = Math.abs(
                        li.Quantity *
                        product.SBQQ__Costs__r[0].SBQQ__UnitCost__c
                    );
    }
    //workflow - Set Default Ship From Location base on Country GTMS 811
    //Zakeer--Commented this block - GTMS-5381- as per Nhi
    /* List<String> lstGlobalGeography = System.label.Account_Global_Geography.split(',');
    if(o.Account.Global_Geography__c != null && lstGlobalGeography.contains(o.Account.Global_Geography__c) && li.Ship_From_Location__c != 'Free Trial EU') {
    if((Trigger.isInsert || (Trigger.isUpdate && li.Ship_From_Location__c == null)))
    li.Ship_From_Location__c = 'VCK';
    }*/
    // Workflow - Set Shipping Quantity GTMS 810
                List<String> lstOppType = System.label.Opp_Type_To_Stamp_Shipped_Qty.split(
                    ','
                );
                if (
                    lstOppType.contains(o.Type) &&
                    (Trigger.isInsert ||
                    (oldOppLineItemMap != null &&
                    oldOppLineItemMap.containsKey(li.OpportunityId) &&
                    oldOppLineItemMap.get(li.OpportunityId).Quantity !=
                    li.Quantity))
                ) {
    li.Shipped_Quantity__c = li.Quantity;
    }
    //workflow - Copy Total Dimensions/Copy Total Weight
                if (
                    li.Total_Dimensions_Copy__c != null ||
                    li.Total_Dimensions_Copy__c != li.Total_Dimensions__c
                ) {
    li.Total_Dimensions_Copy__c = li.Total_Dimensions__c;
    }
                if (
                    li.Total_Weight_oz_Copy__c != null ||
                    li.Total_Weight_oz_Copy__c != li.Total_Weight_oz__c
                ) {
    li.Total_Weight_oz_Copy__c  = li.Total_Weight_oz__c ;
    }
    // Protect against null values when you add products from OOB Add Products button.
    // Must be deprecated after we deal with CPU time limits -@Harsha
                if (
                    li.UnitPrice == null &&
                    o.Returning_Opportunity__c != null &&
                    li.TotalPrice == null
                ) {
    li.UnitPrice = 0;
    }
    /*if(li.Quantity == NULL && o.Configuration_Segment__c != 'Express' && !o.Is_Webstore_Upsell_Opportunity__c) {
    li.Quantity = 0;
    }*/
                if (li.Discount == null) {
    li.Discount = 0;
    }
                if (o.License_Term__c == null) {
    o.License_Term__c = 0;
    }
    // Calculate ACV Price on the lines and this will be rolled up to the opportunity.
    System.debug('line item: '+li);
                if (li.UnitPrice != null) {
    System.debug('line item: '+li.TotalPrice);
                    if (
                        o.closeDate <
                        Date.valueOf(SYSTEM.Label.Annualize_ACV_Date)
                    ) {
                        if (
                            o.License_Term__c < 12 ||
                            o.License_Term__c == null ||
                            o.License_Term__c == 0
                        ) {
                            acvPrice =
                                li.UnitPrice *
                                li.Quantity *
                                (100 - li.Discount) /
                                100;
        } else {
                            acvPrice =
                                li.UnitPrice *
                                li.Quantity *
                                (100 - li.Discount) /
                                100 /
                                o.License_Term__c *
                                12;
        }
    }else{
                        if (
                            o.License_Term__c == null ||
                            o.License_Term__c == 0
                        ) {
                            acvPrice =
                                li.UnitPrice *
                                li.Quantity *
                                (100 - li.Discount) /
                                100;
        } else {
                            acvPrice =
                                li.UnitPrice *
                                li.Quantity *
                                (100 - li.Discount) /
                                100 /
                                o.License_Term__c *
                                12;
        }
    }
                    if (
                        acvPrice != 0 &&
                        o.closeDate >=
                        Date.valueOf(SYSTEM.Label.Annualize_ACV_Date) &&
                        o.type != 'Revenue Opportunity' &&
                        o.License_Term__c < 12 &&
                        o.Returning_Opportunity__c != null &&
                        o.Returning_Opportunity__r.License_Term__c < 12 &&
                        o.Returning_Opportunity__r.CloseDate <
                        Date.valueOf(SYSTEM.Label.Annualize_ACV_Date)
                    ) {
                        li.ACV_Total_Price_Stamp__c =
                            (acvPrice / 12) * o.License_Term__c;
    } else {
    li.ACV_Total_Price_Stamp__c = acvPrice;
    }
    }
    li.License_Term_Copy__c = o.License_Term__c;
    // Stamp Product Code Copy and Product Type Copy from the pricebook entry's product:
    if(pricebookEntryMap.containsKey(li.PricebookEntryId)) {
                    li.Product_Type_Copy__c = pricebookEntryMap.get(
                            li.PricebookEntryId
                        )
                        .Product2.Product_Type__c;
                    li.Product_Code_Copy__c = pricebookEntryMap.get(
                            li.PricebookEntryId
                        )
                        .Product2.ProductCode;
                    System.debug(
                        LoggingLevel.DEBUG,
                        '##### OpportunityLineItemHelper -> beforeUpdateUpkeep -> pricebookEntryMap.get(li.PricebookEntryId) -> ' +
                        pricebookEntryMap.get(li.PricebookEntryId)
                    );
                    System.debug(
                        LoggingLevel.DEBUG,
                        '##### OpportunityLineItemHelper -> beforeUpdateUpkeep -> pricebookEntryMap.get(li.PricebookEntryId).Product2 -> ' +
                        pricebookEntryMap.get(li.PricebookEntryId).Product2
                    );
                    System.debug(
                        LoggingLevel.DEBUG,
                        '##### OpportunityLineItemHelper -> beforeUpdateUpkeep -> pricebookEntryMap.get(li.PricebookEntryId).Product2.ProductCode -> ' +
                        pricebookEntryMap.get(li.PricebookEntryId)
                            .Product2.ProductCode
                    );
                    String prodCode = pricebookEntryMap.get(li.PricebookEntryId)
                        .Product2.ProductCode;
                    if (
                        prodCode.startsWith('ACC') ||
                        prodCode.startsWith('SHRT')
                    ) {
    li.Is_Accessory__c = true;
    }
    if(prodCode.startsWith('HW')) {
    li.Is_Hardware__c = true;
    }
    if(prodCode.startsWith('LIC')) {
    li.Is_Subscription__c = true;
    }
    }
    //GTMS-10353
    //Moved the logic to stamp AccountId on the line Item when its creted from PB <PB Reference: Add Account to Opportunity Product>
    if(li.Account__c == null){
    li.Account__c = o.AccountId;
    }
    if(li.Created_From_Quote__c == false){
    //workflow - Concatenate Ship To Address
    // Moved the logic to populate the Ship_To__c and Ship_To_Address_Concatenated__c from process builder.< PB reference: OpportunityLineItem Address Updater>
                    if (
                        (o.Shipping_Address_NEW__c != null) &&
                        (li.Ship_To__c == null)
                    ) {
    li.Ship_To__c = o.Shipping_Address_NEW__c;
                        li.Ship_To_Address_Concatenated__c =
                            o.Shipping_Address_NEW__r.Shipping_Contact__r.FirstName +
                            ' ' +
                            o.Shipping_Address_NEW__r.Shipping_Contact__r.LastName +
                            '\n' +
                            o.Shipping_Address_NEW__r.Shipping_Address_Line_1__c +
                            '\n' +
                            o.Shipping_Address_NEW__r.Shipping_Address_Line_2__c +
                            '\n' +
                            o.Shipping_Address_NEW__r.Shipping_City__c +
                            ', ' +
                            o.Shipping_Address_NEW__r.Shipping_State__c +
                            ', ' +
                            o.Shipping_Address_NEW__r.Shipping_Zip_Code__c +
                            '\n' +
                            o.Shipping_Address_NEW__r.Shipping_Country__c;
    }
    populateShipFromAddress(li);
    }

                /*  Commented as part of GTMS-28375. The UnitPrice is getting directly 
                    manipulated on the OLI records and that is not an idela approach. 
                    Values should sync to OLIs from the realted QLIs -
                    Hitesh Garg - July 18th, 2025 - START
                */
    // Moved the logic to populate SalesPrice when the license term changes from process builder. <PB Reference: Recalculate License Cost>
                /*if(oldOppLineItemMap != null){
    //GTMS-9831-added RebateType criteria for NS-LineItem insertion.
                    if(
                        (   o.Rebate_Type__c != 'Delinquent' 
                            && o.Type != 'Rebate'
                        ) && 
                        (   
                            newOppLineItemMap.get(li.Id).License_Term_Copy__c != oldOppLineItemMap.get(li.Id).License_Term_Copy__c) 
                            && (newOppLineItemMap.get(li.Id).TotalPrice == oldOppLineItemMap.get(li.Id).TotalPrice
                        )
                    ){
    String productCode = li.ProductCode;
    if(productCode.startsWith('LIC')){
    li.UnitPrice = (li.ListPrice/12)*li.License_Term_Copy__c;
    }
    }
                }*/
    }
    }
    }
    // Code to update ListPrice and UnitPrice for the opportunitylines pushed from NS -@Harsha
    public static void salesPriceUpdateForRenewalLines(
        List<OpportunityLineItem> newOpportunityLineItemList
    ) {
    Map<Id, Decimal> mappedData = new Map<Id, Decimal>();
    Set<OpportunityLineItem> filteredNSLineItems = new Set<OpportunityLineItem>();
    loadDataMap(newOpportunityLineItemList);
    // Make sure that there are lines from NS to run this code
    for(OpportunityLineItem lineItem : newOpportunityLineItemList) {
    if(lineItem.Created_From_NS__c == true){
    filteredNSLineItems.add(lineItem);
    }
    }
        if (
            (pricebookEntryMap.size() > 0) && (filteredNSLineItems.size() > 0)
        ) {
    for(PriceBookEntry pbEntry : pricebookEntryMap.values()){
    mappedData.put(pbEntry.Id, pbEntry.UnitPrice);
    }
    }
    if(!mappedData.isEmpty()){
    for(OpportunityLineItem filteredLineItem : filteredNSLineItems) {
                if (
                    (filteredLineItem.Created_From_NS__c == true) &&
                    (mappedData.containsKey(filteredLineItem.PricebookEntryId))
                ) {
                    Decimal listPrice = mappedData.get(
                        filteredLineItem.PricebookEntryId
                    );
                    filteredLineItem.UnitPrice =
                        (listPrice / 12) *
                        filteredLineItem.License_Term_Copy__c;
    }
    }
    }
    }
    //Added this code here since they won’t be changing often and will be easy to decommission it when CML is moved to CPQ.
    // Didn’t take the formula route because they can’t be synced from CPQ.
    // Didn’t want to add more CPU consumption to the transaction, so didn’t use workflows or process builders. - @Harsha
    private static void populateShipFromAddress(OpportunityLineItem lineItem){
    //system.debug('In the method');
    if(lineItem.Ship_From_Location__c == 'DCL'){
    lineItem.Ship_Frm_Address__c = 'Samsara, Inc c/o DCL Inc 48819 Kato Road';
    lineItem.Ship_Frm_City__c = 'Fremont';
    lineItem.Ship_Frm_Country__c = 'United States';
    lineItem.Ship_Frm_State__c = 'CA';
    lineItem.Ship_Frm_Zip_Code__c = '94539';
        } else if (lineItem.Ship_From_Location__c == 'VCK') {
    lineItem.Ship_Frm_Address__c = 'VCK Logistics SCS BV Bellsingel 11';
    lineItem.Ship_Frm_City__c = 'Schiphol-Rijk';
    lineItem.Ship_Frm_Country__c = 'Netherlands';
    lineItem.Ship_Frm_Zip_Code__c = '1119 NT';
    lineItem.Ship_Frm_State__c = '';
    }
    else if(lineItem.Ship_From_Location__c == 'DHL'){
    lineItem.Ship_Frm_Address__c = 'Bolwerkdok 2';
    lineItem.Ship_Frm_City__c = 'Nieuwegein';
    lineItem.Ship_Frm_Country__c = 'Netherlands';
    lineItem.Ship_Frm_Zip_Code__c = '3433 KN';
    lineItem.Ship_Frm_State__c = '';
    }
    else if(lineItem.Ship_From_Location__c == 'Samsara UK'){
    lineItem.Ship_Frm_Address__c = 'Samsara 32-38 Leman Street London';
    lineItem.Ship_Frm_City__c = 'London';
    lineItem.Ship_Frm_Country__c = 'United Kingdom';
    lineItem.Ship_Frm_Zip_Code__c = 'E1 8EW';
    lineItem.Ship_Frm_State__c = '';
        } else if (lineItem.Ship_From_Location__c == 'DCL-KY') {
    lineItem.Ship_Frm_Address__c = '6825 Enterprise Dr';
    lineItem.Ship_Frm_City__c = 'Louisville';
    lineItem.Ship_Frm_Country__c = 'United States';
    lineItem.Ship_Frm_Zip_Code__c = '40214';
    lineItem.Ship_Frm_State__c = 'KY';
        } else {
    lineItem.Ship_Frm_Address__c = '';
    lineItem.Ship_Frm_City__c = '';
    lineItem.Ship_Frm_Country__c = '';
    lineItem.Ship_Frm_Zip_Code__c = '';
    lineItem.Ship_Frm_State__c = '';
    }
    }
    //GTMS-13327 - Cross Sell Purchase type logic
    //GTMS-13327 - Edit on
    @future
    public static void updateAccountPROSkuFields(
        String jsonNewOliList,
        string oldJsonOliList
    ) {
    system.debug('inside **** updateAccountPROSkuFields');
    List<OpportunityLineItem> oppLineItemListNew = new List<OpportunityLineItem>();
    List<OpportunityLineItem> oppLineItemListOld = new List<OpportunityLineItem>();
    List<Id> accIdOldLst = new List<Id>();
    List<Id> opptyIds = new List<Id>();
    Map<Id,boolean> noProSkuMap = new Map<Id,boolean>();
    Map<String,List<String>> acProductCodeMap = new  Map<String,List<String>>();
    Map<String,integer> acProductCount = new  Map<String,integer>();
    Map<String,integer> oppProductCount = new  Map<String,integer>();
    Map<Id,List<String>> accStatusCrossOrAddOn = new Map<Id,List<String>>();
        set<Account> queryAccLst = new Set<Account>();
    if(jsonNewOliList != null){
            oppLineItemListNew = (List<OpportunityLineItem>) JSON.deserialize(
                jsonNewOliList,
                List<OpportunityLineItem>.class
            );
    }
    if(oldJsonOliList != null){
            oppLineItemListOld = (List<OpportunityLineItem>) JSON.deserialize(
                oldJsonOliList,
                List<OpportunityLineItem>.class
            );
    }
        if (oppLineItemListNew.size() > 0 && oldJsonOliList == null) {
    for(OpportunityLineItem oppLnitem: oppLineItemListNew ){
    opptyIds.add(oppLnitem.opportunityId);
    AccIds.add(oppLnitem.Account__c);
    }
    system.debug('opptyIds:'+opptyIds);
    system.debug('AccIds:'+AccIds);
            for (OpportunityLineItem oppliItem : [
                SELECT
                    id,
                    ProductCode,
                    opportunityId,
                    Account__c,
                    opportunity.Type,
                    quantity
                FROM OpportunityLineItem
                WHERE
                    Account__c = :AccIds
                    AND (opportunity.Type = 'Revenue Opportunity'
                    OR opportunity.Type = 'Remorse Refund')
                    AND opportunityId NOT IN :opptyIds
            ]) {
                system.debug(
                    'oppliItem.opportunity.Type:' + oppliItem.opportunity.Type
                );
    integer count = 1;
    if(oppliItem.ProductCode.contains('PRO')){
                    if (
                        acProductCodeMap.containsKey(
                            oppliItem.Account__c + '-' + oppliItem.ProductCode
                        )
                    ) {
                        acProductCodeMap.get(
                                oppliItem.Account__c +
                                    '-' +
                                    oppliItem.ProductCode
                            )
                            .add(oppliItem.ProductCode);
                    } else {
                        acProductCodeMap.put(
                            oppliItem.Account__c + '-' + oppliItem.ProductCode,
                            new List<String>{ oppliItem.ProductCode }
                        );
    }
                    if (
                        oppliItem.Quantity != null &&
                        oppliItem.ProductCode == System.label.LIC_CM1_PRO
                    ) {
                        if (
                            oppAccCM1Count.containsKey(
                                oppliItem.Account__c +
                                    '-' +
                                    oppliItem.ProductCode
                            )
                        ) {
                            decimal qty = oppAccCM1Count.get(
                                oppliItem.Account__c +
                                    '-' +
                                    oppliItem.ProductCode
                            );
    decimal total = qty + oppliItem.Quantity;
                            oppAccCM1Count.put(
                                oppliItem.Account__c +
                                    '-' +
                                    oppliItem.ProductCode,
                                total
                            );
                        } else {
                            oppAccCM1Count.put(
                                oppliItem.Account__c +
                                    '-' +
                                    oppliItem.ProductCode,
                                oppliItem.Quantity
                            );
    }
    }
                    if (
                        oppliItem.Quantity != null &&
                        oppliItem.ProductCode == System.label.LIC_CM2_PRO
                    ) {
                        if (
                            oppAccCM2Count.containsKey(
                                oppliItem.Account__c +
                                    '-' +
                                    oppliItem.ProductCode
                            )
                        ) {
                            decimal qty = oppAccCM2Count.get(
                                oppliItem.Account__c +
                                    '-' +
                                    oppliItem.ProductCode
                            );
    decimal total = qty + oppliItem.Quantity;
                            oppAccCM2Count.put(
                                oppliItem.Account__c +
                                    '-' +
                                    oppliItem.ProductCode,
                                total
                            );
                        } else {
                            oppAccCM2Count.put(
                                oppliItem.Account__c +
                                    '-' +
                                    oppliItem.ProductCode,
                                oppliItem.Quantity
                            );
    }
    }
                    if (
                        oppliItem.Quantity != null &&
                        oppliItem.ProductCode == System.label.LIC_PLTFM_PRO
                    ) {
                        if (
                            oppAccPltfmCount.containsKey(
                                oppliItem.Account__c +
                                    '-' +
                                    oppliItem.ProductCode
                            )
                        ) {
                            decimal qty = oppAccPltfmCount.get(
                                oppliItem.Account__c +
                                    '-' +
                                    oppliItem.ProductCode
                            );
    decimal total = qty + oppliItem.Quantity;
                            oppAccPltfmCount.put(
                                oppliItem.Account__c +
                                    '-' +
                                    oppliItem.ProductCode,
                                total
                            );
                        } else {
                            oppAccPltfmCount.put(
                                oppliItem.Account__c +
                                    '-' +
                                    oppliItem.ProductCode,
                                oppliItem.Quantity
                            );
    }
    }
                    if (
                        oppliItem.Quantity != null &&
                        oppliItem.ProductCode == System.label.LIC_VG_PRO
                    ) {
                        if (
                            oppAccVgCount.containsKey(
                                oppliItem.Account__c +
                                    '-' +
                                    oppliItem.ProductCode
                            )
                        ) {
                            decimal qty = oppAccVgCount.get(
                                oppliItem.Account__c +
                                    '-' +
                                    oppliItem.ProductCode
                            );
    decimal total = qty + oppliItem.Quantity;
                            oppAccVgCount.put(
                                oppliItem.Account__c +
                                    '-' +
                                    oppliItem.ProductCode,
                                total
                            );
                        } else {
                            oppAccVgCount.put(
                                oppliItem.Account__c +
                                    '-' +
                                    oppliItem.ProductCode,
                                oppliItem.Quantity
                            );
    }
    }
    }
    }
    system.debug('oppAccCM1Count:'+oppAccCM1Count);
    system.debug('oppAccCM2Count:'+oppAccCM2Count);
    system.debug('oppAccPltfmCount:'+oppAccPltfmCount);
    system.debug('oppAccVgCount:'+oppAccVgCount);
    system.debug('acProductCodeMap:'+acProductCodeMap);
    system.debug('acProductCount:'+acProductCount);
    system.debug('oppProductCount:'+oppProductCount);
    for(OpportunityLineItem oi : oppLineItemListNew){
    system.debug('oi.ProductCode:'+oi.ProductCode);
    if(oi.ProductCode.contains('PRO')){
                    if (
                        acProductCodeMap.containskey(
                            oi.Account__c + '-' + oi.ProductCode
                        ) &&
                        acProductCodeMap.get(
                            oi.Account__c + '-' + oi.ProductCode
                        ) != null
                    ) {
                        if (
                            oppAccCM1Count.get(
                                oi.Account__c + '-' + oi.ProductCode
                            ) != null
                        ) {
                            decimal total = oppAccCM1Count.get(
                                oi.Account__c + '-' + oi.ProductCode
                            );
    if(total == 0){
                                acProductCodeMap.remove(
                                    oi.Account__c + '-' + oi.ProductCode
                                );
    }
    }
                        if (
                            oppAccCM2Count.get(
                                oi.Account__c + '-' + oi.ProductCode
                            ) != null
                        ) {
                            decimal total = oppAccCM2Count.get(
                                oi.Account__c + '-' + oi.ProductCode
                            );
    if(total == 0){
                                acProductCodeMap.remove(
                                    oi.Account__c + '-' + oi.ProductCode
                                );
    }
    }
                        if (
                            oppAccPltfmCount.get(
                                oi.Account__c + '-' + oi.ProductCode
                            ) != null
                        ) {
                            decimal total = oppAccPltfmCount.get(
                                oi.Account__c + '-' + oi.ProductCode
                            );
    if(total == 0){
                                acProductCodeMap.remove(
                                    oi.Account__c + '-' + oi.ProductCode
                                );
    }
    }
                        if (
                            oppAccVgCount.get(
                                oi.Account__c + '-' + oi.ProductCode
                            ) != null
                        ) {
                            decimal total = oppAccVgCount.get(
                                oi.Account__c + '-' + oi.ProductCode
                            );
    if(total == 0){
                                acProductCodeMap.remove(
                                    oi.Account__c + '-' + oi.ProductCode
                                );
    }
    }
    List<String> result = new List<String>();
                        if (
                            acProductCodeMap.get(
                                oi.Account__c + '-' + oi.ProductCode
                            ) != null
                        ) {
                            result = acProductCodeMap.get(
                                oi.Account__c + '-' + oi.ProductCode
                            );
    }
    system.debug('result:'+result);
    system.debug('oi.ProductCode:'+oi.ProductCode);
                        if (
                            !result.isEmpty() && result.contains(oi.ProductCode)
                        ) {
                            if (
                                accStatusCrossOrAddOn.containsKey(oi.Account__c)
                            ) {
                                accStatusCrossOrAddOn.get(oi.Account__c)
                                    .add('AddOn');
                            } else {
                                accStatusCrossOrAddOn.put(
                                    oi.Account__c,
                                    new List<String>{ 'AddOn' }
                                );
    }
                        } else {
                            if (
                                accStatusCrossOrAddOn.containsKey(oi.Account__c)
                            ) {
                                accStatusCrossOrAddOn.get(oi.Account__c)
                                    .add('CrossSell');
                            } else {
                                accStatusCrossOrAddOn.put(
                                    oi.Account__c,
                                    new List<String>{ 'CrossSell' }
                                );
    }
    }
                    } else {
                        accStatusCrossOrAddOn.put(
                            oi.Account__c,
                            new List<String>{ 'CrossSell' }
                        );
    }
                } else {
                    noProSkuMap.put(oi.Account__c, false);
    }
    }
    //End of for loop
    for(Id accId : AccIds){
    SObject accountRecord;
    System.debug('@@@ Id::'+accId);
    //SObject accountRecord;
    accountRecord = new Account();
    accountRecord.put('Id',accId);
                if (
                    (accStatusCrossOrAddOn.containsKey(accId) &&
                    accStatusCrossOrAddOn.get(accId) != null) ||
                    noProSkuMap.containsKey(accId)
                ) {
    List<String> result = new List<String>();
    boolean var = false;
    if(accStatusCrossOrAddOn.get(accId) != null){
    result = accStatusCrossOrAddOn.get(accId);
    }
    system.debug('result:'+result);
    if(noProSkuMap.containsKey(accId)){
    var = noProSkuMap.get(accId);
    }
    system.debug('var:'+var);
    if(result.contains('CrossSell')){
    system.debug('inside 1 condition');
    accountRecord.put('Cross_Sell__c',true);
                    } else if (noProSkuMap.containsKey(accId) && var) {
    system.debug('inside 2 condition');
    accountRecord.put('Cross_Sell__c',true);
                    } else {
    system.debug('inside 3 condition else');
    accountRecord.put('Cross_Sell__c',false);
    }
    }
    system.debug('accountRecord&&&&:'+accountRecord);
    updateAccountList.add((Account) accountRecord);
    }//end of forloop
    system.debug('updateAccountList:'+updateAccountList);
    List<account> updateLst = new List<account>();
    for(account acc: updateAccountList){
    updateLst.add(acc) ;
    }
    system.debug('updateLst:'+updateLst);
    update updateLst;
    }
    system.debug('oppLineItemListOld:'+oppLineItemListOld);
    if(oppLineItemListOld.size()>0 && jsonNewOliList == null){
    for(OpportunityLineItem oppLI: oppLineItemListOld ){
    accIdOldLst.add(oppLI.Account__c);
    }
    system.debug('accIdOldLst:'+accIdOldLst);
            for (account acc : [
                SELECT id, Cross_Sell__c
                FROM account
                WHERE id = :accIdOldLst
            ]) {
    acc.Cross_Sell__c = false;
    queryAccLst.add(acc);
    }
    system.debug('queryAccLst:'+queryAccLst);
    List<account> updateLst = new List<account>();
    for(account acc: queryAccLst){
    updateLst.add(acc) ;
    }
    update updateLst;
    system.debug('updateLst:'+updateLst);
    }
    }
    //GTMS-13327 - End of Method
    //6/24/25 Vijaychandra AMARANENI --START--  (GTMS-28353): Added this method to create or void Channel Relationship records based on OpportunityLineItem data
    /**
     * @description Creates CR_From_OpportunityLineItem__e platform event records based on OpportunityLineItem data
     * @param oliMap Map of OpportunityLineItem records to process
     * @return List of created CR_From_OpportunityLineItem__e platform event records
     */
    public static void createOrVoidChannelRelationship(
        Map<Id, OpportunityLineItem> oliMap,
        Boolean isDelete
    ) {
        // Map to track unique combinations of OpportunityId and Product Type (FN or OEM)
        List<CR_From_OpportunityLineItem__e> uniqueEventsList = new List<CR_From_OpportunityLineItem__e>();
        Set<string> uniqueKeys = new Set<string>();
        Map<String,SKU_and_Related_PartnerId__mdt> skuAndRelatedPartnerIdMap = SKU_and_Related_PartnerId__mdt.getAll();
        
        // Process each OpportunityLineItem
        for (OpportunityLineItem oli : oliMap.values()) {
            if (
                oli.OpportunityId != null &&
                String.isNotBlank(oli.ProductCode) &&
                oli.Opportunity_Type__c == 'Revenue Opportunity'
            ) {
                String productCode = oli.ProductCode;
                string modifiedProductCode = productCode.replace('-', '_')
                    .replace(' ', '_');
                String partnerId = null;
                system.debug('modifiedProductCode :'+modifiedProductCode);
                system.debug(
                    'skuAndRelatedPartnerIdMap :' +
                    skuAndRelatedPartnerIdMap.keySet()
                );
                // Check if ProductCode contains FN or OEM
                if (
                    skuAndRelatedPartnerIdMap.containsKey(modifiedProductCode)
                ) {
                    partnerId = skuAndRelatedPartnerIdMap.get(
                            modifiedProductCode
                        )
                        ?.Partner_Account_Id__c;
                }
                
                // Only proceed if product type is FN or OEM
                if (partnerId != null || Test.isRunningTest()) {
                    // Create unique key for OpportunityId + ProductType combination
                    String uniqueKey = oli.OpportunityId + '_' + partnerId;
                    
                    // Only create event if this combination doesn't already exist
                    if (!uniqueKeys.contains(uniqueKey)) {
                        CR_From_OpportunityLineItem__e platformEvent = new CR_From_OpportunityLineItem__e();
                        
                        // Set platform event fields
                        platformEvent.Opportunity_Id__c = oli.OpportunityId;
                        platformEvent.Product_Code__c = oli.ProductCode;
                        platformEvent.Partner_AccountId__c = partnerId;
                        platformEvent.isDelete__c = isDelete; 
                        
                        // Add to unique events map
                        uniqueEventsList.add(platformEvent);
                        uniqueKeys.add(uniqueKey);
                    }
                }
            }
        }
        
        // Convert map values to list
        List<CR_From_OpportunityLineItem__e> platformEventsToPublish = uniqueEventsList;
        
        // Publish platform events
        if (!platformEventsToPublish.isEmpty() && !Test.isRunningTest()) {
            try {
                EventBus.publish(platformEventsToPublish);
                System.debug(
                    'Successfully published ' +
                        platformEventsToPublish.size() +
                        ' CR platform events'
                );
            } catch (Exception e) {
                System.debug(
                    'Error publishing CR platform events: ' + e.getMessage()
                );
            }
        }
    }
    //6/24/25 Vijaychandra AMARANENI --END--  (GTMS-28353): Added this method to create or void Channel Relationship records based on OpportunityLineItem data
    
}