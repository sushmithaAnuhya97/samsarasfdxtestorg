public class DealHealthController {
    
    @AuraEnabled
    public static string updateQuoteDealHealth(String quoteId){

        List<Deal_Health_Data__c> dealList = new List<Deal_Health_Data__c>();
        Map<String,Sobject> objToRec = new Map<String,Sobject>();
        String dealHealth;
        String query;
        String filterData;
        SBQQ__Quote__c quote;
        Account quoteAcc;
        Opportunity quoteOpp;

        query = 'SELECT Id, '+System.Label.Deal_Health_Fields+' FROM Deal_Health_Data__c WHERE ';

        quote = [SELECT Id, Blended_Discount__c, Selected_Payment_Type__c,Subsidy_Amount__c, Buyout_Amount__c, P_P_Legacy__c, 
                                    Account_Industry__c,SBQQ__Account__c, SBQQ__Account__r.Industry,Original_License_Term__c,
                                    SBQQ__Account__r.Global_Geography__c, SBQQ__Account__r.Total_parent_child_ARR__c,
                                    SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Type, SBQQ__Opportunity2__r.First_Purchase__c,
                                    (SELECT Id, Name, SBQQ__ProductFamily__c, SBQQ__Product__r.product_Tag__c, ACV_Total_Price_Stamp__c 
                                        FROM SBQQ__LineItems__r WHERE ACV_Total_Price_Stamp__c != 0 AND ACV_Total_Price_Stamp__c != null) 
                                FROM SBQQ__Quote__c WHERE id = :quoteId LIMIT 1];

        System.debug('Legacy-->'+quote.P_P_Legacy__c);

        quoteAcc = new Account(Id = quote.SBQQ__Account__c, 
                                Industry = quote.SBQQ__Account__r.Industry,
                                Global_Geography__c = quote.SBQQ__Account__r.Global_Geography__c, 
                                Total_parent_child_ARR__c = quote.SBQQ__Account__r.Total_parent_child_ARR__c);

        quoteOpp = [SELECT Id, Type, First_Purchase__c, CloseDate, Account.First_Purchase_Date__c FROM Opportunity WHERE Id = : quote.SBQQ__Opportunity2__c];

        objToRec.put('SBQQ__Quote__c',quote);
        objToRec.put('Account',quoteAcc);
        objToRec.put('Opportunity',quoteOpp);

        //For each field, calcuate the filter criteria
        for(Deal_Health_Mapping__mdt mapping :[SELECT DeveloperName, Object__c, Logic_Type__c, Target_Field__c, Source_Field__c, Logic__c FROM Deal_Health_Mapping__mdt]){

            filterData = '';

            //When Deal Health Mapping Custom Metadata record is not setup properly, skip.
            //Proper Setup includes:
            // >> Must have a Logic Type
            // >> When Logic Type is Direct, Target Field must be present
            // >> When Logic Type is 'Formula' or 'Custom', Logic Type & Object must be present.
            if(String.isBlank(mapping.Logic_Type__c) || (String.isBlank(mapping.Target_Field__c) && mapping.Logic_Type__c == 'Direct') || (String.isBlank(mapping.Logic__c) && new list<string>{'Formula','Mapping'}.contains(mapping.Logic_Type__c))) continue;

            //Calculate the filter data
            Switch on mapping.Logic_Type__c {

                when 'Direct'{
                    filterData = (String)quote.get(mapping.Target_Field__c);
                }

                when 'Formula'{
                    filterData = calculateForumla(mapping, objToRec);
                }

                when 'Custom'{
                    filterData = calculateCustomLogic(mapping, quote);
                }
            }

            // Add the filter criteria to query --> field to filter = 'filter data'
            query += mapping.Source_Field__c +' = \''+filterData+'\' AND ';
        }

        System.debug('Query-->'+query.removeEnd('AND '));

        dealList =  Database.query(query.removeEnd('AND '));

        if(dealList.size() != 1) throw new AuraException(System.label.DealHealth_Query_Error);

        dealHealth = calculateDealHealth(dealList[0], quote);

        //When the deal health is green, no need to capture recommended discount.
        return dealHealth != 'Green'? dealList[0].Green_Zone__c+'_'+dealHealth : '_'+dealHealth;
    }

    /***********************HELPER METHODS ***********************/

    private static string calculateForumla(Deal_Health_Mapping__mdt mapping, Map<String,Sobject> objToRec){

        return (String)formula.builder()
                        .withReturnType(FormulaEval.FormulaReturnType.String)
                        .withType(((Sobject)Type.forName(mapping.Object__c).newInstance()).getSObjectType())
                        .withFormula(mapping.Logic__c)
                        .build()
                        .evaluate(objToRec.get(mapping.Object__c)) ?? '';
    }

    private static string calculateCustomLogic(Deal_Health_Mapping__mdt mapping, SBQQ__Quote__c quote){

        if(mapping.DeveloperName == 'Product_Importance_Tagging'){

            string defaultReturnString = 'Mixed - '+quote.P_P_Legacy__c;

            double totalACV = 0;
            Map<String, double> productTagToACVAcutal = new Map<String, double>(); //Calcualted based on Data
            Map<String,Object> productTagToACVThreshold = (Map<String,Object>)JSON.deserializeUntyped(mapping.Logic__c); //Configured in Metadata

            for(SBQQ__QuoteLine__c line : quote.SBQQ__LineItems__r){

                totalACV += line.ACV_Total_Price_Stamp__c;

                if(productTagToACVThreshold.keySet().contains(line.SBQQ__Product__r.product_Tag__c))
                    productTagToACVAcutal = addToMap(line, productTagToACVAcutal);
            }

            if(totalACV == 0) return defaultReturnString;

            for(String key :productTagToACVAcutal.keySet()){

                if((productTagToACVAcutal.get(key)/totalACV)*100 >= Double.valueOf((String)productTagToACVThreshold.get(key))) 
                    return key+' dominant - '+quote.P_P_Legacy__c;
            }

            return defaultReturnString;
        }

        return '';
    }

    private static string calculateDealHealth(Deal_Health_Data__c dhdRec, SBQQ__Quote__c quote){
        return quote.Blended_Discount__c < = dhdRec.Q1__c ? 'Green' : 
                ( quote.Blended_Discount__c > dhdRec.Q1__c && quote.Blended_Discount__c < = dhdRec.Q2__c? 'Yellow' :
                ( quote.Blended_Discount__c > dhdRec.Q2__c && quote.Blended_Discount__c < = dhdRec.Q3__c? 'Orange' : 'Red'));

    }

    private static Map<String, double> addToMap(SBQQ__QuoteLine__c line, Map<String, double> theMap){

        if(!theMap.containsKey(line.SBQQ__Product__r.product_Tag__c)) theMap.put(line.SBQQ__Product__r.product_Tag__c, 0);

        theMap.put(line.SBQQ__Product__r.product_Tag__c, theMap.get(line.SBQQ__Product__r.product_Tag__c)+line.ACV_Total_Price_Stamp__c);

        return theMap;
    }
}