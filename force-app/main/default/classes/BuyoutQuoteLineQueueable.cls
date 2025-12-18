/**
* @description       : This Salesforce Apex class implements the Queueable interface to asynchronously
*                      handle the creation and deletion of Samsara Buyout Quote Lines in Salesforce CPQ.    
                       GTMS-27113 
* @last modified on  : 07-1-2025
* @last modified by  : mausam_singh
**/
public with sharing class BuyoutQuoteLineQueueable implements Queueable, Database.AllowsCallouts {
   private Map<Id, SBQQ__Quote__c> sourceQuoteData;
   public static Id buyoutProductId;
   public static Id installationCostProductId;
   public static Id samsaraPassThroughProductId;
   public static Id futureFreeMonthsProductId;
   public static Id otdProductId;
   public static Boolean isBuyoutProductAvailable = false;
   public static Boolean isInstallationCostProductAvailable = false;
   public static Boolean isSamsaraPassThroughProductAvailable = false;
   public static Boolean isFutureFreeMonthsProductAvailable = false;
   public static Boolean isOTDProductAvailable = false;
   public static Map<Id, Id> productToPbeIdMap;
   private static Map<Id, Product2> productDetailsMap;
   @testvisible private static Decimal calculatedTotalLicensePrice;


   /*
    * The class is constructed with a map of quote data (sourceQuoteData)
    */
   public BuyoutQuoteLineQueueable(Map<Id, SBQQ__Quote__c> sourceQuoteData) {
       this.sourceQuoteData = sourceQuoteData;
   }


   public void execute(QueueableContext context) {
       try {
           GS_SBQQQuoteService.TaxCalculationScheduled = true;
            calculatedTotalLicensePrice = getTotalLicensePrice(sourceQuoteData.values()[0], sourceQuoteData.values()[0].SBQQ__LineItems__r);
           String currencyIsoCode = sourceQuoteData.values()[0].CurrencyIsoCode;
           Id pricebookId = sourceQuoteData.values()[0].SBQQ__PriceBook__c;
           initializeProductIds(currencyIsoCode, pricebookId);
           collectAndDeleteSamsaraRebateQuoteLines(sourceQuoteData);
           Boolean rebateLinesInserted = createBuyoutLines(sourceQuoteData);
           updateQuotesAndRecalculate(sourceQuoteData, rebateLinesInserted);
       } catch (Exception e) {
           LOGGER.atError().setRecordId(sourceQuoteData.values()[0].Id).setExceptionOrMessage(e);
       }
       Logger.setFunctionalityType('Rebates');
       Logger.insertMasterLogs();
   }


   /*
    * It stores static IDs for various product types (buyout, installation costs, pass-through, free months)
    * checks for PricebookEntry availability for the specific currency and stores the PBE ID.
    */
   public static void initializeProductIds(String currencyIsoCode, Id pricebookId) {
       Map<String, Id> quoteFieldToProductIdMap = new Map<String, Id>();
       Map<String, String> productCodeToQuoteFieldMap = new Map<String, String>();
       Set<String> productCodes = new Set<String>();
       productToPbeIdMap = new Map<Id, Id>();
       productDetailsMap = new Map<Id, Product2>();


       Map<String, Rebate_Buyout_Product_Mapping__mdt> activeMappings = getActiveRebateBuyoutProductMappings();

       for (String productCode : activeMappings.keySet()) {
           Rebate_Buyout_Product_Mapping__mdt mapping = activeMappings.get(productCode);
           productCodes.add(mapping.Product_Code__c);
           productCodeToQuoteFieldMap.put(mapping.Product_Code__c, mapping.CPQ_Quote_Field__c);
       }


       if (productCodes.isEmpty()) {
           LOGGER.atInfo()
               .setLineNumber(54)
               .setMethod('initializeProductIds')
               .setCLassName('BuyoutQuoteLineQueueable')
               .setExceptionOrMessage('No active rebate buyout product mappings found');
           return;
       }


       for (Product2 prod : [SELECT Id, ProductCode,
                             Product_Type__c,
                             SBQQ__SubscriptionPricing__c,
                             SBQQ__SubscriptionType__c,
                             (SELECT Id FROM PricebookEntries
                              WHERE IsActive = true
                              AND Pricebook2Id = :pricebookId
                              AND CurrencyIsoCode = :currencyIsoCode)
                              FROM Product2
                              WHERE ProductCode IN :productCodes
                              AND IsActive = true]) {


           if (productCodeToQuoteFieldMap.containsKey(prod.ProductCode)) {
               Id productId = prod.Id;
               quoteFieldToProductIdMap.put(productCodeToQuoteFieldMap.get(prod.ProductCode), productId);
               productDetailsMap.put(productId, prod);
               if (!prod.PricebookEntries.isEmpty()) {
                   productToPbeIdMap.put(productId, prod.PricebookEntries[0].Id);
               }
           }
       }

       buyoutProductId = getProductId(quoteFieldToProductIdMap, 'Competitor_Buyout_Amount__c');
       installationCostProductId = getProductId(quoteFieldToProductIdMap, 'Total_Estimated_Installation_Costs__c');
       samsaraPassThroughProductId = getProductId(quoteFieldToProductIdMap, 'Is_Installation_Reimbursable__c');
       futureFreeMonthsProductId = getProductId(quoteFieldToProductIdMap, 'Number_of_months_of_Free_service__c');
       otdProductId = getProductId(quoteFieldToProductIdMap, 'OTD_Amt__c');

       isBuyoutProductAvailable = buyoutProductId != null && productToPbeIdMap.containsKey(buyoutProductId);
       isInstallationCostProductAvailable = installationCostProductId != null && productToPbeIdMap.containsKey(installationCostProductId);
       isSamsaraPassThroughProductAvailable = samsaraPassThroughProductId != null && productToPbeIdMap.containsKey(samsaraPassThroughProductId);
       isFutureFreeMonthsProductAvailable = futureFreeMonthsProductId != null && productToPbeIdMap.containsKey(futureFreeMonthsProductId);
       isOTDProductAvailable = otdProductId != null && productToPbeIdMap.containsKey(otdProductId);
   }

   public static Map<String, Rebate_Buyout_Product_Mapping__mdt> getActiveRebateBuyoutProductMappings() {
       Map<String, Rebate_Buyout_Product_Mapping__mdt> activeMappings = new Map<String, Rebate_Buyout_Product_Mapping__mdt>();
       for (Rebate_Buyout_Product_Mapping__mdt mapping : Rebate_Buyout_Product_Mapping__mdt.getAll().values()) {
           if (mapping.Active__c) {
               activeMappings.put(mapping.Product_Code__c, mapping);
           }else{
            Logger.atInfo()
                    .setMethod('getActiveRebateBuyoutProductMappings')
                    .setCLassName('BuyoutQuoteLineQueueable')
                    .setExceptionOrMessage('Mapping is not active: ' + mapping.Product_Code__c);
           }
       }
       return activeMappings;
   }

   private static void collectAndDeleteSamsaraRebateQuoteLines(Map<Id, SBQQ__Quote__c> sourceQuoteData) {
       Map<Id, SBQQ__QuoteLine__c> rebateQuoteLinesToDelete = getRebateQuoteLinesToDelete(sourceQuoteData);
       GS_SBQQQuoteService.bypassValidation = true;
       if (!rebateQuoteLinesToDelete.isEmpty()) {
           byPassTriggers();
           delete rebateQuoteLinesToDelete.values();
           clearByPassTrigger();
       }
       GS_SBQQQuoteService.bypassValidation = false;
   }


   private static Map<Id, SBQQ__QuoteLine__c> getRebateQuoteLinesToDelete(Map<Id, SBQQ__Quote__c> sourceQuoteData) {
       Map<Id, SBQQ__QuoteLine__c> rebateQuoteLinesToDelete = new Map<Id, SBQQ__QuoteLine__c>();
       for (SBQQ__Quote__c quote : sourceQuoteData.values()) {
           if (quote.SBQQ__LineItems__r != null) {
               for (SBQQ__QuoteLine__c ql : quote.SBQQ__LineItems__r) {
                   if (isRebateQuoteLine(ql)) {
                       rebateQuoteLinesToDelete.put(ql.Id, ql);
                   }
               }
           }
       }
       return rebateQuoteLinesToDelete;
   }


   private static Boolean createBuyoutLines(Map<Id, SBQQ__Quote__c> sourceQuoteData) {
       List<SBQQ__QuoteLine__c> allNewRebateQuoteLines = new List<SBQQ__QuoteLine__c>();

       for (Id quoteId : sourceQuoteData.keySet()) {
           SBQQ__Quote__c quote = sourceQuoteData.get(quoteId);
           processCompetitorBuyout(quote, allNewRebateQuoteLines);
           processInstallationCosts(quote, allNewRebateQuoteLines);
           processFutureFreeMonths(quote, allNewRebateQuoteLines);
           processOneTimeDiscount(quote, allNewRebateQuoteLines);
       }

       if (!allNewRebateQuoteLines.isEmpty()) {
           insertRebateQuoteLines(allNewRebateQuoteLines);
           return true; 
       }
       return false; 
   }

   @testvisible
   private static void processCompetitorBuyout(SBQQ__Quote__c quote, List<SBQQ__QuoteLine__c> allNewRebateQuoteLines) {
       if (quote.Competitor_Buyout_Amount__c != null && quote.Competitor_Buyout_Amount__c > 0 && isBuyoutProductAvailable) {
           Boolean createMultiRebates = !quote.Bypass_Multiline__c ;
           if (createMultiRebates) {
               createMultiRebates = processShipTosAndCreateQLs(quote, allNewRebateQuoteLines, buyoutProductId, quote.Competitor_Buyout_Amount__c);
           }
           if(!createMultiRebates) {
               SBQQ__QuoteLine__c quoteLine = createQuoteLine(quote, buyoutProductId, quote.Shipping_Address_New__c, quote.Competitor_Buyout_Amount__c, 1);
               if (quoteLine != null) {
                   allNewRebateQuoteLines.add(quoteLine);
               }
           }
       }
   }

   @testvisible
   private static void processInstallationCosts(SBQQ__Quote__c quote, List<SBQQ__QuoteLine__c> allNewRebateQuoteLines) {
       if (quote.Total_Estimated_Installation_Costs__c != null && quote.Total_Estimated_Installation_Costs__c > 0 && isInstallationCostProductAvailable) {
           SBQQ__QuoteLine__c quoteLine = createQuoteLine(quote, installationCostProductId, quote.Shipping_Address_New__c, quote.Total_Estimated_Installation_Costs__c, 1);
           if (quoteLine != null) {
               allNewRebateQuoteLines.add(quoteLine);
           }
           if (isSamsaraPassThroughProductAvailable && quote.Is_Installation_Reimbursable__c == 'Yes') {
               SBQQ__QuoteLine__c qL = createQuoteLine(quote, samsaraPassThroughProductId, quote.Shipping_Address_New__c, quote.Total_Estimated_Installation_Costs__c, 1);
               if (qL != null) {
                   allNewRebateQuoteLines.add(qL);
               }
           }
       }
   }

   @testvisible
   private static void processFutureFreeMonths(SBQQ__Quote__c quote, List<SBQQ__QuoteLine__c> allNewRebateQuoteLines) {
       Decimal subscriptionTerm = quote.SBQQ__SubscriptionTerm__c != null ? quote.SBQQ__SubscriptionTerm__c : 0;

       if (((quote.Number_of_months_of_Free_service__c != null && quote.Number_of_months_of_Free_service__c > 0)
            || (quote.Future_Free_Months_Amount__c != null && quote.Future_Free_Months_Amount__c > 0))
            && isFutureFreeMonthsProductAvailable 
            && calculatedTotalLicensePrice != null && calculatedTotalLicensePrice > 0 && subscriptionTerm > 0) {

           Decimal monthlyLicensePrice = calculatedTotalLicensePrice / subscriptionTerm;
           Decimal futureFreeMonthAmount = 0;
           
           if (quote.Future_Free_Service_Type__c == 'Months'
                && quote.Number_of_months_of_Free_service__c != null && quote.Number_of_months_of_Free_service__c > 0) {

                futureFreeMonthAmount = (monthlyLicensePrice * quote.Number_of_months_of_Free_service__c).setScale(2);
            } else if (quote.Future_Free_Months_Amount__c != null && quote.Future_Free_Months_Amount__c > 0) {
                futureFreeMonthAmount = (quote.Future_Free_Months_Amount__c).setScale(2);
            }

           Boolean createMultiRebates = !quote.Bypass_Multiline__c ;
           if (createMultiRebates) {
               createMultiRebates = processShipTosAndCreateQLs(quote, allNewRebateQuoteLines, futureFreeMonthsProductId, futureFreeMonthAmount);
           }
           if(!createMultiRebates) {
               SBQQ__QuoteLine__c quoteLine = createQuoteLine(quote, futureFreeMonthsProductId, quote.Shipping_Address_New__c, futureFreeMonthAmount, 1);
               if (quoteLine != null) {
                   allNewRebateQuoteLines.add(quoteLine);
               }
           }
       }
   }

   @testvisible
   private static void processOneTimeDiscount(SBQQ__Quote__c quote, List<SBQQ__QuoteLine__c> allNewRebateQuoteLines) {
       if (quote.OTD_Amt__c != null && quote.OTD_Amt__c > 0 && isOTDProductAvailable) {
            Boolean createMultiRebates = !quote.Bypass_Multiline__c ;
            if (createMultiRebates) {
                createMultiRebates = processShipTosAndCreateQLs(quote, allNewRebateQuoteLines, otdProductId, quote.OTD_Amt__c);
            }
            if(!createMultiRebates) {
                SBQQ__QuoteLine__c quoteLine = createQuoteLine(quote, otdProductId, quote.Shipping_Address_New__c, quote.OTD_Amt__c, 1);
                if (quoteLine != null) {
                    allNewRebateQuoteLines.add(quoteLine);
                }
            }
       }
   }

   private static boolean processShipTosAndCreateQLs(SBQQ__Quote__c quote, List<SBQQ__QuoteLine__c> allNewRebateQuoteLines, Id productId, Decimal totalAmount) {
       List<SBQQ__QuoteLine__c> qLineList = quote.SBQQ__LineItems__r;
       Map<String, Decimal> shipToNetTotal = calculateShipToNetTotal(quote,qLineList);
       if(!shipToNetTotal.isEmpty()){
           Decimal totalNetAmount = calculateTotalNetAmount(qLineList);
           for (String key : shipToNetTotal.keySet()) {
               List<String> parts = key.split('-');
               Id shipToId = parts[1];
  
               Decimal shipToNetTotalAmount = shipToNetTotal.get(key);
               Decimal ratio = (totalNetAmount != 0) ? (shipToNetTotalAmount / totalNetAmount) : 0;
               Decimal finalAmount = (totalAmount * ratio).setScale(2);
  
               SBQQ__QuoteLine__c quoteLine = createQuoteLine(quote, productId, shipToId, finalAmount, ratio);
               if (quoteLine != null) {
                   allNewRebateQuoteLines.add(quoteLine);
               }
           }
       }else{
           return false;
       }
      return true;
   }

   private static Id getProductId(Map<String, Id> quoteFieldToProductIdMap, String fieldName) {
       return (quoteFieldToProductIdMap != null && quoteFieldToProductIdMap.containsKey(fieldName))
           ? quoteFieldToProductIdMap.get(fieldName)
           : null;
   }

   private static Boolean isRebateQuoteLine(SBQQ__QuoteLine__c ql) {
       return ql.SBQQ__Product__c == buyoutProductId ||
              ql.SBQQ__Product__c == installationCostProductId ||
              ql.SBQQ__Product__c == samsaraPassThroughProductId ||
              ql.SBQQ__Product__c == futureFreeMonthsProductId ||
              ql.SBQQ__Product__c == otdProductId;
   }

   @testvisible
   private static Map<String, Decimal> calculateShipToNetTotal(SBQQ__Quote__c quote,List<SBQQ__QuoteLine__c> qLineList) {
       Map<String, Decimal> shipToNetTotal = new Map<String, Decimal>();
       for (SBQQ__QuoteLine__c ql : qLineList) {
           if (!isRebateQuoteLine(ql) && ql.SBQQ__NetTotal__c != 0 && ql.Conga_Line_Item_Type__c == true) {
               if(ql.Ship_To__c == null){
                   ql.Ship_To__c = quote.Shipping_Address_New__c ;
                     if(ql.Ship_To__c == null){
                       shipToNetTotal.clear();
                       return shipToNetTotal;
                   }
               }
               String key = ql.SBQQ__Quote__c + '-' + ql.Ship_To__c;
               Decimal netTotal = (ql.SBQQ__NetTotal__c != null) ? ql.SBQQ__NetTotal__c : 0;
               if (!shipToNetTotal.containsKey(key)) {
                   shipToNetTotal.put(key, 0);
               }
               shipToNetTotal.put(key, shipToNetTotal.get(key) + netTotal);
           }
       }
       return shipToNetTotal;
   }

   @testvisible
   private static Decimal calculateTotalNetAmount(List<SBQQ__QuoteLine__c> qLineList) {
       Decimal totalNetAmount = 0;
       for (SBQQ__QuoteLine__c ql : qLineList) {
           if (!isRebateQuoteLine(ql) && ql.SBQQ__NetTotal__c != null && ql.Conga_Line_Item_Type__c == true ) {
               totalNetAmount += ql.SBQQ__NetTotal__c ;
           }
       }
       return totalNetAmount;
   }

   @testvisible
   private static SBQQ__QuoteLine__c createQuoteLine(SBQQ__Quote__c quote, Id productId, Id shipToId, Decimal amount, Decimal ratio) {
       if (!productToPbeIdMap.containsKey(productId)) {
           LOGGER.atInfo()
               .setLineNumber(244)
               .setMethod('createQuoteLine')
               .setCLassName('BuyoutQuoteLineQueueable')
               .setRecordId(quote.Id)
               .setExceptionOrMessage('PricebookEntryId not found in map for ProductId: ' + productId +
                    ' for currency ' + quote.CurrencyIsoCode);
           return null;
       }

       Product2 productDetails = productDetailsMap.get(productId);
       if (productDetails == null) {
           LOGGER.atError()
               .setLineNumber(250)
               .setMethod('createQuoteLine')
               .setCLassName('BuyoutQuoteLineQueueable')
               .setRecordId(quote.Id)
               .setExceptionOrMessage('Product details not found in map for ProductId: ' + productId);
           return null;
       }

       Id pricebookEntryId = productToPbeIdMap.get(productId);
       amount = amount.setScale(2);

       SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
           SBQQ__Quote__c = quote.Id,
           SBQQ__Product__c = productId,
           Account__c = quote.SBQQ__Account__c,
           Ship_To__c = shipToId,
           SBQQ__Quantity__c = 1,
           SBQQ__ListPrice__c = (productId == samsaraPassThroughProductId) ? Math.abs(amount) : -Math.abs(amount),
           SBQQ__PricebookEntryId__c = pricebookEntryId,
           Rebate_Buyout_Ratio__c = (ratio*100).setScale(2),
           /*
            Setting  QL as non subsription products
           */
           /*SBQQ__SubscriptionPricing__c = productDetails.SBQQ__SubscriptionPricing__c,
           SBQQ__SubscriptionType__c = productDetails.SBQQ__SubscriptionType__c,
           SBQQ__ProductSubscriptionType__c = productDetails.SBQQ__SubscriptionType__c,
           SBQQ__DefaultSubscriptionTerm__c= quote.SBQQ__SubscriptionTerm__c ,
           SBQQ__SubscriptionTerm__c=quote.SBQQ__SubscriptionTerm__c,*/
           Type_of_Product__c = productDetails.Product_Type__c,
           CurrencyIsoCode = quote.CurrencyIsoCode
       );

       return quoteLine;
   }

   @testvisible
   private static void insertRebateQuoteLines(List<SBQQ__QuoteLine__c> allNewRebateQuoteLines) {
       byPassTriggers();
       insert allNewRebateQuoteLines;
       clearByPassTrigger();
   }

   private static void updateQuotesAndRecalculate(Map<Id, SBQQ__Quote__c> sourceQuoteData, Boolean rebateLinesInserted) {
    Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>();

    for (SBQQ__Quote__c quoteRec : sourceQuoteData.values()) {
        SBQQ__Quote__c quoteToUpdate = new SBQQ__Quote__c(
            Id = quoteRec.Id,
            Recalculate_Quote__c = false
        );

        // Only set other fields if rebate lines were inserted
        if (rebateLinesInserted) {
            updateQuoteSubsidyFields(quoteRec); 
            updateNewDCArchitecture(quoteRec);

            quoteToUpdate.Future_Free_Months_Amount__c = quoteRec.Future_Free_Months_Amount__c;
            quoteToUpdate.Subsidy_Amount__c = quoteRec.Subsidy_Amount__c;
            quoteToUpdate.Free_service_months_requested__c = quoteRec.Free_service_months_requested__c;
            quoteToUpdate.New_DC_architecture__c = quoteRec.New_DC_architecture__c;
            quoteToUpdate.Number_of_months_of_Free_service__c = quoteRec.Number_of_months_of_Free_service__c;

        }

        quoteMap.put(quoteRec.Id, quoteToUpdate);
    }

    byPassTriggers();

    if (!quoteMap.isEmpty()) {
        update quoteMap.values();
    }

    clearByPassTrigger();

    if (!quoteMap.isEmpty()) {
        QuoteCalculatorHelper.calculateQuotes(quoteMap.keySet());
    }
}

   private static void updateQuoteSubsidyFields(SBQQ__Quote__c quoteRec) {
        Decimal futureFreeMonthAmount = 0;
        Decimal futureFreeMonth = 0;
        String infoMessage = '';

        
        if(calculatedTotalLicensePrice != null && calculatedTotalLicensePrice > 0 
            && quoteRec.SBQQ__SubscriptionTerm__c != null && quoteRec.SBQQ__SubscriptionTerm__c != 0){
            
            if(quoteRec.Future_Free_Service_Type__c == 'Months'
                && quoteRec.Number_of_months_of_Free_service__c != null && quoteRec.Number_of_months_of_Free_service__c != 0) {
                
                futureFreeMonthAmount = ((calculatedTotalLicensePrice / quoteRec.SBQQ__SubscriptionTerm__c) * quoteRec.Number_of_months_of_Free_service__c ).setScale(2);
                futureFreeMonth = (quoteRec.Number_of_months_of_Free_service__c).setScale(2);

            } else if(quoteRec.Future_Free_Months_Amount__c != null && quoteRec.Future_Free_Months_Amount__c > 0) {
                        
                futureFreeMonthAmount = (quoteRec.Future_Free_Months_Amount__c).setScale(2);
                futureFreeMonth = (futureFreeMonthAmount / (calculatedTotalLicensePrice / quoteRec.SBQQ__SubscriptionTerm__c)).setScale(2);
            }
        }

        infoMessage = ' Future Free Months Amount changed from ' + quoteRec.Future_Free_Months_Amount__c + ' to ' + futureFreeMonthAmount;
        quoteRec.Future_Free_Months_Amount__c = futureFreeMonthAmount;
        quoteRec.Number_of_months_of_Free_service__c = futureFreeMonth;


        infoMessage = infoMessage + ' Subsidy Amount changed from ' + quoteRec.Subsidy_Amount__c + ' to ';
        quoteRec.Subsidy_Amount__c = ((futureFreeMonthAmount==null)?0:futureFreeMonthAmount)
                + ((quoteRec.X3rd_PF_Interest_Subsidy__c==null)?0:quoteRec.X3rd_PF_Interest_Subsidy__c)
            	+ ((quoteRec.OTD_Amt__c==null)?0:quoteRec.OTD_Amt__c); //GTMS-29862 Included OTD_Amt__c
        infoMessage = infoMessage + quoteRec.Subsidy_Amount__c;

        if(quoteRec.Number_of_months_of_Free_service__c != null && quoteRec.Number_of_months_of_Free_service__c > 0){
            quoteRec.Free_service_months_requested__c = true;
        }else{
            quoteRec.Free_service_months_requested__c = false;
        }

        Logger.atInfo()
                .setCLassName('BuyoutQuoteLineQueueable')
                .setMethod('updateQuoteSubsidyFields')
                .setRecordId(quoteRec.Id)
                .setExceptionOrMessage(infoMessage);
   }

   public static void updateNewDCArchitecture(SBQQ__Quote__c quoteRec) {
    if((quoteRec.Competitor_Buyout_Amount__c != null && quoteRec.Competitor_Buyout_Amount__c != 0) ||
            (quoteRec.Total_Estimated_Installation_Costs__c != null && quoteRec.Total_Estimated_Installation_Costs__c != 0) ||
            (quoteRec.Future_Free_Months_Amount__c != null && quoteRec.Future_Free_Months_Amount__c != 0) ||
            (quoteRec.OTD_Amt__c != null && quoteRec.OTD_Amt__c != 0) ) {
                quoteRec.New_DC_architecture__c = true;
        } else {
            quoteRec.New_DC_architecture__c = false;
        }
   }


   /*
    * To detect if there's any mismatch/conflict between the rebate quote lines present in the current quote and
    * the expected rebate quote lines the system would calculate afresh using internal logic.
    */
   public static Boolean checkForConflicts(Id quoteId) {
       try {
           Map<Id, SBQQ__Quote__c> sourceQuoteDataMap = new GS_SBQQQuoteSelector(true).checkFatalError().getQuotesAndQuoteLinesById(new Set<Id>{quoteId});
           SBQQ__Quote__c quote = sourceQuoteDataMap.get(quoteId);
           List<SBQQ__QuoteLine__c> rebateCurrentQuoteLines = new List<SBQQ__QuoteLine__c>();
           List<SBQQ__QuoteLine__c> expectedRebateQuoteLines = new List<SBQQ__QuoteLine__c>();


           initializeProductIds(quote.CurrencyIsoCode, quote.SBQQ__PriceBook__c);


           for (Integer i = quote.SBQQ__LineItems__r.size() - 1; i >= 0; i--) {
               SBQQ__QuoteLine__c line = quote.SBQQ__LineItems__r[i];
               if (isRebateQuoteLine(line)) {
                   rebateCurrentQuoteLines.add(line);
                   quote.SBQQ__LineItems__r.remove(i);
               }
           }
           calculatedTotalLicensePrice = getTotalLicensePrice(quote, sourceQuoteDataMap.values()[0].SBQQ__LineItems__r);

           processCompetitorBuyout(quote, expectedRebateQuoteLines);
           processInstallationCosts(quote, expectedRebateQuoteLines);
           processFutureFreeMonths(quote, expectedRebateQuoteLines);
           processOneTimeDiscount(quote, expectedRebateQuoteLines);
           return !compareQuoteLines(rebateCurrentQuoteLines, expectedRebateQuoteLines);
       } catch (Exception e) {
           return false;
       }
   }


   /*
    * compareQuoteLines() to see if current vs. expected rebate lines match.
    * If they don't match, it returns true → there's a conflict.
    * If there's an exception, it just returns false (safe fallback)
    */
   @testvisible
   private static Boolean compareQuoteLines(List<SBQQ__QuoteLine__c> currentLines, List<SBQQ__QuoteLine__c> expectedLines) {
       if (currentLines.size() != expectedLines.size()) {
           return false;
       }
       Map<String, Decimal> shipToBuyoutValueCurrent = new Map<String, Decimal>();
       Map<String, Decimal> shipToBuyoutValueExpected = new Map<String, Decimal>();


       for (SBQQ__QuoteLine__c ql : currentLines) {
           shipToBuyoutValueCurrent.put(ql.Ship_To__c + '-' + ql.SBQQ__Product__c, -1 * ql.SBQQ__NetTotal__c);
       }
       for (SBQQ__QuoteLine__c ql : expectedLines) {
           shipToBuyoutValueExpected.put(ql.Ship_To__c + '-' + ql.SBQQ__Product__c, -1 * ql.SBQQ__ListPrice__c);
       }
       return shipToBuyoutValueCurrent.equals(shipToBuyoutValueExpected);
   }

   @testvisible
    public static Decimal getTotalLicensePrice(SBQQ__Quote__c qt, List<SBQQ__QuoteLine__c> quoteLines) {
        Decimal annualPayment = 0;
        Decimal totalLicensePrice = 0;
        SBQQ__Quote__c clonedQuote = qt.clone(true, true);
        
        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            if (quoteLine.Total_Annual_Price__c != null && quoteLine.Conga_Line_Item_Type__c == true) {
                annualPayment += quoteLine.Total_Annual_Price__c;
            }
        }
        clonedQuote.Estimated_Annual_Payment__c = annualPayment;
        List<sbqq__Quote__C> quotesRecal = new List<sbqq__Quote__C>{clonedQuote};
        List<FormulaRecalcResult> results = Formula.recalculateFormulas(quotesRecal);
        totalLicensePrice = (Decimal)quotesRecal[0].get('Total_License_Price__c');
        return totalLicensePrice;
    }

   public static void byPassTriggers() {
       TriggerHandler.bypass('GS_OpportunityTriggerHandler');
       TriggerHandler.bypass('OpportunityTriggerHandler');
       TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
       // TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
       TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
       TriggerHandler.bypass('AccountTriggerHandler');
       TriggerHandler.bypass('GS_AccountTriggerHandler');
       TriggerHandler.bypass('ContractTriggerHandler');
       TriggerHandler.bypass('GS_ContactTriggerHandler');
       TriggerHandler.bypass('ContactTriggerHandler');
       SBQQ.TriggerControl.disable();
   }


   public static void clearByPassTrigger() {
       TriggerHandler.clearBypass('GS_OpportunityTriggerHandler');
       TriggerHandler.clearBypass('OpportunityTriggerHandler');
       TriggerHandler.clearBypass('GS_SBQQQuoteTriggerHandler');
       // TriggerHandler.clearBypass('SBQQQuoteLineTriggerHandler');
       TriggerHandler.clearBypass('OpportunityLineItemTriggerHandler');
       TriggerHandler.clearBypass('AccountTriggerHandler');
       TriggerHandler.clearBypass('GS_AccountTriggerHandler');
       TriggerHandler.clearBypass('ContractTriggerHandler');
       TriggerHandler.clearBypass('GS_ContactTriggerHandler');
       TriggerHandler.clearBypass('ContactTriggerHandler');
       SBQQ.TriggerControl.enable();
   }
}