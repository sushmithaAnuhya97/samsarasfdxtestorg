/*
* Oct-12-2023 Rajesh GTMS-16392 Removed SOQL in inner for loop
*/
public class PopulateTaxes { 
    @testVisible public static string mockedResponse = null;

    public static final String STATUS_TAX_CALCULATION_ERROR = 'Error';
    public static final String STATUS_TAX_CALCULATION_SUCCESS = 'Updated';
    public static final String STATUS_TAX_CALCULATION_VALIDATION = 'Validation';
    public static final String STATUS_TAX_CALCULATION_REFRESH = 'Refresh';

    @future(callout = true)
    public static void populateVertexTaxes(Set<ID> quotelistIDs){
        callVertex(quotelistIDs);
    }

    //This method will be called from above Future and also from Batch
    public static void callVertex(Set<ID> quotelistIDs){
        Map<Id,SBQQ__Quote__c> updateQuotes =  new Map<Id,SBQQ__Quote__c>();
        List<SBQQ__QuoteLine__c> updateQuoteLines = new List<SBQQ__QuoteLine__c>();
        Map<Id,Id> qlQuote = new Map<Id,Id>();
        String ExceptionMsg = '';
        String skipTaxes = System.Label.Skip_Taxes;

        for(SBQQ__Quote__c  quote : [SELECT ID, Name, SBQQ__NetAmount__c, Sales_Tax__c, SBQQ__Opportunity2__r.Id, VertexCPQ__Tax_Amount__c, SBQQ__Primary__c,
            Blended_Discount__c, ApprovalStatus__c, Shipping_Address_NEW__c, SBQQ__Opportunity2__r.Name, 
            Tax_Calculation_Status__c, SBQQ__Account__c,SBQQ__Uncalculated__c,
                (SELECT Id, Name, Ship_To_Address_Concatenated__c, VertexCPQ__Tax_Amount__c, SBQQ__NetTotal__c, Ship_To__c,SBQQ__ProductCode__c FROM SBQQ__LineItems__r
                 WHERE SBQQ__Product__r.Skip_Vertex_Calculation__c = false)
            FROM SBQQ__Quote__c
            WHERE Id IN : quotelistIDs AND Shipping_Address_NEW__c <> null]){
            if(!Test.isRunningTest() && (quote.SBQQ__Account__c == null 
                || (skipTaxes).contains(String.valueOf(quote.SBQQ__Account__c)))){
                continue;
            }
            
            String quoteJSON = JSON.serialize(quote);
            List<SBQQ__QuoteLine__c> quoLine = new List<SBQQ__QuoteLine__c>(); 
            String lineItemsString = JSON.serialize(quoLine);
            
            String lineNetTotals = '';
            String lineShipTo = '';
            String response='';
            
            try{
                // Perform a callout to an external service
                response = VertexCPQ.VertexRESTAllFields.getTaxAllFields(quoteJSON, lineItemsString, 'Quote'); 
                if (Test.isRunningTest() && String.isNotBlank(mockedResponse)) {
                    response = mockedResponse;
                }

                System.debug('Vertex Response:' + response);

                Map<Id, SBQQ__QuoteLine__c> quotelineMap = new Map<Id, SBQQ__QuoteLine__c>();
                Set<Id> quotelineIDs = new Set<Id>();

                for(SBQQ__QuoteLine__c line : quote.SBQQ__LineItems__r){ //GTMS-16392
                    qlQuote.put(line.Id,quote.Id);
                    quotelineMap.put(line.Id, line);
                    quotelineIDs.add(line.Id);
                    lineNetTotals += ', ' + line.Name +'='+line.SBQQ__NetTotal__c;
                    lineShipTo += ', ' + line.Name +'='+line.Ship_To_Address_Concatenated__c;
                }

                // Avoid empty object JSON response or completely blank responses
                if(String.isNotBlank(response) && response != '{}'){
                    Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response);
                    for(String Key : responseMap.keySet()){
                        Decimal quotetax = (Decimal) responseMap.get(Key);
                        Decimal quotetax1 = quotetax.setScale(2);

                        if (Key == quote.Id
                            && (quotetax1 != quote.VertexCPQ__Tax_Amount__c || quote.Tax_Calculation_Status__c != STATUS_TAX_CALCULATION_SUCCESS)){
                            SBQQ__Quote__c quoteToUpdate = new SBQQ__Quote__c(
                                Id = Key,
                                VertexCPQ__Tax_Amount__c = (Decimal) responseMap.get(Key),
                                Tax_Calculation_Status__c = STATUS_TAX_CALCULATION_SUCCESS
                            );
                            if(quotetax1 != quote.VertexCPQ__Tax_Amount__c){
                                quoteToUpdate.First_Calculated__c = System.today();
                            }
                            updateQuotes.put(Key,quoteToUpdate);
                        }

                        if(quotelineIDs.contains(Key)){
                            Decimal linetax = (Decimal) responseMap.get(Key);
                            Decimal linetax1 = linetax.setScale(2);
                            
                            if(linetax1 != (Decimal) quotelineMap.get(key).VertexCPQ__Tax_Amount__c){
                                SBQQ__QuoteLine__c quotelineToUpdate = new SBQQ__QuoteLine__c(
                                    Id = Key,
                                    VertexCPQ__Tax_Amount__c = (Decimal) responseMap.get(Key)
                                );
                                updateQuoteLines.add(quotelineToUpdate);
                            }
                        }
                    }
                }else{
                    // Set quote to empty
                    if (quote.VertexCPQ__Tax_Amount__c != null || quote.Tax_Calculation_Status__c != STATUS_TAX_CALCULATION_ERROR){
                        updateQuotes.put(quote.Id, new SBQQ__Quote__c(
                            Id = quote.Id,
                            VertexCPQ__Tax_Amount__c = null,
                            Tax_Calculation_Status__c = STATUS_TAX_CALCULATION_ERROR
                        ));
                    }

                    // Set all QL to empty, if they aren't already
                    for (Id quoteLineId : quotelineMap.keySet()){
                        SBQQ__QuoteLine__c ql = quoteLineMap.get(quoteLineId);

                        if (ql.VertexCPQ__Tax_Amount__c != null){
                            updateQuoteLines.add(new SBQQ__QuoteLine__c(
                                Id = quoteLineId,
                                VertexCPQ__Tax_Amount__c = null
                            ));
                        }
                    }
                }
            }catch(CalloutException ex){
                ExceptionMsg += (String.isBlank(ExceptionMsg) ? '' : '\n')+'Callout exception:\n'+ex.getMessage();
            }catch(Exception ex){
                ExceptionMsg += (String.isBlank(ExceptionMsg) ? '' : '\n')+'Exception:\n'+ex.getMessage()+'\nStack trace: '+ex.getStackTraceString();
            }
        }

        System.debug('updateQuotes IsEmpty? '+updateQuotes.isEmpty());
        System.debug('updateQuoteLines IsEmpty? '+updateQuoteLines.isEmpty());
        Savepoint sp;
        Boolean isDMLPerformed = false;
            
        //try{
            //sp = Database.setSavepoint();
            //SBQQ.TriggerControl.disable();
               byPassTriggers();
            Database.SaveResult[] updatedQLs = Database.update(updateQuoteLines,false);
           // SBQQ.TriggerControl.enable();
             clearByPassTrigger();
            for(Integer i=0;i<updatedQLs.size();i++)
            {
                if(!updatedQLs[i].isSuccess())
                {
                    if(qlQuote.containsKey(updatedQLs[i].Id) 
                        && updateQuotes.containsKey(qlQuote.get(updatedQLs[i].Id)) 
                        && updateQuotes.get(qlQuote.get(updatedQLs[i].Id)).Tax_Calculation_Status__c == 'Updated'){
                            updateQuotes.get(qlQuote.get(updatedQLs[i].Id)).Tax_Calculation_Status__c = 'Aborted';
                            updateQuotes.get(qlQuote.get(updatedQLs[i].Id)). VertexCPQ__Tax_Amount__c = null;
                    }
                }
            }
        
            SBQQ.TriggerControl.disable();
           // Database.SaveResult[] updatedQuotes = Database.update(updateQuotes.values(),false);
           GS_SBQQQuoteService.isTaxCalculationCompleted = true;
           
           update updateQuotes.values();

            /*if(!updateQuotes.isEmpty()){
                isDMLPerformed = true;
                update updateQuotes;
            }
            if(!updateQuoteLines.isEmpty()){
                isDMLPerformed = true;
                update updateQuoteLines;
            }*/
        /*}catch(Exception ex){
            ExceptionMsg += (String.isBlank(ExceptionMsg) ? '' : '\n')+'DML Exception:\n'+ex.getMessage()+'\nStack trace: '+ex.getStackTraceString();
            //Database.rollback(sp);
        }*/
    }
     public static void byPassTriggers(){
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('GS_ContactTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        SBQQ.TriggerControl.disable();
    }

    public static void clearByPassTrigger(){
        TriggerHandler.clearBypass('GS_OpportunityTriggerHandler');
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        TriggerHandler.clearBypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.clearBypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.clearBypass('OpportunityLineItemTriggerHandler');
        TriggerHandler.clearBypass('AccountTriggerHandler');
        TriggerHandler.clearBypass('GS_AccountTriggerHandler');
        TriggerHandler.clearBypass('ContractTriggerHandler');
        TriggerHandler.clearBypass('GS_ContactTriggerHandler');
        TriggerHandler.clearBypass('ContactTriggerHandler');
        SBQQ.TriggerControl.enable();
    }  
}